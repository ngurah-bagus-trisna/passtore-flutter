import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pass_manager/data/password_repository.dart';
import 'package:pass_manager/features/backup/backup_service.dart';
import 'package:pass_manager/widgets/password_prompt_dialog.dart';
import 'package:provider/provider.dart';

class RestoreScreen extends StatefulWidget {
  const RestoreScreen({super.key});

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  PasswordRepository? _repository;
  BackupService? _service;
  List<File> _backups = <File>[];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = Provider.of<PasswordRepository?>(context);
    if (repository != null && repository != _repository) {
      _repository = repository;
      _service = BackupService(repository);
      _loadBackups();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Vault'),
        actions: [
          IconButton(
            onPressed: _isProcessing ? null : _loadBackups,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh backups',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Restore your vault from an encrypted backup file. '
                    'Existing entries will be replaced.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use the same password you provided when creating the backup.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_backups.isEmpty) {
      return const Center(
        child: Text('No backup files found. Create one from the backup screen.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final file = _backups[index];
        final modified = file.lastModifiedSync();
        final size = file.lengthSync();
        return Card(
          child: ListTile(
            title: Text(file.path.split(Platform.pathSeparator).last),
            subtitle: Text(
              'Updated ${modified.toLocal()} · ${(size / 1024).toStringAsFixed(1)} KB',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.restore_outlined),
              tooltip: 'Restore from backup',
              onPressed: () => _handleRestore(file),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _backups.length,
    );
  }

  Future<void> _loadBackups() async {
    if (_service == null) return;
    setState(() {
      _isLoading = true;
    });
    final files = await _service!.listBackups();
    if (!mounted) return;
    setState(() {
      _backups = files;
      _isLoading = false;
    });
  }

  Future<void> _handleRestore(File file) async {
    if (_service == null) return;
    final password = await showPasswordPromptDialog(
      context,
      title: 'Decrypt backup',
      message: 'Enter the password used when this backup was created.',
    );
    if (password == null) return;

    setState(() {
      _isProcessing = true;
    });
    try {
      final result = await _service!.restore(file, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored ${result.restoredCount} entries.'),
        ),
      );
      Navigator.of(context).pop(true);
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
        await _loadBackups();
      }
    }
  }
}

