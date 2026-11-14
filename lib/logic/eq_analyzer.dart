import '../models/models.dart';

enum Gravidade { info, atencao, perigo }

class Alerta {
  const Alerta(this.gravidade, this.titulo, this.comoCorrigir, {this.banda});
  final Gravidade gravidade;
  final String titulo;
  final String comoCorrigir;

  /// Índice da banda envolvida (0 = 63Hz ... 6 = 15KHz), se houver uma só.
  final int? banda;
}

/// Analisa a curva de um banco e devolve alertas em ordem de gravidade.
/// Índices: 0=63Hz 1=150Hz 2=400Hz 3=1KHz 4=2.5KHz 5=6.4KHz 6=15KHz.
List<Alerta> analisarCurva(List<double> v, FuncaoBanco funcao) {
  assert(v.length == numBandas);
  final alertas = <Alerta>[];
  final retorno = funcao == FuncaoBanco.retornos;

  for (var i = 0; i < numBandas; i++) {
    if (v[i] >= 9) {
      alertas.add(Alerta(
        Gravidade.perigo,
        'Reforço extremo em ${_nome(i)}',
        'Acima de +9 dB a banda estoura o som e convida a microfonia. Volte para +3 ou menos e, se faltar algo, corte as outras bandas.',
        banda: i,
      ));
    }
  }

  if (v[0] >= 4) {
    alertas.add(const Alerta(
      Gravidade.perigo,
      'Subgrave alto: caixas podem distorcer',
      'Sem subwoofer, 63Hz reforçado consome a potência das caixas. Deixe em 0 ou corte.',
      banda: 0,
    ));
  }
  if (v[1] >= 5) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      'Som inchado',
      'Muito 150Hz deixa as vozes graves dentro de um tambor. Volte para 0 a +2.',
      banda: 1,
    ));
  }
  if (v[2] >= 3) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      'Risco de som abafado',
      '400Hz reforçado é a principal causa de som embolado. Experimente cortar de -2 a -5.',
      banda: 2,
    ));
  }
  if (v[3] >= 5) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      'Som nasal',
      '1KHz alto soa como rádio AM e apita com facilidade. Volte para 0 a +2.',
      banda: 3,
    ));
  }
  if (v[4] >= 6) {
    alertas.add(const Alerta(
      Gravidade.perigo,
      'Som áspero e risco de microfonia',
      '2.5KHz acima de +5 cansa o ouvido e apita. O ideal para voz é de +1 a +3.',
      banda: 4,
    ));
  }
  if (v[5] >= 5) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      '"S" cortante e microfonia aguda',
      '6.4KHz alto realça a sibilância dos microfones sem fio. Volte para 0 a +2.',
      banda: 5,
    ));
  }
  if (v[6] >= 7) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      'Chiado em evidência',
      '15KHz muito alto realça chiado e defeitos de MP3. +1 a +3 já dá o "ar".',
      banda: 6,
    ));
  }
  if (v[3] <= -6 && v[4] <= -6) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      'Voz sem inteligibilidade',
      'Com 1KHz e 2.5KHz muito cortados ninguém entende a letra. Volte pelo menos o 2.5KHz para perto de 0.',
    ));
  }

  final gravesAltos = v[0] >= 4 || v[1] >= 4;
  final agudosAltos = v[5] >= 4 || v[6] >= 4;
  final mediosCortados = v[2] <= -3 && v[3] <= -3;
  if (gravesAltos && agudosAltos && mediosCortados) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      'Curva "sorriso"',
      'Graves e agudos no alto com médios cortados impressionam por um minuto, mas cansam e escondem a voz. Traga 1KHz e 2.5KHz de volta para perto de 0.',
    ));
  }

  final somaReforcos =
      v.where((x) => x > 0).fold<double>(0, (acc, x) => acc + x);
  if (somaReforcos >= 20) {
    alertas.add(const Alerta(
      Gravidade.atencao,
      'Reforço demais no total',
      'Muitos sliders para cima somam volume e estouram a mesa. Corte o que sobra em vez de reforçar o que falta.',
    ));
  }

  final media = v.reduce((a, b) => a + b) / numBandas;
  if (media <= -6) {
    alertas.add(const Alerta(
      Gravidade.info,
      'Volume geral vai cair',
      'Com quase tudo cortado o som fica mais baixo. Compense no MAIN sem acender o LED vermelho.',
    ));
  }

  if (retorno) {
    if (v[0] > 0 || v[1] > 2) {
      alertas.add(const Alerta(
        Gravidade.atencao,
        'Grave no retorno',
        'Retorno não precisa de grave: só gasta potência e embola o palco. Corte 63Hz e 150Hz.',
      ));
    }
    if (v[3] >= 3 || v[4] >= 4) {
      alertas.add(const Alerta(
        Gravidade.atencao,
        'Retorno com risco de microfonia',
        'Os retornos ficam de frente para os microfones. Reforço em 1KHz ou 2.5KHz apita rápido.',
      ));
    }
  }

  if (alertas.isEmpty) {
    final plano = v.every((x) => x == 0);
    alertas.add(plano
        ? const Alerta(
            Gravidade.info,
            'Equalizador plano',
            'Bom ponto de partida. Ouça com música e voz conhecidas e corte primeiro o que incomodar.',
          )
        : const Alerta(
            Gravidade.info,
            'Curva equilibrada',
            'Nenhum exagero encontrado. Confirme ouvindo no volume real do evento.',
          ));
  }

  alertas.sort((a, b) => b.gravidade.index.compareTo(a.gravidade.index));
  return alertas;
}

const _nomes = ['63Hz', '150Hz', '400Hz', '1KHz', '2.5KHz', '6.4KHz', '15KHz'];
String _nome(int i) => _nomes[i];
