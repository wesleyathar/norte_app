import '../models/budget.dart';
import '../models/institution.dart';
import '../models/transaction.dart';

/// Resultado de uma sincronização Open Finance: contas e lançamentos importados.
class SyncResult {
  const SyncResult({
    required this.accounts,
    required this.transactions,
  });

  final List<Account> accounts;
  final List<Transaction> transactions;
}

/// Contrato do provedor Open Finance.
///
/// A implementação de produção fala com as APIs das instituições (fluxo de
/// consentimento OAuth + endpoints de contas/transações). O app não conhece
/// esses detalhes: só recebe [BankConnection] e [SyncResult].
abstract interface class OpenFinanceService {
  /// Instituições que o usuário pode conectar.
  Future<List<FinancialInstitution>> availableInstitutions();

  /// Inicia o consentimento e devolve a conexão após a autorização.
  ///
  /// Em produção, dispara o redirect OAuth e aguarda o callback.
  Future<BankConnection> connect({
    required FinancialInstitution institution,
    required List<ConsentScope> scopes,
  });

  /// Busca contas e transações de uma conexão ativa.
  Future<SyncResult> sync(BankConnection connection);

  /// Revoga o consentimento junto à instituição.
  Future<void> revoke(BankConnection connection);
}
