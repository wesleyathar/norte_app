import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/budget.dart';
import '../../domain/models/institution.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/services/open_finance_service.dart';

/// Repositório financeiro real, por usuário, no Cloud Firestore.
///
/// Estrutura: users/{uid}/{accounts,transactions,budgets,goals,connections},
/// cada documento com o id do próprio modelo. O uid é lido dinamicamente do
/// Firebase Auth a cada operação, então o repositório acompanha login/logout.
class FirestoreFinanceRepository implements FinanceRepository {
  FirestoreFinanceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _collection(String name) {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection(name);
  }

  @override
  Future<FinanceSnapshot> load() async {
    final uid = _uid;
    if (uid == null) {
      return const FinanceSnapshot(
        accounts: [],
        transactions: [],
        budgetLimits: [],
        goals: [],
      );
    }

    final results = await Future.wait([
      _collection('accounts')!.get(),
      _collection('transactions')!.get(),
      _collection('budgets')!.get(),
      _collection('goals')!.get(),
      _collection('connections')!.get(),
    ]);

    final transactions = [
      for (final doc in results[1].docs) Transaction.fromJson(doc.data()),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return FinanceSnapshot(
      accounts: [
        for (final doc in results[0].docs) Account.fromJson(doc.data()),
      ],
      transactions: transactions,
      budgetLimits: [
        for (final doc in results[2].docs) Budget.fromJson(doc.data(), 0),
      ],
      goals: [for (final doc in results[3].docs) Goal.fromJson(doc.data())],
      connections: [
        for (final doc in results[4].docs) BankConnection.fromJson(doc.data()),
      ],
    );
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final collection = _collection('transactions');
    if (collection == null) return;
    await collection.doc(transaction.id).set(transaction.toJson());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final collection = _collection('transactions');
    if (collection == null) return;
    await collection.doc(id).delete();
  }

  @override
  Future<void> importConnection(
    BankConnection connection,
    SyncResult data,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    final batch = _db.batch();

    for (final account in data.accounts) {
      batch.set(_collection('accounts')!.doc(account.id), account.toJson());
    }
    for (final transaction in data.transactions) {
      batch.set(
        _collection('transactions')!.doc(transaction.id),
        transaction.toJson(),
      );
    }
    batch.set(
      _collection('connections')!.doc(connection.id),
      connection.toJson(),
    );

    await batch.commit();
  }

  @override
  Future<void> removeConnection(String connectionId) async {
    final uid = _uid;
    if (uid == null) return;
    final batch = _db.batch();

    for (final name in ['accounts', 'transactions']) {
      final docs = await _prefixedDocs(name, connectionId);
      for (final doc in docs) {
        batch.delete(doc.reference);
      }
    }
    batch.delete(_collection('connections')!.doc(connectionId));

    await batch.commit();
  }

  @override
  Future<void> replaceAll(FinanceSnapshot snapshot) async {
    final uid = _uid;
    if (uid == null) return;
    final batch = _db.batch();

    for (final name in [
      'accounts',
      'transactions',
      'budgets',
      'goals',
      'connections',
    ]) {
      final existing = await _collection(name)!.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
    }

    for (final account in snapshot.accounts) {
      batch.set(_collection('accounts')!.doc(account.id), account.toJson());
    }
    for (final transaction in snapshot.transactions) {
      batch.set(
        _collection('transactions')!.doc(transaction.id),
        transaction.toJson(),
      );
    }
    for (final budget in snapshot.budgetLimits) {
      batch.set(_collection('budgets')!.doc(budget.id), budget.toJson());
    }
    for (final goal in snapshot.goals) {
      batch.set(_collection('goals')!.doc(goal.id), goal.toJson());
    }
    for (final connection in snapshot.connections) {
      batch.set(
        _collection('connections')!.doc(connection.id),
        connection.toJson(),
      );
    }

    await batch.commit();
  }

  /// Documentos cujo id começa com [prefix] (contas/transações importadas
  /// carregam o id da conexão como prefixo).
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _prefixedDocs(
    String name,
    String prefix,
  ) async {
    final result = await _collection(name)!
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
        .where(FieldPath.documentId, isLessThan: '$prefix\uf8ff')
        .get();
    return result.docs;
  }
}
