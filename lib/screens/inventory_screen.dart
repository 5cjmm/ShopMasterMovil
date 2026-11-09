import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';

enum Orden { menorStock, mayorStock, nombre, precioMenor, precioMayor }

extension OrdenX on Orden {
  String get etiqueta {
    switch (this) {
      case Orden.menorStock:
        return 'Menor stock primero';
      case Orden.mayorStock:
        return 'Mayor stock primero';
      case Orden.nombre:
        return 'Nombre (A–Z)';
      case Orden.precioMenor:
        return 'Precio: menor a mayor';
      case Orden.precioMayor:
        return 'Precio: mayor a menor';
    }
  }

  /// Valor del parámetro `orden` de GET /api/productos.
  String get codigoApi {
    switch (this) {
      case Orden.menorStock:
        return 'stock_asc';
      case Orden.mayorStock:
        return 'stock_desc';
      case Orden.nombre:
        return 'nombre';
      case Orden.precioMenor:
        return 'precio_asc';
      case Orden.precioMayor:
        return 'precio_desc';
    }
  }
}

/// Categorías de respaldo si GET /api/inventario/estadisticas no responde.
const List<String> kCategoriasRespaldo = ['Granos', 'Lácteos', 'Galletas', 'Aseo', 'Aceites', 'Bebidas'];

/// Filtros activos de la lista de inventario.
class FiltrosInventario {
  const FiltrosInventario({this.categoria, this.estado, this.orden = Orden.menorStock});

  final String? categoria;
  final EstadoStock? estado;
  final Orden orden;

  /// Cantidad de filtros distintos a los de fábrica (para la insignia).
  int get activos => (categoria != null ? 1 : 0) + (estado != null ? 1 : 0) + (orden != Orden.menorStock ? 1 : 0);
}

const int _tamanoPagina = 20;

