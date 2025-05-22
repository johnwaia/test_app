import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import pour l'initialisation des locales
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Constantes
const String appTitle = 'EDT UNC';
const String homePageTitle = 'Emploi du temps UNC';
const String noumeaTimeZone = 'Pacific/Noumea';
const String icsTypeVEvent = 'VEVENT';
const String defaultErrorMessage = "Impossible de charger l'emploi du temps.";
const String networkErrorMessage = "Erreur de connexion. Veuillez vérifier votre accès internet.";
const String timeoutErrorMessage = "La requête a mis trop de temps à répondre. Veuillez réessayer.";
const String userIdPrompt = 'Veuillez entrer votre identifiant UNC :';
const String userIdLabel = 'Identifiant';
const String submitButtonText = 'Valider';
const String noEventsText = 'Aucun événement cette semaine.';
const String errorTextPrefix = 'Erreur : ';
const String emptyIdErrorText = 'L’identifiant ne peut pas être vide';

void main() async {
  // Assurer l'initialisation des bindings Flutter si des opérations asynchrones
  // sont effectuées avant runApp (comme initializeDateFormatting)
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  // Initialiser les données de localisation pour le français
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(title: homePageTitle),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userId;
  final TextEditingController _controller = TextEditingController();
  Future<List<IcsEvent>>? _futureEvents; // Nullable pour l'état initial
  late final tz.Location _noumeaLocation;
  late DateTime _startOfWeek;
  late DateTime _endOfWeek;

  late final ScheduleService _scheduleService;

  @override
  void initState() {
    super.initState();
    _noumeaLocation = tz.getLocation(noumeaTimeZone);
    _scheduleService = ScheduleService(http.Client());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitUserId() {
    final String input = _controller.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(emptyIdErrorText)),
      );
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(_noumeaLocation);
    // Calcul pour que le lundi soit le premier jour de la semaine
    _startOfWeek = tz.TZDateTime(_noumeaLocation, now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    _endOfWeek = _startOfWeek.add(const Duration(days: 7));

    setState(() {
      _userId = input;
      _futureEvents = _scheduleService.fetchWeekEvents(
          _userId!, _noumeaLocation, _startOfWeek, _endOfWeek);
    });
  }

  String _formatTime(DateTime? dt) =>
      dt != null ? DateFormat('HH:mm', 'fr_FR').format(dt) : '';

  Map<String, List<IcsEvent>> _groupEventsByDay(List<IcsEvent> events) {
    final SplayTreeMap<String, List<IcsEvent>> grouped =
    SplayTreeMap<String, List<IcsEvent>>();
    for (final IcsEvent event in events) {
      if (event.start == null) continue;
      // Capitaliser la première lettre du jour pour une meilleure présentation
      final String dayKey = DateFormat('EEEE dd/MM', 'fr_FR')
          .format(event.start!)
          .capitalizeFirstLetter();
      grouped.putIfAbsent(dayKey, () => []).add(event);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null || _futureEvents == null) {
      return UserIdInputView(
        controller: _controller,
        onSubmit: _onSubmitUserId,
        title: widget.title,
      );
    }

    final String formattedStart = DateFormat('dd/MM').format(_startOfWeek);
    final String formattedEnd = DateFormat('dd/MM')
        .format(_endOfWeek.subtract(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.title} ($_userId) - Sem. $formattedStart → $formattedEnd',
        ),
      ),
      body: FutureBuilder<List<IcsEvent>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('$errorTextPrefix${snapshot.error}',
                      textAlign: TextAlign.center),
                ));
          }

          final List<IcsEvent>? events = snapshot.data;
          if (events == null || events.isEmpty) {
            return const Center(child: Text(noEventsText));
          }

          final Map<String, List<IcsEvent>> groupedEvents =
          _groupEventsByDay(events);

          return ListView(
            children: groupedEvents.entries.map((entry) {
              return ExpansionTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: true,
                children: entry.value.map((event) {
                  return ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(event.summary ?? 'Sans titre'),
                    subtitle: Text(
                      '${_formatTime(event.start)} → ${_formatTime(event.end)}\n${event.description ?? ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    isThreeLine: (event.description ?? '').isNotEmpty,
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class UserIdInputView extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String title;

  const UserIdInputView({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              userIdPrompt,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: userIdLabel,
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.center,
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onSubmit,
              child: const Text(submitButtonText),
            ),
          ],
        ),
      ),
    );
  }
}

class IcsEvent {
  final String? summary;
  final String? description;
  final DateTime? start;
  final DateTime? end;

  IcsEvent({
    this.summary,
    this.description,
    this.start,
    this.end,
  });

  factory IcsEvent.fromJson(
      Map<String, dynamic> json, tz.Location tzLocation) {
    // Fonction utilitaire pour obtenir un champ en ignorant la casse
    dynamic getField(String key) { // Notez que le type de retour est dynamic ici
      return json.entries
          .firstWhere(
            (e) => e.key.toString().toLowerCase() == key.toLowerCase(),
        orElse: () => const MapEntry<String, dynamic>('', null),
      )
          .value; // On retourne directement la valeur, sans .toString()
    }

    // Fonction utilitaire pour parser les dates de l'ICS
    DateTime? parseDate(dynamic fieldValue) { // Accepte dynamic
      if (fieldValue == null) return null;

      String? dateString;

      // Vérifier si fieldValue est un IcsDateTime et extraire la date
      if (fieldValue is IcsDateTime) {
        dateString = fieldValue.dt; // Accéder directement à la propriété 'dt'
      } else if (fieldValue is String) {
        dateString = fieldValue;
      } else {
        // Si ce n'est ni un IcsDateTime ni une String, on ne peut pas le parser
        debugPrint("Type de date inattendu: ${fieldValue.runtimeType} pour la valeur: $fieldValue");
        return null;
      }

      if (dateString == null || dateString.isEmpty) return null;

      try {
        // Format avec heure (ex: 20231026T080000Z ou 20231026T100000)
        if (dateString.contains('T')) {
          if (dateString.endsWith('Z')) {
            // La date est déjà en UTC
            return tz.TZDateTime.parse(tzLocation, dateString);
          } else {
            // La date est "flottante" ou dans un format local, la parser puis l'associer au fuseau horaire
            // DateTime.parse peut gérer des formats comme "20231026T100000"
            // Ensuite, on crée un TZDateTime à partir de ça dans le fuseau horaire de Nouméa
            final DateTime localDateTime = DateTime.parse(dateString);
            return tz.TZDateTime.from(localDateTime, tzLocation);
          }
        }
        // Format date seule (ex: 20231026)
        else if (dateString.length == 8) {
          final int year = int.parse(dateString.substring(0, 4));
          final int month = int.parse(dateString.substring(4, 6));
          final int day = int.parse(dateString.substring(6, 8));
          return tz.TZDateTime(tzLocation, year, month, day);
        }
      } catch (e) {
        debugPrint("Erreur de parsing de la chaîne de date '$dateString': $e");
        return null;
      }
      debugPrint("Format de date non reconnu pour la chaîne: '$dateString'");
      return null;
    }

    // Nettoie les chaînes en enlevant ce qui suit une parenthèse (spécifique aux données UNC)
    String? clean(String? value) => value?.split('(')[0].trim();

    // On récupère les champs 'summary' et 'description' comme String
    String? summaryValue = getField('summary')?.toString();
    String? descriptionValue = getField('description')?.toString();

    return IcsEvent(
      summary: clean(summaryValue),
      description: clean(descriptionValue),
      start: parseDate(getField('dtstart')), // Passer directement la valeur du champ
      end: parseDate(getField('dtend')),     // Passer directement la valeur du champ
    );
  }
}

class ScheduleService {
  final http.Client _client;
  ScheduleService(this._client);

  Future<List<IcsEvent>> fetchWeekEvents(String userId,
      tz.Location location, DateTime startOfWeek, DateTime endOfWeek) async {
    final String encodedUserId = Uri.encodeComponent(userId);
    final Uri url = Uri.parse(
        'http://applis.univ-nc.nc/cgi-bin/WebObjects/EdtWeb.woa/2/wa/default?login=$encodedUserId%2Fical');
    debugPrint("Fetching events from: $url");

    try {
      final http.Response response =
      await _client.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          debugPrint("ICS response body is empty for $userId.");
          return [];
        }
        return _parseIcsEvents(
            response.body, location, startOfWeek, endOfWeek);
      } else if (response.statusCode == 404) {
        throw Exception(
            "L'identifiant '$userId' n'a pas été trouvé ou l'emploi du temps n'existe pas (Erreur ${response.statusCode}).");
      } else {
        throw Exception(
            'Erreur serveur (${response.statusCode}) lors de la récupération de l\'emploi du temps.');
      }
    } on TimeoutException catch (_) {
      debugPrint("Timeout lors du chargement des événements pour $userId");
      throw Exception(timeoutErrorMessage);
    } on http.ClientException catch (e) {
      debugPrint("Erreur réseau/client pour $userId: $e");
      throw Exception(networkErrorMessage);
    } catch (e) {
      debugPrint("Erreur inconnue lors du chargement des événements pour $userId: $e");
      throw Exception("$defaultErrorMessage ($e)");
    }
  }

  List<IcsEvent> _parseIcsEvents(String icsContent, tz.Location noumeaLocation,
      DateTime startOfWeek, DateTime endOfWeek) {
    try {
      final ICalendar calendar = ICalendar.fromString(icsContent);

      return calendar.data
          .where((e) =>
      _getCaseInsensitive(e, 'type')?.toString().toUpperCase() ==
          icsTypeVEvent)
          .map((e) => IcsEvent.fromJson(e, noumeaLocation))
          .where((event) =>
      event.start != null &&
          event.end != null &&
          !event.start!.isBefore(startOfWeek) &&
          event.start!.isBefore(endOfWeek))
          .toList()
        ..sort((a, b) => a.start!.compareTo(b.start!));
    } catch (e) {
      debugPrint("Erreur de parsing du contenu ICS: $e");
      throw Exception("Les données de l'emploi du temps sont corrompues ou dans un format inattendu.");
    }
  }

  dynamic _getCaseInsensitive(Map map, String key) {
    return map.entries
        .firstWhere(
          (entry) => entry.key.toString().toLowerCase() == key.toLowerCase(),
      orElse: () => const MapEntry<String, dynamic>(
          '', null),
    )
        .value;
  }
}

// Petite extension pour capitaliser la première lettre d'une chaîne
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}