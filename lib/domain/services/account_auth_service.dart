/// Usuário autenticado na conta (identidade + dados na nuvem).
class AccountUser {
  const AccountUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
}

/// Autenticação de conta (login Google) separada do bloqueio local por PIN.
abstract interface class AccountAuthService {
  /// Emite o usuário atual (ou null quando deslogado) a cada mudança de sessão.
  Stream<AccountUser?> authStateChanges();

  AccountUser? get currentUser;

  Future<AccountUser> signInWithGoogle();

  Future<void> signOut();
}
