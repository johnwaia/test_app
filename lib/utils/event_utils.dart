import 'package:flutter/material.dart';

String getFirstString(dynamic value, {String defaultValue = 'Inconnu'}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is List && value.isNotEmpty && value.first is String) {
    final first = value.first.trim();
    return first.isNotEmpty ? first : defaultValue;
  }
  return defaultValue;
}

Color getEventColor(String summary) {
  final s = summary.toLowerCase();
  if (s.contains('td')) return Colors.green.shade300;
  if (s.contains('cm')) return const Color(0xFF71B4EA);
  if (s.contains('tp')) return const Color(0xFFE8AC52);
  return Colors.grey.shade300;
}

String getCourseType(String summary) {
  final s = summary.toLowerCase();
  if (s.contains('td')) return 'TD';
  if (s.contains('cm')) return 'CM';
  if (s.contains('tp')) return 'TP';
  return 'Autre';
}

int getDurationMinutes(DateTime? start, DateTime? end) {
  if (start != null && end != null) {
    return end.difference(start).inMinutes;
  }
  return 30;
}
