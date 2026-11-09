import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import 'mock_data.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

typedef TokenProvider = String? Function();

const String _mensajeSesion = 'Tu sesión venció. Ingresa de nuevo.';

bool _esRutaPublica(String path) => path.startsWith('/api/auth/');

/// Cliente de la ShopMaster API. Siempre devuelve el JSON ya decodificado y
/// validado (`success: true`); si el servidor responde con error lanza
/// [ApiException] con el mensaje para el usuario.
abstract class ApiClient {
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query});

  Future<Map<String, dynamic>> post(String path, Map<String, Object?> body);
}

/// Cliente real: agrega `Authorization: Bearer <token>` en cada petición salvo
/// login y recuperar. Si recibe 401 en otra pantalla avisa con [onUnauthorized]
/// para borrar el token y volver al login.
class HttpApiClient implements ApiClient {
  HttpApiClient({http.Client? client, this.tokenProvider, this.onUnauthorized, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;
  final TokenProvider? tokenProvider;
  final void Function()? onUnauthorized;

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _enviar('GET', path, query: query);
  }

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, Object?> body) {
    return _enviar('POST', path, body: body);
  }

  Future<Map<String, dynamic>> _enviar(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    final token = tokenProvider?.call();
    if (!_esRutaPublica(path) && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final futuro = method == 'POST'
          ? _client.post(uri, headers: headers, body: jsonEncode(body ?? <String, Object?>{}))
          : _client.get(uri, headers: headers);
      response = await futuro.timeout(AppConfig.timeout);
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (_) {
      throw ApiException('No hay conexión con el servidor. Revisa tu red e intenta de nuevo.');
    }

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) json = Map<String, dynamic>.from(decoded);
    } catch (_) {
      json = null;
    }
    final mensaje = json?['message'] is String ? json!['message'] as String : null;
    final codigo = response.statusCode;

    if (codigo == 401) {
      if (_esRutaPublica(path)) {
        throw ApiException(mensaje ?? 'Correo o contraseña incorrectos', 401);
      }
      onUnauthorized?.call();
      throw ApiException(_mensajeSesion, 401);
    }
    if (codigo == 403) {
      throw ApiException(mensaje ?? 'Tu usuario no tiene una tienda asignada.', 403);
    }
    if (codigo == 404) {
      throw ApiException(mensaje ?? 'No se encontró lo que buscas.', 404);
    }
    if (codigo == 400) {
      throw ApiException(mensaje ?? 'La solicitud no es válida.', 400);
    }
    if (codigo < 200 || codigo >= 300) {
      throw ApiException(mensaje ?? 'Error del servidor. Intenta de nuevo en un momento.', codigo);
    }
    if (json == null) {
      throw ApiException('La respuesta del servidor no tiene el formato esperado.');
    }
    if (json['success'] == false) {
      throw ApiException(mensaje ?? 'No se pudo completar la operación.', codigo);
    }
    return json;
  }
}

/// Servidor simulado local: responde igual que el contrato v1.1 (con filtros,
/// orden y paginación, que el Postman Mock Server no aplica). También exige el
/// token en las rutas protegidas, como la API real.
class MockApiClient implements ApiClient {
  MockApiClient({this.latency = const Duration(milliseconds: 400), this.tokenProvider, this.onUnauthorized});

  final Duration latency;
  final TokenProvider? tokenProvider;
  final void Function()? onUnauthorized;

  Future<Map<String, dynamic>> _responder(String path, Map<String, dynamic> Function() construir) async {
    await Future<void>.delayed(latency);

    if (!_esRutaPublica(path)) {
      final token = tokenProvider?.call();
      if (token == null || token.isEmpty) {
        onUnauthorized?.call();
        throw ApiException(_mensajeSesion, 401);
      }
    }
    try {
      return construir();
    } on MockError catch (e) {
      throw ApiException(e.mensaje, e.codigo);
    }
  }

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    final q = query ?? const <String, String>{};
    return _responder(path, () {
      switch (path) {
        case '/api/perfil':
          return perfilJson();
        case '/api/inventario/resumen':
          return resumenJson();
        case '/api/inventario/estadisticas':
          return estadisticasJson();
        case '/api/productos':
          return listarProductosJson(q);
        case '/api/productos/stock-critico':
          return stockCriticoJson(q);
        case '/api/prediccion/productos':
          return prediccionProductosJson();
        case '/api/prediccion/precios':
          return prediccionPreciosJson(q);
        case '/api/prediccion/panorama':
          return prediccionPanoramaJson();
      }
      const prefijo = '/api/productos/';
      if (path.startsWith(prefijo)) {
        return detalleProductoJson(path.substring(prefijo.length));
      }
      throw MockError(404, 'Ruta no soportada por el servidor simulado: $path');
    });
  }

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, Object?> body) {
    return _responder(path, () {
      switch (path) {
        case '/api/auth/login':
          return loginJson(body);
        case '/api/auth/recuperar':
          return recuperarJson(body);
        case '/api/auth/restablecer':
          return restablecerJson(body);
        case '/api/perfil/password':
          return cambiarPasswordJson(body);
        case '/api/chat':
          return chatJson(body);
      }
      throw MockError(404, 'Ruta no soportada por el servidor simulado: $path');
    });
  }
}
