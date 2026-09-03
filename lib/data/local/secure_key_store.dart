import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

/// Guarda a chave AES-256 do banco local no Keychain (iOS) / Keystore (Android).
/// A chave nunca é gravada em texto claro nem versionada.
class SecureKeyStore {
  const SecureKeyStore({this._storage = _defaultStorage});

  static const _defaultStorage = FlutterSecureStorage();
  static const _keyName = 'norte.db.key';

  final FlutterSecureStorage _storage;

  Future<List<int>> readOrCreate() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) return base64Decode(existing);

    final key = Hive.generateSecureKey();
    await _storage.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  Future<void> clear() => _storage.delete(key: _keyName);
}
