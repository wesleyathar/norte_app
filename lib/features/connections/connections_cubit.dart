import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/ml/transaction_categorizer.dart';
import '../../domain/models/institution.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/services/open_finance_service.dart';

enum ConnectionFlowStatus {
  idle,
  loadingInstitutions,
  institutionsReady,
  connecting,
  syncing,
  success,
  error,
}

class ConnectionsState {
  const ConnectionsState({
    this.status = ConnectionFlowStatus.idle,
    this.institutions = const [],
    this.lastConnection,
    this.error,
  });

  final ConnectionFlowStatus status;
  final List<FinancialInstitution> institutions;
  final BankConnection? lastConnection;
  final String? error;

  bool get isBusy =>
      status == ConnectionFlowStatus.connecting ||
      status == ConnectionFlowStatus.syncing;

  ConnectionsState copyWith({
    ConnectionFlowStatus? status,
    List<FinancialInstitution>? institutions,
    BankConnection? lastConnection,
    String? error,
  }) {
    return ConnectionsState(
      status: status ?? this.status,
      institutions: institutions ?? this.institutions,
      lastConnection: lastConnection ?? this.lastConnection,
      error: error,
    );
  }
}

class ConnectionsCubit extends Cubit<ConnectionsState> {
  ConnectionsCubit(this._service, this._repository, [this._categorizer])
      : super(const ConnectionsState());

  final OpenFinanceService _service;
  final FinanceRepository _repository;
  final TransactionCategorizer? _categorizer;
  Future<void> loadInstitutions() async {    emit(state.copyWith(status: ConnectionFlowStatus.loadingInstitutions));
    try {
      final institutions = await _service.availableInstitutions();
      emit(
        state.copyWith(
          status: ConnectionFlowStatus.institutionsReady,
          institutions: institutions,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: ConnectionFlowStatus.error,
          error: 'Não foi possível carregar as instituições: $e',
        ),
      );
    }
  }

  /// Executa o fluxo completo: consentimento, sincronização e persistência.
  Future<bool> connectInstitution({
    required FinancialInstitution institution,
    required List<ConsentScope> scopes,
  }) async {
    try {
      emit(state.copyWith(status: ConnectionFlowStatus.connecting));
      final connection = await _service.connect(
        institution: institution,
        scopes: scopes,
      );

      emit(state.copyWith(status: ConnectionFlowStatus.syncing));
      final data = await _service.sync(connection);
      final categorized = SyncResult(
        accounts: data.accounts,
        transactions: _categorize(data.transactions),
      );
      final synced = connection.copyWith(lastSyncedAt: DateTime.now());
      await _repository.importConnection(synced, categorized);

      emit(
        state.copyWith(
          status: ConnectionFlowStatus.success,
          lastConnection: synced,
        ),
      );
      return true;
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: ConnectionFlowStatus.error,
          error: 'Falha ao conectar com ${institution.displayName}: $e',
        ),
      );
      return false;
    }
  }

  Future<bool> disconnect(BankConnection connection) async {
    try {
      await _service.revoke(connection);
      await _repository.removeConnection(connection.id);
      return true;
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: ConnectionFlowStatus.error,
          error: 'Falha ao desconectar: $e',
        ),
      );
      return false;
    }
  }

  void reset() => emit(const ConnectionsState());

  /// Classifica as transações importadas com a IA, quando confiante.
  List<Transaction> _categorize(List<Transaction> transactions) {
    final categorizer = _categorizer;
    if (categorizer == null) return transactions;
    return [
      for (final tx in transactions)
        if (tx.category.isIncome)
          tx
        else
          _applyPrediction(tx, categorizer.predict(tx.description)),
    ];
  }

  Transaction _applyPrediction(Transaction tx, CategoryPrediction prediction) {
    if (!prediction.isConfident) return tx;
    return Transaction(
      id: tx.id,
      description: tx.description,
      amount: tx.amount,
      date: tx.date,
      category: prediction.category,
      accountName: tx.accountName,
      tags: tx.tags,
      note: tx.note,
    );
  }
}
