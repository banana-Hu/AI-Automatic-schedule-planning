import 'package:flutter/material.dart';

class Event {
  final int? id;
  final int startAt;
  final int durationMin;
  final String title;
  final int createdAt;
  final String? sourceText;
  final String? llmRaw;
  final bool isArchived;
  final bool isCompleted;
  final int priority;
  final int? focusTime;
  final int delayCount;
  final int? originalStartAt;

  Event({
    this.id,
    required this.startAt,
    required this.durationMin,
    required this.title,
    required this.createdAt,
    this.sourceText,
    this.llmRaw,
    this.isArchived = false,
    this.isCompleted = false,
    this.priority = 0,
    this.focusTime,
    this.delayCount = 0,
    this.originalStartAt,
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
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
      'focus_time': focusTime,
      'delay_count': delayCount,
      'original_start_at': originalStartAt,
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
      isCompleted: (map['is_completed'] as int?) == 1,
      priority: (map['priority'] as int?) ?? 0,
      focusTime: map['focus_time'] as int?,
      delayCount: (map['delay_count'] as int?) ?? 0,
      originalStartAt: map['original_start_at'] as int?,
    );
  }

  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return Colors.grey[300]!; // 无优先级
      case 1:
        return Colors.green[200]!; // 低
      case 2:
        return Colors.blue[200]!; // 中低
      case 3:
        return Colors.yellow[200]!; // 中
      case 4:
        return Colors.orange[200]!; // 中高
      case 5:
        return Colors.red[200]!; // 高
      default:
        return Colors.grey[300]!;
    }
  }

  static String getPriorityText(int priority) {
    switch (priority) {
      case 0:
        return '无';
      case 1:
        return '低';
      case 2:
        return '中低';
      case 3:
        return '中';
      case 4:
        return '中高';
      case 5:
        return '高';
      default:
        return '无';
    }
  }
}
