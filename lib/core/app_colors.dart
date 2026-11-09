import 'package:flutter/material.dart';

import '../data/models.dart';

/// Paleta tomada de las variables de color del prototipo en Figma ("Colores").
class AppColors {
  AppColors._();

  // Marca
  static const primary = Color(0xFF1D5FD1);
  static const navy = Color(0xFF0B2E6B);
  static const header = Color(0xFF0A2E78);

  // Superficies y bordes
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF3F6FB);
  static const field = Color(0xFFF5F7FB);
  static const track = Color(0xFFE3EAF6);
  static const accentSoft = Color(0xFFEAF1FF);
  static const border = Color(0xFFE6EBF3);
  static const divider = Color(0xFFDDE4EF);

  // Texto
  static const textSecondary = Color(0xFF6B7A90);
  static const textMuted = Color(0xFF8A94A6);
  static const placeholder = Color(0xFF7C8798);

  // Estados
  static const success = Color(0xFF1E8E4E);
  static const successBg = Color(0xFFDDF3E4);
  static const danger = Color(0xFFD93636);
  static const dangerStrong = Color(0xFFB91C1C);
  static const dangerBg = Color(0xFFFFE1E1);
  static const warning = Color(0xFFE08A00);
  static const warningBg = Color(0xFFFFF1D6);

  // Escala de intensidad (mapa de calor)
  static const scale1 = Color(0xFFD4E3FB);
  static const scale2 = Color(0xFF9DBEF0);
  static const scale3 = Color(0xFF7FA8EC);
  static const scale4 = Color(0xFF5489DF);

  // Donut de nivel de stock
  static const donutNormal = Color(0xFF2FB36D);
  static const donutBajo = Color(0xFFF5A524);
  static const donutSinStock = Color(0xFFE5484D);

  // Series por categoría (treemap): hasta 6 tonos de azul
  static const series = <Color>[
    Color(0xFF1D5FD1),
    Color(0xFF4F87DE),
    Color(0xFF7FA8EC),
    Color(0xFFA9C5F2),
    Color(0xFFD3E2FA),
    Color(0xFF0B2E6B),
  ];

  // Miniaturas de producto por categoría
  static const thumbGranos = Color(0xFFFBD9D9);
  static const thumbAceites = Color(0xFFFFE9B8);
  static const thumbGalletas = Color(0xFFF6C9A8);
  static const thumbLacteos = Color(0xFFD8E8FA);
  static const thumbAseo = Color(0xFFE3D9F7);
  static const thumbBebidas = Color(0xFFD5ECF6);
  static const thumbOtros = Color(0xFFE6EBF3);
  static const thumbIcon = Color(0x99565F7A);

  static Color thumbFor(String categoria) {
    switch (categoria) {
      case 'Granos':
        return thumbGranos;
      case 'Aceites':
        return thumbAceites;
      case 'Galletas':
        return thumbGalletas;
      case 'Lácteos':
        return thumbLacteos;
      case 'Aseo':
        return thumbAseo;
      case 'Bebidas':
        return thumbBebidas;
      default:
        return thumbOtros;
    }
  }

  static Color seriesFor(int index) => series[index % series.length];

  static Color estadoFg(EstadoStock e) {
    switch (e) {
      case EstadoStock.normal:
        return success;
      case EstadoStock.bajo:
        return danger;
      case EstadoStock.sinStock:
        return dangerStrong;
    }
  }

  static Color estadoBg(EstadoStock e) {
    switch (e) {
      case EstadoStock.normal:
        return successBg;
      case EstadoStock.bajo:
        return dangerBg;
      case EstadoStock.sinStock:
        return const Color(0xFFFFD3D3);
    }
  }
}
