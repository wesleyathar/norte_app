import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/models/budget.dart';
import '../../domain/models/institution.dart';
import '../../domain/models/patrimony.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/services/open_finance_service.dart';
import 'secure_key_store.dart';

/// Repositório sobre uma box do Hive criptografada com AES-256.
///
/// Os objetos são gravados como JSON em vez de TypeAdapters gerados: evita
/// build_runner e mantém a migração de schema explícita.
class LocalFinanceRepository implements FinanceRepository {
  LocalFinanceRepository._(this._box);

  static const _boxName = 'finance';
  static const _accountsKey = 'accounts';
  static const _transactionsKey = 'transactions';
  static const _budgetsKey = 'budgets';
  static const _goalsKey = 'goals';
  static const _connectionsKey = 'connections';
  static const _patrimonyKey = 'patrimony';

  final Box<dynamic> _box;

  static Future<LocalFinanceRepository> open({
    SecureKeyStore keyStore = const SecureKeyStore(),
  }) async {
    await Hive.initFlutter();
    final key = await keyStore.readOrCreate();

    final box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );

    return LocalFinanceRepository._(box);
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _box.get(key) as List<dynamic>? ?? const [];
    return [for (final item in raw) Map<String, dynamic>.from(item as Map)];
  }

  @override
  Future<FinanceSnapshot> load() async {
    final transactions = [
      for (final json in _readList(_transactionsKey))
        Transaction.fromJson(json),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return FinanceSnapshot(
      accounts: [
        for (final json in _readList(_accountsKey)) Account.fromJson(json),
      ],
      transactions: transactions,
      budgetLimits: [
        for (final json in _readList(_budgetsKey)) Budget.fromJson(json, 0),
      ],
      goals: [for (final json in _readList(_goalsKey)) Goal.fromJson(json)],
      connections: [
        for (final json in _readList(_connectionsKey))
          BankConnection.fromJson(json),
      ],
      patrimony: [
        for (final json in _readList(_patrimonyKey))
          PatrimonyItem.fromJson(json),
      ],
    );
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final all = _readList(_transactionsKey);
    final index = all.indexWhere((json) => json['id'] == transaction.id);

    if (index == -1) {
      all.add(transaction.toJson());
    } else {
      all[index] = transaction.toJson();
    }

    await _box.put(_transactionsKey, all);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final all = _readList(_transactionsKey)
      ..removeWhere((json) => json['id'] == id);
    await _box.put(_transactionsKey, all);
  }

  @override
  Future<void> savePatrimonyItem(PatrimonyItem item) async {
    final all = _readList(_patrimonyKey);
    final index = all.indexWhere((json) => json['id'] == item.id);
    if (index == -1) {
      all.add(item.toJson());
    } else {
      all[index] = item.toJson();
    }
    await _box.put(_patrimonyKey, all);
  }

  @override
  Future<void> deletePatrimonyItem(String id) async {
    final all = _readList(_patrimonyKey)
      ..removeWhere((json) => json['id'] == id);
    await _box.put(_patrimonyKey, all);
  }

  @override
  Future<void> importConnection(
    BankConnection connection,
    SyncResult data,
  ) async {
    final accounts = _readList(_accountsKey)
      ..addAll([for (final a in data.accounts) a.toJson()]);
    await _box.put(_accountsKey, accounts);

    final transactions = _readList(_transactionsKey)
      ..addAll([for (final t in data.transactions) t.toJson()]);
    await _box.put(_transactionsKey, transactions);

    final connections = _readList(_connectionsKey)
      ..removeWhere((json) => json['id'] == connection.id)
      ..add(connection.toJson());
    await _box.put(_connectionsKey, connections);
  }

  @override
  Future<void> removeConnection(String connectionId) async {
    // Contas e transações importadas têm o id prefixado com o da conexão.
    final accounts = _readList(_accountsKey)
      ..removeWhere(
        (json) => (json['id'] as String).startsWith(connectionId),
      );
    await _box.put(_accountsKey, accounts);

    final transactions = _readList(_transactionsKey)
      ..removeWhere(
        (json) => (json['id'] as String).startsWith(connectionId),
      );
    await _box.put(_transactionsKey, transactions);

    final connections = _readList(_connectionsKey)
      ..removeWhere((json) => json['id'] == connectionId);
    await _box.put(_connectionsKey, connections);
  }

  @override
  Future<void> replaceAll(FinanceSnapshot snapshot) async {
    await _box.putAll({
      _accountsKey: [for (final a in snapshot.accounts) a.toJson()],
      _transactionsKey: [for (final t in snapshot.transactions) t.toJson()],
      _budgetsKey: [for (final b in snapshot.budgetLimits) b.toJson()],
      _goalsKey: [for (final g in snapshot.goals) g.toJson()],
      _connectionsKey: [for (final c in snapshot.connections) c.toJson()],
      _patrimonyKey: [for (final p in snapshot.patrimony) p.toJson()],
    });
  }
}