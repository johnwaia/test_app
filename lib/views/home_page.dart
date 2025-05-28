import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/ics_event.dart';
import '../utils/event_utils.dart'; // <-- Ajoute cet import
import '../widgets/drawer_menu.dart';
import '../models/view_mode.dart'; // Ajoute cet import

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

    final teacher = getFirstString(event.teacher);
    final room = getFirstString(event.room, defaultValue: defaultRoomText);

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
  ViewMode _currentView = ViewMode.week; // Ajoute cette variable d'état
  late Map<String, List<IcsEvent>> _groupedEventsByWeek;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _groupEventsByDay();
    _groupEventsByWeek();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.events, oldWidget.events)) {
      _groupEventsByDay();
      _groupEventsByWeek();
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

  void _groupEventsByWeek() {
    _groupedEventsByWeek = groupBy(
      widget.events.where((e) => e.start != null),
      (IcsEvent e) => 'Semaine ${DateFormat('w').format(e.start!)}',
    );
  }

  void _navigateWeek(int offsetDays) {
    setState(() {
      _referenceDate = _referenceDate.add(Duration(days: offsetDays));
      _groupEventsByDay();
    });
  }

  void _onViewModeChange(ViewMode mode) {
    setState(() {
      _currentView = mode;
      // Tu peux ici regrouper les événements différemment si besoin
    });
    Navigator.pop(context); // Ferme le drawer
  }

  List<String> get _weeksOfMonth {
    // Génère les labels de semaines pour le mois courant, ex: ["Semaine 22", ...]
    final now = _referenceDate;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final weeks = <String>{};
    for (
      var d = firstDayOfMonth;
      d.isBefore(lastDayOfMonth) || d.isAtSameMomentAs(lastDayOfMonth);
      d = d.add(const Duration(days: 1))
    ) {
      final weekStr = DateFormat('w').format(d);
      final weekNum = int.tryParse(weekStr);
      if (weekNum != null) {
        weeks.add('Semaine $weekNum');
      }
    }
    return weeks.toList();
  }

  // Fonction pour obtenir les jours d'une semaine donnée
  List<String> _getDaysOfWeek(String weekLabel) {
    // Extrait le numéro de semaine et retourne la liste des jours de cette semaine
    final weekNum =
        int.tryParse(weekLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final year = _referenceDate.year;
    final firstDayOfYear = DateTime(year, 1, 1);
    final firstWeekDay = firstDayOfYear.add(Duration(days: (weekNum - 1) * 7));
    return List.generate(7, (i) {
      final day = firstWeekDay.add(Duration(days: i));
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day);
    });
  }

  List<DateTime> get _daysOfCurrentMonth {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return List.generate(
      lastDay.day,
      (i) => DateTime(_selectedMonth.year, _selectedMonth.month, i + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty || _daysWithEvents.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text(noEventsText)),
      );
    }

    final tabs =
        _currentView == ViewMode.week
            ? _daysWithEvents
            : ['Mois']; // Un seul tab pour le mois

    return DefaultTabController(
      length: tabs.length,
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
                  tabs: tabs.map((label) => Tab(text: label)).toList(),
                ),
              ],
            ),
          ),
        ),
        drawer: DrawerMenu(
          currentView: _currentView,
          onChange: _onViewModeChange,
        ),
        body: TabBarView(
          children:
              tabs.map((tabLabel) {
                if (_currentView == ViewMode.week) {
                  // Affichage classique semaine (jours, matin/après-midi)
                  final events = _groupedEvents[tabLabel] ?? [];

                  if (events.isEmpty) {
                    final weekday = tabLabel.split(' ').first;
                    return Center(child: Text('Pas de cours ce $weekday'));
                  }

                  final isMorning =
                      (DateTime d) =>
                          d.hour < 12 &&
                          (d.hour > 7 || (d.hour == 7 && d.minute >= 45));
                  final isAfternoon =
                      (DateTime d) => d.hour >= 12 && d.hour < 18;

                  final morning =
                      events
                          .where((e) => e.start != null && isMorning(e.start!))
                          .toList();
                  final afternoon =
                      events
                          .where(
                            (e) => e.start != null && isAfternoon(e.start!),
                          )
                          .toList();

                  // Combine les sections dans un seul ListView pour de meilleures perfs
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (morning.isNotEmpty) ...[
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: morning.length,
                          itemBuilder: (context, i) {
                            final e = morning[i];
                            return _EventCardDialog(event: e);
                          },
                        ),
                      ],
                      if (afternoon.isNotEmpty) ...[
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: afternoon.length,
                          itemBuilder: (context, i) {
                            final e = afternoon[i];
                            return _EventCardDialog(event: e);
                          },
                        ),
                      ],
                    ],
                  );
                } else {
                  // Affichage mois : chaque tab = une semaine, séparé par jours
                  final eventsOfWeek = _groupedEventsByWeek[tabLabel] ?? [];
                  final daysOfWeek = _getDaysOfWeek(tabLabel); // à implémenter
                  return ListView(
                    children:
                        daysOfWeek.map((day) {
                          final eventsOfDay =
                              eventsOfWeek
                                  .where(
                                    (e) =>
                                        DateFormat(
                                          'EEEE d MMMM yyyy',
                                          'fr_FR',
                                        ).format(e.start!) ==
                                        day,
                                  )
                                  .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...eventsOfDay
                                  .map((e) => _EventCardDialog(event: e))
                                  .toList(),
                            ],
                          );
                        }).toList(),
                  );
                }
              }).toList(),
        ),
      ),
    );
  }
}

class _EventCardDialog extends StatelessWidget {
  final IcsEvent event;
  const _EventCardDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final title = event.summary ?? 'Sans titre';
    final room = getFirstString(event.room, defaultValue: defaultRoomText);
    final teacher = getFirstString(event.teacher);
    final color = getEventColor(title);
    final courseType = getCourseType(title);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: color,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(title),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Professeur : $teacher'),
                        const SizedBox(height: 8),
                        Text(
                          'Début : ${event.start != null ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.start!) : "Heure inconnue"}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fin : ${event.end != null ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.end!) : "Heure inconnue"}',
                        ),
                        const SizedBox(height: 8),
                        Text('Salle : $room'),
                        if (event.description?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Description :\n${event.description}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'event-${event.summary}',
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
                        courseType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.black87,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${event.start != null ? DateFormat('HH:mm', 'fr_FR').format(event.start!) : ''} - ${event.end != null ? DateFormat('HH:mm', 'fr_FR').format(event.end!) : ''}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        teacher,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.room, size: 16),
                    const SizedBox(width: 6),
                    Text(room, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
