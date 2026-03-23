import 'dart:convert';
import '../models/event.dart';

/// Extracts the outermost JSON object from [raw] (first { to last }).
/// Returns null if no valid JSON found.
Map<String, dynamic>? extractJsonObject(String raw) {
  final start = raw.indexOf('{');
  if (start < 0) return null;
  final end = raw.lastIndexOf('}');
  if (end < start) return null;
  final slice = raw.substring(start, end + 1);
  try {
    final decoded = jsonDecode(slice) as Map<String, dynamic>?;
    return decoded;
  } catch (_) {
    return null;
  }
}

/// Expects top-level key "events" as List. Returns empty list if invalid.
List<dynamic> extractEventsList(Map<String, dynamic>? json) {
  if (json == null) return [];
  final events = json['events'];
  if (events is! List) return [];
  return events;
}

int _clamp(int v, int lo, int hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

/// Parses LLM event items (start_time ISO8601, title, duration_minutes) into [Event].
/// Invalid items are skipped. [createdAt] and optional [sourceText]/[llmRaw] applied to all.
List<Event> parseEventsFromLlm(
  List<dynamic> raw, {
  required int createdAt,
  String? sourceText,
  String? llmRaw,
}) {
  final result = <Event>[];
  for (final item in raw) {
    if (item is! Map<String, dynamic>) continue;
    final startTime = item['start_time'];
    final title = item['title'];
    final durationMinutes = item['duration_minutes'];
    if (startTime is! String || title is! String) continue;
    int durationMin = 30;
    if (durationMinutes is int) {
      durationMin = _clamp(durationMinutes, 5, 24 * 60);
    } else if (durationMinutes is num) {
      durationMin = _clamp(durationMinutes.toInt(), 5, 24 * 60);
    }
    DateTime start;
    try {
      start = DateTime.parse(startTime);
    } catch (_) {
      continue;
    }
    final priority = item['priority'];
    int priorityValue = 0;
    if (priority is int) {
      priorityValue = priority.clamp(0, 5);
    }
    result.add(Event(
      startAt: start.millisecondsSinceEpoch,
      durationMin: durationMin,
      title: title.length > 60 ? title.substring(0, 60) : title,
      createdAt: createdAt,
      sourceText: sourceText,
      llmRaw: llmRaw,
      priority: priorityValue,
    ));
  }
  return result;
}
