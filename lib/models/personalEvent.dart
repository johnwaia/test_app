enum EventType { personal, meeting }

class PersonalEvent {
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final EventType type;

  PersonalEvent({
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.type = EventType.personal,
  });
}
