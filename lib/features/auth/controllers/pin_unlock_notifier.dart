import 'package:flutter/foundation.dart';
import 'package:pass_manager/data/pin_repository.dart';

class PinUnlockNotifier extends ChangeNotifier {
  PinUnlockNotifier(this._repository);

  static const pinLength = 6;

  final PinRepository _repository;

  String _input = '';
  String? _errorMessage;
  bool _isVerifying = false;
  bool _isUnlocked = false;

  String get input => _input;
  String? get errorMessage => _errorMessage;
  bool get isVerifying => _isVerifying;
  bool get isUnlocked => _isUnlocked;

  void addDigit(String digit) {
    if (_isVerifying || _isUnlocked) {
      return;
    }
    if (_input.length >= pinLength) {
      return;
    }
    _input += digit;
    _errorMessage = null;
    notifyListeners();
    if (_input.length == pinLength) {
      _verify();
    }
  }

  void removeDigit() {
    if (_isVerifying || _input.isEmpty || _isUnlocked) {
      return;
    }
    _input = _input.substring(0, _input.length - 1);
    notifyListeners();
  }

  Future<void> _verify() async {
    _isVerifying = true;
    notifyListeners();
    final isValid = await _repository.verifyPin(_input);
    _isVerifying = false;
    if (isValid) {
      _isUnlocked = true;
      _input = '';
    } else {
      _errorMessage = 'Incorrect PIN. Try again.';
      _input = '';
    }
    notifyListeners();
  }

  void reset() {
    _input = '';
    _errorMessage = null;
    _isVerifying = false;
    _isUnlocked = false;
    notifyListeners();
  }
}

