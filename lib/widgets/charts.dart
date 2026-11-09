import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../data/models.dart';

// ---------------------------------------------------------------------------
// Utilidades de dibujo
// ---------------------------------------------------------------------------

/// Curva suave (Catmull-Rom convertida a Bézier cúbica) por los puntos dados.
Path smoothPath(List<Offset> p, {Path? into, bool moveToFirst = true}) {
  final path = into ?? Path();
  if (p.isEmpty) return path;
  if (moveToFirst) {
    path.moveTo(p.first.dx, p.first.dy);
  } else {
    path.lineTo(p.first.dx, p.first.dy);
  }
  for (var i = 0; i < p.length - 1; i++) {
    final p0 = i > 0 ? p[i - 1] : p[i];
    final p1 = p[i];
    final p2 = p[i + 1];
    final p3 = i + 2 < p.length ? p[i + 2] : p[i + 1];
    final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
    final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

void _drawText(
  Canvas canvas,
  String text,
  Offset anchor,
  TextStyle style, {
  TextAlign align = TextAlign.center,
  bool verticalCenter = false,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
  )..layout();
  var dx = anchor.dx;
  if (align == TextAlign.center) dx -= tp.width / 2;
  if (align == TextAlign.right || align == TextAlign.end) dx -= tp.width;
  final dy = verticalCenter ? anchor.dy - tp.height / 2 : anchor.dy;
  tp.paint(canvas, Offset(dx, dy));
}

final TextStyle _axisStyle = appText(11, color: AppColors.textMuted);

// ---------------------------------------------------------------------------
// Línea con área (Valor de inventario)
// ---------------------------------------------------------------------------

class AreaLineChart extends StatelessWidget {
  const AreaLineChart({super.key, required this.values, required this.labels, this.height = 170});

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _AreaLinePainter(values, labels)),
    );
  }
}

class _AreaLinePainter extends CustomPainter {
  _AreaLinePainter(this.values, this.labels);

  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const left = 8.0, right = 8.0, top = 12.0, bottom = 24.0;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    final pad = (maxV - minV) * 0.25;
    if (pad == 0) {
      minV -= 1;
      maxV += 1;
    } else {
      minV -= pad;
      maxV += pad;
    }

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = plot.top + plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    final pts = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = plot.left + plot.width * i / (values.length - 1);
      final y = plot.bottom - (values[i] - minV) / (maxV - minV) * plot.height;
      pts.add(Offset(x, y));
    }

    final line = smoothPath(pts);
    final area = Path.from(line)
      ..lineTo(pts.last.dx, plot.bottom)
      ..lineTo(pts.first.dx, plot.bottom)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x401D5FD1), Color(0x001D5FD1)],
        ).createShader(plot),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Punto final resaltado
    canvas.drawCircle(pts.last, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      pts.last,
      4.5,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill,
    );

    for (var i = 0; i < pts.length && i < labels.length; i++) {
      _drawText(canvas, labels[i], Offset(pts[i].dx, size.height - 18), _axisStyle);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaLinePainter old) => old.values != values || old.labels != labels;
}

// ---------------------------------------------------------------------------
// Donut (Nivel de stock)
// ---------------------------------------------------------------------------

