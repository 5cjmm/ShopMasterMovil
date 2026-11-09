import 'package:flutter/foundation.dart';

import 'biometric_service.dart';
import 'local_store.dart';
import 'models.dart';
import 'repository.dart';

class Credenciales {
  const Credenciales(this.email, this.password);
  final String email;
  final String password;
}

/// Sesión y preferencias del dispositivo.
///
/// Según el contrato v1.1 (sección 5), el interruptor de huella, las
/// preferencias de notificaciones y el estado leído o no leído de los avisos
/// se guardan solo en el dispositivo, no en el servidor.
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  final LocalStore _store = LocalStore.instance;

  // --- Sesión ---------------------------------------------------------------

  String? token;
  DateTime? tokenExpira;

  /// Mensaje que la pantalla de acceso muestra una sola vez (por ejemplo "sesión vencida").
  String? mensajeLogin;

  /// La app lo asigna para volver al login cuando el servidor responde 401.
  VoidCallback? alExpirarSesion;

  String? _emailSesion;
  String? _passwordSesion;

  bool get sesionIniciada => token != null && (tokenExpira == null || tokenExpira!.isAfter(DateTime.now()));

  // --- Preferencias ----------------------------------------------------------

  bool huellaActiva = true;
  bool avisosStock = true;
  bool resumenDiario = true;
  bool novedades = false;

  // --- Avisos ----------------------------------------------------------------

  List<Aviso> avisos = <Aviso>[];
  Set<String> _leidos = <String>{};

  int get sinLeer => avisos.where((a) => !a.leida).length;

  /// Lee token y preferencias guardados. Se llama una vez al abrir la app.
  Future<void> cargar() async {
    huellaActiva = await _store.leerBool(LocalStore.kPrefHuella) ?? true;
    avisosStock = await _store.leerBool(LocalStore.kPrefAvisosStock) ?? true;
    resumenDiario = await _store.leerBool(LocalStore.kPrefResumenDiario) ?? true;
    novedades = await _store.leerBool(LocalStore.kPrefNovedades) ?? false;

    final guardados = await _store.leer(LocalStore.kAvisosLeidos);
    _leidos = (guardados ?? '').split(',').where((e) => e.isNotEmpty).toSet();

    final t = await _store.leer(LocalStore.kToken);
    final exp = int.tryParse(await _store.leer(LocalStore.kTokenExpira) ?? '');
    if (t != null && t.isNotEmpty && exp != null) {
      final vence = DateTime.fromMillisecondsSinceEpoch(exp);
      if (vence.isAfter(DateTime.now())) {
        token = t;
        tokenExpira = vence;
      }
    }
    if (token == null) {
      await _store.borrar(LocalStore.kToken);
      await _store.borrar(LocalStore.kTokenExpira);
    }
  }

  /// Guarda la sesión que devolvió POST /api/auth/login. Si la huella está
  /// activa, deja las credenciales en el almacenamiento seguro para que el
  /// próximo acceso con huella repita este mismo login.
  Future<void> iniciarSesion(SesionApi sesion, {required String email, required String password}) async {
    token = sesion.token;
    tokenExpira = DateTime.now().add(Duration(seconds: sesion.expiraEnSegundos));
    _emailSesion = email;
    _passwordSesion = password;
    mensajeLogin = null;
    notifyListeners();

    await _store.guardar(LocalStore.kToken, sesion.token);
    await _store.guardar(LocalStore.kTokenExpira, '${tokenExpira!.millisecondsSinceEpoch}');
    if (huellaActiva && await BiometricService.instance.disponible()) {
      await _guardarCredenciales(email, password);
    }
  }

  /// Cierra la sesión. Conserva las credenciales de la huella: el diálogo dice
  /// "para volver a entrar, usa tu contraseña o tu huella".
  Future<void> cerrarSesion({String? mensaje}) async {
    token = null;
    tokenExpira = null;
    _passwordSesion = null;
    _emailSesion = null;
    avisos = <Aviso>[];
    mensajeLogin = mensaje;
    InventarioRepository.instance.invalidar();
    notifyListeners();

    await _store.borrar(LocalStore.kToken);
    await _store.borrar(LocalStore.kTokenExpira);
  }

  /// El servidor respondió 401 en una pantalla que no es el login.
  void sesionExpirada() {
    if (token == null) return;
    cerrarSesion(mensaje: 'Tu sesión venció. Ingresa de nuevo.');
    alExpirarSesion?.call();
  }

  // --- Huella ------------------------------------------------------------------

  Future<void> _guardarCredenciales(String email, String password) async {
    await _store.guardar(LocalStore.kCredEmail, email);
    await _store.guardar(LocalStore.kCredPassword, password);
  }

  /// Tras cambiar la contraseña desde Perfil: si la huella ya tenía guardadas
  /// las credenciales de este usuario, las actualiza; si no, el próximo acceso
  /// con huella fallaría con la contraseña vieja.
  Future<void> contrasenaCambiada(String nuevaPassword) async {
    _passwordSesion = nuevaPassword;
    final guardadas = await credencialesGuardadas();
    if (guardadas != null && guardadas.email == _emailSesion) {
      await _guardarCredenciales(guardadas.email, nuevaPassword);
    }
  }

  /// Tras restablecer la contraseña con el código: borra la contraseña vieja
  /// que la huella tenía guardada para ese correo. La próxima vez se entra con
  /// la contraseña nueva y la huella vuelve a guardarla.
  Future<void> contrasenaRestablecida(String email) async {
    final guardadas = await credencialesGuardadas();
    if (guardadas != null && guardadas.email.toLowerCase() == email.trim().toLowerCase()) {
      await _store.borrar(LocalStore.kCredPassword);
    }
  }

  Future<Credenciales?> credencialesGuardadas() async {
    final email = await _store.leer(LocalStore.kCredEmail);
    final pass = await _store.leer(LocalStore.kCredPassword);
    if (email == null || email.isEmpty || pass == null || pass.isEmpty) return null;
    return Credenciales(email, pass);
  }

  /// Activa o desactiva el acceso con huella. Devuelve un mensaje si no se pudo.
  Future<String?> setHuellaActiva(bool activa) async {
    if (activa) {
      if (!await BiometricService.instance.disponible()) {
        return 'Este teléfono no tiene una huella registrada. Regístrala en los ajustes del dispositivo.';
      }
      if (await credencialesGuardadas() == null) {
        final email = _emailSesion;
        final pass = _passwordSesion;
        if (email == null || pass == null) {
          return 'Para activar la huella, cierra sesión e ingresa una vez con tu contraseña.';
        }
        await _guardarCredenciales(email, pass);
      }
      final ok = await BiometricService.instance.autenticar('Confirma tu huella para activar el acceso rápido');
      if (!ok) return 'No pudimos confirmar tu huella. Intenta de nuevo.';
      huellaActiva = true;
    } else {
      huellaActiva = false;
      await _store.borrar(LocalStore.kCredEmail);
      await _store.borrar(LocalStore.kCredPassword);
    }
    await _store.guardarBool(LocalStore.kPrefHuella, huellaActiva);
    notifyListeners();
    return null;
  }

  // --- Notificaciones ------------------------------------------------------------

  Future<void> setAvisosStock(bool v) async {
    avisosStock = v;
    notifyListeners();
    await _store.guardarBool(LocalStore.kPrefAvisosStock, v);
  }

  Future<void> setResumenDiario(bool v) async {
    resumenDiario = v;
    notifyListeners();
    await _store.guardarBool(LocalStore.kPrefResumenDiario, v);
  }

  Future<void> setNovedades(bool v) async {
    novedades = v;
    notifyListeners();
    await _store.guardarBool(LocalStore.kPrefNovedades, v);
  }

  /// Avisos recientes = los 3 productos más críticos de GET /api/productos/stock-critico.
  Future<void> cargarAvisos() async {
    try {
      final sc = await InventarioRepository.instance.stockCritico(limite: 3);
      avisos = sc.productos.map((p) => Aviso.desdeProducto(p, leida: _leidos.contains(p.id))).toList();
      notifyListeners();
    } catch (_) {
      // Los avisos son un extra: si falla, el resto de la pantalla sigue igual.
    }
  }

  Future<void> marcarTodasLeidas() async {
    for (final a in avisos) {
      a.leida = true;
      _leidos.add(a.id);
    }
    notifyListeners();
    await _store.guardar(LocalStore.kAvisosLeidos, _leidos.join(','));
  }
}
