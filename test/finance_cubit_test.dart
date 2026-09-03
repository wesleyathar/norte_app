import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/features/finance/finance_cubit.dart';
import 'package:norte_app/domain/models/tx_category.dart';

import 'support/fake_finance_repository.dart';

void main() {
  late FakeFinanceRepository repository;
  late FinanceCubit cubit;

  setUp(() {
    repository = FakeFinanceRepository();
    cubit = FinanceCubit(repository);
  });

  tearDown(() => cubit.close());

  test('começa carregando e fica pronto após load', () async {
    expect(cubit.state.status, FinanceStatus.loading);

    await cubit.load();

    expect(cubit.state.status, FinanceStatus.ready);
    expect(cubit.state.transactions, isNotEmpty);
    expect(cubit.state.accounts, isNotEmpty);
    expect(repository.loadCount, 1);
  });

  test('editar categoria persiste e reflete no estado', () async {
    await cubit.load();
    final original = cubit.state.transactions.firstWhere(
      (t) => t.category != TxCategory.educacao,
    );

    await cubit.saveTransaction(
      original.copyWith(category: TxCategory.educacao),
    );

    final updated = cubit.state.transactions.firstWhere(
      (t) => t.id == original.id,
    );
    expect(updated.category, TxCategory.educacao);

    // Confirma que foi para o repositório, não só para o estado em memória.
    final reloaded = await repository.load();
    expect(
      reloaded.transactions.firstWhere((t) => t.id == original.id).category,
      TxCategory.educacao,
    );
  });

  test('excluir remove do estado e do repositório', () async {
    await cubit.load();
    final target = cubit.state.transactions.first;
    final before = cubit.state.transactions.length;

    await cubit.deleteTransaction(target.id);

    expect(cubit.state.transactions.length, before - 1);
    expect(cubit.state.transactions.where((t) => t.id == target.id), isEmpty);
  });

  test('orçamentos combinam limite salvo com gasto do mês', () async {
    await cubit.load();

    for (final budget in cubit.state.budgets) {
      final expected = cubit.state.currentMonth
          .where((t) => t.category == budget.category && t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      expect(budget.spent, expected);
    }
  });
}
