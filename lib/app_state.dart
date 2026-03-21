import 'package:flutter/material.dart';
import 'data/event_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyApiKey = 'deepseek_api_key';

class AppState extends InheritedWidget {
  const AppState({
    super.key,
    required this.repo,
    required this.prefs,
    required super.child,
  });

  final EventRepo repo;
  final SharedPreferences prefs;

  static AppState of(BuildContext context) {
    final state = context.dependOnInheritedWidgetOfExactType<AppState>();
    assert(state != null, 'AppState not found');
    return state!;
  }

  String? get apiKey => prefs.getString(_keyApiKey);
  Future<void> setApiKey(String value) => prefs.setString(_keyApiKey, value);

  @override
  bool updateShouldNotify(AppState oldWidget) =>
      repo != oldWidget.repo || prefs != oldWidget.prefs;
}
