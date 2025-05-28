import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ics_event.dart';

class EventDetailsPage extends StatelessWidget {
  final IcsEvent event;

  const EventDetailsPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final start =
        event.start != null
            ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.start!)
            : 'Inconnu';
    final end =
        event.end != null
            ? DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(event.end!)
            : 'Inconnu';

    return Scaffold(
      appBar: AppBar(title: Text(event.summary ?? 'Détails de l\'événement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              event.summary ?? 'Sans titre',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Début : $start'),
            const SizedBox(height: 8),
            Text('Fin : $end'),
            const SizedBox(height: 8),
            Text('Salle : ${event.room ?? 'Non spécifiée'}'),
            const SizedBox(height: 8),
            Text('Enseignant : ${event.teacher ?? 'Non spécifié'}'),
          ],
        ),
      ),
    );
  }
}
