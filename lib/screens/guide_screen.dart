import 'package:flutter/material.dart';

import '../data/bands.dart';

/// Guia das 7 frequências, da esquerda para a direita como na mesa.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key, this.inicial = 0});
  final int inicial;

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  late final PageController _pagina = PageController(initialPage: widget.inicial);
  late int _atual = widget.inicial;

  @override
  void dispose() {
    _pagina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Guia de frequências')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: bandas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(bandas[i].rotulo),
                selected: i == _atual,
                onSelected: (_) => _pagina.animateToPage(i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pagina,
              itemCount: bandas.length,
              onPageChanged: (i) => setState(() => _atual = i),
              itemBuilder: (_, i) {
                final b = bandas[i];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(b.rotulo, style: Theme.of(context).textTheme.headlineMedium),
                    Text('${b.apelido} · ${b.regiao}',
                        style: TextStyle(color: cs.primary, fontSize: 16)),
                    const SizedBox(height: 16),
                    _Secao('O que é', b.oQueE, Icons.info_outline),
                    _Secao('Soa como', b.soaComo, Icons.hearing),
                    _Secao('Em excesso', b.excesso, Icons.arrow_upward),
                    _Secao('Quando falta', b.falta, Icons.arrow_downward),
                    _Secao('Melhor forma de usar', b.comoUsar, Icons.tips_and_updates_outlined),
                    _Secao('No seu som (voz + playback)', b.noSeuSom, Icons.mic_none),
                    const SizedBox(height: 8),
                    Text('O que cada posição do slider faz',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var f = 4; f >= 0; f--)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 104,
                              child: Text(nomesFaixa[f],
                                  style: TextStyle(
                                      color: f == 0 || f == 4 ? cs.error : cs.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Expanded(child: Text(b.dicasPorFaixa[f])),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo, this.texto, this.icone);
  final String titulo;
  final String texto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(texto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
