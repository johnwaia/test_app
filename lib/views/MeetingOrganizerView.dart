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

  final controller1 = TextEditingController();
  final controller2 = TextEditingController();

  String? resultText;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    scheduleService = ScheduleService(http.Client());
    tzdata.initializeTimeZones();
    tzLocation = tz.getLocation('Pacific/Noumea');
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
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

  List<TimeRange> intersectSlots(List<TimeRange> a, List<TimeRange> b) {
    List<TimeRange> result = [];
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

    final id1 = controller1.text.trim();
    final id2 = controller2.text.trim();

    try {
      final events1 = await scheduleService.fetchSchedule(id1, tzLocation);
      final events2 = await scheduleService.fetchSchedule(id2, tzLocation);

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
        final free1 = getFreeSlots(events1, day);
        final free2 = getFreeSlots(events2, day);
        final common = intersectSlots(free1, free2);
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
    List<Widget> cards = [];
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
                'Entrez les identifiants des deux étudiants :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller1,
                decoration: const InputDecoration(
                  labelText: 'Identifiant étudiant 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller2,
                decoration: const InputDecoration(
                  labelText: 'Identifiant étudiant 2',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),
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
