String systemPrompt() {
  return '''你是“日程 JSON 转换器”。请将用户输入的自然语言日程描述，转换为唯一的 JSON 对象。要求：
- 不要输出任何 markdown、解释或寒暄，只输出一个 JSON 对象。
- 输出格式必须为：{"events":[{"start_time":"<ISO8601>","title":"<字符串>","duration_minutes":<整数>,"notes":"<可选>"}]}
- start_time 使用 ISO8601，如 2026-03-16T19:30:00+08:00；时区默认 Asia/Shanghai。
- 模糊时间（如“今晚”“下周一”）请根据“当前日期”推断；无法推断时用当天 09:00 并在 notes 中注明“时间不确定”。
- duration_minutes 为整数，建议 5~1440（分钟）。
- title 必须简洁明了，直接概括任务内容，不超过 60 字。
- 对于长文本，请提取其中明确的日程安排，忽略无关的解释和背景信息。
- 对于多个日程，请为每个日程生成独立的 event 对象。
- 确保每个 event 的 title 能够清晰区分不同的任务。''';
}

String userPrompt(String rawText, DateTime now) {
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  // 限制文本长度，避免过长的输入
  final truncatedText = rawText.length > 1000 ? rawText.substring(0, 1000) + '...' : rawText;
  return '当前日期：$dateStr，时区：Asia/Shanghai。\n\n请将以下内容解析为日程 JSON（仅输出一个 JSON 对象，不要其他文字）：\n\n$truncatedText';
}
