import 'package:flutter/foundation.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:timezone/timezone.dart' as tz;

class IcsEvent {
  final String? summary;
  final String? description;
  final DateTime? start;
  final DateTime? end;
  final String? room;
  final String? teacher;

  IcsEvent({
    this.summary,
    this.description,
    this.start,
    this.end,
    this.room,
    this.teacher,
  });

  factory IcsEvent.fromJson(Map<String, dynamic> json, tz.Location tzLocation) {
    dynamic getField(String key) {
      final entry = json.entries.firstWhere(
        (e) => e.key.toString().toLowerCase() == key.toLowerCase(),
        orElse: () => const MapEntry<String, dynamic>('', null),
      );
      return entry.value;
    }

    DateTime? parseDate(dynamic fieldValue) {
      if (fieldValue == null) return null;
      String? dateString;

      if (fieldValue is IcsDateTime) {
        dateString = fieldValue.dt;
      } else if (fieldValue is String) {
        dateString = fieldValue;
      } else {
        debugPrint(
          "Type de date inattendu: ${fieldValue.runtimeType} pour la valeur: $fieldValue",
        );
        return null;
      }

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
        debugPrint("Erreur de parsing de la chaîne de date '$dateString': $e");
        return null;
      }

      return null;
    }

    String? clean(String? value) => value?.split('(')[0].trim();

    String? extractRoom(String? text) {
      if (text == null) return null;

      final btfRegex = RegExp(
        r'(?:Btf|Bte|Bti|Btg|Bth|Btr|Bts|Lls|Amp)\s*:\s*([^\[\]\n\r]+)',
        caseSensitive: false,
      );
      final match = btfRegex.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }

      return null;
    }

    String? extractTeacher(String? text) {
      if (text == null) return null;

      final lines = text.split('\n').map((l) => l.trim()).toList();
      for (var line in lines) {
        final RegExp nameRegex = RegExp(r'^[A-Z]\.[A-Za-z]+$');
        if (nameRegex.hasMatch(line)) {
          return line;
        }
      }

      return null;
    }

    final String? rawSummary = getField('summary')?.toString();
    final String? rawDescription = getField('description')?.toString();
    final String combinedText = ((rawDescription ?? '') +
            '\n' +
            (rawSummary ?? ''))
        .replaceAll(r'\n', '\n');

    return IcsEvent(
      summary: clean(rawSummary),
      description: clean(rawDescription),
      start: parseDate(getField('dtstart')),
      end: parseDate(getField('dtend')),
      room: extractRoom(combinedText),
      teacher: extractTeacher(combinedText),
    );
  }
}
