import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/ics_event.dart';

class ScheduleService {
  final http.Client client;

  ScheduleService(this.client);

  // Corrige les accents mal encodés via une seule RegExp
  static final Map<String, String> _accentFixMap = {
    'Ã©': 'é',
    'Ã¨': 'è',
    'Ã´': 'ô',
    'Ã': 'à',
  };

  static final RegExp _accentFixRegex = RegExp(
    _accentFixMap.keys.map(RegExp.escape).join('|'),
  );

  static String cleanAccents(String input) =>
      input.replaceAllMapped(_accentFixRegex, (m) => _accentFixMap[m[0]]!);

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

    final isUtf8 = (response.headers['content-type'] ?? '')
        .toLowerCase()
        .contains('charset=utf-8');
    final decodedBody =
        isUtf8
            ? utf8.decode(response.bodyBytes)
            : latin1.decode(response.bodyBytes);

    final calendar = ICalendar.fromString(decodedBody);
    final List<Map<String, dynamic>> eventsData = calendar.data;

    final List<IcsEvent> allEvents =
        eventsData
            .where((e) => e['type'] == 'VEVENT')
            .map((e) => IcsEvent.fromJson(e, tzLocation))
            .where((event) => event.start != null)
            .map(
              (event) => IcsEvent(
                summary:
                    event.summary != null ? cleanAccents(event.summary!) : null,
                description:
                    event.description != null
                        ? cleanAccents(event.description!)
                        : null,
                start: event.start,
                end: event.end,
                room: event.room?.map(cleanAccents).toList(),
                teacher:
                    event.teacher != null ? cleanAccents(event.teacher!) : null,
              ),
            )
            .toList()
          ..sort((a, b) => a.start!.compareTo(b.start!));

    return allEvents;
  }
}
