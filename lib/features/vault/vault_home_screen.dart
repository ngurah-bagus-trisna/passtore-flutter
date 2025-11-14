import 'package:flutter/material.dart';
import 'package:pass_manager/app/app_router.dart';
import 'package:pass_manager/app/session_controller.dart';
import 'package:pass_manager/data/password_repository.dart';
import 'package:pass_manager/features/vault/controllers/password_list_notifier.dart';
import 'package:pass_manager/features/vault/password_form_arguments.dart';
import 'package:pass_manager/models/password_entry.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:pass_manager/data/crypto/crypto_helper.dart';

enum _VaultMenu { backup, restore, lock }

class VaultHomeScreen extends StatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  bool _redirecting = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (!session.isUnlocked && !_redirecting) {
      _redirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.pinUnlock);
      });
    }

    final repository = context.watch<PasswordRepository?>();
    if (repository == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => PasswordListNotifier(repository)..load(),
      child: const _VaultView(),
    );
  }
}

class _VaultView extends StatefulWidget {
  const _VaultView();

  @override
  State<_VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<_VaultView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordListNotifier>(
      builder: (context, notifier, _) {
        if (_searchController.text != notifier.query) {
          _searchController.value = _searchController.value.copyWith(
            text: notifier.query,
            selection: TextSelection.collapsed(offset: notifier.query.length),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Password Vault'),
            actions: [
              PopupMenuButton<_VaultMenu>(
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _VaultMenu.backup,
                    child: ListTile(
                      leading: Icon(Icons.cloud_upload_outlined),
                      title: Text('Backup'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _VaultMenu.restore,
                    child: ListTile(
                      leading: Icon(Icons.restore_outlined),
                      title: Text('Restore'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _VaultMenu.lock,
                    child: ListTile(
                      leading: Icon(Icons.lock_outlined),
                      title: Text('Lock app'),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.settings);
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by title or username',
                    ),
                    onChanged: notifier.updateQuery,
                  ),
                ),
                Expanded(
                  child: _buildContent(context, notifier),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, PasswordListNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.errorMessage != null) {
      return Center(
        child: Text(
          notifier.errorMessage!,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!notifier.hasResults) {
      return RefreshIndicator(
        onRefresh: notifier.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 96),
            Icon(Icons.vpn_key_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'No passwords stored yet.\nTap Add to create one.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final entry = notifier.items[index];
          return _PasswordTile(
            entry: entry,
            onTap: () => _showEntry(context, entry),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: notifier.items.length,
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {PasswordEntry? entry}) async {
    final shouldRefresh = await Navigator.of(context).pushNamed(
      AppRouter.passwordForm,
      arguments: PasswordFormArguments(entry: entry),
    );
    if (shouldRefresh == true && context.mounted) {
      await context.read<PasswordListNotifier>().load();
    }
  }

  Future<void> _handleMenuAction(BuildContext context, _VaultMenu action) async {
    switch (action) {
      case _VaultMenu.backup:
        await Navigator.of(context).pushNamed(AppRouter.backup);
        break;
      case _VaultMenu.restore:
        final restored = await Navigator.of(context).pushNamed(AppRouter.restore);
        if (restored == true && context.mounted) {
          await context.read<PasswordListNotifier>().load();
        }
        break;
      case _VaultMenu.lock:
        context.read<SessionController>().lock();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(AppRouter.pinUnlock);
        }
        break;
    }
  }

  void _showEntry(BuildContext context, PasswordEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(entry.title),
                  // show username if present
                  subtitle: (entry.username != null && entry.username!.isNotEmpty) ? Text(entry.username!) : null,
                ),
                const SizedBox(height: 8),
                if (entry.username != null && entry.username!.isNotEmpty) ...[
                  Text('Username', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  SelectableText(entry.username!),
                  const SizedBox(height: 12),
                ],

                Text('Password (stored hash)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                // Use a StatefulBuilder so the reveal toggle affects only the sheet
                (() {
                  var revealed = false;
                  String? decrypted;
                  return StatefulBuilder(builder: (context, setState) {
                    String display;
                    if (revealed) {
                      display = decrypted ?? entry.secret;
                    } else {
                      display = entry.secret.length <= 8 ? entry.secret : '${entry.secret.substring(0, 6)}••';
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            display,
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: revealed ? (decrypted ?? entry.secret) : entry.secret));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied value to clipboard')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: revealed ? 'Hide' : 'Show',
                          icon: Icon(revealed ? Icons.visibility_off : Icons.visibility),
                          onPressed: () async {
                            if (!revealed) {
                              // attempt to decrypt if encryptedSecret present
                              if (entry.encryptedSecret != null) {
                                final dec = await CryptoHelper.decrypt(entry.encryptedSecret);
                                decrypted = dec;
                              }
                            }
                            setState(() => revealed = !revealed);
                          },
                        ),
                      ],
                    );
                  });
                }()),
                const SizedBox(height: 12),
                if ((entry.notes ?? '').isNotEmpty) ...[
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(entry.notes!),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Updated ${_formatDate(entry.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openForm(context, entry: entry);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _confirmDelete(context, entry);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, PasswordEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete password'),
          content: Text('This will remove ${entry.title}. This action cannot be undone.'),
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
        );
      },
    );
    if (confirmed == true && context.mounted) {
      final id = entry.id;
      if (id != null) {
        await context.read<PasswordListNotifier>().deleteEntry(id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.title} deleted')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays >= 1) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }
}

class _PasswordTile extends StatelessWidget {
  const _PasswordTile({
    required this.entry,
    required this.onTap,
  });

  final PasswordEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(entry.title),
        // Only show the title on the homepage list. Details (username, stored
        // secret/hash, notes) appear in the detail popup when tapped.
        subtitle: null,
        isThreeLine: false,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

