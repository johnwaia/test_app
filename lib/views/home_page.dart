import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../models/ics_event.dart';

const String noEventsText = 'Aucun événement à venir.';
const String defaultLocationText = 'Salle non spécifiée';

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

  @override
  Widget build(BuildContext context) {
    final startTime =
        event.start != null
            ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.start!)
            : 'Heure inconnue';

    final endTime =
        event.end != null
            ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.end!)
            : 'Heure inconnue';

    final professor =
        event.teacher?.trim().isNotEmpty == true ? event.teacher! : 'Inconnu';
    final room =
        event.room?.trim().isNotEmpty == true
            ? event.room!
            : defaultLocationText;

    return Scaffold(
      appBar: AppBar(title: Text(event.summary ?? 'Détails du cours')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nom : ${event.summary ?? "Sans titre"}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Professeur : $professor',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text('Début : $startTime', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Fin : $endTime', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Salle : $room', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            if (event.description != null && event.description!.isNotEmpty)
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
    _groupAndSortEvents();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.events, oldWidget.events)) {
      _groupAndSortEvents();
    }
  }

  Color _getCourseColor(String summary) {
    final s = summary.toLowerCase();
    if (s.contains('td')) {
      return Colors.green.shade300;
    } else if (s.contains('cm')) {
      return const Color.fromARGB(255, 113, 180, 234);
    } else if (s.contains('tp')) {
      return const Color.fromARGB(255, 232, 172, 82);
    } else {
      return Colors.grey.shade300;
    }
  }

  void _groupAndSortEvents() {
    final startOfWeek = _referenceDate.subtract(
      Duration(days: _referenceDate.weekday - 1),
    );
    final daysOfWeek = List.generate(
      6,
      (i) => startOfWeek.add(Duration(days: i)),
    );

    final grouped = groupBy(
      widget.events.where((e) => e.start != null),
      (IcsEvent e) => DateFormat('yyyy-MM-dd').format(e.start!),
    );

    final Map<String, List<IcsEvent>> fullWeekEvents = {};
    for (var day in daysOfWeek) {
      final key = DateFormat('yyyy-MM-dd').format(day);
      final displayKey = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day);
      final events = grouped[key] ?? [];
      events.sort((a, b) => a.start!.compareTo(b.start!));
      fullWeekEvents[displayKey] = events;
    }

    setState(() {
      _groupedEvents = fullWeekEvents;
      _daysWithEvents = fullWeekEvents.keys.toList();
    });
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
            preferredSize: const Size.fromHeight(96.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _referenceDate = _referenceDate.subtract(
                              const Duration(days: 7),
                            );
                            _groupAndSortEvents();
                          });
                        },
                      ),
                      Text(
                        'Semaine du ${DateFormat('d MMMM', 'fr_FR').format(_referenceDate.subtract(Duration(days: _referenceDate.weekday - 1)))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _referenceDate = _referenceDate.add(
                              const Duration(days: 7),
                            );
                            _groupAndSortEvents();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabs:
                      _daysWithEvents.map((day) {
                        try {
                          final parsedDate = DateFormat(
                            'EEEE d MMMM yyyy',
                            'fr_FR',
                          ).parse(day);
                          return Tab(
                            text: DateFormat(
                              'EEE d/M',
                              'fr_FR',
                            ).format(parsedDate),
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
                final eventsForDay = _groupedEvents[day] ?? [];

                if (eventsForDay.isEmpty) {
                  return Center(
                    child: Text('Pas cours ce ${day.split(' ')[0]}'),
                  );
                }

                return ListView.builder(
                  itemCount: eventsForDay.length,
                  itemBuilder: (context, index) {
                    final event = eventsForDay[index];

                    final room =
                        event.room?.trim().isNotEmpty == true
                            ? event.room!
                            : defaultLocationText;
                    final professor =
                        event.teacher?.trim().isNotEmpty == true
                            ? event.teacher!
                            : 'Inconnu';

                    final startTime =
                        event.start != null
                            ? DateFormat('HH:mm', 'fr_FR').format(event.start!)
                            : 'Heure inconnue';
                    final endTime =
                        event.end != null
                            ? DateFormat('HH:mm', 'fr_FR').format(event.end!)
                            : '';

                    final title = event.summary ?? 'Sans titre';
                    final description = event.description ?? '';
                    final color = _getCourseColor(title);

                    return Card(
                      color: color,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(title),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Professeur : $professor'),
                                      const SizedBox(height: 8),
                                      Text('Début : $startTime'),
                                      Text('Fin : $endTime'),
                                      const SizedBox(height: 8),
                                      Text('Salle : $room'),
                                      if (description.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Text('Description :'),
                                        Text(description),
                                      ],
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          child: Text(
                            startTime.split(':')[0],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$startTime - $endTime'),
                            Text('Salle : $room'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
        ),
      ),
    );
  }
}
