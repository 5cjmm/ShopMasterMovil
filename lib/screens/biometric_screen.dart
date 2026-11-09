import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/api_client.dart';
import '../data/app_state.dart';
import '../data/biometric_service.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';

enum _Fase { escaneando, ok, fail }

/// 02–04 · Acceso con huella: escaneo, huella verificada y huella no reconocida.
///
/// La huella la valida el sistema con `local_auth` y nunca viaja al servidor:
/// solo desbloquea las credenciales guardadas en el dispositivo y la app repite
/// POST /api/auth/login con ellas.
class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso;
  _Fase _fase = _Fase.escaneando;
  String? _mensajeError;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    // Deja pintar la pantalla antes de abrir el cuadro de huella del sistema.
    WidgetsBinding.instance.addPostFrameCallback((_) => _escanear());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulso.dispose();
    super.dispose();
  }

  Future<void> _escanear() async {
    if (!mounted) return;
    setState(() {
      _fase = _Fase.escaneando;
      _mensajeError = null;
    });

    final reconocida = await BiometricService.instance.autenticar('Confirma tu identidad para entrar a ShopMaster');
    if (!mounted) return;
    if (!reconocida) {
      setState(() => _fase = _Fase.fail);
      return;
    }

    final cred = await AppState.instance.credencialesGuardadas();
    if (!mounted) return;
    if (cred == null) {
      setState(() {
        _fase = _Fase.fail;
        _mensajeError = 'Ingresa una vez con tu contraseña para activar el acceso con huella.';
      });
      return;
    }

    try {
      final sesion = await InventarioRepository.instance.login(cred.email, cred.password);
      await AppState.instance.iniciarSesion(sesion, email: cred.email, password: cred.password);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fase = _Fase.fail;
        _mensajeError = e.statusCode == 401
            ? 'Tus credenciales guardadas ya no son válidas. Ingresa con tu contraseña.'
            : e.message;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _fase = _Fase.ok);
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) Nav.entrar(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Acceso y huella',
      onBack: () => Nav.volver(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _Sensor(fase: _fase, pulso: _pulso),
              const SizedBox(height: 28),
              Text(_titulo, style: appText(22, weight: w7), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_detalle, style: appText(14, color: AppColors.textSecondary, height: 1.4), textAlign: TextAlign.center),
              const Spacer(flex: 2),
              ..._acciones(context),
            ],
          ),
        ),
      ),
    );
  }

  String get _titulo {
    switch (_fase) {
      case _Fase.escaneando:
        return 'Coloca tu dedo en el sensor';
      case _Fase.ok:
        return 'Huella verificada';
      case _Fase.fail:
        return 'No reconocemos tu huella';
    }
  }

  String get _detalle {
    switch (_fase) {
      case _Fase.escaneando:
        return 'Confirma tu identidad para acceder a tu tienda.';
      case _Fase.ok:
        return 'Identidad confirmada. Entrando a ShopMaster…';
      case _Fase.fail:
        return _mensajeError ?? 'Limpia el sensor y vuelve a intentarlo o accede con tu contraseña.';
    }
  }

  List<Widget> _acciones(BuildContext context) {
    switch (_fase) {
      case _Fase.escaneando:
        return [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Escaneando huella…', style: appText(14, weight: w6)),
                      const SizedBox(height: 2),
                      Text('Mantén el dedo sobre el sensor', style: appText(12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinkButton(label: 'Usar contraseña', onTap: () => Nav.login(context)),
        ];
      case _Fase.ok:
        return [
          const SizedBox(height: 4),
          const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.success),
          const SizedBox(height: 20),
        ];
      case _Fase.fail:
        return [
          PrimaryButton(label: 'Intentar de nuevo', onPressed: _escanear),
          const SizedBox(height: 4),
          LinkButton(label: 'Usar contraseña', onTap: () => Nav.login(context)),
        ];
    }
  }
}

class _Sensor extends StatelessWidget {
  const _Sensor({required this.fase, required this.pulso});

  final _Fase fase;
  final Animation<double> pulso;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final Color bg;
    late final IconData icono;
    switch (fase) {
      case _Fase.escaneando:
        color = AppColors.primary;
        bg = AppColors.accentSoft;
        icono = Icons.fingerprint;
      case _Fase.ok:
        color = AppColors.success;
        bg = AppColors.successBg;
        icono = Icons.check_rounded;
      case _Fase.fail:
        color = AppColors.danger;
        bg = AppColors.dangerBg;
        icono = Icons.close_rounded;
    }

    return AnimatedBuilder(
      animation: pulso,
      builder: (context, child) {
        final extra = fase == _Fase.escaneando ? pulso.value * 14 : 0.0;
        return SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150 + extra,
                height: 150 + extra,
                decoration: BoxDecoration(color: bg.withAlpha(140), shape: BoxShape.circle),
              ),
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
                child: Icon(icono, size: 68, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
