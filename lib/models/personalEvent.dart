class PersonalEvent {
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;

  PersonalEvent({
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });
}
