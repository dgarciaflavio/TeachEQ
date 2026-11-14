import 'package:flutter_test/flutter_test.dart';
import 'package:teacheq/data/presets.dart';
import 'package:teacheq/logic/eq_analyzer.dart';
import 'package:teacheq/models/models.dart';

void main() {
  test('EQ plano gera apenas info de ponto de partida', () {
    final a = analisarCurva(eqPlano(), FuncaoBanco.pa);
    expect(a, hasLength(1));
    expect(a.first.gravidade, Gravidade.info);
    expect(a.first.titulo, 'Equalizador plano');
  });

  test('curva sorriso é detectada', () {
    final a = analisarCurva([6, 4, -4, -4, 0, 5, 6], FuncaoBanco.pa);
    expect(a.any((x) => x.titulo == 'Curva "sorriso"'), isTrue);
  });

  test('reforço extremo é perigo e vem primeiro', () {
    final a = analisarCurva([0, 0, 0, 0, 10, 0, 0], FuncaoBanco.pa);
    expect(a.first.gravidade, Gravidade.perigo);
    expect(a.first.banda, 4);
  });

  test('grave no retorno gera alerta só quando o banco é retorno', () {
    const v = [3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    expect(analisarCurva(v, FuncaoBanco.retornos)
        .any((x) => x.titulo == 'Grave no retorno'), isTrue);
    expect(analisarCurva(v, FuncaoBanco.pa)
        .any((x) => x.titulo == 'Grave no retorno'), isFalse);
  });

  test('presets prontos não disparam alertas de perigo', () {
    for (final p in presetsProntos) {
      final a = analisarCurva(p.valores, FuncaoBanco.pa);
      expect(a.where((x) => x.gravidade == Gravidade.perigo), isEmpty,
          reason: p.nome);
    }
  });
}
