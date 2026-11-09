import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/api_client.dart';
import '../data/app_state.dart';
import '../data/biometric_service.dart';
import '../data/repository.dart';
import '../widgets/common.dart';

/// 01 · Inicio de sesión (POST /api/auth/login).
///
/// El campo «Usuario» del diseño recibe el correo electrónico registrado.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;
  String? _errorUsuario;
  String? _errorClave;

  @override
  void initState() {
    super.initState();
    // Mensaje pendiente, por ejemplo "Tu sesión venció. Ingresa de nuevo."
    final mensaje = AppState.instance.mensajeLogin;
    if (mensaje != null) {
      AppState.instance.mensajeLogin = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showInfo(context, mensaje);
      });
    }
  }

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final usuario = _usuario.text.trim();
    final clave = _clave.text;
    setState(() {
      _errorUsuario = usuario.isEmpty ? 'Escribe tu correo' : null;
      _errorClave = clave.isEmpty ? 'Escribe tu contraseña' : null;
    });
    if (_errorUsuario != null || _errorClave != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);
    try {
      final sesion = await InventarioRepository.instance.login(usuario, clave);
      await AppState.instance.iniciarSesion(sesion, email: usuario, password: clave);
      if (!mounted) return;
      Nav.entrar(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (e.statusCode == 401) {
          _errorClave = e.message;
        } else {
          _errorClave = null;
        }
      });
      if (e.statusCode != 401) showInfo(context, e.message);
    }
  }

  Future<void> _huella() async {
    if (!AppState.instance.huellaActiva) {
      showInfo(context, 'El acceso con huella está desactivado. Actívalo desde tu perfil.');
      return;
    }
    if (!await BiometricService.instance.disponible()) {
      if (!mounted) return;
      showInfo(context, 'Este teléfono no tiene una huella registrada. Usa tu contraseña.');
      return;
    }
    if (await AppState.instance.credencialesGuardadas() == null) {
      if (!mounted) return;
      showInfo(context, 'Ingresa una vez con tu contraseña para activar el acceso con huella.');
      return;
    }
    if (!mounted) return;
    Nav.huella(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Bienvenido', style: appText(26, weight: w7)),
                        const SizedBox(height: 4),
                        Text('Inicia sesión para continuar', style: appText(14, color: AppColors.textSecondary)),
                        const SizedBox(height: 22),
                        Text('Usuario', style: appText(13, weight: w6)),
                        const SizedBox(height: 6),
                        AppTextField(
                          controller: _usuario,
                          hint: 'correo@ejemplo.com',
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _errorUsuario,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_errorUsuario != null) setState(() => _errorUsuario = null);
                          },
                        ),
                        const SizedBox(height: 14),
                        Text('Contraseña', style: appText(13, weight: w6)),
                        const SizedBox(height: 6),
                        AppTextField(
                          controller: _clave,
                          hint: 'Escribe tu contraseña',
                          icon: Icons.lock_outline_rounded,
                          obscure: _ocultar,
                          errorText: _errorClave,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _iniciar(),
                          onChanged: (_) {
                            if (_errorClave != null) setState(() => _errorClave = null);
                          },
                          suffix: IconButton(
                            tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                            onPressed: () => setState(() => _ocultar = !_ocultar),
                            icon: Icon(
                              _ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(label: 'Iniciar sesión', onPressed: _iniciar, loading: _cargando),
                        const SizedBox(height: 14),
                        AppCard(
                          color: AppColors.accentSoft,
                          radius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          onTap: _cargando ? null : _huella,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.fingerprint, color: AppColors.primary, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Iniciar con huella dactilar', style: appText(14, weight: w6)),
                                    const SizedBox(height: 2),
                                    Text('Accede de forma rápida y segura',
                                        style: appText(12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.primary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.divider)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('o', style: appText(13, color: AppColors.textMuted)),
                            ),
                            const Expanded(child: Divider(color: AppColors.divider)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Center(child: LinkButton(label: '¿Olvidaste tu contraseña?', onTap: () => Nav.recuperar(context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: _Wave())),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A2E78), Color(0xFF1B5BC8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
          child: Column(
            children: [
              const LogoMark(width: 78),
              const SizedBox(height: 14),
              const Wordmark(size: 30, onDark: true),
              const SizedBox(height: 6),
              Text(
                'Gestión inteligente para tu tienda',
                style: appText(13, color: const Color(0xCCFFFFFF)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wave extends StatelessWidget {
  const _Wave();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 70, width: double.infinity, child: CustomPaint(painter: _WavePainter()));
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final back = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(size.width * 0.25, size.height * 0.1, size.width * 0.55, size.height * 0.75,
          size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFF1B5BC8));

    final front = Path()
      ..moveTo(0, size.height * 0.7)
      ..cubicTo(size.width * 0.3, size.height * 0.4, size.width * 0.65, size.height * 1.0,
          size.width, size.height * 0.55)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF0F46A6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
