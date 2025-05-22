import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class IcsEvent {
  final String? summary;
  final String? description;
  final DateTime? start;
  final DateTime? end;

  IcsEvent({this.summary, this.description, this.start, this.end});

  factory IcsEvent.fromJson(Map<String, dynamic> json, tz.Location tzLocation) {
    dynamic getField(String key) {
      return json.entries
          .firstWhere(
            (e) => e.key.toLowerCase() == key.toLowerCase(),
            orElse: () => const MapEntry('', null),
          )
          .value;
    }

    DateTime? parseDate(dynamic fieldValue) {
      if (fieldValue == null) return null;

      if (fieldValue is! String) {
        debugPrint(
          "Type inattendu pour la date : ${fieldValue.runtimeType}, valeur : $fieldValue",
        );
        return null;
      }

      final dateString = fieldValue;

      if (dateString.isEmpty) return null;

      try {
        if (dateString.contains('T')) {
          if (dateString.endsWith('Z')) {
            return tz.TZDateTime.parse(tzLocation, dateString);
          } else {
            final localDateTime = DateTime.parse(dateString);
            return tz.TZDateTime.from(localDateTime, tzLocation);
          }
        } else if (dateString.length == 8) {
          final year = int.parse(dateString.substring(0, 4));
          final month = int.parse(dateString.substring(4, 6));
          final day = int.parse(dateString.substring(6, 8));
          return tz.TZDateTime(tzLocation, year, month, day);
        }
      } catch (e) {
        debugPrint("Erreur lors du parsing de la date '$dateString' : $e");
        return null;
      }

      debugPrint("Format de date non reconnu : '$dateString'");
      return null;
    }

    String? clean(String? value) => value?.split('(')[0].trim();

    final summaryValue = getField('summary')?.toString();
    final descriptionValue = getField('description')?.toString();

    return IcsEvent(
      summary: clean(summaryValue),
      description: clean(descriptionValue),
      start: parseDate(getField('dtstart')),
      end: parseDate(getField('dtend')),
    );
  }
}
