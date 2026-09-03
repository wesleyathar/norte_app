import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../local/secure_key_store.dart';
import 'naive_bayes_model.dart';

/// Persiste o modelo treinado. Abstrai o backend para permitir testes.
abstract interface class CategorizerStore {
  Future<NaiveBayesModel?> load();
  Future<void> save(NaiveBayesModel model);
}

/// Store em memória usado nos testes.
class InMemoryCategorizerStore implements CategorizerStore {
  NaiveBayesModel? _model;

  @override
  Future<NaiveBayesModel?> load() async => _model;

  @override
  Future<void> save(NaiveBayesModel model) async => _model = model;
}

/// Store sobre uma box Hive criptografada com AES-256.
class HiveCategorizerStore implements CategorizerStore {
  HiveCategorizerStore._(this._box);

  static const _boxName = 'ml_model';
  static const _modelKey = 'naive_bayes';

  final Box<dynamic> _box;

  static Future<HiveCategorizerStore> open({
    SecureKeyStore keyStore = const SecureKeyStore(),
  }) async {
    final key = await keyStore.readOrCreate();
    final box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
    return HiveCategorizerStore._(box);
  }

  @override
  Future<NaiveBayesModel?> load() async {
    final raw = _box.get(_modelKey) as String?;
    if (raw == null) return null;
    return NaiveBayesModel.fromJson(
      json.decode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(NaiveBayesModel model) async {
    await _box.put(_modelKey, json.encode(model.toJson()));
  }
}
