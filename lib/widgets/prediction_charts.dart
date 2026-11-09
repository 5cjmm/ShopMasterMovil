import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../data/models.dart';

/// Color del veredicto: rojo sube más que el IPC, ámbar a la par, verde sube menos.
Color colorVeredicto(VeredictoPrecio v) {
  switch (v) {
    case VeredictoPrecio.porEncima:
      return AppColors.danger;
    case VeredictoPrecio.enLinea:
      return AppColors.warning;
    case VeredictoPrecio.porDebajo:
      return AppColors.success;
  }
}

/// Primera palabra del nombre ("Arroz Diana x 500g" → "Arroz") para los ejes.
String nombreCorto(String nombre) {
  final palabras = nombre.trim().split(RegExp(r'\s+'));
  return palabras.isEmpty || palabras.first.isEmpty ? nombre : palabras.first;
}

/// Si hay más de [max] productos deja los extremos: los que más suben sobre el IPC
/// y los que menos (la lista llega ordenada de mayor a menor diferencia).
List<PanoramaProducto> seleccionarExtremos(List<PanoramaProducto> productos, {int max = 8}) {
  if (productos.length <= max) return productos;
  final mitad = max ~/ 2;
  return [...productos.take(mitad), ...productos.skip(productos.length - (max - mitad))];
}

/// Radar fl_chart: el polígono naranja es el aumento pronosticado de cada producto y el
/// verde es la inflación de referencia. Donde el naranja se sale del verde, el producto
/// sube más que el IPC.
class RadarPrediccion extends StatelessWidget {
  const RadarPrediccion({super.key, required this.productos, required this.ipcPct, this.height = 280});

  final List<PanoramaProducto> productos;
  final double ipcPct;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (productos.length < 3) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Text('Se necesitan al menos 3 productos para el radar.',
              style: appText(13, color: AppColors.textSecondary)),
        ),
      );
    }
    final etiquetas = [for (final p in productos) nombreCorto(p.nombre)];

    return SizedBox(
      height: height,
      width: double.infinity,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: appText(9, color: AppColors.textMuted),
          tickBorderData: const BorderSide(color: AppColors.divider),
          gridBorderData: const BorderSide(color: AppColors.divider),
          radarBorderData: const BorderSide(color: AppColors.scale2, width: 1.5),
          titleTextStyle: appText(11, weight: w6),
          titlePositionPercentageOffset: 0.14,
          getTitle: (index, angle) => RadarChartTitle(text: etiquetas[index % etiquetas.length]),
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.donutNormal.withAlpha(40),
              borderColor: AppColors.donutNormal,
              borderWidth: 2,
              entryRadius: 0,
              dataEntries: [for (var i = 0; i < productos.length; i++) RadarEntry(value: ipcPct < 0 ? 0 : ipcPct)],
            ),
            RadarDataSet(
              fillColor: AppColors.warning.withAlpha(60),
              borderColor: AppColors.warning,
              borderWidth: 2.4,
              entryRadius: 3,
              dataEntries: [
                for (final p in productos) RadarEntry(value: p.variacionPct < 0 ? 0 : p.variacionPct),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barras fl_chart con la diferencia (en puntos) entre el pronóstico y la inflación:
/// hacia arriba y rojas, el producto sube más que el IPC; hacia abajo y verdes, menos.
class BarrasDiferencia extends StatelessWidget {
  const BarrasDiferencia({super.key, required this.productos, this.height = 230});

  final List<PanoramaProducto> productos;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) return SizedBox(height: height);

    var maxAbs = 0.0;
    var hayNegativos = false;
    for (final p in productos) {
      if (p.diferenciaPuntos.abs() > maxAbs) maxAbs = p.diferenciaPuntos.abs();
      if (p.diferenciaPuntos < 0) hayNegativos = true;
    }
    if (maxAbs <= 0) maxAbs = 1;
    final techo = maxAbs * 1.25;
    const sinTitulos = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return SizedBox(
      height: height,
      width: double.infinity,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: techo,
          minY: hayNegativos ? -techo : 0,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: value == 0 ? AppColors.textMuted : AppColors.divider,
              strokeWidth: value == 0 ? 1.5 : 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: sinTitulos,
            rightTitles: sinTitulos,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    formatDecimal(value, digits: 0),
                    textAlign: TextAlign.right,
                    style: appText(10, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= productos.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 46,
                      child: Text(
                        nombreCorto(productos[i].nombre),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(10, color: AppColors.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < productos.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: productos[i].diferenciaPuntos,
                    width: 16,
                    color: colorVeredicto(productos[i].veredicto),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
