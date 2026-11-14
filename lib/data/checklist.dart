class SecaoChecklist {
  const SecaoChecklist(this.titulo, this.itens);
  final String titulo;
  final List<String> itens;
}

const List<SecaoChecklist> checklist = [
  SecaoChecklist('Antes de sair de casa', [
    'Pilhas novas ou carregadas para os 6 microfones (e reserva)',
    'Cabo P2 x 2 P10 do computador e um reserva',
    'Cabos P10 das caixas e dos retornos, mais um reserva',
    'Régua de tomadas e extensão',
    'Isolador de terra P2 (contra zumbido)',
    'Playlist baixada no computador e cópia no celular (plano B)',
    'Carregador do notebook',
  ]),
  SecaoChecklist('Montagem', [
    'Caixas PA à frente da linha dos microfones, o mais alto possível',
    'Retornos apontados para quem canta',
    'Mesa, computador e caixas na mesma régua',
    'Ligar: mesa e computador primeiro, caixas por último',
    'Receptores com antenas em pé e longe do notebook e do roteador',
    'Microfone, receptor e canal da mesa etiquetados com o mesmo número',
  ]),
  SecaoChecklist('Computador', [
    'Windows entre 80 e 90%, player em 100%',
    'Atualizações automáticas pausadas',
    'Modo "não perturbe" ativado e sons de notificação desligados',
    'Equalizador e "melhorias" de áudio do Windows desligados',
    'Playlist normalizada (volumes parecidos entre músicas)',
  ]),
  SecaoChecklist('Passagem de som', [
    'Equalizador no preset do evento (ou no último ajuste salvo do local)',
    'Ganho de cada microfone: cantando forte, sem acender o vermelho',
    'Teste de microfonia: subir cada microfone devagar e anotar onde apita',
    'Retorno: cada cantor se ouve sem apitar',
    'Playback: tocar a música mais alta da lista e conferir o LED +10',
    'Número do efeito DSP e EFF RETURN anotados no projeto',
  ]),
  SecaoChecklist('Depois do evento', [
    'Desligar: caixas primeiro, mesa por último',
    'Anotar no projeto o que deu errado e como foi resolvido',
    'Salvar o equalizador final no projeto',
    'Pilhas recarregáveis para carregar',
  ]),
];
