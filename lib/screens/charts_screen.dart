import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/nav.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class _GraficosData {
  const _GraficosData(this.resumen, this.estadisticas);
  final ResumenInventario resumen;
  final Estadisticas estadisticas;
}

/// 13 · Gráficos y análisis (GET /api/inventario/estadisticas y /resumen).
///
/// Ventas y Compras están fuera del alcance de la v1.1 del contrato, así que
/// esas pestañas muestran un aviso; Inventario trae los gráficos.
class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final _repo = InventarioRepository.instance;
  late Future<_GraficosData> _futuro;
  int _tab = 1; // Inventario

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_GraficosData> _cargar() async {
    final resumen = _repo.resumen();
    final estadisticas = _repo.estadisticas();
    return _GraficosData(await resumen, await estadisticas);
  }

  void _reintentar() {
    _repo.invalidar();
    setState(() => _futuro = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Gráficos y análisis',
      navIndex: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                for (var i = 0; i < _nombres.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  FilterPill(label: _nombres[i], selected: _tab == i, onTap: () => setState(() => _tab = i)),
                ],
              ],
            ),
          ),
          Expanded(
            child: _tab != 1
                ? _Proximamente(nombre: _nombres[_tab])
                : AsyncView<_GraficosData>(
                    future: _futuro,
                    onRetry: _reintentar,
                    builder: (context, data) => _Inventario(data: data),
                  ),
          ),
        ],
      ),
    );
  }

  static const _nombres = ['Ventas', 'Inventario', 'Compras'];
}

class _Proximamente extends StatelessWidget {
  const _Proximamente({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text('$nombre: muy pronto', style: appText(17, weight: w7), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Esta versión móvil se centra en el seguimiento del inventario. Revisa la pestaña Inventario.',
              style: appText(13, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Inventario extends StatelessWidget {
  const _Inventario({required this.data});

  final _GraficosData data;

  @override
  Widget build(BuildContext context) {
    final r = data.resumen;
    final e = data.estadisticas;
    final variacion = r.variacionMensual; // opcional: null = sin historial
    final subeValor = (variacion ?? 0) >= 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _Kpi(titulo: 'Total productos', valor: '${r.totalProductos}', icono: Icons.inventory_2_outlined),
            _Kpi(titulo: 'Valor inventario', valor: formatCop(r.valorInventario), icono: Icons.payments_outlined),
            _Kpi(titulo: 'Categorías', valor: '${e.categorias.length}', icono: Icons.category_outlined),
            _Kpi(
              titulo: 'Vs. mes anterior',
              valor: variacion == null ? '—' : '${subeValor ? '+' : '-'}${formatDecimal(variacion.abs(), digits: 0)}%',
              icono: subeValor ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: variacion == null
                  ? AppColors.textMuted
                  : (subeValor ? AppColors.success : AppColors.danger),
            ),
          ],
        ),
        // valorUltimosDias es opcional: si el servidor no guarda historial se oculta el gráfico.
        if (e.valorUltimosDias.length >= 2) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor de inventario', style: appText(14, weight: w6)),
                const SizedBox(height: 2),
                Text('Últimos ${e.valorUltimosDias.length} días', style: appText(11, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                AreaLineChart(
                  values: e.valorUltimosDias.map((p) => p.valor).toList(),
                  labels: e.valorUltimosDias.map((p) => p.inicial).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nivel de stock', style: appText(14, weight: w6)),
              const SizedBox(height: 14),
              Row(
                children: [
                  DonutChart(
                    segments: [
                      DonutSegment(e.disponible.toDouble(), AppColors.donutNormal),
                      DonutSegment(e.critico.toDouble(), AppColors.donutBajo),
                      DonutSegment(e.agotado.toDouble(), AppColors.donutSinStock),
                    ],
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.total}', style: appText(24, weight: w7)),
                        Text('productos', style: appText(11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LegendDot(color: AppColors.donutNormal, label: 'Normal', value: '${e.disponible}'),
                        const SizedBox(height: 10),
                        LegendDot(color: AppColors.donutBajo, label: 'Bajo', value: '${e.critico}'),
                        const SizedBox(height: 10),
                        LegendDot(color: AppColors.donutSinStock, label: 'Sin stock', value: '${e.agotado}'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Productos con más stock', style: appText(14, weight: w6)),
              const SizedBox(height: 14),
              HBarList(items: e.masStock),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Ver análisis de inventario',
          icon: Icons.analytics_outlined,
          onPressed: () => Nav.analisis(context),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.titulo, required this.valor, required this.icono, this.color = AppColors.primary});

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(titulo, style: appText(11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: appText(22, weight: w7)),
          ),
        ],
      ),
    );
  }
}
