import '../core/config.dart';
import 'api_client.dart';
import 'app_state.dart';
import 'mock_data.dart' show mensajeRecuperar;
import 'models.dart';

/// Punto único de acceso a los 8 endpoints del contrato v1.1. Guarda en
/// memoria la última respuesta de cada consulta; [invalidar] fuerza a pedirlas
/// de nuevo (por ejemplo al cerrar sesión o al reintentar).
class InventarioRepository {
  InventarioRepository(this._api);

  static final InventarioRepository instance = InventarioRepository(_crearCliente());

  static ApiClient _crearCliente() {
    String? token() => AppState.instance.token;
    void expirada() => AppState.instance.sesionExpirada();
    if (AppConfig.useMock) {
      return MockApiClient(tokenProvider: token, onUnauthorized: expirada);
    }
    return HttpApiClient(tokenProvider: token, onUnauthorized: expirada);
  }

  final ApiClient _api;
  final Map<String, Future<dynamic>> _cache = <String, Future<dynamic>>{};

  Future<T> _memo<T>(String key, Future<T> Function() cargar) {
    final guardado = _cache[key];
    if (guardado != null) return guardado as Future<T>;

    final futuro = cargar();
    _cache[key] = futuro;
    // Si falla no se guarda, para que "Reintentar" vuelva a pedirlo.
    futuro.then((_) {}, onError: (Object _) {
      _cache.remove(key);
    });
    return futuro;
  }

  void invalidar() => _cache.clear();

  Map<String, dynamic> _data(Map<String, dynamic> envelope) {
    final d = envelope['data'];
    if (d is Map) return Map<String, dynamic>.from(d);
    // Tolerancia: algunos ejemplos del mock devuelven los campos sueltos, sin
    // el envoltorio {"success": true, "data": {...}}.
    if (!envelope.containsKey('data') && envelope.keys.any((k) => k != 'success' && k != 'message')) {
      return Map<String, dynamic>.from(envelope);
    }
    throw ApiException('La respuesta del servidor no tiene el formato esperado.');
  }

  // --- Acceso (sin token, sin caché) ---------------------------------------

  /// POST /api/auth/login
  Future<SesionApi> login(String email, String password) async {
    final r = await _api.post('/api/auth/login', {'email': email, 'password': password});
    final sesion = SesionApi.fromJson(_data(r));
    if (sesion.token.isEmpty) {
      throw ApiException('La respuesta del servidor no tiene el formato esperado.');
    }
    return sesion;
  }

  /// POST /api/auth/recuperar. Devuelve el mensaje del servidor.
  Future<String> recuperar(String email) async {
    final r = await _api.post('/api/auth/recuperar', {'email': email});
    final m = r['message'];
    return m is String && m.isNotEmpty ? m : mensajeRecuperar;
  }

  /// POST /api/auth/restablecer: el código de 6 dígitos del correo + la nueva
  /// contraseña. Devuelve el mensaje del servidor.
  Future<String> restablecer(String email, String codigo, String nuevaPassword) async {
    final r = await _api.post('/api/auth/restablecer', {
      'email': email,
      'codigo': codigo,
      'nuevaPassword': nuevaPassword,
    });
    return _mensaje(r, 'Tu contraseña fue actualizada. Ya puedes ingresar.');
  }

  String _mensaje(Map<String, dynamic> r, String porDefecto) {
    final m = r['message'];
    return m is String && m.isNotEmpty ? m : porDefecto;
  }

  // --- Acciones de la cuenta (con token, sin caché) -------------------------

  /// POST /api/perfil/password. Si la contraseña actual no es correcta el
  /// servidor responde 400 (no 401), así que la sesión no se cierra.
  Future<String> cambiarPassword(String passwordActual, String nuevaPassword) async {
    final r = await _api.post('/api/perfil/password', {
      'passwordActual': passwordActual,
      'nuevaPassword': nuevaPassword,
    });
    return _mensaje(r, 'Tu contraseña fue actualizada.');
  }

