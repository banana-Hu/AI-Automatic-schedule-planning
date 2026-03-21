import 'dart:convert';
import 'package:dio/dio.dart';
import 'db_helper.dart';

class AiService {
  // TODO: 替换成你自己的 URL
  static const String apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const String model = 'deepseek-chat';

  static const String systemPrompt = '''
你是一个无情的日程提取器。
你的输出必须是且只能是一个 JSON 对象，不要输出任何 markdown、代码块标记、解释、寒暄或额外文本。

输出数据协议（严格遵守字段名与类型）：
{"events":[{"start_time":"2026-03-17T09:00:00Z","title":"字符串","duration_minutes":60,"notes":""}]}

规则：
- start_time 必须是 ISO8601（允许带时区，如 Z 或 +08:00）。
- duration_minutes 必须是整数。
- notes 可以为空字符串。
''';

  AiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<DbEvent>> parseTextToEvents({
    required String input,
    required String apiKey,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API Key 为空');
    }
    final resp = await _dio.post<Map<String, dynamic>>(
      apiUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': input},
        ],
        'temperature': 0.2,
      },
    );

    final data = resp.data;
    if (data == null) throw Exception('AI 返回为空');
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) throw Exception('AI choices 为空');
    final first = choices.first;
    if (first is! Map) throw Exception('AI choices 格式异常');
    final message = first['message'];
    if (message is! Map) throw Exception('AI message 格式异常');
    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('AI content 为空');
    }

    final jsonStr = _extractJsonString(content);
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('JSON 顶层不是对象');
    }
    final events = decoded['events'];
    if (events is! List) throw Exception('JSON.events 不是数组');

    final result = <DbEvent>[];
    for (final e in events) {
      if (e is! Map) continue;
      final startTime = e['start_time'];
      final title = e['title'];
      final duration = e['duration_minutes'];
      final notes = e['notes'];
      if (startTime is! String || title is! String) continue;
      int? durationMin;
      if (duration is int) durationMin = duration;
      if (duration is num) durationMin = duration.toInt();
      if (durationMin == null) continue;
      durationMin = durationMin.clamp(1, 24 * 60);

      // Validate ISO8601 parseable; keep original string in DB.
      try {
        DateTime.parse(startTime);
      } catch (_) {
        continue;
      }

      result.add(
        DbEvent(
          title: title,
          startTimeIso: startTime,
          durationMinutes: durationMin,
          notes: notes is String ? notes : null,
        ),
      );
    }
    return result;
  }

  /// Highest-tolerance JSON extraction:
  /// 1) remove common ```json fences
  /// 2) use regex to grab { ... } (DOTALL)
  /// 3) if regex fails, do a brace-scan to find first balanced object
  String _extractJsonString(String raw) {
    var s = raw.trim();

    // Strip common markdown fences but do NOT trust that this is sufficient.
    s = s.replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '');
    s = s.replaceAll('```', '');
    s = s.trim();

    // Regex: grab the biggest { ... } block (DOTALL).
    final m = RegExp(r'\{[\s\S]*\}').firstMatch(s);
    if (m != null) {
      final candidate = m.group(0);
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    // Fallback: brace scan to find first balanced JSON object substring.
    final scanned = _scanBalancedObject(s);
    if (scanned != null) return scanned;

    throw Exception('无法从 AI 输出中提取 JSON');
  }

  String? _scanBalancedObject(String s) {
    int depth = 0;
    int start = -1;
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (ch == '}') {
        if (depth > 0) depth--;
        if (depth == 0 && start >= 0) {
          final candidate = s.substring(start, i + 1).trim();
          if (candidate.startsWith('{') && candidate.endsWith('}')) {
            return candidate;
          }
        }
      }
    }
    return null;
  }
}

