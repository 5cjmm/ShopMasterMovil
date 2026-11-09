import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/nav.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/prediction_chart.dart';

/// Predicción de precios contra la inflación del DANE.
///
/// GET /api/prediccion/productos para elegir el producto y
/// GET /api/prediccion/precios para el historial, el pronóstico y la comparación.
/// La pregunta que responde es "¿se va a encarecer más que la inflación?".
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

String _pct(double v, {bool signo = false}) {
  final texto = '${formatDecimal(v)} %';
  return signo && v > 0 ? '+$texto' : texto;
}

class _PredictionScreenState extends State<PredictionScreen> {
  List<ProductoPrecio> _productos = const [];
  String? _error;
  bool _cargando = true;

  String? _seleccion;
  int _anios = 3;
  Future<PrediccionPrecios>? _prediccion;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _error = null;
      _cargando = true;
    });
    try {
      final lista = await InventarioRepository.instance.prediccionProductos();
      if (!mounted) return;
      setState(() {
        _productos = lista;
        _cargando = false;
        if (lista.isNotEmpty) {
          _seleccion ??= lista.first.nombre;
          _pedirPrediccion();
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.message;
      });
    }
  }

  void _pedirPrediccion() {
    final producto = _seleccion;
    if (producto == null) return;
    _prediccion = InventarioRepository.instance.prediccionPrecios(producto, anios: _anios);
  }

  void _reintentarPrediccion() {
    InventarioRepository.instance.invalidar();
    setState(_pedirPrediccion);
  }

  Future<void> _elegirProducto() async {
    final elegido = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Elige un producto', style: appText(17, weight: w7)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _productos.length,
                separatorBuilder: (context, i) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (ctx, i) {
                  final p = _productos[i];
                  final activo = p.nombre == _seleccion;
                  return ListTile(
                    onTap: () => Navigator.of(ctx).pop(p.nombre),
                    title: Text(p.nombre, style: appText(15, weight: activo ? w7 : w5)),
                    subtitle: Text(
                      '${formatCop(p.ultimoPrecio)} en ${p.ultimoAnio}',
                      style: appText(12, color: AppColors.textSecondary),
                    ),
                    trailing: activo ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (elegido != null && elegido != _seleccion && mounted) {
      setState(() {
        _seleccion = elegido;
        _pedirPrediccion();
      });
    }
  }

  void _cambiarAnios(int n) {
    if (n == _anios) return;
    setState(() {
      _anios = n;
      _pedirPrediccion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Predicción de precios',
      onBack: () => Nav.volver(context),
      child: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _cargarProductos);
    }
    if (_productos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Todavía no hay productos con historial de precios para predecir.',
            style: appText(14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Compara cuánto subiría el precio de un producto con la inflación oficial del DANE.',
          style: appText(13, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 14),
        AppCard(
          onTap: () => Nav.panoramaPrediccion(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: AppColors.accentSoft,
          child: Row(
            children: [
              const Icon(Icons.radar_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Comparar todos los productos: radar, mapa y ranking', style: appText(14, weight: w6)),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: _elegirProducto,
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Producto', style: appText(12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(_seleccion ?? '', style: appText(15, weight: w6), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Años a proyectar', style: appText(13, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            for (var n = 1; n <= 5; n++) ...[
              FilterPill(label: '$n', selected: _anios == n, onTap: () => _cambiarAnios(n)),
              const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<PrediccionPrecios>(
          future: _prediccion,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(snapshot.error.toString(), style: appText(13, color: AppColors.textSecondary)),
                    ),
                    LinkButton(label: 'Reintentar', onTap: _reintentarPrediccion),
                  ],
                ),
              );
            }
            final datos = snapshot.data;
            if (datos == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            return _Resultado(datos: datos);
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// Precio que tendría el producto si desde el último dato real solo subiera con la inflación
/// (Cartagena si hay, si no la nacional). Incluye el punto de partida para que la línea nazca ahí.
List<PuntoGrafica> _precioSiSubieraComoElIpc(PrediccionPrecios d) {
  if (d.historico.isEmpty || d.pronostico.isEmpty) return const [];
  final ultimo = d.historico.last;
  final puntos = [PuntoGrafica(ultimo.anio, ultimo.precio)];
  var precio = ultimo.precio;
  for (final p in d.pronostico) {
    final ipc = p.ipcCartagenaPct ?? p.ipcNacionalPct;
    if (ipc == null) break;
    precio = precio * (1 + ipc / 100);
    puntos.add(PuntoGrafica(p.anio, precio));
  }
  return puntos.length < 2 ? const [] : puntos;
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.datos});

  final PrediccionPrecios datos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VeredictoCard(resumen: datos.resumen),
        const SizedBox(height: 16),
        const SectionTitle('Precio por año'),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 12, 12),
          child: Column(
            children: [
              PredictionChart(
                historico: [for (final p in datos.historico) PuntoGrafica(p.anio, p.precio)],
                pronostico: [for (final p in datos.pronostico) PuntoGrafica(p.anio, p.precio)],
                referencia: _precioSiSubieraComoElIpc(datos),
              ),
              const SizedBox(height: 10),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 6,
                children: [
                  _Leyenda(color: AppColors.primary, texto: 'Histórico', punteada: false),
                  _Leyenda(color: AppColors.warning, texto: 'Pronóstico', punteada: true),
                  _Leyenda(color: PredictionChart.colorReferencia, texto: 'Si subiera como el IPC', punteada: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Pronóstico frente a la inflación'),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < datos.pronostico.length; i++) ...[
                if (i > 0) const Divider(height: 22, color: AppColors.divider),
                _ComparacionAnio(punto: datos.pronostico[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Historial'),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: _TablaHistorial(puntos: datos.historico),
        ),
        const SizedBox(height: 14),
        Text(
          'El pronóstico es una estimación estadística hecha con precios de años anteriores; no garantiza el precio futuro. '
          'En los años sin inflación publicada se usa como referencia el último dato disponible.',
          style: appText(11, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 6),
        if (datos.fuentePrecios.isNotEmpty)
          Text('Precios: ${datos.fuentePrecios}.', style: appText(11, color: AppColors.textMuted, height: 1.4)),
        if (datos.fuenteInflacion.isNotEmpty)
          Text('Inflación: ${datos.fuenteInflacion}.', style: appText(11, color: AppColors.textMuted, height: 1.4)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _VeredictoCard extends StatelessWidget {
  const _VeredictoCard({required this.resumen});

  final ResumenPrediccion resumen;

  @override
  Widget build(BuildContext context) {
    final String titulo;
    final IconData icono;
    final Color color;
    final Color fondo;
    switch (resumen.veredicto) {
      case VeredictoPrecio.porEncima:
        titulo = 'Sube más que la inflación';
        icono = Icons.trending_up_rounded;
        color = AppColors.danger;
        fondo = AppColors.dangerBg;
      case VeredictoPrecio.porDebajo:
        titulo = resumen.variacionPronosticoPct < 0 ? 'Baja de precio' : 'Sube menos que la inflación';
        icono = Icons.trending_down_rounded;
        color = AppColors.success;
        fondo = AppColors.successBg;
      case VeredictoPrecio.enLinea:
        titulo = 'Va a la par de la inflación';
        icono = Icons.trending_flat_rounded;
        color = AppColors.warning;
        fondo = AppColors.warningBg;
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
                child: Icon(icono, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Tan caro? · ${resumen.anio}', style: appText(12, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(titulo, style: appText(16, weight: w7, color: color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  etiqueta: 'Pronóstico',
                  valor: _pct(resumen.variacionPronosticoPct, signo: true),
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _Dato(
                  etiqueta: 'IPC nacional',
                  valor: resumen.ipcNacionalPct == null ? '—' : _pct(resumen.ipcNacionalPct!),
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _Dato(
                  etiqueta: 'IPC Cartagena',
                  valor: resumen.ipcCartagenaPct == null ? '—' : _pct(resumen.ipcCartagenaPct!),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (resumen.ipcEsReferencia) ...[
            const SizedBox(height: 6),
            Text(
              'La inflación de ${resumen.anio} aún no se publica: se muestra el último dato.',
              style: appText(11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          Text(resumen.mensaje, style: appText(13, color: AppColors.textSecondary, height: 1.45)),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, required this.color});

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: appText(11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(valor, style: appText(18, weight: w7, color: color)),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto, required this.punteada});

  final Color color;
  final String texto;
  final bool punteada;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 4,
          child: punteada
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [for (var i = 0; i < 3; i++) Container(width: 5, height: 3, color: color)],
                )
              : Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: appText(12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Un año del pronóstico: tres barras (producto, IPC nacional, IPC Cartagena).
class _ComparacionAnio extends StatelessWidget {
  const _ComparacionAnio({required this.punto});

  final PuntoPrecio punto;

  @override
  Widget build(BuildContext context) {
    final valores = <double>[
      (punto.variacionPct ?? 0).abs(),
      punto.ipcNacionalPct?.abs() ?? 0,
      punto.ipcCartagenaPct?.abs() ?? 0,
    ];
    var maximo = valores.reduce((a, b) => a > b ? a : b);
    if (maximo <= 0) maximo = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${punto.anio}', style: appText(14, weight: w7)),
            const SizedBox(width: 8),
            Text(formatCop(punto.precio), style: appText(13, color: AppColors.textSecondary)),
            if (punto.ipcEsReferencia) ...[
              const Spacer(),
              Text('IPC de referencia', style: appText(11, color: AppColors.textMuted)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _Barra(
          etiqueta: 'Pronóstico',
          texto: punto.variacionPct == null ? '—' : _pct(punto.variacionPct!, signo: true),
          fraccion: valores[0] / maximo,
          color: AppColors.warning,
        ),
        const SizedBox(height: 8),
        _Barra(
          etiqueta: 'IPC nacional',
          texto: punto.ipcNacionalPct == null ? '—' : _pct(punto.ipcNacionalPct!),
          fraccion: valores[1] / maximo,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        _Barra(
          etiqueta: 'IPC Cartagena',
          texto: punto.ipcCartagenaPct == null ? '—' : _pct(punto.ipcCartagenaPct!),
          fraccion: valores[2] / maximo,
          color: AppColors.scale4,
        ),
      ],
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.etiqueta, required this.texto, required this.fraccion, required this.color});

  final String etiqueta;
  final String texto;
  final double fraccion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 92, child: Text(etiqueta, style: appText(12, color: AppColors.textSecondary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 12,
              color: AppColors.track,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraccion.clamp(0.0, 1.0),
                child: Container(color: color),
              ),
            ),
          ),
        ),
        SizedBox(width: 56, child: Text(texto, style: appText(12, weight: w6), textAlign: TextAlign.right)),
      ],
    );
  }
}

class _TablaHistorial extends StatelessWidget {
  const _TablaHistorial({required this.puntos});

  final List<PuntoPrecio> puntos;

  @override
  Widget build(BuildContext context) {
    TextStyle cab() => appText(11, weight: w6, color: AppColors.textSecondary);

    Widget fila(List<Widget> celdas) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: celdas),
        );

    return Column(
      children: [
        fila([
          SizedBox(width: 44, child: Text('Año', style: cab())),
          Expanded(child: Text('Precio', style: cab())),
          SizedBox(width: 64, child: Text('Cambio', style: cab(), textAlign: TextAlign.right)),
          SizedBox(width: 64, child: Text('IPC nac.', style: cab(), textAlign: TextAlign.right)),
        ]),
        for (final p in puntos.reversed) ...[
          const Divider(height: 1, color: AppColors.divider),
          fila([
            SizedBox(width: 44, child: Text('${p.anio}', style: appText(13, weight: w6))),
            Expanded(child: Text(formatCop(p.precio), style: appText(13))),
            SizedBox(
              width: 64,
              child: Text(
                p.variacionPct == null ? '—' : _pct(p.variacionPct!, signo: true),
                style: appText(13, color: _colorCambio(p)),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 64,
              child: Text(
                p.ipcNacionalPct == null ? '—' : _pct(p.ipcNacionalPct!),
                style: appText(13, color: AppColors.textSecondary),
                textAlign: TextAlign.right,
              ),
            ),
          ]),
        ],
      ],
    );
  }

  /// El cambio sale en rojo cuando el producto subió más que la inflación nacional de ese año.
  Color _colorCambio(PuntoPrecio p) {
    final v = p.variacionPct;
    final ipc = p.ipcNacionalPct;
    if (v == null || ipc == null) return AppColors.navy;
    return v - ipc > 1.0 ? AppColors.danger : AppColors.navy;
  }
}
