import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small helper that stores an AES key in secure storage and provides
/// encrypt/decrypt helpers. This keeps the key off the DB. It's a simple
/// approach suitable for local device-only encryption.
class CryptoHelper {
  CryptoHelper._();

  static const _storageKey = 'pass_manager_aes_key_v1';
  static final _secureStorage = FlutterSecureStorage();

  static Future<Encrypter> _getEncrypter() async {
    final keyString = await _secureStorage.read(key: _storageKey);
    if (keyString == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      final newKey = base64UrlEncode(bytes);
      await _secureStorage.write(key: _storageKey, value: newKey);
      final key = Key.fromBase64(newKey);
      return Encrypter(AES(key, mode: AESMode.cbc));
    }
    final key = Key.fromBase64(keyString);
    return Encrypter(AES(key, mode: AESMode.cbc));
  }

  static Future<String> encrypt(String plaintext) async {
    final encrypter = await _getEncrypter();
    final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final iv = IV(Uint8List.fromList(ivBytes));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    // store as base64(iv)|base64(cipher)
    return '${base64UrlEncode(iv.bytes)}|${encrypted.base64}';
  }

  static Future<String?> decrypt(String? ciphertext) async {
    if (ciphertext == null) return null;
    final parts = ciphertext.split('|');
    if (parts.length != 2) return null;
    final ivBase64 = parts[0];
    final cipherBase64 = parts[1];
    final iv = IV(base64Url.decode(ivBase64));
    final encrypter = await _getEncrypter();
    try {
      final decrypted = encrypter.decrypt(Encrypted.fromBase64(cipherBase64), iv: iv);
      return decrypted;
    } catch (_) {
      return null;
    }
  }
}
