import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/nav.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';

class _HomeData {
  const _HomeData(this.perfil, this.resumen, this.criticos);
  final Perfil? perfil;
  final ResumenInventario resumen;
  final List<Producto> criticos;
}

/// 06 · Inicio: GET /api/perfil, GET /api/inventario/resumen y
/// GET /api/productos/stock-critico?estado=CRITICO&limite=2.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = InventarioRepository.instance;
  late Future<_HomeData> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<_HomeData> _cargar() async {
    // El saludo es un extra: si el perfil falla, la pantalla sigue con «Hola».
    final perfil = _repo.perfil().then<Perfil?>((p) => p).catchError((Object _) => null);
    final resumen = _repo.resumen();
    final criticos = _repo.stockCritico(estado: EstadoStock.bajo, limite: 2);
    // Los avisos del perfil y la insignia de la campana salen del mismo endpoint.
    app.cargarAvisos();
    return _HomeData(await perfil, await resumen, (await criticos).productos);
  }

  AppState get app => AppState.instance;

  void _reintentar() {
    _repo.invalidar();
    setState(() => _futuro = _cargar());
  }

  Future<void> _refrescar() async {
    _repo.invalidar();
    final nuevo = _cargar();
    setState(() => _futuro = nuevo);
    try {
      await nuevo;
    } catch (_) {
      // El error se muestra en pantalla con el botón "Reintentar".
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      navIndex: 0,
      header: SizedBox(
        height: 52,
        child: FutureBuilder<_HomeData>(
          future: _futuro,
          builder: (context, snapshot) {
            final nombre = snapshot.data?.perfil?.primerNombre ?? '';
            return AnimatedBuilder(
              animation: app,
              builder: (context, _) => Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                            style: appText(20, weight: w7, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('¡Qué gusto verte!', style: appText(13, color: const Color(0xCCFFFFFF))),
                      ],
                    ),
                  ),
                  HeaderIconButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: 'Asistente',
                    onTap: () => Nav.chat(context),
                  ),
                  const SizedBox(width: 4),
                  HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Alertas',
                    badge: app.sinLeer,
                    onTap: () => Nav.alertas(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      child: AsyncView<_HomeData>(
        future: _futuro,
        onRetry: _reintentar,
        builder: (context, data) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refrescar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const SectionTitle('Resumen del inventario'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SummaryTile(
                      kind: SummaryKind.total,
                      label: 'Total productos',
                      value: '${data.resumen.totalProductos}',
                      onTap: () => Nav.inventario(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryTile(
                      kind: SummaryKind.bajo,
                      label: 'Stock bajo',
                      value: '${data.resumen.stockCritico}',
                      onTap: () => Nav.inventario(context, estado: EstadoStock.bajo),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryTile(
                      kind: SummaryKind.sinStock,
                      label: 'Sin stock',
                      value: '${data.resumen.sinStock}',
                      onTap: () => Nav.inventario(context, estado: EstadoStock.sinStock),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ValorCard(resumen: data.resumen),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: SectionTitle('Productos con stock crítico')),
                  LinkButton(label: 'Ver todo', onTap: () => Nav.alertas(context)),
                ],
              ),
              const SizedBox(height: 4),
              if (data.criticos.isEmpty)
                AppCard(
                  child: Text('No hay productos con stock crítico. ¡Todo en orden!',
                      style: appText(14, color: AppColors.textSecondary)),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < data.criticos.length && i < 2; i++) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.divider),
                        ProductTile(
                          producto: data.criticos[i],
                          style: ProductTileStyle.compacto,
                          onTap: () => Nav.detalle(context, data.criticos[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              AppCard(
                onTap: () => Nav.prediccion(context),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.show_chart_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Predicción de precios', style: appText(15, weight: w7)),
                          const SizedBox(height: 2),
                          Text('Compara el pronóstico con la inflación del DANE',
                              style: appText(12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValorCard extends StatelessWidget {
  const _ValorCard({required this.resumen});

  final ResumenInventario resumen;

  @override
  Widget build(BuildContext context) {
    final variacion = resumen.variacionMensual; // null = sin historial: se oculta la flecha
    final sube = (variacion ?? 0) >= 0;
    final color = sube ? AppColors.success : AppColors.danger;
    final pct = (variacion ?? 0).abs();
    final pctTexto = pct == pct.roundToDouble() ? '${pct.round()}' : formatDecimal(pct);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor del inventario', style: appText(13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(formatCop(resumen.valorInventario, space: true), style: appText(26, weight: w7)),
                if (variacion != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(sube ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: color),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text('$pctTexto% vs. mes anterior', style: appText(12, weight: w5, color: color)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
