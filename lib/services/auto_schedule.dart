import '../models/event.dart';

/// Linear reschedule: for each new event, if it overlaps with existing ones,
/// move start to the end of the last overlapping event. [existing] must be
/// sorted by start_at.
List<Event> linearReschedule(List<Event> existing, List<Event> incoming) {
  incoming = List.from(incoming)..sort((a, b) => a.startAt.compareTo(b.startAt));
  final result = <Event>[];
  for (final e in incoming) {
    int start = e.startAt;
    final end = start + e.durationMin * 60 * 1000;
    for (final ex in existing) {
      final exEnd = ex.startAt + ex.durationMin * 60 * 1000;
      if (start < exEnd && end > ex.startAt) {
        start = exEnd;
      }
    }
    for (final r in result) {
      final rEnd = r.startAt + r.durationMin * 60 * 1000;
      if (start < rEnd && (start + e.durationMin * 60 * 1000) > r.startAt) {
        start = rEnd;
      }
    }
    result.add(Event(
      startAt: start,
      durationMin: e.durationMin,
      title: e.title,
      createdAt: e.createdAt,
      sourceText: e.sourceText,
      llmRaw: e.llmRaw,
      priority: e.priority,
      focusTime: e.focusTime,
    ));
  }
  return result;
}
