import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/data/openfinance/mock_open_finance_service.dart';
import 'package:norte_app/domain/models/institution.dart';
import 'package:norte_app/features/connections/connections_cubit.dart';

import 'support/fake_finance_repository.dart';

void main() {
  group('ConnectionsCubit', () {
    late FakeFinanceRepository repo;
    late ConnectionsCubit cubit;

    setUp(() {
      repo = FakeFinanceRepository();
      cubit = ConnectionsCubit(const MockOpenFinanceService(), repo);
    });

    tearDown(() => cubit.close());

    test('carrega instituições disponíveis', () async {
      await cubit.loadInstitutions();
      expect(cubit.state.status, ConnectionFlowStatus.institutionsReady);
      expect(cubit.state.institutions, isNotEmpty);
    });

    test('conectar importa contas e transações e persiste conexão', () async {
      await cubit.loadInstitutions();
      final institution = cubit.state.institutions.first;

      final before = (await repo.load()).transactions.length;

      final ok = await cubit.connectInstitution(
        institution: institution,
        scopes: ConsentScope.values,
      );

      expect(ok, isTrue);
      expect(cubit.state.status, ConnectionFlowStatus.success);
      expect(cubit.state.lastConnection, isNotNull);

      final snapshot = await repo.load();
      expect(snapshot.connections, hasLength(1));
      expect(snapshot.transactions.length, greaterThan(before));
    });

    test('desconectar remove conexão e dados importados', () async {
      await cubit.loadInstitutions();
      final institution = cubit.state.institutions.first;
      await cubit.connectInstitution(
        institution: institution,
        scopes: ConsentScope.values,
      );

      final connection = cubit.state.lastConnection!;
      final withConn = await repo.load();
      expect(withConn.connections, hasLength(1));

      final ok = await cubit.disconnect(connection);
      expect(ok, isTrue);

      final after = await repo.load();
      expect(after.connections, isEmpty);
    });
  });
}
