import 'package:flutter/material.dart';

/// Instituição financeira disponível para conexão via Open Finance.
class FinancialInstitution {
  const FinancialInstitution({
    required this.id,
    required this.name,
    required this.brandColor,
    required this.logoAsset,
    this.shortName,
  });

  final String id;
  final String name;
  final String? shortName;

  /// Cor da marca usada nos cartões e no fluxo de consentimento.
  final Color brandColor;

  /// Iniciais exibidas quando não há logo (placeholder tipográfico).
  final String logoAsset;

  String get displayName => shortName ?? name;
}

/// Escopo de dados que o usuário autoriza no consentimento Open Finance.
enum ConsentScope {
  accounts('Dados de contas', Icons.account_balance_outlined),
  balances('Saldos', Icons.account_balance_wallet_outlined),
  transactions('Histórico de transações', Icons.receipt_long_outlined),
  creditCards('Cartões de crédito', Icons.credit_card_outlined);

  const ConsentScope(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum ConnectionStatus { pending, active, expired, revoked }

/// Vínculo ativo entre o usuário e uma instituição após o consentimento.
class BankConnection {
  const BankConnection({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.status,
    required this.connectedAt,
    required this.consentExpiresAt,
    required this.scopes,
    this.lastSyncedAt,
  });

  final String id;
  final String institutionId;
  final String institutionName;
  final ConnectionStatus status;
  final DateTime connectedAt;
  final DateTime consentExpiresAt;
  final List<ConsentScope> scopes;
  final DateTime? lastSyncedAt;

  bool get isActive =>
      status == ConnectionStatus.active &&
      consentExpiresAt.isAfter(DateTime.now());

  BankConnection copyWith({
    ConnectionStatus? status,
    DateTime? lastSyncedAt,
  }) {
    return BankConnection(
      id: id,
      institutionId: institutionId,
      institutionName: institutionName,
      status: status ?? this.status,
      connectedAt: connectedAt,
      consentExpiresAt: consentExpiresAt,
      scopes: scopes,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'institutionId': institutionId,
        'institutionName': institutionName,
        'status': status.name,
        'connectedAt': connectedAt.toIso8601String(),
        'consentExpiresAt': consentExpiresAt.toIso8601String(),
        'scopes': [for (final s in scopes) s.name],
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };

  factory BankConnection.fromJson(Map<String, dynamic> json) => BankConnection(
        id: json['id'] as String,
        institutionId: json['institutionId'] as String,
        institutionName: json['institutionName'] as String,
        status: ConnectionStatus.values.byName(json['status'] as String),
        connectedAt: DateTime.parse(json['connectedAt'] as String),
        consentExpiresAt: DateTime.parse(json['consentExpiresAt'] as String),
        scopes: [
          for (final s in (json['scopes'] as List).cast<String>())
            ConsentScope.values.byName(s),
        ],
        lastSyncedAt: json['lastSyncedAt'] == null
            ? null
            : DateTime.parse(json['lastSyncedAt'] as String),
      );
}
