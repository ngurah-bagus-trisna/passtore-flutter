import 'package:flutter/foundation.dart';

class SessionController extends ChangeNotifier {
  bool _isUnlocked = false;

  bool get isUnlocked => _isUnlocked;

  void unlock() {
    if (_isUnlocked) return;
    _isUnlocked = true;
    notifyListeners();
  }

  void lock() {
    if (!_isUnlocked) return;
    _isUnlocked = false;
    notifyListeners();
  }
}

