import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../core/validators.dart';
import '../data/api_client.dart';
import '../data/app_state.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';
import '../widgets/common.dart';
import '../widgets/password_field.dart';

/// 05b · Recuperar contraseña, paso 2 (POST /api/auth/restablecer).
///
/// Se escribe el código de 6 dígitos que llegó al correo y la nueva contraseña.
/// El código vence a los 15 minutos y se bloquea tras 5 intentos fallidos; en
/// ese caso se pide uno nuevo con "Reenviar código" (el servidor deja uno por minuto).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const int _segundosEntreEnvios = 60;

  final _codigo = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  String? _errorCodigo;
  String? _errorNueva;
  String? _errorConfirmar;
  String? _errorGeneral;
  bool _cargando = false;

  Timer? _reloj;
  int _espera = _segundosEntreEnvios; // el código se acaba de enviar

  @override
  void initState() {
    super.initState();
    _arrancarReloj();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _codigo.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  void _iniciarEspera() {
    setState(() => _espera = _segundosEntreEnvios);
    _arrancarReloj();
  }

  void _arrancarReloj() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _espera--);
      if (_espera <= 0) t.cancel();
    });
  }

  Future<void> _reenviar() async {
    try {
      final mensaje = await InventarioRepository.instance.recuperar(widget.email);
      if (!mounted) return;
      showInfo(context, mensaje);
      _iniciarEspera();
    } on ApiException catch (e) {
      if (!mounted) return;
      showInfo(context, e.message);
    }
  }

  Future<void> _guardar() async {
    final codigo = _codigo.text.trim();
    final eCodigo = esCodigoValido(codigo) ? null : 'Escribe el código de 6 dígitos';
    final eNueva = errorPassword(_nueva.text);
    final eConfirmar = _confirmar.text == _nueva.text ? null : 'Las contraseñas no coinciden';
    if (eCodigo != null || eNueva != null || eConfirmar != null) {
      setState(() {
        _errorCodigo = eCodigo;
        _errorNueva = eNueva;
        _errorConfirmar = eConfirmar;
        _errorGeneral = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _errorCodigo = _errorNueva = _errorConfirmar = _errorGeneral = null;
      _cargando = true;
    });
    try {
      final mensaje = await InventarioRepository.instance.restablecer(widget.email, codigo, _nueva.text);
      await AppState.instance.contrasenaRestablecida(widget.email);
      if (!mounted) return;
      showInfo(context, mensaje);
      Nav.login(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (e.message.toLowerCase().contains('código')) {
          _errorCodigo = e.message; // "El código no es válido o venció"
        } else {
          _errorGeneral = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Nueva contraseña',
      onBack: () => Nav.volver(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Escribe el código de 6 dígitos que enviamos a ${widget.email} y elige tu nueva contraseña. El código vence en 15 minutos.',
              style: appText(14, color: AppColors.textSecondary, height: 1.45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text('Código', style: appText(13, weight: w6)),
            const SizedBox(height: 6),
            AppTextField(
              controller: _codigo,
              hint: '000000',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              errorText: _errorCodigo,
              onChanged: (_) {
                if (_errorCodigo != null) setState(() => _errorCodigo = null);
              },
            ),
            const SizedBox(height: 16),
            Text('Nueva contraseña', style: appText(13, weight: w6)),
            const SizedBox(height: 6),
            PasswordField(
              controller: _nueva,
              hint: 'Mínimo 8 caracteres, con letra y número',
              textInputAction: TextInputAction.next,
              errorText: _errorNueva,
              onChanged: (_) {
                if (_errorNueva != null) setState(() => _errorNueva = null);
              },
            ),
            const SizedBox(height: 16),
            Text('Confirmar contraseña', style: appText(13, weight: w6)),
            const SizedBox(height: 6),
            PasswordField(
              controller: _confirmar,
              hint: 'Repite la contraseña',
              textInputAction: TextInputAction.done,
              errorText: _errorConfirmar,
              onSubmitted: (_) => _guardar(),
              onChanged: (_) {
                if (_errorConfirmar != null) setState(() => _errorConfirmar = null);
              },
            ),
            if (_errorGeneral != null) ...[
              const SizedBox(height: 12),
              Text(_errorGeneral!, style: appText(13, color: AppColors.danger), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 22),
            PrimaryButton(label: 'Guardar contraseña', onPressed: _guardar, loading: _cargando),
            const SizedBox(height: 8),
            Center(
              child: LinkButton(
                label: _espera > 0 ? 'Reenviar código en ${_espera}s' : 'Reenviar código',
                onTap: _espera > 0 ? null : _reenviar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
