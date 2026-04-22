import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models/event.dart';
import '../services/deepseek_client.dart';
import '../services/prompt_builder.dart';
import '../services/json_extract.dart';
import '../services/auto_schedule.dart';
import '../theme/app_theme.dart';
import 'goal_planner_page.dart';
import 'home_page.dart';

/// 对话消息模型
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime time;
  final bool isLoading;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.time,
    this.isLoading = false,
  });
}

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _loading = false;
  int _priority = 0;
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // 添加欢迎消息
    _messages.add(ChatMessage(
      content: '嗨！我是你的日程小助手~ 请告诉我你想要安排什么日程，我会帮你整理好哦！',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _textController.text = args;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
    final raw = _textController.text.trim();
    if (raw.isEmpty) return;

    final apiKey = AppState.of(context).apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _addMessage(ChatMessage(
        content: '需要先配置 API Key 才能使用哦，请先到设置页面配置~',
        isUser: false,
        time: DateTime.now(),
      ));
      return;
    }

    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        content: raw,
        isUser: true,
        time: DateTime.now(),
      ));
      _messages.add(ChatMessage(
        content: '让我来帮你整理一下~',
        isUser: false,
        time: DateTime.now(),
        isLoading: true,
      ));
      _loading = true;
    });

    _textController.clear();
    _scrollToBottom();
    HapticFeedback.lightImpact();

    try {
      final client = DeepSeekClient(apiKey: apiKey);
      final system = systemPrompt();
      final user = userPrompt(raw, DateTime.now());
      final response = await client.chat(system, user);

      final json = extractJsonObject(response);
      final rawList = extractEventsList(json);
      final createdAt = DateTime.now().millisecondsSinceEpoch;

      var events = parseEventsFromLlm(
        rawList,
        createdAt: createdAt,
        sourceText: raw,
        llmRaw: response,
      ).map((e) => Event(
        id: e.id,
        startAt: e.startAt,
        durationMin: e.durationMin,
        title: e.title,
        createdAt: e.createdAt,
        sourceText: e.sourceText,
        llmRaw: e.llmRaw,
        priority: _priority,
      )).toList();

      // 移除 loading 消息
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
      });

      if (events.isEmpty) {
        _addMessage(ChatMessage(
          content: '抱歉，我没有理解你的意思... 换一种方式描述试试？比如："明天下午3点开会"',
          isUser: false,
          time: DateTime.now(),
        ));
        return;
      }

      // 保存到数据库
      final repo = AppState.of(context).repo;
      final existing = await repo.listAll();
      events = linearReschedule(existing, events);
      for (final e in events) {
        await repo.insert(e);
      }

      // 生成成功消息
      final eventTexts = events.map((e) =>
        '• ${e.title}\n  ${_formatTime(DateTime.fromMillisecondsSinceEpoch(e.startAt))} - ${e.durationMin}分钟'
      ).join('\n');

      _addMessage(ChatMessage(
        content: '太棒了！我已经帮你安排好了：\n\n$eventTexts\n\n已添加到你的日程表中~',
        isUser: false,
        time: DateTime.now(),
      ));

      HapticFeedback.mediumImpact();

    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
      });
      _addMessage(ChatMessage(
        content: '出了点小问题：$e\n\n请稍后重试，或者检查一下网络连接~',
        isUser: false,
        time: DateTime.now(),
      ));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  String _formatTime(DateTime dt) {
    final month = dt.month;
    final day = dt.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month月$day日 $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCream,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _buildMessageList(),
          ),
          // 优先级选择（仅在输入时显示）
          if (_messages.isNotEmpty && !_loading)
            _buildPrioritySelector(),
          // 输入区域
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
          const FoxAssistant(size: 32),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Text(
              'AI 写日记',
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
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GoalPlannerPage()),
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentLavender.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: AppTheme.accentLavender,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isLoading) {
      return _buildAILoadingBubble();
    }

    if (message.isUser) {
      return _buildUserBubble(message);
    } else {
      return _buildAIBubble(message);
    }
  }

  Widget _buildUserBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Spacer(),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: CuteCardDecoration.userBubble(),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 用户头像
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
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBubble(ChatMessage message) {
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
                message.content,
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

  Widget _buildAILoadingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const FoxAssistant(size: 36, isTalking: true),
          const SizedBox(width: 12),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: CuteCardDecoration.aiBubble(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPeach),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '思考中...',
                  style: TextStyle(
                    color: AppTheme.textLightBrown,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: 18,
                color: AppTheme.textLightBrown,
              ),
              const SizedBox(width: 8),
              Text(
                '设置优先级',
                style: TextStyle(
                  color: AppTheme.textLightBrown,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (index) {
                final isSelected = _priority == index;
                final color = AppTheme.warmPastelColors[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _priority = index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.textBrown.withOpacity(0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected ? AppTheme.softShadow : null,
                      ),
                      child: Text(
                        ['无', '低', '中低', '中', '中高', '高'][index],
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.textBrown
                              : AppTheme.textLightBrown,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
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
                focusNode: _focusNode,
                enabled: !_loading,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: '告诉我你想安排什么日程...',
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
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
