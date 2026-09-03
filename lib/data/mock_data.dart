import 'dart:math';

import '../domain/models/budget.dart';
import '../domain/models/transaction.dart';
import '../domain/models/tx_category.dart';

/// Fonte de dados falsa usada enquanto o Open Finance não está plugado.
/// Usa semente fixa para os dados serem os mesmos a cada execução.
abstract final class MockData {
  static final _random = Random(42);

  static const accounts = <Account>[
    Account(
      id: 'acc-1',
      bankName: 'Banco Digital',
      type: 'Conta corrente',
      balance: 8420.55,
    ),
    Account(
      id: 'acc-2',
      bankName: 'Banco Digital',
      type: 'Cartão de crédito',
      balance: -2310.90,
    ),
    Account(
      id: 'acc-3',
      bankName: 'Corretora',
      type: 'Conta investimento',
      balance: 15750.00,
    ),
  ];

  static const _merchants = <TxCategory, List<String>>{
    TxCategory.alimentacao: [
      'IFOOD *PEDIDO',
      "MCDONALD'S",
      'PADARIA CENTRAL',
      'SUPERMERCADO BOM PRECO',
      'CAFETERIA GRAO',
    ],
    TxCategory.transporte: [
      'UBER *TRIP',
      'POSTO IPIRANGA',
      '99 *VIAGEM',
      'ESTACIONAMENTO SHOPPING',
    ],
    TxCategory.moradia: [
      'ALUGUEL',
      'CONDOMINIO',
      'ENEL DISTRIBUICAO',
      'SABESP',
    ],
    TxCategory.lazer: ['CINEMARK', 'STEAM GAMES', 'BAR DO ZE', 'INGRESSO.COM'],
    TxCategory.saude: ['DROGARIA SP', 'CLINICA ODONTO', 'SMART FIT'],
    TxCategory.educacao: ['UDEMY', 'ALURA', 'LIVRARIA CULTURA'],
    TxCategory.compras: ['SHOPEE', 'AMAZON BR', 'MERCADO LIVRE', 'RENNER'],
    TxCategory.assinaturas: [
      'NETFLIX.COM',
      'SPOTIFY',
      'GITHUB COPILOT',
      'ICLOUD',
    ],
    TxCategory.transferencia: ['PIX ENVIADO - JOAO', 'PIX ENVIADO - MARIA'],
  };

  static const _amountRanges = <TxCategory, (double, double)>{
    TxCategory.alimentacao: (18, 190),
    TxCategory.transporte: (12, 240),
    TxCategory.moradia: (95, 2200),
    TxCategory.lazer: (25, 320),
    TxCategory.saude: (35, 280),
    TxCategory.educacao: (40, 400),
    TxCategory.compras: (30, 850),
    TxCategory.assinaturas: (19, 70),
    TxCategory.transferencia: (50, 600),
  };

  static List<Transaction>? _cache;

  /// Transações dos últimos 6 meses, mais recentes primeiro.
  static List<Transaction> get transactions => _cache ??= _generate();

  static List<Transaction> _generate() {
    final now = DateTime.now();
    final result = <Transaction>[];
    final categories = _merchants.keys.toList();
    var seq = 0;

    for (var monthsAgo = 5; monthsAgo >= 0; monthsAgo--) {
      final month = DateTime(now.year, now.month - monthsAgo);
      final lastDay = monthsAgo == 0
          ? now.day
          : DateTime(month.year, month.month + 1, 0).day;

      result.add(
        Transaction(
          id: 'tx-${seq++}',
          description: 'SALARIO EMPRESA LTDA',
          amount: 11500,
          date: DateTime(month.year, month.month, min(5, lastDay)),
          category: TxCategory.salario,
          accountName: 'Conta corrente',
        ),
      );

      final count = 22 + _random.nextInt(10);
      for (var i = 0; i < count; i++) {
        final category = categories[_random.nextInt(categories.length)];
        final merchants = _merchants[category]!;
        final range = _amountRanges[category]!;
        final amount = range.$1 + _random.nextDouble() * (range.$2 - range.$1);
        final day = 1 + _random.nextInt(lastDay);

        result.add(
          Transaction(
            id: 'tx-${seq++}',
            description: merchants[_random.nextInt(merchants.length)],
            amount: -double.parse(amount.toStringAsFixed(2)),
            date: DateTime(
              month.year,
              month.month,
              day,
              8 + _random.nextInt(13),
              _random.nextInt(60),
            ),
            category: category,
            accountName: _random.nextBool()
                ? 'Conta corrente'
                : 'Cartão de crédito',
            autoCategorized: _random.nextInt(10) != 0,
            tags: category == TxCategory.compras && _random.nextBool()
                ? const ['#revenda']
                : const [],
          ),
        );
      }
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  static List<Budget> budgets(List<Transaction> monthTransactions) {
    const limits = <TxCategory, double>{
      TxCategory.alimentacao: 1400,
      TxCategory.transporte: 700,
      TxCategory.lazer: 500,
      TxCategory.compras: 900,
      TxCategory.assinaturas: 200,
    };

    return [
      for (final entry in limits.entries)
        Budget(
          id: 'bdg-${entry.key.name}',
          category: entry.key,
          limit: entry.value,
          spent: monthTransactions
              .where((t) => t.category == entry.key && t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount.abs()),
        ),
    ];
  }

  static List<Goal> goals() {
    final now = DateTime.now();
    return [
      Goal(
        id: 'goal-1',
        name: 'Reserva de emergência',
        target: 30000,
        saved: 18400,
        deadline: DateTime(now.year + 1, now.month),
      ),
      Goal(
        id: 'goal-2',
        name: 'Viagem Japão',
        target: 22000,
        saved: 6300,
        deadline: DateTime(now.year + 1, now.month + 6),
      ),
      Goal(
        id: 'goal-3',
        name: 'Setup novo',
        target: 9000,
        saved: 9000,
        deadline: DateTime(now.year, now.month + 2),
      ),
    ];
  }
}
