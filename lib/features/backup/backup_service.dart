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
  static const _jsonExtension = '.json';
  static const _csvExtension = '.csv';

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

  /// Create a plain JSON export (not encrypted). Includes same map format as
  /// the encrypted payload (entries as maps). This file can be used to restore
  /// later on the same app.
  Future<BackupResult> createJsonExport() async {
    if (!_repository.isInitialized) {
      await _repository.loadEntries();
    }
    final entries = List<PasswordEntry>.from(_repository.entries);
    final directory = await _ensureDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(directory.path, 'export_$timestamp$_jsonExtension'));

    final payload = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': entries.map((entry) => entry.toMap()).toList(),
    };

    await file.writeAsString(jsonEncode(payload));
    return BackupResult(file: file, entriesCount: entries.length);
  }

  /// Create a CSV export. Columns match the map keys. encrypted_secret field
  /// is included so the export can be restored without plaintext.
  Future<BackupResult> createCsvExport() async {
    if (!_repository.isInitialized) {
      await _repository.loadEntries();
    }
    final entries = List<PasswordEntry>.from(_repository.entries);
    final directory = await _ensureDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(directory.path, 'export_$timestamp$_csvExtension'));

    final headers = [
      'id',
      'title',
      'username',
      'secret',
      'salt',
      'encrypted_secret',
      'url',
      'notes',
      'created_at',
      'updated_at',
    ];

    String escape(String? v) {
      if (v == null) return '';
      final s = v.replaceAll('"', '""');
      return '"$s"';
    }

    final sb = StringBuffer();
    sb.writeln(headers.join(','));
    for (final entry in entries) {
      final map = entry.toMap();
      final row = headers.map((h) => escape(map[h]?.toString())).join(',');
      sb.writeln(row);
    }
    await file.writeAsString(sb.toString());
    return BackupResult(file: file, entriesCount: entries.length);
  }

  Future<RestoreResult> restore(File file, String password) async {
    if (!await file.exists()) {
      throw BackupException('Backup file not found.');
    }
    final ext = p.extension(file.path).toLowerCase();
    if (ext == _extension) {
      // encrypted .pmvault
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
    } else if (ext == _jsonExtension) {
      // plain JSON export
      final content = await file.readAsString();
      final wrapper = jsonDecode(content) as Map<String, dynamic>;
      final entriesRaw = (wrapper['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
      final entries = entriesRaw.map(PasswordEntry.fromMap).toList();
      await _repository.replaceAll(entries);
      return RestoreResult(file: file, restoredCount: entries.length);
    } else if (ext == _csvExtension) {
      final content = await file.readAsString();
      final lines = const LineSplitter().convert(content);
      if (lines.isEmpty) {
        throw BackupException('CSV is empty');
      }
      final headers = lines.first.split(',').map((h) => h.trim()).toList();
      final entries = <PasswordEntry>[];
      for (final line in lines.skip(1)) {
        if (line.trim().isEmpty) continue;
        // crude CSV parsing: remove surrounding quotes and unescape double quotes
        final cols = <String>[];
        var i = 0;
        while (i < line.length) {
          if (line[i] == '"') {
            final sb = StringBuffer();
            i++; // skip quote
            while (i < line.length) {
              if (line[i] == '"' && i + 1 < line.length && line[i + 1] == '"') {
                sb.write('"');
                i += 2;
                continue;
              }
              if (line[i] == '"') {
                i++; // skip closing quote
                break;
              }
              sb.write(line[i]);
              i++;
            }
            // skip comma
            if (i < line.length && line[i] == ',') i++;
            cols.add(sb.toString());
          } else {
            final start = i;
            while (i < line.length && line[i] != ',') i++;
            cols.add(line.substring(start, i));
            if (i < line.length && line[i] == ',') i++;
          }
        }
        final map = <String, Object?>{};
        for (var j = 0; j < headers.length && j < cols.length; j++) {
          map[headers[j]] = cols[j];
        }
        // convert numeric timestamps
        if (map['created_at'] != null && map['created_at'] is String) {
          map['created_at'] = int.tryParse(map['created_at'] as String) ?? 0;
        }
        if (map['updated_at'] != null && map['updated_at'] is String) {
          map['updated_at'] = int.tryParse(map['updated_at'] as String) ?? 0;
        }
        entries.add(PasswordEntry.fromMap(map));
      }
      await _repository.replaceAll(entries);
      return RestoreResult(file: file, restoredCount: entries.length);
    }
    throw BackupException('Unsupported backup file type.');
  }

  Future<List<File>> listBackups() async {
    final directory = await _ensureDirectory();
  final files = directory
    .listSync()
    .whereType<File>()
    .where((file) => file.path.endsWith(_extension) || file.path.endsWith(_jsonExtension) || file.path.endsWith(_csvExtension))
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

