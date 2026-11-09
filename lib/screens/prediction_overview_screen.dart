import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/nav.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/charts.dart' show DonutChart, DonutSegment, LegendDot, TreemapView;
import '../widgets/common.dart';
import '../widgets/prediction_charts.dart';

String _pct(double v, {bool signo = false}) {
  final texto = '${formatDecimal(v)} %';
  return signo && v > 0 ? '+$texto' : texto;
}

/// Panorama de predicción: todos los productos frente a la inflación del DANE, con
/// gráficos comparativos (radar, mapa de bloques, ranking y reparto de veredictos).
/// GET /api/prediccion/panorama.
class PredictionOverviewScreen extends StatefulWidget {
  const PredictionOverviewScreen({super.key});

  @override
  State<PredictionOverviewScreen> createState() => _PredictionOverviewScreenState();
}

class _PredictionOverviewScreenState extends State<PredictionOverviewScreen> {
  late Future<PanoramaPrediccion> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = InventarioRepository.instance.prediccionPanorama();
  }

  void _reintentar() {
    InventarioRepository.instance.invalidar();
    setState(() => _futuro = InventarioRepository.instance.prediccionPanorama());
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Panorama de predicción',
      onBack: () => Nav.volver(context),
      child: AsyncView<PanoramaPrediccion>(
        future: _futuro,
        onRetry: _reintentar,
        builder: (context, datos) => _Contenido(datos: datos),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.datos});

  final PanoramaPrediccion datos;

  @override
  Widget build(BuildContext context) {
    final ipc = datos.ipcBasePct;
    final extremos = seleccionarExtremos(datos.productos);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Pronóstico de ${datos.anio} de cada producto frente a la inflación del DANE'
          '${ipc == null ? '' : ' (${_pct(ipc)}${datos.ipcCartagenaPct != null ? ' en Cartagena' : ' nacional'})'}.',
          style: appText(13, color: AppColors.textSecondary, height: 1.4),
        ),
        if (datos.ipcEsReferencia) ...[
          const SizedBox(height: 4),
          Text('Esa inflación es el último dato publicado.', style: appText(11, color: AppColors.textMuted)),
        ],
        const SizedBox(height: 16),
        if (datos.productos.isEmpty)
          AppCard(
            child: Text('Todavía no hay productos con pronóstico.', style: appText(14, color: AppColors.textSecondary)),
          )
        else ...[
          const SectionTitle('¿Cuántos suben más que el IPC?'),
          const SizedBox(height: 10),
          _Reparto(datos: datos),
          const SizedBox(height: 18),
          if (ipc != null) ...[
            const SectionTitle('Radar: pronóstico vs inflación'),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
              child: Column(
                children: [
                  RadarPrediccion(productos: extremos, ipcPct: ipc),
                  const SizedBox(height: 6),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 6,
                    children: [
                      LegendDot(color: AppColors.warning, label: 'Aumento pronosticado (%)'),
                      LegendDot(color: AppColors.donutNormal, label: 'Inflación (%)'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Donde el naranja se sale del verde, el producto sube más que la inflación.',
                    style: appText(11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          const SectionTitle('Mapa de precios por veredicto'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TreemapView(
                  height: 230,
                  items: [for (final p in datos.productos) CategoriaValor(p.nombre, p.precioPronosticado)],
                  colors: [for (final p in datos.productos) colorVeredicto(p.veredicto)],
                  formatoValor: (v) => formatCop(v),
                ),
                const SizedBox(height: 10),
                Text(
                  'El tamaño es el precio pronosticado; el color indica si sube más, igual o menos que la inflación.',
                  style: appText(11, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Ranking: diferencia con el IPC'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 12, 12),
            child: Column(
              children: [
                BarrasDiferencia(productos: extremos),
                const SizedBox(height: 6),
                Text(
                  'Puntos porcentuales entre el aumento pronosticado y la inflación.',
                  style: appText(11, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Detalle'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < datos.productos.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.divider),
                  _FilaProducto(producto: datos.productos[i]),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'El pronóstico es una estimación estadística hecha con precios de años anteriores; no garantiza el precio futuro.',
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

class _Reparto extends StatelessWidget {
  const _Reparto({required this.datos});

  final PanoramaPrediccion datos;

  @override
  Widget build(BuildContext context) {
    final total = datos.porEncima + datos.enLinea + datos.porDebajo;
    return AppCard(
      child: Row(
        children: [
          DonutChart(
            size: 110,
            stroke: 16,
            segments: [
              DonutSegment(datos.porEncima.toDouble(), colorVeredicto(VeredictoPrecio.porEncima)),
              DonutSegment(datos.enLinea.toDouble(), colorVeredicto(VeredictoPrecio.enLinea)),
              DonutSegment(datos.porDebajo.toDouble(), colorVeredicto(VeredictoPrecio.porDebajo)),
            ],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$total', style: appText(22, weight: w7)),
                Text('productos', style: appText(10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LegendDot(
                    color: colorVeredicto(VeredictoPrecio.porEncima), label: 'Suben más', value: '${datos.porEncima}'),
                const SizedBox(height: 8),
                LegendDot(color: colorVeredicto(VeredictoPrecio.enLinea), label: 'A la par', value: '${datos.enLinea}'),
                const SizedBox(height: 8),
                LegendDot(
                    color: colorVeredicto(VeredictoPrecio.porDebajo), label: 'Suben menos', value: '${datos.porDebajo}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({required this.producto});

  final PanoramaProducto producto;

  @override
  Widget build(BuildContext context) {
    final color = colorVeredicto(producto.veredicto);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(width: 8, height: 34, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.nombre, style: appText(14, weight: w6), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${formatCop(producto.ultimoPrecio)} → ${formatCop(producto.precioPronosticado)}',
                  style: appText(12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_pct(producto.variacionPct, signo: true), style: appText(14, weight: w7, color: color)),
              const SizedBox(height: 2),
              Text(
                '${_pct(producto.diferenciaPuntos, signo: true).replaceAll(' %', '')} pts',
                style: appText(11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
