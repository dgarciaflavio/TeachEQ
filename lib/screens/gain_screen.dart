import 'package:flutter/material.dart';

/// Guia de ganho (gain staging) para o cenário: playback no PC pelo canal
/// estéreo, até 6 microfones sem fio e retornos no SEND.
class GainScreen extends StatelessWidget {
  const GainScreen({super.key});

  static const _etapas = [
    (
      'Por que isso importa',
      'Ganho errado é a causa número 1 de som sujo: baixo demais traz chiado; alto demais distorce. '
          'A regra é acertar o volume na ordem: fonte → ganho do canal → fader → MAIN. Só então equalizar.'
    ),
    (
      '1. Tudo no ponto de partida',
      'MAIN e faders no mínimo, equalizador plano (ou o preset do evento), efeito DSP com EFF RETURN baixo.'
    ),
    (
      '2. Computador (playback)',
      'Windows entre 80 e 90%, player em 100%, sem equalizador ou "melhorias" do Windows. '
          'Toque a música mais alta da playlist.'
    ),
    (
      '3. Canal estéreo do PC',
      'Suba o nível do canal até o medidor da mesa ficar perto de 0 nas partes mais fortes, sem acender o vermelho. '
          'Se distorcer com o canal baixo, baixe o volume do Windows.'
    ),
    (
      '4. Cada microfone sem fio',
      'Receptor com volume de saída no meio. Peça para a pessoa cantar o trecho mais forte, com o microfone a 2 ou 3 dedos da boca. '
          'Suba o GAIN do canal até o medidor ficar perto de 0. Repita para os 6, um de cada vez.'
    ),
    (
      '5. Faders e MAIN',
      'Com os ganhos certos, os faders dos canais trabalham perto da marca 0 e o MAIN também. '
          'Se precisar do MAIN no máximo, algum ganho ficou baixo.'
    ),
    (
      '6. Retornos (SEND)',
      'Suba o SEND de cada microfone e o SEND master até os cantores se ouvirem. '
          'Use o Analisador para achar o ponto em que começa a microfonia e fique um pouco abaixo.'
    ),
    (
      '7. Só agora: equalizar',
      'Comece pelo preset "Voz + playback" e use o Analisador para medir a sala. Corte antes de reforçar.'
    ),
    (
      'Durante o evento',
      'Ajuste o volume pelos faders, não pelo GAIN. Mexer no GAIN com o evento rolando muda tudo de uma vez e pode causar microfonia.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ganho certo')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _etapas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => Card(
          color: i == 0 ? cs.primaryContainer : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_etapas[i].$1,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: i == 0 ? cs.onPrimaryContainer : null)),
                const SizedBox(height: 6),
                Text(_etapas[i].$2,
                    style: TextStyle(color: i == 0 ? cs.onPrimaryContainer : null)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
