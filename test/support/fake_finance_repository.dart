import 'package:norte_app/data/mock_data.dart';
import 'package:norte_app/domain/models/budget.dart';
import 'package:norte_app/domain/models/institution.dart';
import 'package:norte_app/domain/models/transaction.dart';
import 'package:norte_app/domain/repositories/finance_repository.dart';
import 'package:norte_app/domain/services/open_finance_service.dart';

/// Repositório em memória para os testes, sem Hive nem secure storage.
class FakeFinanceRepository implements FinanceRepository {
  FakeFinanceRepository({List<Transaction>? transactions})
    : _transactions = List.of(transactions ?? MockData.transactions),
      _accounts = List.of(MockData.accounts),
      _goals = MockData.goals();

  final List<Transaction> _transactions;
  List<Account> _accounts;
  List<Goal> _goals;
  final List<BankConnection> _connections = [];

  int loadCount = 0;

  @override
  Future<FinanceSnapshot> load() async {
    loadCount++;
    return FinanceSnapshot(
      accounts: List.of(_accounts),
      transactions: List.of(_transactions)
        ..sort((a, b) => b.date.compareTo(a.date)),
      budgetLimits: MockData.budgets(_transactions),
      goals: List.of(_goals),
      connections: List.of(_connections),
    );
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index == -1) {
      _transactions.add(transaction);
    } else {
      _transactions[index] = transaction;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> importConnection(
    BankConnection connection,
    SyncResult data,
  ) async {
    _transactions.addAll(data.transactions);
    _connections
      ..removeWhere((c) => c.id == connection.id)
      ..add(connection);
  }

  @override
  Future<void> removeConnection(String connectionId) async {
    _transactions.removeWhere((t) => t.id.startsWith(connectionId));
    _connections.removeWhere((c) => c.id == connectionId);
  }

  @override
  Future<void> replaceAll(FinanceSnapshot snapshot) async {
    _accounts = List.of(snapshot.accounts);
    _goals = List.of(snapshot.goals);
    _transactions
      ..clear()
      ..addAll(snapshot.transactions);
    _connections
      ..clear()
      ..addAll(snapshot.connections);
  }
}
