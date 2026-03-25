import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketServer {
  late HttpServer _server;
  final List<WebSocketChannel> _clients = [];

  Future<void> start(int port) async {
    final handler = webSocketHandler((webSocket) {
      final channel = WebSocketChannel(webSocket);
      _clients.add(channel);

      channel.stream.listen(
        (message) {
          // 广播消息给所有客户端
          for (var client in _clients) {
            client.sink.add(message);
          }
        },
        onDone: () {
          _clients.remove(channel);
        },
        onError: (error) {
          _clients.remove(channel);
        },
      );
    });

    _server = await shelf_io.serve(handler, 'localhost', port);
    print('WebSocket服务器已启动，监听端口: ${_server.port}');
  }

  Future<void> stop() async {
    await _server.close();
    print('WebSocket服务器已停止');
  }

  void broadcast(String message) {
    for (var client in _clients) {
      client.sink.add(message);
    }
  }

  int get clientCount => _clients.length;
}
