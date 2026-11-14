import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/share_codec.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/mini_curve.dart';
import 'channel_map_screen.dart';
import 'eq_screen.dart';
import 'qr_screens.dart';

String _data(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Eventos'),
          actions: [
            IconButton(
              tooltip: 'Ler QR code',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => lerQrEImportar(context),
            ),
            IconButton(
              tooltip: 'Colar código',
              icon: const Icon(Icons.content_paste),
              onPressed: () => colarCodigo(context),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _novo(context),
          icon: const Icon(Icons.add),
          label: const Text('Novo evento'),
        ),
        body: s.projetos.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Crie um evento para guardar a equalização, o efeito DSP e o que deu certo ou errado. '
                    'Na próxima vez no mesmo local, é só carregar.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                itemCount: s.projetos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = s.projetos[i];
                  return Card(
                    child: ListTile(
                      title: Text(p.nome),
                      subtitle: Text([
                        _data(p.data),
                        if (p.local.isNotEmpty) p.local,
                        if (p.efeitoDsp != null) 'DSP ${p.efeitoDsp}',
                      ].join(' · ')),
                      trailing: SizedBox(
                          width: 70, child: MiniCurve(valores: p.eqCima, altura: 30)),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(projeto: p))),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _novo(BuildContext context) async {
    final nome = TextEditingController();
    final local = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nome,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do evento'),
            ),
            TextField(
              controller: local,
              decoration: const InputDecoration(labelText: 'Local'),
            ),
            const SizedBox(height: 8),
            const Text(
              'O equalizador atual do simulador será salvo no evento.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Criar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final s = AppState.instance;
    final anterior = s.ultimoNoLocal(local.text);
    final p = s.novoProjeto(
      nome.text.trim().isEmpty ? 'Evento ${_data(DateTime.now())}' : nome.text.trim(),
      local.text.trim(),
    );
    if (anterior != null && context.mounted) {
      final usar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Já tocou neste local'),
          content: Text(
              'Encontrei "${anterior.nome}" (${_data(anterior.data)}) no mesmo local. Usar a equalização e o efeito daquele evento?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Não')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Usar')),
          ],
        ),
      );
      if (usar == true) {
        p.eqCima = List<double>.of(anterior.eqCima);
        p.eqBaixo = List<double>.of(anterior.eqBaixo);
        p.efeitoDsp = anterior.efeitoDsp;
        p.effReturn = anterior.effReturn;
        s.carregarEqDoProjeto(p);
      }
    }
    if (context.mounted) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProjectDetailScreen(projeto: p)));
    }
  }
}

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projeto});
  final Projeto projeto;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final _nome = TextEditingController(text: widget.projeto.nome);
  late final _local = TextEditingController(text: widget.projeto.local);
  late final _dsp =
      TextEditingController(text: widget.projeto.efeitoDsp?.toString() ?? '');
  late final _eff = TextEditingController(text: widget.projeto.effReturn);
  late final _notas = TextEditingController(text: widget.projeto.notas);
  late final _problemas = TextEditingController(text: widget.projeto.problemas);

  AppState get _s => AppState.instance;
  Projeto get _p => widget.projeto;

  @override
  void dispose() {
    for (final c in [_nome, _local, _dsp, _eff, _notas, _problemas]) {
      c.dispose();
    }
    super.dispose();
  }

  void _salvarCampos() {
    _p.nome = _nome.text.trim().isEmpty ? _p.nome : _nome.text.trim();
    _p.local = _local.text.trim();
    _p.efeitoDsp = int.tryParse(_dsp.text.trim());
    _p.effReturn = _eff.text.trim();
    _p.notas = _notas.text;
    _p.problemas = _problemas.text;
    _s.atualizarProjeto();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) => _salvarCampos(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Evento'),
          actions: [
            IconButton(
              tooltip: 'Compartilhar por QR code',
              icon: const Icon(Icons.qr_code),
              onPressed: () => _acao('qr'),
            ),
            PopupMenuButton<String>(
              onSelected: _acao,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'exportar', child: Text('Copiar código (WhatsApp)')),
                PopupMenuItem(value: 'excluir', child: Text('Excluir evento')),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome'),
              onChanged: (_) => _salvarCampos(),
            ),
            TextField(
              controller: _local,
              decoration: const InputDecoration(labelText: 'Local'),
              onChanged: (_) => _salvarCampos(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dsp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Efeito DSP (número do visor)'),
                    onChanged: (_) => _salvarCampos(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _eff,
                    decoration: const InputDecoration(
                        labelText: 'EFF RETURN', hintText: 'ex.: 10 horas'),
                    onChanged: (_) => _salvarCampos(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Equalização salva', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Banco de cima'),
            MiniCurve(valores: _p.eqCima),
            const SizedBox(height: 8),
            const Text('Banco de baixo'),
            MiniCurve(valores: _p.eqBaixo),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.download),
                  label: const Text('Carregar no simulador'),
                  onPressed: () {
                    _s.carregarEqDoProjeto(_p);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EqScreen()));
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar EQ atual aqui'),
                  onPressed: () {
                    _s.salvarEqNoProjeto(_p);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Equalização do simulador salva no evento')));
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Mapa de canais', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              _p.mapa == null
                  ? 'Nenhum mapa salvo neste evento.'
                  : '${_p.mapa!.emUso} canais em uso.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_p.mapa != null)
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.grid_view),
                    label: const Text('Ver/editar mapa'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChannelMapScreen(
                        mapaDoEvento: _p.mapa,
                        titulo: 'Mapa: ${_p.nome}',
                      ),
                    )),
                  ),
                if (_p.mapa != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Usar como mapa atual'),
                    onPressed: () {
                      _s.substituirMapa(_p.mapa!);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Mapa do evento virou o mapa atual da mesa.')));
                    },
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar mapa atual aqui'),
                  onPressed: () {
                    _p.mapa = _s.mapa.copia();
                    _s.atualizarProjeto();
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notas,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Anotações (canais, posição das caixas, ganho...)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _salvarCampos(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _problemas,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'O que deu errado e como resolveu',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _salvarCampos(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acao(String op) async {
    if (op == 'qr') {
      _salvarCampos();
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QrShowScreen(titulo: _p.nome, pacote: codificarEvento(_p)),
      ));
    } else if (op == 'exportar') {
      _salvarCampos();
      // Código completo (com anotações): sem o limite de tamanho do QR.
      final dados = _p.toJson()..remove('id');
      final codigo = codificarEventoCompleto(dados);
      await Clipboard.setData(ClipboardData(text: codigo));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Código copiado. Cole no WhatsApp; quem receber copia o texto e toca em "Colar código" na tela Eventos.')));
      }
    } else if (op == 'excluir') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Excluir "${_p.nome}"?'),
          content: const Text('Essa ação não pode ser desfeita.'),
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
      if (ok == true && mounted) {
        _s.excluirProjeto(_p.id);
        Navigator.pop(context);
      }
    }
  }
}
