import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_math.dart';
import 'fft.dart';

/// Resultado da análise de um bloco de áudio.
class QuadroEspectro {
  QuadroEspectro({
    required this.magDb,
    required this.binHz,
    required this.nivelDbfs,
    required this.nivelDbfsA,
    required this.bandasDbOitava,
  });

  /// Magnitude em dBFS de cada bin (0..n/2). Um seno de amplitude máxima
  /// aparece perto de 0 dBFS.
  final Float64List magDb;
  final double binHz;

  /// Nível RMS do bloco (dBFS, alinhado para seno = 0 dBFS).
  final double nivelDbfs;

  /// Nível RMS com ponderação A (dBFS).
  final double nivelDbfsA;

  /// Energia de cada banda da mesa normalizada por oitava (dB).
  final List<double> bandasDbOitava;
}

/// Recebe amostras (−1..1) em qualquer tamanho de bloco e emite um quadro a
/// cada [hop] amostras, analisando janelas de [n] amostras.
class ProcessadorEspectro {
  ProcessadorEspectro({this.sampleRate = 44100, this.n = 4096, this.hop = 2048})
      : _fft = Fft(n),
        _janela = janelaHann(n),
        _buffer = Float64List(n),
        _re = Float64List(n),
        _im = Float64List(n) {
    var soma = 0.0;
    for (final w in _janela) {
      soma += w * w;
    }
    _somaJanela2 = soma;
    _ganhoA = Float64List(n ~/ 2 + 1);
    for (var k = 0; k <= n ~/ 2; k++) {
      final a = ganhoPonderacaoA(k * binHz);
      _ganhoA[k] = a * a;
    }
  }

  final int sampleRate;
  final int n;
  final int hop;
  final Fft _fft;
  final Float64List _janela;
  final Float64List _buffer;
  final Float64List _re;
  final Float64List _im;
  late final double _somaJanela2;
  late final Float64List _ganhoA;
  /// Buffer circular: [_pos] é onde entra a próxima amostra (a mais antiga).
  int _pos = 0;
  int _total = 0;
  int _desdeUltimo = 0;

  double get binHz => sampleRate / n;

  /// Adiciona amostras e devolve os quadros completados (normalmente 0 ou 1).
  List<QuadroEspectro> adicionar(List<double> amostras) {
    final saida = <QuadroEspectro>[];
    final mascara = n - 1;
    for (final s in amostras) {
      _buffer[_pos] = s;
      _pos = (_pos + 1) & mascara;
      _total++;
      _desdeUltimo++;
      if (_total >= n && _desdeUltimo >= hop) {
        _desdeUltimo = 0;
        saida.add(_analisar());
      }
    }
    return saida;
  }

  void reiniciar() {
    _pos = 0;
    _total = 0;
    _desdeUltimo = 0;
  }

  QuadroEspectro _analisar() {
    final mascara = n - 1;
    for (var i = 0; i < n; i++) {
      _re[i] = _buffer[(_pos + i) & mascara] * _janela[i];
      _im[i] = 0;
    }
    _fft.transform(_re, _im);

    final meio = n ~/ 2;
    final magDb = Float64List(meio + 1);
    final escala = 2 / _somaJanelaLinear;
    var potencia = 0.0;
    var potenciaA = 0.0;
    final energiaBanda = List<double>.filled(centrosBandas.length, 0);
    for (var k = 0; k <= meio; k++) {
      final p = _re[k] * _re[k] + _im[k] * _im[k];
      final mag = math.sqrt(p) * escala;
      magDb[k] = 20 * math.log(mag + 1e-12) / math.ln10;
      if (k == 0) continue;
      potencia += p;
      potenciaA += p * _ganhoA[k];
      final f = k * binHz;
      for (var b = 0; b < centrosBandas.length; b++) {
        if (f >= limitesBandas[b] && f < limitesBandas[b + 1]) {
          energiaBanda[b] += p;
          break;
        }
      }
    }
    // Parseval: rms² = (2/N)·Σ|X|² / Σw²; +3,01 dB alinha seno = 0 dBFS.
    double paraDbfs(double soma) =>
        10 * math.log(2 * soma / (n * _somaJanela2) + 1e-20) / math.ln10 + 3.01;

    return QuadroEspectro(
      magDb: magDb,
      binHz: binHz,
      nivelDbfs: paraDbfs(potencia),
      nivelDbfsA: paraDbfs(potenciaA),
      bandasDbOitava: [
        for (var b = 0; b < centrosBandas.length; b++)
          paraDbfs(energiaBanda[b]) - 10 * math.log(oitavasDaBanda(b)) / math.ln10,
      ],
    );
  }

  late final double _somaJanelaLinear = _janela.fold<double>(0, (a, w) => a + w);
}
