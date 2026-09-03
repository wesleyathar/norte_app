/// Retrato dos dados do usuário armazenado na nuvem.
///
/// [revision] é um contador monotônico usado para detectar qual dispositivo
/// tem a versão mais recente. [data] é o [FinanceSnapshot] serializado.
class CloudSnapshot {
  const CloudSnapshot({
    required this.deviceId,
    required this.revision,
    required this.updatedAt,
    required this.data,
  });

  final String deviceId;
  final int revision;
  final DateTime updatedAt;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'revision': revision,
    'updatedAt': updatedAt.toIso8601String(),
    'data': data,
  };

  factory CloudSnapshot.fromJson(Map<String, dynamic> json) => CloudSnapshot(
    deviceId: json['deviceId'] as String,
    revision: json['revision'] as int,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    data: Map<String, dynamic>.from(json['data'] as Map),
  );
}

/// Transporte de sincronização com a nuvem. Em produção seria uma API REST
/// sobre TLS com criptografia ponta a ponta; aqui é abstraído para testes.
abstract interface class CloudSyncService {
  /// Baixa o snapshot remoto, ou `null` se ainda não houver dados na nuvem.
  Future<CloudSnapshot?> download();

  /// Envia o snapshot local para a nuvem.
  Future<void> upload(CloudSnapshot snapshot);
}
