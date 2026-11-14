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
      );
}
