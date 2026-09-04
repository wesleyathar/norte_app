import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/analytics.dart';
import '../../domain/ml/transaction_categorizer.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/institution.dart';
import '../../domain/models/patrimony.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/tx_category.dart';
import '../../domain/repositories/finance_repository.dart';

enum FinanceStatus { loading, ready, failure }

class FinanceState {
  const FinanceState({
    this.status = FinanceStatus.loading,
    this.accounts = const [],
    this.transactions = const [],
    this.budgetLimits = const [],
    this.goals = const [],
    this.connections = const [],
    this.patrimony = const [],
    this.error,
  });

  final FinanceStatus status;
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Budget> budgetLimits;
  final List<Goal> goals;
  final List<BankConnection> connections;
  final List<PatrimonyItem> patrimony;
  final String? error;

  bool get isLoading => status == FinanceStatus.loading;

  double get totalBalance =>
      accounts.fold(0.0, (sum, account) => sum + account.balance);

  /// Uma conta é tratada como dívida quando é cartão de crédito.
  bool _isCardAccount(Account account) {
    final type = account.type.toLowerCase();
    return type.contains('cart') || type.contains('crédito') ||
        type.contains('credito');
  }

  /// Total de ativos: saldos positivos das contas + bens manuais.
  double get assetsTotal {
    var total = 0.0;
    for (final account in accounts) {
      if (_isCardAccount(account)) continue;
      if (account.balance > 0) total += account.balance;
    }
    for (final item in patrimony) {
      if (item.isAsset) total += item.value;
    }
    return total;
  }

  /// Total de passivos: faturas de cartão, saldos negativos + dívidas manuais.
  double get liabilitiesTotal {
    var total = 0.0;
    for (final account in accounts) {
      if (_isCardAccount(account)) {
        total += account.balance.abs();
      } else if (account.balance < 0) {
        total += -account.balance;
      }
    }
    for (final item in patrimony) {
      if (!item.isAsset) total += item.value;
    }
    return total;
  }

  /// Patrimônio líquido = ativos - passivos.
  double get netWorth => assetsTotal - liabilitiesTotal;

  List<Transaction> get currentMonth =>
      Analytics.inMonth(transactions, DateTime.now());

  /// Limites persistidos combinados com o gasto real do mês corrente.
  List<Budget> get budgets {
    final month = currentMonth;
    return [
      for (final budget in budgetLimits)
        Budget(
          id: budget.id,
          category: budget.category,
          limit: budget.limit,
          spent: month
              .where((t) => t.category == budget.category && t.isExpense)
              .fold(0.0, (sum, t) => sum + t.amount.abs()),
        ),
    ];
  }

  FinanceState copyWith({
    FinanceStatus? status,
    List<Account>? accounts,
    List<Transaction>? transactions,
    List<Budget>? budgetLimits,
    List<Goal>? goals,
    List<BankConnection>? connections,
    List<PatrimonyItem>? patrimony,
    String? error,
  }) {
    return FinanceState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      budgetLimits: budgetLimits ?? this.budgetLimits,
      goals: goals ?? this.goals,
      connections: connections ?? this.connections,
      patrimony: patrimony ?? this.patrimony,
      error: error,
    );
  }
}

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit(this._repository, [this._categorizer])
      : super(const FinanceState());

  final FinanceRepository _repository;
  final TransactionCategorizer? _categorizer;

  /// Sugere uma categoria para a descrição informada, quando há classificador.
  CategoryPrediction? predictCategory(String description) =>
      _categorizer?.predict(description);

  Future<void> load() async {
    emit(state.copyWith(status: FinanceStatus.loading));
    try {
      final snapshot = await _repository.load();
      emit(
        state.copyWith(
          status: FinanceStatus.ready,
          accounts: snapshot.accounts,
          transactions: snapshot.transactions,
          budgetLimits: snapshot.budgetLimits,
          goals: snapshot.goals,
          connections: snapshot.connections,
          patrimony: snapshot.patrimony,
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: FinanceStatus.failure,
          error: 'Não foi possível carregar seus dados. $error',
        ),
      );
    }
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final previous = state.transactions.firstWhere(
      (t) => t.id == transaction.id,
      orElse: () => transaction,
    );
    await _repository.saveTransaction(transaction);

    final updated = [...state.transactions];
    final index = updated.indexWhere((t) => t.id == transaction.id);
    if (index == -1) {
      updated
        ..add(transaction)
        ..sort((a, b) => b.date.compareTo(a.date));
    } else {
      updated[index] = transaction;
    }

    emit(state.copyWith(transactions: updated));
    await _maybeLearn(previous, transaction);
  }

  /// Reforça o modelo quando o usuário corrige a categoria manualmente.
  Future<void> _maybeLearn(Transaction previous, Transaction current) async {
    final categorizer = _categorizer;
    if (categorizer == null) return;
    final changedCategory = previous.category != current.category;
    final isCorrection = current.category != TxCategory.outros &&
        (changedCategory || previous.autoCategorized);
    if (!isCorrection) return;
    await categorizer.learn(current.description, current.category);
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    emit(
      state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      ),
    );
  }

  Future<void> savePatrimonyItem(PatrimonyItem item) async {
    await _repository.savePatrimonyItem(item);
    final updated = [...state.patrimony];
    final index = updated.indexWhere((p) => p.id == item.id);
    if (index == -1) {
      updated.add(item);
    } else {
      updated[index] = item;
    }
    emit(state.copyWith(patrimony: updated));
  }

  Future<void> deletePatrimonyItem(String id) async {
    await _repository.deletePatrimonyItem(id);
    emit(
      state.copyWith(
        patrimony: state.patrimony.where((p) => p.id != id).toList(),
      ),
    );
  }
}
