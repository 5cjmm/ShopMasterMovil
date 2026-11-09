import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class _AnalisisData {
  const _AnalisisData(this.resumen, this.estadisticas);
  final ResumenInventario resumen;
  final Estadisticas estadisticas;
}

/// 14 · Análisis de inventario: radar de cobertura y treemap de productos por
/// categoría. El mapa de calor, las ventas por categoría y la rotación quedan
/// fuera del alcance de la v1.1 del contrato.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _repo = InventarioRepository.instance;
  late Future<_AnalisisData> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_AnalisisData> _cargar() async {
    final resumen = _repo.resumen();
    final estadisticas = _repo.estadisticas();
    return _AnalisisData(await resumen, await estadisticas);
  }

  void _reintentar() {
    _repo.invalidar();
    setState(() => _futuro = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Análisis de inventario',
      onBack: () => Nav.volver(context),
      navIndex: 2,
      child: AsyncView<_AnalisisData>(
        future: _futuro,
        onRetry: _reintentar,
        builder: (context, data) => _Contenido(data: data),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.data});

  final _AnalisisData data;

  @override
  Widget build(BuildContext context) {
    final r = data.resumen;
    final e = data.estadisticas;
    final menor = e.menorCobertura;
    final mayor = e.categoriaMayor;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Últimos 7 días', style: appText(13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: SummaryTile(kind: SummaryKind.total, label: 'Total productos', value: '${r.totalProductos}', valueSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: SummaryTile(kind: SummaryKind.bajo, label: 'Stock bajo', value: '${r.stockCritico}', valueSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: SummaryTile(kind: SummaryKind.sinStock, label: 'Sin stock', value: '${r.sinStock}', valueSize: 20)),
          ],
        ),
        const SizedBox(height: 16),
        _Tarjeta(
          titulo: 'Cobertura por categoría',
          etiqueta: 'Radar',
          subtitulo: 'Stock disponible frente al objetivo (%)',
          child: Column(
            children: [
              RadarChart(items: e.cobertura),
              const SizedBox(height: 4),
              Text('Cobertura actual · objetivo: 100%', style: appText(11, color: AppColors.textSecondary)),
              if (menor != null) ...[
                const SizedBox(height: 12),
                _Conclusion('${menor.categoria} presenta la menor cobertura (${menor.valor.round()}%). Prioriza su reposición.'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Tarjeta(
          titulo: 'Productos por categoría',
          etiqueta: 'Treemap',
          subtitulo: '${e.totalProductos} productos · Área proporcional a la cantidad',
          child: Column(
            children: [
              TreemapView(items: e.categorias),
              if (mayor != null) ...[
                const SizedBox(height: 12),
                _Conclusion('${mayor.categoria} concentra la mayor cantidad de productos registrados.'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.etiqueta, this.subtitulo, required this.child});

  final String titulo;
  final String etiqueta;
  final String? subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: appText(14, weight: w6))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                child: Text(etiqueta, style: appText(11, weight: w6, color: AppColors.primary)),
              ),
            ],
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(subtitulo!, style: appText(11, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Conclusion extends StatelessWidget {
  const _Conclusion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(12)),
      child: Text(texto, style: appText(13, color: AppColors.navy, height: 1.4)),
    );
  }
}
