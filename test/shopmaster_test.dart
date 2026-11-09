import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:shopmaster_mobile/core/format.dart';
import 'package:shopmaster_mobile/core/validators.dart';
import 'package:shopmaster_mobile/data/api_client.dart';
import 'package:shopmaster_mobile/data/models.dart';
import 'package:shopmaster_mobile/data/repository.dart';
import 'package:shopmaster_mobile/screens/inventory_screen.dart';
import 'package:shopmaster_mobile/widgets/charts.dart';
import 'package:shopmaster_mobile/widgets/prediction_charts.dart';

InventarioRepository _repoConToken() =>
    InventarioRepository(MockApiClient(latency: Duration.zero, tokenProvider: () => 'token'));

void main() {
  group('formatos', () {
    test('formatCop usa punto de miles', () {
      expect(formatCop(4500), '\$4.500');
      expect(formatCop(2486700, space: true), '\$ 2.486.700');
      expect(formatCop(0), '\$0');
    });

    test('formatDecimal usa coma', () {
      expect(formatDecimal(4.2), '4,2');
    });

    test('formatUnidades singular y plural', () {
      expect(formatUnidades(1), '1 unidad');
      expect(formatUnidades(20), '20 unidades');
    });
  });

  group('reglas de negocio del contrato (2.1)', () {
    test('estado según el stock', () {
      expect(estadoDesdeStock(0), EstadoStock.sinStock);
      expect(estadoDesdeStock(1), EstadoStock.bajo);
      expect(estadoDesdeStock(5), EstadoStock.bajo);
      expect(estadoDesdeStock(6), EstadoStock.normal);
    });

    test('nivelStock = min(100, redondeo(100 × stock ÷ 25))', () {
      expect(nivelStockDesde(20), 80);
      expect(nivelStockDesde(2), 8);
      expect(nivelStockDesde(0), 0);
      expect(nivelStockDesde(25), 100);
      expect(nivelStockDesde(40), 100);
    });

    test('textos y códigos de la API', () {
      expect(EstadoStock.bajo.etiqueta, 'Stock bajo');
      expect(EstadoStock.sinStock.codigoApi, 'AGOTADO');
      expect(EstadoStock.normal.codigoApi, 'DISPONIBLE');
      expect(Orden.menorStock.codigoApi, 'stock_asc');
    });
  });

  group('modelos', () {
    test('Producto.fromJson con campos opcionales nulos', () {
      final p = Producto.fromJson({
        'id': 'P002',
        'codigo': 'ACE-GOU-1L',
        'codigoBarras': null,
        'nombre': 'Aceite Gourmet',
        'descripcion': null,
        'categoria': 'Aceites',
        'precio': 8500,
        'stock': 2,
        'stockMinimo': 5,
        'nivelStock': 8,
        'estado': 'CRITICO',
        'ventasUltimos7Dias': [
          {'fecha': '2026-10-31', 'unidades': 3},
          {'fecha': '2026-11-06', 'unidades': 2},
        ],
      });
      expect(p.estado, EstadoStock.bajo);
      expect(p.codigoBarras, '');
      expect(p.descripcion, '');
      expect(p.nivel, closeTo(0.08, 1e-9));
      expect(p.ventas7Dias.length, 2);
      expect(p.ventas7Dias.last.inicial, 'V'); // 2026-11-06 es viernes
    });

    test('Perfil: rol, iniciales y saludo', () {
      final perfil = Perfil.fromJson({
        'id': 'U001',
        'nombre': 'Ana Martínez',
        'email': 'ana@mitienda.com',
        'rol': 'ADMIN',
        'tienda': {'id': 'T001', 'nombre': 'Mi tienda'},
      });
      expect(perfil.primerNombre, 'Ana');
      expect(perfil.iniciales, 'AM');
      expect(perfil.rolTexto, 'Administradora');
      expect(perfil.rolYTienda, 'Administradora · Mi tienda');
    });

    test('variacionValorMensual puede venir null', () {
      final r = ResumenInventario.fromJson({
        'totalProductos': 245,
        'productosDisponibles': 224,
        'stockCritico': 18,
        'sinStock': 3,
        'valorInventario': 2486700,
        'variacionValorMensual': null,
      });
      expect(r.variacionMensual, isNull);
      expect(r.totalProductos, r.disponibles + r.stockCritico + r.sinStock);
    });
  });

  group('servidor simulado = contrato v1.1', () {
    final repo = _repoConToken();

    test('resumen: 245 = 224 + 18 + 3, \$2.486.700 y +12 %', () async {
      final r = await repo.resumen();
      expect(r.totalProductos, 245);
      expect(r.disponibles, 224);
      expect(r.stockCritico, 18);
      expect(r.sinStock, 3);
      expect(r.valorInventario, 2486700);
      expect(r.variacionMensual, 12.0);
    });

    test('perfil', () async {
      final p = await repo.perfil();
      expect(p.nombre, 'Ana Martínez');
      expect(p.tiendaNombre, 'Mi tienda');
    });

    test('lista paginada: 245 productos en 13 páginas de 20', () async {
      final p0 = await repo.productos();
      expect(p0.productos.length, 20);
      expect(p0.totalElementos, 245);
      expect(p0.totalPaginas, 13);
      expect(p0.hayMas, isTrue);

      final ultima = await repo.productos(pagina: 12);
      expect(ultima.productos.length, 5);
      expect(ultima.hayMas, isFalse);
    });

    test('filtros por estado y categoría', () async {
      final criticos = await repo.productos(estado: EstadoStock.bajo, tamano: 100);
      expect(criticos.totalElementos, 18);
      expect(criticos.productos.every((p) => p.estado == EstadoStock.bajo), isTrue);

      final agotados = await repo.productos(estado: EstadoStock.sinStock);
      expect(agotados.totalElementos, 3);

      final granos = await repo.productos(categoria: 'Granos');
      expect(granos.totalElementos, 70);

      final aceitesCriticos = await repo.productos(categoria: 'Aceites', estado: EstadoStock.bajo, orden: 'stock_asc');
      expect(aceitesCriticos.productos.first.nombre, 'Aceite Gourmet');
    });

    test('búsqueda por nombre o código, sin distinguir mayúsculas ni tildes', () async {
      final r = await repo.productos(q: 'ARROZ diana');
      expect(r.productos.any((p) => p.id == 'P001'), isTrue);
      final porCodigo = await repo.productos(q: 'arr-dia-500');
      expect(porCodigo.totalElementos, 1);
      final azucar = await repo.productos(q: 'azucar');
      expect(azucar.productos.any((p) => p.nombre == 'Azúcar 1 kg'), isTrue);
    });

    test('sin coincidencias: 200 con lista vacía y totalElementos 0', () async {
      final r = await repo.productos(q: 'zzzzzz');
      expect(r.productos, isEmpty);
      expect(r.totalElementos, 0);
    });

    test('orden por stock y por precio', () async {
      final asc = await repo.productos(orden: 'stock_asc');
      expect(asc.productos.first.stock, 0);
      final desc = await repo.productos(orden: 'stock_desc');
      expect(desc.productos.first.nombre, 'Agua Cristal 600 ml');
      final caro = await repo.productos(orden: 'precio_desc');
      expect(caro.productos.first.nombre, 'Leche en polvo Klim');
    });

    test('estado inválido responde 400 con el mensaje del contrato', () async {
      final api = MockApiClient(latency: Duration.zero, tokenProvider: () => 'token');
      await expectLater(
        api.get('/api/productos', query: {'estado': 'XYZ'}),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 400)
            .having((e) => e.message, 'message', 'El parámetro estado debe ser DISPONIBLE, CRITICO o AGOTADO')),
      );
    });

    test('stock crítico: 18 críticos, 3 agotados, ordenados por stock', () async {
      final sc = await repo.stockCritico();
      expect(sc.totalCritico, 18);
      expect(sc.totalAgotado, 3);
      expect(sc.productos.length, 21);
      expect(sc.productos.first.stock, 0);
      for (var i = 1; i < sc.productos.length; i++) {
        expect(sc.productos[i - 1].stock <= sc.productos[i].stock, isTrue);
      }
      expect(sc.productos.map((p) => p.nombre).take(3), ['Jabón Rey', 'Jugo Hit 1 L', 'Papel Higiénico Elite']);
    });

    test('stock crítico con estado y límite (Inicio)', () async {
      final sc = await repo.stockCritico(estado: EstadoStock.bajo, limite: 2);
      expect(sc.productos.length, 2);
      expect(sc.productos.first.nombre, 'Galletas Festival');
      expect(sc.productos.every((p) => p.estado == EstadoStock.bajo), isTrue);
    });

    test('detalle P001 igual al ejemplo de Postman', () async {
      final p = await repo.producto('P001');
      expect(p.codigo, 'ARR-DIA-500');
      expect(p.codigoBarras, '7702001005008');
      expect(p.nivelStock, 80);
      expect(p.estado, EstadoStock.normal);
      expect(p.ubicacion, 'Estante A · Nivel 2');
      expect(p.ventas7Dias.map((v) => v.unidades), [12, 9, 6, 11, 8, 15, 10]);
    });

    test('detalle P002 con opcionales nulos y P999 → 404', () async {
      final p = await repo.producto('P002');
      expect(p.codigoBarras, '');
      expect(p.descripcion, '');
      expect(p.estado, EstadoStock.bajo);
      await expectLater(
        repo.producto('P999'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Producto no encontrado')),
      );
    });

    test('estadísticas', () async {
      final e = await repo.estadisticas();
      expect(e.categorias.map((c) => c.categoria), ['Granos', 'Lácteos', 'Galletas', 'Aseo', 'Aceites', 'Bebidas']);
      expect(e.categorias.map((c) => c.valor.round()), [70, 45, 40, 35, 30, 25]);
      expect(e.categorias.fold<double>(0, (s, c) => s + c.valor), 245);
      expect(e.disponible, 224);
      expect(e.critico, 18);
      expect(e.agotado, 3);
      expect(e.valorUltimosDias.length, 7);
      expect(e.valorUltimosDias.last.valor, 2486700);
      expect(e.masStock.map((p) => p.unidades), [40, 30, 25, 20]);
      expect(e.masStock.first.nombre, 'Agua Cristal 600 ml');
      expect(e.menorCobertura?.categoria, 'Aceites');
      expect(e.categoriaMayor?.categoria, 'Granos');
    });
  });

  group('acceso', () {
    test('login correcto devuelve token de 1 hora', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero));
      final s = await repo.login('ana@mitienda.com', 'clave');
      expect(s.token, isNotEmpty);
      expect(s.expiraEnSegundos, 3600);
    });

    test('login con credenciales incorrectas → 401', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero));
      await expectLater(
        repo.login('ana@mitienda.com', 'incorrecta'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 401)
            .having((e) => e.message, 'message', 'Correo o contraseña incorrectos')),
      );
    });

    test('recuperar: mensaje del contrato y 400 si el correo no es válido', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero));
      expect(await repo.recuperar('ana@mitienda.com'), startsWith('Si el correo está registrado'));
      await expectLater(
        repo.recuperar('ana@'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
      );
    });

    test('sin token las rutas protegidas responden 401 y avisan', () async {
      var avisos = 0;
      final repo = InventarioRepository(
        MockApiClient(latency: Duration.zero, onUnauthorized: () => avisos++),
      );
      await expectLater(repo.resumen(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
      expect(avisos, 1);
    });
  });

  group('cliente HTTP', () {
    HttpApiClient cliente(http.Client c, {String? token, void Function()? onUnauthorized}) => HttpApiClient(
          client: c,
          baseUrl: 'https://mock.test',
          tokenProvider: () => token,
          onUnauthorized: onUnauthorized,
        );

    http.Response json(int code, Object body) =>
        http.Response(jsonEncode(body), code, headers: {'content-type': 'application/json; charset=utf-8'});

    test('envía Bearer en rutas protegidas y no en el login', () async {
      final vistos = <String, String?>{};
      final c = cliente(
        MockClient((req) async {
          vistos[req.url.path] = req.headers['Authorization'];
          return json(200, {'success': true, 'data': {}});
        }),
        token: 'abc',
      );
      await c.get('/api/perfil');
      await c.post('/api/auth/login', {'email': 'a@b.co', 'password': 'x'});
      expect(vistos['/api/perfil'], 'Bearer abc');
      expect(vistos['/api/auth/login'], isNull);
    });

    test('manda los filtros como parámetros de consulta', () async {
      Uri? uri;
      final c = cliente(
        MockClient((req) async {
          uri = req.url;
          return json(200, {'success': true, 'data': []});
        }),
        token: 'abc',
      );
      await c.get('/api/productos', query: {'categoria': 'Aceites', 'estado': 'CRITICO', 'orden': 'stock_asc'});
      expect(uri!.queryParameters['categoria'], 'Aceites');
      expect(uri!.queryParameters['estado'], 'CRITICO');
      expect(uri!.queryParameters['orden'], 'stock_asc');
    });

    test('401 fuera del login cierra sesión; en el login muestra el mensaje', () async {
      var avisos = 0;
      final c = cliente(
        MockClient((req) async => json(401, {'success': false, 'message': 'Token inválido o vencido'})),
        token: 'viejo',
        onUnauthorized: () => avisos++,
      );
      await expectLater(c.get('/api/inventario/resumen'), throwsA(isA<ApiException>()));
      expect(avisos, 1);

      final login = cliente(
        MockClient((req) async => json(401, {'success': false, 'message': 'Correo o contraseña incorrectos'})),
        onUnauthorized: () => avisos++,
      );
      await expectLater(
        login.post('/api/auth/login', {'email': 'a@b.co', 'password': 'x'}),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Correo o contraseña incorrectos')),
      );
      expect(avisos, 1); // el login no dispara el cierre de sesión
    });

    test('400, 403, 404 y 500 se traducen a mensajes', () async {
      Future<ApiException> falla(int code, Map<String, Object?> body) async {
        final c = cliente(MockClient((req) async => json(code, body)), token: 't');
        try {
          await c.get('/api/productos/P999');
        } on ApiException catch (e) {
          return e;
        }
        fail('debía lanzar ApiException');
      }

      expect((await falla(400, {'success': false, 'message': 'El parámetro estado debe ser DISPONIBLE, CRITICO o AGOTADO'})).message,
          'El parámetro estado debe ser DISPONIBLE, CRITICO o AGOTADO');
      expect((await falla(403, {'success': false})).message, contains('tienda'));
      expect((await falla(404, {'success': false, 'message': 'Producto no encontrado'})).message, 'Producto no encontrado');
      expect((await falla(500, {'success': false, 'message': 'Error interno del servidor'})).statusCode, 500);
    });

    test('sin conexión', () async {
      final c = cliente(MockClient((req) async => throw http.ClientException('sin red')), token: 't');
      await expectLater(
        c.get('/api/perfil'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('conexión'))),
      );
    });
  });

  group('treemap', () {
    test('cubre todo el rectángulo con 6 categorías', () {
      const rect = Rect.fromLTWH(0, 0, 300, 200);
      final tiles = treemapLayout([70, 45, 40, 35, 30, 25], rect);
      expect(tiles.length, 6);
      final area = tiles.fold<double>(0, (s, t) => s + t.rect.width * t.rect.height);
      expect(area, closeTo(300 * 200, 0.001));
    });
  });

  group('contraseña y chat (v1.2)', () {
    test('política de contraseña: 8 a 72, con letra y número', () {
      expect(errorPassword('Clave1234'), isNull);
      expect(errorPassword('corta1'), isNotNull);
      expect(errorPassword('sololetrasaqui'), isNotNull);
      expect(errorPassword('12345678'), isNotNull);
      expect(errorPassword('a1${'x' * 80}'), isNotNull);
      expect(esCodigoValido('123456'), isTrue);
      expect(esCodigoValido('12345'), isFalse);
      expect(esCodigoValido('12345a'), isFalse);
    });

    test('restablecer: código correcto, incorrecto y contraseña débil', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero));
      expect(await repo.restablecer('ana@mitienda.com', '123456', 'NuevaClave99'), contains('actualizada'));
      await expectLater(
        repo.restablecer('ana@mitienda.com', '000000', 'NuevaClave99'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 400)
            .having((e) => e.message, 'message', 'El código no es válido o venció')),
      );
      await expectLater(
        repo.restablecer('ana@mitienda.com', '123456', 'corta'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
      );
    });

    test('cambiar contraseña: clave actual incorrecta → 400 y no cierra la sesión', () async {
      var avisos = 0;
      final repo = InventarioRepository(
        MockApiClient(latency: Duration.zero, tokenProvider: () => 'token', onUnauthorized: () => avisos++),
      );
      expect(await repo.cambiarPassword('Clave1234', 'OtraClave55'), 'Tu contraseña fue actualizada.');
      await expectLater(
        repo.cambiarPassword('incorrecta', 'OtraClave55'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 400)
            .having((e) => e.message, 'message', 'La contraseña actual no es correcta')),
      );
      expect(avisos, 0);
    });

    test('chat: devuelve la respuesta y exige token', () async {
      final repo = _repoConToken();
      expect(await repo.chat('¿Qué está agotado?'), isNotEmpty);
      await expectLater(
        repo.chat('   '),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
      );
      final sinToken = InventarioRepository(MockApiClient(latency: Duration.zero));
      await expectLater(
        sinToken.chat('hola'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('cliente HTTP: restablecer es público (sin Bearer); chat y cambio de clave llevan Bearer', () async {
      final vistos = <String, String?>{};
      final cuerpos = <String, Object?>{};
      final c = HttpApiClient(
        client: MockClient((req) async {
          vistos[req.url.path] = req.headers['Authorization'];
          cuerpos[req.url.path] = jsonDecode(req.body);
          return http.Response(
            jsonEncode({'success': true, 'data': {'respuesta': 'Hola'}}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        baseUrl: 'https://mock.test',
        tokenProvider: () => 'abc',
      );
      final repo = InventarioRepository(c);
      await repo.restablecer('ana@mitienda.com', '123456', 'NuevaClave99');
      await repo.cambiarPassword('Clave1234', 'OtraClave55');
      expect(await repo.chat('hola'), 'Hola');

      expect(vistos['/api/auth/restablecer'], isNull);
      expect(vistos['/api/perfil/password'], 'Bearer abc');
      expect(vistos['/api/chat'], 'Bearer abc');
      expect(cuerpos['/api/auth/restablecer'], {'email': 'ana@mitienda.com', 'codigo': '123456', 'nuevaPassword': 'NuevaClave99'});
      expect(cuerpos['/api/perfil/password'], {'passwordActual': 'Clave1234', 'nuevaPassword': 'OtraClave55'});
      expect(cuerpos['/api/chat'], {'mensaje': 'hola'});
    });
  });

  group('predicción de precios vs IPC (v1.2)', () {
    test('lista de productos y pronóstico con la forma del contrato', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero, tokenProvider: () => 'token'));
      final productos = await repo.prediccionProductos();
      expect(productos, isNotEmpty);
      final p = await repo.prediccionPrecios(productos.first.nombre, anios: 3);
      expect(p.producto, productos.first.nombre);
      expect(p.historico, isNotEmpty);
      expect(p.pronostico.length, 3);
      expect(p.pronostico.first.anio, p.historico.last.anio + 1);
      expect(p.resumen.anio, p.pronostico.first.anio);
      expect(p.fuenteInflacion, isNotEmpty);
    });

    test('el veredicto sigue la regla de ±1 punto frente a la referencia', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero, tokenProvider: () => 'token'));
      for (final prod in await repo.prediccionProductos()) {
        final r = (await repo.prediccionPrecios(prod.nombre)).resumen;
        final base = r.ipcCartagenaPct ?? r.ipcNacionalPct!;
        final dif = r.variacionPronosticoPct - base;
        final esperado = dif > 1.0
            ? VeredictoPrecio.porEncima
            : dif < -1.0
                ? VeredictoPrecio.porDebajo
                : VeredictoPrecio.enLinea;
        expect(r.veredicto, esperado, reason: prod.nombre);
      }
    });

    test('fromJson tolera Cartagena sin dato y veredicto desconocido', () {
      final p = PrediccionPrecios.fromJson({
        'producto': 'X',
        'historico': [
          {'anio': 2015, 'precio': 1000, 'variacionPct': null, 'ipcNacionalPct': 6.77, 'ipcCartagenaPct': null},
        ],
        'pronostico': [
          {'anio': 2025, 'precio': 1100, 'variacionPct': 10.0, 'ipcNacionalPct': 5.1, 'ipcCartagenaPct': null, 'ipcEsReferencia': false, 'veredicto': 'POR_ENCIMA'},
        ],
        'resumen': {'anio': 2025, 'variacionPronosticoPct': 10.0, 'ipcNacionalPct': 5.1, 'ipcCartagenaPct': null, 'veredicto': 'POR_ENCIMA', 'mensaje': 'm'},
        'fuentes': {'precios': 'a', 'inflacion': 'b'},
      });
      expect(p.historico.first.ipcCartagenaPct, isNull);
      expect(p.historico.first.variacionPct, isNull);
      expect(p.resumen.veredicto, VeredictoPrecio.porEncima);
      expect(p.fuentePrecios, 'a');
    });

    test('producto inexistente y años fuera de rango dan error legible', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero, tokenProvider: () => 'token'));
      await expectLater(repo.prediccionPrecios('No existe'), throwsA(isA<ApiException>()));
      await expectLater(repo.prediccionPrecios('Leche Colanta 1L', anios: 9), throwsA(isA<ApiException>()));
    });

    test('cliente HTTP: GET con Bearer y parámetros producto y anios', () async {
      Uri? visto;
      String? auth;
      final c = HttpApiClient(
        client: MockClient((req) async {
          visto = req.url;
          auth = req.headers['Authorization'];
          return http.Response(
            jsonEncode({'success': true, 'data': {
              'producto': 'Leche Colanta 1L',
              'historico': [], 'pronostico': [],
              'resumen': {'anio': 2025, 'variacionPronosticoPct': 1.0, 'veredicto': 'EN_LINEA', 'mensaje': 'm'},
              'fuentes': {'precios': '', 'inflacion': ''},
            }}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        baseUrl: 'https://mock.test',
        tokenProvider: () => 'abc',
      );
      await InventarioRepository(c).prediccionPrecios('Leche Colanta 1L', anios: 2);
      expect(visto!.path, '/api/prediccion/precios');
      expect(visto!.queryParameters, {'producto': 'Leche Colanta 1L', 'anios': '2'});
      expect(auth, 'Bearer abc');
    });
  });

  group('panorama de predicción (v1.2)', () {
    test('el servidor simulado compara todos los productos y los ordena por diferencia', () async {
      final repo = InventarioRepository(MockApiClient(latency: Duration.zero, tokenProvider: () => 'token'));
      final pan = await repo.prediccionPanorama();
      expect(pan.productos.length, 5);
      expect(pan.porEncima + pan.enLinea + pan.porDebajo, pan.productos.length);
      expect(pan.ipcBasePct, isNotNull);
      for (var i = 1; i < pan.productos.length; i++) {
        expect(pan.productos[i - 1].diferenciaPuntos >= pan.productos[i].diferenciaPuntos, isTrue);
      }
      // Coincide con el detalle de cada producto.
      final detalle = await repo.prediccionPrecios(pan.productos.first.nombre, anios: 1);
      expect(detalle.resumen.variacionPronosticoPct, pan.productos.first.variacionPct);
      expect(detalle.resumen.veredicto, pan.productos.first.veredicto);
    });

    test('fromJson del panorama tolera IPC de Cartagena nulo', () {
      final p = PanoramaPrediccion.fromJson({
        'anio': 2025,
        'ipcNacionalPct': 5.1,
        'ipcCartagenaPct': null,
        'conteo': {'porEncima': 1, 'enLinea': 0, 'porDebajo': 0},
        'productos': [
          {'nombre': 'Arroz', 'ultimoPrecio': 100, 'precioPronosticado': 110, 'variacionPct': 10, 'diferenciaPuntos': 4.9, 'veredicto': 'POR_ENCIMA'},
        ],
      });
      expect(p.ipcBasePct, 5.1);
      expect(p.productos.single.veredicto, VeredictoPrecio.porEncima);
    });

    test('ayudas de los gráficos: nombre corto y extremos', () {
      expect(nombreCorto('Arroz Diana x 500g'), 'Arroz');
      PanoramaProducto prod(int i) => PanoramaProducto(
          nombre: 'P$i', ultimoPrecio: 1, precioPronosticado: 1, variacionPct: 0, diferenciaPuntos: 20.0 - i, veredicto: VeredictoPrecio.enLinea);
      final lista = [for (var i = 0; i < 12; i++) prod(i)];
      final sel = seleccionarExtremos(lista, max: 8);
      expect(sel.map((e) => e.nombre).toList(), ['P0', 'P1', 'P2', 'P3', 'P8', 'P9', 'P10', 'P11']);
      expect(seleccionarExtremos(lista.take(5).toList()).length, 5);
    });

    test('cliente HTTP: GET /api/prediccion/panorama con Bearer', () async {
      String? auth;
      Uri? visto;
      final c = HttpApiClient(
        client: MockClient((req) async {
          auth = req.headers['Authorization'];
          visto = req.url;
          return http.Response(
            jsonEncode({'success': true, 'data': {'anio': 2025, 'conteo': {}, 'productos': []}}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        baseUrl: 'https://mock.test',
        tokenProvider: () => 'abc',
      );
      final p = await InventarioRepository(c).prediccionPanorama();
      expect(visto!.path, '/api/prediccion/panorama');
      expect(auth, 'Bearer abc');
      expect(p.productos, isEmpty);
    });
  });
}
