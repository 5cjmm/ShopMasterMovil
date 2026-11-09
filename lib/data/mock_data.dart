import '../core/validators.dart';

// Datos de referencia del contrato v1.1 (sección 6): 245 productos,
// 224 disponibles / 18 críticos / 3 agotados, valor $2.486.700, +12 %,
// categorías Granos 70, Lácteos 45, Galletas 40, Aseo 35, Aceites 30, Bebidas 25.
//
// Los productos P001–P033 son los mismos de la colección de Postman; el resto
// se genera de forma determinista (siempre con stock mayor que 5).

class _Base {
  const _Base(this.id, this.nombre, this.categoria, this.precio, this.stock);
  final String id;
  final String nombre;
  final String categoria;
  final int precio;
  final int stock;
}

const List<_Base> _nombrados = [
  _Base('P001', 'Arroz Diana', 'Granos', 4500, 20),
  _Base('P002', 'Aceite Gourmet', 'Aceites', 8500, 2),
  _Base('P003', 'Leche Entera', 'Lácteos', 4200, 15),
  _Base('P004', 'Leche Alpina', 'Lácteos', 2800, 15),
  _Base('P005', 'Detergente Fab', 'Aseo', 5200, 12),
  _Base('P006', 'Papel Higiénico Elite', 'Aseo', 6900, 0),
  _Base('P007', 'Lentejas Diana', 'Granos', 3800, 30),
  _Base('P008', 'Frijol Cargamanto', 'Granos', 7200, 3),
  _Base('P009', 'Aceite Vegetal 1 L', 'Aceites', 8500, 8),
  _Base('P010', 'Galletas Saltín', 'Galletas', 2500, 25),
  _Base('P011', 'Gaseosa 1.5 L', 'Bebidas', 5000, 18),
  _Base('P012', 'Jugo Hit 1 L', 'Bebidas', 3200, 0),
  _Base('P013', 'Jabón Rey', 'Aseo', 2100, 0),
  _Base('P014', 'Azúcar 1 kg', 'Granos', 4000, 3),
  _Base('P015', 'Galletas Noel', 'Galletas', 3000, 4),
  _Base('P016', 'Queso Campesino', 'Lácteos', 9800, 6),
  _Base('P017', 'Cloro Límpido', 'Aseo', 3900, 14),
  _Base('P018', 'Agua Cristal 600 ml', 'Bebidas', 1800, 40),
  _Base('P019', 'Galletas Festival', 'Galletas', 1700, 1),
  _Base('P020', 'Yogurt Alpina', 'Lácteos', 3500, 9),
  _Base('P021', 'Sal Refisal 1 kg', 'Granos', 2200, 2),
  _Base('P022', 'Harina PAN 1 kg', 'Granos', 4800, 5),
  _Base('P023', 'Pasta Doria 500 g', 'Granos', 3600, 4),
  _Base('P024', 'Café Sello Rojo 250 g', 'Granos', 7800, 3),
  _Base('P025', 'Mantequilla Alpina', 'Lácteos', 6500, 4),
  _Base('P026', 'Leche en polvo Klim', 'Lácteos', 18500, 2),
  _Base('P027', 'Kumis Alpina', 'Lácteos', 3300, 5),
  _Base('P028', 'Aceite Girasol 1 L', 'Aceites', 9200, 4),
  _Base('P029', 'Galletas Ducales', 'Galletas', 2800, 3),
  _Base('P030', 'Suavizante Suavitel', 'Aseo', 8900, 2),
  _Base('P031', 'Shampoo Savital', 'Aseo', 11500, 3),
  _Base('P032', 'Gaseosa 2.5 L', 'Bebidas', 7200, 4),
  _Base('P033', 'Jugo Del Valle', 'Bebidas', 4600, 2),
];

/// Detalle exacto de los tres ejemplos de la colección de Postman.
const Map<String, Map<String, Object?>> _detalleFijo = {
  'P001': {
    'codigo': 'ARR-DIA-500',
    'codigoBarras': '7702001005008',
    'descripcion': 'Arroz blanco Diana, presentación de 500 g.',
    'presentacion': 'Bolsa · 500 g',
    'proveedor': 'Distribuidora Diana',
    'ubicacion': 'Estante A · Nivel 2',
    'ventas': [12, 9, 6, 11, 8, 15, 10],
  },
  'P002': {
    'codigo': 'ACE-GOU-1L',
    'codigoBarras': null,
    'descripcion': null,
    'presentacion': 'Botella · 1 L',
    'proveedor': 'Aceites del Caribe',
    'ubicacion': 'Estante B · Nivel 1',
    'ventas': [3, 2, 1, 4, 2, 3, 2],
  },
  'P006': {
    'codigo': 'PAP-ELI-4R',
    'codigoBarras': '7702002003345',
    'descripcion': null,
    'presentacion': 'Paquete · 4 rollos',
    'proveedor': 'Papeles del Norte',
    'ubicacion': 'Bodega',
    'ventas': [5, 4, 6, 3, 7, 2, 0],
  },
};

