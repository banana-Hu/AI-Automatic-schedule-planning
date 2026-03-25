
import 'package:flutter/material.dart';
import 'dart:convert';
import '../app_state.dart';
import '../services/deepseek_client.dart';
import '../models/event.dart';
import 'input_page.dart';

class GoalPlannerPage extends StatefulWidget {
  const GoalPlannerPage({super.key});

  @override
  State<GoalPlannerPage> createState() => _GoalPlannerPageState();
}

class _GoalPlannerPageState extends State<GoalPlannerPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _planningComplete = false;
  List<Event> _generatedEvents = [];

  @override
  void initState() {
    super.initState();
    _addSystemMessage('欢迎使用目标规划助手！请告诉我你的目标是什么，我将帮助你制定详细的日程计划来达成目标。');
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addSystemMessage(String content) {
    setState(() {
      _messages.add({'role': 'system', 'content': content});
    });
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    setState(() {
      _messages.add({'role': 'user', 'content': content});
    });
    _scrollToBottom();
  }

  void _addAssistantMessage(String content) {
    setState(() {
      _messages.add({'role': 'assistant', 'content': content});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _textController.clear();
    setState(() => _loading = true);

    try {
      final apiKey = AppState.of(context).apiKey;
      if (apiKey == null || apiKey.isEmpty) {
        _addSystemMessage('请先在设置中配置 API Key');
        setState(() => _loading = false);
        return;
      }

      final client = DeepSeekClient(apiKey: apiKey);
      final systemPrompt = '''你是一个专业的目标规划助手。你的任务是通过多轮对话，帮助用户制定详细的日程计划来达成他们的目标。

请遵循以下步骤：
1. 首先了解用户的目标是什么
2. 询问必要的信息，如目标截止日期、可用时间、现有 commitments等
3. 分析信息并制定合理的日程计划
4. 以JSON格式输出最终的日程计划，包含具体的任务、时间和优先级

JSON格式要求：
{
  "goal": "用户的目标",
  "plan": [
    {
      "title": "任务标题",
      "description": "任务描述",
      "start_time": "ISO8601时间",
      "duration_minutes": 整数,
      "priority": 0-5
    }
  ]
}

请用自然友好的语言与用户交流，逐步引导用户提供必要信息。''';

      final userPrompt = _buildUserPrompt(text);
      final response = await client.chat(systemPrompt, userPrompt);
      _addAssistantMessage(response);

      // 检查是否包含日程计划
      if (response.contains('{"goal":') && response.contains('"plan":')) {
        _parseAndShowPlan(response);
      }
    } catch (e) {
      _addSystemMessage('发生错误：$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _buildUserPrompt(String newMessage) {
    String prompt = '';
    for (final message in _messages) {
      if (message['role'] == 'user') {
        prompt += '用户: ${message['content']}\n';
      } else if (message['role'] == 'assistant') {
        prompt += '助手: ${message['content']}\n';
      }
    }
    prompt += '用户: $newMessage';
    return prompt;
  }

  void _parseAndShowPlan(String response) {
    try {
      // 提取JSON部分
      final start = response.indexOf('{"goal":');
      final end = response.lastIndexOf('}') + 1;
      if (start >= 0 && end > start) {
        final jsonStr = response.substring(start, end);
        final jsonData = json.decode(jsonStr);
        
        if (jsonData is Map && jsonData.containsKey('plan') && jsonData['plan'] is List) {
          final planList = jsonData['plan'] as List;
          final createdAt = DateTime.now().millisecondsSinceEpoch;
          
          _generatedEvents = planList.map((item) {
            if (item is Map) {
              final title = item['title'] ?? '未命名任务';
              final startTimeStr = item['start_time'] ?? '';
              final durationMinutes = item['duration_minutes'] ?? 60;
              final priority = item['priority'] ?? 0;
              
              // 解析开始时间
              DateTime startTime = DateTime.now().add(const Duration(hours: 1));
              try {
                if (startTimeStr is String && startTimeStr.isNotEmpty) {
                  startTime = DateTime.parse(startTimeStr);
                }
              } catch (e) {
                // 如果解析失败，使用默认时间
              }
              
              return Event(
                startAt: startTime.millisecondsSinceEpoch,
                durationMin: durationMinutes is int ? durationMinutes : 60,
                title: title is String ? title : '未命名任务',
                createdAt: createdAt,
                priority: priority is int ? priority : 0,
              );
            }
            return null;
          }).where((event) => event != null).cast<Event>().toList();
          
          if (_generatedEvents.isNotEmpty) {
            _addSystemMessage('日程计划已生成，请查看并确认');
            setState(() => _planningComplete = true);
          } else {
            _addSystemMessage('未能从响应中提取日程计划，请重试');
          }
        } else {
          _addSystemMessage('日程计划格式不正确，请重试');
        }
      }
    } catch (e) {
      _addSystemMessage('解析日程计划失败：$e');
    }
  }

  Future<void> _confirmPlan() async {
    if (_generatedEvents.isEmpty) return;

    final repo = AppState.of(context).repo;
    for (final event in _generatedEvents) {
      await repo.insert(event);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存 ${_generatedEvents.length} 条日程')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目标规划'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final isSystem = message['role'] == 'system';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : isSystem ? Colors.grey[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message['content']),
                  ),
                );
              },
            ),
          ),
          if (_planningComplete)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('生成的日程计划:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final event in _generatedEvents)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Event.getPriorityColor(event.priority),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${DateTime.fromMillisecondsSinceEpoch(event.startAt).toString()}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text('${event.durationMin}分钟'),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmPlan,
                          child: const Text('确认保存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_planningComplete)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '输入你的目标和相关信息...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _sendMessage,
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
