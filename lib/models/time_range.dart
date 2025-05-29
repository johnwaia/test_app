class TimeRange {
  final DateTime start;
  final DateTime end;
  TimeRange(this.start, this.end);

  @override
  String toString() =>
      "${start.hour.toString().padLeft(2, '0')}h${start.minute.toString().padLeft(2, '0')} - "
      "${end.hour.toString().padLeft(2, '0')}h${end.minute.toString().padLeft(2, '0')}";
}
