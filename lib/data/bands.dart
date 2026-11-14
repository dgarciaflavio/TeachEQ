/// Conteúdo didático das 7 bandas do equalizador gráfico da K-Audio HX-1202USB.
class BandInfo {
  const BandInfo({
    required this.rotulo,
    required this.apelido,
    required this.regiao,
    required this.oQueE,
    required this.soaComo,
    required this.excesso,
    required this.falta,
    required this.comoUsar,
    required this.noSeuSom,
    required this.dicasPorFaixa,
  });

  /// Texto exatamente como está impresso na mesa (ex.: "2.5KHz").
  final String rotulo;

  /// Nome curto e fácil de lembrar (ex.: "Voz clara").
  final String apelido;

  /// Região técnica (subgrave, grave, médio...).
  final String regiao;
  final String oQueE;
  final String soaComo;
  final String excesso;
  final String falta;
  final String comoUsar;

  /// Dica específica para o cenário de voz + playback com microfones sem fio.
  final String noSeuSom;

  /// 5 dicas: [corte forte, corte, neutro, reforço, reforço forte].
  final List<String> dicasPorFaixa;

  String dicaPara(double valor) => dicasPorFaixa[faixaDoValor(valor)];
}

/// 0 = corte forte (<= -7), 1 = corte (-6..-2), 2 = neutro (-1..+1),
/// 3 = reforço (+2..+5), 4 = reforço forte (>= +6).
int faixaDoValor(double v) {
  if (v <= -7) return 0;
  if (v <= -2) return 1;
  if (v <= 1) return 2;
  if (v <= 5) return 3;
  return 4;
}

const List<String> nomesFaixa = [
  'Corte forte',
  'Corte',
  'Neutro',
  'Reforço',
  'Reforço forte',
];

