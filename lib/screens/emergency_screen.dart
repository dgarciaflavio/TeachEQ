import 'package:flutter/material.dart';

import '../data/emergencies.dart';
import '../data/presets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'analyzer_screen.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O que está acontecendo?')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final cat in Categoria.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(nomesCategoria[cat]!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
            for (final e in emergencias.where((e) => e.categoria == cat))
              ListTile(
                title: Text(e.titulo),
                subtitle: Text(e.sintoma),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EmergencyDetailScreen(emergencia: e))),
              ),
          ],
        ],
      ),
    );
  }
}

class EmergencyDetailScreen extends StatefulWidget {
  const EmergencyDetailScreen({super.key, required this.emergencia});
  final Emergencia emergencia;

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  final Set<int> _feitos = {};
  bool _naoResolveu = false;

  Preset? get _preset {
    final id = widget.emergencia.presetSugerido;
    if (id == null) return null;
    for (final p in presetsProntos) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.emergencia;
    final cs = Theme.of(context).colorScheme;
    final preset = _preset;
    return Scaffold(
      appBar: AppBar(title: Text(e.titulo, maxLines: 2)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          if (e.id == 'microfonia' || e.id == 'retorno_fraco')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text('Achar a frequência com o Analisador'),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnalyzerScreen())),
              ),
            ),
          Text('Siga na ordem e marque o que já fez.',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          for (var i = 0; i < e.passos.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: _feitos.contains(i) ? cs.surfaceContainerHighest : null,
              child: CheckboxListTile(
                value: _feitos.contains(i),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _feitos.add(i);
                  } else {
                    _feitos.remove(i);
                  }
                }),
                title: Text('${i + 1}. ${e.passos[i].titulo}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: _feitos.contains(i)
                          ? TextDecoration.lineThrough
                          : null,
                    )),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(e.passos[i].detalhe),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          if (preset != null) ...[
            const SizedBox(height: 8),
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equalização sugerida: ${preset.nome}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text(_valoresTexto(preset.valores),
                        style: TextStyle(color: cs.onPrimaryContainer)),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _aplicarPreset(preset),
                      child: const Text('Aplicar no simulador'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Resolveu?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Sim'),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Boa! Depois anote o que aconteceu no projeto do evento.')));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Ainda não'),
                  onPressed: () => setState(() => _naoResolveu = true),
                ),
              ),
            ],
          ),
          if (_naoResolveu) ...[
            const SizedBox(height: 12),
            Text(
              e.relacionados.isEmpty
                  ? 'Revise os passos com calma. Se nada resolver, troque o equipamento suspeito por um reserva e siga o evento.'
                  : 'Pode ser outro problema parecido:',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            for (final id in e.relacionados)
              if (emergenciaPorId(id) case final rel?)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(rel.titulo),
                  onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => EmergencyDetailScreen(emergencia: rel))),
                ),
          ],
          if (e.prevencao.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Para não acontecer de novo',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final p in e.prevencao)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(p)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _valoresTexto(List<double> v) {
    const nomes = ['63Hz', '150Hz', '400Hz', '1KHz', '2.5KHz', '6.4KHz', '15KHz'];
    return [
      for (var i = 0; i < v.length; i++)
        '${nomes[i]} ${v[i] > 0 ? '+' : ''}${v[i].toInt()}'
    ].join(' · ');
  }

  Future<void> _aplicarPreset(Preset p) async {
    final s = AppState.instance;
    // Se o usuário já informou qual banco é o PA, aplica direto nele.
    final indicePa = s.funcoes.indexOf(FuncaoBanco.pa);
    final banco = indicePa >= 0
        ? indicePa
        : await showDialog<int>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: const Text('Aplicar em qual banco?'),
              children: [
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, 0),
                    child: const Text('Banco de cima')),
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, 1),
                    child: const Text('Banco de baixo')),
              ],
            ),
          );
    if (banco == null) return;
    s.aplicarValores(banco, p.valores);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Aplicado no banco de ${banco == 0 ? 'cima' : 'baixo'}. Copie os sliders na mesa.')));
    }
  }
}
