import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/data/sync/mock_cloud_sync_service.dart';
import 'package:norte_app/data/sync/sync_metadata_store.dart';
import 'package:norte_app/domain/models/transaction.dart';
import 'package:norte_app/domain/models/tx_category.dart';
import 'package:norte_app/features/sync/sync_cubit.dart';

import 'support/fake_finance_repository.dart';

Transaction _tx(String id) => Transaction(
      id: id,
      description: 'Compra $id',
      amount: -50,
      date: DateTime(2026, 9, 1),
      category: TxCategory.compras,
      accountName: 'Conta',
    );

void main() {
  group('SyncCubit', () {
    test('primeiro sync envia os dados locais para a nuvem', () async {
      final service = MockCloudSyncService(latency: Duration.zero);
      final repo = FakeFinanceRepository(transactions: [_tx('a')]);
      final cubit = SyncCubit(repo, service, InMemorySyncMetadataStore());

      await cubit.synchronize();

      expect(cubit.state.status, SyncStatus.success);
      expect(cubit.state.outcome, SyncOutcome.pushed);
      expect(await service.download(), isNotNull);
    });

    test('sem mudanças locais, o segundo sync não reenvia', () async {
      final service = MockCloudSyncService(latency: Duration.zero);
      final repo = FakeFinanceRepository(transactions: [_tx('a')]);
      final meta = InMemorySyncMetadataStore();
      final cubit = SyncCubit(repo, service, meta);

      await cubit.synchronize();
      await cubit.synchronize();

      expect(cubit.state.outcome, SyncOutcome.alreadyInSync);
    });

    test('baixa dados quando a nuvem está à frente (outro dispositivo)',
        () async {
      final service = MockCloudSyncService(latency: Duration.zero);

      // Dispositivo A envia sua versão.
      final repoA = FakeFinanceRepository(transactions: [_tx('a')]);
      final cubitA = SyncCubit(repoA, service, InMemorySyncMetadataStore());
      await cubitA.synchronize();

      // Dispositivo B, com dados diferentes, sincroniza e deve baixar A.
      final repoB = FakeFinanceRepository(transactions: [_tx('b')]);
      final cubitB = SyncCubit(
        repoB,
        service,
        InMemorySyncMetadataStore(deviceId: 'device-b'),
      );
      await cubitB.synchronize();

      expect(cubitB.state.outcome, SyncOutcome.pulled);
      expect(cubitB.state.didPull, isTrue);

      final snapshot = await repoB.load();
      expect(snapshot.transactions.map((t) => t.id), contains('a'));
      expect(snapshot.transactions.map((t) => t.id), isNot(contains('b')));
    });

    test('mudança local após sync é enviada como nova revisão', () async {
      final service = MockCloudSyncService(latency: Duration.zero);
      final repo = FakeFinanceRepository(transactions: [_tx('a')]);
      final cubit = SyncCubit(repo, service, InMemorySyncMetadataStore());

      await cubit.synchronize();
      await repo.saveTransaction(_tx('b'));
      await cubit.synchronize();

      expect(cubit.state.outcome, SyncOutcome.pushed);
      final remote = await service.download();
      expect(remote!.revision, 2);
    });
  });
}
