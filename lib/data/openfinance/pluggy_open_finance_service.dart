import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/budget.dart';
import '../../domain/models/institution.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/tx_category.dart';
import '../../domain/services/open_finance_service.dart';
import 'pluggy/pluggy_connect.dart';

/// Integração real com o Open Finance via agregador Pluggy.
///
/// O widget Pluggy Connect (web) cuida da seleção do banco, login e
/// consentimento. As credenciais ficam apenas nas funções serverless da Vercel
/// (`/api/pluggy/*`); o app nunca vê o client secret.
class PluggyOpenFinanceService implements OpenFinanceService {
  const PluggyOpenFinanceService();

  static const _institutions = <FinancialInstitution>[
    FinancialInstitution(
      id: 'itau',
      name: 'Itaú Unibanco S.A.',
      shortName: 'Itaú',
      brandColor: Color(0xFFEC7000),
      logoAsset: 'It',
    ),
    FinancialInstitution(
      id: 'nubank',
      name: 'Nu Pagamentos S.A.',
      shortName: 'Nubank',
      brandColor: Color(0xFF820AD1),
      logoAsset: 'Nu',
    ),
    FinancialInstitution(
      id: 'bradesco',
      name: 'Banco Bradesco S.A.',
      shortName: 'Bradesco',
      brandColor: Color(0xFFCC092F),
      logoAsset: 'Br',
    ),
    FinancialInstitution(
      id: 'bb',
      name: 'Banco do Brasil S.A.',
      shortName: 'Banco do Brasil',
      brandColor: Color(0xFFFAE128),
      logoAsset: 'BB',
    ),
    FinancialInstitution(
      id: 'santander',
      name: 'Banco Santander (Brasil) S.A.',
      shortName: 'Santander',
      brandColor: Color(0xFFEC0000),
      logoAsset: 'Sa',
    ),
    FinancialInstitution(
      id: 'inter',
      name: 'Banco Inter S.A.',
      shortName: 'Inter',
      brandColor: Color(0xFFFF7A00),
      logoAsset: 'In',
    ),
    FinancialInstitution(
      id: 'c6',
      name: 'Banco C6 S.A.',
      shortName: 'C6 Bank',
      brandColor: Color(0xFF242424),
      logoAsset: 'C6',
    ),
    FinancialInstitution(
      id: 'caixa',
      name: 'Caixa Econômica Federal',
      shortName: 'Caixa',
      brandColor: Color(0xFF005CA9),
      logoAsset: 'CE',
    ),
  ];

  @override
  Future<List<FinancialInstitution>> availableInstitutions() async {
    return _institutions;
  }

  @override
  Future<BankConnection> connect({
    required FinancialInstitution institution,
    required List<ConsentScope> scopes,
  }) async {
    final connectToken = await _fetchConnectToken();
    final PluggyConnectResult result;
    try {
      result = await launchPluggyConnect(connectToken);
    } on PluggyConnectCancelled {
      throw Exception('Conexão cancelada.');
    } on PluggyConnectException catch (e) {
      throw Exception(e.message);
    }

    final now = DateTime.now();
    return BankConnection(
      id: result.itemId,
      institutionId: institution.id,
      institutionName: result.connectorName ?? institution.displayName,
      status: ConnectionStatus.active,
      connectedAt: now,
      // Consentimento Open Finance dura no máximo 12 meses.
      consentExpiresAt: now.add(const Duration(days: 365)),
      scopes: scopes,
    );
  }

  @override
  Future<SyncResult> sync(BankConnection connection) async {
    final uri = _apiUri('/api/pluggy/data')
        .replace(queryParameters: {'itemId': connection.id});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Falha ao importar dados (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawAccounts = (body['accounts'] as List? ?? const []);
    final rawTransactions = (body['transactions'] as List? ?? const []);

    final accounts = <Account>[
      for (final a in rawAccounts.cast<Map<String, dynamic>>())
        Account(
          id: a['id'] as String,
          bankName: (a['bankName'] as String?) ?? connection.institutionName,
          type: (a['type'] as String?) ?? 'Conta',
          balance: (a['balance'] as num?)?.toDouble() ?? 0,
        ),
    ];

    final transactions = <Transaction>[
      for (final t in rawTransactions.cast<Map<String, dynamic>>())
        Transaction(
          id: t['id'] as String,
          description: (t['description'] as String?) ?? 'Transação',
          amount: (t['amount'] as num?)?.toDouble() ?? 0,
          date: _parseDate(t['date']),
          category: _categoryFor(
            (t['amount'] as num?)?.toDouble() ?? 0,
            (t['description'] as String?) ?? '',
          ),
          accountName:
              (t['accountName'] as String?) ?? connection.institutionName,
        ),
    ];

    return SyncResult(accounts: accounts, transactions: transactions);
  }

  @override
  Future<void> revoke(BankConnection connection) async {
    final uri = _apiUri('/api/pluggy/delete-item');
    await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'itemId': connection.id}),
    );
  }

  Future<String> _fetchConnectToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final response = await http.post(
      _apiUri('/api/pluggy/connect-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'clientUserId': ?uid}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível iniciar a conexão (${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Token de conexão inválido.');
    }
    return token;
  }

  Uri _apiUri(String path) => Uri.base.resolve(path);

  static DateTime _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  // Créditos são tratados como entrada; débitos ficam em "outros" para a IA
  // classificar em seguida no ConnectionsCubit.
  static TxCategory _categoryFor(double amount, String description) {
    if (amount > 0) {
      final normalized = description.toUpperCase();
      if (normalized.contains('SALARIO') ||
          normalized.contains('SALÁRIO') ||
          normalized.contains('PROVENTO') ||
          normalized.contains('VENCIMENTO')) {
        return TxCategory.salario;
      }
      return TxCategory.transferencia;
    }
    return TxCategory.outros;
  }
}
