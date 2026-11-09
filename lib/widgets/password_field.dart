import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'common.dart';

/// Campo de contraseña con el ojo para mostrar u ocultar lo escrito.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      hint: widget.hint,
      icon: Icons.lock_outline_rounded,
      obscure: _oculta,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      suffix: IconButton(
        tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _oculta = !_oculta),
        icon: Icon(
          _oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
