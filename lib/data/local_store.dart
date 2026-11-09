import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro del dispositivo (Keystore en Android, Keychain en iOS):
/// token, credenciales para la huella y preferencias. Nunca lanza: si el
/// almacenamiento falla, la app sigue funcionando sin guardar.
class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String kToken = 'token';
  static const String kTokenExpira = 'token_expira';
  static const String kCredEmail = 'cred_email';
  static const String kCredPassword = 'cred_password';
  static const String kPrefHuella = 'pref_huella';
  static const String kPrefAvisosStock = 'pref_avisos_stock';
  static const String kPrefResumenDiario = 'pref_resumen_diario';
  static const String kPrefNovedades = 'pref_novedades';
  static const String kAvisosLeidos = 'avisos_leidos';

  Future<String?> leer(String clave) async {
    try {
      return await _storage.read(key: clave);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardar(String clave, String valor) async {
    try {
      await _storage.write(key: clave, value: valor);
    } catch (_) {
      // Sin almacenamiento seguro la app sigue funcionando, solo que no recuerda.
    }
  }

  Future<void> borrar(String clave) async {
    try {
      await _storage.delete(key: clave);
    } catch (_) {
      // Nada que hacer.
    }
  }

  Future<bool?> leerBool(String clave) async {
    final v = await leer(clave);
    if (v == 'true') return true;
    if (v == 'false') return false;
    return null;
  }

  Future<void> guardarBool(String clave, bool valor) => guardar(clave, valor ? 'true' : 'false');
}
