import 'package:flutter/material.dart';
import 'package:pass_manager/data/pin_repository.dart';

import 'widgets/pin_keypad.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({
    super.key,
    this.onCompleted,
    this.title = 'Create PIN',
    this.choosePrompt = 'Choose a 4–6 digit PIN',
    this.confirmPrompt = 'Confirm your PIN',
  });

  final VoidCallback? onCompleted;
  final String title;
  final String choosePrompt;
  final String confirmPrompt;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isSaving = false;
  late final PinRepository _pinRepository;

  @override
  void initState() {
    super.initState();
    _pinRepository = PinRepository();
  }

  void _onDigit(String d) {
    if (_isSaving) return;
    setState(() {
      if (!_isConfirming) {
        if (_pin.length < 6) _pin += d;
      } else {
        if (_confirmPin.length < 6) _confirmPin += d;
      }
    });
  }

  void _onBackspace() {
    if (_isSaving) return;
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _onSubmit() async {
    if (_isSaving) return;

    if (!_isConfirming) {
      if (_pin.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter at least 4 digits')),
        );
        return;
      }
      setState(() {
        _isConfirming = true;
        _confirmPin = '';
      });
      return;
    }

    if (_confirmPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm your 4–6 digit PIN')),
      );
      return;
    }

    if (_pin == _confirmPin) {
      setState(() {
        _isSaving = true;
      });
      try {
        await _pinRepository.savePin(_pin);
        if (!mounted) return;
        if (widget.onCompleted != null) {
          widget.onCompleted!();
        } else {
          Navigator.of(context).pushReplacementNamed('/vault');
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PIN: $error')),
        );
        setState(() {
          _isSaving = false;
        });
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PINs do not match')),
    );
    setState(() {
      _confirmPin = '';
      _isConfirming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final length = _isConfirming ? _confirmPin.length : _pin.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                    _isConfirming ? widget.confirmPrompt : widget.choosePrompt,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _PinDot(filled: i < length),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PinKeypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onSubmit: _onSubmit,
                  submitIcon: Icons.check,
                ),
              ),
              if (_isSaving)
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

