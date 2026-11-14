import 'dart:math' as math;

/// Frequências centrais das 7 bandas da mesa (Hz), na ordem dos sliders.
const List<double> centrosBandas = [63, 150, 400, 1000, 2500, 6400, 15000];

/// Limites de cada banda: média geométrica entre centros vizinhos.
/// Banda i vai de limitesBandas[i] até limitesBandas[i + 1].
final List<double> limitesBandas = [
  20,
  for (var i = 0; i < centrosBandas.length - 1; i++)
    math.sqrt(centrosBandas[i] * centrosBandas[i + 1]),
  20000,
];

double log2(double x) => math.log(x) / math.ln2;

/// Largura de cada banda em oitavas (para comparar bandas de larguras diferentes).
double oitavasDaBanda(int i) => log2(limitesBandas[i + 1] / limitesBandas[i]);

/// Banda da mesa mais próxima da frequência, em distância logarítmica.
int bandaMaisProxima(double hz) {
  var melhor = 0;
  var dist = double.infinity;
  for (var i = 0; i < centrosBandas.length; i++) {
    final d = (log2(hz / centrosBandas[i])).abs();
    if (d < dist) {
      dist = d;
      melhor = i;
    }
  }
  return melhor;
}

/// Se a frequência cai praticamente no meio de duas bandas, devolve a outra
/// banda também (o usuário deve baixar as duas um pouco).
int? segundaBanda(double hz) {
  final b = bandaMaisProxima(hz);
  final dB = log2(hz / centrosBandas[b]).abs();
  final vizinha = hz > centrosBandas[b] ? b + 1 : b - 1;
  if (vizinha < 0 || vizinha >= centrosBandas.length) return null;
  final dV = log2(hz / centrosBandas[vizinha]).abs();
  return (dV - dB) < 0.3 ? vizinha : null;
}

/// Ganho linear da ponderação A (IEC 61672), ~1.0 em 1 kHz.
double ganhoPonderacaoA(double f) {
  if (f <= 0) return 0;
  final f2 = f * f;
  final numerador = 12194.0 * 12194.0 * f2 * f2;
  final denominador = (f2 + 20.6 * 20.6) *
      math.sqrt((f2 + 107.7 * 107.7) * (f2 + 737.9 * 737.9)) *
      (f2 + 12194.0 * 12194.0);
  return numerador / denominador * 1.2589254; // +2.00 dB
}

String formatarHz(double hz) {
  if (hz >= 1000) {
    final k = hz / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.', ',')} kHz';
  }
  return '${hz.round()} Hz';
}

/// Sugestão de equalização a partir de uma medição com ruído rosa (ou música
/// variada). [nivelPorOitava] = nível médio de cada banda em dB por oitava.
/// Devolve o ajuste sugerido para cada slider (em dB, inteiro).
///
/// Regras: corta metade do excesso (até -6), reforça pouco (até +3) e não
/// mexe em 63Hz e 15KHz por reforço, porque o microfone do celular é pouco
/// confiável nos extremos.
List<double> sugerirCorrecao(List<double> nivelPorOitava) {
  // Referência: média das bandas centrais (150Hz a 6.4KHz), onde o
  // microfone do celular é mais fiel.
  final centrais = nivelPorOitava.sublist(1, 6);
  final ref = centrais.reduce((a, b) => a + b) / centrais.length;
  return [
    for (var i = 0; i < nivelPorOitava.length; i++)
      () {
        final desvio = nivelPorOitava[i] - ref;
        if (desvio > 3) return (-(desvio / 2)).clamp(-6.0, 0.0).roundToDouble();
        final extremo = i == 0 || i == nivelPorOitava.length - 1;
        if (desvio < -4 && !extremo) {
          return (-(desvio / 2)).clamp(0.0, 3.0).roundToDouble();
        }
        return 0.0;
      }(),
  ];
}
