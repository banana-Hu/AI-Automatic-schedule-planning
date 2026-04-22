import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/input_page.dart';
import 'pages/settings_page.dart';
import 'app_state.dart';
import 'data/event_repo.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.cardBackground,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final repo = EventRepo();
    await repo.db;
    runApp(MyApp(prefs: prefs, repo: repo));
  } catch (e) {
    print('Error initializing app: $e');
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
        title: '我的日程本',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cuteTheme,
        home: const HomePage(),
        routes: {
          '/input': (context) => const InputPage(),
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}
