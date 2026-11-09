import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/format.dart';

class PuntoGrafica {
  const PuntoGrafica(this.anio, this.valor);

  final int anio;
  final double valor;
}

/// Precio por año con la librería fl_chart: línea continua para el histórico,
/// punteada para el pronóstico (arranca en el último dato real) y, si se da,
/// otra línea punteada con el precio que tendría el producto si solo subiera
/// como la inflación. La distancia entre las dos punteadas es "qué tan caro".
class PredictionChart extends StatelessWidget {
  const PredictionChart({
    super.key,
    required this.historico,
    required this.pronostico,
    this.referencia = const [],
    this.height = 230,
  });

  final List<PuntoGrafica> historico;
  final List<PuntoGrafica> pronostico;

  /// Precio si el producto subiera exactamente como el IPC (ya incluye el punto de partida).
  final List<PuntoGrafica> referencia;
  final double height;

  static const Color colorReferencia = AppColors.donutNormal;

  @override
  Widget build(BuildContext context) {
    final todos = [...historico, ...pronostico, ...referencia];
    if (todos.length < 2) return SizedBox(height: height);

    final minX = todos.map((p) => p.anio).reduce(math.min).toDouble();
    final maxX = todos.map((p) => p.anio).reduce(math.max).toDouble();
    var minY = todos.map((p) => p.valor).reduce(math.min);
    var maxY = todos.map((p) => p.valor).reduce(math.max);
    final margen = (maxY - minY) * 0.12;
    minY -= margen == 0 ? 1 : margen;
    maxY += margen == 0 ? 1 : margen;
    final intervaloY = (maxY - minY) / 4;
    final intervaloX = (maxX - minX) > 8 ? 2.0 : 1.0;

    List<FlSpot> spots(List<PuntoGrafica> l) => [for (final p in l) FlSpot(p.anio.toDouble(), p.valor)];

    final ultimoReal = historico.isEmpty ? null : historico.last;
    final spotsPronostico = [
      if (ultimoReal != null) FlSpot(ultimoReal.anio.toDouble(), ultimoReal.valor),
      ...spots(pronostico),
    ];

    final sinTitulos = const AxisTitles(sideTitles: SideTitles(showTitles: false));

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: intervaloY,
            getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: sinTitulos,
            rightTitles: sinTitulos,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: intervaloY,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    formatCop(value),
                    textAlign: TextAlign.right,
                    style: appText(10, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: intervaloX,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${value.toInt()}', style: appText(10, color: AppColors.textSecondary)),
                ),
              ),
            ),
          ),
          lineBarsData: [
            if (historico.length >= 2)
              LineChartBarData(
                spots: spots(historico),
                isCurved: false,
                color: AppColors.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(radius: 3, color: AppColors.primary, strokeWidth: 0),
                ),
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withAlpha(22)),
              ),
            if (referencia.length >= 2)
              LineChartBarData(
                spots: spots(referencia),
                isCurved: false,
                color: colorReferencia,
                barWidth: 2.4,
                dashArray: [4, 5],
                dotData: const FlDotData(show: false),
              ),
            if (spotsPronostico.length >= 2)
              LineChartBarData(
                spots: spotsPronostico,
                isCurved: false,
                color: AppColors.warning,
                barWidth: 3,
                dashArray: [7, 5],
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) => ultimoReal == null || spot.x != ultimoReal.anio.toDouble(),
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 4.2,
                    color: AppColors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
