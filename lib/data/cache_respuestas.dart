import 'dart:convert';

import 'local_store.dart';

/// Última respuesta correcta de cada consulta GET, guardada en el dispositivo
/// para poder mostrarla cuando no hay conexión con el servidor.
class RespuestaGuardada {
  const RespuestaGuardada(this.json, this.fecha);

  final Map<String, dynamic> json;

  /// Momento en que se guardó la respuesta.
  final DateTime fecha;
}

class CacheRespuestas {
  CacheRespuestas._();

  static final CacheRespuestas instance = CacheRespuestas._();

  static const String _prefijo = 'cache_';

  final LocalStore _store = LocalStore.instance;

  String _clave(Uri uri) => '$_prefijo${uri.path}?${uri.query}';

  Future<void> guardar(Uri uri, Map<String, dynamic> json) async {
    try {
      final valor = jsonEncode(<String, Object?>{
        't': DateTime.now().millisecondsSinceEpoch,
        'j': json,
      });
      await _store.guardar(_clave(uri), valor);
    } catch (_) {
      // Sin caché la app sigue funcionando; solo que no podrá mostrar datos sin conexión.
    }
  }

  Future<RespuestaGuardada?> leer(Uri uri) async {
    try {
      final texto = await _store.leer(_clave(uri));
      if (texto == null || texto.isEmpty) return null;
      final decoded = jsonDecode(texto);
      if (decoded is! Map) return null;
      final t = decoded['t'];
      final j = decoded['j'];
      if (t is! int || j is! Map) return null;
      return RespuestaGuardada(
        Map<String, dynamic>.from(j),
        DateTime.fromMillisecondsSinceEpoch(t),
      );
    } catch (_) {
      return null;
    }
  }

  /// Se llama al iniciar o cerrar sesión, para que los datos de una tienda no
  /// queden disponibles para otro usuario.
  Future<void> borrarTodo() => _store.borrarPrefijo(_prefijo);
}