class DonutSegment {
  const DonutSegment(this.valor, this.color);
  final double valor;
  final Color color;
}

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.segments, this.size = 130, this.stroke = 18, this.center});

  final List<DonutSegment> segments;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _DonutPainter(segments, stroke)),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.stroke);

  final List<DonutSegment> segments;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final total = segments.fold<double>(0, (s, e) => s + e.valor);

    final track = Paint()
      ..color = AppColors.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (total <= 0) return;

    const gap = 0.035; // radianes entre segmentos
    var start = -math.pi / 2;
    final visibles = segments.where((s) => s.valor > 0).length;
    for (final s in segments) {
      if (s.valor <= 0) continue;
      final full = s.valor / total * math.pi * 2;
      final sweep = visibles > 1 ? math.max(full - gap, 0.01) : full;
      canvas.drawArc(
        rect,
        start + (visibles > 1 ? gap / 2 : 0),
        sweep,
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += full;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments || old.stroke != stroke;
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label, this.value});

  final Color color;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: appText(13, color: AppColors.textSecondary)),
        if (value != null) ...[
          const SizedBox(width: 8),
          Text(value!, style: appText(13, weight: w6)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Barras horizontales (Productos con más stock)
// ---------------------------------------------------------------------------

class HBarList extends StatelessWidget {
  const HBarList({super.key, required this.items});

  final List<ProductoStock> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final maximo = items.map((e) => e.unidades).reduce(math.max);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(items[i].nombre, style: appText(13, weight: w5), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${items[i].unidades}', style: appText(13, weight: w7)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: AppColors.track),
                FractionallySizedBox(
                  widthFactor: maximo <= 0 ? 0 : (items[i].unidades / maximo).clamp(0.0, 1.0).toDouble(),
                  child: Container(height: 8, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Barras de la semana (Ventas últimos 7 días)
// ---------------------------------------------------------------------------

class WeekBarChart extends StatelessWidget {
  const WeekBarChart({super.key, required this.values, required this.labels, this.height = 150});

  final List<int> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maximo = values.isEmpty ? 0 : values.reduce(math.max);
    const areaLabels = 38.0; // valor arriba + etiqueta abajo
    final alto = height - areaLabels;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${values[i]}', style: appText(11, weight: w6, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    width: 22,
                    height: maximo <= 0 ? 4 : math.max(4.0, alto * values[i] / maximo),
                    decoration: BoxDecoration(
                      color: values[i] == maximo && maximo > 0 ? AppColors.primary : AppColors.scale2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(i < labels.length ? labels[i] : '', style: _axisStyle),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Radar (Cobertura por categoría)
// ---------------------------------------------------------------------------

class RadarChart extends StatelessWidget {
  const RadarChart({super.key, required this.items, this.height = 240});

  /// Porcentaje 0–100 por categoría; 100 es el objetivo (anillo exterior).
  final List<CategoriaValor> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _RadarPainter(items)),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.items);

  final List<CategoriaValor> items;

  @override
  void paint(Canvas canvas, Size size) {
    final n = items.length;
    if (n < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 34;
    if (radius <= 0) return;

    Offset punto(int i, double fraccion) {
      final ang = -math.pi / 2 + 2 * math.pi * i / n;
      return Offset(center.dx + math.cos(ang) * radius * fraccion, center.dy + math.sin(ang) * radius * fraccion);
    }

    final gridPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final nivel in const [0.25, 0.5, 0.75, 1.0]) {
      final path = Path()..moveTo(punto(0, nivel).dx, punto(0, nivel).dy);
      for (var i = 1; i < n; i++) {
        final p = punto(i, nivel);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        nivel == 1.0
            ? (Paint()
              ..color = AppColors.scale2
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5)
            : gridPaint,
      );
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, punto(i, 1), gridPaint);
    }

    final datos = Path();
    for (var i = 0; i < n; i++) {
      final f = (items[i].valor / 100).clamp(0.0, 1.0).toDouble();
      final p = punto(i, f);
      if (i == 0) {
        datos.moveTo(p.dx, p.dy);
      } else {
        datos.lineTo(p.dx, p.dy);
      }
    }
    datos.close();
    canvas.drawPath(datos, Paint()..color = const Color(0x401D5FD1));
    canvas.drawPath(
      datos,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < n; i++) {
      final f = (items[i].valor / 100).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(punto(i, f), 4, Paint()..color = AppColors.primary);
    }

    for (var i = 0; i < n; i++) {
      final p = punto(i, 1.0);
      final ang = -math.pi / 2 + 2 * math.pi * i / n;
      final fuera = Offset(p.dx + math.cos(ang) * 22, p.dy + math.sin(ang) * 16);
      _drawText(canvas, items[i].categoria, fuera - const Offset(0, 14), appText(12, weight: w6), verticalCenter: false);
      _drawText(canvas, '${items[i].valor.round()}%', fuera, appText(11, color: AppColors.textSecondary));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.items != items;
}

// ---------------------------------------------------------------------------
// Treemap (Productos por categoría)
// ---------------------------------------------------------------------------

class TreemapTile {
  const TreemapTile(this.indice, this.rect);
  final int indice;
  final Rect rect;
}

/// Reparte [rect] en proporción a [valores]. Divide recursivamente en dos
/// grupos de suma parecida, alternando el corte según el lado más largo.
List<TreemapTile> treemapLayout(List<double> valores, Rect rect) {
  final indices = List<int>.generate(valores.length, (i) => i)
    ..removeWhere((i) => valores[i] <= 0)
    ..sort((a, b) {
      final c = valores[b].compareTo(valores[a]);
      return c != 0 ? c : a.compareTo(b);
    });
  final salida = <TreemapTile>[];
  _dividir(indices, valores, rect, salida);
  return salida;
}

void _dividir(List<int> idx, List<double> v, Rect r, List<TreemapTile> out) {
  if (idx.isEmpty) return;
  if (idx.length == 1) {
    out.add(TreemapTile(idx.first, r));
    return;
  }
  final total = idx.fold<double>(0, (s, i) => s + v[i]);
  var acum = 0.0;
  var corte = 1;
  for (var k = 0; k < idx.length - 1; k++) {
    acum += v[idx[k]];
    corte = k + 1;
    if (acum >= total / 2) break;
  }
  final a = idx.sublist(0, corte);
  final b = idx.sublist(corte);
  final sumaA = a.fold<double>(0, (s, i) => s + v[i]);
  final fraccion = total <= 0 ? 0.5 : sumaA / total;

  if (r.width >= r.height) {
    final w = r.width * fraccion;
    _dividir(a, v, Rect.fromLTWH(r.left, r.top, w, r.height), out);
    _dividir(b, v, Rect.fromLTWH(r.left + w, r.top, r.width - w, r.height), out);
  } else {
    final h = r.height * fraccion;
    _dividir(a, v, Rect.fromLTWH(r.left, r.top, r.width, h), out);
    _dividir(b, v, Rect.fromLTWH(r.left, r.top + h, r.width, r.height - h), out);
  }
}

class TreemapView extends StatelessWidget {
  const TreemapView({super.key, required this.items, this.height = 210, this.colors, this.formatoValor});

  final List<CategoriaValor> items;
  final double height;

  /// Color de cada bloque (mismo orden que [items]). Si es nulo se usa la paleta de series.
  final List<Color>? colors;

  /// Cómo se escribe el valor de cada bloque; por defecto el número redondeado.
  final String Function(double valor)? formatoValor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, c) {
          final tiles = treemapLayout(items.map((e) => e.valor).toList(), Rect.fromLTWH(0, 0, c.maxWidth, height));
          return Stack(
            children: [
              for (final t in tiles)
                Positioned.fromRect(
                  rect: t.rect.deflate(1.5),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors != null ? colors![t.indice] : AppColors.seriesFor(t.indice),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            items[t.indice].categoria,
                            style: appText(13, weight: w6, color: colors != null ? Colors.white : _textoSobre(t.indice)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatoValor != null ? formatoValor!(items[t.indice].valor) : '${items[t.indice].valor.round()}',
                          style: appText(15, weight: w7, color: colors != null ? Colors.white : _textoSobre(t.indice)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Texto blanco sobre los tonos oscuros de AppColors.series (índices 0, 1 y 5).
Color _textoSobre(int indice) {
  final i = indice % AppColors.series.length;
  return (i <= 1 || i == 5) ? Colors.white : AppColors.navy;
}
