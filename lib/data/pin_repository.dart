import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinRepository {
  PinRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _pinKey = 'app_pin_v1';
  static const _saltLength = 16;

  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinKey, value: '$salt:$hash');
  }

  Future<bool> hasPin() async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored.isNotEmpty;
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null || stored.isEmpty) {
      return false;
    }
    final parts = stored.split(':');
    if (parts.length != 2) {
      return false;
    }
    final salt = parts[0];
    final expectedHash = parts[1];
    final actualHash = _hashPin(pin, salt);
    return _constantTimeEquals(expectedHash, actualHash);
  }

  Future<void> clearPin() => _storage.delete(key: _pinKey);

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64UrlEncode(saltBytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

