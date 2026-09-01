import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth` v3 to provide fingerprint / Face ID / PIN authentication.
/// Used for one-tap login — the user must pass the same auth as their device
/// screen lock before the stored token is used.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device supports any biometric or device credential.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns which biometrics are enrolled (fingerprint, face, iris).
  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Prompts the device screen-lock authentication (biometric or PIN/pattern).
  /// Returns true if the user passes, false if they cancel or fail.
  Future<bool> authenticate({String reason = 'Use Face ID or your passcode to log in'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // allow PIN/pattern/passcode fallback
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      // Device has no credentials configured — allow through
      if (e.code == LocalAuthExceptionCode.noCredentialsSet ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled ||
          e.code == LocalAuthExceptionCode.noBiometricHardware) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
