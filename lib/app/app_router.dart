import 'package:flutter/material.dart';
import 'package:pass_manager/features/auth/pin_setup_screen.dart';
import 'package:pass_manager/features/auth/pin_unlock_screen.dart';
import 'package:pass_manager/features/backup/backup_screen.dart';
import 'package:pass_manager/features/backup/restore_screen.dart';
import 'package:pass_manager/features/common/splash_screen.dart';
import 'package:pass_manager/features/settings/settings_screen.dart';
import 'package:pass_manager/features/vault/password_form_screen.dart';
import 'package:pass_manager/features/vault/vault_home_screen.dart';

class AppRouter {
  static const splash = '/';
  static const pinSetup = '/pin-setup';
  static const pinUnlock = '/pin-unlock';
  static const vault = '/vault';
  static const passwordForm = '/password-form';
  static const backup = '/backup';
  static const restore = '/restore';
  static const settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _materialRoute(const SplashScreen(), settings);
      case pinSetup:
        return _materialRoute(const PinSetupScreen(), settings);
      case pinUnlock:
        return _materialRoute(const PinUnlockScreen(), settings);
      case vault:
        return _materialRoute(const VaultHomeScreen(), settings);
      case passwordForm:
        final screen = PasswordFormScreen.fromArguments(settings.arguments);
        return _materialRoute(screen, settings);
      case backup:
        return _materialRoute(const BackupScreen(), settings);
      case restore:
        return _materialRoute(const RestoreScreen(), settings);
      case settings:
        return _materialRoute(const SettingsScreen(), settings);
      default:
        return _materialRoute(
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<T> _materialRoute<T>(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      builder: (_) => child,
      settings: settings,
    );
  }
}

