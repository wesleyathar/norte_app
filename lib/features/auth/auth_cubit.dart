import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, locked, unlocked, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.pinCodeSet = false,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.pinAttempts = 0,
    this.error,
  });

  final AuthStatus status;
  final bool pinCodeSet;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final int pinAttempts;
  final String? error;

  bool get isLocked => status == AuthStatus.locked;
  bool get isUnlocked => status == AuthStatus.unlocked;
  bool get isPinRequired => pinCodeSet;

  AuthState copyWith({
    AuthStatus? status,
    bool? pinCodeSet,
    bool? biometricAvailable,
    bool? biometricEnabled,
    int? pinAttempts,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      pinCodeSet: pinCodeSet ?? this.pinCodeSet,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinAttempts: pinAttempts ?? this.pinAttempts,
      error: error,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> initialize() async {
    emit(state.copyWith(status: AuthStatus.initial));
    try {
      final hasPinSet = await _repository.hasPinCode();
      final bioInfo = await _repository.getBiometricInfo();
      final isBioEnabled = await _repository.isBiometricEnabled();

      final status = !hasPinSet ? AuthStatus.unlocked : AuthStatus.locked;

      emit(
        state.copyWith(
          status: status,
          pinCodeSet: hasPinSet,
          biometricAvailable: bioInfo.canAuthenticate,
          biometricEnabled: isBioEnabled && bioInfo.canAuthenticate,
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Erro ao inicializar autenticação: $e',
        ),
      );
    }
  }

  Future<bool> setPin(String pin) async {
    try {
      final success = await _repository.setPinCode(pin);
      if (success) {
        emit(state.copyWith(pinCodeSet: true, status: AuthStatus.locked));
      }
      return success;
    } on Exception catch (e) {
      emit(state.copyWith(error: 'Erro ao salvar PIN: $e'));
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final success = await _repository.verifyPinCode(pin);
      if (success) {
        emit(state.copyWith(status: AuthStatus.unlocked, pinAttempts: 0));
      } else {
        final attempts = state.pinAttempts + 1;
        emit(
          state.copyWith(
            pinAttempts: attempts,
            error: attempts >= 3
                ? 'PIN bloqueado após 3 tentativas'
                : 'PIN incorreto. Tentativas restantes: ${3 - attempts}',
          ),
        );
      }
      return success;
    } on Exception catch (e) {
      emit(state.copyWith(error: 'Erro ao verificar PIN: $e'));
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      if (!state.biometricEnabled) return false;

      final result = await _repository.authenticateWithBiometric(
        reason: 'Desbloqueie o Norte com biometria',
      );

      if (result == BiometricResult.success) {
        emit(state.copyWith(status: AuthStatus.unlocked, pinAttempts: 0));
        return true;
      } else {
        emit(
          state.copyWith(
            error: switch (result) {
              BiometricResult.userCancelled => 'Autenticação cancelada',
              BiometricResult.notAvailable =>
                'Biometria não disponível neste momento',
              BiometricResult.hardwareUnavailable =>
                'Leitor biométrico indisponível',
              _ => 'Erro ao autenticar com biometria',
            },
          ),
        );
        return false;
      }
    } on Exception catch (e) {
      emit(state.copyWith(error: 'Erro na autenticação: $e'));
      return false;
    }
  }

  Future<bool> enableBiometric() async {
    try {
      final success = await _repository.enableBiometric();
      if (success) emit(state.copyWith(biometricEnabled: true));
      return success;
    } on Exception catch (e) {
      emit(state.copyWith(error: 'Erro ao ativar biometria: $e'));
      return false;
    }
  }

  Future<bool> disableBiometric() async {
    try {
      final success = await _repository.disableBiometric();
      if (success) emit(state.copyWith(biometricEnabled: false));
      return success;
    } on Exception catch (e) {
      emit(state.copyWith(error: 'Erro ao desativar biometria: $e'));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on Exception catch (e) {
      emit(state.copyWith(error: 'Erro ao fazer logout: $e'));
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }
}
