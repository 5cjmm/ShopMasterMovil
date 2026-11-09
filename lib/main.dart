import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_theme.dart';
import 'core/nav.dart';
import 'data/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Recupera el token y las preferencias guardadas en el dispositivo.
  await AppState.instance.cargar();
  // Si el servidor responde 401 en cualquier pantalla, vuelve al login.
  AppState.instance.alExpirarSesion = Nav.loginGlobal;

  runApp(const ShopMasterApp());
}

class ShopMasterApp extends StatelessWidget {
  const ShopMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopMaster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: Nav.key,
      home: AppState.instance.sesionIniciada ? const HomeScreen() : const LoginScreen(),
    );
  }
}
