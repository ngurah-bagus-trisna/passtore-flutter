import 'package:flutter/material.dart';
import 'package:pass_manager/app/app_router.dart';
import 'package:pass_manager/app/session_controller.dart';
import 'package:pass_manager/data/pin_repository.dart';
import 'package:pass_manager/features/auth/controllers/pin_unlock_notifier.dart';
import 'package:pass_manager/widgets/pin_display.dart';
import 'package:pass_manager/widgets/pin_pad.dart';
import 'package:provider/provider.dart';

class PinUnlockScreen extends StatelessWidget {
  const PinUnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PinRepository?>();
    if (repository == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => PinUnlockNotifier(repository),
      child: const _PinUnlockView(),
    );
  }
}

class _PinUnlockView extends StatefulWidget {
  const _PinUnlockView();

  @override
  State<_PinUnlockView> createState() => _PinUnlockViewState();
}

class _PinUnlockViewState extends State<_PinUnlockView> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return Consumer<PinUnlockNotifier>(
      builder: (context, notifier, _) {
        if (notifier.isUnlocked && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            session.unlock();
            Navigator.of(context).pushReplacementNamed(AppRouter.vault);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Unlock Vault'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Text(
                    'Enter your 6-digit PIN',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  PinDisplay(
                    length: PinUnlockNotifier.pinLength,
                    filled: notifier.input.length,
                  ),
                  const SizedBox(height: 24),
                  if (notifier.errorMessage != null)
                    Text(
                      notifier.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (notifier.isVerifying) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                  const Spacer(),
                  PinPad(
                    onDigit: notifier.addDigit,
                    onBackspace: notifier.removeDigit,
                    onClear: notifier.reset,
                    isDisabled: notifier.isVerifying,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      notifier.reset();
                    },
                    child: const Text('Clear input'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

