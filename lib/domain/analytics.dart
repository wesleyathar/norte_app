import 'models/transaction.dart';
import 'models/tx_category.dart';

/// Agregações usadas pelos gráficos e cards. Sem estado, só cálculo.
abstract final class Analytics {
  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static List<Transaction> inMonth(List<Transaction> all, DateTime month) =>
      all.where((t) => sameMonth(t.date, month)).toList();

  static double income(List<Transaction> list) =>
      list.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

  static double expense(List<Transaction> list) => list
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount.abs());

  /// Total gasto por categoria, do maior para o menor.
  static List<({TxCategory category, double total})> byCategory(
    List<Transaction> list,
  ) {
    final totals = <TxCategory, double>{};
    for (final t in list.where((t) => t.isExpense)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount.abs();
    }
    final entries = totals.entries
        .map((e) => (category: e.key, total: e.value))
        .toList();
    entries.sort((a, b) => b.total.compareTo(a.total));
    return entries;
  }

  /// Divide o mês em blocos semanais para o gráfico de barras.
  static List<({String label, double income, double expense})> weeklySeries(
    List<Transaction> monthTransactions,
    DateTime month,
  ) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final buckets = <({String label, double income, double expense})>[];

    for (var start = 1; start <= lastDay; start += 7) {
      final end = (start + 6).clamp(1, lastDay);
      final slice = monthTransactions
          .where((t) => t.date.day >= start && t.date.day <= end)
          .toList();
      buckets.add((
        label: '$start-$end',
        income: income(slice),
        expense: expense(slice),
      ));
    }
    return buckets;
  }

  /// Série dos últimos [count] meses, do mais antigo para o mais recente.
  static List<({DateTime month, double income, double expense})> monthlySeries(
    List<Transaction> all,
    int count,
  ) {
    final now = DateTime.now();
    return [
      for (var i = count - 1; i >= 0; i--)
        () {
          final month = DateTime(now.year, now.month - i);
          final slice = inMonth(all, month);
          return (month: month, income: income(slice), expense: expense(slice));
        }(),
    ];
  }

  /// Projeção linear do saldo até o fim do mês corrente.
  static double projectedBalance(List<Transaction> monthTransactions) {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final elapsed = now.day;
    final current = income(monthTransactions) - expense(monthTransactions);
    if (elapsed == 0) return current;
    final dailyExpense = expense(monthTransactions) / elapsed;
    return current - dailyExpense * (lastDay - elapsed);
  }
}
