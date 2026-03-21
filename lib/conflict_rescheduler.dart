import 'db_helper.dart';

class ConflictRescheduler {
  /// Linear stacking:
  /// - Existing events are treated as occupied slots.
  /// - Incoming events are sorted by start_time and shifted forward if overlap.
  /// - No complex splitting; always "push to the end of the conflict chain".
  List<DbEvent> reschedule({
    required List<DbEvent> existing,
    required List<DbEvent> incoming,
  }) {
    final occupied = _toSlots(existing);
    occupied.sort((a, b) => a.startMs.compareTo(b.startMs));

    final sortedIncoming = List<DbEvent>.from(incoming)
      ..sort((a, b) => _startMs(a).compareTo(_startMs(b)));

    final result = <DbEvent>[];
    for (final e in sortedIncoming) {
      var start = _startMs(e);
      final durationMs = e.durationMinutes * 60 * 1000;

      start = _pushPastConflicts(occupied, start, durationMs);
      // Also avoid overlaps with events we've already rescheduled in this batch.
      start = _pushPastConflicts(_toSlots(result), start, durationMs);

      final adjusted = DbEvent(
        id: e.id,
        title: e.title,
        startTimeIso: DateTime.fromMillisecondsSinceEpoch(start, isUtc: true)
            .toIso8601String(),
        durationMinutes: e.durationMinutes,
        notes: e.notes,
      );
      result.add(adjusted);
      occupied.add(_Slot(startMs: start, endMs: start + durationMs));
      occupied.sort((a, b) => a.startMs.compareTo(b.startMs));
    }

    return result;
  }

  int _pushPastConflicts(List<_Slot> slots, int startMs, int durationMs) {
    var start = startMs;
    while (true) {
      final end = start + durationMs;
      _Slot? conflict;
      for (final s in slots) {
        if (_overlap(start, end, s.startMs, s.endMs)) {
          conflict = s;
          break;
        }
      }
      if (conflict == null) return start;
      start = conflict.endMs;
    }
  }

  bool _overlap(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart < bEnd && aEnd > bStart;
  }

  int _startMs(DbEvent e) {
    return DateTime.parse(e.startTimeIso).toUtc().millisecondsSinceEpoch;
  }

  List<_Slot> _toSlots(List<DbEvent> events) {
    final slots = <_Slot>[];
    for (final e in events) {
      try {
        final start = _startMs(e);
        final end = start + e.durationMinutes * 60 * 1000;
        slots.add(_Slot(startMs: start, endMs: end));
      } catch (_) {
        // skip invalid
      }
    }
    slots.sort((a, b) => a.startMs.compareTo(b.startMs));
    return slots;
  }
}

class _Slot {
  _Slot({required this.startMs, required this.endMs});
  final int startMs;
  final int endMs;
}

