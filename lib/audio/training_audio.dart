import 'dart:math' as math;
import 'dart:typed_data';

import 'signal_generator.dart';

/// Áudios de treino gerados pelo próprio app (sem músicas protegidas por
/// direitos autorais e sem precisar de internet).
enum FonteTreino { musica, ruidoRosa }

const Map<FonteTreino, String> nomesFonte = {
  FonteTreino.musica: 'Batida sintética',
  FonteTreino.ruidoRosa: 'Ruído rosa',
};

/// Pico dos áudios de treino. Deixa folga para reforços de até +12 dB sem
/// estourar, e o volume original e o equalizado ficam comparáveis.
const double picoTreinoDbfs = -15;

final Map<FonteTreino, Float64List> _cache = {};

Float64List audioTreino(FonteTreino fonte) => _cache[fonte] ??= switch (fonte) {
      FonteTreino.ruidoRosa => ruidoRosa(segundos: 4, picoDbfs: picoTreinoDbfs),
      FonteTreino.musica => _batida(),
    };

/// Loop de 2 compassos a 100 BPM: bumbo, baixo, acordes, chimbal e caixa.
/// Cobre todas as bandas da mesa, do 63Hz (bumbo) ao 15KHz (chimbal).
Float64List _batida() {
  const sr = taxaGerador;
  const bpm = 100.0;
  final tempo = 60 / bpm; // segundos por tempo
  final n = (tempo * 8 * sr).round(); // 8 tempos
  final x = Float64List(n);
  final r = math.Random(11);

  void somar(int inicio, Float64List s) {
    for (var i = 0; i < s.length && inicio + i < n; i++) {
      x[inicio + i] += s[i];
    }
  }

  // Bumbo: seno com queda de afinação 110 → 45 Hz.
  Float64List bumbo() {
    final len = (0.35 * sr).round();
    final s = Float64List(len);
    var fase = 0.0;
    for (var i = 0; i < len; i++) {
      final t = i / sr;
      final f = 45 + 65 * math.exp(-t * 30);
      fase += 2 * math.pi * f / sr;
      s[i] = math.sin(fase) * math.exp(-t * 9) * 0.9;
    }
    return s;
  }

  // Caixa: ruído com corpo em 190 Hz.
  Float64List caixa() {
    final len = (0.22 * sr).round();
    final s = Float64List(len);
    for (var i = 0; i < len; i++) {
      final t = i / sr;
      s[i] = ((r.nextDouble() * 2 - 1) * 0.45 + math.sin(2 * math.pi * 190 * t) * 0.35) *
          math.exp(-t * 18);
    }
    return s;
  }

  // Chimbal: ruído agudo (diferença de amostras = passa-altas simples).
  Float64List chimbal() {
    final len = (0.06 * sr).round();
    final s = Float64List(len);
    var ant = 0.0;
    for (var i = 0; i < len; i++) {
      final b = r.nextDouble() * 2 - 1;
      s[i] = (b - ant) * 0.18 * math.exp(-i / sr * 60);
      ant = b;
    }
    return s;
  }

  // Nota com harmônicos (baixo e acordes), envelope suave.
  Float64List nota(double hz, double dur, double amp, int harmonicos) {
    final len = (dur * sr).round();
    final s = Float64List(len);
    for (var i = 0; i < len; i++) {
      final t = i / sr;
      final env = math.min(1.0, t / 0.01) * math.min(1.0, (dur - t) / 0.05);
      var v = 0.0;
      for (var h = 1; h <= harmonicos; h++) {
        v += math.sin(2 * math.pi * hz * h * t) / h;
      }
      s[i] = v * amp * env;
    }
    return s;
  }

  int pos(double tempos) => (tempos * tempo * sr).round();

  final kick = bumbo(), snare = caixa(), hat = chimbal();
  for (var t = 0; t < 8; t++) {
    if (t % 2 == 0) somar(pos(t.toDouble()), kick);
    if (t % 2 == 1) somar(pos(t.toDouble()), snare);
    somar(pos(t.toDouble()), hat);
    somar(pos(t + 0.5), hat);
  }
  // Baixo: Lá, Lá, Fá, Sol (110, 87 e 98 Hz), com harmônicos até ~600 Hz.
  const baixo = [110.0, 110.0, 87.31, 98.0];
  for (var c = 0; c < 4; c++) {
    somar(pos(c * 2.0), nota(baixo[c], tempo * 1.9, 0.22, 6));
  }
  // Acordes (Lá menor, Fá maior) na região média.
  const acordes = [
    [440.0, 523.25, 659.25],
    [349.23, 440.0, 523.25],
  ];
  for (var c = 0; c < 2; c++) {
    for (final hz in acordes[c]) {
      somar(pos(c * 4.0), nota(hz, tempo * 3.8, 0.06, 5));
    }
  }

  var pico = 0.0;
  for (final v in x) {
    pico = math.max(pico, v.abs());
  }
  final g = math.pow(10, picoTreinoDbfs / 20) / pico;
  for (var i = 0; i < n; i++) {
    x[i] *= g;
  }
  return x;
}
