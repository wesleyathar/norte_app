import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/budget.dart';
import '../../domain/models/institution.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/tx_category.dart';
import '../../domain/services/open_finance_service.dart';

/// Implementação simulada do Open Finance para desenvolvimento e demonstração.
///
/// Reproduz latência de rede, o fluxo de consentimento e a geração de dados
/// bancários. Trocar por uma implementação real não afeta o restante do app,
/// pois ambas respeitam [OpenFinanceService].
class MockOpenFinanceService implements OpenFinanceService {
  const MockOpenFinanceService();

  static const _institutions = <FinancialInstitution>[
    FinancialInstitution(
      id: 'nubank',
      name: 'Nu Pagamentos S.A.',
      shortName: 'Nubank',
      brandColor: Color(0xFF820AD1),
      logoAsset: 'Nu',
    ),
    FinancialInstitution(
      id: 'itau',
      name: 'Itaú Unibanco S.A.',
      shortName: 'Itaú',
      brandColor: Color(0xFFEC7000),
      logoAsset: 'It',
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
    await _networkDelay();
    return _institutions;
  }

  @override
  Future<BankConnection> connect({
    required FinancialInstitution institution,
    required List<ConsentScope> scopes,
  }) async {
    await _networkDelay(min: 1200, max: 2200);
    final now = DateTime.now();
    return BankConnection(
      id: 'conn_${institution.id}_${now.millisecondsSinceEpoch}',
      institutionId: institution.id,
      institutionName: institution.displayName,
      status: ConnectionStatus.active,
      connectedAt: now,
      // Consentimento Open Finance dura no máximo 12 meses.
      consentExpiresAt: now.add(const Duration(days: 365)),
      scopes: scopes,
    );
  }

  @override
  Future<SyncResult> sync(BankConnection connection) async {
    await _networkDelay(min: 900, max: 1800);
    final rng = Random(connection.id.hashCode);
    final accounts = _accountsFor(connection, rng);
    final transactions = _transactionsFor(connection, accounts, rng);
    return SyncResult(accounts: accounts, transactions: transactions);
  }

  @override
  Future<void> revoke(BankConnection connection) async {
    await _networkDelay();
  }

  List<Account> _accountsFor(BankConnection conn, Random rng) {
    final checking = Account(
      id: '${conn.id}_cc',
      bankName: conn.institutionName,
      type: 'Conta corrente',
      balance: 800 + rng.nextDouble() * 6000,
    );
    // Metade das instituições também traz uma conta poupança.
    if (rng.nextBool()) {
      return [
        checking,
        Account(
          id: '${conn.id}_poup',
          bankName: conn.institutionName,
          type: 'Poupança',
          balance: 1500 + rng.nextDouble() * 12000,
        ),
      ];
    }
    return [checking];
  }

  List<Transaction> _transactionsFor(
    BankConnection conn,
    List<Account> accounts,
    Random rng,
  ) {
    final now = DateTime.now();
    final primary = accounts.first.bankName;
    final result = <Transaction>[];

    // 90 dias de histórico, alguns lançamentos por semana.
    for (var day = 0; day < 90; day++) {
      final date = now.subtract(Duration(days: day));
      final count = rng.nextInt(3);
      for (var i = 0; i < count; i++) {
        final merchant = _merchants[rng.nextInt(_merchants.length)];
        result.add(
          Transaction(
            id: '${conn.id}_tx_${day}_$i',
            description: merchant.$1,
            amount: -(merchant.$3 + rng.nextDouble() * merchant.$3),
            date: date.subtract(Duration(hours: rng.nextInt(12))),
            category: merchant.$2,
            accountName: primary,
          ),
        );
      }
    }

    // Salário mensal nos últimos três meses.
    for (var month = 0; month < 3; month++) {
      result.add(
        Transaction(
          id: '${conn.id}_salario_$month',
          description: 'Crédito salário',
          amount: 4200 + rng.nextDouble() * 3000,
          date: DateTime(now.year, now.month - month, 5),
          category: TxCategory.salario,
          accountName: primary,
        ),
      );
    }

    return result;
  }

  static const _merchants = <(String, TxCategory, double)>[
    ('IFOOD *RESTAURANTE', TxCategory.alimentacao, 28),
    ('UBER *TRIP', TxCategory.transporte, 12),
    ('99 *POP', TxCategory.transporte, 10),
    ('SUPERMERCADO PAO DE ACUCAR', TxCategory.alimentacao, 90),
    ('DROGARIA SAO PAULO', TxCategory.saude, 35),
    ('NETFLIX.COM', TxCategory.assinaturas, 39),
    ('SPOTIFY', TxCategory.assinaturas, 21),
    ('AMAZON BR', TxCategory.compras, 60),
    ('POSTO SHELL', TxCategory.transporte, 120),
    ('SMART FIT', TxCategory.saude, 99),
    ('CINEMARK', TxCategory.lazer, 45),
    ('MAGAZINE LUIZA', TxCategory.compras, 150),
    ('UDEMY CURSOS', TxCategory.educacao, 55),
    ('ALUGUEL IMOBILIARIA', TxCategory.moradia, 1400),
    ('CONTA DE LUZ', TxCategory.moradia, 180),
  ];

  Future<void> _networkDelay({int min = 400, int max = 900}) {
    final ms = min + Random().nextInt(max - min);
    return Future<void>.delayed(Duration(milliseconds: ms));
  }
}