// Cuántos productos generados lleva cada categoría (212 en total: 245 − 33).
const Map<String, int> _cuotas = {
  'Granos': 62,
  'Lácteos': 38,
  'Galletas': 36,
  'Aseo': 29,
  'Aceites': 27,
  'Bebidas': 20,
};

const List<String> _ordenCategorias = ['Granos', 'Lácteos', 'Galletas', 'Aseo', 'Aceites', 'Bebidas'];

const Map<String, List<String>> _bases = {
  'Granos': ['Arroz', 'Fríjol', 'Lenteja', 'Garbanzo', 'Maíz', 'Avena', 'Harina de trigo', 'Panela'],
  'Lácteos': ['Leche deslactosada', 'Yogurt griego', 'Queso crema', 'Crema de leche', 'Arequipe', 'Leche condensada', 'Cuajada', 'Queso mozzarella'],
  'Galletas': ['Galletas wafer', 'Galletas de soda', 'Galletas integrales', 'Galletas de chocolate', 'Galletas de vainilla', 'Galletas de coco', 'Galletas de limón', 'Galletas rellenas'],
  'Aseo': ['Detergente', 'Jabón líquido', 'Desinfectante', 'Lavaplatos', 'Limpiavidrios', 'Esponja', 'Bolsas de basura', 'Toallas de cocina'],
  'Aceites': ['Aceite de soya', 'Aceite de oliva', 'Aceite de canola', 'Aceite de maíz', 'Aceite de palma', 'Aceite en spray', 'Aceite de coco', 'Aceite mezcla'],
  'Bebidas': ['Agua', 'Gaseosa', 'Jugo', 'Té helado', 'Bebida energética', 'Malta', 'Agua con gas', 'Bebida de avena'],
};

const Map<String, List<String>> _marcas = {
  'Granos': ['Roa', 'Florhuila', 'Premier', 'Campesino', 'Doña Pepa', 'Don Maíz', 'La Mejor', 'Fruver'],
  'Lácteos': ['Colanta', 'Alquería', 'Parmalat', 'Algarra', 'Lechesán', 'Proleche', 'Meals', 'Doña Leche'],
  'Galletas': ['Colombina', 'Nestlé', 'Pozuelo', 'Tosh', 'Ramo', 'Bimbo', 'Fruna', 'Crujiente'],
  'Aseo': ['Axion', 'Ariel', 'Lava', 'Brillante', 'Fuller', 'Clean', 'Fresh', 'Hogar'],
  'Aceites': ['Premier', 'Oleocali', 'Olivetto', 'Cocinero', 'Real', 'Girasol de Oro', 'Campo Verde', 'Sabor Andino'],
  'Bebidas': ['Manantial', 'Postobón', 'Frutal', 'Tropical', 'Nevada', 'Sierra', 'Andina', 'Caribe'],
};

const Map<String, List<String>> _presentaciones = {
  'Granos': ['Bolsa · 500 g', 'Bolsa · 1 kg', 'Bolsa · 250 g', 'Bolsa · 2 kg'],
  'Lácteos': ['Bolsa · 1 L', 'Caja · 1 L', 'Vaso · 200 g', 'Bloque · 500 g'],
  'Galletas': ['Paquete · 6 und', 'Paquete · 12 und', 'Paquete · 300 g', 'Tubo · 150 g'],
  'Aseo': ['Bolsa · 1 kg', 'Botella · 1 L', 'Botella · 500 ml', 'Paquete · 3 und'],
  'Aceites': ['Botella · 1 L', 'Botella · 500 ml', 'Botella · 3 L', 'Frasco · 250 ml'],
  'Bebidas': ['Botella · 600 ml', 'Botella · 1.5 L', 'Botella · 2.5 L', 'Lata · 330 ml'],
};

const Map<String, List<String>> _proveedores = {
  'Granos': ['Distribuidora Diana', 'Granos del Valle'],
  'Lácteos': ['Lácteos de la Sabana', 'Distribuidora Alpina'],
  'Galletas': ['Dulces y Galletas S.A.', 'Distribuidora Noel'],
  'Aseo': ['Papeles del Norte', 'Aseo Total'],
  'Aceites': ['Aceites del Caribe', 'Distribuidora Premier'],
  'Bebidas': ['Bebidas del Caribe', 'Distribuidora Postobón'],
};

