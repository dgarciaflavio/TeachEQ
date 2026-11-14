import 'dart:math' as math;
import 'dart:typed_data';

const int taxaGerador = 44100;

/// Monta um WAV PCM 16 bits mono a partir de amostras −1..1.
Uint8List montarWav(Float64List amostras, {int sampleRate = taxaGerador}) {
  final dados = amostras.length * 2;
  final b = ByteData(44 + dados);
  void texto(int pos, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(pos + i, s.codeUnitAt(i));
    }
  }

  texto(0, 'RIFF');
  b.setUint32(4, 36 + dados, Endian.little);
  texto(8, 'WAVE');
  texto(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // mono
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  texto(36, 'data');
  b.setUint32(40, dados, Endian.little);
  for (var i = 0; i < amostras.length; i++) {
    final v = (amostras[i].clamp(-1.0, 1.0) * 32767).round();
    b.setInt16(44 + i * 2, v, Endian.little);
  }
  return b.buffer.asUint8List();
}

/// Ruído rosa (energia igual por oitava), método de Paul Kellet.
/// Pico normalizado em [picoDbfs]. Bordas com fade curto para o loop não estalar.
Float64List ruidoRosa({double segundos = 20, double picoDbfs = -6, int semente = 7}) {
  final n = (segundos * taxaGerador).round();
  final r = math.Random(semente);
  final out = Float64List(n);
  var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0, b6 = 0.0;
  for (var i = 0; i < n; i++) {
    final white = r.nextDouble() * 2 - 1;
    b0 = 0.99886 * b0 + white * 0.0555179;
    b1 = 0.99332 * b1 + white * 0.0750759;
    b2 = 0.96900 * b2 + white * 0.1538520;
    b3 = 0.86650 * b3 + white * 0.3104856;
    b4 = 0.55000 * b4 + white * 0.5329522;
    b5 = -0.7616 * b5 - white * 0.0168980;
    out[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
    b6 = white * 0.115926;
  }
  _normalizar(out, picoDbfs);
  _fadeBordas(out, (0.04 * taxaGerador).round());
  return out;
}

/// Seno contínuo para tocar em loop. A frequência é ajustada levemente para
/// caber um número inteiro de ciclos e o loop não estalar.
Float64List tomSenoidal(double hz, {double segundos = 2, double picoDbfs = -12}) {
  final n = (segundos * taxaGerador).round();
  final ciclos = math.max(1, (hz * n / taxaGerador).round());
  final f = ciclos * taxaGerador / n;
  final amp = math.pow(10, picoDbfs / 20).toDouble();
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    out[i] = amp * math.sin(2 * math.pi * f * i / taxaGerador);
  }
  return out;
}

/// Tom longo para o gerador, com entrada e saída suaves. Começar um seno de
/// repente gera um estalo (muito mais audível que o próprio tom em 63Hz e
/// 150Hz, que o alto-falante do celular quase não reproduz).
Float64List tomLongo(double hz, {double segundos = 30, double picoDbfs = -12}) {
  final out = tomSenoidal(hz, segundos: segundos, picoDbfs: picoDbfs);
  _fadeBordas(out, (0.04 * taxaGerador).round());
  return out;
}

/// Tom curto com ataque e fim suaves, para "ouvir a frequência" no guia.
Float64List tomCurto(double hz, {double segundos = 1.5, double picoDbfs = -12}) {
  final out = tomSenoidal(hz, segundos: segundos, picoDbfs: picoDbfs);
  _fadeBordas(out, (0.05 * taxaGerador).round());
  return out;
}

void _normalizar(Float64List x, double picoDbfs) {
  var pico = 0.0;
  for (final v in x) {
    pico = math.max(pico, v.abs());
  }
  if (pico == 0) return;
  final g = math.pow(10, picoDbfs / 20) / pico;
  for (var i = 0; i < x.length; i++) {
    x[i] *= g;
  }
}

void _fadeBordas(Float64List x, int tamanho) {
  final t = math.min(tamanho, x.length ~/ 2);
  for (var i = 0; i < t; i++) {
    final g = i / t;
    x[i] *= g;
    x[x.length - 1 - i] *= g;
  }
}
