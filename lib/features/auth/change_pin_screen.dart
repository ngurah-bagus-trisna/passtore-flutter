import 'package:flutter/material.dart';
import 'package:pass_manager/data/pin_repository.dart';

import 'widgets/pin_keypad.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

enum _ChangePinStage { verifyCurrent, newPin, confirmPin }

class _ChangePinScreenState extends State<ChangePinScreen> {
  final PinRepository _pinRepository = PinRepository();
  _ChangePinStage _stage = _ChangePinStage.verifyCurrent;
  String _input = '';
  String _newPin = '';
  bool _isProcessing = false;
  String? _error;

  void _onDigit(String digit) {
    if (_isProcessing) return;
    if (_input.length >= 6) return;
    setState(() {
      _input += digit;
    });
  }

  void _onBackspace() {
    if (_isProcessing || _input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _onSubmit() async {
    if (_isProcessing) return;
    if (_input.length < 4) {
      _showError('Enter at least 4 digits');
      return;
    }

    switch (_stage) {
      case _ChangePinStage.verifyCurrent:
        await _verifyCurrent();
        break;
      case _ChangePinStage.newPin:
        setState(() {
          _stage = _ChangePinStage.confirmPin;
          _newPin = _input;
          _input = '';
          _error = null;
        });
        break;
      case _ChangePinStage.confirmPin:
        await _completeChange();
        break;
    }
  }

  Future<void> _verifyCurrent() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    final isValid = await _pinRepository.verifyPin(_input);
    if (!mounted) return;
    if (isValid) {
      setState(() {
        _stage = _ChangePinStage.newPin;
        _input = '';
        _isProcessing = false;
      });
    } else {
      setState(() {
        _isProcessing = false;
        _input = '';
      });
      _showError('Incorrect current PIN');
    }
  }

  Future<void> _completeChange() async {
    if (_input != _newPin) {
      _showError('PINs do not match');
      setState(() {
        _input = '';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      await _pinRepository.savePin(_input);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _input = '';
        _stage = _ChangePinStage.verifyCurrent;
      });
      _showError('Failed to update PIN: $error');
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dotsFilled = _input.length;
    final prompt = switch (_stage) {
      _ChangePinStage.verifyCurrent => 'Enter your current PIN',
      _ChangePinStage.newPin => 'Choose a new PIN',
      _ChangePinStage.confirmPin => 'Confirm your new PIN',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prompt,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _PinDot(filled: index < dotsFilled),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PinKeypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onSubmit: _onSubmit,
                  submitIcon: switch (_stage) {
                    _ChangePinStage.verifyCurrent => Icons.arrow_forward,
                    _ChangePinStage.newPin => Icons.arrow_forward,
                    _ChangePinStage.confirmPin => Icons.check,
                  },
                ),
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
