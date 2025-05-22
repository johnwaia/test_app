// Dans votre fichier models/ics_event.dart

import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'package:icalendar_parser/icalendar_parser.dart'; // Pour IcsDateTime
import 'package:timezone/timezone.dart' as tz;

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
    // Fonction utilitaire pour obtenir la valeur d'un champ en ignorant la casse
    dynamic getField(String key) {
      final entry = json.entries.firstWhere(
            (e) => e.key.toString().toLowerCase() == key.toLowerCase(),
        orElse: () => const MapEntry<String, dynamic>('', null),
      );
      return entry.value;
    }

    // Fonction utilitaire pour parser les dates de l'ICS
    DateTime? parseDate(dynamic fieldValue) {
      if (fieldValue == null) return null;

      String? dateString;

      if (fieldValue is IcsDateTime) {
        dateString = fieldValue.dt;
      } else if (fieldValue is String) {
        dateString = fieldValue;
      } else {
        // Ce cas ne devrait plus se produire si les données sont cohérentes
        debugPrint("Type de date inattendu: ${fieldValue.runtimeType} pour la valeur: $fieldValue");
        return null;
      }

      if (dateString == null || dateString.isEmpty) return null;

      try {
        if (dateString.contains('T')) {
          if (dateString.endsWith('Z')) {
            return tz.TZDateTime.parse(tzLocation, dateString);
          } else {
            final DateTime localDateTime = DateTime.parse(dateString);
            return tz.TZDateTime.from(localDateTime, tzLocation);
          }
        } else if (dateString.length == 8) {
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

    String? clean(String? value) => value?.split('(')[0].trim();

    String? summaryValue = getField('summary')?.toString();
    String? descriptionValue = getField('description')?.toString();

    return IcsEvent(
      summary: clean(summaryValue),
      description: clean(descriptionValue),
      start: parseDate(getField('dtstart')),
      end: parseDate(getField('dtend')),
    );
  }
}