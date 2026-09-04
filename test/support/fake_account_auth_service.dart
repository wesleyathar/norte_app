import 'dart:async';

import 'package:norte_app/domain/services/account_auth_service.dart';

/// Serviço de conta fake para testes. Por padrão já inicia autenticado, para
/// os testes de navegação caírem direto no app (sem passar pela tela de login).
class FakeAccountAuthService implements AccountAuthService {
  FakeAccountAuthService({
    AccountUser? initialUser = const AccountUser(
      uid: 'test-uid',
      email: 'teste@norte.app',
      displayName: 'Teste',
    ),
  }) : _user = initialUser;

  AccountUser? _user;
  final _controller = StreamController<AccountUser?>.broadcast();

  @override
  Stream<AccountUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AccountUser? get currentUser => _user;

  @override
  Future<AccountUser> signInWithGoogle() async {
    _user = const AccountUser(uid: 'test-uid', email: 'teste@norte.app');
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
