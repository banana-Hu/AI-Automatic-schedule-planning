import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../app_state.dart';
import '../services/deepseek_client.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';

class GoalPlannerPage extends StatefulWidget {
  const GoalPlannerPage({super.key});

  @override
  State<GoalPlannerPage> createState() => _GoalPlannerPageState();
}

class _GoalPlannerPageState extends State<GoalPlannerPage>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _planningComplete = false;
  List<Event> _generatedEvents = [];
  late AnimationController _foxAnimController;

  @override
  void initState() {
    super.initState();
    _foxAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _addAssistantMessage(
      '嗨！我是目标规划小助手~\n\n想要达成某个目标吗？告诉我你的目标是什么，比如：\n• "我想在一个月内学会游泳"\n• "准备三个月后参加马拉松"\n• "今年要读完50本书"\n\n我会帮你制定详细的执行计划哦！🎯',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _foxAnimController.dispose();
    super.dispose();
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _textController.clear();
    setState(() => _loading = true);
    HapticFeedback.lightImpact();

    try {
      final apiKey = AppState.of(context).apiKey;
      if (apiKey == null || apiKey.isEmpty) {
        _addAssistantMessage('需要先配置 API Key 才能使用目标规划功能哦~\n\n请先到"设置"页面配置你的 DeepSeek API Key~');
        setState(() => _loading = false);
        return;
      }

      final client = DeepSeekClient(apiKey: apiKey);
      const systemPrompt = '''你是一个专业、友好的目标规划助手，名字叫"小狐"。你的任务是通过多轮对话，帮助用户制定详细的日程计划来达成他们的目标。

请用轻松友好的语言与用户交流，像朋友一样。适当使用 emoji 让对话更有趣。

步骤：
1. 了解用户的目标是什么
2. 询问必要信息（截止日期、可用时间、现有安排等）
3. 分析并制定合理的计划
4. 当计划完善后，以JSON格式输出最终日程

JSON格式：
{"goal":"目标描述","plan":[{"title":"任务标题","description":"任务描述","start_time":"ISO8601时间","duration_minutes":整数,"priority":0-5}]}''';

      final userPrompt = _buildUserPrompt(text);
      final response = await client.chat(systemPrompt, userPrompt);
      _addAssistantMessage(response);

      if (response.contains('{"goal":') && response.contains('"plan":')) {
        _parseAndShowPlan(response);
      }
    } catch (e) {
      _addAssistantMessage('出了点小问题：$e\n\n请稍后重试，或者检查一下网络连接~');
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

              DateTime startTime = DateTime.now().add(const Duration(hours: 1));
              try {
                if (startTimeStr is String && startTimeStr.isNotEmpty) {
                  startTime = DateTime.parse(startTimeStr);
                }
              } catch (e) {
                // 使用默认时间
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
            _addAssistantMessage('太棒了！✨ 计划已经制定好了~\n\n请查看下方生成的日程，确认后点击保存~');
            setState(() => _planningComplete = true);
          }
        }
      }
    } catch (e) {
      _addAssistantMessage('计划生成成功，但解析时遇到点小问题，你可以直接根据上面的建议安排日程哦~');
    }
  }

  Future<void> _confirmPlan() async {
    if (_generatedEvents.isEmpty) return;

    final repo = AppState.of(context).repo;
    for (final event in _generatedEvents) {
      await repo.insert(event);
    }

    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('已保存 ${_generatedEvents.length} 条日程~'),
            ],
          ),
          backgroundColor: AppTheme.accentMint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCream,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          if (_planningComplete)
            _buildPlanPreview(),
          if (!_planningComplete)
            _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryCream,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.softShadow,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textBrown,
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _foxAnimController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_foxAnimController.value * 3),
                child: const FoxAssistant(size: 32),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Text(
              '目标规划',
              style: TextStyle(
                color: AppTheme.textBrown,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['role'] == 'user';

        if (isUser) {
          return _buildUserBubble(message['content']);
        } else {
          return _buildAIBubble(message['content']);
        }
      },
    );
  }

  Widget _buildUserBubble(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: CuteCardDecoration.userBubble(),
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentPeach, AppTheme.accentPeachDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBubble(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const FoxAssistant(size: 36),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: CuteCardDecoration.aiBubble(),
              child: Text(
                content,
                style: const TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentMint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppTheme.accentMint,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '生成的日程计划',
                  style: TextStyle(
                    color: AppTheme.textBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: _generatedEvents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final event = entry.value;
                  final color = AppTheme.warmPastelColors[event.priority % 6];
                  final startTime = DateTime.fromMillisecondsSinceEpoch(event.startAt);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.textBrown,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: AppTheme.textBrown,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${startTime.month}/${startTime.day} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} • ${event.durationMin}分钟',
                                style: TextStyle(
                                  color: AppTheme.textLightBrown,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            Event.getPriorityText(event.priority),
                            style: const TextStyle(
                              color: AppTheme.textBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _confirmPlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('保存 ${_generatedEvents.length} 条日程'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.inputBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
              ),
              child: TextField(
                controller: _textController,
                enabled: !_loading,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: '告诉我你的目标...',
                  hintStyle: TextStyle(
                    color: AppTheme.textLightBrown.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _loading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: _loading
                    ? LinearGradient(
                        colors: [Colors.grey[300]!, Colors.grey[400]!],
                      )
                    : const LinearGradient(
                        colors: [AppTheme.accentPeach, AppTheme.accentPeachDark],
                      ),
                shape: BoxShape.circle,
                boxShadow: _loading ? null : AppTheme.softShadow,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
