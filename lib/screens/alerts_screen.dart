import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';

/// 12 · Alertas de inventario: GET /api/productos/stock-critico (críticos y agotados).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _repo = InventarioRepository.instance;
  late Future<StockCritico> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.stockCritico();
  }

  void _reintentar() {
    _repo.invalidar();
    setState(() => _futuro = _repo.stockCritico());
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Alertas de inventario',
      onBack: () => Nav.volver(context),
      navIndex: 1,
      child: AsyncView<StockCritico>(
        future: _futuro,
        onRetry: _reintentar,
        builder: (context, data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _ResumenAlerta(
                    icono: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    fondo: AppColors.warningBg,
                    titulo: 'Stock bajo',
                    cantidad: data.totalCritico,
                    onTap: () => Nav.inventario(context, estado: EstadoStock.bajo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ResumenAlerta(
                    icono: Icons.cancel_outlined,
                    color: AppColors.danger,
                    fondo: AppColors.dangerBg,
                    titulo: 'Sin stock',
                    cantidad: data.totalAgotado,
                    onTap: () => Nav.inventario(context, estado: EstadoStock.sinStock),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionTitle('Productos con stock crítico'),
            const SizedBox(height: 12),
            if (data.productos.isEmpty)
              AppCard(
                child: Text('No hay productos con stock crítico. ¡Todo en orden!',
                    style: appText(14, color: AppColors.textSecondary)),
              )
            else
              for (var i = 0; i < data.productos.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                ProductTile(
                  producto: data.productos[i],
                  style: ProductTileStyle.alerta,
                  onTap: () => Nav.detalle(context, data.productos[i]),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _ResumenAlerta extends StatelessWidget {
  const _ResumenAlerta({
    required this.icono,
    required this.color,
    required this.fondo,
    required this.titulo,
    required this.cantidad,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final Color fondo;
  final String titulo;
  final int cantidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
            child: Icon(icono, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text('$cantidad', style: appText(26, weight: w7)),
          const SizedBox(height: 2),
          Text(titulo, style: appText(13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
