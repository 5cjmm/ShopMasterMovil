import '../core/format.dart';

// ---------------------------------------------------------------------------
// Lectura tolerante de JSON. Los campos opcionales del contrato pueden venir
// null o no venir: la app los trata como vacíos y muestra «—» u oculta el bloque.
// ---------------------------------------------------------------------------

Object? _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null) return v;
  }
  return null;
}

int _int(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) {
    return int.tryParse(v) ?? double.tryParse(v)?.round() ?? fallback;
  }
  return fallback;
}

double _dbl(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? fallback;
  return fallback;
}

double? _dblOrNull(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.'));
  return null;
}

String _str(Object? v, [String fallback = '']) => v == null ? fallback : v.toString();

List<dynamic> _list(Object? v) => v is List ? v : const <dynamic>[];

Map<String, dynamic> _map(Object? v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

const String _inicialesDia = 'LMMJVSD';

/// "2026-11-06" -> "V" (viernes). Vacío si la fecha no se puede leer.
String inicialDeFecha(String fecha) {
  final d = DateTime.tryParse(fecha);
  if (d == null) return '';
  return _inicialesDia[d.weekday - 1];
}

// ---------------------------------------------------------------------------
// Estado del stock (regla de negocio 2.1 del contrato)
// ---------------------------------------------------------------------------

/// stock = 0 -> AGOTADO («Sin stock»), 1 a 5 -> CRITICO («Stock bajo»),
/// mayor que 5 -> DISPONIBLE («Stock normal»).
enum EstadoStock { normal, bajo, sinStock }

extension EstadoStockX on EstadoStock {
  String get etiqueta {
    switch (this) {
      case EstadoStock.normal:
        return 'Stock normal';
      case EstadoStock.bajo:
        return 'Stock bajo';
      case EstadoStock.sinStock:
        return 'Sin stock';
    }
  }

  /// Valor que viaja en la API (parámetro `estado` y campo `estado`).
  String get codigoApi {
    switch (this) {
      case EstadoStock.normal:
        return 'DISPONIBLE';
      case EstadoStock.bajo:
        return 'CRITICO';
      case EstadoStock.sinStock:
        return 'AGOTADO';
    }
  }
}

const int kStockMinimo = 5;

EstadoStock estadoDesdeStock(int stock, [int minimo = kStockMinimo]) {
  if (stock <= 0) return EstadoStock.sinStock;
  if (stock <= minimo) return EstadoStock.bajo;
  return EstadoStock.normal;
}

EstadoStock _estadoDesdeApi(Object? valor, int stock, int minimo) {
  switch (_str(valor).toUpperCase()) {
    case 'AGOTADO':
      return EstadoStock.sinStock;
    case 'CRITICO':
      return EstadoStock.bajo;
    case 'DISPONIBLE':
      return EstadoStock.normal;
  }
  return estadoDesdeStock(stock, minimo);
}

/// min(100, redondeo(100 × stock ÷ (stockMinimo × 5))).
int nivelStockDesde(int stock, [int minimo = kStockMinimo]) {
  final tope = minimo * 5;
  if (tope <= 0) return 0;
  final v = (100 * stock / tope).round();
  return v > 100 ? 100 : (v < 0 ? 0 : v);
}

// ---------------------------------------------------------------------------
// Producto (lista, detalle y stock crítico comparten este modelo)
// ---------------------------------------------------------------------------

class VentaDia {
  const VentaDia(this.fecha, this.unidades);

  final String fecha;
  final int unidades;

  String get inicial => inicialDeFecha(fecha);
}

class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.stockMinimo,
    required this.estado,
    required this.nivelStock,
    this.categoria = '',
    this.precio = 0,
    this.codigo = '',
    this.codigoBarras = '',
    this.presentacion = '',
    this.proveedor = '',
    this.ubicacion = '',
    this.descripcion = '',
    this.ventas7Dias = const <VentaDia>[],
  });

  /// Cadena opaca (ObjectId en la API real, "P001" en el mock): no se interpreta.
  final String id;
  final String nombre;
  final int stock;
  final int stockMinimo;
  final EstadoStock estado;

  /// Porcentaje de 0 a 100.
  final int nivelStock;

  // La lista trae categoria y precio; el stock crítico no. El detalle trae todo.
  final String categoria;
  final int precio;
  final String codigo;
  final String codigoBarras;
  final String presentacion;
  final String proveedor;
  final String ubicacion;
  final String descripcion;
  final List<VentaDia> ventas7Dias;

  double get nivel => nivelStock / 100;

  String get unidadesTexto => formatUnidades(stock);

  factory Producto.fromJson(Map<String, dynamic> json) {
    final stock = _int(json['stock']);
    final minimo = _int(json['stockMinimo'], kStockMinimo);
    return Producto(
      id: _str(json['id']),
      nombre: _str(json['nombre']),
      categoria: _str(json['categoria']),
      precio: _int(json['precio']),
      stock: stock,
      stockMinimo: minimo,
      estado: _estadoDesdeApi(json['estado'], stock, minimo),
      nivelStock: json['nivelStock'] == null ? nivelStockDesde(stock, minimo) : _int(json['nivelStock']),
      codigo: _str(json['codigo']),
      codigoBarras: _str(json['codigoBarras']),
      presentacion: _str(json['presentacion']),
      proveedor: _str(json['proveedor']),
      ubicacion: _str(json['ubicacion']),
      descripcion: _str(json['descripcion']),
      ventas7Dias: _list(json['ventasUltimos7Dias']).map((e) {
        final m = _map(e);
        return VentaDia(_str(m['fecha']), _int(m['unidades']));
      }).toList(),
    );
  }
}

