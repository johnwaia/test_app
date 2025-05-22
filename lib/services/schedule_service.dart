import 'dart:async'; // Pour TimeoutException
import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'package:http/http.dart' as http; // Pour http.Client, http.Response
import 'package:timezone/timezone.dart' as tz; // Pour tz.Location
import 'package:icalendar_parser/icalendar_parser.dart'; // Pour ICalendar
import 'package:test_app/models/ics_event.dart'; // Pour IcsEvent (fichier que tu dois créer ou avoir dan_
import 'package:test_app/constants/strings.dart';

class ScheduleService {
  final http.Client _client;
  ScheduleService(this._client);

  Future<List<IcsEvent>> fetchWeekEvents(
    String userId,
    tz.Location location,
    DateTime startOfWeek,
    DateTime endOfWeek,
  ) async {
    final String encodedUserId = Uri.encodeComponent(userId);
    final Uri url = Uri.parse(
      'http://applis.univ-nc.nc/cgi-bin/WebObjects/EdtWeb.woa/2/wa/default?login=$encodedUserId%2Fical',
    );
    debugPrint("Fetching events from: $url");

    try {
      final http.Response response = await _client
          .get(url)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          debugPrint("ICS response body is empty for $userId.");
          return [];
        }
        return _parseIcsEvents(response.body, location, startOfWeek, endOfWeek);
      } else if (response.statusCode == 404) {
        throw Exception(
          "L'identifiant '$userId' n'a pas été trouvé ou l'emploi du temps n'existe pas (Erreur ${response.statusCode}).",
        );
      } else {
        throw Exception(
          'Erreur serveur (${response.statusCode}) lors de la récupération de l\'emploi du temps.',
        );
      }
    } on TimeoutException catch (_) {
      debugPrint("Timeout lors du chargement des événements pour $userId");
      throw Exception(timeoutErrorMessage);
    } on http.ClientException catch (e) {
      debugPrint("Erreur réseau/client pour $userId: $e");
      throw Exception(networkErrorMessage);
    } catch (e) {
      debugPrint(
        "Erreur inconnue lors du chargement des événements pour $userId: $e",
      );
      throw Exception("$defaultErrorMessage ($e)");
    }
  }

  List<IcsEvent> _parseIcsEvents(
    String icsContent,
    tz.Location noumeaLocation,
    DateTime startOfWeek,
    DateTime endOfWeek,
  ) {
    try {
      final ICalendar calendar = ICalendar.fromString(icsContent);

      return calendar.data
          .where(
            (e) =>
                _getCaseInsensitive(e, 'type')?.toString().toUpperCase() ==
                icsTypeVEvent,
          )
          .map((e) => IcsEvent.fromJson(e, noumeaLocation))
          .where(
            (event) =>
                event.start != null &&
                event.end != null &&
                !event.start!.isBefore(startOfWeek) &&
                event.start!.isBefore(endOfWeek),
          )
          .toList()
        ..sort((a, b) => a.start!.compareTo(b.start!));
    } catch (e) {
      debugPrint("Erreur de parsing du contenu ICS: $e");
      throw Exception(
        "Les données de l'emploi du temps sont corrompues ou dans un format inattendu.",
      );
    }
  }

  dynamic _getCaseInsensitive(Map map, String key) {
    return map.entries
        .firstWhere(
          (entry) => entry.key.toString().toLowerCase() == key.toLowerCase(),
          orElse: () => const MapEntry<String, dynamic>('', null),
        )
        .value;
  }
}
