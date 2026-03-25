import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  late WebSocketChannel _channel;
  bool _connected = false;
  Function(String)? _onMessage;
  Function()? _onConnected;
  Function()? _onDisconnected;

  Future<void> connect(String url) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _connected = true;
      if (_onConnected != null) {
        _onConnected!();
      }

      _channel.stream.listen(
        (message) {
          if (_onMessage != null && message is String) {
            _onMessage!(message);
          }
        },
        onDone: () {
          _connected = false;
          if (_onDisconnected != null) {
            _onDisconnected!();
          }
        },
        onError: (error) {
          _connected = false;
          if (_onDisconnected != null) {
            _onDisconnected!();
          }
        },
      );
    } catch (e) {
      print('WebSocket连接失败: $e');
      _connected = false;
      if (_onDisconnected != null) {
        _onDisconnected!();
      }
    }
  }

  void disconnect() {
    if (_connected) {
      _channel.sink.close();
      _connected = false;
    }
  }

  void send(String message) {
    if (_connected) {
      _channel.sink.add(message);
    }
  }

  bool get isConnected => _connected;

  set onMessage(Function(String) callback) {
    _onMessage = callback;
  }

  set onConnected(Function() callback) {
    _onConnected = callback;
  }

  set onDisconnected(Function() callback) {
    _onDisconnected = callback;
  }
}
