/// Biometric Authentication Service
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

enum BiometricResult {
  success,
  failed,        // wrong finger
  notAvailable,  // no biometric enrolled
  notSupported,  // device doesn't support
  cancelled,     // user cancelled
  lockedOut,     // too many attempts
}

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if fingerprint is available
  Future<bool> isFingerprintAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong);
    } catch (e) {
      return false;
    }
  }

  /// Check if face recognition is available
  Future<bool> isFaceRecognitionAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.face);
    } catch (e) {
      return false;
    }
  }

  /// Get reason text based on available biometrics
  Future<String> getAuthenticationReason({required String action}) async {
    final isFinger = await isFingerprintAvailable();
    final isFace = await isFaceRecognitionAvailable();

    if (isFinger && isFace) {
      return 'Use your registered fingerprint or face to $action';
    } else if (isFinger) {
      return 'Place your registered finger to $action';
    } else if (isFace) {
      return 'Use your face to $action';
    } else {
      return 'Authenticate to $action';
    }
  }

  /// Main authenticate method — returns BiometricResult with clear reason
  /// 
  /// KEY BEHAVIOR:
  /// - biometricOnly: true  → sirf fingerprint/face, NO PIN fallback
  /// - Agar galat ungli → OS khud "Not recognized" dikhata hai
  /// - 5 baar galat → lockedOut
  Future<BiometricResult> authenticateStrict({
    required String reason,
  }) async {
    try {
      // Step 1: Check device support
      final deviceSupports = await _localAuth.isDeviceSupported();
      if (!deviceSupports) {
        return BiometricResult.notSupported;
      }

      // Step 2: Check biometric enrolled
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        return BiometricResult.notAvailable;
      }

      // Step 3: Check fingerprint specifically enrolled
      final biometrics = await _localAuth.getAvailableBiometrics();
      final hasFingerOrFace = biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.face);

      if (!hasFingerOrFace) {
        return BiometricResult.notAvailable;
      }

      // Step 4: Authenticate — biometricOnly:true means NO PIN fallback
      // Galat finger lagane par OS "Not recognized" dikhata hai automatically
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,   // ← PIN fallback BAND — sirf finger/face
          useErrorDialogs: true, // OS khud error dialog dikhata hai
          sensitiveTransaction: true,
        ),
      );

      if (isAuthenticated) {
        return BiometricResult.success;
      } else {
        // User ne cancel kiya ya OS ne reject kiya
        return BiometricResult.cancelled;
      }
    } on PlatformException catch (e) {
      // Specific error codes handle karo
      switch (e.code) {
        case auth_error.notAvailable:
          return BiometricResult.notAvailable;
        case auth_error.notEnrolled:
          return BiometricResult.notAvailable;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricResult.lockedOut;
        case auth_error.passcodeNotSet:
          return BiometricResult.notAvailable;
        default:
          return BiometricResult.failed;
      }
    } catch (e) {
      return BiometricResult.failed;
    }
  }

  /// Legacy method — backward compatibility ke liye
  Future<bool> authenticate({required String reason}) async {
    final result = await authenticateStrict(reason: reason);
    return result == BiometricResult.success;
  }
}
