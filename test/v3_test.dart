import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacheq/audio/eq_filter.dart';
import 'package:teacheq/audio/spectrum_processor.dart';
import 'package:teacheq/audio/training_audio.dart';
import 'package:teacheq/data/presets.dart';
import 'package:teacheq/logic/share_codec.dart';
import 'package:teacheq/logic/training.dart';
import 'package:teacheq/models/models.dart';

double rmsDb(Float64List x, {int pular = 0}) {
  var s = 0.0;
  for (var i = pular; i < x.length; i++) {
    s += x[i] * x[i];
  }
  return 10 * math.log(s / (x.length - pular)) / math.ln10;
}

Float64List seno(double hz, {int n = 44100}) =>
    Float64List.fromList([for (var i = 0; i < n; i++) 0.5 * math.sin(2 * math.pi * hz * i / 44100)]);

void main() {
  group('Filtro de equalização', () {
    test('reforço de +9 dB na frequência central', () {
      final x = seno(1000);
      final y = aplicarEq(x, [0, 0, 0, 9, 0, 0, 0]);
      // Ignora o início (transitório do filtro).
      expect(rmsDb(y, pular: 4410) - rmsDb(x, pular: 4410), closeTo(9, 0.3));
    });

    test('corte de -6 dB na frequência central', () {
      final x = seno(2500);
      final y = aplicarEq(x, [0, 0, 0, 0, -6, 0, 0]);
      expect(rmsDb(y, pular: 4410) - rmsDb(x, pular: 4410), closeTo(-6, 0.3));
    });

    test('EQ plano não altera o áudio', () {
      final x = seno(400);
      expect(aplicarEq(x, eqPlano()), orderedEquals(x));
    });

    test('banda vizinha quase não sente o filtro de outra', () {
      final x = seno(63);
      final y = aplicarEq(x, [0, 0, 0, 9, 0, 0, 0]); // 1KHz mexido
      expect((rmsDb(y, pular: 4410) - rmsDb(x, pular: 4410)).abs(), lessThan(0.5));
    });
  });

  group('Áudio de treino', () {
    test('batida tem energia em todas as bandas da mesa', () {
      final q = ProcessadorEspectro().adicionar(audioTreino(FonteTreino.musica)).last;
      for (final v in q.bandasDbOitava) {
        expect(v, greaterThan(-100));
      }
    });

    test('pico fica em -15 dBFS, com folga para reforços', () {
      for (final f in FonteTreino.values) {
        final x = audioTreino(f);
        final pico = x.fold<double>(0, (a, v) => math.max(a, v.abs()));
        expect(20 * math.log(pico) / math.ln10, closeTo(picoTreinoDbfs, 0.2), reason: '$f');
      }
    });
  });

  group('Exercícios', () {
    test('Ache a banda respeita "sem graves" e o nível', () {
      final r = math.Random(1);
      for (var i = 0; i < 50; i++) {
        final d = novoDesafioBanda(r, Dificuldade.medio, semGraves: true);
        expect(d.banda, greaterThanOrEqualTo(2));
        expect(d.ganhoDb.abs(), 9);
        expect(d.confere(d.banda, d.reforco), isTrue);
        expect(d.confere(d.banda, !d.reforco), isFalse);
      }
    });

    test('Conserte o som: corrigir exatamente dá nota 100', () {
      final d = novoConserto(math.Random(2), Dificuldade.dificil);
      expect(d.bandasAlteradas, 3);
      final ajuste = [for (final v in d.estrago) -v];
      final r = avaliarConserto(d, ajuste);
      expect(r.nota, 100);
      expect(r.acertou, isTrue);
    });

    test('Conserte o som: não mexer dá nota 0 e erro', () {
      final d = novoConserto(math.Random(3), Dificuldade.facil);
      final r = avaliarConserto(d, eqPlano());
      expect(r.nota, 0);
      expect(r.acertou, isFalse);
    });

    test('Conserte o som: até 3 dB de sobra conta como acerto', () {
      const d = DesafioConserto([0, 0, 9, 0, 0, 0, 0]);
      expect(avaliarConserto(d, [0, 0, -6, 0, 0, 0, 0]).acertou, isTrue);
      expect(avaliarConserto(d, [0, 0, -5, 0, 0, 0, 0]).acertou, isFalse);
    });
  });

  group('Compartilhamento', () {
    test('preset vai e volta pelo código', () {
      const p = Preset(id: 'x', nome: 'Salão', quando: 'domingo', valores: [-3, 0, -4, 0, 2, 0, 1]);
      final lido = decodificar(codificarPreset(p).codigo);
      expect(lido, isA<PresetLido>());
      final volta = (lido as PresetLido).preset;
      expect(volta.nome, 'Salão');
      expect(volta.valores, p.valores);
    });

    test('evento com mapa vai e volta', () {
      final mapa = MapaMesa();
      mapa.canais[0]
        ..nome = 'Mic 1 – Ana'
        ..tipo = TipoCanal.micSemFio;
      final p = Projeto(id: 'a', nome: 'Culto', local: 'Salão', efeitoDsp: 13, mapa: mapa);
      final pacote = codificarEvento(p);
      expect(pacote.codigo, startsWith(prefixoCodigo));
      expect(pacote.cortouNotas, isFalse);
      final volta = (decodificar(pacote.codigo) as EventoLido).projeto;
      expect(volta.nome, 'Culto');
      expect(volta.efeitoDsp, 13);
      expect(volta.id, isNot('a'));
      expect(volta.mapa!.canais[0].nome, 'Mic 1 – Ana');
      expect(volta.mapa!.emUso, 1);
    });

    test('anotações enormes saem do QR para caber', () {
      final r = math.Random(5);
      final texto = String.fromCharCodes([for (var i = 0; i < 5000; i++) 65 + r.nextInt(26)]);
      final p = Projeto(id: 'a', nome: 'Grande', notas: texto);
      final pacote = codificarEvento(p);
      expect(pacote.cortouNotas, isTrue);
      expect(pacote.codigo.length, lessThanOrEqualTo(limiteCaracteresQr));
    });

    test('mapa vai e volta, e texto aleatório é recusado', () {
      final m = MapaMesa()..canais[8].tipo = TipoCanal.computador;
      final volta = (decodificar(codificarMapa(m).codigo) as MapaLido).mapa;
      expect(volta.canais[8].tipo, TipoCanal.computador);
      expect(decodificar('oi, tudo bem?'), isNull);
      expect(decodificar('TEQ1:lixo'), isNull);
    });

    test('mapa gera texto só com canais em uso', () {
      final m = MapaMesa();
      m.canais[0]
        ..nome = 'Mic 1'
        ..tipo = TipoCanal.micSemFio
        ..detalhe = 'receptor A';
      final t = m.texto();
      expect(t, contains('Canal 1: Mic 1 (Microfone sem fio) · receptor A'));
      expect(t, isNot(contains('Canal 2')));
    });
  });
}
