import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ics_event.dart';
import '../views/event_details.dart';
import '../utils/event_utils.dart'; // <-- Ajoute cet import

class EventCard extends StatelessWidget {
  final IcsEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final title = event.summary ?? 'Sans titre';
    final room = getFirstString(
      event.room,
      defaultValue: 'Salle non spécifiée',
    );
    final teacher = getFirstString(event.teacher);
    final start =
        event.start != null
            ? DateFormat('HH:mm', 'fr_FR').format(event.start!)
            : 'Heure inconnue';
    final end =
        event.end != null
            ? DateFormat('HH:mm', 'fr_FR').format(event.end!)
            : '';
    final color = getEventColor(title);
    final height =
        getDurationMinutes(event.start, event.end).clamp(60, 180).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      height: height,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsPage(event: event),
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
                        getCourseType(title),
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
                      child: Text(teacher, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.room, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(room, overflow: TextOverflow.ellipsis),
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
