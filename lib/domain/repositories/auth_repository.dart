import 'package:local_auth/local_auth.dart';

/// Resultado de uma tentativa de autenticação biométrica.
enum BiometricResult {
  success,
  userCancelled,
  notAvailable,
  hardwareUnavailable,
  unknown,
}

/// Informações sobre o dispositivo de biometria.
class BiometricInfo {
  const BiometricInfo({
    required this.canAuthenticate,
    required this.availableBiometrics,
  });

  final bool canAuthenticate;
  final List<BiometricType> availableBiometrics;

  bool get hasFace =>
      availableBiometrics.contains(BiometricType.face);

  bool get hasFingerprint =>
      availableBiometrics.contains(BiometricType.fingerprint);

  bool get hasIris =>
      availableBiometrics.contains(BiometricType.iris);
}

abstract interface class AuthRepository {
  Future<bool> setPinCode(String pin);

  Future<bool> hasPinCode();

  Future<bool> verifyPinCode(String pin);

  Future<BiometricInfo> getBiometricInfo();

  Future<BiometricResult> authenticateWithBiometric({
    required String reason,
  });

  Future<bool> enableBiometric();

  Future<bool> disableBiometric();

  Future<bool> isBiometricEnabled();

  Future<void> logout();
}
