import 'package:flutter/material.dart';

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

/// Cambiar contraseña desde Perfil (POST /api/perfil/password).
///
/// Si la contraseña actual no es correcta el servidor responde 400 (no 401),
/// así que el error se muestra aquí y la sesión sigue abierta.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();

  String? _errorActual;
  String? _errorNueva;
  String? _errorConfirmar;
  String? _errorGeneral;
  bool _cargando = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final eActual = _actual.text.isEmpty ? 'Escribe tu contraseña actual' : null;
    String? eNueva = errorPassword(_nueva.text);
    if (eNueva == null && _nueva.text == _actual.text) {
      eNueva = 'La nueva contraseña debe ser diferente a la actual';
    }
    final eConfirmar = _confirmar.text == _nueva.text ? null : 'Las contraseñas no coinciden';
    if (eActual != null || eNueva != null || eConfirmar != null) {
      setState(() {
        _errorActual = eActual;
        _errorNueva = eNueva;
        _errorConfirmar = eConfirmar;
        _errorGeneral = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _errorActual = _errorNueva = _errorConfirmar = _errorGeneral = null;
      _cargando = true;
    });
    try {
      final mensaje = await InventarioRepository.instance.cambiarPassword(_actual.text, _nueva.text);
      await AppState.instance.contrasenaCambiada(_nueva.text);
      if (!mounted) return;
      showInfo(context, mensaje);
      Nav.volver(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (e.message.toLowerCase().contains('actual')) {
          _errorActual = e.message; // "La contraseña actual no es correcta"
        } else {
          _errorGeneral = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlueScaffold(
      title: 'Cambiar contraseña',
      onBack: () => Nav.volver(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Por tu seguridad, escribe tu contraseña actual y luego la nueva.',
              style: appText(14, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 20),
            Text('Contraseña actual', style: appText(13, weight: w6)),
            const SizedBox(height: 6),
            PasswordField(
              controller: _actual,
              hint: 'Tu contraseña actual',
              textInputAction: TextInputAction.next,
              errorText: _errorActual,
              onChanged: (_) {
                if (_errorActual != null) setState(() => _errorActual = null);
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
              hint: 'Repite la nueva contraseña',
              textInputAction: TextInputAction.done,
              errorText: _errorConfirmar,
              onSubmitted: (_) => _guardar(),
              onChanged: (_) {
                if (_errorConfirmar != null) setState(() => _errorConfirmar = null);
              },
            ),
            if (_errorGeneral != null) ...[
              const SizedBox(height: 12),
              Text(_errorGeneral!, style: appText(13, color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(label: 'Guardar contraseña', onPressed: _guardar, loading: _cargando),
          ],
        ),
      ),
    );
  }
}