/// Una página de GET /api/productos.
class PaginaProductos {
  const PaginaProductos({
    required this.productos,
    required this.pagina,
    required this.tamano,
    required this.totalElementos,
    required this.totalPaginas,
  });

  final List<Producto> productos;
  final int pagina;
  final int tamano;
  final int totalElementos;
  final int totalPaginas;

  bool get hayMas => pagina + 1 < totalPaginas;

  factory PaginaProductos.fromJson(Map<String, dynamic> envelope) {
    final pag = _map(envelope['paginacion']);
    final productos = _list(envelope['data'])
        .whereType<Map>()
        .map((e) => Producto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return PaginaProductos(
      productos: productos,
      pagina: _int(pag['pagina']),
      tamano: _int(pag['tamano'], productos.length),
      totalElementos: _int(pag['totalElementos'], productos.length),
      totalPaginas: _int(pag['totalPaginas'], 1),
    );
  }
}

/// GET /api/productos/stock-critico
class StockCritico {
  const StockCritico({required this.totalCritico, required this.totalAgotado, required this.productos});

  final int totalCritico;
  final int totalAgotado;
  final List<Producto> productos;

  factory StockCritico.fromJson(Map<String, dynamic> data) {
    return StockCritico(
      totalCritico: _int(data['totalCritico']),
      totalAgotado: _int(data['totalAgotado']),
      productos: _list(data['productos'])
          .whereType<Map>()
          .map((e) => Producto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Acceso y perfil
// ---------------------------------------------------------------------------

class SesionApi {
  const SesionApi({required this.token, required this.expiraEnSegundos});

  final String token;
  final int expiraEnSegundos;

  factory SesionApi.fromJson(Map<String, dynamic> data) {
    return SesionApi(
      token: _str(data['token']),
      expiraEnSegundos: _int(data['expiraEnSegundos'], 3600),
    );
  }
}

class Perfil {
  const Perfil({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.tiendaNombre,
  });

  final String id;
  final String nombre;
  final String email;

  /// ADMIN o TENDERO.
  final String rol;
  final String tiendaNombre;

  String get primerNombre {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes.isEmpty || partes.first.isEmpty ? '' : partes.first;
  }

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes[1][0]).toUpperCase();
  }

  /// La app muestra ADMIN como «Administradora» y TENDERO como «Tendero».
  String get rolTexto {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return 'Administradora';
      case 'TENDERO':
        return 'Tendero';
    }
    return rol;
  }

  String get rolYTienda => tiendaNombre.isEmpty ? rolTexto : '$rolTexto · $tiendaNombre';

  factory Perfil.fromJson(Map<String, dynamic> data) {
    final tienda = _map(data['tienda']);
    return Perfil(
      id: _str(data['id']),
      nombre: _str(data['nombre']),
      email: _str(data['email']),
      rol: _str(data['rol']),
      tiendaNombre: _str(tienda['nombre']),
    );
  }
}

// ---------------------------------------------------------------------------
// Resumen (GET /api/inventario/resumen)
// ---------------------------------------------------------------------------

class ResumenInventario {
  const ResumenInventario({
    required this.totalProductos,
    required this.disponibles,
    required this.stockCritico,
    required this.sinStock,
    required this.valorInventario,
    this.variacionMensual,
  });