class _Puesto {
  const _Puesto(this.pos, this.orden, this.categoria);
  final double pos;
  final int orden;
  final String categoria;
}

String _letras(String s) {
  final b = StringBuffer();
  for (final r in s.toUpperCase().runes) {
    if (r >= 65 && r <= 90) b.writeCharCode(r);
    if (b.length == 3) break;
  }
  final t = b.toString();
  return t.isEmpty ? 'PRD' : t;
}

List<Map<String, dynamic>>? _catalogo;

/// Catálogo completo con todos los campos del detalle (más `estado` y `nivelStock`).
List<Map<String, dynamic>> catalogoJson() => _catalogo ??= _construir();

String _estadoApi(int stock) {
  if (stock <= 0) return 'AGOTADO';
  if (stock <= 5) return 'CRITICO';
  return 'DISPONIBLE';
}

int _nivel(int stock) {
  final v = (100 * stock / 25).round();
  return v > 100 ? 100 : v;
}

String _fechaIso(DateTime d) {
  String dos(int n) => n < 10 ? '0$n' : '$n';
  return '${d.year}-${dos(d.month)}-${dos(d.day)}';
}

Map<String, dynamic> _armar({
  required int n,
  required String id,
  required String nombre,
  required String categoria,
  required int precio,
  required int stock,
  required String base,
  required String marca,
}) {
  final catIdx = _ordenCategorias.indexOf(categoria);
  final fijo = _detalleFijo[id];

  final presentaciones = _presentaciones[categoria]!;
  final proveedores = _proveedores[categoria]!;

  final codigo = fijo?['codigo'] ?? '${_letras(base)}-${_letras(marca)}-$n';
  final codigoBarras = fijo != null ? fijo['codigoBarras'] : (n % 4 == 0 ? null : '7702${100000000 + n * 7919}');
  final descripcion = fijo != null ? fijo['descripcion'] : (n % 3 == 0 ? null : '$nombre. Producto de la categoría $categoria.');
  final presentacion = fijo?['presentacion'] ?? presentaciones[n % presentaciones.length];
  final proveedor = fijo?['proveedor'] ?? proveedores[n % proveedores.length];
  final ubicacion = fijo?['ubicacion'] ?? 'Estante ${'ABCDEF'[catIdx < 0 ? 0 : catIdx]} · Nivel ${n % 4 + 1}';
  final ventas = fijo != null ? List<int>.from(fijo['ventas']! as List) : [for (var d = 0; d < 7; d++) (n * 5 + d * 7) % 10];

  return {
    'id': id,
    'codigo': codigo,
    'codigoBarras': codigoBarras,
    'nombre': nombre,
    'descripcion': descripcion,
    'categoria': categoria,
    'precio': precio,
    'stock': stock,
    'stockMinimo': 5,
    'nivelStock': _nivel(stock),
    'estado': _estadoApi(stock),
    'presentacion': presentacion,
    'proveedor': proveedor,
    'ubicacion': ubicacion,
    '_ventas': ventas,
  };
}

List<Map<String, dynamic>> _construir() {
  final lista = <Map<String, dynamic>>[];

  for (var i = 0; i < _nombrados.length; i++) {
    final b = _nombrados[i];
    lista.add(_armar(
      n: i + 1,
      id: b.id,
      nombre: b.nombre,
      categoria: b.categoria,
      precio: b.precio,
      stock: b.stock,
      base: b.nombre.split(' ').first,
      marca: b.nombre.split(' ').last,
    ));
  }

  // Reparto uniforme de las categorías para los productos generados.
  final puestos = <_Puesto>[];
  var orden = 0;
  _cuotas.forEach((cat, k) {
    for (var i = 0; i < k; i++) {
      puestos.add(_Puesto((i + 0.5) / k, orden, cat));
    }
    orden++;
  });
  puestos.sort((a, b) {
    final c = a.pos.compareTo(b.pos);
    return c != 0 ? c : a.orden.compareTo(b.orden);
  });

  final contador = <String, int>{for (final c in _cuotas.keys) c: 0};
  var n = _nombrados.length;
  for (final puesto in puestos) {
    n++;
    final cat = puesto.categoria;
    final k = contador[cat]!;
    contador[cat] = k + 1;

    final bases = _bases[cat]!;
    final marcas = _marcas[cat]!;
    final pres = _presentaciones[cat]!;
    final base = bases[k % bases.length];
    final marca = marcas[(k ~/ bases.length) % marcas.length];
    final presTexto = pres[(k + n) % pres.length];
    final medida = presTexto.split(' · ').last;

    lista.add(_armar(
      n: n,
      id: 'P${n < 100 ? (n < 10 ? '00$n' : '0$n') : '$n'}',
      nombre: '$base $marca $medida',
      categoria: cat,
      precio: 1500 + ((n * 377) % 90) * 100,
      stock: 6 + (n * 7 + 3) % 14, // 6 a 19: siempre DISPONIBLE y por debajo de los 4 más altos
      base: base,
      marca: marca,
    ));
  }
  return lista;
}

