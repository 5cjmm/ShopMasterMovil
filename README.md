# ShopMaster Móvil (Flutter)

App móvil de ShopMaster enfocada en el **monitoreo del inventario**. Implementa las
pantallas del prototipo de Figma y consume la **ShopMaster API — Contrato v1.1**
(los 8 endpoints, con token Bearer, filtros y paginación).

> Esta carpeta trae el código Dart (`lib/`, `test/`, `assets/`, `pubspec.yaml`).
> Las carpetas de plataforma (`android/`, `ios/`…) se generan con el paso 1.

## Puesta en marcha

```bash
cd shopmaster_mobile
flutter create . --project-name shopmaster_mobile --org com.shopmaster   # 1. genera android/ ios/ ...
flutter pub get                                                          # 2. dependencias
```

Después configura Android para la huella (sección siguiente) y ejecuta:

```bash
flutter analyze     # revisión estática
flutter test        # pruebas (no necesitan teléfono)
flutter run         # ejecuta con datos de ejemplo locales
```

Si `flutter create` deja un `test/widget_test.dart` de ejemplo, bórralo (hace referencia a `MyApp`).

## Configurar Android para la huella (una sola vez)

La huella usa `local_auth` y el token y las credenciales viven en `flutter_secure_storage`.

1. **`android/app/src/main/AndroidManifest.xml`**: dentro de `<manifest>`, antes de `<application>`, agrega:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
   ```
2. **`android/app/src/main/kotlin/com/shopmaster/shopmaster_mobile/MainActivity.kt`**: reemplaza todo su contenido por:
   ```kotlin
   package com.shopmaster.shopmaster_mobile

   import io.flutter.embedding.android.FlutterFragmentActivity

   class MainActivity : FlutterFragmentActivity()
   ```
   (`local_auth` exige `FlutterFragmentActivity`. Si usaste otro `--org`, conserva la primera línea `package` que ya traía el archivo.)
3. Si al abrir la huella sale el error *"You need to use a Theme.AppCompat theme"*, en
   `android/app/src/main/res/values/styles.xml` cambia el `parent` de `LaunchTheme` y `NormalTheme` a
   `Theme.AppCompat.Light.NoActionBar` (y en `values-night/styles.xml` a `Theme.AppCompat.DayNight.NoActionBar`).

**iOS**: en `ios/Runner/Info.plist` agrega `NSFaceIDUsageDescription` con un texto como
"Usamos tu huella o rostro para entrar rápido a ShopMaster".

## Datos: simulados o Postman Mock Server

Por defecto la app usa un **servidor simulado local** (`MockApiClient`) que responde igual que el
contrato (con filtros, orden y paginación) usando los datos de referencia de la sección 6: 245 productos,
224 / 18 / 3, $2.486.700, +12 %, categorías 70 / 45 / 40 / 35 / 30 / 25. Los productos P001–P033 son los
de la colección de Postman.

Para usar el **Postman Mock Server** (sección 7 del contrato):

```bash
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://TU-ID.mock.pstmn.io
```

o deja la URL fija cambiando `defaultValue` en `lib/core/config.dart`. Para pasar a la API real solo
cambia esa URL.

Limitaciones del Mock Server de Postman (contrato 7): devuelve el Example guardado, **no aplica filtros,
orden ni paginación y no valida el token**. La búsqueda y los filtros se verán con los mismos datos de
ejemplo; con la API real el servidor los aplica. La app ya lo tolera (si el servidor repite la página, deja
de pedir más). Para probar errores agrega el encabezado `x-mock-response-code` desde Postman.

Credenciales del servidor simulado local: cualquier correo válido con cualquier contraseña. La contraseña
`incorrecta` devuelve 401 ("Correo o contraseña incorrectos") para probar ese caso.

| Endpoint | Pantalla |
|---|---|
| `POST /api/auth/login` | Acceso (y huella: repite este login) |
| `POST /api/auth/recuperar` | Recuperar contraseña |
| `GET /api/perfil` | Inicio (saludo) y Perfil |
| `GET /api/inventario/resumen` | Inicio, contadores de los chips del Inventario, Gráficos, Análisis |
| `GET /api/productos?q&categoria&estado&orden&pagina&tamano` | Inventario (búsqueda, filtros, orden, paginación) |
| `GET /api/productos/{id}` | Detalle |
| `GET /api/productos/stock-critico?estado&limite` | Alertas, Inicio (`estado=CRITICO&limite=2`) y avisos del Perfil |
| `GET /api/inventario/estadisticas` | Gráficos, Análisis y categorías del filtro |

## Huella y sesión

- La huella **no viaja al servidor**: `local_auth` confirma al dueño del teléfono y desbloquea las
  credenciales guardadas en `flutter_secure_storage` (Keystore); la app repite `POST /api/auth/login`.
- Las credenciales se guardan al iniciar sesión con contraseña si el teléfono tiene huella registrada y el
  interruptor «Acceso con huella» está activo. Se borran al apagar el interruptor. Cerrar sesión las conserva.
- El token (vigencia 1 h) se guarda en el almacenamiento seguro. Si el servidor responde 401 en cualquier
  pantalla, la app borra el token y vuelve al login con el aviso «Tu sesión venció».
- El interruptor de huella, las preferencias de notificaciones y el estado leído de los avisos se guardan
  solo en el dispositivo (contrato, sección 5).

## Errores (contrato, sección 8)

200 muestra los datos · 400 muestra el mensaje y conserva los filtros anteriores · 401 login: «Correo o
contraseña incorrectos», otras pantallas: cierra sesión · 403 «no tiene tienda asignada» · 404 «Producto no
encontrado» · 500 mensaje y botón Reintentar · sin conexión: aviso de que no hay red.

## Estructura

```
lib/
  main.dart
  core/      colores y tema (tokens de Figma), formatos COP, navegación, configuración
  data/      modelos (success/data, estados), cliente HTTP y simulado, repositorio con caché,
             estado de sesión, almacenamiento seguro y huella
  widgets/   cabecera azul + barra inferior, componentes comunes, gráficos (CustomPainter)
  screens/   login, huella, recuperar, inicio, inventario (+filtros), detalle, alertas,
             gráficos, análisis, perfil (+cierre de sesión)
```

## Fuera del alcance de la v1.1 (el contrato lo excluye)

Registrar ventas o compras, pestañas **Ventas** y **Compras** de Gráficos (muestran «muy pronto»),
**mapa de calor**, ventas por categoría y rotación (se quitaron de Análisis), **editar productos o perfil**
(los botones muestran un aviso), botones **+/−** de stock (se quitaron del detalle), crear cuenta y guardar
preferencias de notificaciones en el servidor.

## Notas

- Tipografía Inter incluida en `assets/fonts` (licencia OFL en `OFL-Inter.txt`).
- Los identificadores de producto se tratan como cadenas opacas (`P001` en el mock, ObjectId en la API real).
- Los campos opcionales (`codigoBarras`, `descripcion`, `presentacion`, `proveedor`, `ubicacion`,
  `variacionValorMensual`, `valorUltimosDias`) pueden venir `null`: la app muestra «—» u oculta el bloque.
