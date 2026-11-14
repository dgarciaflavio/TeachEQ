import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacheq/audio/audio_math.dart';
import 'package:teacheq/audio/feedback_detector.dart';
import 'package:teacheq/audio/signal_generator.dart';
import 'package:teacheq/audio/spectrum_processor.dart';

const sr = 44100;

List<double> seno(double hz, double segundos, {double amp = 1, double dbIni = 0, double dbFim = 0}) {
  final n = (segundos * sr).round();
  return [
    for (var i = 0; i < n; i++)
      amp *
          math.pow(10, (dbIni + (dbFim - dbIni) * i / n) / 20) *
          math.sin(2 * math.pi * hz * i / sr),
  ];
}

List<double> ruido(int n, double amp, {int semente = 3}) {
  final r = math.Random(semente);
  return [for (var i = 0; i < n; i++) (r.nextDouble() * 2 - 1) * amp];
}

List<double> somar(List<double> a, List<double> b) =>
    [for (var i = 0; i < a.length; i++) a[i] + b[i]];

List<DeteccaoMicrofonia> detectar(List<double> sinal) {
  final p = ProcessadorEspectro();
  final d = DetectorMicrofonia();
  final achados = <DeteccaoMicrofonia>[];
  for (final q in p.adicionar(sinal)) {
    final r = d.atualizar(q);
    if (r != null) achados.add(r);
  }
  return achados;
}

void main() {
  group('Processador', () {
    test('seno de amplitude 1 mede ~0 dBFS e o pico cai no bin certo', () {
      final p = ProcessadorEspectro();
      final quadros = p.adicionar(seno(1000, 0.5));
      expect(quadros, isNotEmpty);
      final q = quadros.last;
      expect(q.nivelDbfs, closeTo(0, 0.5));
      expect(q.nivelDbfsA, closeTo(0, 0.5)); // ponderação A ≈ 0 dB em 1 kHz
      var pico = 1;
      for (var k = 1; k < q.magDb.length; k++) {
        if (q.magDb[k] > q.magDb[pico]) pico = k;
      }
      expect(pico * q.binHz, closeTo(1000, q.binHz));
      expect(q.magDb[pico], closeTo(0, 1.5));
    });

    test('energia do tom aparece na banda certa da mesa', () {
      final q = ProcessadorEspectro().adicionar(seno(2500, 0.5)).last;
      var maior = 0;
      for (var b = 1; b < 7; b++) {
        if (q.bandasDbOitava[b] > q.bandasDbOitava[maior]) maior = b;
      }
      expect(maior, 4);
    });
  });

  group('Detector de microfonia', () {
    test('apito crescendo é detectado na frequência certa', () {
      final sinal = somar(seno(2437, 3, dbIni: -40, dbFim: -10), ruido(3 * sr, 0.01));
      final r = detectar(sinal);
      expect(r, isNotEmpty);
      expect(r.first.hz, closeTo(2437, 5));
      expect(r.first.banda, 4); // slider 2.5KHz
      expect(r.where((x) => x.nova), hasLength(1));
    });

    test('ruído branco não dispara', () {
      expect(detectar(ruido(3 * sr, 0.3)), isEmpty);
    });

    test('nota com harmônicos (voz/instrumento) não dispara', () {
      final n = 3 * sr;
      final sinal = List<double>.filled(n, 0);
      for (var h = 1; h <= 8; h++) {
        for (var i = 0; i < n; i++) {
          sinal[i] += 0.3 / h * math.sin(2 * math.pi * 330 * h * i / sr);
        }
      }
      expect(detectar(somar(sinal, ruido(n, 0.01))), isEmpty);
    });

    test('nota pura com ataque suave (1,6 s) não dispara', () {
      final n = (1.6 * sr).round();
      final nota = [
        for (var i = 0; i < n; i++)
          0.3 * math.min(1, i / (0.08 * sr)) * math.sin(2 * math.pi * 660 * i / sr),
      ];
      final sinal = [
        ...List<double>.filled(sr ~/ 2, 0),
        ...nota,
        ...List<double>.filled(sr, 0),
      ];
      expect(detectar(somar(sinal, ruido(sinal.length, 0.01))), isEmpty);
    });

    test('nota pura curta (1,2 s) não dispara', () {
      final sinal = [...seno(880, 1.2, amp: 0.3), ...List<double>.filled(sr, 0)];
      expect(detectar(somar(sinal, ruido(sinal.length, 0.01))), isEmpty);
    });
  });

  group('Bandas', () {
    test('frequência mapeia para o slider mais próximo', () {
      expect(bandaMaisProxima(70), 0);
      expect(bandaMaisProxima(800), 3);
      expect(bandaMaisProxima(3000), 4);
      expect(bandaMaisProxima(12000), 6);
    });

    test('ponderação A segue a norma', () {
      double db(double f) => 20 * math.log(ganhoPonderacaoA(f)) / math.ln10;
      expect(db(1000), closeTo(0, 0.1));
      expect(db(100), closeTo(-19.1, 0.2));
      expect(db(10000), closeTo(-2.5, 0.2));
    });

    test('sugestão corta excesso e não reforça os extremos', () {
      final s = sugerirCorrecao([-40, -30, -22, -30, -30, -30, -45]);
      expect(s[2], lessThan(0)); // 400Hz sobrando → corte
      expect(s[0], 0); // 63Hz baixo → não reforça
      expect(s[6], 0); // 15KHz baixo → não reforça
      expect(s.every((v) => v >= -6 && v <= 3), isTrue);
    });
  });

  group('Gerador', () {
    test('WAV tem cabeçalho válido e tamanho certo', () {
      final wav = montarWav(Float64List.fromList([0, 0.5, -0.5]));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(wav.length, 44 + 6);
    });

    test('ruído rosa respeita o pico pedido', () {
      final x = ruidoRosa(segundos: 1, picoDbfs: -6);
      final pico = x.fold<double>(0, (a, v) => math.max(a, v.abs()));
      expect(20 * math.log(pico) / math.ln10, closeTo(-6, 0.1));
    });

    test('ruído rosa tem energia parecida por oitava', () {
      final q = ProcessadorEspectro().adicionar(ruidoRosa(segundos: 2)).last;
      // Bandas centrais (150Hz a 6.4KHz) dentro de ±4 dB entre si.
      final centrais = q.bandasDbOitava.sublist(1, 6);
      final media = centrais.reduce((a, b) => a + b) / centrais.length;
      for (final v in centrais) {
        expect(v, closeTo(media, 4));
      }
    });
  });
}
