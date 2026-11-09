import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../data/models.dart';

void showInfo(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

// ---------------------------------------------------------------------------
// Contenedores
// ---------------------------------------------------------------------------

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 16,
    this.color = AppColors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0B2E6B), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: appText(15, weight: w6));
}

// ---------------------------------------------------------------------------
// Botones y campos
// ---------------------------------------------------------------------------

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Muestra un indicador de carga y desactiva el botón.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.scale2,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(label, style: appText(16, weight: w6, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onTap, this.color = AppColors.primary});

  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: appText(14, weight: w5, color: color)),
    );
  }
}

OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.errorText,
    this.inputFormatters,
  });

  final List<TextInputFormatter>? inputFormatters;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      style: appText(15),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: appText(15, color: AppColors.placeholder),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.field,
        errorText: errorText,
        errorStyle: appText(12, color: AppColors.danger),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: _inputBorder(AppColors.divider),
        enabledBorder: _inputBorder(AppColors.divider),
        focusedBorder: _inputBorder(AppColors.primary, 1.5),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, 1.5),
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: appText(13, weight: selected ? w6 : w5, color: selected ? Colors.white : AppColors.navy),
          ),
        ),
      ),
    );
  }
}

/// Interruptor con el estilo del prototipo (evita depender de Switch).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Marca
// ---------------------------------------------------------------------------

class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.width = 67});
  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/logo.svg', width: width);
}

class LogoTile extends StatelessWidget {
  const LogoTile({super.key, this.size = 62});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.17),
      decoration: BoxDecoration(
        color: AppColors.header,
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: SvgPicture.asset('assets/logo.svg'),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 28, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Shop',
            style: appText(size, weight: w7, color: onDark ? Colors.white : AppColors.navy),
          ),
          TextSpan(
            text: 'Master',
            style: appText(size, weight: w7, color: onDark ? const Color(0xFF2F6FE4) : AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Producto
// ---------------------------------------------------------------------------

class StockBadge extends StatelessWidget {
  const StockBadge(this.estado, {super.key});
  final EstadoStock estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.estadoBg(estado),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        estado.etiqueta,
        style: appText(11, weight: w6, color: AppColors.estadoFg(estado)),
      ),
    );
  }
}

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.categoria, this.size = 56, this.radius = 12});

  final String categoria;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.thumbFor(categoria),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.inventory_2_outlined, size: size * 0.45, color: AppColors.thumbIcon),
    );
  }
}

enum ProductTileStyle { inventario, alerta, compacto }

/// Fila de producto. "inventario" muestra precio y estado; "alerta" muestra el
/// stock y el estado; "compacto" (Inicio) muestra solo las unidades en rojo.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.producto,
    required this.onTap,
    this.style = ProductTileStyle.inventario,
  });

  final Producto producto;
  final VoidCallback onTap;
  final ProductTileStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case ProductTileStyle.compacto:
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ProductThumb(categoria: producto.categoria, size: 40, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(producto.nombre, style: appText(15, weight: w6), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        producto.unidadesTexto,
                        style: appText(13, color: producto.stock == 0 ? AppColors.dangerStrong : AppColors.danger),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      case ProductTileStyle.alerta:
        return AppCard(
          padding: const EdgeInsets.all(12),
          onTap: onTap,
          child: Row(
            children: [
              ProductThumb(categoria: producto.categoria),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.nombre, style: appText(16, weight: w6), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Stock: ${producto.unidadesTexto}', style: appText(13, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    StockBadge(producto.estado),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        );
      case ProductTileStyle.inventario:
        return AppCard(
          padding: const EdgeInsets.all(12),
          onTap: onTap,
          child: Row(
            children: [
              ProductThumb(categoria: producto.categoria),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.nombre, style: appText(16, weight: w6), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${producto.categoria} · ${producto.unidadesTexto}',
                      style: appText(13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('\$${_miles(producto.precio)}', style: appText(15, weight: w7)),
                        const Spacer(),
                        StockBadge(producto.estado),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        );
    }
  }
}

String _miles(int value) {
  final s = value.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

// ---------------------------------------------------------------------------
// Resumen: baldosas con icono
// ---------------------------------------------------------------------------

enum SummaryKind { total, bajo, sinStock }

/// Baldosa vertical de resumen (Total productos / Stock bajo / Sin stock).
class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.kind,
    required this.label,
    required this.value,
    this.onTap,
    this.valueSize = 24,
  });

  final SummaryKind kind;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final IconData icon;
    late final Color iconColor;
    switch (kind) {
      case SummaryKind.total:
        bg = AppColors.accentSoft;
        icon = Icons.inventory_2_outlined;
        iconColor = AppColors.primary;
      case SummaryKind.bajo:
        bg = AppColors.warningBg;
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.warning;
      case SummaryKind.sinStock:
        bg = AppColors.dangerBg;
        icon = Icons.cancel_outlined;
        iconColor = AppColors.danger;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(height: 6),
              Text(label, style: appText(11, weight: w5, color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(value, style: appText(valueSize, weight: w7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carga y error
// ---------------------------------------------------------------------------

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_outlined, color: AppColors.danger, size: 30),
            ),
            const SizedBox(height: 16),
            Text('No pudimos cargar la información', style: appText(17, weight: w7), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: appText(13, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(width: 180, child: PrimaryButton(label: 'Reintentar', onPressed: onRetry)),
          ],
        ),
      ),
    );
  }
}

class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder, required this.onRetry});

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(message: snapshot.error.toString(), onRetry: onRetry);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return builder(context, snapshot.requireData);
      },
    );
  }
}
