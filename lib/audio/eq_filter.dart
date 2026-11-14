import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_math.dart';

/// Filtro biquad "peaking" (RBJ Audio EQ Cookbook): reforça ou corta uma
/// faixa em volta de [hz], como um slider de equalizador gráfico.
class FiltroPico {
  FiltroPico(double hz, double ganhoDb, {double q = 1.2, int sampleRate = 44100}) {
    final a = math.pow(10, ganhoDb / 40).toDouble();
    final w0 = 2 * math.pi * hz / sampleRate;
    final alfa = math.sin(w0) / (2 * q);
    final cosw = math.cos(w0);
    final a0 = 1 + alfa / a;
    _b0 = (1 + alfa * a) / a0;
    _b1 = (-2 * cosw) / a0;
    _b2 = (1 - alfa * a) / a0;
    _a1 = (-2 * cosw) / a0;
    _a2 = (1 - alfa / a) / a0;
  }

  late final double _b0, _b1, _b2, _a1, _a2;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  void processar(Float64List x) {
    for (var i = 0; i < x.length; i++) {
      final entrada = x[i];
      final saida = _b0 * entrada + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
      _x2 = _x1;
      _x1 = entrada;
      _y2 = _y1;
      _y1 = saida;
      x[i] = saida;
    }
  }
}

/// Aplica os 7 sliders da mesa (dB, de 63Hz a 15KHz) a uma cópia do áudio.
/// Bandas em 0 dB são puladas.
Float64List aplicarEq(Float64List entrada, List<double> ganhosDb, {int sampleRate = 44100}) {
  final saida = Float64List.fromList(entrada);
  for (var b = 0; b < centrosBandas.length && b < ganhosDb.length; b++) {
    if (ganhosDb[b] == 0) continue;
    FiltroPico(centrosBandas[b], ganhosDb[b], sampleRate: sampleRate).processar(saida);
  }
  return saida;
}
