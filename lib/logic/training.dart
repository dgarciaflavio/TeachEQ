import 'dart:math' as math;

import '../models/models.dart';

enum Dificuldade { facil, medio, dificil }

const Map<Dificuldade, String> nomesDificuldade = {
  Dificuldade.facil: 'Fácil',
  Dificuldade.medio: 'Médio',
  Dificuldade.dificil: 'Difícil',
};

/// Tamanho da alteração de cada nível: quanto menor, mais difícil de ouvir.
double ganhoDoNivel(Dificuldade d) => switch (d) {
      Dificuldade.facil => 12,
      Dificuldade.medio => 9,
      Dificuldade.dificil => 6,
    };

/// Bandas sorteáveis. Sem fone de ouvido, o alto-falante do celular não
/// reproduz 63Hz e 150Hz, então elas ficam de fora.
List<int> bandasSorteaveis({required bool semGraves}) =>
    [for (var i = semGraves ? 2 : 0; i < numBandas; i++) i];

/// Exercício "Ache a banda": uma banda foi alterada; qual, e para cima ou baixo?
class DesafioBanda {
  const DesafioBanda({required this.banda, required this.ganhoDb});
  final int banda;
  final double ganhoDb;

  bool get reforco => ganhoDb > 0;

  List<double> get curva {
    final c = eqPlano();
    c[banda] = ganhoDb;
    return c;
  }

  bool confere(int bandaEscolhida, bool reforcoEscolhido) =>
      bandaEscolhida == banda && reforcoEscolhido == reforco;
}

DesafioBanda novoDesafioBanda(math.Random r, Dificuldade d, {bool semGraves = false}) {
  final opcoes = bandasSorteaveis(semGraves: semGraves);
  final banda = opcoes[r.nextInt(opcoes.length)];
  final g = ganhoDoNivel(d);
  return DesafioBanda(banda: banda, ganhoDb: r.nextBool() ? g : -g);
}

/// Exercício "Conserte o som": o som chega estragado em 1 a 3 bandas e o
/// usuário mexe nos sliders até ficar igual ao original.
class DesafioConserto {
  const DesafioConserto(this.estrago);
  final List<double> estrago;

  int get bandasAlteradas => estrago.where((v) => v != 0).length;
}

DesafioConserto novoConserto(math.Random r, Dificuldade d, {bool semGraves = false}) {
  final opcoes = bandasSorteaveis(semGraves: semGraves)..shuffle(r);
  final (quantas, ganhos) = switch (d) {
    Dificuldade.facil => (1, [9.0]),
    Dificuldade.medio => (2, [9.0, 6.0]),
    Dificuldade.dificil => (3, [6.0, 6.0, 9.0]),
  };
  final estrago = eqPlano();
  for (var i = 0; i < quantas; i++) {
    estrago[opcoes[i]] = r.nextBool() ? ganhos[i] : -ganhos[i];
  }
  return DesafioConserto(estrago);
}

class ResultadoConserto {
  const ResultadoConserto({required this.residuo, required this.nota});

  /// O que sobrou em cada banda depois do ajuste (estrago + ajuste).
  final List<double> residuo;

  /// 0 a 100.
  final int nota;

  /// Acertou se nenhuma banda ficou mais de 3 dB fora.
  bool get acertou => residuo.every((v) => v.abs() <= 3);
}

ResultadoConserto avaliarConserto(DesafioConserto d, List<double> ajuste) {
  final residuo = [for (var i = 0; i < numBandas; i++) d.estrago[i] + ajuste[i]];
  final erro = residuo.fold<double>(0, (a, v) => a + v.abs());
  final total = d.estrago.fold<double>(0, (a, v) => a + v.abs());
  final nota = total == 0 ? 100 : (100 * (1 - erro / total)).clamp(0, 100).round();
  return ResultadoConserto(residuo: residuo, nota: nota);
}