// ---------------------------------------------------------------------------
// Utilidades de consulta
// ---------------------------------------------------------------------------

String _clave(String s) {
  const de = 'áéíóúüÁÉÍÓÚÜ';
  const a = 'aeiouuaeiouu';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? a[i] : ch.toLowerCase());
  }
  return b.toString();
}

int _comparaNombre(Map<String, dynamic> a, Map<String, dynamic> b) {
  final c = _clave(a['nombre'] as String).compareTo(_clave(b['nombre'] as String));
  return c != 0 ? c : (a['id'] as String).compareTo(b['id'] as String);
}

Map<String, dynamic> _itemLista(Map<String, dynamic> p) => {
      'id': p['id'],
      'nombre': p['nombre'],
      'categoria': p['categoria'],
      'precio': p['precio'],
      'stock': p['stock'],
      'stockMinimo': p['stockMinimo'],
      'estado': p['estado'],
    };

/// Resultado de una validación del servidor simulado (400).
class MockError implements Exception {
  MockError(this.codigo, this.mensaje);
  final int codigo;
  final String mensaje;
}

// ---------------------------------------------------------------------------
// Respuestas (cada función devuelve el envoltorio completo del contrato)
// ---------------------------------------------------------------------------

const List<String> ordenesValidos = ['nombre', 'stock_asc', 'stock_desc', 'precio_asc', 'precio_desc'];

/// GET /api/productos
Map<String, dynamic> listarProductosJson(Map<String, String> query) {
  final q = _clave((query['q'] ?? '').trim());
  final categoria = query['categoria'];
  final estado = query['estado'];
  final orden = query['orden'] ?? 'nombre';

  if (estado != null && estado.isNotEmpty && !const ['DISPONIBLE', 'CRITICO', 'AGOTADO'].contains(estado)) {
    throw MockError(400, 'El parámetro estado debe ser DISPONIBLE, CRITICO o AGOTADO');
  }
  if (!ordenesValidos.contains(orden)) {
    throw MockError(400, 'El parámetro orden debe ser nombre, stock_asc, stock_desc, precio_asc o precio_desc');
  }
  final pagina = int.tryParse(query['pagina'] ?? '0');
  final tamano = int.tryParse(query['tamano'] ?? '20');
  if (pagina == null || pagina < 0) throw MockError(400, 'El parámetro pagina debe ser un entero desde 0');
  if (tamano == null || tamano < 1 || tamano > 100) throw MockError(400, 'El parámetro tamano debe estar entre 1 y 100');

  final filtrados = catalogoJson().where((p) {
    if (categoria != null && categoria.isNotEmpty && p['categoria'] != categoria) return false;
    if (estado != null && estado.isNotEmpty && p['estado'] != estado) return false;
    if (q.isNotEmpty) {
      final texto = '${_clave(p['nombre'] as String)} ${_clave(p['codigo'] as String)}';
      if (!texto.contains(q)) return false;
    }
    return true;
  }).toList();

  filtrados.sort((a, b) {
    int c;
    switch (orden) {
      case 'stock_asc':
        c = (a['stock'] as int).compareTo(b['stock'] as int);
      case 'stock_desc':
        c = (b['stock'] as int).compareTo(a['stock'] as int);
      case 'precio_asc':
        c = (a['precio'] as int).compareTo(b['precio'] as int);
      case 'precio_desc':
        c = (b['precio'] as int).compareTo(a['precio'] as int);
      default:
        c = 0;
    }
    return c != 0 ? c : _comparaNombre(a, b);
  });

  final total = filtrados.length;
  final totalPaginas = total == 0 ? 0 : (total + tamano - 1) ~/ tamano;
  final desde = pagina * tamano;
  final pagItems = desde >= total ? <Map<String, dynamic>>[] : filtrados.sublist(desde, desde + tamano > total ? total : desde + tamano);

  return {
    'success': true,
    'data': pagItems.map(_itemLista).toList(),
    'paginacion': {
      'pagina': pagina,
      'tamano': tamano,
      'totalElementos': total,
      'totalPaginas': totalPaginas,
    },
  };
}

