import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'local/database_provider.dart';
import 'models/password_entry.dart';

class PasswordRepository extends ChangeNotifier {
  PasswordRepository(this._databaseProvider);

  final DatabaseProvider _databaseProvider;

  final List<PasswordEntry> _entries = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<PasswordEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    final db = await _databaseProvider.database;
    final rows = await db.query(
      'passwords',
      orderBy: 'title COLLATE NOCASE ASC',
    );
    _entries
      ..clear()
      ..addAll(rows.map(PasswordEntry.fromMap));
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<PasswordEntry> create({
    required String title,
    String? username,
    required String password,
    String? url,
    String? notes,
  }) async {
    final now = DateTime.now();
    final normalizedTitle = title.trim();
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final entry = PasswordEntry(
      title: normalizedTitle,
      username: _normalize(username),
      secret: hash,
      salt: salt,
      url: _normalize(url),
      notes: _normalize(notes),
      createdAt: now,
      updatedAt: now,
    );

    final db = await _databaseProvider.database;
    final id = await db.insert('passwords', entry.toMap()..remove('id'));
    final saved = entry.copyWith(id: id);
    _entries.add(saved);
    _entries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    notifyListeners();
    return saved;
  }

  Future<void> update(
    int id, {
    required String title,
    String? username,
    String? password,
    String? url,
    String? notes,
  }) async {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) {
      throw StateError('Entry $id not found');
    }
    final original = _entries[index];
    final now = DateTime.now();
    final normalizedTitle = title.trim();
    final values = <String, Object?>{
      'title': normalizedTitle,
      'username': _normalize(username),
      'url': _normalize(url),
      'notes': _normalize(notes),
      'updated_at': now.millisecondsSinceEpoch,
    };

    PasswordEntry updated = original.copyWith(
      title: normalizedTitle,
      username: values['username'] as String?,
      url: values['url'] as String?,
      notes: values['notes'] as String?,
      updatedAt: now,
    );

    if (password != null && password.isNotEmpty) {
      final salt = _generateSalt();
      final hash = _hashPassword(password, salt);
      values['secret'] = hash;
      values['salt'] = salt;
      updated = updated.copyWith(secret: hash, salt: salt);
    }

    final db = await _databaseProvider.database;
    await db.update(
      'passwords',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );

    _entries[index] = updated;
    _entries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    notifyListeners();
  }

  Future<void> delete(int id) async {
    final db = await _databaseProvider.database;
    await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  Future<void> clear() async {
    final db = await _databaseProvider.database;
    await db.delete('passwords');
    _entries.clear();
    notifyListeners();
  }

  Future<void> replaceAll(List<PasswordEntry> entries) async {
    final db = await _databaseProvider.database;
    await db.transaction((txn) async {
      await txn.delete('passwords');
      for (final entry in entries) {
        await txn.insert(
          'passwords',
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    final sorted = List<PasswordEntry>.from(entries)
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    _entries
      ..clear()
      ..addAll(sorted);
    _isInitialized = true;
    notifyListeners();
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
