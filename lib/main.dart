import 'package:flutter/material.dart';
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
