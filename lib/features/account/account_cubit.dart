import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/account_auth_service.dart';

enum AccountStatus { unknown, signedOut, signedIn }

class AccountState {
  const AccountState({
    this.status = AccountStatus.unknown,
    this.user,
    this.signingIn = false,
    this.error,
  });

  final AccountStatus status;
  final AccountUser? user;
  final bool signingIn;
  final String? error;

  bool get isSignedIn => status == AccountStatus.signedIn;

  AccountState copyWith({
    AccountStatus? status,
    AccountUser? user,
    bool? signingIn,
    String? error,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: user ?? this.user,
      signingIn: signingIn ?? this.signingIn,
      error: error,
    );
  }
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._service) : super(const AccountState()) {
    _subscription = _service.authStateChanges().listen(_onAuthChanged);
  }

  final AccountAuthService _service;
  late final StreamSubscription<AccountUser?> _subscription;

  void _onAuthChanged(AccountUser? user) {
    emit(
      state.copyWith(
        status: user == null ? AccountStatus.signedOut : AccountStatus.signedIn,
        user: user,
        signingIn: false,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(signingIn: true, error: null));
    try {
      await _service.signInWithGoogle();
      // O estado final chega pelo authStateChanges.
    } on RedirectInProgress {
      // Página vai recarregar; login conclui no retorno. Não é erro.
    } catch (error) {
      if (kDebugMode) debugPrint('Falha no login Google: $error');
      emit(
        state.copyWith(
          signingIn: false,
          error: 'Não foi possível entrar com o Google. Tente novamente.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  void clearError() => emit(state.copyWith(error: null));

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
