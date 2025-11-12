import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../features/auth/pin_setup_screen.dart';
import '../features/auth/unlock_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/backup/backup_screen.dart';
import '../features/auth/change_pin_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pass Manager',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      initialRoute: '/auth/entry',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/auth/entry':
            return MaterialPageRoute(
              builder: (context) => UnlockScreen(
                onMissingPin: () =>
                    Navigator.of(context).pushReplacementNamed('/auth/setup'),
                onUnlocked: () =>
                    Navigator.of(context).pushReplacementNamed('/vault'),
              ),
              settings: settings,
            );
          case '/auth/setup':
            return MaterialPageRoute(
              builder: (context) => PinSetupScreen(
                onCompleted: () =>
                    Navigator.of(context).pushReplacementNamed('/vault'),
              ),
              settings: settings,
            );
          case '/vault':
            return MaterialPageRoute(
              builder: (_) => const VaultScreen(),
              settings: settings,
            );
          case '/backup':
            return MaterialPageRoute(
              builder: (_) => const BackupScreen(),
              settings: settings,
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (context) => SettingsScreen(
                themeMode: _themeMode,
                onThemeModeChanged: _setThemeMode,
              ),
              settings: settings,
            );
          case '/auth/change':
            return MaterialPageRoute(
              builder: (_) => const ChangePinScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => UnlockScreen(
                onMissingPin: () =>
                    Navigator.of(context).pushReplacementNamed('/auth/setup'),
                onUnlocked: () =>
                    Navigator.of(context).pushReplacementNamed('/vault'),
              ),
            );
        }
      },
    );
  }
}
