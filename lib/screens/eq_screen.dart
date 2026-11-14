import 'package:flutter/material.dart';

import '../data/bands.dart';
import '../logic/eq_analyzer.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/eq_bank_panel.dart';
import '../widgets/mini_curve.dart';
import 'guide_screen.dart';

class EqScreen extends StatefulWidget {
  const EqScreen({super.key});

  @override
  State<EqScreen> createState() => _EqScreenState();
}

class _EqScreenState extends State<EqScreen> {
  int _banco = 0;
  int _banda = 4;

  AppState get _s => AppState.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final valores = _s.bancos[_banco];
        final funcao = _s.funcoes[_banco];
        final alertas = analisarCurva(valores, funcao);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Equalizador'),
            actions: [
              IconButton(
                tooltip: 'Aplicar preset',
                icon: const Icon(Icons.tune),
                onPressed: _escolherPreset,
              ),
              PopupMenuButton<String>(
                onSelected: (op) {
                  if (op == 'zerar') _s.zerar(_banco);
                  if (op == 'salvar') _salvarComoPreset(valores);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'zerar', child: Text('Zerar este banco')),
                  PopupMenuItem(
                      value: 'salvar', child: Text('Salvar como preset')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Banco de cima')),
                  ButtonSegment(value: 1, label: Text('Banco de baixo')),
                ],
                selected: {_banco},
                onSelectionChanged: (s) => setState(() => _banco = s.first),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Controla: '),
                  Expanded(
                    child: DropdownButton<FuncaoBanco>(
                      isExpanded: true,
                      value: funcao,
                      items: [
                        for (final f in FuncaoBanco.values)
                          DropdownMenuItem(value: f, child: Text(nomesFuncao[f]!)),
                      ],
                      onChanged: (f) {
                        if (f != null) _s.setFuncao(_banco, f);
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Como descobrir',
                    icon: const Icon(Icons.help_outline),
                    onPressed: _ajudaFuncao,
                  ),
                ],
              ),
              EqBankPanel(
                valores: valores,
                bandaSelecionada: _banda,
                onSelecionar: (i) => setState(() => _banda = i),
                onChanged: (i, v) => _s.setBanda(_banco, i, v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Espelhar nos dois bancos'),
                subtitle: const Text('Use quando os bancos forem L e R do mesmo som'),
                value: _s.espelhar,
                onChanged: (v) => _s.setEspelhar(v, origem: _banco),
              ),
              _CartaoBanda(
                banda: _banda,
                valor: valores[_banda],
                onGuia: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GuideScreen(inicial: _banda))),
              ),
              const SizedBox(height: 16),
              Text('Análise da curva',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final a in alertas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CartaoAlerta(
                    alerta: a,
                    onTap: a.banda == null
                        ? null
                        : () => setState(() => _banda = a.banda!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _ajudaFuncao() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('O que este banco controla?'),
        content: const Text(
          'A mesa tem dois bancos de 7 sliders. Para descobrir, na passagem de som e com música tocando, '
          'leve um slider do banco até o máximo e ouça:\n\n'
          '• Mudou o som para o público nas duas caixas: é o PA (MAIN).\n'
          '• Mudou só nos retornos: são os retornos (SEND).\n'
          '• Mudou só em uma das caixas do PA: é o lado L ou R.\n\n'
          'Depois volte o slider para onde estava. Informar a função deixa as dicas mais precisas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _escolherPreset() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, controle) => ListView(
          controller: controle,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Text(
              'Aplicar no banco de ${_banco == 0 ? 'cima' : 'baixo'}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final p in _s.todosPresets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p.nome),
                subtitle: MiniCurve(valores: p.valores, altura: 32),
                onTap: () {
                  _s.aplicarValores(_banco, p.valores);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Preset "${p.nome}" aplicado')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarComoPreset(List<double> valores) async {
    final nome = TextEditingController();
    final quando = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar como preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: quando,
              decoration: const InputDecoration(labelText: 'Quando usar (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true && nome.text.trim().isNotEmpty) {
      _s.salvarPreset(nome.text.trim(), quando.text.trim(), valores);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Preset salvo')));
      }
    }
  }
}

class _CartaoBanda extends StatelessWidget {
  const _CartaoBanda({required this.banda, required this.valor, required this.onGuia});
  final int banda;
  final double valor;
  final VoidCallback onGuia;

  @override
  Widget build(BuildContext context) {
    final b = bandas[banda];
    final cs = Theme.of(context).colorScheme;
    final faixa = faixaDoValor(valor);
    final cor = switch (faixa) {
      0 || 4 => cs.error,
      2 => cs.onSurfaceVariant,
      _ => cs.primary,
    };
    final sinal = valor > 0 ? '+' : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${b.rotulo} · ${b.apelido}',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Text('$sinal${valor.toInt()} dB',
                    style: TextStyle(
                        color: cor, fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            Text(b.regiao, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(b.oQueE),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nomesFaixa[faixa],
                      style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(b.dicaPara(valor)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onGuia,
                icon: const Icon(Icons.school_outlined),
                label: const Text('Guia completo da banda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoAlerta extends StatelessWidget {
  const _CartaoAlerta({required this.alerta, this.onTap});
  final Alerta alerta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icone, cor) = switch (alerta.gravidade) {
      Gravidade.perigo => (Icons.error_outline, cs.error),
      Gravidade.atencao => (Icons.warning_amber_rounded, Colors.amber),
      Gravidade.info => (Icons.check_circle_outline, cs.primary),
    };
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icone, color: cor),
        title: Text(alerta.titulo),
        subtitle: Text(alerta.comoCorrigir),
      ),
    );
  }
}