  /// POST /api/chat. La tienda sale del token. Devuelve la respuesta del asistente.
  Future<String> chat(String mensaje) async {
    final r = await _api.post('/api/chat', {'mensaje': mensaje});
    final respuesta = _data(r)['respuesta'];
    if (respuesta is String && respuesta.trim().isNotEmpty) return respuesta.trim();
    throw ApiException('El asistente no respondió. Intenta de nuevo.');
  }

  // --- Consultas (con token) ------------------------------------------------

  /// GET /api/perfil
  Future<Perfil> perfil() => _memo('perfil', () async {
        final r = await _api.get('/api/perfil');
        return Perfil.fromJson(_data(r));
      });

  /// GET /api/inventario/resumen
  Future<ResumenInventario> resumen() => _memo('resumen', () async {
        final r = await _api.get('/api/inventario/resumen');
        return ResumenInventario.fromJson(_data(r));
      });

  /// GET /api/productos  (los filtros, el orden y la paginación los aplica el servidor)
  Future<PaginaProductos> productos({
    String q = '',
    String? categoria,
    EstadoStock? estado,
    String orden = 'nombre',
    int pagina = 0,
    int tamano = 20,
  }) {
    final query = <String, String>{
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      if (estado != null) 'estado': estado.codigoApi,
      'orden': orden,
      'pagina': '$pagina',
      'tamano': '$tamano',
    };
    final key = 'productos?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return _memo(key, () async {
      final r = await _api.get('/api/productos', query: query);
      return PaginaProductos.fromJson(r);
    });
  }

  /// GET /api/productos/{id}
  Future<Producto> producto(String id) => _memo('producto/$id', () async {
        final r = await _api.get('/api/productos/${Uri.encodeComponent(id)}');
        return Producto.fromJson(_data(r));
      });

  /// GET /api/productos/stock-critico  (estado: CRITICO o AGOTADO; sin estado trae ambos)
  Future<StockCritico> stockCritico({EstadoStock? estado, int? limite}) {
    final query = <String, String>{
      if (estado != null && estado != EstadoStock.normal) 'estado': estado.codigoApi,
      if (limite != null) 'limite': '$limite',
    };
    final key = 'stock-critico?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return _memo(key, () async {
      final r = await _api.get('/api/productos/stock-critico', query: query);
      return StockCritico.fromJson(_data(r));
    });
  }

  /// GET /api/prediccion/productos: productos que tienen historial de precios y modelo.
  Future<List<ProductoPrecio>> prediccionProductos() => _memo('prediccion/productos', () async {
        final r = await _api.get('/api/prediccion/productos');
        final d = r['data'];
        if (d is! List) {
          throw ApiException('La respuesta del servidor no tiene el formato esperado.');
        }
        return d.whereType<Map>().map((e) => ProductoPrecio.fromJson(Map<String, dynamic>.from(e))).toList();
      });

  /// GET /api/prediccion/precios: historial, pronóstico de [anios] años y comparación con el IPC del DANE.
  Future<PrediccionPrecios> prediccionPrecios(String producto, {int anios = 3}) {
    return _memo('prediccion/precios/$producto/$anios', () async {
      final r = await _api.get('/api/prediccion/precios', query: {'producto': producto, 'anios': '$anios'});
      return PrediccionPrecios.fromJson(_data(r));
    });
  }

  /// GET /api/prediccion/panorama: pronóstico del próximo año de todos los productos frente al IPC.
  Future<PanoramaPrediccion> prediccionPanorama() => _memo('prediccion/panorama', () async {
        final r = await _api.get('/api/prediccion/panorama');
        return PanoramaPrediccion.fromJson(_data(r));
      });

  /// GET /api/inventario/estadisticas
  Future<Estadisticas> estadisticas() => _memo('estadisticas', () async {
        final r = await _api.get('/api/inventario/estadisticas');
        return Estadisticas.fromJson(_data(r));
      });
}
