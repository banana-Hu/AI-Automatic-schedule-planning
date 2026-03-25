import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/websocket_client.dart';

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _textController = TextEditingController();
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
      setState(() {
        _isConnected = true;
      });
    };
    _webSocketClient.onDisconnected = () {
      setState(() {
        _isConnected = false;
      });
    };
    // 连接到WebSocket服务器
    _webSocketClient.connect('ws://localhost:8080');
  }

  @override
  void dispose() {
    _webSocketClient.disconnect();
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
    } catch (e) {
      print('解析消息失败: $e');
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    final messageText = _textController.text;
    final messageData = jsonEncode({
      'text': messageText,
      'isUser': true,
    });

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
      ));
      _isTyping = true;
    });

    _textController.clear();

    // 通过WebSocket发送消息
    _webSocketClient.send(messageData);

    // 模拟AI回复
    Future.delayed(const Duration(seconds: 1), () {
      final aiResponse = '这是一个模拟的AI回复。在实际实现中，这里会调用Gemini API获取真实回复。';
      final aiResponseData = jsonEncode({
        'text': aiResponse,
        'isUser': false,
      });
      _webSocketClient.send(aiResponseData);
      
      setState(() {
        _messages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
        ));
        _isTyping = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini 问答'),
        actions: [
          IconButton(
            onPressed: () {
              if (!_isConnected) {
                _webSocketClient.connect('ws://localhost:8080');
              }
            },
            icon: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _messages[index];
                } else {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('AI 正在输入...'),
                    ),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '输入你的问题...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(text),
      ),
    );
  }
}
