import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pass_manager/data/local/database_provider.dart';
import 'package:pass_manager/data/password_repository.dart';

import 'backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late final PasswordRepository _repository;
  late final BackupService _service;
  List<File> _backups = <File>[];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _repository = PasswordRepository(DatabaseProvider.instance);
    _service = BackupService(_repository);
    _loadBackups();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
    });
    final files = await _service.listBackups();
    if (!mounted) return;
    setState(() {
      _backups = files;
      _isLoading = false;
    });
  }

  Future<void> _handleCreateBackup() async {
    final password = await _promptPassword(
      title: 'Encrypt backup',
      description: 'Enter a password to encrypt your backup file. Keep it safe—'
          'you will need it to restore.',
      requireConfirmation: true,
    );
    if (password == null) return;

    setState(() {
      _isProcessing = true;
    });
    try {
      final result = await _service.createBackup(password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved (${result.entriesCount} entries)')), 
      );
      await _loadBackups();
    } on BackupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleRestore(File file) async {
    final password = await _promptPassword(
      title: 'Decrypt backup',
      description:
          'Enter the password that was used when this backup was created to restore your vault.',
      requireConfirmation: false,
    );
    if (password == null) return;

    setState(() {
      _isProcessing = true;
    });
    try {
      final result = await _service.restore(file, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored ${result.restoredCount} entries from backup.')),
      );
    } on BackupException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleDelete(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete backup'),
        content: Text('Delete ${file.path.split(Platform.pathSeparator).last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteBackup(file);
      await _loadBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup deleted.')),
      );
    }
  }

  Future<String?> _promptPassword({
    required String title,
    required String description,
    required bool requireConfirmation,
  }) async {
    final formKey = GlobalKey<FormState>();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a password';
                    }
                    if (value.length < 6) {
                      return 'Use at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (requireConfirmation) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm the password';
                      }
                      if (value != passwordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(passwordCtrl.text);
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    passwordCtrl.dispose();
    confirmCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Column(
        children: [
          if (_isProcessing) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Create encrypted backups of your vault. Files are stored on this device.'),
                SizedBox(height: 8),
                Text('Remember the password—you will need it to restore a backup.'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _handleCreateBackup,
                icon: const Icon(Icons.backup_outlined),
                label: const Text('Create backup'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backups.isEmpty
                    ? const Center(child: Text('No backups yet. Create one to get started.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _backups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final file = _backups[index];
                          final stat = file.statSync();
                          final title = file.path.split(Platform.pathSeparator).last;
                          final modified = stat.modified.toLocal();
                          final sizeKb = stat.size / 1024;
                          return Card(
                            child: ListTile(
                              title: Text(title),
                              subtitle: Text(
                                'Updated ${_formatTimestamp(modified)} • ${sizeKb.toStringAsFixed(1)} KB',
                              ),
                              onTap: _isProcessing ? null : () => _handleRestore(file),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'restore':
                                      _handleRestore(file);
                                      break;
                                    case 'delete':
                                      _handleDelete(file);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'restore', child: Text('Restore')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final date = '${timestamp.year.toString().padLeft(4, '0')}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')}';
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

