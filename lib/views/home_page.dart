import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/ics_event.dart';

const String noEventsText = 'Aucun événement à venir.';
const String defaultRoomText = 'Salle non spécifiée';

class HomePage extends StatefulWidget {
  final String title;
  final List<IcsEvent> events;

  const HomePage({super.key, required this.title, required this.events});

  @override
  State<HomePage> createState() => _HomePageState();
}

class EventDetailsPage extends StatelessWidget {
  final IcsEvent event;

  const EventDetailsPage({super.key, required this.event});

  String _getFirstString(dynamic value, {String defaultValue = 'Inconnu'}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List && value.isNotEmpty && value.first is String) {
      final first = value.first.trim();
      return first.isNotEmpty ? first : defaultValue;
    }
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final start =
        event.start != null
            ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.start!)
            : 'Heure inconnue';
    final end =
        event.end != null
            ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.end!)
            : 'Heure inconnue';

    final teacher = _getFirstString(event.teacher);
    final room = _getFirstString(event.room, defaultValue: defaultRoomText);

    return Scaffold(
      appBar: AppBar(title: Text(event.summary ?? 'Détails du cours')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nom : ${event.summary ?? "Sans titre"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Professeur : $teacher', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Début : $start', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Fin : $end', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Salle : $room', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            if (event.description?.isNotEmpty ?? false)
              Text(
                'Description :\n${event.description}',
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Map<String, List<IcsEvent>> _groupedEvents = {};
  List<String> _daysWithEvents = [];
  DateTime _referenceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _groupEventsByDay();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.events, oldWidget.events)) {
      _groupEventsByDay();
    }
  }

  void _groupEventsByDay() {
    final startOfWeek = _referenceDate.subtract(
      Duration(days: _referenceDate.weekday - 1),
    );
    final weekDays = List.generate(
      6,
      (i) => startOfWeek.add(Duration(days: i)),
    );

    final grouped = groupBy(
      widget.events.where((e) => e.start != null),
      (IcsEvent e) => DateFormat('yyyy-MM-dd').format(e.start!),
    );

    final Map<String, List<IcsEvent>> result = {
      for (final day in weekDays)
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day):
            (grouped[DateFormat('yyyy-MM-dd').format(day)] ?? [])
              ..sort((a, b) => a.start!.compareTo(b.start!)),
    };

    setState(() {
      _groupedEvents = result;
      _daysWithEvents = result.keys.toList();
    });
  }

  void _navigateWeek(int offsetDays) {
    setState(() {
      _referenceDate = _referenceDate.add(Duration(days: offsetDays));
      _groupEventsByDay();
    });
  }

  int _getDurationMinutes(IcsEvent event) {
    if (event.start != null && event.end != null) {
      return event.end!.difference(event.start!).inMinutes;
    }
    return 30;
  }

  String _getFirstString(dynamic value, {String defaultValue = 'Inconnu'}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List && value.isNotEmpty && value.first is String) {
      final first = value.first.trim();
      return first.isNotEmpty ? first : defaultValue;
    }
    return defaultValue;
  }

  Color _getEventColor(String summary) {
    final s = summary.toLowerCase();
    if (s.contains('td')) return Colors.green.shade300;
    if (s.contains('cm')) return const Color(0xFF71B4EA);
    if (s.contains('tp')) return const Color(0xFFE8AC52);
    return Colors.grey.shade300;
  }

  String _getCourseType(String summary) {
    final s = summary.toLowerCase();
    if (s.contains('td')) return 'TD';
    if (s.contains('cm')) return 'CM';
    if (s.contains('tp')) return 'TP';
    return 'Autre';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty || _daysWithEvents.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text(noEventsText)),
      );
    }

    return DefaultTabController(
      length: _daysWithEvents.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(96),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _navigateWeek(-7),
                      ),
                      Text(
                        'Semaine du ${DateFormat('d MMMM', 'fr_FR').format(_referenceDate.subtract(Duration(days: _referenceDate.weekday - 1)))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _navigateWeek(7),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabs:
                      _daysWithEvents.map((day) {
                        try {
                          final parsed = DateFormat(
                            'EEEE d MMMM yyyy',
                            'fr_FR',
                          ).parse(day);
                          return Tab(
                            text: DateFormat('EEE d/M', 'fr_FR').format(parsed),
                          );
                        } catch (_) {
                          return Tab(text: day);
                        }
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children:
              _daysWithEvents.map((day) {
                final events = _groupedEvents[day] ?? [];

                if (events.isEmpty) {
                  final weekday = day.split(' ').first;
                  return Center(child: Text('Pas de cours ce $weekday'));
                }

                final isMorning =
                    (DateTime d) =>
                        d.hour < 12 &&
                        (d.hour > 7 || (d.hour == 7 && d.minute >= 45));
                final isAfternoon = (DateTime d) => d.hour >= 12 && d.hour < 18;

                final morning =
                    events
                        .where((e) => e.start != null && isMorning(e.start!))
                        .toList();
                final afternoon =
                    events
                        .where((e) => e.start != null && isAfternoon(e.start!))
                        .toList();

                Widget buildEventCards(List<IcsEvent> list) {
                  if (list.isEmpty)
                    return const Center(child: Text('Aucun cours'));

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      final title = e.summary ?? 'Sans titre';
                      final room = _getFirstString(
                        e.room,
                        defaultValue: defaultRoomText,
                      );
                      final teacher = _getFirstString(e.teacher);
                      final start =
                          e.start != null
                              ? DateFormat('HH:mm', 'fr_FR').format(e.start!)
                              : 'Heure inconnue';
                      final end =
                          e.end != null
                              ? DateFormat('HH:mm', 'fr_FR').format(e.end!)
                              : '';
                      final color = _getEventColor(title);
                      final height =
                          (_getDurationMinutes(e) * 3)
                              .clamp(60, 180)
                              .toDouble();

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        height: height,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: color,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailsPage(event: e),
                                  ),
                                ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Hero(
                                          tag: 'event-${e.summary}',
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          _getCourseType(title),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.black12,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 16),
                                      const SizedBox(width: 4),
                                      Text('$start - $end'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          teacher,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.room, size: 16),
                                      const SizedBox(width: 4),
                                      Text(room),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Matin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      buildEventCards(morning),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Après-midi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      buildEventCards(afternoon),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