const List<BandInfo> bandas = [
  BandInfo(
    rotulo: '63Hz',
    apelido: 'Peso',
    regiao: 'Subgrave',
    oQueE:
        'É o grave que se sente no peito mais do que se ouve: a pancada do bumbo e o baixo eletrônico do playback.',
    soaComo: 'Pressão, ronco, o "tum" grave.',
    excesso:
        'Som embolado e retumbante, caixas distorcendo, barulho de mão no microfone e sopro muito audíveis, potência desperdiçada.',
    falta: 'Playback sem peso, som "magro", parecendo rádio de pilha.',
    comoUsar:
        'Em caixa sem subwoofer quase sempre fica em corte (-3 a -9). A voz não tem nada útil aqui, só barulho de manuseio e vento. Só reforce com subwoofer e ambiente aberto.',
    noSeuSom:
        'Nos microfones sem fio, o 63Hz carrega toque na mão, sopro e o "P" estourado. Cortar aqui limpa a voz sem ninguém perceber perda.',
    dicasPorFaixa: [
      'Corte forte: ótimo para caixas pequenas, retornos e lugares que ressoam. O playback perde a pancada, mas as caixas agradecem.',
      'Corte moderado: limpa ronco de manuseio e sobra potência. É o ponto mais usado para voz + playback.',
      'Neutro: o grave do playback chega como veio. Observe se as caixas distorcem nas músicas mais pesadas.',
      'Reforço leve: só em ambiente grande/aberto ou com caixas grandes. Fique de olho no LED +10.',
      'Perigo: reforço forte no subgrave consome a potência e distorce as caixas. Volte para 0 ou abaixo.',
    ],
  ),
  BandInfo(
    rotulo: '150Hz',
    apelido: 'Corpo',
    regiao: 'Grave',
    oQueE:
        'Dá corpo e calor: voz masculina, violão, a linha de baixo, a "cama" da música.',
    soaComo: 'Calor, voz encorpada.',
    excesso:
        'Som inchado, vozes graves parecendo dentro de um tambor. Piora quando o cantor cola o microfone na boca (efeito proximidade).',
    falta: 'Voz fina, sem corpo; playback frio.',
    comoUsar:
        'Geralmente entre -3 e 0. Se o cantor encosta o microfone na boca, o grave sobe sozinho: corte 2 a 3 dB.',
    noSeuSom:
        'É onde a voz e o baixo do playback brigam. Se as vozes masculinas soam abafadas, desconfie desta banda junto com 400Hz.',
    dicasPorFaixa: [
      'Corte forte: a voz fica fina, como telefone. Use só em emergência (retornos fazendo papel de PA) ou ambiente muito retumbante.',
      'Corte leve: tira o inchaço sem perder calor. Bom para salões fechados.',
      'Neutro: bom ponto. Se os cantores colam o microfone na boca, considere cortar 2 dB.',
      'Reforço: voz mais encorpada, mas embola rápido em ambiente fechado. Prefira 0.',
      'Excesso: som inchado e grave sobrando. Volte para 0 ou abaixo.',
    ],
  ),
  BandInfo(
    rotulo: '400Hz',
    apelido: 'Caixa de papelão',
    regiao: 'Médio-grave',
    oQueE:
        'A região que mais acumula sujeira: ressonância da sala e aquele som de caixa de papelão.',
    soaComo: 'Abafado, oco, sem definição.',
    excesso:
        'É o vilão do som sujo: tudo embola, a voz parece atrás de um cobertor e as palavras perdem definição.',
    falta: 'Som oco, "cavado" no meio.',
    comoUsar:
        'Um corte entre -2 e -6 é o ajuste que mais limpa o som. Desça devagar até o abafado sumir; se a voz ficar oca, volte 1 ou 2 dB.',
    noSeuSom:
        'Salões com paredes lisas acumulam 400Hz. Se o som está embolado mas o grave não parece exagerado, o problema está aqui.',
    dicasPorFaixa: [
      'Corte forte: pode deixar o som oco. Se a voz perdeu corpo, suba 2 dB.',
      'Faixa ideal: o abafado vai embora e as palavras ficam claras. Esse é o segredo do som limpo.',
      'Neutro: se o som parecer abafado ou embolado, este é o primeiro slider a descer.',
      'Reforço aqui raramente ajuda: o som tende a abafar. Volte para 0 ou corte.',
      'Excesso: som de caixa de papelão, tudo embolado. Corte já.',
    ],
  ),
  BandInfo(
    rotulo: '1KHz',
    apelido: 'Timbre',
    regiao: 'Médio',
    oQueE:
        'O centro da voz humana e do timbre dos instrumentos. É o "som de telefone".',
    soaComo: 'Nasal, buzina, presença.',
    excesso: 'Som nasal, agressivo e cansativo, parecendo rádio AM.',
    falta: 'Som distante; a voz parece que se afasta.',
    comoUsar:
        'Normalmente em 0, com ajustes pequenos (±2). Se a voz soa nasal ou fanhosa, corte 2 a 3 dB.',
    noSeuSom:
        'Uma das frequências comuns de microfonia em salão. Se ao subir o volume aparece um "uuuu" médio, baixe aqui.',
    dicasPorFaixa: [
      'Corte forte: a voz perde frente e fica distante. Use só para matar microfonia nesta faixa.',
      'Corte leve: tira o nasal e o som de telefone. Bom se a voz está agressiva.',
      'Neutro: a maioria dos ajustes deixa 1KHz aqui.',
      'Reforço leve: traz a voz para frente, mas cuidado com o som nasal.',
      'Excesso: som de rádio AM, cansativo e com risco de microfonia.',
    ],
  ),
  BandInfo(
    rotulo: '2.5KHz',
    apelido: 'Voz clara',
    regiao: 'Médio-agudo',
    oQueE:
        'Onde estão as consoantes que fazem a gente entender as palavras. O ouvido humano é mais sensível nesta faixa.',
    soaComo: 'Clareza, ataque, som "na cara".',
    excesso:
        'Som áspero e estridente que cansa e fura o ouvido; microfonia aguda.',
    falta: 'Dá para ouvir, mas não dá para entender a letra.',
    comoUsar:
        'Um reforço leve (+1 a +3) faz a voz aparecer sobre o playback. Acima de +5 o som fica áspero.',
    noSeuSom:
        'É a frequência que separa a voz do playback. Antes de subir, experimente cortar 400Hz: muitas vezes a clareza aparece sem reforçar nada.',
    dicasPorFaixa: [
      'Corte forte: as letras ficam difíceis de entender. Só use se houver microfonia nesta faixa.',
      'Corte: som macio, mas a voz pode sumir no playback.',
      'Neutro: se a voz estiver sumindo, um +2 aqui costuma resolver.',
      'Faixa ideal para voz: clareza sem aspereza.',
      'Excesso: som áspero e risco alto de microfonia. Volte para +3 ou menos.',
    ],
  ),
  BandInfo(
    rotulo: '6.4KHz',
    apelido: 'Brilho',
    regiao: 'Agudo',
    oQueE:
        'Brilho, definição dos pratos e chimbal, e o chiado dos "S", "T" e "X" (sibilância).',
    soaComo: 'Brilho, "ssss".',
    excesso:
        'Som estridente, "S" cortante, microfonia aguda e chiado do playback aparecendo.',
    falta: 'Som opaco, sem vida, como se viesse de trás de uma parede.',
    comoUsar:
        'Entre -2 e +2. Se os "S" das vozes machucam o ouvido, corte 2 a 4 dB.',
    noSeuSom:
        'Microfones sem fio costumam ter agudo exagerado. Cortar um pouco aqui suaviza as vozes.',
    dicasPorFaixa: [
      'Corte forte: som opaco. Use só se houver microfonia aguda persistente.',
      'Corte leve: domestica o "S" e o agudo dos microfones sem fio.',
      'Neutro: bom ponto. Escute os "S" das vozes: se machucarem, corte 2 dB.',
      'Reforço: mais brilho, mas aumenta a sibilância e o risco de microfonia.',
      'Excesso: som estridente e chiado. Volte para 0.',
    ],
  ),
  BandInfo(
    rotulo: '15KHz',
    apelido: 'Ar',
    regiao: 'Agudíssimo',
    oQueE:
        'O "ar" e a cintilação: brilho dos pratos, respiração, sensação de espaço.',
    soaComo: 'Ar, cintilância.',
    excesso:
        'Chiado constante, defeitos de MP3 de baixa qualidade, som artificial.',
    falta: 'Pouco perceptível; o som fica um pouco mais fechado.',
    comoUsar:
        'Mexa pouco. Um reforço leve (+1 a +3) dá acabamento. Se ouvir chiado constante, corte.',
    noSeuSom:
        'Playbacks de má qualidade (baixados de vídeo, MP3 comprimido) mostram defeitos aqui. Se o playback chia, corte 2 a 4 dB.',
    dicasPorFaixa: [
      'Corte forte: útil se o playback ou a mesa chiam muito. Pouca perda para a voz.',
      'Corte leve: suaviza chiado e playbacks de baixa qualidade.',
      'Neutro: tudo certo.',
      'Reforço leve: dá ar e acabamento ao som.',
      'Excesso: realça chiado e defeitos do playback.',
    ],
  ),
];
