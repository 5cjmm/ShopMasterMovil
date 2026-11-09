/// Formatos en español de Colombia (miles con punto, decimales con coma).

/// 4500 -> "$4.500" (con [space], "$ 4.500").
String formatCop(num value, {bool space = false}) {
  final negative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}\$${space ? ' ' : ''}$buffer';
}

/// 4.2 -> "4,2".
String formatDecimal(double value, {int digits = 1}) {
  return value.toStringAsFixed(digits).replaceAll('.', ',');
}

/// 32.65 -> "32,7%".
String formatPercent(double value, {int digits = 1}) {
  return '${formatDecimal(value, digits: digits)}%';
}

/// 1 -> "1 unidad", 20 -> "20 unidades".
String formatUnidades(int n) => n == 1 ? '1 unidad' : '$n unidades';