/// GET /api/productos/{id}
Map<String, dynamic> detalleProductoJson(String id) {
  for (final p in catalogoJson()) {
    if (p['id'] == id) {
      final hoy = DateTime.now();
      final ventas = p['_ventas'] as List<int>;
      final salida = Map<String, dynamic>.from(p)..remove('_ventas');
      salida['ventasUltimos7Dias'] = [
        for (var d = 0; d < 7; d++)
          {'fecha': _fechaIso(hoy.subtract(Duration(days: 6 - d))), 'unidades': ventas[d]},
      ];
      return {'success': true, 'data': salida};
    }
  }
  throw MockError(404, 'Producto no encontrado');
}

/// GET /api/productos/stock-critico
Map<String, dynamic> stockCriticoJson(Map<String, String> query) {
  final estado = query['estado'];
  if (estado != null && estado.isNotEmpty && !const ['CRITICO', 'AGOTADO'].contains(estado)) {
    throw MockError(400, 'El parámetro estado debe ser CRITICO o AGOTADO');
  }
  final limite = query['limite'] == null ? null : int.tryParse(query['limite']!);
  if (query['limite'] != null && (limite == null || limite < 1)) {
    throw MockError(400, 'El parámetro limite debe ser un entero mayor que 0');
  }

  final todos = catalogoJson().where((p) => p['estado'] != 'DISPONIBLE').toList();
  final criticos = todos.where((p) => p['estado'] == 'CRITICO').length;
  final agotados = todos.where((p) => p['estado'] == 'AGOTADO').length;

  var visibles = todos.where((p) => estado == null || estado.isEmpty || p['estado'] == estado).toList()
    ..sort((a, b) {
      final c = (a['stock'] as int).compareTo(b['stock'] as int);
      return c != 0 ? c : _comparaNombre(a, b);
    });
  if (limite != null && visibles.length > limite) visibles = visibles.sublist(0, limite);

  return {
    'success': true,
    'data': {
      'totalCritico': criticos,
      'totalAgotado': agotados,
      'productos': [
        for (final p in visibles)
          {
            'id': p['id'],
            'nombre': p['nombre'],
            'stock': p['stock'],
            'stockMinimo': p['stockMinimo'],
            'estado': p['estado'],
          },
      ],
    },
  };
}

/// GET /api/inventario/resumen
Map<String, dynamic> resumenJson() {
  final lista = catalogoJson();
  final critico = lista.where((p) => p['estado'] == 'CRITICO').length;
  final agotado = lista.where((p) => p['estado'] == 'AGOTADO').length;
  return {
    'success': true,
    'data': {
      'totalProductos': lista.length,
      'productosDisponibles': lista.length - critico - agotado,
      'stockCritico': critico,
      'sinStock': agotado,
      'valorInventario': 2486700,
      'variacionValorMensual': 12.0,
    },
  };
}

/// GET /api/inventario/estadisticas
Map<String, dynamic> estadisticasJson() {
  final lista = catalogoJson();
  final critico = lista.where((p) => p['estado'] == 'CRITICO').length;
  final agotado = lista.where((p) => p['estado'] == 'AGOTADO').length;

  final porCategoria = <String, int>{};
  for (final p in lista) {
    final c = p['categoria'] as String;
    porCategoria[c] = (porCategoria[c] ?? 0) + 1;
  }

  final masStock = [...lista]..sort((a, b) {
      final c = (b['stock'] as int).compareTo(a['stock'] as int);
      return c != 0 ? c : (a['id'] as String).compareTo(b['id'] as String);
    });

  const valores = [2310400, 2352900, 2298000, 2401500, 2425300, 2460100, 2486700];
  final hoy = DateTime.now();

  return {
    'success': true,
    'data': {
      'totalProductos': lista.length,
      'valorInventario': 2486700,
      'categorias': [
        for (final c in _ordenCategorias) {'nombre': c, 'cantidad': porCategoria[c] ?? 0},
      ],
      'nivelesStock': {
        'disponible': lista.length - critico - agotado,
        'critico': critico,
        'agotado': agotado,
      },
      'valorUltimosDias': [
        for (var d = 0; d < 7; d++) {'fecha': _fechaIso(hoy.subtract(Duration(days: 6 - d))), 'valor': valores[d]},
      ],
      'productosMasStock': [
        for (final p in masStock.take(4)) {'id': p['id'], 'nombre': p['nombre'], 'stock': p['stock']},
      ],
      'coberturaCategorias': [
        {'categoria': 'Granos', 'porcentaje': 82},
        {'categoria': 'Lácteos', 'porcentaje': 74},
        {'categoria': 'Galletas', 'porcentaje': 66},
        {'categoria': 'Aseo', 'porcentaje': 70},
        {'categoria': 'Aceites', 'porcentaje': 58},
        {'categoria': 'Bebidas', 'porcentaje': 90},
      ],
    },
  };
}

