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

/// 10 · Detalle (Historial de ventas) y 11 · Detalle (Información): GET /api/productos/{id}.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productoId, this.inicial});

  final String productoId;

  /// Producto que ya se conocía desde la lista (solo para el título mientras carga).
  final Producto? inicial;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _repo = InventarioRepository.instance;
  late Future<Producto> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.producto(widget.productoId);
  }

  void _reintentar() {
    setState(() => _futuro = _repo.producto(widget.productoId));
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: widget.inicial?.nombre ?? 'Detalle del producto',
      onBack: () => Nav.volver(context),
      child: AsyncView<Producto>(
        future: _futuro,
        onRetry: _reintentar,
        builder: (context, producto) => _Detalle(producto: producto),
      ),
    );
  }
}

class _Detalle extends StatefulWidget {
  const _Detalle({required this.producto});

  final Producto producto;

  @override
  State<_Detalle> createState() => _DetalleState();
}

class _DetalleState extends State<_Detalle> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final colorNivel = p.estado == EstadoStock.normal ? AppColors.primary : AppColors.danger;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Row(
            children: [
              ProductThumb(categoria: p.categoria, size: 64, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: appText(17, weight: w7), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      p.presentacion.isEmpty ? p.categoria : '${p.categoria} · ${p.presentacion}',
                      style: appText(13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    StockBadge(p.estado),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio de venta', style: appText(12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(formatCop(p.precio), style: appText(22, weight: w7)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock actual', style: appText(12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(formatUnidades(p.stock), style: appText(22, weight: w7)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Nivel de stock', style: appText(14, weight: w6))),
                  Text('${p.nivelStock}%', style: appText(14, weight: w7, color: colorNivel)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: p.nivel.clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  backgroundColor: AppColors.track,
                  valueColor: AlwaysStoppedAnimation<Color>(colorNivel),
                ),
              ),
              const SizedBox(height: 6),
              Text('Mínimo recomendado: ${formatUnidades(p.stockMinimo)}',
                  style: appText(12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Pestanas(actual: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 14),
        if (_tab == 0) _Historial(producto: p) else _Informacion(producto: p),
      ],
    );
  }
}

class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.actual, required this.onChanged});

  final int actual;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const nombres = ['Historial de ventas', 'Información'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.track, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (var i = 0; i < nombres.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == actual ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    nombres[i],
                    textAlign: TextAlign.center,
                    style: appText(13, weight: w6, color: i == actual ? AppColors.primary : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Historial extends StatelessWidget {
  const _Historial({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final ventas = producto.ventas7Dias;
    final total = ventas.fold<int>(0, (s, v) => s + v.unidades);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Ventas (últimos 7 días)')),
              if (ventas.isNotEmpty) Text('$total uds.', style: appText(13, weight: w6, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          if (ventas.isEmpty)
            Text('Aún no hay ventas registradas para este producto.',
                style: appText(13, color: AppColors.textSecondary))
          else
            WeekBarChart(
              values: ventas.map((v) => v.unidades).toList(),
              labels: ventas.map((v) => v.inicial).toList(),
            ),
        ],
      ),
    );
  }
}

class _Informacion extends StatelessWidget {
  const _Informacion({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final p = producto;
    final filas = <MapEntry<String, String>>[
      MapEntry('Código / SKU', p.codigo),
      MapEntry('Código de barras', p.codigoBarras),
      MapEntry('Categoría', p.categoria),
      MapEntry('Presentación', p.presentacion),
      MapEntry('Proveedor', p.proveedor),
      MapEntry('Precio de venta', formatCop(p.precio)),
      MapEntry('Stock actual / mínimo', '${p.stock} / ${p.stockMinimo}'),
      MapEntry('Ubicación', p.ubicacion),
    ];

    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < filas.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: Text(filas[i].key, style: appText(13, color: AppColors.textSecondary))),
                      Expanded(
                        flex: 6,
                        child: Text(
                          filas[i].value.isEmpty ? '—' : filas[i].value,
                          style: appText(14, weight: w6),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Editar producto',
          icon: Icons.edit_outlined,
          onPressed: () => showInfo(context, 'La edición no está disponible en esta versión.'),
        ),
      ],
    );
  }
}
