import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/share_codec.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'qr_screens.dart';

const Map<TipoCanal, IconData> iconesTipoCanal = {
  TipoCanal.vazio: Icons.radio_button_unchecked,
  TipoCanal.micSemFio: Icons.mic_external_on,
  TipoCanal.micComFio: Icons.mic,
  TipoCanal.computador: Icons.laptop,
  TipoCanal.celular: Icons.smartphone,
  TipoCanal.instrumento: Icons.piano,
  TipoCanal.outro: Icons.cable,
};

/// Mapa dos canais da mesa: o que está ligado em cada canal e nas saídas.
/// Edita o mapa atual do app, ou o mapa salvo de um evento ([mapaDoEvento]).
class ChannelMapScreen extends StatelessWidget {
  const ChannelMapScreen({super.key, this.mapaDoEvento, this.titulo});

  final MapaMesa? mapaDoEvento;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final mapa = mapaDoEvento ?? s.mapa;
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(titulo ?? 'Mapa da mesa'),
            actions: [
              IconButton(
                tooltip: 'Copiar como texto',
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: mapa.texto()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Mapa copiado. Cole no WhatsApp ou imprima como etiqueta.')));
                },
              ),
              IconButton(
                tooltip: 'Compartilhar por QR code',
                icon: const Icon(Icons.qr_code),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QrShowScreen(
                    titulo: 'Mapa da mesa',
                    pacote: codificarMapa(mapa),
                  ),
                )),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
            children: [
              Text(
                '${mapa.emUso} de ${mapa.canais.length} canais em uso. Toque num canal para editar.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < mapa.canais.length; i++)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: mapa.canais[i].emUso ? null : cs.surfaceContainerLow,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          mapa.canais[i].emUso ? cs.primaryContainer : cs.surfaceContainerHighest,
                      child: Text('${i + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: mapa.canais[i].emUso
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant)),
                    ),
                    title: Text(mapa.rotulo(i)),
                    subtitle: Text([
                      if (mapa.canais[i].emUso && mapa.canais[i].nome.isNotEmpty)
                        nomesTipoCanal[mapa.canais[i].tipo]!,
                      if (mapa.canais[i].detalhe.isNotEmpty) mapa.canais[i].detalhe,
                    ].join(' · ')),
                    trailing: Icon(iconesTipoCanal[mapa.canais[i].tipo]),
                    onTap: () => _editar(context, mapa, i),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.output),
                  title: const Text('Saídas'),
                  subtitle: Text(mapa.saidas.isEmpty ? 'Toque para descrever' : mapa.saidas),
                  onTap: () => _editarSaidas(context, mapa),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar canal'),
                    onPressed: () {
                      mapa.canais.add(CanalMesa());
                      s.atualizarMapa();
                    },
                  ),
                  const Spacer(),
                  if (mapa.canais.length > 1)
                    TextButton.icon(
                      icon: const Icon(Icons.remove),
                      label: const Text('Remover último'),
                      onPressed: () {
                        mapa.canais.removeLast();
                        s.atualizarMapa();
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editar(BuildContext context, MapaMesa mapa, int i) async {
    final c = mapa.canais[i];
    final nome = TextEditingController(text: c.nome);
    final detalhe = TextEditingController(text: c.detalhe);
    var tipo = c.tipo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text('Canal ${i + 1}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TipoCanal>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'O que está ligado'),
                  items: [
                    for (final t in TipoCanal.values)
                      DropdownMenuItem(
                        value: t,
                        child: Row(children: [
                          Icon(iconesTipoCanal[t], size: 18),
                          const SizedBox(width: 8),
                          Text(nomesTipoCanal[t]!),
                        ]),
                      ),
                  ],
                  onChanged: (t) => set(() => tipo = t ?? TipoCanal.vazio),
                ),
                TextField(
                  controller: nome,
                  decoration: const InputDecoration(
                      labelText: 'Nome', hintText: 'ex.: Mic 1 – Ana'),
                ),
                TextField(
                  controller: detalhe,
                  decoration: const InputDecoration(
                      labelText: 'Detalhe', hintText: 'ex.: receptor A, pilha recarregável'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (ok == true) {
      c
        ..tipo = tipo
        ..nome = nome.text.trim()
        ..detalhe = detalhe.text.trim();
      AppState.instance.atualizarMapa();
    }
    nome.dispose();
    detalhe.dispose();
  }

  Future<void> _editarSaidas(BuildContext context, MapaMesa mapa) async {
    final ctrl = TextEditingController(text: mapa.saidas);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saídas da mesa'),
        content: TextField(
          controller: ctrl,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
        ],
      ),
    );
    if (ok == true) {
      mapa.saidas = ctrl.text.trim();
      AppState.instance.atualizarMapa();
    }
    ctrl.dispose();
  }
}