/// GET /api/perfil
Map<String, dynamic> perfilJson() => {
      'success': true,
      'data': {
        'id': 'U001',
        'nombre': 'Ana Martínez',
        'email': 'ana@mitienda.com',
        'rol': 'ADMIN',
        'tienda': {'id': 'T001', 'nombre': 'Mi tienda'},
      },
    };

const String mockToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbmFAbWl0aWVuZGEuY29tIn0.firma';

/// POST /api/auth/login. Acepta cualquier correo válido con contraseña, salvo
/// la contraseña reservada "incorrecta", que devuelve 401 para probar el error.
Map<String, dynamic> loginJson(Map<String, Object?> body) {
  final email = '${body['email'] ?? ''}'.trim();
  final password = '${body['password'] ?? ''}';
  if (!correoValido(email) || password.isEmpty || password == 'incorrecta') {
    throw MockError(401, 'Correo o contraseña incorrectos');
  }
  return {
    'success': true,
    'data': {'token': mockToken, 'tipo': 'Bearer', 'expiraEnSegundos': 3600},
  };
}

/// POST /api/auth/recuperar
Map<String, dynamic> recuperarJson(Map<String, Object?> body) {
  final email = '${body['email'] ?? ''}'.trim();
  if (!correoValido(email)) throw MockError(400, 'El correo no tiene un formato válido');
  return {
    'success': true,
    'message': mensajeRecuperar,
  };
}

/// Código de 6 dígitos que acepta el servidor simulado en /api/auth/restablecer.
const String codigoMock = '123456';

const String mensajeRecuperar =
    'Si el correo está registrado, recibirás un código de 6 dígitos para crear una nueva contraseña.';

/// POST /api/auth/restablecer
Map<String, dynamic> restablecerJson(Map<String, Object?> body) {
  final email = '${body['email'] ?? ''}'.trim();
  final codigo = '${body['codigo'] ?? ''}'.trim();
  final nueva = '${body['nuevaPassword'] ?? ''}';
  if (!correoValido(email)) throw MockError(400, 'El correo no tiene un formato válido');
  if (!esCodigoValido(codigo)) throw MockError(400, 'El código debe tener 6 dígitos');
  final fallo = errorPassword(nueva);
  if (fallo != null) throw MockError(400, fallo);
  if (codigo != codigoMock) throw MockError(400, 'El código no es válido o venció');
  return {'success': true, 'message': 'Tu contraseña fue actualizada. Ya puedes ingresar.'};
}

/// POST /api/perfil/password. Acepta cualquier contraseña actual salvo la
/// reservada "incorrecta", que devuelve 400 para probar el error.
Map<String, dynamic> cambiarPasswordJson(Map<String, Object?> body) {
  final actual = '${body['passwordActual'] ?? ''}';
  final nueva = '${body['nuevaPassword'] ?? ''}';
  if (actual.isEmpty) throw MockError(400, 'Escribe tu contraseña actual');
  if (actual == 'incorrecta') throw MockError(400, 'La contraseña actual no es correcta');
  final fallo = errorPassword(nueva);
  if (fallo != null) throw MockError(400, fallo);
  if (nueva == actual) throw MockError(400, 'La nueva contraseña debe ser diferente a la actual');
  return {'success': true, 'message': 'Tu contraseña fue actualizada.'};
}

/// POST /api/chat. Respuesta de ejemplo: el asistente real vive en el servidor.
Map<String, dynamic> chatJson(Map<String, Object?> body) {
  final mensaje = '${body['mensaje'] ?? ''}'.trim();
  if (mensaje.isEmpty) throw MockError(400, 'Escribe un mensaje para el asistente');
  if (mensaje.length > 500) throw MockError(400, 'El mensaje no puede superar los 500 caracteres');
  return {
    'success': true,
    'data': {
      'respuesta': 'Esta es una respuesta de ejemplo. Conecta la app a tu servidor para hablar con el asistente real.',
    },
  };
}

