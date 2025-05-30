import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../services/schedule_service.dart';
import '../models/ics_event.dart';
import '../models/time_range.dart';
import '../models/personalEvent.dart';

class MeetingOrganizerView extends StatefulWidget {
  final String connectedStudentId;
  final List<PersonalEvent> personalEvents; // <-- AJOUTE cette ligne

  const MeetingOrganizerView({
    super.key,
    required this.connectedStudentId,
    required this.personalEvents, // <-- AJOUTE cette ligne
  });

  @override
  State<MeetingOrganizerView> createState() => _MeetingOrganizerViewState();
}

class _MeetingOrganizerViewState extends State<MeetingOrganizerView> {
  late final ScheduleService scheduleService;
  late final tz.Location tzLocation;

  int studentCount = 2;
  final List<TextEditingController> controllers = [];

  String? resultText;
  bool isLoading = false;

  List<String> _tabLabels = [];
  Map<String, List<TimeRange>> _daySlots = {};

  DateTime _referenceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    scheduleService = ScheduleService(http.Client());
    tzdata.initializeTimeZones();
    tzLocation = tz.getLocation('Pacific/Noumea');
    _updateControllers();
  }

  void _updateControllers() {
    while (controllers.length < studentCount) {
      controllers.add(TextEditingController());
    }
    while (controllers.length > studentCount) {
      controllers.removeLast().dispose();
    }

    if (controllers.isNotEmpty) {
      controllers[0].text = widget.connectedStudentId;
    }
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<TimeRange> getFreeSlots(List<IcsEvent> events, DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day, 8, 0);
    final endOfDay = DateTime(day.year, day.month, day.day, 18, 0);

    final dayEvents =
        events
            .where(
              (e) =>
                  e.start != null &&
                  e.start!.year == day.year &&
                  e.start!.month == day.month &&
                  e.start!.day == day.day,
            )
            .toList()
          ..sort((a, b) => a.start!.compareTo(b.start!));

    List<TimeRange> free = [];
    DateTime current = startOfDay;
    for (final e in dayEvents) {
      if (current.isBefore(e.start!)) {
        free.add(TimeRange(current, e.start!));
      }
      if (current.isBefore(e.end!)) {
        current = e.end!;
      }
    }
    if (current.isBefore(endOfDay)) {
      free.add(TimeRange(current, endOfDay));
    }
    return free;
  }

  List<TimeRange> intersectSlots(List<List<TimeRange>> slotsLists) {
    if (slotsLists.isEmpty) return [];
    var result = slotsLists.first;
    for (int i = 1; i < slotsLists.length; i++) {
      result = _intersectTwo(result, slotsLists[i]);
      if (result.isEmpty) break;
    }
    return result;
  }

  List<TimeRange> _intersectTwo(List<TimeRange> a, List<TimeRange> b) {
    final result = <TimeRange>[];
    for (final slotA in a) {
      for (final slotB in b) {
        final start =
            slotA.start.isAfter(slotB.start) ? slotA.start : slotB.start;
        final end = slotA.end.isBefore(slotB.end) ? slotA.end : slotB.end;
        if (start.isBefore(end)) {
          result.add(TimeRange(start, end));
        }
      }
    }
    return result;
  }

  Future<void> findCommonSlots() async {
    setState(() {
      isLoading = true;
      resultText = null;
      _tabLabels = [];
      _daySlots = {};
    });

    final ids =
        controllers
            .map((c) => c.text.trim())
            .where((id) => id.isNotEmpty)
            .toList();

    if (ids.length != studentCount) {
      setState(() {
        isLoading = false;
        resultText = "Veuillez renseigner tous les identifiants.";
      });
      return;
    }

    final idsSet = ids.toSet();
    if (idsSet.length != ids.length) {
      setState(() {
        isLoading = false;
        resultText = "Chaque identifiant doit être unique.";
      });
      return;
    }

    try {
      final allEvents = await Future.wait(
        ids.map((id) => scheduleService.fetchSchedule(id, tzLocation)),
      );

      final now = DateTime.now();
      final monday = now.subtract(
        Duration(days: now.weekday - DateTime.monday),
      );
      final days = List.generate(5, (i) => monday.add(Duration(days: i)));

      final Map<String, List<TimeRange>> daySlots = {};
      final List<String> tabLabels = [];
      const weekDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];

      for (int i = 0; i < days.length; i++) {
        final day = days[i];
        final slotsLists =
            allEvents.map((events) => getFreeSlots(events, day)).toList();
        final common = intersectSlots(slotsLists);
        final label = "${weekDays[i]} ${day.day}/${day.month}";
        tabLabels.add(label);
        daySlots[label] = common;
      }

      setState(() {
        isLoading = false;
        _tabLabels = tabLabels;
        _daySlots = daySlots;
        resultText = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        resultText = "Erreur lors de la récupération des emplois du temps.";
      });
    }
  }

  void _navigateWeek(int days) {
    setState(() {
      _referenceDate = _referenceDate.add(Duration(days: days));
    });
    findCommonSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organiser une réunion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Nombre d\'étudiants :',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: studentCount,
                    items:
                        List.generate(6, (i) => i + 2)
                            .map(
                              (n) =>
                                  DropdownMenuItem(value: n, child: Text('$n')),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          studentCount = val;
                          _updateControllers();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(
                studentCount,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      labelText: 'Identifiant étudiant ${i + 1}',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Trouver les créneaux communs'),
                onPressed: isLoading ? null : findCommonSlots,
              ),
              const SizedBox(height: 32),
              if (isLoading) const CircularProgressIndicator(),
              if (_tabLabels.isNotEmpty)
                DefaultTabController(
                  length: _tabLabels.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      TabBar(
                        isScrollable: true,
                        tabs:
                            _tabLabels
                                .map((label) => Tab(text: label))
                                .toList(),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: TabBarView(
                          children:
                              _tabLabels.map((dayLabel) {
                                final slots = subtractPersonalEvents(
                                  _daySlots[dayLabel] ?? [],
                                  widget.personalEvents,
                                );
                                if (slots.isEmpty) {
                                  final weekday = dayLabel.split(' ').first;
                                  return Center(
                                    child: Text(
                                      'Pas de créneau commun ce $weekday',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  );
                                }

                                final isMorning =
                                    (DateTime d) =>
                                        d.hour < 12 &&
                                        (d.hour > 7 ||
                                            (d.hour == 7 && d.minute >= 45));
                                final isAfternoon =
                                    (DateTime d) => d.hour >= 12 && d.hour < 18;

                                final morning =
                                    slots
                                        .where((tr) => isMorning(tr.start))
                                        .toList();
                                final afternoon =
                                    slots
                                        .where((tr) => isAfternoon(tr.start))
                                        .toList();

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
                                        (tr) => _CommonSlotCard(
                                          start: tr.start,
                                          end: tr.end,
                                        ),
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
                                        (tr) => _CommonSlotCard(
                                          start: tr.start,
                                          end: tr.end,
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isLoading && _tabLabels.isEmpty && resultText != null)
                Text(
                  resultText!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommonSlotsView extends StatelessWidget {
  final List<String> tabLabels;
  final Map<String, List<TimeRange>> daySlots;

  const CommonSlotsView({
    super.key,
    required this.tabLabels,
    required this.daySlots,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabLabels.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabs: tabLabels.map((label) => Tab(text: label)).toList(),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: TabBarView(
              children:
                  tabLabels.map((dayLabel) {
                    final slots = daySlots[dayLabel] ?? [];
                    if (slots.isEmpty) {
                      final weekday = dayLabel.split(' ').first;
                      return Center(
                        child: Text(
                          'Pas de créneau commun ce $weekday',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final isMorning =
                        (DateTime d) =>
                            d.hour < 12 &&
                            (d.hour > 7 || (d.hour == 7 && d.minute >= 45));
                    final isAfternoon =
                        (DateTime d) => d.hour >= 12 && d.hour < 18;

                    final morning =
                        slots.where((tr) => isMorning(tr.start)).toList();
                    final afternoon =
                        slots.where((tr) => isAfternoon(tr.start)).toList();

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
                            (tr) =>
                                _CommonSlotCard(start: tr.start, end: tr.end),
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
                            (tr) =>
                                _CommonSlotCard(start: tr.start, end: tr.end),
                          ),
                        ],
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommonSlotCard extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  const _CommonSlotCard({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        color: Colors.blue.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
                    '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Créneau commun disponible",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool isSlotAvailable(
  DateTime slotStart,
  DateTime slotEnd,
  List<PersonalEvent> personalEvents,
) {
  for (final event in personalEvents) {
    if (slotStart.isBefore(event.end) && slotEnd.isAfter(event.start)) {
      // Le créneau chevauche un événement personnel
      return false;
    }
  }
  return true;
}

List<TimeRange> subtractPersonalEvents(
  List<TimeRange> slots,
  List<PersonalEvent> personalEvents,
) {
  List<TimeRange> result = [];
  for (final slot in slots) {
    // Commence avec le créneau complet
    List<TimeRange> current = [slot];
    for (final event in personalEvents) {
      List<TimeRange> next = [];
      for (final range in current) {
        // Si pas de chevauchement, on garde tel quel
        if (event.end.isBefore(range.start) || event.start.isAfter(range.end)) {
          next.add(range);
        } else {
          // Découpe à gauche
          if (event.start.isAfter(range.start)) {
            next.add(TimeRange(range.start, event.start));
          }
          // Découpe à droite
          if (event.end.isBefore(range.end)) {
            next.add(TimeRange(event.end, range.end));
          }
        }
      }
      current = next;
    }
    result.addAll(current);
  }
  return result;
}
