import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/ics_event.dart';

class ScheduleService {
  final http.Client client;

  ScheduleService(this.client);

  // Fonction pour corriger les accents mal encodés
  String cleanAccents(String value) {
    return value
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã¨', 'è')
        .replaceAll('Ã', 'à')
        .replaceAll('Ã´', 'ô');
  }

  Future<List<IcsEvent>> fetchSchedule(
    String userId,
    tz.Location tzLocation,
  ) async {
    final url = Uri.parse(
      'http://applis.univ-nc.nc/cgi-bin/WebObjects/EdtWeb.woa/2/wa/default?login=$userId%2Fical',
    );
    final response = await client.get(url);

    if (response.statusCode != 200) {
      throw Exception("Erreur HTTP ${response.statusCode}");
    }

    final contentType = response.headers['content-type'] ?? '';
    String decodedBody;

    if (contentType.toLowerCase().contains('charset=utf-8')) {
      decodedBody = utf8.decode(response.bodyBytes);
    } else {
      decodedBody = latin1.decode(response.bodyBytes);
    }

    final calendar = ICalendar.fromString(decodedBody);

    final allEvents =
        calendar.data
            .where((e) => e['type'] == 'VEVENT')
            .map((e) {
              final event = IcsEvent.fromJson(e, tzLocation);
              return IcsEvent(
                summary:
                    event.summary != null ? cleanAccents(event.summary!) : null,
                description:
                    event.description != null
                        ? cleanAccents(event.description!)
                        : null,
                start: event.start,
                end: event.end,
                // Ici on nettoie chaque élément de la liste room si elle existe
                room:
                    event.room != null
                        ? event.room!.map((r) => cleanAccents(r)).toList()
                        : null,
                teacher:
                    event.teacher != null ? cleanAccents(event.teacher!) : null,
              );
            })
            .where((event) => event.start != null)
            .toList();

    allEvents.sort((a, b) => a.start!.compareTo(b.start!));

    return allEvents;
  }
}