  final int totalProductos;
  final int disponibles;
  final int stockCritico;
  final int sinStock;
  final int valorInventario;

  /// Opcional: porcentaje frente al mes anterior; null = sin historial (se oculta la flecha).
  final double? variacionMensual;

  factory ResumenInventario.fromJson(Map<String, dynamic> data) {
    return ResumenInventario(
      totalProductos: _int(data['totalProductos']),
      disponibles: _int(data['productosDisponibles']),
      stockCritico: _int(data['stockCritico']),
      sinStock: _int(data['sinStock']),
      valorInventario: _int(data['valorInventario']),
      variacionMensual: _dblOrNull(data['variacionValorMensual']),
    );
  }
}

// ---------------------------------------------------------------------------
// Estadísticas (GET /api/inventario/estadisticas)
// ---------------------------------------------------------------------------

class ProductoStock {
  const ProductoStock(this.id, this.nombre, this.unidades);
  final String id;
  final String nombre;
  final int unidades;
}

class CategoriaValor {
  const CategoriaValor(this.categoria, this.valor);
  final String categoria;
  final double valor;
}

class PuntoValor {
  const PuntoValor(this.fecha, this.valor);
  final String fecha;
  final double valor;

  String get inicial => inicialDeFecha(fecha);
}

class Estadisticas {
  const Estadisticas({
    required this.totalProductos,
    required this.valorInventario,
    required this.categorias,
    required this.disponible,
    required this.critico,
    required this.agotado,
    required this.valorUltimosDias,
    required this.masStock,
    required this.cobertura,
  });

  final int totalProductos;
  final int valorInventario;

  /// Nombre y cantidad por categoría (también llena los chips del filtro).
  final List<CategoriaValor> categorias;
  final int disponible;
  final int critico;
  final int agotado;

  /// Opcional: vacío si el servidor no guarda historial (se oculta el gráfico).
  final List<PuntoValor> valorUltimosDias;
  final List<ProductoStock> masStock;

  /// Promedio de nivelStock por categoría (0 a 100) para el radar.
  final List<CategoriaValor> cobertura;

  int get total => disponible + critico + agotado;

  CategoriaValor? get menorCobertura {
    if (cobertura.isEmpty) return null;
    var menor = cobertura.first;
    for (final c in cobertura) {
      if (c.valor < menor.valor) menor = c;
    }
    return menor;
  }

  CategoriaValor? get categoriaMayor {
    if (categorias.isEmpty) return null;
    var mayor = categorias.first;
    for (final c in categorias) {
      if (c.valor > mayor.valor) mayor = c;
    }
    return mayor;
  }

