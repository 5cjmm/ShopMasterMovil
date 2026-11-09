import 'package:local_auth/local_auth.dart';

/// Huella dactilar con `local_auth`. La huella nunca viaja al servidor: solo
/// confirma que quien sostiene el teléfono es su dueño y desbloquea las
/// credenciales guardadas en el dispositivo.
class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// true si el teléfono tiene sensor y al menos una huella registrada.
  Future<bool> disponible() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final tipos = await _auth.getAvailableBiometrics();
      return tipos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Muestra el cuadro del sistema para poner el dedo. false si falla o se cancela.
  Future<bool> autenticar(String motivo) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
