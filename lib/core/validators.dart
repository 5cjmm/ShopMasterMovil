/// Reglas de validación compartidas por las pantallas y el servidor simulado.
/// Son las mismas que aplica la API (8 a 72 caracteres, con una letra y un número).
const String politicaPassword =
    'La contraseña debe tener entre 8 y 72 caracteres, con al menos una letra y un número.';

final RegExp _letra = RegExp(r'\p{L}', unicode: true);
final RegExp _digito = RegExp(r'\p{Nd}', unicode: true);

/// Devuelve el motivo si [password] no cumple la política, o null si es válida.
String? errorPassword(String password) {
  final ok = password.length >= 8 &&
      password.length <= 72 &&
      _letra.hasMatch(password) &&
      _digito.hasMatch(password);
  return ok ? null : politicaPassword;
}

bool esCodigoValido(String codigo) => RegExp(r'^\d{6}$').hasMatch(codigo);