/// 07 · Inventario, 08 · Filtros, 09 · Sin resultados.
///
/// La búsqueda, los filtros, el orden y la paginación los aplica el servidor
/// (GET /api/productos?q=&categoria=&estado=&orden=&pagina=&tamano=). Los
/// contadores de los chips salen de GET /api/inventario/resumen y las
/// categorías de GET /api/inventario/estadisticas.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.estadoInicial});

  final EstadoStock? estadoInicial;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repo = InventarioRepository.instance;
  final _busqueda = TextEditingController();
  final _scroll = ScrollController();

  late FiltrosInventario _filtros;
  String _consulta = '';

  // Última combinación que el servidor aceptó (para conservarla si responde 400).
  late FiltrosInventario _filtrosOk;
  String _consultaOk = '';

  List<Producto> _items = <Producto>[];
  int _pagina = 0;
  int _total = 0;
  bool _hayMas = false;

  bool _cargando = true;
  bool _cargandoMas = false;
  String? _error;

  ResumenInventario? _resumen;
  List<String> _categorias = kCategoriasRespaldo;

  Timer? _debounce;
  int _peticion = 0;

  @override
  void initState() {
    super.initState();
    _filtros = FiltrosInventario(estado: widget.estadoInicial);
    _filtrosOk = _filtros;
    _scroll.addListener(_alDesplazar);
    _cargarLista();
    _repo.resumen().then<void>((r) {
      if (mounted) setState(() => _resumen = r);
    }).catchError((Object _) {});
    _repo.estadisticas().then<void>((e) {
      final nombres = e.categorias.map((c) => c.categoria).where((n) => n.isNotEmpty).toList();
      if (mounted && nombres.isNotEmpty) setState(() => _categorias = nombres);
    }).catchError((Object _) {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) _cargarMas();
  }

  /// Carga la página 0 con los filtros actuales.
  Future<void> _cargarLista() async {
    final id = ++_peticion;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pag = await _repo.productos(
        q: _consulta,
        categoria: _filtros.categoria,
        estado: _filtros.estado,
        orden: _filtros.orden.codigoApi,
        pagina: 0,
        tamano: _tamanoPagina,
      );
      if (!mounted || id != _peticion) return;
      setState(() {
        _items = List<Producto>.of(pag.productos);
        _pagina = pag.pagina;
        _total = pag.totalElementos;
        _hayMas = pag.hayMas;
        _cargando = false;
        _filtrosOk = _filtros;
        _consultaOk = _consulta;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _peticion) return;
      if (e.statusCode == 400) {
        // 400: muestra el mensaje y conserva los filtros anteriores.
        setState(() {
          _filtros = _filtrosOk;
          _consulta = _consultaOk;
          _busqueda.text = _consultaOk;
          _cargando = false;
        });
        showInfo(context, e.message);
        return;
      }
      setState(() {
        _cargando = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted || id != _peticion) return;
      setState(() {
        _cargando = false;
        _error = 'No pudimos leer la respuesta del servidor.';
      });
    }
  }

  Future<void> _cargarMas() async {
    if (_cargando || _cargandoMas || !_hayMas || _error != null) return;
    final id = _peticion;
    setState(() => _cargandoMas = true);
    try {
      final pag = await _repo.productos(
        q: _consultaOk,
        categoria: _filtrosOk.categoria,
        estado: _filtrosOk.estado,
        orden: _filtrosOk.orden.codigoApi,
        pagina: _pagina + 1,
        tamano: _tamanoPagina,
      );
      if (!mounted || id != _peticion) return;
      final conocidos = _items.map((p) => p.id).toSet();
      final nuevos = pag.productos.where((p) => !conocidos.contains(p.id)).toList();
      setState(() {
        _items = [..._items, ...nuevos];
        _pagina = pag.pagina;
        // Si el servidor repite la página (p. ej. el Mock Server de Postman, que
        // ignora la paginación) no hay nada más que cargar.
        _hayMas = pag.hayMas && nuevos.isNotEmpty;
        _cargandoMas = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _peticion) return;
      setState(() {
        _cargandoMas = false;
        _hayMas = false;
      });
      showInfo(context, e.message);
    } catch (_) {
      if (!mounted || id != _peticion) return;
      setState(() {
        _cargandoMas = false;
        _hayMas = false;
      });
    }
  }

  void _alCambiarTexto(String valor) {
    _debounce?.cancel();
    setState(() => _consulta = valor);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _cargarLista();
    });
  }

  void _aplicarFiltros(FiltrosInventario nuevos) {
    setState(() => _filtros = nuevos);
    _cargarLista();
  }

  void _limpiarTodo() {
    _debounce?.cancel();
    _busqueda.clear();
    setState(() {
      _consulta = '';
      _filtros = const FiltrosInventario();
    });
    _cargarLista();
  }

  void _reintentar() {
    _repo.invalidar();
    _cargarLista();
  }

  Future<void> _refrescar() async {
    _repo.invalidar();
    await _cargarLista();
  }

  Future<void> _abrirFiltros() async {
    final resultado = await showModalBottomSheet<FiltrosInventario>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltrosSheet(categorias: _categorias, consulta: _consulta, inicial: _filtros),
    );
    if (resultado != null) _aplicarFiltros(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Inventario',
      navIndex: 1,
      trailing: HeaderIconButton(
        icon: Icons.tune_rounded,
        tooltip: 'Filtros',
        badge: _filtros.activos,
        onTap: _abrirFiltros,
      ),
      child: _cuerpo(),
    );
  }

  Widget _chips() {
    final r = _resumen;
    String conteo(String nombre, int? n) => n == null ? nombre : '$nombre ($n)';
    void elegir(EstadoStock? e) => _aplicarFiltros(
          FiltrosInventario(categoria: _filtros.categoria, estado: e, orden: _filtros.orden),
        );

    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          FilterPill(
            label: conteo('Todos', r?.totalProductos),
            selected: _filtros.estado == null,
            onTap: () => elegir(null),
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: conteo('Stock bajo', r?.stockCritico),
            selected: _filtros.estado == EstadoStock.bajo,
            onTap: () => elegir(EstadoStock.bajo),
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: conteo('Sin stock', r?.sinStock),
            selected: _filtros.estado == EstadoStock.sinStock,
            onTap: () => elegir(EstadoStock.sinStock),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: AppTextField(
            controller: _busqueda,
            hint: 'Buscar producto…',
            icon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onChanged: _alCambiarTexto,
            onSubmitted: (_) {
              _debounce?.cancel();
              _cargarLista();
            },
            suffix: _consulta.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () {
                      _debounce?.cancel();
                      _busqueda.clear();
                      setState(() => _consulta = '');
                      _cargarLista();
                    },
                  ),
          ),
        ),
        _chips(),
        Expanded(child: _lista()),
      ],
    );
  }

  Widget _lista() {
    if (_error != null) return ErrorState(message: _error!, onRetry: _reintentar);
    if (_cargando && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (!_cargando && _items.isEmpty) {
      return _SinResultados(consulta: _consulta, onLimpiar: _limpiarTodo);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refrescar,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: _items.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == _items.length) return _pie();
          return ProductTile(producto: _items[i], onTap: () => Nav.detalle(context, _items[i]));
        },
      ),
    );
  }

  Widget _pie() {
    if (_cargandoMas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          _total > 0 ? 'Mostrando ${_items.length} de $_total productos' : '',
          style: appText(12, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({required this.consulta, required this.onLimpiar});

  final String consulta;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final texto = consulta.trim().isEmpty
        ? 'No hay productos con estos filtros. Prueba con otros o límpialos.'
        : 'No hay coincidencias para “${consulta.trim()}”. Prueba otro nombre o revisa los filtros.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text('No encontramos productos', style: appText(18, weight: w7), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(texto, style: appText(14, color: AppColors.textSecondary, height: 1.45), textAlign: TextAlign.center),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Limpiar búsqueda y filtros', onPressed: onLimpiar),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 08 · Hoja de filtros
// ---------------------------------------------------------------------------

class _FiltrosSheet extends StatefulWidget {
  const _FiltrosSheet({required this.categorias, required this.consulta, required this.inicial});

  final List<String> categorias;
  final String consulta;
  final FiltrosInventario inicial;

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late String? _categoria = widget.inicial.categoria;
  late EstadoStock? _estado = widget.inicial.estado;
  late Orden _orden = widget.inicial.orden;

  int? _cantidad;
  int _peticion = 0;

  FiltrosInventario get _actual => FiltrosInventario(categoria: _categoria, estado: _estado, orden: _orden);

  @override
  void initState() {
    super.initState();
    _contar();
  }

  /// Pide al servidor cuántos productos darían estos filtros (totalElementos).
  Future<void> _contar() async {
    final id = ++_peticion;
    try {
      final pag = await InventarioRepository.instance.productos(
        q: widget.consulta,
        categoria: _categoria,
        estado: _estado,
        orden: _orden.codigoApi,
        pagina: 0,
        tamano: 1,
      );
      if (mounted && id == _peticion) setState(() => _cantidad = pag.totalElementos);
    } catch (_) {
      if (mounted && id == _peticion) setState(() => _cantidad = null);
    }
  }

  void _cambiar(VoidCallback cambio) {
    setState(() {
      cambio();
      _cantidad = null;
    });
    _contar();
  }

  @override
  Widget build(BuildContext context) {
    final n = _cantidad;
    final etiqueta = n == null ? 'Mostrar resultados' : (n == 1 ? 'Mostrar 1 producto' : 'Mostrar $n productos');

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Filtrar productos', style: appText(18, weight: w7))),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categoría', style: appText(14, weight: w6)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterPill(label: 'Todas', selected: _categoria == null, onTap: () => _cambiar(() => _categoria = null)),
                        for (final c in widget.categorias)
                          FilterPill(label: c, selected: _categoria == c, onTap: () => _cambiar(() => _categoria = c)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Estado del stock', style: appText(14, weight: w6)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterPill(label: 'Todos', selected: _estado == null, onTap: () => _cambiar(() => _estado = null)),
                        for (final e in EstadoStock.values)
                          FilterPill(label: e.etiqueta, selected: _estado == e, onTap: () => _cambiar(() => _estado = e)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Ordenar por', style: appText(14, weight: w6)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in Orden.values)
                          FilterPill(label: o.etiqueta, selected: _orden == o, onTap: () => _cambiar(() => _orden = o)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                children: [
                  PrimaryButton(label: etiqueta, onPressed: () => Navigator.of(context).pop(_actual)),
                  const SizedBox(height: 2),
                  LinkButton(
                    label: 'Limpiar filtros',
                    onTap: () => _cambiar(() {
                      _categoria = null;
                      _estado = null;
                      _orden = Orden.menorStock;
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
