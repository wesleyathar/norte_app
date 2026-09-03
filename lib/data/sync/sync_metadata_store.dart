import 'package:hive_ce_flutter/hive_flutter.dart';

import '../local/secure_key_store.dart';

/// Estado local da sincronização, usado para decidir a direção (baixar/enviar).
class SyncMetadata {
  const SyncMetadata({
    required this.deviceId,
    this.baseRevision = 0,
    this.lastSyncedAt,
    this.lastSyncedHash,
  });

  /// Identificador estável deste dispositivo.
  final String deviceId;

  /// Revisão remota já reconciliada localmente.
  final int baseRevision;
  final DateTime? lastSyncedAt;

  /// Hash do último snapshot sincronizado, para detectar mudanças locais.
  final String? lastSyncedHash;

  SyncMetadata copyWith({
    int? baseRevision,
    DateTime? lastSyncedAt,
    String? lastSyncedHash,
  }) {
    return SyncMetadata(
      deviceId: deviceId,
      baseRevision: baseRevision ?? this.baseRevision,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSyncedHash: lastSyncedHash ?? this.lastSyncedHash,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'baseRevision': baseRevision,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'lastSyncedHash': lastSyncedHash,
  };

  factory SyncMetadata.fromJson(Map<String, dynamic> json) => SyncMetadata(
    deviceId: json['deviceId'] as String,
    baseRevision: json['baseRevision'] as int? ?? 0,
    lastSyncedAt: json['lastSyncedAt'] == null
        ? null
        : DateTime.parse(json['lastSyncedAt'] as String),
    lastSyncedHash: json['lastSyncedHash'] as String?,
  );
}

/// Persiste a [SyncMetadata]. Abstrai o backend para permitir testes.
abstract interface class SyncMetadataStore {
  Future<SyncMetadata> read();
  Future<void> write(SyncMetadata metadata);
}

/// Store em memória usado nos testes.
class InMemorySyncMetadataStore implements SyncMetadataStore {
  InMemorySyncMetadataStore({String deviceId = 'test-device'})
      : _metadata = SyncMetadata(deviceId: deviceId);

  SyncMetadata _metadata;

  @override
  Future<SyncMetadata> read() async => _metadata;

  @override
  Future<void> write(SyncMetadata metadata) async => _metadata = metadata;
}

/// Store sobre uma box Hive criptografada com AES-256.
class HiveSyncMetadataStore implements SyncMetadataStore {
  HiveSyncMetadataStore._(this._box);

  static const _boxName = 'sync_meta';
  static const _key = 'metadata';

  final Box<dynamic> _box;

  static Future<HiveSyncMetadataStore> open({
    SecureKeyStore keyStore = const SecureKeyStore(),
  }) async {
    final key = await keyStore.readOrCreate();
    final box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
    return HiveSyncMetadataStore._(box);
  }

  @override
  Future<SyncMetadata> read() async {
    final raw = _box.get(_key);
    if (raw is Map) {
      return SyncMetadata.fromJson(Map<String, dynamic>.from(raw));
    }
    // Primeira execução: gera um id de dispositivo estável e persiste.
    final metadata = SyncMetadata(
      deviceId: 'dev-${DateTime.now().microsecondsSinceEpoch}',
    );
    await write(metadata);
    return metadata;
  }

  @override
  Future<void> write(SyncMetadata metadata) async {
    await _box.put(_key, metadata.toJson());
  }
}