bool correoValido(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

// ---------------------------------------------------------------------------
// Predicción de precios contra el IPC (v1.2)
//
// El servidor simulado usa 5 productos del dataset de consumo masivo y una
// regresión lineal simple. La API real usa el modelo de Weka del servidor.
// ---------------------------------------------------------------------------

const Map<String, List<double>> _preciosEjemplo = {
  'Arroz Diana x 500g': [5339.21, 5789.8, 6338.65, 6766.55, 7268.69, 7962.89, 8275.53, 8939.42, 9641.73, 10417.77],
  'Detergente Ariel 1kg': [2105.67, 2311.86, 2384.27, 2529.14, 2667.86, 2764.98, 2867.11, 3076.23, 3376.15, 3639.28],
  'Gaseosa Postobón 1.5L': [4253.51, 4663.73, 4872.53, 5018.92, 5259.42, 5641.27, 5831.31, 6126.9, 6323.72, 6802.96],
  'Leche Colanta 1L': [5106.18, 5343.35, 5556.66, 5951.02, 6207.92, 6420.86, 6709.87, 7208.88, 7447.59, 7831.73],
  'Pan Bimbo Tajado': [3031.98, 3169.64, 3363.69, 3649.01, 3947.63, 4108.3, 4315.61, 4589.56, 4992.85, 5177.61],
};

const int _primerAnioEjemplo = 2015;

/// IPC anual (diciembre a diciembre) del DANE. Cartagena no tiene cifras confiables antes de 2020.
const Map<int, double> _ipcNacionalEjemplo = {
  2015: 6.77, 2016: 5.75, 2017: 4.09, 2018: 3.18, 2019: 3.80, 2020: 1.61,
  2021: 5.62, 2022: 13.12, 2023: 9.28, 2024: 5.20, 2025: 5.10,
};
const Map<int, double> _ipcCartagenaEjemplo = {
  2020: 0.35, 2021: 5.75, 2022: 14.33, 2023: 9.91, 2024: 4.57, 2025: 4.80,
};

double _r2(double v) => (v * 100).round() / 100;

double _variacion(double actual, double anterior) => anterior == 0 ? 0 : _r2((actual / anterior - 1) * 100);

String _veredictoApi(double variacion, double referencia) {
  final d = variacion - referencia;
  if (d > 1.0) return 'POR_ENCIMA';
  if (d < -1.0) return 'POR_DEBAJO';
  return 'EN_LINEA';
}

/// GET /api/prediccion/productos
Map<String, dynamic> prediccionProductosJson() {
  final nombres = _preciosEjemplo.keys.toList()..sort();
  return {
    'success': true,
    'data': [
      for (final n in nombres)
        {
          'nombre': n,
          'ultimoAnio': _primerAnioEjemplo + _preciosEjemplo[n]!.length - 1,
          'ultimoPrecio': _r2(_preciosEjemplo[n]!.last),
        },
    ],
  };
}

/// GET /api/prediccion/precios?producto=...&anios=3
Map<String, dynamic> prediccionPreciosJson(Map<String, String> query) {
  final buscado = (query['producto'] ?? '').trim();
  if (buscado.isEmpty) throw MockError(400, 'Indica el producto que quieres consultar');

  var anios = 3;
  final texto = (query['anios'] ?? '').trim();
  if (texto.isNotEmpty) {
    final n = int.tryParse(texto);
    if (n == null || n < 1 || n > 5) {
      throw MockError(400, 'El parámetro anios debe ser un número entre 1 y 5');
    }
    anios = n;
  }

  String? nombre;
  for (final k in _preciosEjemplo.keys) {
    if (k.toLowerCase() == buscado.toLowerCase()) nombre = k;
  }
  if (nombre == null) throw MockError(404, 'Producto no encontrado en el modelo de precios');

  final serie = _preciosEjemplo[nombre]!;
  final ultimoAnio = _primerAnioEjemplo + serie.length - 1;

  // Regresión lineal por mínimos cuadrados: precio = a + b · año.
  final n = serie.length;
  final xs = [for (var i = 0; i < n; i++) (_primerAnioEjemplo + i).toDouble()];
  final mediaX = xs.reduce((a, b) => a + b) / n;
  final mediaY = serie.reduce((a, b) => a + b) / n;
  var sxy = 0.0, sxx = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (xs[i] - mediaX) * (serie[i] - mediaY);
    sxx += (xs[i] - mediaX) * (xs[i] - mediaX);
  }
  final b = sxy / sxx;
  final a = mediaY - b * mediaX;

  final historico = <Map<String, dynamic>>[];
  for (var i = 0; i < n; i++) {
    final anio = _primerAnioEjemplo + i;
    historico.add({
      'anio': anio,
      'precio': _r2(serie[i]),
      'variacionPct': i == 0 ? null : _variacion(serie[i], serie[i - 1]),
      'ipcNacionalPct': _ipcNacionalEjemplo[anio],
      'ipcCartagenaPct': _ipcCartagenaEjemplo[anio],
    });
  }

  final ultimoNacional = _ipcNacionalEjemplo[_ipcNacionalEjemplo.keys.reduce((x, y) => x > y ? x : y)]!;
  final anioUltimoNacional = _ipcNacionalEjemplo.keys.reduce((x, y) => x > y ? x : y);
  final ultimoCartagena = _ipcCartagenaEjemplo[_ipcCartagenaEjemplo.keys.reduce((x, y) => x > y ? x : y)]!;

  final pronostico = <Map<String, dynamic>>[];
  var previo = serie.last;
  for (var i = 1; i <= anios; i++) {
    final anio = ultimoAnio + i;
    final valor = a + b * anio;
    final variacion = _variacion(valor, previo);
    final nacional = _ipcNacionalEjemplo[anio];
    final referencia = nacional == null;
    final cartagena = _ipcCartagenaEjemplo[anio] ?? ultimoCartagena;
    pronostico.add({
      'anio': anio,
      'precio': _r2(valor),
      'variacionPct': variacion,
      'ipcNacionalPct': nacional ?? ultimoNacional,
      'ipcCartagenaPct': cartagena,
      'ipcEsReferencia': referencia,
      'anioReferencia': referencia ? anioUltimoNacional : null,
      'veredicto': _veredictoApi(variacion, cartagena),
    });
    previo = valor;
  }

  final p = pronostico.first;
  final variacion = p['variacionPct'] as double;
  final cartagena = p['ipcCartagenaPct'] as double;
  final nacional = p['ipcNacionalPct'] as double;
  final veredicto = p['veredicto'] as String;
  final frase = veredicto == 'POR_ENCIMA'
      ? 'Sube más que la inflación.'
      : veredicto == 'POR_DEBAJO'
          ? (variacion < 0 ? 'Baja mientras los precios en general suben.' : 'Sube menos que la inflación.')
          : 'Va a la par de la inflación.';
  final signo = variacion >= 0 ? '+' : '';
  final mensaje = 'Para ${p['anio']} el modelo proyecta que $nombre cambie $signo${variacion.toStringAsFixed(1).replaceAll('.', ',')} % '
      'en el precio, frente a una inflación de ${cartagena.toStringAsFixed(1).replaceAll('.', ',')} % en Cartagena'
      '${p['ipcEsReferencia'] == true ? ' (último dato publicado)' : ''}. $frase';

  return {
    'success': true,
    'data': {
      'producto': nombre,
      'historico': historico,
      'pronostico': pronostico,
      'resumen': {
        'anio': p['anio'],
        'variacionPronosticoPct': variacion,
        'ipcNacionalPct': nacional,
        'ipcCartagenaPct': cartagena,
        'ipcEsReferencia': p['ipcEsReferencia'],
        'diferenciaNacionalPuntos': _r2(variacion - nacional),
        'diferenciaCartagenaPuntos': _r2(variacion - cartagena),
        'veredicto': veredicto,
        'mensaje': mensaje,
      },
      'fuentes': {
        'precios': 'Dataset de productos de consumo masivo (Kaggle), precios por año',
        'inflacion': 'DANE · IPC, variación anual de diciembre a diciembre',
      },
    },
  };
}

