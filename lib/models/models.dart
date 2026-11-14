/// Função de cada banco de sliders. A mesa tem dois bancos de 7 bandas; o
/// usuário informa no app o que cada um controla, porque isso muda as dicas.
enum FuncaoBanco { naoSei, pa, retornos, ladoL, ladoR }

const Map<FuncaoBanco, String> nomesFuncao = {
  FuncaoBanco.naoSei: 'Ainda não sei',
  FuncaoBanco.pa: 'PA (MAIN)',
  FuncaoBanco.retornos: 'Retornos (SEND)',
  FuncaoBanco.ladoL: 'Lado L do MAIN',
  FuncaoBanco.ladoR: 'Lado R do MAIN',
};

const int numBandas = 7;

List<double> eqPlano() => List<double>.filled(numBandas, 0);

List<double> lerValores(dynamic json) {
  if (json is! List || json.length != numBandas) return eqPlano();
  return json.map((e) => (e as num).toDouble().clamp(-12.0, 12.0).toDouble()).toList();
}

// ---------------------------------------------------------------------------
// Mapa de canais da mesa
// ---------------------------------------------------------------------------

enum TipoCanal { vazio, micSemFio, micComFio, computador, celular, instrumento, outro }

const Map<TipoCanal, String> nomesTipoCanal = {
  TipoCanal.vazio: 'Livre',
  TipoCanal.micSemFio: 'Microfone sem fio',
  TipoCanal.micComFio: 'Microfone com fio',
  TipoCanal.computador: 'Computador (playback)',
  TipoCanal.celular: 'Celular (plano B)',
  TipoCanal.instrumento: 'Instrumento',
  TipoCanal.outro: 'Outro',
};

class CanalMesa {
  CanalMesa({this.nome = '', this.tipo = TipoCanal.vazio, this.detalhe = ''});

  /// Ex.: "Mic 1 – Ana".
  String nome;
  TipoCanal tipo;

  /// Ex.: "Receptor A, canal 3, pilha recarregável".
  String detalhe;

  bool get emUso => tipo != TipoCanal.vazio;

  Map<String, dynamic> toJson() => {
        if (nome.isNotEmpty) 'n': nome,
        't': tipo.name,
        if (detalhe.isNotEmpty) 'd': detalhe,
      };

  factory CanalMesa.fromJson(Map<String, dynamic> j) => CanalMesa(
        nome: (j['n'] as String?) ?? '',
        tipo: TipoCanal.values.firstWhere(
          (t) => t.name == j['t'],
          orElse: () => TipoCanal.vazio,
        ),
        detalhe: (j['d'] as String?) ?? '',
      );

  CanalMesa copia() => CanalMesa(nome: nome, tipo: tipo, detalhe: detalhe);
}

class MapaMesa {
  MapaMesa({List<CanalMesa>? canais, this.saidas = saidasPadrao})
      : canais = canais ?? [for (var i = 0; i < 12; i++) CanalMesa()];

  static const String saidasPadrao =
      'MAIN L/R → caixas PA\nSEND → retornos (um ligado no outro)';

  final List<CanalMesa> canais;
  String saidas;

  int get emUso => canais.where((c) => c.emUso).length;

  String rotulo(int i) {
    final c = canais[i];
    return c.nome.isEmpty ? (c.emUso ? nomesTipoCanal[c.tipo]! : 'Livre') : c.nome;
  }

  /// Texto simples para mandar no WhatsApp ou imprimir como etiqueta.
  String texto() {
    final b = StringBuffer('Mapa da mesa\n');
    for (var i = 0; i < canais.length; i++) {
      final c = canais[i];
      if (!c.emUso) continue;
      b.write('Canal ${i + 1}: ${rotulo(i)}');
      if (c.nome.isNotEmpty) b.write(' (${nomesTipoCanal[c.tipo]})');
      if (c.detalhe.isNotEmpty) b.write(' · ${c.detalhe}');
      b.writeln();
    }
    if (saidas.isNotEmpty) b.write('\nSaídas:\n$saidas');
    return b.toString().trim();
  }

  Map<String, dynamic> toJson() => {
        'c': canais.map((c) => c.toJson()).toList(),
        's': saidas,
      };

  factory MapaMesa.fromJson(Map<String, dynamic> j) => MapaMesa(
        canais: ((j['c'] as List?) ?? const [])
            .map((e) => CanalMesa.fromJson(e as Map<String, dynamic>))
            .toList(),
        saidas: (j['s'] as String?) ?? saidasPadrao,
      );

  MapaMesa copia() =>
      MapaMesa(canais: canais.map((c) => c.copia()).toList(), saidas: saidas);
}

// ---------------------------------------------------------------------------
// Evento (projeto)
// ---------------------------------------------------------------------------

class Projeto {
  Projeto({
    required this.id,
    required this.nome,
    this.local = '',
    DateTime? data,
    List<double>? eqCima,
    List<double>? eqBaixo,
    this.efeitoDsp,
    this.effReturn = '',
    this.notas = '',
    this.problemas = '',
    this.mapa,
  })  : data = data ?? DateTime.now(),
        eqCima = eqCima ?? eqPlano(),
        eqBaixo = eqBaixo ?? eqPlano();

  final String id;
  String nome;
  String local;
  DateTime data;
  List<double> eqCima;
  List<double> eqBaixo;
  int? efeitoDsp;
  String effReturn;
  String notas;
  String problemas;

  /// Cópia do mapa de canais usado neste evento.
  MapaMesa? mapa;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'local': local,
        'data': data.toIso8601String(),
        'eqCima': eqCima,
        'eqBaixo': eqBaixo,
        'efeitoDsp': efeitoDsp,
        'effReturn': effReturn,
        'notas': notas,
        'problemas': problemas,
        if (mapa != null) 'mapa': mapa!.toJson(),
      };

  factory Projeto.fromJson(Map<String, dynamic> j) => Projeto(
        id: j['id'] as String,
        nome: (j['nome'] as String?) ?? 'Sem nome',
        local: (j['local'] as String?) ?? '',
        data: DateTime.tryParse((j['data'] as String?) ?? ''),
        eqCima: lerValores(j['eqCima']),
        eqBaixo: lerValores(j['eqBaixo']),
        efeitoDsp: (j['efeitoDsp'] as num?)?.toInt(),
        effReturn: (j['effReturn'] as String?) ?? '',
        notas: (j['notas'] as String?) ?? '',
        problemas: (j['problemas'] as String?) ?? '',
        mapa: j['mapa'] is Map<String, dynamic>
            ? MapaMesa.fromJson(j['mapa'] as Map<String, dynamic>)
            : null,
      );
}
