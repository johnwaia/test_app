import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  tzdata.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDT UNC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Emploi du temps UNC'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<IcsEvent>> _futureEvents;
  static const String userId = 'jwaia04';

  @override
  void initState() {
    super.initState();
    _futureEvents = fetchTodayEvents(userId);
  }

  Future<List<IcsEvent>> fetchTodayEvents(String userId) async {
    final icsUrl =
        'http://applis.univ-nc.nc/cgi-bin/WebObjects/EdtWeb.woa/2/wa/default?login=$userId%2Fical';

    try {
      final response = await http.get(Uri.parse(icsUrl));

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP : ${response.statusCode}');
      }

      // Utilisation de compute pour décharger le parsing ICS dans un isolate
      final events = await compute(parseIcsEvents, response.body);

      return events;
    } catch (e) {
      debugPrint('Erreur: $e');
      throw Exception("Impossible de charger l'emploi du temps.");
    }
  }

  // Fonction pure appelée dans un isolate par compute
  static List<IcsEvent> parseIcsEvents(String icsContent) {
    tzdata.initializeTimeZones(); // nécessaire dans l'isolate
    final noumea = tz.getLocation('Pacific/Noumea');

    final calendar = ICalendar.fromString(icsContent);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final events =
        calendar.data
            .where(
              (item) =>
                  _getIgnoreCase(item, 'type')?.toString().toUpperCase() ==
                  'VEVENT',
            )
            .map((item) => IcsEvent.fromJson(item, noumea))
            .where(
              (e) =>
                  e.start != null &&
                  e.end != null &&
                  e.start!.isAfter(
                    todayStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  e.start!.isBefore(todayEnd),
            )
            .toList()
          ..sort((a, b) => a.start!.compareTo(b.start!));

    return events;
  }

  static dynamic _getIgnoreCase(Map map, String key) {
    for (final k in map.keys) {
      if (k.toString().toLowerCase() == key.toLowerCase()) {
        return map[k];
      }
    }
    return null;
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final format = DateFormat('dd/MM HH:mm');
    return format.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<IcsEvent>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun événement aujourd\'hui.'));
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                leading: const Icon(Icons.event_note),
                title: Text(e.summary ?? 'Sans titre'),
                subtitle: Text(
                  '${_formatDateTime(e.start)} → ${_formatDateTime(e.end)}\n${e.description}',
                  style: const TextStyle(fontSize: 13),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class IcsEvent {
  final String? summary;
  final String? description;
  final DateTime? start;
  final DateTime? end;

  IcsEvent({this.summary, this.description, this.start, this.end});

  factory IcsEvent.fromJson(Map<String, dynamic> json, tz.Location timezone) {
    dynamic getIgnoreCase(String key) {
      for (final k in json.keys) {
        if (k.toLowerCase() == key.toLowerCase()) return json[k];
      }
      return null;
    }

    DateTime? parseDate(dynamic value) {
      try {
        if (value is DateTime) return tz.TZDateTime.from(value, timezone);
        if (value is String) {
          if (value.contains('T')) {
            return tz.TZDateTime.from(DateTime.parse(value), timezone);
          } else if (value.length == 8) {
            final year = int.parse(value.substring(0, 4));
            final month = int.parse(value.substring(4, 6));
            final day = int.parse(value.substring(6, 8));
            return tz.TZDateTime(timezone, year, month, day);
          }
        }
      } catch (_) {}
      return null;
    }

    String? clean(String? text) {
      if (text == null) return null;
      return text.split('(')[0].trim();
    }

    return IcsEvent(
      summary: clean(getIgnoreCase('summary')?.toString()),
      description: clean(getIgnoreCase('description')?.toString()),
      start: parseDate(getIgnoreCase('dtstart')),
      end: parseDate(getIgnoreCase('dtend')),
    );
  }
}
