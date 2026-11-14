/// Roteiros de emergência para eventos com playback (PC no canal estéreo),
/// até 6 microfones sem fio e retornos ligados no SEND da mesa
/// (um retorno ligado no outro, um controle para os dois).
enum Categoria { caixas, microfonia, microfones, playback, energia, mixagem }

const Map<Categoria, String> nomesCategoria = {
  Categoria.caixas: 'Caixas e retornos',
  Categoria.microfonia: 'Microfonia',
  Categoria.microfones: 'Microfones sem fio',
  Categoria.playback: 'Playback / computador',
  Categoria.energia: 'Energia e ruídos',
  Categoria.mixagem: 'Mixagem e qualidade do som',
};

class Passo {
  const Passo(this.titulo, this.detalhe);
  final String titulo;
  final String detalhe;
}

class Emergencia {
  const Emergencia({
    required this.id,
    required this.titulo,
    required this.sintoma,
    required this.categoria,
    required this.passos,
    this.presetSugerido,
    this.prevencao = const [],
    this.relacionados = const [],
  });

  final String id;
  final String titulo;
  final String sintoma;
  final Categoria categoria;
  final List<Passo> passos;
  final String? presetSugerido;
  final List<String> prevencao;
  final List<String> relacionados;
}

const List<Emergencia> emergencias = [
  Emergencia(
    id: 'pa_parou',
    titulo: 'As caixas PA pararam (só os retornos funcionam)',
    sintoma: 'O público não ouve nada; só os retornos estão tocando.',
    categoria: Categoria.caixas,
    presetSugerido: 'so_retornos',
    passos: [
      Passo('Não suba o MAIN no desespero',
          'Baixe o fader MAIN até a metade. Se a caixa entrou em proteção por excesso de volume, subir só piora.'),
      Passo('Teste rápido (no máximo 2 minutos)',
          'Veja se o LED de energia das caixas ativas está aceso, se o cabo está firme na saída MAIN L/R e se a régua/tomada está ligada. Trocar o cabo L pelo R mostra se o defeito é o cabo ou a caixa.'),
      Passo('Transforme os retornos em PA',
          'Tire o cabo dos retornos da saída SEND e ligue na saída MAIN (L). Como um retorno está ligado no outro, os dois passam a tocar a mesma mistura do público, controlada pelo fader MAIN.'),
      Passo('Vire os retornos para o público',
          'Coloque-os o mais alto possível (tripé, mesa, cadeira) e o mais longe e à frente dos microfones. Nunca aponte a caixa para quem canta.'),
      Passo('Corte o grave',
          'Aplique o preset "Emergência: só retornos": 63Hz bem cortado e 150Hz em -4. Caixa pequena distorce rápido com grave.'),
      Passo('Microfones mais baixos, cantores mais perto',
          'As caixas agora estão perto dos microfones: o risco de microfonia aumentou. Peça para cantarem com o microfone a 2 ou 3 dedos da boca e baixe o fader de cada mic até o limite aceitável.'),
      Passo('Avise a equipe',
          'Quem canta ficou sem retorno. Combine que vão se guiar pelo som que volta da sala e evite subir o volume para compensar.'),
    ],
    prevencao: [
      'Leve um cabo P10 extra e uma régua extra.',
      'Saiba de antemão qual cabo vai da saída MAIN para cada caixa.',
    ],
    relacionados: ['microfonia', 'clip'],
  ),
  Emergencia(
    id: 'microfonia',
    titulo: 'Microfonia (apito ou zumbido crescente)',
    sintoma: 'Um apito agudo ou um "uuuu" que cresce sozinho.',
    categoria: Categoria.microfonia,
    presetSugerido: 'anti_microfonia',
    passos: [
      Passo('Corte na hora',
          'Baixe o fader do microfone que está aberto mais perto da caixa. Se não souber qual, baixe o MAIN um pouco.'),
      Passo('Descubra se vem do retorno',
          'Baixe o SEND master dos retornos. Se o apito parar, o problema está no retorno; se continuar, está no PA.'),
      Passo('Corrija a posição',
          'Nenhum microfone apontado para caixa ou retorno. Segure o microfone pelo corpo, sem cobrir a grelha (cobrir a grelha provoca microfonia).'),
      Passo('Ache a banda pelo som',
          'Apito fino e agudo: 2.5KHz ou 6.4KHz. "Uuuu" médio: 1KHz ou 400Hz. Ronco grave: 150Hz ou 63Hz. Baixe 3 dB na banda suspeita (no banco do PA ou do retorno, conforme o teste) e teste de novo.'),
      Passo('Feche microfones sem uso',
          'Com 6 microfones abertos o risco soma. Deixe o fader no mínimo (ou o microfone desligado) para quem não está cantando.'),
      Passo('Confira o efeito',
          'Reverb longo realimenta a microfonia. Baixe o EFF RETURN ou escolha um efeito mais curto.'),
    ],
    prevencao: [
      'Faça o teste de microfonia na passagem de som: suba cada microfone devagar até quase apitar e anote a banda.',
      'Posicione as caixas PA à frente da linha dos microfones.',
    ],
    relacionados: ['retorno_fraco'],
  ),
  Emergencia(
    id: 'zumbido_pc',
    titulo: 'Zumbido ou chiado constante',
    sintoma: 'Um "hummm" grave ou um chiado que não para, mesmo sem música.',
    categoria: Categoria.energia,
    passos: [
      Passo('Descubra a origem',
          'Desconecte o cabo do computador da mesa. Se o zumbido sumir, é o computador (geralmente loop de terra).'),
      Passo('Notebook: tire o carregador',
          'Teste o notebook só na bateria. Se o zumbido sumir, o problema é o aterramento do carregador.'),
      Passo('Mesma tomada',
          'Ligue mesa, computador e caixas na mesma régua. Tomadas diferentes com terras diferentes causam zumbido.'),
      Passo('Troque o cabo',
          'Cabo P2 x 2 P10 velho ou adaptador frouxo causam ruído e estalos. Use um cabo bom e bem encaixado.'),
      Passo('Chiado (não zumbido)? Acerte o ganho',
          'Volume do computador muito baixo e canal da mesa muito alto aumenta o chiado. Deixe o Windows em 80 a 90% e baixe o canal na mesa.'),
      Passo('Solução definitiva',
          'Um isolador de terra (ground loop isolator) P2 ou uma direct box resolve o zumbido do computador. Nunca corte o pino terra da tomada.'),
    ],
    prevencao: [
      'Tenha um isolador de terra P2 na bolsa de cabos.',
    ],
    relacionados: ['playback_baixo'],
  ),
  Emergencia(
    id: 'playback_um_lado',
    titulo: 'Playback saindo só de um lado',
    sintoma: 'Uma caixa toca a música e a outra não, ou falta algum instrumento.',
    categoria: Categoria.playback,
    passos: [
      Passo('Encaixe do cabo',
          'Plugue P2 meio encaixado no computador manda só um lado. Empurre até o fim.'),
      Passo('Botão BAL/PAN',
          'Confira se o balanço do canal estéreo do PC está no centro.'),
      Passo('Teste o cabo',
          'Troque os dois P10 de lugar na mesa (L no R). Se o defeito mudar de lado, é o cabo.'),
      Passo('Se o cabo falhar no meio do evento',
          'Ligue só o P10 que funciona na entrada L do canal estéreo. Em muitas mesas, a entrada L sozinha é enviada para os dois lados.'),
    ],
    relacionados: ['pa_parou'],
  ),
  Emergencia(
    id: 'playback_baixo',
    titulo: 'Playback baixo ou distorcido',
    sintoma: 'A música está fraca mesmo com o fader alto, ou soa estourada.',
    categoria: Categoria.playback,
    passos: [
      Passo('Volume do computador',
          'Windows entre 80 e 90% e o player em 100%. Volume baixo no PC obriga a subir a mesa e traz chiado.'),
      Passo('Distorcido? Baixe primeiro no PC',
          'Se a música estoura, baixe o volume do Windows para 70% e compense na mesa.'),
      Passo('Desligue "melhorias" de áudio',
          'Equalizador do player, "aprimoramentos" do Windows e "volume adaptativo" distorcem e mudam o som entre músicas.'),
      Passo('Músicas com volumes diferentes',
          'Antes do evento, normalize a playlist (função "normalizar" ou ReplayGain do player) para não ter que corrigir o fader a cada música.'),
    ],
    relacionados: ['clip'],
  ),
  Emergencia(
    id: 'pc_travou',
    titulo: 'O playback travou ou parou',
    sintoma: 'Silêncio no meio da música, ou o computador congelou.',
    categoria: Categoria.playback,
    passos: [
      Passo('Plano B pronto',
          'Tenha um celular com a mesma playlist ligado em outro canal estéreo da mesa, com o fader fechado. Se o PC travar, abra esse fader.'),
      Passo('Silêncio constrangedor',
          'Peça para quem está com o microfone falar com o público enquanto você resolve.'),
      Passo('Evite que aconteça',
          'Antes do evento: desative atualizações automáticas, ative o modo foco/"não perturbe" e desligue sons de notificação (eles saem nas caixas).'),
    ],
  ),
  Emergencia(
    id: 'mic_mudo',
    titulo: 'Microfone sem som',
    sintoma: 'Alguém fala e nada sai nas caixas.',
    categoria: Categoria.microfones,
    passos: [
      Passo('Microfone ligado e sem mute',
          'Confira a chave ON/OFF/MUTE do bastão. É a causa mais comum.'),
      Passo('Pilha',
          'Troque a pilha. Pilha fraca faz o microfone ligar e não transmitir.'),
      Passo('Receptor',
          'O LED de sinal (RF) do receptor acende quando a pessoa segura o microfone? Se não, o microfone e o receptor não estão pareados no mesmo canal.'),
      Passo('Canal da mesa',
          'Confira se o receptor está ligado no canal que você está mexendo, com GAIN e fader abertos.'),
      Passo('Troca rápida',
          'Entregue outro microfone que você sabe que funciona e resolva o defeito depois.'),
    ],
    prevencao: [
      'Use pilhas novas ou recarregáveis carregadas em todo evento.',
      'Etiquete microfone, receptor e canal da mesa com o mesmo número.',
    ],
    relacionados: ['mic_cortando'],
  ),
  Emergencia(
    id: 'mic_cortando',
    titulo: 'Microfone sem fio cortando ou chiando',
    sintoma: 'A voz falha, some por instantes ou vem com chiado.',
    categoria: Categoria.microfones,
    passos: [
      Passo('Pilha primeiro',
          'Pilha fraca é a primeira suspeita de corte. Troque.'),
      Passo('Antenas e visão',
          'Antenas do receptor em pé, receptor fora de case metálico e com "visão" do palco. Corpos e paredes bloqueiam o sinal.'),
      Passo('Microfones em canais próximos',
          'Com 6 microfones, frequências muito próximas se atrapalham. Configure cada par em um canal bem diferente.'),
      Passo('Interferência',
          'Afaste celulares, roteadores Wi-Fi e o próprio notebook dos receptores.'),
      Passo('Como segurar',
          'A mão cobrindo a base do bastão (onde fica a antena interna) enfraquece o sinal.'),
    ],
    relacionados: ['mic_mudo'],
  ),
  Emergencia(
    id: 'clip',
    titulo: 'LED vermelho acendendo / som distorcido',
    sintoma: 'O LED +10 acende e o som soa rasgado.',
    categoria: Categoria.mixagem,
    passos: [
      Passo('Ache o canal culpado',
          'Abaixe o GAIN do canal que está forte demais (o de quem canta mais alto ou o do PC), não o MAIN.'),
      Passo('Ganho certo',
          'Com a pessoa cantando forte, o medidor deve ficar perto de 0 e o vermelho não deve acender.'),
      Passo('Confira o equalizador',
          'Vários sliders reforçados somam volume e estouram. Prefira cortar o que sobra a reforçar o que falta.'),
      Passo('MAIN perto do 0 dB',
          'O fader MAIN deve trabalhar perto da marca 0. Se precisa dele no máximo, o ganho dos canais está baixo demais.'),
    ],
    relacionados: ['playback_baixo'],
  ),
  Emergencia(
    id: 'voz_some',
    titulo: 'A voz some por baixo do playback',
    sintoma: 'Dá para ouvir a música, mas não a letra de quem canta.',
    categoria: Categoria.mixagem,
    presetSugerido: 'voz_playback',
    passos: [
      Passo('Baixe a música antes de subir a voz',
          'Baixe o canal do PC 2 ou 3 dB. Subir a voz aumenta o risco de microfonia.'),
      Passo('Limpe o médio-grave',
          'Corte 400Hz de -3 a -5 no PA. Isso abre espaço para a voz.'),
      Passo('Clareza',
          'Suba 2.5KHz em +2.'),
      Passo('Técnica de microfone',
          'Microfone a 2 ou 3 dedos da boca. Longe da boca, a voz fica fraca e você precisa abrir mais ganho.'),
      Passo('Playback com voz-guia',
          'Se o playback tem voz gravada, ela compete com quem canta. Prefira versões instrumentais.'),
    ],
  ),
  Emergencia(
    id: 'retorno_fraco',
    titulo: 'Os cantores não se ouvem',
    sintoma: 'Reclamam que não ouvem a própria voz ou a música.',
    categoria: Categoria.caixas,
    passos: [
      Passo('SEND de cada microfone',
          'Confira o botão SEND de cada canal de microfone. O SEND master controla os dois retornos juntos.'),
      Passo('Música no retorno',
          'Suba o SEND do canal do PC (se o canal estéreo tiver SEND) só o suficiente para manter o tempo.'),
      Passo('Aponte certo',
          'O retorno deve apontar para a cabeça de quem canta, e o microfone ficar de costas para ele.'),
      Passo('Limite de microfonia',
          'Retorno alto demais apita. No banco do equalizador que controla os retornos, corte grave (63Hz e 150Hz) para ganhar volume sem microfonia.'),
    ],
    relacionados: ['microfonia'],
  ),
  Emergencia(
    id: 'embolado',
    titulo: 'Som embolado ou com eco',
    sintoma: 'Nada fica claro; as palavras se misturam com o eco da sala.',
    categoria: Categoria.mixagem,
    presetSugerido: 'eco',
    passos: [
      Passo('Volume geral menor',
          'Em sala com eco, mais volume significa mais eco. Baixe o MAIN um pouco.'),
      Passo('Efeito DSP',
          'Baixe o EFF RETURN ou escolha um efeito mais curto. A sala já tem reverb natural.'),
      Passo('Corte grave e médio-grave',
          'Aplique o preset "Ambiente com eco".'),
      Passo('Caixas',
          'Caixas mais altas, apontadas para o público e afastadas das paredes.'),
    ],
  ),
  Emergencia(
    id: 'queda_energia',
    titulo: 'Queda de energia / mesa desligou',
    sintoma: 'Tudo apagou ou a mesa reiniciou.',
    categoria: Categoria.energia,
    passos: [
      Passo('Ordem para religar',
          'Mesa e computador primeiro, com o MAIN no mínimo. Caixas e retornos por último. Ligar as caixas antes gera um estalo que pode danificar o alto-falante.'),
      Passo('Confira as configurações',
          'Veja se o efeito DSP voltou para o número certo (anote no projeto do evento).'),
      Passo('Volte o volume aos poucos',
          'Suba o MAIN devagar, com alguém falando no microfone.'),
      Passo('Para desligar no fim',
          'Caixas primeiro, mesa por último.'),
    ],
    prevencao: [
      'Um nobreak pequeno para mesa e computador evita perder o playback em quedas rápidas.',
    ],
  ),
  Emergencia(
    id: 'estalos',
    titulo: 'Estalos quando mexe em algum cabo',
    sintoma: 'Pipocos ou cortes quando alguém esbarra nos cabos.',
    categoria: Categoria.energia,
    passos: [
      Passo('Ache o cabo',
          'Mexa um cabo por vez, com cuidado, até o estalo aparecer.'),
      Passo('Troque ou isole',
          'Troque o cabo com mau contato. Se não houver reserva, fixe-o com fita para ninguém mexer até o fim.'),
      Passo('Prevenção',
          'Passe os cabos longe da passagem de pessoas e fixe com fita no chão.'),
    ],
  ),
];

Emergencia? emergenciaPorId(String id) {
  for (final e in emergencias) {
    if (e.id == id) return e;
  }
  return null;
}
