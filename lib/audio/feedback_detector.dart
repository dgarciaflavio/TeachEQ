import 'dart:math' as math;

import 'audio_math.dart';
import 'spectrum_processor.dart';

class DeteccaoMicrofonia {
  const DeteccaoMicrofonia({
    required this.hz,
    required this.nivelDbfs,
    required this.banda,
    required this.banda2,
    required this.nova,
  });

  /// Frequência estimada do apito.
  final double hz;
  final double nivelDbfs;

  /// Slider da mesa a baixar (0 = 63Hz ... 6 = 15KHz).
  final int banda;

  /// Segundo slider, quando o apito cai entre duas bandas.
  final int? banda2;

  /// true só no primeiro quadro em que a microfonia foi confirmada.
  final bool nova;
}

/// Detecta microfonia no espectro: um pico estreito, quase sem harmônicos,
/// que fica parado na mesma frequência por vários quadros sem perder força.
/// Voz e música mudam de nota, têm vibrato e harmônicos, e por isso não passam.
class DetectorMicrofonia {
  DetectorMicrofonia({
    this.quadrosMinimos = 12,
    this.proeminenciaMinDb = 18,
    this.harmonicoMaxDb = -15,
    this.nivelMinDbfs = -60,
    this.fMin = 80,
    this.fMax = 12000,
  });

  /// Quadros seguidos com o mesmo pico (12 × ~46 ms ≈ 0,55 s).
  final int quadrosMinimos;

  /// Quanto o pico precisa estar acima do entorno (±1/3 de oitava).
  final double proeminenciaMinDb;

  /// O 2º harmônico precisa estar pelo menos isso abaixo do pico.
  final double harmonicoMaxDb;
  final double nivelMinDbfs;
  final double fMin;
  final double fMax;

  /// Sem crescimento, o pico precisa durar bem mais (40 × ~46 ms ≈ 1,8 s),
  /// para não confundir com uma nota longa e quase pura (flauta, assobio).
  static const int quadrosSemCrescimento = 40;
  static const double crescimentoMinDb = 3;
  static const int quadrosBase = 4;

  int? _bin;
  int _contagem = 0;
  double _nivelMax = -200;
  double _nivelInicial = -200;
  bool _confirmada = false;

  void reiniciar() => _semPico();

  DeteccaoMicrofonia? atualizar(QuadroEspectro q) {
    final mag = q.magDb;
    final binHz = q.binHz;
    final kMin = math.max(2, (fMin / binHz).ceil());
    final kMax = math.min(mag.length - 3, (fMax / binHz).floor());

    var pico = kMin;
    for (var k = kMin + 1; k <= kMax; k++) {
      if (mag[k] > mag[pico]) pico = k;
    }
    final nivel = mag[pico];

    if (!_ehTomPuro(mag, pico, binHz)) {
      _semPico();
      return null;
    }

    if (_bin != null && (pico - _bin!).abs() <= 1) {
      _contagem++;
      _nivelMax = math.max(_nivelMax, nivel);
      // Som que está morrendo (nota terminando) não é microfonia.
      if (nivel < _nivelMax - 6) {
        _semPico();
        return null;
      }
    } else {
      _bin = pico;
      _contagem = 1;
      _nivelMax = nivel;
      _nivelInicial = nivel;
      _confirmada = false;
    }
    _bin = pico;

    // A linha de base do crescimento é tirada no 4º quadro, quando o tom já
    // se firmou. Assim o ataque de uma nota (fade-in) não conta como
    // "crescendo" e não gera alarme falso.
    if (_contagem == quadrosBase) {
      _nivelInicial = nivel;
      _nivelMax = nivel;
    }

    if (_contagem < quadrosMinimos) return null;
    // Microfonia costuma crescer; sem crescimento, exige mais tempo parado.
    final cresceu = _contagem > quadrosBase &&
        _nivelMax - _nivelInicial >= crescimentoMinDb;
    if (!cresceu && _contagem < quadrosSemCrescimento) return null;

    final hz = _frequenciaInterpolada(mag, pico, binHz);
    final nova = !_confirmada;
    _confirmada = true;
    return DeteccaoMicrofonia(
      hz: hz,
      nivelDbfs: nivel,
      banda: bandaMaisProxima(hz),
      banda2: segundaBanda(hz),
      nova: nova,
    );
  }

  void _semPico() {
    _bin = null;
    _contagem = 0;
    _nivelMax = -200;
    _nivelInicial = -200;
    _confirmada = false;
  }

  bool _ehTomPuro(List<double> mag, int pico, double binHz) {
    final nivel = mag[pico];
    if (nivel < nivelMinDbfs) return false;

    // Entorno: média de potência em ±1/3 de oitava, sem os 3 bins do pico.
    final f = pico * binHz;
    final kIni = math.max(1, (f / 1.26 / binHz).floor());
    final kFim = math.min(mag.length - 1, (f * 1.26 / binHz).ceil());
    var soma = 0.0;
    var cont = 0;
    for (var k = kIni; k <= kFim; k++) {
      if ((k - pico).abs() <= 3) continue;
      soma += math.pow(10, mag[k] / 10).toDouble();
      cont++;
    }
    if (cont < 4) return false;
    final entorno = 10 * math.log(soma / cont) / math.ln10;
    if (nivel - entorno < proeminenciaMinDb) return false;

    // Harmônico: voz e instrumentos têm 2f forte; microfonia é quase pura.
    final k2 = pico * 2;
    if (k2 + 2 < mag.length) {
      var h = -200.0;
      for (var k = k2 - 2; k <= k2 + 2; k++) {
        h = math.max(h, mag[k]);
      }
      if (h - nivel > harmonicoMaxDb) return false;
    }
    return true;
  }

  /// Interpolação parabólica do pico (precisão melhor que 1 bin).
  double _frequenciaInterpolada(List<double> mag, int k, double binHz) {
    final a = mag[k - 1], b = mag[k], c = mag[k + 1];
    final den = a - 2 * b + c;
    final delta = den.abs() < 1e-9 ? 0.0 : 0.5 * (a - c) / den;
    return (k + delta.clamp(-0.5, 0.5).toDouble()) * binHz;
  }
}
