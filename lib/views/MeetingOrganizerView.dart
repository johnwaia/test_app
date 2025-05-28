import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../services/schedule_service.dart';
import '../models/ics_event.dart';

class MeetingOrganizerView extends StatefulWidget {
  const MeetingOrganizerView({super.key});

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

    try {
      final allEvents = await Future.wait(
        ids.map((id) => scheduleService.fetchSchedule(id, tzLocation)),
      );

      final now = DateTime.now();
      final days =
          List.generate(7, (i) => now.add(Duration(days: i)))
              .where(
                (day) =>
                    day.weekday >= DateTime.monday &&
                    day.weekday <= DateTime.friday,
              )
              .toList();

      final buffer = StringBuffer();
      const weekDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];

      for (final day in days) {
        final slotsLists =
            allEvents.map((events) => getFreeSlots(events, day)).toList();
        final common = intersectSlots(slotsLists);
        if (common.isNotEmpty) {
          buffer.writeln(
            "${weekDays[day.weekday - 1]} ${day.day}/${day.month} :",
          );
          for (final slot in common) {
            buffer.writeln("  - $slot");
          }
        }
      }

      setState(() {
        isLoading = false;
        resultText = buffer.isEmpty ? null : buffer.toString();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        resultText = "Erreur lors de la récupération des emplois du temps.";
      });
    }
  }

  List<Widget> _buildSlotsCards(String slotsText) {
    final lines = slotsText.split('\n');
    final cards = <Widget>[];
    String? currentDay;
    List<String> slots = [];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (!line.startsWith('  - ')) {
        if (currentDay != null && slots.isNotEmpty) {
          cards.add(_buildDayCard(currentDay, slots));
        }
        currentDay = line;
        slots = [];
      } else {
        slots.add(line.replaceFirst('  - ', ''));
      }
    }
    if (currentDay != null && slots.isNotEmpty) {
      cards.add(_buildDayCard(currentDay, slots));
    }
    return cards;
  }

  Widget _buildDayCard(String day, List<String> slots) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...slots.map((s) => Text(s, style: const TextStyle(fontSize: 15))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organiser une réunion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Choisissez le nombre d\'étudiants puis entrez les identifiants :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
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
              if (resultText != null) ..._buildSlotsCards(resultText!),
              if (!isLoading && resultText == null)
                const Text(
                  "Aucun créneau commun trouvé cette semaine (hors week-ends).",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeRange {
  final DateTime start;
  final DateTime end;
  TimeRange(this.start, this.end);

  @override
  String toString() =>
      "${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')} - "
      "${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}";
}
