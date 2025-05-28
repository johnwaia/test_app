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

  static final RegExp _roomRegex = RegExp(
    r'(?:Btf|Bte|Bti|Btg|Bth|Btr|Bts|Ate|Lls|Amp|Aph|Eif)\s*:\s*([^\[\]\n\r]+)',
    caseSensitive: false,
  );

  static final RegExp _teacherRegex = RegExp(r'^[A-Z]\.[A-Za-zÀ-ÿ\-]+$');

  factory IcsEvent.fromJson(Map<String, dynamic> json, tz.Location tzLocation) {
    final normalizedJson = <String, dynamic>{
      for (final entry in json.entries) entry.key.toLowerCase(): entry.value,
    };

    dynamic getField(String key) => normalizedJson[key.toLowerCase()];

    DateTime? parseDate(dynamic fieldValue) {
      if (fieldValue == null) return null;

      final String? dateString = switch (fieldValue) {
        IcsDateTime dt => dt.dt,
        String s => s,
        _ => null,
      };

      if (dateString == null || dateString.isEmpty) return null;

      try {
        if (dateString.contains('T')) {
          return dateString.endsWith('Z')
              ? tz.TZDateTime.parse(tzLocation, dateString)
              : tz.TZDateTime.from(DateTime.parse(dateString), tzLocation);
        } else if (dateString.length == 8) {
          return tz.TZDateTime(
            tzLocation,
            int.parse(dateString.substring(0, 4)),
            int.parse(dateString.substring(4, 6)),
            int.parse(dateString.substring(6, 8)),
          );
        }
      } catch (_) {
        return null;
      }

      return null;
    }

    String? clean(String? value) => value?.split('(').first.trim();

    List<String>? extractRooms(String? text) {
      if (text == null) return null;

      final matches = _roomRegex.allMatches(text);
      final Set<String> rooms = {};

      for (final match in matches) {
        final group = match.group(1);
        if (group != null) {
          for (final s in group.split(RegExp(r'\s+'))) {
            final room = s.trim();
            if (room.isNotEmpty) rooms.add(room);
          }
        }
      }

      return rooms.isEmpty ? null : rooms.toList();
    }

    String? extractTeacher(String? text) {
      if (text == null) return null;

      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (_teacherRegex.hasMatch(trimmed)) {
          return trimmed;
        }
      }
      return null;
    }

    String? rawSummary = getField('summary')?.toString();
    final rawDescription = getField('description')?.toString();

    final combinedText =
        (rawDescription ?? '') +
        '\n' +
        (rawSummary ?? '').replaceAll(r'\n', '\n');

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
