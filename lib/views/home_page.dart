import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Gardé si vous prévoyez de l'utiliser ici plus tard
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Pour groupBy

// Importations de timezone si nécessaire pour le traitement direct des dates ici,
// sinon, assurez-vous que les dates dans IcsEvent sont déjà dans le bon fuseau horaire.
// import 'package:timezone/data/latest.dart' as tzdata;
// import 'package:timezone/timezone.dart' as tz;

import '../services/schedule_service.dart'; // Supposant que vous l'utiliserez pour charger les événements
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Pas besoin de _controller, _noumeaLocation, _scheduleService ici
  // si les événements sont déjà passés et correctement formatés.
  // Si vous devez charger les événements ici, gardez-les.

  Map<String, List<IcsEvent>> _groupedEvents = {};
  List<String> _daysWithEvents = [];

  @override
  void initState() {
    super.initState();
    // tzdata.initializeTimeZones(); // Initialisez dans main.dart
    // _noumeaLocation = tz.getLocation('Pacific/Noumea'); // Si besoin de convertir ici
    _groupAndSortEvents();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la liste d'événements peut changer dynamiquement après la construction initiale
    if (widget.events != oldWidget.events) {
      _groupAndSortEvents();
    }
  }

  void _groupAndSortEvents() {
    if (widget.events.isEmpty) {
      setState(() {
        _groupedEvents = {};
        _daysWithEvents = [];
      });
      return;
    }

    // Regrouper les événements par jour.
    // Assurez-vous que event.start est non null et dans le bon fuseau horaire.
    final grouped = groupBy(
      widget.events.where((event) => event.start != null),
          (IcsEvent event) => DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(event.start!),
    );

    // Trier les jours par ordre chronologique (les clés du map)
    final sortedDays = grouped.keys.toList()
      ..sort((a, b) {
        try {
          // Nous devons parser les clés de chaîne de caractères en DateTime pour les trier correctement
          final dateA = DateFormat('EEEE d MMMM yyyy', 'fr_FR').parse(a);
          final dateB = DateFormat('EEEE d MMMM yyyy', 'fr_FR').parse(b);
          return dateA.compareTo(dateB);
        } catch (e) {
          // En cas d'erreur de parsing (ne devrait pas arriver si le format est cohérent)
          return 0;
        }
      });

    // Créer un nouveau map trié
    final Map<String, List<IcsEvent>> sortedGroupedEvents = {
      for (var day in sortedDays) day: grouped[day]!
        ..sort((evA, evB) => evA.start!.compareTo(evB.start!)) // Trier les événements dans chaque jour
    };


    setState(() {
      _groupedEvents = sortedGroupedEvents;
      _daysWithEvents = sortedDays;
    });
  }

  // Fonction pour essayer d'extraire la salle de la description ou du résumé
  // CECI EST UN EXEMPLE ET DOIT ÊTRE ADAPTÉ À VOS DONNÉES ICS
  String _extractRoom(IcsEvent event) {
    String description = event.description?.toLowerCase() ?? '';
    String summary = event.summary?.toLowerCase() ?? '';
    String combinedText = '$summary $description'; // Combiner pour chercher dans les deux

    // Exemple de motifs (à adapter) :
    // - "Salle : AMITER"
    // - "Lieu : B201"
    // - "Amphi 80"
    // - "TD G102"
    RegExp sallePattern = RegExp(
        r'(salle\s*:\s*|lieu\s*:\s*|amphi\s*|td\s+)([a-z0-9\s\-]+)',
        caseSensitive: false
    );

    Match? match = sallePattern.firstMatch(combinedText);
    if (match != null && match.groupCount >= 2) {
      // Le groupe 2 devrait contenir le nom de la salle
      return match.group(2)!.trim().toUpperCase();
    }

    // Si aucun motif spécifique n'est trouvé, vous pouvez retourner une partie de la description
    // ou une valeur par défaut. Par exemple, si la salle est toujours à la fin de la description :
    // if (event.description != null && event.description!.contains("Salle")) {
    //   return event.description!.split("Salle").last.trim();
    // }

    return defaultLocationText; // Ou event.location si votre parser le remplit
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
          bottom: TabBar(
            isScrollable: true, // Permet de faire défiler les onglets s'ils sont nombreux
            tabs: _daysWithEvents.map((day) {
              // Pour afficher un format plus court dans l'onglet
              try {
                final date = DateFormat('EEEE d MMMM yyyy', 'fr_FR').parse(day);
                return Tab(text: DateFormat('EEE d/M', 'fr_FR').format(date));
              } catch (e) {
                return Tab(text: day); // Fallback
              }
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: _daysWithEvents.map((day) {
            final eventsForDay = _groupedEvents[day] ?? [];
            if (eventsForDay.isEmpty) {
              // Ne devrait pas arriver si _daysWithEvents est correctement peuplé
              return const Center(child: Text('Aucun cours ce jour.'));
            }
            return ListView.builder(
              itemCount: eventsForDay.length,
              itemBuilder: (context, index) {
                final event = eventsForDay[index];
                final String room = _extractRoom(event);

                // Assurez-vous que event.start est non null avant de le formater
                final String startTime = event.start != null
                    ? DateFormat('HH:mm', 'fr_FR').format(event.start!)
                    : 'Heure inconnue';
                final String endTime = event.end != null
                    ? DateFormat('HH:mm', 'fr_FR').format(event.end!)
                    : '';

                final String title = event.summary ?? 'Sans titre';
                final String description = event.description ?? '';

                return Card( // Utiliser des Card pour une meilleure séparation visuelle
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar( // Pour afficher l'heure de début de manière proéminente
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Text(
                        startTime.split(':')[0], // Juste l'heure
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$startTime ${endTime.isNotEmpty ? " - $endTime" : ""}'),
                        if (room != defaultLocationText)
                          Text('Salle : $room', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                        if (description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ),
                      ],
                    ),
                    isThreeLine: description.isNotEmpty || (room != defaultLocationText),
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