import 'package:flutter/foundation.dart';
import 'package:pass_manager/data/pin_repository.dart';

enum PinSetupStage { create, confirm, success }

class PinSetupNotifier extends ChangeNotifier {
  PinSetupNotifier(this._repository);

  static const pinLength = 6;

  final PinRepository _repository;

  PinSetupStage _stage = PinSetupStage.create;
  String _input = '';
  String? _firstEntry;
  String? _errorMessage;
  bool _isSaving = false;

  PinSetupStage get stage => _stage;
  String get input => _input;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  String get prompt {
    switch (_stage) {
      case PinSetupStage.create:
        return 'Create a 6-digit PIN';
      case PinSetupStage.confirm:
        return 'Confirm your PIN';
      case PinSetupStage.success:
        return 'PIN saved';
    }
  }

  void addDigit(String digit) {
    if (_isSaving || _stage == PinSetupStage.success) {
      return;
    }
    if (_input.length >= pinLength) {
      return;
    }
    _input += digit;
    _errorMessage = null;
    notifyListeners();
    if (_input.length == pinLength) {
      _handleComplete();
    }
  }

  void removeDigit() {
    if (_isSaving || _input.isEmpty || _stage == PinSetupStage.success) {
      return;
    }
    _input = _input.substring(0, _input.length - 1);
    notifyListeners();
  }

  Future<void> _handleComplete() async {
    if (_stage == PinSetupStage.create) {
      _firstEntry = _input;
      _input = '';
      _stage = PinSetupStage.confirm;
      notifyListeners();
      return;
    }
    if (_firstEntry != _input) {
      _errorMessage = 'PINs do not match. Try again.';
      _input = '';
      notifyListeners();
      return;
    }
    _isSaving = true;
    notifyListeners();
    await _repository.savePin(_input);
    _isSaving = false;
    _input = '';
    _firstEntry = null;
    _stage = PinSetupStage.success;
    notifyListeners();
  }

  void reset() {
    _stage = PinSetupStage.create;
    _input = '';
    _firstEntry = null;
    _errorMessage = null;
    _isSaving = false;
    notifyListeners();
  }
}

