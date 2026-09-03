import 'package:norte_app/domain/repositories/auth_repository.dart';

/// Repositório de autenticação em memória para testes, sem biometria/PIN.
class FakeAuthRepository implements AuthRepository {
  String? _pinHash;
  bool _biometricEnabled = false;

  @override
  Future<bool> setPinCode(String pin) async {
    if (pin.length < 4 || pin.length > 8) return false;
    _pinHash = pin;
    return true;
  }

  @override
  Future<bool> verifyPinCode(String pin) async => _pinHash == pin;

  @override
  Future<bool> hasPinCode() async => _pinHash != null;
  @override
  Future<BiometricInfo> getBiometricInfo() async => const BiometricInfo(
        canAuthenticate: false,
        availableBiometrics: [],
      );

  @override
  Future<BiometricResult> authenticateWithBiometric({
    required String reason,
  }) async =>
      BiometricResult.success;

  @override
  Future<bool> enableBiometric() async {
    _biometricEnabled = true;
    return true;
  }

  @override
  Future<bool> disableBiometric() async {
    _biometricEnabled = false;
    return true;
  }

  @override
  Future<bool> isBiometricEnabled() async => _biometricEnabled;

  @override
  Future<void> logout() async {
    _pinHash = null;
    _biometricEnabled = false;
  }
}
