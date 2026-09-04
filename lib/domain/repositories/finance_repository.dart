import '../models/budget.dart';
import '../models/institution.dart';
import '../models/patrimony.dart';
import '../models/transaction.dart';
import '../services/open_finance_service.dart';

/// Retrato completo dos dados financeiros carregados do armazenamento local.
class FinanceSnapshot {
  const FinanceSnapshot({
    required this.accounts,
    required this.transactions,
    required this.budgetLimits,
    required this.goals,
    this.connections = const [],
    this.patrimony = const [],
  });

  final List<Account> accounts;
  final List<Transaction> transactions;

  /// Limites definidos pelo usuário; o valor gasto é sempre recalculado.
  final List<Budget> budgetLimits;
  final List<Goal> goals;

  /// Conexões Open Finance ativas com instituições financeiras.
  final List<BankConnection> connections;

  /// Itens manuais de patrimônio (ativos e passivos) informados pelo usuário.
  final List<PatrimonyItem> patrimony;

  Map<String, dynamic> toJson() => {
    'accounts': [for (final a in accounts) a.toJson()],
    'transactions': [for (final t in transactions) t.toJson()],
    'budgetLimits': [for (final b in budgetLimits) b.toJson()],
    'goals': [for (final g in goals) g.toJson()],
    'connections': [for (final c in connections) c.toJson()],
    'patrimony': [for (final p in patrimony) p.toJson()],
  };

  factory FinanceSnapshot.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) => [
      for (final item in (json[key] as List? ?? const []))
        Map<String, dynamic>.from(item as Map),
    ];
    return FinanceSnapshot(
      accounts: [for (final j in list('accounts')) Account.fromJson(j)],
      transactions: [
        for (final j in list('transactions')) Transaction.fromJson(j),
      ],
      budgetLimits: [for (final j in list('budgetLimits')) Budget.fromJson(j, 0)],
      goals: [for (final j in list('goals')) Goal.fromJson(j)],
      connections: [
        for (final j in list('connections')) BankConnection.fromJson(j),
      ],
      patrimony: [for (final j in list('patrimony')) PatrimonyItem.fromJson(j)],
    );
  }
}

abstract interface class FinanceRepository {
  Future<FinanceSnapshot> load();

  Future<void> saveTransaction(Transaction transaction);

  Future<void> deleteTransaction(String id);

  /// Persiste uma conexão Open Finance com as contas e transações importadas.
  Future<void> importConnection(BankConnection connection, SyncResult data);

  /// Remove a conexão e todos os dados (contas e transações) associados.
  Future<void> removeConnection(String connectionId);

  /// Cria ou atualiza um item manual de patrimônio.
  Future<void> savePatrimonyItem(PatrimonyItem item);

  /// Remove um item manual de patrimônio.
  Future<void> deletePatrimonyItem(String id);

  /// Sobrescreve todo o estado local (usado ao baixar dados da nuvem).
  Future<void> replaceAll(FinanceSnapshot snapshot);
}
