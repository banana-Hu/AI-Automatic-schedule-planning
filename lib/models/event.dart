class Event {
  final int? id;
  final int startAt;
  final int durationMin;
  final String title;
  final int createdAt;
  final String? sourceText;
  final String? llmRaw;
  final bool isArchived;

  Event({
    this.id,
    required this.startAt,
    required this.durationMin,
    required this.title,
    required this.createdAt,
    this.sourceText,
    this.llmRaw,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'start_at': startAt,
      'duration_min': durationMin,
      'title': title,
      'created_at': createdAt,
      'source_text': sourceText,
      'llm_raw': llmRaw,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      startAt: map['start_at'] as int,
      durationMin: map['duration_min'] as int,
      title: map['title'] as String,
      createdAt: map['created_at'] as int,
      sourceText: map['source_text'] as String?,
      llmRaw: map['llm_raw'] as String?,
      isArchived: (map['is_archived'] as int?) == 1,
    );
  }
}