  factory Estadisticas.fromJson(Map<String, dynamic> data) {
    final niveles = _map(data['nivelesStock']);
    return Estadisticas(
      totalProductos: _int(data['totalProductos']),
      valorInventario: _int(data['valorInventario']),
      categorias: _list(data['categorias']).map((e) {
        final m = _map(e);
        return CategoriaValor(_str(m['nombre']), _dbl(m['cantidad']));
      }).toList(),
      disponible: _int(niveles['disponible']),
      critico: _int(niveles['critico']),
      agotado: _int(niveles['agotado']),
      valorUltimosDias: _list(data['valorUltimosDias']).map((e) {
        final m = _map(e);
        return PuntoValor(_str(m['fecha']), _dbl(m['valor']));
      }).toList(),
      masStock: _list(data['productosMasStock']).map((e) {
        final m = _map(e);
        return ProductoStock(_str(m['id']), _str(m['nombre']), _int(m['stock']));
      }).toList(),
      cobertura: _list(data['coberturaCategorias']).map((e) {
        final m = _map(e);
        return CategoriaValor(_str(m['categoria']), _dbl(m['porcentaje']));
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Avisos recientes del perfil: salen de stock-critico; el estado leído / no
// leído se guarda solo en el dispositivo.
// ---------------------------------------------------------------------------

class Aviso {
  Aviso({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.agotado,
    this.leida = false,
  });

  final String id;
  final String titulo;
  final String detalle;
  final bool agotado;
  bool leida;

  factory Aviso.desdeProducto(Producto p, {required bool leida}) {
    final agotado = p.estado == EstadoStock.sinStock;
    return Aviso(
      id: p.id,
      titulo: agotado ? '${p.nombre}: sin stock' : '${p.nombre}: stock bajo',
      detalle: agotado
          ? 'Producto agotado. Repón tu inventario.'
          : 'Quedan ${formatUnidades(p.stock)}. Revisa tu próximo pedido.',
      agotado: agotado,
      leida: leida,
    );
  }
}

// ---------------------------------------------------------------------------
// Predicción de precios contra la inflación del DANE (v1.2)
// ---------------------------------------------------------------------------

bool _bool(Object? v) => v is bool ? v : v?.toString().toLowerCase() == 'true';

/// Cómo se compara el pronóstico del precio con la inflación de referencia.
enum VeredictoPrecio { porEncima, enLinea, porDebajo }

VeredictoPrecio veredictoDesdeApi(Object? v) {
  switch (v) {
    case 'POR_ENCIMA':
      return VeredictoPrecio.porEncima;
    case 'POR_DEBAJO':
      return VeredictoPrecio.porDebajo;
    default:
      return VeredictoPrecio.enLinea;
  }
}

class ProductoPrecio {
  const ProductoPrecio({required this.nombre, required this.ultimoAnio, required this.ultimoPrecio});

  final String nombre;
  final int ultimoAnio;
  final double ultimoPrecio;

  factory ProductoPrecio.fromJson(Map<String, dynamic> json) {
    return ProductoPrecio(
      nombre: _str(json['nombre']),
      ultimoAnio: _int(json['ultimoAnio']),
      ultimoPrecio: _dbl(json['ultimoPrecio']),
    );
  }
}

/// Un año de la serie: precio, cuánto cambió frente al año anterior y la inflación de ese año.
/// Los porcentajes son null cuando no hay dato (por ejemplo, Cartagena antes de 2020).
class PuntoPrecio {
  const PuntoPrecio({
    required this.anio,
    required this.precio,
    this.variacionPct,
    this.ipcNacionalPct,
    this.ipcCartagenaPct,
    this.ipcEsReferencia = false,
    this.anioReferencia,
    this.veredicto,
  });

  final int anio;
  final double precio;
  final double? variacionPct;
  final double? ipcNacionalPct;
  final double? ipcCartagenaPct;

  /// true cuando ese año aún no tiene inflación anual publicada y se usa el último dato.
  final bool ipcEsReferencia;
  final int? anioReferencia;
  final VeredictoPrecio? veredicto;

  factory PuntoPrecio.fromJson(Map<String, dynamic> json) {
    return PuntoPrecio(
      anio: _int(json['anio']),
      precio: _dbl(json['precio']),
      variacionPct: _dblOrNull(json['variacionPct']),
      ipcNacionalPct: _dblOrNull(json['ipcNacionalPct']),
      ipcCartagenaPct: _dblOrNull(json['ipcCartagenaPct']),
      ipcEsReferencia: _bool(json['ipcEsReferencia']),
      anioReferencia: json['anioReferencia'] == null ? null : _int(json['anioReferencia']),
      veredicto: json['veredicto'] == null ? null : veredictoDesdeApi(json['veredicto']),
    );
  }
}

class ResumenPrediccion {
  const ResumenPrediccion({
    required this.anio,
    required this.variacionPronosticoPct,
    required this.veredicto,
    required this.mensaje,
    this.ipcNacionalPct,
    this.ipcCartagenaPct,
    this.ipcEsReferencia = false,
    this.diferenciaNacionalPuntos,
    this.diferenciaCartagenaPuntos,
  });

  final int anio;
  final double variacionPronosticoPct;
  final double? ipcNacionalPct;
  final double? ipcCartagenaPct;
  final bool ipcEsReferencia;
  final double? diferenciaNacionalPuntos;
  final double? diferenciaCartagenaPuntos;
  final VeredictoPrecio veredicto;
  final String mensaje;

  factory ResumenPrediccion.fromJson(Map<String, dynamic> json) {
    return ResumenPrediccion(
      anio: _int(json['anio']),
      variacionPronosticoPct: _dbl(json['variacionPronosticoPct']),
      ipcNacionalPct: _dblOrNull(json['ipcNacionalPct']),
      ipcCartagenaPct: _dblOrNull(json['ipcCartagenaPct']),
      ipcEsReferencia: _bool(json['ipcEsReferencia']),
      diferenciaNacionalPuntos: _dblOrNull(json['diferenciaNacionalPuntos']),
      diferenciaCartagenaPuntos: _dblOrNull(json['diferenciaCartagenaPuntos']),
      veredicto: veredictoDesdeApi(json['veredicto']),
      mensaje: _str(json['mensaje']),
    );
  }
}

class PrediccionPrecios {
  const PrediccionPrecios({
    required this.producto,
    required this.historico,
    required this.pronostico,
    required this.resumen,
    this.fuentePrecios = '',
    this.fuenteInflacion = '',
  });

  final String producto;
  final List<PuntoPrecio> historico;
  final List<PuntoPrecio> pronostico;
  final ResumenPrediccion resumen;
  final String fuentePrecios;
  final String fuenteInflacion;

  factory PrediccionPrecios.fromJson(Map<String, dynamic> data) {
    final fuentes = _map(data['fuentes']);
    return PrediccionPrecios(
      producto: _str(data['producto']),
      historico: _list(data['historico']).map((e) => PuntoPrecio.fromJson(_map(e))).toList(),
      pronostico: _list(data['pronostico']).map((e) => PuntoPrecio.fromJson(_map(e))).toList(),
      resumen: ResumenPrediccion.fromJson(_map(data['resumen'])),
      fuentePrecios: _str(fuentes['precios']),
      fuenteInflacion: _str(fuentes['inflacion']),
    );
  }
}

/// Un producto en el panorama: su pronóstico del próximo año frente a la inflación.
class PanoramaProducto {
  const PanoramaProducto({
    required this.nombre,
    required this.ultimoPrecio,
    required this.precioPronosticado,
    required this.variacionPct,
    required this.diferenciaPuntos,
    required this.veredicto,
  });

  final String nombre;
  final double ultimoPrecio;
  final double precioPronosticado;
  final double variacionPct;

  /// Pronóstico menos inflación de referencia, en puntos porcentuales.
  final double diferenciaPuntos;
  final VeredictoPrecio veredicto;

  factory PanoramaProducto.fromJson(Map<String, dynamic> json) {
    return PanoramaProducto(
      nombre: _str(json['nombre']),
      ultimoPrecio: _dbl(json['ultimoPrecio']),
      precioPronosticado: _dbl(json['precioPronosticado']),
      variacionPct: _dbl(json['variacionPct']),
      diferenciaPuntos: _dbl(json['diferenciaPuntos']),
      veredicto: veredictoDesdeApi(json['veredicto']),
    );
  }
}

/// GET /api/prediccion/panorama: todos los productos frente al IPC (para los gráficos comparativos).
class PanoramaPrediccion {
  const PanoramaPrediccion({
    required this.anio,
    required this.productos,
    this.ipcNacionalPct,
    this.ipcCartagenaPct,
    this.ipcEsReferencia = false,
    this.porEncima = 0,
    this.enLinea = 0,
    this.porDebajo = 0,
    this.fuentePrecios = '',
    this.fuenteInflacion = '',
  });

  final int anio;
  final double? ipcNacionalPct;
  final double? ipcCartagenaPct;
  final bool ipcEsReferencia;
  final int porEncima;
  final int enLinea;
  final int porDebajo;
  final List<PanoramaProducto> productos;
  final String fuentePrecios;
  final String fuenteInflacion;

  /// Inflación contra la que se compara: Cartagena si existe, si no la nacional.
  double? get ipcBasePct => ipcCartagenaPct ?? ipcNacionalPct;

  factory PanoramaPrediccion.fromJson(Map<String, dynamic> data) {
    final conteo = _map(data['conteo']);
    final fuentes = _map(data['fuentes']);
    return PanoramaPrediccion(
      anio: _int(data['anio']),
      ipcNacionalPct: _dblOrNull(data['ipcNacionalPct']),
      ipcCartagenaPct: _dblOrNull(data['ipcCartagenaPct']),
      ipcEsReferencia: _bool(data['ipcEsReferencia']),
      porEncima: _int(conteo['porEncima']),
      enLinea: _int(conteo['enLinea']),
      porDebajo: _int(conteo['porDebajo']),
      productos: _list(data['productos']).map((e) => PanoramaProducto.fromJson(_map(e))).toList(),
      fuentePrecios: _str(fuentes['precios']),
      fuenteInflacion: _str(fuentes['inflacion']),
    );
  }
}
