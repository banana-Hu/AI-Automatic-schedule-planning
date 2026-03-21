import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/input_page.dart';
import 'pages/settings_page.dart';
import 'app_state.dart';
import 'data/event_repo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repo = EventRepo();
  ShareHandler.init();
  runApp(MyApp(prefs: prefs, repo: repo));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs, required this.repo});

  final SharedPreferences prefs;
  final EventRepo repo;

  @override
  Widget build(BuildContext context) {
    return AppState(
      prefs: prefs,
      repo: repo,
      child: MaterialApp(
        title: '极简 AI 日程',
        theme: ThemeData(useMaterial3: true),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/input': (context) => const InputPage(),
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}

// 分享处理
class ShareHandler {
  static void init() {
    // 监听分享流
    ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      final text = _extractTextFromShared(files);
      if (text != null && text.trim().isNotEmpty) {
        // 这里可以通过全局状态或事件总线来处理分享内容
        // 暂时先打印出来
        print('Shared text: $text');
      }
    });

    // 处理应用启动时的分享
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      final text = _extractTextFromShared(files);
      if (text != null && text.trim().isNotEmpty) {
        print('Initial shared text: $text');
        // 这里可以导航到输入页面并填充文本
      }
    });
  }

  static String? _extractTextFromShared(List<SharedMediaFile> files) {
    if (files.isEmpty) return null;
    // For text/url shares, `path` contains the text/url (per plugin docs).
    return files.first.path;
  }
}
