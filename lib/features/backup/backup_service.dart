import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pass_manager/data/models/password_entry.dart';
import 'package:pass_manager/data/password_repository.dart';

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException: $message';
}

class BackupService {
  BackupService(this._repository);

  final PasswordRepository _repository;
  static const _extension = '.pmvault';

  Future<BackupResult> createBackup(String password) async {
    if (!_repository.isInitialized) {
      await _repository.loadEntries();
    }
    final entries = List<PasswordEntry>.from(_repository.entries);
    final directory = await _ensureDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(directory.path, 'backup_$timestamp$_extension'));

    final payload = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': entries.map((entry) => entry.toMap()).toList(),
    };

    final salt = _randomBytes(16);
    final ivBytes = _randomBytes(16);
    final key = _deriveKey(password, salt);

    final encrypter = Encrypter(
      AES(Key(key), mode: AESMode.cbc, padding: 'PKCS7'),
    );
    final iv = IV(ivBytes);
    final encrypted = encrypter.encrypt(jsonEncode(payload), iv: iv);

    final backupContent = jsonEncode({
      'version': 1,
      'salt': base64Encode(salt),
      'iv': base64Encode(ivBytes),
      'cipherText': encrypted.base64,
    });

    await file.writeAsString(backupContent);
    return BackupResult(file: file, entriesCount: entries.length);
  }

  Future<RestoreResult> restore(File file, String password) async {
    if (!await file.exists()) {
      throw BackupException('Backup file not found.');
    }
    final content = await file.readAsString();
    final wrapper = jsonDecode(content) as Map<String, dynamic>;
    final version = wrapper['version'] as int? ?? 0;
    if (version != 1) {
      throw BackupException('Unsupported backup version.');
    }
    final salt = Uint8List.fromList(base64Decode(wrapper['salt'] as String));
    final ivBytes = Uint8List.fromList(base64Decode(wrapper['iv'] as String));
    final cipherText = wrapper['cipherText'] as String;

    final key = _deriveKey(password, salt);
    final encrypter = Encrypter(
      AES(Key(key), mode: AESMode.cbc, padding: 'PKCS7'),
    );
    final iv = IV(ivBytes);

    String decrypted;
    try {
      decrypted = encrypter.decrypt64(cipherText, iv: iv);
    } catch (_) {
      throw BackupException('Incorrect password or corrupted backup.');
    }

    final data = jsonDecode(decrypted) as Map<String, dynamic>;
    final entriesRaw = (data['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
    final entries = entriesRaw.map(PasswordEntry.fromMap).toList();

    await _repository.replaceAll(entries);

    return RestoreResult(file: file, restoredCount: entries.length);
  }

  Future<List<File>> listBackups() async {
    final directory = await _ensureDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith(_extension))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<void> deleteBackup(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _ensureDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(baseDir.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    final digest = sha256.convert(utf8.encode('$password:${base64Encode(salt)}'));
    return Uint8List.fromList(digest.bytes);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return Uint8List.fromList(bytes);
  }
}

class BackupResult {
  BackupResult({
    required this.file,
    required this.entriesCount,
  });

  final File file;
  final int entriesCount;
}

class RestoreResult {
  RestoreResult({
    required this.file,
    required this.restoredCount,
  });

  final File file;
  final int restoredCount;
}

