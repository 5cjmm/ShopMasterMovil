import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';

/// Estructura común de las pantallas internas: cabecera azul y hoja clara con
/// esquinas superiores redondeadas. Si [navIndex] no es nulo, muestra la barra
/// inferior con esa pestaña resaltada.
class BlueScaffold extends StatelessWidget {
  const BlueScaffold({
    super.key,
    this.title,
    this.header,
    this.onBack,
    this.trailing,
    this.navIndex,
    required this.child,
  });

  final String? title;

  /// Cabecera personalizada (reemplaza a [title], [onBack] y [trailing]).
  final Widget? header;
  final VoidCallback? onBack;
  final Widget? trailing;
  final int? navIndex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cabecera = header ?? _TitleRow(title: title ?? '', onBack: onBack, trailing: trailing);

    return Scaffold(
      backgroundColor: AppColors.header,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: cabecera,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(color: AppColors.background, child: child),
            ),
          ),
        ],
      ),
      bottomNavigationBar: navIndex == null ? null : AppBottomNav(currentIndex: navIndex!),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          if (onBack != null) const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: appText(20, weight: w6, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Botón circular de la cabecera (campana, filtros, etc.).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({super.key, required this.icon, required this.onTap, this.badge = 0, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Color(0x26FFFFFF), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              if (badge > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.header, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text('$badge', style: appText(10, weight: w7, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = <_NavItem>[
    _NavItem('Inicio', Icons.home_outlined, Icons.home_rounded),
    _NavItem('Inventario', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _NavItem('Gráficos', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _NavItem('Perfil', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: i == currentIndex ? null : () => Nav.tab(context, i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == currentIndex ? _items[i].activeIcon : _items[i].icon,
                          size: 24,
                          color: i == currentIndex ? AppColors.primary : AppColors.textMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: appText(
                            11,
                            weight: i == currentIndex ? w6 : w5,
                            color: i == currentIndex ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
