import 'package:flutter/material.dart';
import 'package:pass_manager/app/app_router.dart';
import 'package:pass_manager/data/pin_repository.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attemptNavigation();
  }

  void _attemptNavigation() {
    if (_navigated) return;
    final repository = context.watch<PinRepository?>();
    if (repository == null) {
      return;
    }
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasPin = repository.hasPin();
      final target = hasPin ? AppRouter.pinUnlock : AppRouter.pinSetup;
      Navigator.of(context).pushReplacementNamed(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

