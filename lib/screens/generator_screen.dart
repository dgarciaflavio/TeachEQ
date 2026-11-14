import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/audio_math.dart';
import '../audio/audio_services.dart';
import '../data/bands.dart';

/// Gerador de sinais de teste: ruído rosa e tons nas frequências da mesa.
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _g = GeradorService.instance;
  double _volume = 0.5;
  double _posLivre = 0.5; // 0..1 em escala log de 40 Hz a 16 kHz

  // O sinal continua tocando ao sair desta tela, para medir no Analisador.
  double get _hzLivre => 40 * math.pow(400, _posLivre).toDouble();

  Future<void> _rosa() async {
    if (_g.tocando == 'Ruído rosa') {
      await _g.parar();
    } else {
      await _g.tocarRuidoRosa(volume: _volume);
    }
    setState(() {});
  }

  Future<void> _tom(double hz) async {
    final rotulo = 'Tom ${hz.round()} Hz';
    if (_g.tocando == rotulo) {
      await _g.parar();
    } else {
      await _g.tocarTom(hz, volume: _volume);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tocando = _g.tocando;
    return Scaffold(
      appBar: AppBar(title: const Text('Gerador de sinais')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          Card(
            color: cs.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Antes de tocar: MAIN da mesa baixo. Ligue o celular na mesa com um cabo P2 x 2 P10 '
                'em um canal estéreo livre (o mesmo do plano B do playback) e suba aos poucos. '
                'Sinal de teste alto demais pode danificar as caixas.',
                style: TextStyle(color: cs.onTertiaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.volume_up),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    _g.setVolume(v);
                  },
                ),
              ),
              Text('${(_volume * 100).round()}%'),
            ],
          ),
          if (tocando != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: cs.error, foregroundColor: cs.onError),
                onPressed: () async {
                  await _g.parar();
                  setState(() {});
                },
                icon: const Icon(Icons.stop),
                label: Text('Parar: $tocando'),
              ),
            ),
          Card(
            child: ListTile(
              leading: Icon(
                tocando == 'Ruído rosa' ? Icons.stop_circle : Icons.play_circle,
                size: 36,
                color: cs.primary,
              ),
              title: const Text('Ruído rosa'),
              subtitle: const Text(
                  'Som "chiado" com a mesma energia em todas as oitavas. Use para medir a sala no Analisador.'),
              onTap: _rosa,
            ),
          ),
          const SizedBox(height: 16),
          Text('Tons das bandas da mesa', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Teste as caixas (cada tom deve soar limpo, sem rasgar ou vibrar) e treine o ouvido para reconhecer cada slider.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < centrosBandas.length; i++)
                FilterChip(
                  label: Text(bandas[i].rotulo),
                  selected: tocando == 'Tom ${centrosBandas[i].round()} Hz',
                  onSelected: (_) => _tom(centrosBandas[i]),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Frequência livre', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _posLivre,
            onChanged: (v) => setState(() => _posLivre = v),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatarHz(_hzLivre)} · mais perto de ${bandas[bandaMaisProxima(_hzLivre)].rotulo}',
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _tom(_hzLivre.roundToDouble()),
                child: const Text('Tocar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dica: o alto-falante do celular não reproduz 63Hz e 150Hz. Para ouvir os graves, use fone de ouvido ou o cabo na mesa.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
