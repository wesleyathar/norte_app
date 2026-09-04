import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/services/account_auth_service.dart';

/// Implementação com Firebase Auth + Google Sign-In.
///
/// Na web usa o fluxo de popup do Firebase (não requer client id extra); no
/// mobile usa o google_sign_in v7 e troca o idToken por credencial do Firebase.
class FirebaseAccountAuthService implements AccountAuthService {
  FirebaseAccountAuthService([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleInitialized = false;

  @override
  Stream<AccountUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AccountUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<AccountUser> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      try {
        final result = await _auth.signInWithPopup(provider);
        return _requireUser(result.user);
      } on FirebaseAuthException catch (e) {
        // No celular/TWA o popup costuma ser bloqueado: cai no redirect, que
        // recarrega a página e conclui o login via authStateChanges.
        const popupIssues = {
          'popup-blocked',
          'popup-closed-by-user',
          'cancelled-popup-request',
          'operation-not-supported-in-this-environment',
          'web-context-canceled',
        };
        if (popupIssues.contains(e.code)) {
          await _auth.signInWithRedirect(provider);
          throw const RedirectInProgress();
        }
        rethrow;
      }
    }

    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    return _requireUser(result.user);
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb && _googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  AccountUser _requireUser(User? user) {
    if (user == null) {
      throw StateError('Login concluído sem usuário retornado.');
    }
    return _mapUser(user)!;
  }

  AccountUser? _mapUser(User? user) {
    if (user == null) return null;
    return AccountUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