/// GET /api/prediccion/panorama
Map<String, dynamic> prediccionPanoramaJson() {
  final productos = <Map<String, dynamic>>[];
  late int anio;
  late double nacional;
  late double cartagena;
  late bool referencia;
  var porEncima = 0, enLinea = 0, porDebajo = 0;

  for (final nombre in _preciosEjemplo.keys) {
    final r = prediccionPreciosJson({'producto': nombre, 'anios': '1'})['data'] as Map<String, dynamic>;
    final p = (r['pronostico'] as List).first as Map<String, dynamic>;
    final res = r['resumen'] as Map<String, dynamic>;
    anio = p['anio'] as int;
    nacional = (p['ipcNacionalPct'] as num).toDouble();
    cartagena = (p['ipcCartagenaPct'] as num).toDouble();
    referencia = p['ipcEsReferencia'] == true;
    final veredicto = p['veredicto'] as String;
    if (veredicto == 'POR_ENCIMA') {
      porEncima++;
    } else if (veredicto == 'POR_DEBAJO') {
      porDebajo++;
    } else {
      enLinea++;
    }
    productos.add({
      'nombre': nombre,
      'ultimoPrecio': _r2(_preciosEjemplo[nombre]!.last),
      'precioPronosticado': p['precio'],
      'variacionPct': p['variacionPct'],
      'diferenciaPuntos': res['diferenciaCartagenaPuntos'],
      'veredicto': veredicto,
    });
  }
  productos.sort((a, b) => (b['diferenciaPuntos'] as num).compareTo(a['diferenciaPuntos'] as num));

  return {
    'success': true,
    'data': {
      'anio': anio,
      'ipcNacionalPct': nacional,
      'ipcCartagenaPct': cartagena,
      'ipcEsReferencia': referencia,
      'conteo': {'porEncima': porEncima, 'enLinea': enLinea, 'porDebajo': porDebajo},
      'productos': productos,
      'fuentes': {
        'precios': 'Dataset de productos de consumo masivo (Kaggle), precios por año',
        'inflacion': 'DANE · IPC, variación anual de diciembre a diciembre',
      },
    },
  };
}
