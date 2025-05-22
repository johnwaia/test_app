import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
      debugShowCheckedModeBanner: false,
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
  String? _userId;
  final TextEditingController _controller = TextEditingController();
  late Future<List<IcsEvent>> _futureEvents;
  DateTime? _startOfWeek;
  DateTime? _endOfWeek;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitUserId() {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L’identifiant ne peut pas être vide")),
      );
      return;
    }

    final now = DateTime.now();
    _startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _endOfWeek = _startOfWeek!.add(const Duration(days: 7));

    setState(() {
      _userId = input;
      _futureEvents = _loadWeekEvents(_userId!);
    });
  }

  Future<List<IcsEvent>> _loadWeekEvents(String userId) async {
    final url =
        'http://applis.univ-nc.nc/cgi-bin/WebObjects/EdtWeb.woa/2/wa/default?login=$userId%2Fical';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP : ${response.statusCode}');
      }

      return _parseIcsEvents(response.body);
    } catch (e) {
      debugPrint("Erreur lors du chargement des événements : $e");
      throw Exception("Impossible de charger l'emploi du temps.");
    }
  }

  static List<IcsEvent> _parseIcsEvents(String icsContent) {
    final location = tz.getLocation('Pacific/Noumea');
    final calendar = ICalendar.fromString(icsContent);

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return calendar.data
        .where(
          (e) =>
              _getCaseInsensitive(e, 'type')?.toString().toUpperCase() ==
              'VEVENT',
        )
        .map((e) => IcsEvent.fromJson(e, location))
        .where(
          (e) =>
              e.start != null &&
              e.end != null &&
              !e.start!.isBefore(startOfWeek) &&
              e.start!.isBefore(endOfWeek),
        )
        .toList()
      ..sort((a, b) => a.start!.compareTo(b.start!));
  }

  static dynamic _getCaseInsensitive(Map map, String key) {
    return map.entries
        .firstWhere(
          (entry) => entry.key.toString().toLowerCase() == key.toLowerCase(),
          orElse: () => const MapEntry<String, dynamic>('', null),
        )
        .value;
  }

  String _formatTime(DateTime? dt) =>
      dt != null ? DateFormat('HH:mm').format(dt) : '';

  Map<String, List<IcsEvent>> _groupEventsByDay(List<IcsEvent> events) {
    final grouped = SplayTreeMap<String, List<IcsEvent>>();
    for (var e in events) {
      if (e.start == null) continue;
      final dayKey = DateFormat('EEEE dd/MM', 'fr_FR').format(e.start!);
      grouped.putIfAbsent(dayKey, () => []).add(e);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Veuillez entrer votre identifiant UNC :',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Identifiant',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _onSubmitUserId(),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _onSubmitUserId,
                child: const Text('Valider'),
              ),
            ],
          ),
        ),
      );
    }

    final String formattedStart = DateFormat('dd/MM').format(_startOfWeek!);
    final String formattedEnd = DateFormat(
      'dd/MM',
    ).format(_endOfWeek!.subtract(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.title} ($_userId) - Semaine $formattedStart → $formattedEnd',
        ),
      ),
      body: FutureBuilder<List<IcsEvent>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final events = snapshot.data;
          if (events == null || events.isEmpty) {
            return const Center(child: Text('Aucun événement cette semaine.'));
          }

          final groupedEvents = _groupEventsByDay(events);

          return ListView(
            children:
                groupedEvents.entries.map((entry) {
                  return ExpansionTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children:
                        entry.value.map((event) {
                          return ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(event.summary ?? 'Sans titre'),
                            subtitle: Text(
                              '${_formatTime(event.start)} → ${_formatTime(event.end)}\n${event.description ?? ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                  );
                }).toList(),
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

  factory IcsEvent.fromJson(Map<String, dynamic> json, tz.Location tzLocation) {
    String? getField(String key) {
      return json.entries
          .firstWhere(
            (e) => e.key.toString().toLowerCase() == key.toLowerCase(),
            orElse: () => const MapEntry<String, dynamic>('', null),
          )
          .value
          ?.toString();
    }

    DateTime? parseDate(String? value) {
      if (value == null) return null;
      try {
        if (value.contains('T')) {
          return tz.TZDateTime.from(DateTime.parse(value), tzLocation);
        } else if (value.length == 8) {
          final year = int.parse(value.substring(0, 4));
          final month = int.parse(value.substring(4, 6));
          final day = int.parse(value.substring(6, 8));
          return tz.TZDateTime(tzLocation, year, month, day);
        }
      } catch (_) {}
      return null;
    }

    String? clean(String? value) => value?.split('(')[0].trim();

    return IcsEvent(
      summary: clean(getField('summary')),
      description: clean(getField('description')),
      start: parseDate(getField('dtstart')),
      end: parseDate(getField('dtend')),
    );
  }
}
