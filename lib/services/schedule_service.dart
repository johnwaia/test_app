import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/ics_event.dart';

class ScheduleService {
  final http.Client client;

  ScheduleService(this.client);

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

    final calendar = ICalendar.fromString(response.body);
    final allEvents =
        calendar.data
            .where((e) => e['type'] == 'VEVENT')
            .map((e) => IcsEvent.fromJson(e, tzLocation))
            .toList();

    // Calculer le début et la fin de la semaine en cours (lundi à dimanche)
    final now = tz.TZDateTime.now(tzLocation);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // lundi
    final endOfWeek = startOfWeek.add(
      const Duration(days: 7),
    ); // lundi prochain

    // Filtrer les événements dont start est dans cette plage
    final eventsOfWeek =
        allEvents.where((event) {
          final start = event.start;
          if (start == null) return false;
          final startLocal = tz.TZDateTime.from(start, tzLocation);
          return startLocal.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              ) &&
              startLocal.isBefore(endOfWeek);
        }).toList();

    return eventsOfWeek;
  }
}
