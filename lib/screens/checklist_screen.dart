import 'package:flutter/material.dart';

import '../data/checklist.dart';
import '../state/app_state.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final total = checklist.fold<int>(0, (a, sec) => a + sec.itens.length);
        final feitos = s.checklistMarcados.length;
        return Scaffold(
          appBar: AppBar(
            title: Text('Checklist ($feitos/$total)'),
            actions: [
              IconButton(
                tooltip: 'Começar de novo',
                icon: const Icon(Icons.restart_alt),
                onPressed: s.limparChecklist,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              LinearProgressIndicator(value: total == 0 ? 0 : feitos / total),
              for (var si = 0; si < checklist.length; si++) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(checklist[si].titulo,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
                for (var ii = 0; ii < checklist[si].itens.length; ii++)
                  CheckboxListTile(
                    value: s.checklistMarcados.contains('$si-$ii'),
                    onChanged: (v) => s.marcarItem('$si-$ii', v ?? false),
                    title: Text(checklist[si].itens[ii]),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
