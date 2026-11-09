import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';

/// 15 · Perfil y configuración, 16 · Diálogo de cerrar sesión.
///
/// El perfil sale de GET /api/perfil (solo lectura en la v1.1). Los avisos
/// recientes salen de GET /api/productos/stock-critico; el interruptor de
/// huella, las preferencias y el estado leído se guardan solo en el dispositivo.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Perfil> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = InventarioRepository.instance.perfil();
    AppState.instance.cargarAvisos();
  }

  void _reintentar() {
    InventarioRepository.instance.invalidar();
    setState(() => _perfil = InventarioRepository.instance.perfil());
    AppState.instance.cargarAvisos();
  }

  Future<void> _cambiarHuella(bool valor) async {
    final mensaje = await AppState.instance.setHuellaActiva(valor);
    if (mensaje != null && mounted) showInfo(context, mensaje);
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: AppColors.dangerBg, shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 28),
              ),
              const SizedBox(height: 16),
              Text('¿Quieres cerrar sesión?', style: appText(18, weight: w7), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Tus datos están guardados. Para volver a entrar, usa tu contraseña o tu huella.',
                style: appText(14, color: AppColors.textSecondary, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Sí, cerrar sesión', style: appText(15, weight: w6, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 4),
              LinkButton(label: 'Cancelar', color: AppColors.textSecondary, onTap: () => Navigator.of(ctx).pop(false)),
            ],
          ),
        ),
      ),
    );

    if (salir == true && context.mounted) {
      await AppState.instance.cerrarSesion();
      if (context.mounted) Nav.login(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;

    return BlueScaffold(
      title: 'Perfil',
      navIndex: 3,
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FutureBuilder<Perfil>(
              future: _perfil,
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
                        LinkButton(label: 'Reintentar', onTap: _reintentar),
                      ],
                    ),
                  );
                }
                final p = snapshot.data;
                if (p == null) {
                  return const AppCard(
                    child: SizedBox(
                      height: 64,
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
                    ),
                  );
                }
                return AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: Text(p.iniciales, style: appText(22, weight: w7, color: Colors.white)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombre, style: appText(17, weight: w7)),
                            const SizedBox(height: 2),
                            Text(p.rolYTienda, style: appText(13, color: AppColors.textSecondary)),
                            Text(p.email, style: appText(13, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => showInfo(context, 'En esta versión el perfil es de solo lectura.'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text('Editar perfil', style: appText(13, weight: w6, color: AppColors.primary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const SectionTitle('Cuenta y seguridad'),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _FilaAccion(
                    icono: Icons.lock_outline_rounded,
                    titulo: 'Cambiar contraseña',
                    onTap: () => Nav.cambiarPassword(context),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _FilaInterruptor(
                    icono: Icons.fingerprint,
                    titulo: 'Acceso con huella',
                    detalle: 'Inicia sesión de forma rápida y segura',
                    valor: app.huellaActiva,
                    onChanged: _cambiarHuella,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Notificaciones'),
            const SizedBox(height: 2),
            Text('Elige qué avisos quieres recibir.', style: appText(12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _FilaInterruptor(
                    icono: Icons.warning_amber_rounded,
                    titulo: 'Stock bajo y sin stock',
                    detalle: 'Avisos para reponer tus productos',
                    valor: app.avisosStock,
                    onChanged: app.setAvisosStock,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _FilaInterruptor(
                    icono: Icons.summarize_outlined,
                    titulo: 'Resumen diario',
                    detalle: 'Estado del inventario a las 8:00 a. m.',
                    valor: app.resumenDiario,
                    onChanged: app.setResumenDiario,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _FilaInterruptor(
                    icono: Icons.campaign_outlined,
                    titulo: 'Novedades y consejos',
                    detalle: 'Recomendaciones de ShopMaster',
                    valor: app.novedades,
                    onChanged: app.setNovedades,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: SectionTitle('Avisos recientes')),
                Text(
                  app.sinLeer == 0 ? 'Al día' : '${app.sinLeer} sin leer',
                  style: appText(12, weight: w6, color: app.sinLeer == 0 ? AppColors.success : AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  if (app.avisos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No tienes avisos por ahora.', style: appText(13, color: AppColors.textSecondary)),
                    ),
                  for (var i = 0; i < app.avisos.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.divider),
                    _FilaAviso(aviso: app.avisos[i]),
                  ],
                  const Divider(height: 1, color: AppColors.divider),
                  Center(
                    child: LinkButton(
                      label: 'Marcar todas como leídas',
                      onTap: app.sinLeer == 0 ? null : app.marcarTodasLeidas,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              onTap: () => _confirmarSalida(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Cerrar sesión', style: appText(15, weight: w6, color: AppColors.danger))),
                    const Icon(Icons.chevron_right, color: AppColors.danger),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilaAccion extends StatelessWidget {
  const _FilaAccion({required this.icono, required this.titulo, required this.onTap});

  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _IconoCirculo(icono),
            const SizedBox(width: 12),
            Expanded(child: Text(titulo, style: appText(14, weight: w6))),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _FilaInterruptor extends StatelessWidget {
  const _FilaInterruptor({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.valor,
    required this.onChanged,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _IconoCirculo(icono),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: appText(14, weight: w6)),
                const SizedBox(height: 2),
                Text(detalle, style: appText(12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppSwitch(value: valor, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _IconoCirculo extends StatelessWidget {
  const _IconoCirculo(this.icono);

  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
      child: Icon(icono, size: 20, color: AppColors.primary),
    );
  }
}

class _FilaAviso extends StatelessWidget {
  const _FilaAviso({required this.aviso});

  final Aviso aviso;

  @override
  Widget build(BuildContext context) {
    final agotado = aviso.agotado;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: agotado ? AppColors.dangerBg : AppColors.warningBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              agotado ? Icons.cancel_outlined : Icons.warning_amber_rounded,
              size: 19,
              color: agotado ? AppColors.danger : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aviso.titulo, style: appText(14, weight: aviso.leida ? w5 : w7)),
                const SizedBox(height: 2),
                Text(aviso.detalle, style: appText(12, color: AppColors.textSecondary, height: 1.35)),
              ],
            ),
          ),
          if (!aviso.leida)
            Container(
              margin: const EdgeInsets.only(top: 6, left: 8),
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
