import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/ics_event.dart';
import '../utils/event_utils.dart';
import '../widgets/drawer_menu.dart';
import '../models/view_mode.dart';
import 'addpersonalEvent.dart';
import '../models/personalEvent.dart';
import 'MeetingOrganizerView.dart';

const String noEventsText = 'Aucun événement à venir.';
const String defaultRoomText = 'Salle non spécifiée';

class HomePage extends StatefulWidget {
  final String title;
  final List<IcsEvent> events;
  final String connectedStudentId;

  const HomePage({
    super.key,
    required this.title,
    required this.events,
    required this.connectedStudentId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<dynamic>> _groupedEvents = {};
  List<String> _daysWithEvents = [];
  DateTime _referenceDate = DateTime.now();
  ViewMode _currentView = ViewMode.week;
  List<PersonalEvent> _personalEvents = [];

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

    final personalGrouped = groupBy(
      _personalEvents,
      (PersonalEvent e) => DateFormat('yyyy-MM-dd').format(e.start),
    );

    final Map<String, List<dynamic>> result = {
      for (final day in weekDays)
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day): [
          ...(grouped[DateFormat('yyyy-MM-dd').format(day)] ?? []),
          ...(personalGrouped[DateFormat('yyyy-MM-dd').format(day)] ?? []),
        ]..sort((a, b) {
          final aStart = a is IcsEvent ? a.start! : a.start;
          final bStart = b is IcsEvent ? b.start! : b.start;
          return aStart.compareTo(bStart);
        }),
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

  void _onViewModeChange(ViewMode mode) {
    setState(() {
      _currentView = mode;
    });
    Navigator.pop(context); // Ferme le drawer
  }

  void _showAddPersonalEventView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AddPersonalEventView(
              onEventAdded: (title, start, end, desc) {
                setState(() {
                  _personalEvents.add(
                    PersonalEvent(
                      title: title,
                      start: start,
                      end: end,
                      description: desc,
                    ),
                  );
                  _groupEventsByDay();
                });
              },
            ),
      ),
    );
  }

  void _openMeetingOrganizer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeetingOrganizerView(
          connectedStudentId: widget.connectedStudentId,
          personalEvents: _personalEvents,
          onEventCreated: (event) {
            setState(() {
              _personalEvents.add(event);
              _groupEventsByDay();
            });
          },
        ),
      ),
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
                      _daysWithEvents.map((label) => Tab(text: label)).toList(),
                ),
              ],
            ),
          ),
        ),
        drawer: DrawerMenu(
          currentView: _currentView,
          onChange: _onViewModeChange,
          connectedStudentId: widget.connectedStudentId,
          onAddPersonalEvent: _showAddPersonalEventView,
          personalEvents: _personalEvents,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openMeetingOrganizer(context),
          child: const Icon(Icons.group_add),
          tooltip: 'Organiser une réunion',
        ),
        body: TabBarView(
          children:
              _daysWithEvents.map((dayLabel) {
                final events = _groupedEvents[dayLabel] ?? [];
                if (events.isEmpty) {
                  final weekday = dayLabel.split(' ').first;
                  return Center(child: Text('Pas de cours ce $weekday'));
                }

                final isMorning =
                    (DateTime d) =>
                        d.hour < 12 &&
                        (d.hour > 7 || (d.hour == 7 && d.minute >= 45));
                final isAfternoon = (DateTime d) => d.hour >= 12 && d.hour < 18;

                final morning =
                    events.where((e) {
                      final date = e is IcsEvent ? e.start : e.start;
                      return date != null && isMorning(date);
                    }).toList();

                final afternoon =
                    events.where((e) {
                      final date = e is IcsEvent ? e.start : e.start;
                      return date != null && isAfternoon(date);
                    }).toList();

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
                      ...morning.map(
                        (e) =>
                            e is IcsEvent
                                ? _EventCardDialog(event: e)
                                : _PersonalEventCard(event: e as PersonalEvent),
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
                      ...afternoon.map(
                        (e) =>
                            e is IcsEvent
                                ? _EventCardDialog(event: e)
                                : _PersonalEventCard(event: e as PersonalEvent),
                      ),
                    ],
                  ],
                );
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
      )
   );
  }
}

class _PersonalEventCard extends StatelessWidget {
  final PersonalEvent event;
  const _PersonalEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: event.type == EventType.meeting
            ? Colors.blue.shade100
            : Colors.green.shade100,
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
                    title: Text(event.title),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Début : ${DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.start)}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fin : ${DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.end)}',
                        ),
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
                    Icon(
                      event.type == EventType.meeting
                          ? Icons.groups
                          : Icons.event,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('HH:mm', 'fr_FR').format(event.start)} - ${DateFormat('HH:mm', 'fr_FR').format(event.end)}',
                      style: const TextStyle(fontSize: 14),
                    ),
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
