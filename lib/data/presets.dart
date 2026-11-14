/// Equalizações prontas. Valores em dB, na ordem 63Hz → 15KHz.
class Preset {
  const Preset({
    required this.id,
    required this.nome,
    required this.quando,
    required this.valores,
    this.personalizado = false,
  });

  final String id;
  final String nome;
  final String quando;
  final List<double> valores;
  final bool personalizado;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'quando': quando,
        'valores': valores,
      };

  factory Preset.fromJson(Map<String, dynamic> j) => Preset(
        id: j['id'] as String,
        nome: j['nome'] as String,
        quando: (j['quando'] as String?) ?? '',
        valores: (j['valores'] as List).map((e) => (e as num).toDouble()).toList(),
        personalizado: true,
      );
}

const List<Preset> presetsProntos = [
  Preset(
    id: 'plano',
    nome: 'Plano (ponto zero)',
    quando: 'Para começar do zero e ouvir o som real das caixas e do ambiente.',
    valores: [0, 0, 0, 0, 0, 0, 0],
  ),
  Preset(
    id: 'voz_playback',
    nome: 'Voz + playback',
    quando:
        'Padrão para cantar sobre playback em salão fechado. Tira o ronco e o abafado e destaca a voz.',
    valores: [-3, 0, -4, 0, 2, 0, 1],
  ),
  Preset(
    id: 'fala',
    nome: 'Fala / locução',
    quando:
        'Avisos, pregação, apresentação. Prioriza entender cada palavra; o grave quase não importa.',
    valores: [-6, -2, -3, 0, 3, 1, 0],
  ),
  Preset(
    id: 'playback_ambiente',
    nome: 'Só playback (som ambiente)',
    quando: 'Música de fundo antes e depois do evento, sem microfones abertos.',
    valores: [0, 1, -2, 0, 0, 1, 2],
  ),
  Preset(
    id: 'eco',
    nome: 'Ambiente com eco',
    quando:
        'Salão vazio, piso frio, paredes lisas. Corta o que mais reverbera e mantém a clareza.',
    valores: [-5, -3, -5, 0, 2, -1, -2],
  ),
  Preset(
    id: 'ar_livre',
    nome: 'Ar livre',
    quando:
        'Evento aberto: sem paredes, o grave some. Pode devolver um pouco de peso.',
    valores: [2, 2, -2, 0, 2, 1, 1],
  ),
  Preset(
    id: 'so_retornos',
    nome: 'Emergência: só retornos',
    quando:
        'As caixas PA pararam e os retornos viraram o som principal. Protege as caixas pequenas e reduz microfonia.',
    valores: [-9, -4, -3, 0, 2, -2, -3],
  ),
  Preset(
    id: 'anti_microfonia',
    nome: 'Anti-microfonia',
    quando:
        'Ponto seguro quando a microfonia insiste: corta de leve as faixas que mais apitam. Depois, ajuste banda a banda.',
    valores: [-3, -1, -3, -3, -2, -3, 0],
  ),
];
