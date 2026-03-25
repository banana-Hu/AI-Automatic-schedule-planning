import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

void main() async {
  // 创建WebSocket处理程序
  final wsHandler = webSocketHandler((webSocket) {
    final channel = WebSocketChannel(webSocket);
    print('客户端已连接');

    channel.stream.listen(
      (message) {
        print('收到消息: $message');
        // 广播消息给所有客户端
        for (var client in clients) {
          client.sink.add(message);
        }
      },
      onDone: () {
        clients.remove(channel);
        print('客户端已断开连接');
      },
      onError: (error) {
        clients.remove(channel);
        print('客户端错误: $error');
      },
    );

    clients.add(channel);
  });

  // 创建静态文件处理程序
  final staticHandler = createStaticHandler('web', defaultDocument: 'gemini_chat.html');

  // 创建路由
  final router = Router();
  router.mount('/ws', wsHandler);
  router.mount('/', staticHandler);

  // 启动服务器
  final server = await shelf_io.serve(router, 'localhost', 8080);
  print('服务器已启动，监听端口: ${server.port}');
  print('访问地址: http://localhost:${server.port}');
}

// 存储所有连接的客户端
final List<WebSocketChannel> clients = [];
