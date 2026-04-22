import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/websocket_client.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late WebSocketClient _webSocketClient;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _webSocketClient = WebSocketClient();
    _webSocketClient.onMessage = _handleMessage;
    _webSocketClient.onConnected = () {
      setState(() => _isConnected = true);
    };
    _webSocketClient.onDisconnected = () {
      setState(() => _isConnected = false);
    };
    _webSocketClient.connect('ws://localhost:8080');
    
    // 添加欢迎消息
    _messages.add(ChatMessage(
      text: '嗨！我是 Gemini 问答助手~\n有什么问题可以问我哦！',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _webSocketClient.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message);
      setState(() {
        _messages.add(ChatMessage(
          text: data['text'],
          isUser: data['isUser'],
        ));
      });
      _scrollToBottom();
    } catch (e) {
      print('解析消息失败: $e');
    }
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

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    final messageText = _textController.text;
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
      ));
      _isTyping = true;
    });

    _textController.clear();
    HapticFeedback.lightImpact();
    _scrollToBottom();

    // 通过WebSocket发送消息
    _webSocketClient.send(jsonEncode({
      'text': messageText,
      'isUser': true,
    }));

    // 模拟AI回复
    Future.delayed(const Duration(seconds: 1), () {
      final aiResponse = '这是一个模拟的AI回复。在实际实现中，这里会调用Gemini API获取真实回复。';
      setState(() {
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCream,
      appBar: AppBar(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentLavender.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.accentLavender,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Text(
                'Gemini 问答',
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
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected
                  ? AppTheme.accentMint.withOpacity(0.2)
                  : AppTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: _isConnected ? AppTheme.accentMint : AppTheme.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? '已连接' : '未连接',
                  style: TextStyle(
                    color: _isConnected ? AppTheme.accentMint : AppTheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final msg = _messages[index];
                  if (msg.isUser) {
                    return _buildUserBubble(msg.text);
                  } else {
                    return _buildAIBubble(msg.text);
                  }
                } else {
                  return _buildLoadingBubble();
                }
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
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
                text,
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

  Widget _buildAIBubble(String text) {
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
                text,
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

  Widget _buildLoadingBubble() {
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentLavender),
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
                enabled: !_isTyping,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: '输入你的问题...',
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
            onTap: _isTyping ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: _isTyping
                    ? LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!])
                    : const LinearGradient(
                        colors: [AppTheme.accentLavender, AppTheme.accentPeach],
                      ),
                shape: BoxShape.circle,
                boxShadow: _isTyping ? null : AppTheme.softShadow,
              ),
              child: Icon(
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

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
