import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialMode = ThemeMode.system})
      : _mode = initialMode;

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggle() {
    if (_mode == ThemeMode.dark) {
      setMode(ThemeMode.light);
    } else {
      setMode(ThemeMode.dark);
    }
  }
}

