import 'package:flutter/material.dart';

import '../data/presets.dart';
import '../state/app_state.dart';
import '../widgets/mini_curve.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Presets')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final p in s.todosPresets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CartaoPreset(preset: p),
              ),
            if (s.presetsPersonalizados.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Dica: no Equalizador, use o menu ⋮ → "Salvar como preset" para guardar os seus ajustes.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartaoPreset extends StatelessWidget {
  const _CartaoPreset({required this.preset});
  final Preset preset;

  String _fmt(double v) => v > 0 ? '+${v.toInt()}' : '${v.toInt()}';

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(preset.nome,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (preset.personalizado)
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Excluir "${preset.nome}"?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar')),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Excluir')),
                          ],
                        ),
                      );
                      if (ok == true) s.excluirPreset(preset.id);
                    },
                  ),
              ],
            ),
            if (preset.quando.isNotEmpty)
              Text(preset.quando, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            MiniCurve(valores: preset.valores),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final v in preset.valores)
                  Expanded(
                    child: Text(_fmt(v),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _aplicar(context, [0]),
                  child: const Text('Banco de cima'),
                ),
                OutlinedButton(
                  onPressed: () => _aplicar(context, [1]),
                  child: const Text('Banco de baixo'),
                ),
                FilledButton.tonal(
                  onPressed: () => _aplicar(context, [0, 1]),
                  child: const Text('Os dois'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _aplicar(BuildContext context, List<int> bancos) {
    final s = AppState.instance;
    for (final b in bancos) {
      s.aplicarValores(b, preset.valores);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${preset.nome}" aplicado. Agora copie os sliders na mesa.')),
    );
  }
}
