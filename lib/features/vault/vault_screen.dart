import 'package:flutter/material.dart';
import 'package:pass_manager/data/local/database_provider.dart';
import 'package:pass_manager/data/models/password_entry.dart';
import 'package:pass_manager/data/password_repository.dart';
import 'package:provider/provider.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  late final PasswordRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = PasswordRepository(DatabaseProvider.instance);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repository.loadEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _openEditor({PasswordEntry? entry}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AddEditPasswordScreen(
          repository: _repository,
          entry: entry,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PasswordEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete password'),
          content: Text('Delete "${entry.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (shouldDelete == true && entry.id != null) {
      await _repository.delete(entry.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${entry.title}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PasswordRepository>.value(
      value: _repository,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Passwords'),
          actions: [
            IconButton(
              icon: const Icon(Icons.backup_outlined),
              onPressed: () => Navigator.of(context).pushNamed('/backup'),
              tooltip: 'Backup & Restore',
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _query = '';
                              _searchController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
              ),
            ),
            Expanded(
              child: Consumer<PasswordRepository>(
                builder: (context, repository, _) {
                  final entries = repository.entries.where((entry) {
                    if (_query.isEmpty) return true;
                    final lower = _query.toLowerCase();
                    return entry.title.toLowerCase().contains(lower) ||
                        (entry.username?.toLowerCase().contains(lower) ?? false) ||
                        (entry.url?.toLowerCase().contains(lower) ?? false);
                  }).toList();

                  if (repository.isLoading && !repository.isInitialized) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          repository.isInitialized
                              ? 'No passwords yet. Tap the button below to add one.'
                              : 'Loading passwords…',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(entry.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (entry.username != null && entry.username!.isNotEmpty)
                                Text(entry.username!, style: const TextStyle(fontSize: 14)),
                              if (entry.url != null && entry.url!.isNotEmpty)
                                Text(
                                  entry.url!,
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              const SizedBox(height: 4),
                              const Text('Stored securely'),
                            ],
                          ),
                          onTap: () => _openEditor(entry: entry),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _openEditor(entry: entry);
                                  break;
                                case 'delete':
                                  _confirmDelete(entry);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: entries.length,
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ),
    );
  }
}

class _AddEditPasswordScreen extends StatefulWidget {
  const _AddEditPasswordScreen({
    required this.repository,
    this.entry,
  });

  final PasswordRepository repository;
  final PasswordEntry? entry;

  @override
  State<_AddEditPasswordScreen> createState() => _AddEditPasswordScreenState();
}

class _AddEditPasswordScreenState extends State<_AddEditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _notesCtrl;
  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleCtrl = TextEditingController(text: entry?.title ?? '');
    _usernameCtrl = TextEditingController(text: entry?.username ?? '');
    _passwordCtrl = TextEditingController();
    _urlCtrl = TextEditingController(text: entry?.url ?? '');
    _notesCtrl = TextEditingController(text: entry?.notes ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final title = _titleCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final url = _urlCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    try {
      if (_isEditing) {
        final id = widget.entry!.id;
        if (id == null) {
          throw StateError('Cannot update entry without id');
        }
        await widget.repository.update(
          id,
          title: title,
          username: username,
          password: password.isEmpty ? null : password,
          url: url,
          notes: notes,
        );
      } else {
        await widget.repository.create(
          title: title,
          username: username,
          password: password,
          url: url,
          notes: notes,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Password' : 'Add Password'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Password (leave blank to keep)' : 'Password',
              ),
              obscureText: true,
              validator: (value) {
                if (_isEditing) {
                  return null;
                }
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (value.length < 6) {
                  return 'Use at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Save changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

