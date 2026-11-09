/// Configuración de la app.
///
/// Según el contrato v1.1, para pasar del mock a la API real solo cambia
/// [apiBaseUrl]. Por defecto la app usa datos de ejemplo locales (sin red),
/// que responden igual que el contrato. Para usar el Postman Mock Server:
///
///   flutter run \
///     --dart-define=USE_MOCK=false \
///     --dart-define=API_BASE_URL=https://TU-ID.mock.pstmn.io
///
/// También puedes dejar la URL fija cambiando el `defaultValue` de abajo.
class AppConfig {
  AppConfig._();

  /// true = datos locales de ejemplo; false = servidor en [apiBaseUrl].
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  /// URL base del Postman Mock Server (o de la API en Render).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://REEMPLAZAR-CON-URL-DEL-MOCK.mock.pstmn.io',
  );

  /// Tiempo máximo de espera por petición. El plan gratis de Render "duerme" el
  /// servidor y tarda cerca de 50 s en despertar, así que 60 s evita falsos errores.
  static const Duration timeout = Duration(seconds: 60);
}
