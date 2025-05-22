import 'package:flutter/material.dart';
// Gardé si vous prévoyez de l'utiliser ici plus tard
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Pour groupBy

// Importations de timezone si nécessaire pour le traitement direct des dates ici,
// sinon, assurez-vous que les dates dans IcsEvent sont déjà dans le bon fuseau horaire.
// import 'package:timezone/data/latest.dart' as tzdata;
// import 'package:timezone/timezone.dart' as tz;

// Supposant que vous l'utiliserez pour charger les événements
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
    if (widget.events != oldWidget.events) {
      _groupAndSortEvents();
    }
  }

  Color _getCourseColor(String summary) {
    summary = summary.toLowerCase();
    if (summary.contains('td')) {
      return Colors.green.shade300;
    } else if (summary.contains('cm')) {
      return const Color.fromARGB(255, 113, 180, 234);
    } else if (summary.contains('tp')) {
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
      6, // Lundi à Samedi (exclut Dimanche)
      (i) => startOfWeek.add(Duration(days: i)),
    );

    final grouped = groupBy(
      widget.events.where((e) => e.start != null),
      (IcsEvent event) => DateFormat('yyyy-MM-dd').format(event.start!),
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

  String _extractRoom(IcsEvent event) {
    String description = event.description?.toLowerCase() ?? '';
    String summary = event.summary?.toLowerCase() ?? '';
    String combinedText =
        '$summary $description'; // Combiner pour chercher dans les deux

    RegExp sallePattern = RegExp(
      r'(salle\s*:\s*|lieu\s*:\s*|amphi\s*|td\s+)([a-z0-9\s\-]+)',
      caseSensitive: false,
    );

    Match? match = sallePattern.firstMatch(combinedText);
    if (match != null && match.groupCount >= 2) {
      // Le groupe 2 devrait contenir le nom de la salle
      return match.group(2)!.trim().toUpperCase();
    }

    return defaultLocationText; // Ou event.location si votre parser le remplit
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Cas où il n'y a aucun événement
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
                // Barre de navigation pour changer de semaine
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

                // Onglets pour chaque jour avec événements
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
                        } catch (e) {
                          return Tab(text: day); // Fallback si parsing échoue
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

                // Aucun cours ce jour-là
                if (eventsForDay.isEmpty) {
                  return Center(
                    child: Text('Pas cours ce ${day.split(' ')[0]}'),
                  );
                }

                // Liste des événements du jour
                return ListView.builder(
                  itemCount: eventsForDay.length,
                  itemBuilder: (context, index) {
                    final event = eventsForDay[index];
                    final room = _extractRoom(event);

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
                            Text(
                              '$startTime${endTime.isNotEmpty ? ' - $endTime' : ''}',
                            ),
                            if (room != defaultLocationText)
                              Text(
                                'Salle : $room',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            if (description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine:
                            description.isNotEmpty ||
                            room != defaultLocationText,
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
