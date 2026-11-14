import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_services.dart';
import '../audio/eq_filter.dart';
import '../audio/training_audio.dart';
import '../data/bands.dart';
import '../logic/training.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/eq_bank_panel.dart';

/// Modo treino: treina o ouvido para reconhecer cada slider da mesa.
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  FonteTreino fonte = FonteTreino.musica;
  Dificuldade dificuldade = Dificuldade.facil;
  bool semGraves = false;

  @override
  void dispose() {
    GeradorService.instance.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Treino de ouvido'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Ache a banda'),
            Tab(text: 'Conserte o som'),
          ]),
        ),
        body: Column(
          children: [
            _Opcoes(
              fonte: fonte,
              dificuldade: dificuldade,
              semGraves: semGraves,
              onFonte: (f) => setState(() => fonte = f),
              onDificuldade: (d) => setState(() => dificuldade = d),
              onSemGraves: (v) => setState(() => semGraves = v),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(children: [
                _AcheABanda(fonte: fonte, dificuldade: dificuldade, semGraves: semGraves),
                _ConserteOSom(fonte: fonte, dificuldade: dificuldade, semGraves: semGraves),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcoes extends StatelessWidget {
  const _Opcoes({
    required this.fonte,
    required this.dificuldade,
    required this.semGraves,
    required this.onFonte,
    required this.onDificuldade,
    required this.onSemGraves,
  });

  final FonteTreino fonte;
  final Dificuldade dificuldade;
  final bool semGraves;
  final ValueChanged<FonteTreino> onFonte;
  final ValueChanged<Dificuldade> onDificuldade;
  final ValueChanged<bool> onSemGraves;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<FonteTreino>(
                  isExpanded: true,
                  value: fonte,
                  items: [
                    for (final f in FonteTreino.values)
                      DropdownMenuItem(value: f, child: Text(nomesFonte[f]!)),
                  ],
                  onChanged: (f) {
                    if (f != null) onFonte(f);
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<Dificuldade>(
                value: dificuldade,
                items: [
                  for (final d in Dificuldade.values)
                    DropdownMenuItem(
                        value: d,
                        child: Text('${nomesDificuldade[d]} (±${ganhoDoNivel(d).toInt()})')),
                ],
                onChanged: (d) {
                  if (d != null) onDificuldade(d);
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  semGraves
                      ? 'Sem fone: 63Hz e 150Hz ficam de fora'
                      : 'Com fone de ouvido: todas as bandas',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Switch(value: !semGraves, onChanged: (v) => onSemGraves(!v)),
            ],
          ),
          ListenableBuilder(
            listenable: s,
            builder: (context, _) => Text(
              'Acertos: ${s.treinoAcertos}/${s.treinoTentativas} · '
              'Sequência: ${s.treinoSequencia} · Recorde: ${s.treinoMelhorSequencia}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botões de A/B: tocam o áudio original e a versão processada.
class _Player extends StatelessWidget {
  const _Player({
    required this.tocando,
    required this.opcoes,
    required this.onTocar,
    required this.onParar,
  });

  final String? tocando;
  final List<String> opcoes;
  final ValueChanged<String> onTocar;
  final VoidCallback onParar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in opcoes)
          tocando == o
              ? FilledButton.icon(
                  onPressed: onParar,
                  icon: const Icon(Icons.stop),
                  label: Text(o),
                )
              : OutlinedButton.icon(
                  onPressed: () => onTocar(o),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(o),
                ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ache a banda
// ---------------------------------------------------------------------------

class _AcheABanda extends StatefulWidget {
  const _AcheABanda({required this.fonte, required this.dificuldade, required this.semGraves});
  final FonteTreino fonte;
  final Dificuldade dificuldade;
  final bool semGraves;

  @override
  State<_AcheABanda> createState() => _AcheABandaState();
}

class _AcheABandaState extends State<_AcheABanda> with AutomaticKeepAliveClientMixin {
  final _r = math.Random();
  late DesafioBanda _desafio;
  int? _banda;
  bool _reforco = true;
  bool? _acertou;
  String? _tocando;

  static const _original = 'Original';
  static const _alterado = 'Alterado';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _novo();
  }

  @override
  void didUpdateWidget(_AcheABanda old) {
    super.didUpdateWidget(old);
    if (old.dificuldade != widget.dificuldade || old.semGraves != widget.semGraves) {
      _novo();
    } else if (old.fonte != widget.fonte && _tocando != null) {
      _tocar(_tocando!);
    }
  }

  void _novo() {
    _desafio = novoDesafioBanda(_r, widget.dificuldade, semGraves: widget.semGraves);
    _banda = null;
    _acertou = null;
    if (_tocando != null) {
      GeradorService.instance.parar();
      _tocando = null;
    }
  }

  Future<void> _tocar(String qual) async {
    final base = audioTreino(widget.fonte);
    final audio = qual == _original ? base : aplicarEq(base, _desafio.curva);
    await GeradorService.instance.tocarAmostras(audio, 'Treino: $qual');
    if (mounted) setState(() => _tocando = qual);
  }

  Future<void> _parar() async {
    await GeradorService.instance.parar();
    if (mounted) setState(() => _tocando = null);
  }

  void _responder() {
    final b = _banda;
    if (b == null) return;
    final ok = _desafio.confere(b, _reforco);
    HapticFeedback.mediumImpact();
    AppState.instance.registrarTreino(ok);
    setState(() => _acertou = ok);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final validas = bandasSorteaveis(semGraves: widget.semGraves);
    final respondido = _acertou != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        const Text(
          'Um slider foi mexido. Compare o original com o alterado e descubra qual banda mudou e se foi reforço ou corte.',
        ),
        const SizedBox(height: 12),
        _Player(
          tocando: _tocando,
          opcoes: const [_original, _alterado],
          onTocar: _tocar,
          onParar: _parar,
        ),
        const SizedBox(height: 16),
        Text('Qual banda?', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < numBandas; i++)
              ChoiceChip(
                label: Text(bandas[i].rotulo),
                selected: _banda == i,
                onSelected: !validas.contains(i) || respondido
                    ? null
                    : (_) => setState(() => _banda = i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Reforço'), icon: Icon(Icons.arrow_upward)),
            ButtonSegment(value: false, label: Text('Corte'), icon: Icon(Icons.arrow_downward)),
          ],
          selected: {_reforco},
          onSelectionChanged: respondido ? null : (v) => setState(() => _reforco = v.first),
        ),
        const SizedBox(height: 12),
        if (!respondido)
          FilledButton(
            onPressed: _banda == null ? null : _responder,
            child: const Text('Responder'),
          )
        else ...[
          Card(
            color: _acertou! ? cs.primaryContainer : cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Builder(builder: (context) {
                final b = bandas[_desafio.banda];
                final cor = _acertou! ? cs.onPrimaryContainer : cs.onErrorContainer;
                final sinal = _desafio.reforco ? '+' : '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_acertou! ? 'Acertou!' : 'Não foi dessa vez',
                        style: TextStyle(
                            color: cor, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Era ${b.rotulo} (${b.apelido}) em $sinal${_desafio.ganhoDb.toInt()} dB.',
                      style: TextStyle(color: cor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _desafio.reforco ? 'Em excesso: ${b.excesso}' : 'Quando falta: ${b.falta}',
                      style: TextStyle(color: cor),
                    ),
                    const SizedBox(height: 6),
                    Text('Ouça de novo os dois para gravar esse som.',
                        style: TextStyle(color: cor, fontSize: 13)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => setState(_novo),
            icon: const Icon(Icons.skip_next),
            label: const Text('Próximo'),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Conserte o som
// ---------------------------------------------------------------------------

class _ConserteOSom extends StatefulWidget {
  const _ConserteOSom({required this.fonte, required this.dificuldade, required this.semGraves});
  final FonteTreino fonte;
  final Dificuldade dificuldade;
  final bool semGraves;

  @override
  State<_ConserteOSom> createState() => _ConserteOSomState();
}

class _ConserteOSomState extends State<_ConserteOSom> with AutomaticKeepAliveClientMixin {
  final _r = math.Random();
  late DesafioConserto _desafio;
  List<double> _ajuste = eqPlano();
  int _bandaSel = 3;
  ResultadoConserto? _resultado;
  String? _tocando;
  Timer? _atraso;

  static const _original = 'Original';
  static const _seu = 'Estragado + seu ajuste';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _novo();
  }

  @override
  void dispose() {
    _atraso?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ConserteOSom old) {
    super.didUpdateWidget(old);
    if (old.dificuldade != widget.dificuldade || old.semGraves != widget.semGraves) {
      _novo();
    } else if (old.fonte != widget.fonte && _tocando != null) {
      _tocar(_tocando!);
    }
  }

  void _novo() {
    _desafio = novoConserto(_r, widget.dificuldade, semGraves: widget.semGraves);
    _ajuste = eqPlano();
    _resultado = null;
    if (_tocando != null) {
      GeradorService.instance.parar();
      _tocando = null;
    }
  }

  List<double> get _curvaFinal =>
      [for (var i = 0; i < numBandas; i++) _desafio.estrago[i] + _ajuste[i]];

  Future<void> _tocar(String qual) async {
    final base = audioTreino(widget.fonte);
    final audio = qual == _original ? base : aplicarEq(base, _curvaFinal);
    await GeradorService.instance.tocarAmostras(audio, 'Treino: $qual');
    if (mounted) setState(() => _tocando = qual);
  }

  Future<void> _parar() async {
    await GeradorService.instance.parar();
    if (mounted) setState(() => _tocando = null);
  }

  void _mexer(int banda, double valor) {
    setState(() => _ajuste[banda] = valor);
    // Se estiver ouvindo a sua versão, atualiza o som logo depois de soltar.
    if (_tocando == _seu) {
      _atraso?.cancel();
      _atraso = Timer(const Duration(milliseconds: 350), () => _tocar(_seu));
    }
  }

  void _conferir() {
    final r = avaliarConserto(_desafio, _ajuste);
    HapticFeedback.mediumImpact();
    AppState.instance.registrarTreino(r.acertou);
    setState(() => _resultado = r);
  }

  String _fmt(double v) => v > 0 ? '+${v.toInt()}' : '${v.toInt()}';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final r = _resultado;
    final n = _desafio.bandasAlteradas;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Text(
          'O som foi estragado em $n ${n == 1 ? 'banda' : 'bandas'}. '
          'Mexa nos sliders até o som ficar igual ao original. Corrigir é fazer o contrário do estrago.',
        ),
        const SizedBox(height: 12),
        _Player(
          tocando: _tocando,
          opcoes: const [_original, _seu],
          onTocar: _tocar,
          onParar: _parar,
        ),
        const SizedBox(height: 12),
        EqBankPanel(
          valores: _ajuste,
          bandaSelecionada: _bandaSel,
          onSelecionar: (i) => setState(() => _bandaSel = i),
          onChanged: r == null ? _mexer : (_, __) {},
          altura: 200,
        ),
        const SizedBox(height: 12),
        if (r == null)
          FilledButton(onPressed: _conferir, child: const Text('Conferir'))
        else ...[
          Card(
            color: r.acertou ? cs.primaryContainer : cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.acertou ? 'Consertou! Nota ${r.nota}' : 'Quase: nota ${r.nota}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: r.acertou ? cs.onPrimaryContainer : cs.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < numBandas; i++)
                    if (_desafio.estrago[i] != 0 || _ajuste[i] != 0)
                      Text(
                        '${bandas[i].rotulo}: estrago ${_fmt(_desafio.estrago[i])}, '
                        'seu ajuste ${_fmt(_ajuste[i])} → sobrou ${_fmt(r.residuo[i])}',
                        style: TextStyle(
                            color: r.acertou ? cs.onPrimaryContainer : cs.onErrorContainer),
                      ),
                  const SizedBox(height: 6),
                  Text(
                    'Acerto = nenhuma banda mais de 3 dB fora.',
                    style: TextStyle(
                        fontSize: 12,
                        color: r.acertou ? cs.onPrimaryContainer : cs.onErrorContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => setState(_novo),
            icon: const Icon(Icons.skip_next),
            label: const Text('Novo desafio'),
          ),
        ],
      ],
    );
  }
}
