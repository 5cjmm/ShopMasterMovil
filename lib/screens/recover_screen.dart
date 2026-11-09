import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/api_client.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';

/// 05 · Recuperar contraseña, paso 1 (POST /api/auth/recuperar).
///
/// El servidor responde 200 con el mismo mensaje exista o no el correo, para no
/// revelar qué correos están registrados. Si todo sale bien, pasa al paso 2
/// ([ResetPasswordScreen]), donde se escribe el código que llegó al correo.
class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _correo = TextEditingController();
  String? _error;
  bool _cargando = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  bool _correoValido(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _enviar() async {
    final correo = _correo.text.trim();
    if (!_correoValido(correo)) {
      setState(() => _error = 'Escribe un correo válido');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _cargando = true;
    });
    try {
      final mensaje = await InventarioRepository.instance.recuperar(correo);
      if (!mounted) return;
      setState(() => _cargando = false);
      showInfo(context, mensaje);
      Nav.restablecer(context, correo);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.message; // 400: "El correo no tiene un formato válido"
      });
    }
  }

  /// Para quien ya pidió el código antes y solo quiere escribirlo.
  void _yaTengoCodigo() {
    final correo = _correo.text.trim();
    if (!_correoValido(correo)) {
      setState(() => _error = 'Escribe el correo al que llegó el código');
      return;
    }
    Nav.restablecer(context, correo);
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Recuperar contraseña',
      onBack: () => Nav.volver(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                child: const Icon(Icons.lock_reset_rounded, size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Introduce tu correo registrado. Te enviaremos un código de 6 dígitos para crear una nueva contraseña.',
              style: appText(14, color: AppColors.textSecondary, height: 1.45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text('Correo electrónico', style: appText(13, weight: w6)),
            const SizedBox(height: 6),
            AppTextField(
              controller: _correo,
              hint: 'correo@ejemplo.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              errorText: _error,
              onSubmitted: (_) => _enviar(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Enviar código', onPressed: _enviar, loading: _cargando),
            const SizedBox(height: 8),
            Center(child: LinkButton(label: 'Ya tengo un código', onTap: _yaTengoCodigo)),
            Center(
              child: LinkButton(
                label: 'Volver a iniciar sesión',
                color: AppColors.textSecondary,
                onTap: () => Nav.volver(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
