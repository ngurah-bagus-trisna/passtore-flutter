import 'package:flutter/material.dart';
import 'package:pass_manager/data/pin_repository.dart';

import 'widgets/pin_keypad.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    super.key,
    this.onMissingPin,
    this.onUnlocked,
    this.allowSetupFallback = false,
  });

  final VoidCallback? onMissingPin;
  final VoidCallback? onUnlocked;
  final bool allowSetupFallback;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  String _pin = '';
  bool _isLoading = true;
  bool _isVerifying = false;
  late final PinRepository _pinRepository;

  @override
  void initState() {
    super.initState();
    _pinRepository = PinRepository();
    _ensurePinExists();
  }

  Future<void> _ensurePinExists() async {
    final hasPin = await _pinRepository.hasPin();
    if (!mounted) return;
    if (!hasPin) {
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.onMissingPin != null) {
          widget.onMissingPin!();
        } else {
          Navigator.of(context).pushReplacementNamed('/auth/setup');
        }
      });
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _onDigit(String d) {
    if (_isLoading || _isVerifying) return;
    setState(() {
      if (_pin.length < 6) _pin += d;
    });
  }

  void _onBackspace() {
    if (_isLoading || _isVerifying) return;
    setState(() {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _onSubmit() async {
    if (_isLoading || _isVerifying) return;

    if (_pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your PIN')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });
    final isValid = await _pinRepository.verifyPin(_pin);
    if (!mounted) {
      return;
    }
    setState(() {
      _isVerifying = false;
    });
    if (isValid) {
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else {
        Navigator.of(context).pushReplacementNamed('/vault');
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incorrect PIN')),
    );
    setState(() {
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Unlock')),
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
                    'Enter your PIN',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _PinDot(filled: i < _pin.length),
                      ),
                    ),
                  ),
                  if (widget.allowSetupFallback)
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/auth/setup'),
                      child: const Text('Set up PIN'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PinKeypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onSubmit: _onSubmit,
                  submitIcon: Icons.lock_open,
                ),
              ),
              if (_isVerifying)
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


