import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:timezone/timezone.dart' as tz;

class IcsEvent {
  final String? summary;
  final String? description;
  final DateTime? start;
  final DateTime? end;
  final List<String>? room;
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
    final Map<String, dynamic> normalizedJson = {
      for (final entry in json.entries) entry.key.toLowerCase(): entry.value,
    };

    dynamic getField(String key) => normalizedJson[key.toLowerCase()];

    DateTime? parseDate(dynamic fieldValue) {
      if (fieldValue == null) return null;
      String dateString;

      if (fieldValue is IcsDateTime) {
        dateString = fieldValue.dt;
      } else if (fieldValue is String) {
        dateString = fieldValue;
      } else {
        return null;
      }

      if (dateString.isEmpty) return null;

      try {
        if (dateString.contains('T')) {
          return dateString.endsWith('Z')
              ? tz.TZDateTime.parse(tzLocation, dateString)
              : tz.TZDateTime.from(DateTime.parse(dateString), tzLocation);
        }

        if (dateString.length == 8) {
          final y = int.parse(dateString.substring(0, 4));
          final m = int.parse(dateString.substring(4, 6));
          final d = int.parse(dateString.substring(6, 8));
          return tz.TZDateTime(tzLocation, y, m, d);
        }
      } catch (_) {
        return null;
      }

      return null;
    }

    String? clean(String? value) => value?.split('(')[0].trim();

    /// Extrait toutes les salles trouvées (ex : L34info20, L35info36)
    List<String>? extractRooms(String? text) {
      if (text == null) return null;
      final roomRegex = RegExp(
        r'(?:Btf|Bte|Bti|Btg|Bth|Btr|Bts|Ate|Lls|Amp|Aph)\s*:\s*([^\[\]\n\r]+)',
        caseSensitive: false,
      );

      final matches = roomRegex.allMatches(text);
      final rooms =
          matches
              .expand((match) => match.group(1)!.split(RegExp(r'\s+')))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();

      return rooms.isEmpty ? null : rooms;
    }

    String? extractTeacher(String? text) {
      if (text == null) return null;
      final lines = text.split('\n').map((l) => l.trim());
      for (final line in lines) {
        if (RegExp(r'^[A-Z]\.[A-Za-zÀ-ÿ\-]+$').hasMatch(line)) {
          return line;
        }
      }
      return null;
    }

    String? rawSummary = getField('summary')?.toString();
    final rawDescription = getField('description')?.toString();

    // Fusionne les champs pour analyse
    final combinedText = ((rawDescription ?? '') + '\n' + (rawSummary ?? ''))
        .replaceAll(r'\n', '\n');

    // Remplace Cm par CC si CONTROLE CONTINU est mentionné
    if ((rawSummary ?? '').toUpperCase().contains('CONTROLE CONTINU')) {
      rawSummary = rawSummary?.replaceAll(
        RegExp(r'\bCm\b', caseSensitive: false),
        'CC',
      );
    }

    return IcsEvent(
      summary: clean(rawSummary),
      description: clean(rawDescription),
      start: parseDate(getField('dtstart')),
      end: parseDate(getField('dtend')),
      room: extractRooms(combinedText),
      teacher: extractTeacher(combinedText),
    );
  }
}
