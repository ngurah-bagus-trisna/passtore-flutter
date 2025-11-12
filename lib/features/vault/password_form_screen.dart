import 'package:flutter/material.dart';
import 'package:pass_manager/data/password_repository.dart';
import 'package:pass_manager/features/vault/password_form_arguments.dart';
import 'package:pass_manager/models/password_entry.dart'
    show PasswordEntry, PasswordEntryInput;
import 'package:provider/provider.dart';

class PasswordFormScreen extends StatefulWidget {
  const PasswordFormScreen({super.key, this.initialEntry});

  final PasswordEntry? initialEntry;

  @override
  State<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends State<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;
  bool _isSaving = false;

  bool get _isEditing => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _usernameController = TextEditingController(text: entry?.username ?? '');
    _passwordController = TextEditingController();
    _notesController = TextEditingController(text: entry?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Password' : 'Add Password'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Email account',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. user@example.com',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: _isEditing ? 'Leave blank to keep current hash' : 'Enter password',
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (_isEditing) {
                    return null;
                  }
                  if (value == null || value.trim().isEmpty) {
                    return 'Password is required';
                  }
                  if (value.trim().length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Passwords are stored using secure hashing. '
                    'The original password cannot be retrieved after saving.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _handleSubmit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'Save changes' : 'Save password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final repository = context.read<PasswordRepository?>();
    if (repository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage not ready. Please try again.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    final input = PasswordEntryInput(
      id: widget.initialEntry?.id,
      title: _titleController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      await repository.save(input);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

extension PasswordFormRoute on PasswordFormScreen {
  static PasswordFormScreen fromArguments(Object? arguments) {
    if (arguments is PasswordFormArguments) {
      return PasswordFormScreen(initialEntry: arguments.entry);
    }
    return const PasswordFormScreen();
  }
}

