import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/domain/analytics.dart';
import 'package:norte_app/domain/models/transaction.dart';
import 'package:norte_app/domain/models/tx_category.dart';

Transaction _tx(double amount, DateTime date, TxCategory category) =>
    Transaction(
      id: '$amount-$date',
      description: 'teste',
      amount: amount,
      date: date,
      category: category,
      accountName: 'Conta corrente',
    );

void main() {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);

  final sample = [
    _tx(5000, DateTime(month.year, month.month, 5), TxCategory.salario),
    _tx(-200, DateTime(month.year, month.month, 6), TxCategory.alimentacao),
    _tx(-150, DateTime(month.year, month.month, 7), TxCategory.alimentacao),
    _tx(-300, DateTime(month.year, month.month, 8), TxCategory.transporte),
    _tx(-90, DateTime(month.year, month.month - 1, 8), TxCategory.lazer),
  ];

  test('inMonth filtra apenas o mês informado', () {
    expect(Analytics.inMonth(sample, month).length, 4);
  });

  test('income e expense somam corretamente', () {
    final current = Analytics.inMonth(sample, month);
    expect(Analytics.income(current), 5000);
    expect(Analytics.expense(current), 650);
  });

  test('byCategory ordena do maior gasto para o menor', () {
    final result = Analytics.byCategory(Analytics.inMonth(sample, month));
    expect(result.first.category, TxCategory.alimentacao);
    expect(result.first.total, 350);
    expect(result.last.category, TxCategory.transporte);
  });

  test('weeklySeries cobre todos os dias do mês', () {
    final current = Analytics.inMonth(sample, month);
    final series = Analytics.weeklySeries(current, month);
    final totalExpense = series.fold(0.0, (sum, b) => sum + b.expense);
    expect(totalExpense, Analytics.expense(current));
  });
}
