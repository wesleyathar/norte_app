import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/repositories/auth_repository.dart';

/// Implementação local: PIN salvo como hash SHA-256 com salt e biometria via local_auth.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    FlutterSecureStorage? storage,
    LocalAuthentication? auth,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _auth = auth ?? LocalAuthentication();

  static const _pinKey = 'norte.auth.pin.hash';
  static const _biometricEnabledKey = 'norte.auth.biometric.enabled';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  String _hashPin(String pin, {String? salt}) {
    final useSalt = salt ?? _generateSalt();
    final combined = utf8.encode('$useSalt$pin');
    final digest = sha256.convert(combined);
    return '$useSalt:${base64Url.encode(digest.bytes)}';
  }

  String _generateSalt() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return base64Url.encode(utf8.encode('$now')).replaceAll('=', '');
  }

  bool _verifyPin(String pin, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      final salt = parts[0];
      return _hashPin(pin, salt: salt) == storedHash;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setPinCode(String pin) async {
    if (pin.length < 4 || pin.length > 8) return false;
    final hash = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hash);
    return true;
  }

  @override
  Future<bool> hasPinCode() async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null;
  }

  @override
  Future<bool> verifyPinCode(String pin) async {
    try {
      final stored = await _storage.read(key: _pinKey);
      if (stored == null) return false;
      return _verifyPin(pin, stored);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricInfo> getBiometricInfo() async {
    try {
      final canAuth = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();
      return BiometricInfo(
        canAuthenticate: canAuth,
        availableBiometrics: available,
      );
    } catch (_) {
      return const BiometricInfo(
        canAuthenticate: false,
        availableBiometrics: [],
      );
    }
  }

  @override
  Future<BiometricResult> authenticateWithBiometric({
    required String reason,
  }) async {
    try {
      final result = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return result
          ? BiometricResult.success
          : BiometricResult.userCancelled;
    } on Exception catch (e) {
      final str = e.toString();
      if (str.contains('NotAvailable')) return BiometricResult.notAvailable;
      if (str.contains('NotEnrolled')) return BiometricResult.notAvailable;
      if (str.contains('LockedOut')) {
        return BiometricResult.hardwareUnavailable;
      }
      return BiometricResult.unknown;
    }
  }

  @override
  Future<bool> enableBiometric() async {
    await _storage.write(key: _biometricEnabledKey, value: 'true');
    return true;
  }

  @override
  Future<bool> disableBiometric() async {
    await _storage.write(key: _biometricEnabledKey, value: 'false');
    return true;
  }

  @override
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
