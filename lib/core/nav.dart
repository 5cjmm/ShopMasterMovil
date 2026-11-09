import 'package:flutter/material.dart';

import '../data/models.dart';
import '../screens/alerts_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/biometric_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/charts_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/prediction_overview_screen.dart';
import '../screens/prediction_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recover_screen.dart';
import '../screens/reset_password_screen.dart';

/// Navegación centralizada (Navigator.push / pop, como en el documento de
/// navegación). Las 4 pestañas se reemplazan entre sí sin acumular pantallas.
class Nav {
  Nav._();

  /// Permite navegar sin contexto (por ejemplo cuando el servidor responde 401).
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Vuelve al login desde cualquier pantalla (sesión vencida).
  static void loginGlobal() {
    key.currentState?.pushAndRemoveUntil(_fade<void>(const LoginScreen()), (route) => false);
  }

  static Route<T> _fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondary) => page,
      transitionDuration: const Duration(milliseconds: 160),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static Widget _tabPage(int index) {
    switch (index) {
      case 1:
        return const InventoryScreen();
      case 2:
        return const ChartsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  /// Cambia de pestaña (Inicio, Inventario, Gráficos, Perfil).
  static void tab(BuildContext context, int index) {
    Navigator.of(context).pushAndRemoveUntil(_fade<void>(_tabPage(index)), (route) => false);
  }

  /// Inventario con un filtro de estado ya aplicado (desde Inicio).
  static void inventario(BuildContext context, {EstadoStock? estado}) {
    Navigator.of(context).pushAndRemoveUntil(
      _fade<void>(InventoryScreen(estadoInicial: estado)),
      (route) => false,
    );
  }

  // --- Acceso -------------------------------------------------------------

  static void entrar(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(_fade<void>(const HomeScreen()), (route) => false);
  }

  static void login(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(_fade<void>(const LoginScreen()), (route) => false);
  }

  static void recuperar(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecoverScreen()));
  }

  /// Paso 2 de la recuperación: código del correo + nueva contraseña.
  static void restablecer(BuildContext context, String email) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ResetPasswordScreen(email: email)));
  }

  static void huella(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BiometricScreen()));
  }

  // --- Secciones ----------------------------------------------------------

  static void detalle(BuildContext context, Producto producto) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProductDetailScreen(productoId: producto.id, inicial: producto)),
    );
  }

  static void chat(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChatScreen()));
  }

  static void prediccion(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PredictionScreen()));
  }

  static void panoramaPrediccion(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PredictionOverviewScreen()));
  }

  static void cambiarPassword(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()));
  }

  static void alertas(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AlertsScreen()));
  }

  static void analisis(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AnalysisScreen()));
  }

  static void volver(BuildContext context) => Navigator.of(context).pop();
}
