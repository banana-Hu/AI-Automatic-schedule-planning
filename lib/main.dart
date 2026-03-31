import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/input_page.dart';
import 'pages/settings_page.dart';
import 'app_state.dart';
import 'data/event_repo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    final repo = EventRepo();
    // 确保数据库初始化完成
    await repo.db;
    runApp(MyApp(prefs: prefs, repo: repo));
  } catch (e) {
    print('Error initializing app: $e');
    // 即使初始化失败，也运行应用，避免在某些设备上完全显示不出来
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('应用初始化失败，请重启应用'),
        ),
      ),
    ));
  }
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
        title: '极简 AI 日程2.0',
        theme: ThemeData(useMaterial3: true),
        home: const HomePage(),
        routes: {
          '/input': (context) => const InputPage(),
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}
