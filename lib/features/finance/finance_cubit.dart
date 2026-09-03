import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/analytics.dart';
import '../../domain/ml/transaction_categorizer.dart';
import '../../domain/models/budget.dart';
import '../../domain/models/institution.dart';
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
    this.error,
  });

  final FinanceStatus status;
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Budget> budgetLimits;
  final List<Goal> goals;
  final List<BankConnection> connections;
  final String? error;

  bool get isLoading => status == FinanceStatus.loading;

  double get totalBalance =>
      accounts.fold(0.0, (sum, account) => sum + account.balance);

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
    String? error,
  }) {
    return FinanceState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      budgetLimits: budgetLimits ?? this.budgetLimits,
      goals: goals ?? this.goals,
      connections: connections ?? this.connections,
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
}
