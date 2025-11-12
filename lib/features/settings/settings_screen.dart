import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Appearance', style: TextStyle(fontSize: 16)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (m) => onThemeModeChanged(m ?? ThemeMode.system),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (m) => onThemeModeChanged(m ?? ThemeMode.light),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (m) => onThemeModeChanged(m ?? ThemeMode.dark),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Security', style: TextStyle(fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Change PIN'),
            subtitle: const Text('Update the PIN used to unlock the vault'),
            onTap: () async {
              final result = await Navigator.of(context).pushNamed('/auth/change');
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN updated successfully')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
