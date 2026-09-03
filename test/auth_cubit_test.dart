import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/features/auth/auth_cubit.dart';

import 'support/fake_auth_repository.dart';

void main() {
  group('AuthCubit', () {
    late FakeAuthRepository repo;
    late AuthCubit cubit;

    setUp(() {
      repo = FakeAuthRepository();
      cubit = AuthCubit(repo);
    });

    tearDown(() => cubit.close());

    test('sem PIN configurado inicia desbloqueado', () async {
      await cubit.initialize();
      expect(cubit.state.status, AuthStatus.unlocked);
      expect(cubit.state.pinCodeSet, isFalse);
    });

    test('com PIN configurado inicia bloqueado', () async {
      await repo.setPinCode('1234');
      await cubit.initialize();
      expect(cubit.state.status, AuthStatus.locked);
      expect(cubit.state.pinCodeSet, isTrue);
    });

    test('setPin valida tamanho e bloqueia', () async {
      final tooShort = await cubit.setPin('12');
      expect(tooShort, isFalse);

      final ok = await cubit.setPin('4321');
      expect(ok, isTrue);
      expect(cubit.state.status, AuthStatus.locked);
    });

    test('verifyPin correto desbloqueia', () async {
      await cubit.setPin('1234');
      final ok = await cubit.verifyPin('1234');
      expect(ok, isTrue);
      expect(cubit.state.status, AuthStatus.unlocked);
      expect(cubit.state.pinAttempts, 0);
    });

    test('verifyPin errado incrementa tentativas', () async {
      await cubit.setPin('1234');
      await cubit.verifyPin('0000');
      expect(cubit.state.status, isNot(AuthStatus.unlocked));
      expect(cubit.state.pinAttempts, 1);
      expect(cubit.state.error, isNotNull);
    });

    test('enable/disable biometria alterna estado', () async {
      await cubit.enableBiometric();
      expect(cubit.state.biometricEnabled, isTrue);

      await cubit.disableBiometric();
      expect(cubit.state.biometricEnabled, isFalse);
    });

    test('logout limpa e marca não autenticado', () async {
      await cubit.setPin('1234');
      await cubit.logout();
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(await repo.hasPinCode(), isFalse);
    });
  });
}
