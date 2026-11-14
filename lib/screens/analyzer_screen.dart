import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_math.dart';
import '../audio/audio_services.dart';
import '../audio/feedback_detector.dart';
import '../audio/spectrum_processor.dart';
import '../data/bands.dart';
import '../state/app_state.dart';
import '../widgets/bank_picker.dart';
import '../widgets/mini_curve.dart';
import '../widgets/spectrum_view.dart';
import 'generator_screen.dart';

/// Analisador pelo microfone do celular: medidor de volume, espectro ao vivo,
/// detector de microfonia e medição da sala com sugestão de equalização.
class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  final _mic = MicrofoneService();
  final _proc = ProcessadorEspectro();
  final _detector = DetectorMicrofonia();
  AppState get _s => AppState.instance;

  bool _ouvindo = false;
  String? _erro;

  Float64List? _espectro;
  double _dbfsA = -120;
  double _maxDb = 0;
  final List<double> _bandas = List<double>.filled(7, -100);

  DeteccaoMicrofonia? _microfonia;
  DateTime _ultimaMicrofonia = DateTime(2000);
  final List<DeteccaoMicrofonia> _historico = [];

  // Medição da sala.
  static const int segundosMedicao = 15;
  bool _medindo = false;
  int _quadrosMedidos = 0;
  final List<double> _somaPotencia = List<double>.filled(7, 0);
  DateTime? _fimMedicao;
  List<double>? _sugestao;
  List<double>? _medido;
  Timer? _tick;

  double get _dbEstimado => _dbfsA + _s.offsetCalibracao;

  @override
  void dispose() {
    _tick?.cancel();
    _mic.descartar();
    super.dispose();
  }

  Future<void> _alternar() async {
    if (_ouvindo) {
      await _mic.parar();
      setState(() {
        _ouvindo = false;
        _medindo = false;
        _microfonia = null;
      });
      return;
    }
    if (!await _mic.temPermissao()) {
      setState(() => _erro =
          'Sem permissão para o microfone. Libere em Configurações do Android → Apps → TeachEQ → Permissões.');
      return;
    }
    _proc.reiniciar();
    _detector.reiniciar();
    _maxDb = 0;
    try {
      await _mic.iniciar(_aoReceber);
      setState(() {
        _ouvindo = true;
        _erro = null;
      });
    } catch (e) {
      setState(() => _erro = 'Não consegui abrir o microfone: $e');
    }
  }

  void _aoReceber(List<double> amostras) {
    final quadros = _proc.adicionar(amostras);
    if (quadros.isEmpty || !mounted) return;
    for (final q in quadros) {
      _processarQuadro(q);
    }
    setState(() {});
  }

  void _processarQuadro(QuadroEspectro q) {
    // Suavização para a tela não tremer.
    final e = _espectro;
    if (e == null || e.length != q.magDb.length) {
      _espectro = Float64List.fromList(q.magDb);
    } else {
      for (var k = 0; k < e.length; k++) {
        e[k] = e[k] * 0.5 + q.magDb[k] * 0.5;
      }
    }
    _dbfsA = _dbfsA < -110 ? q.nivelDbfsA : _dbfsA * 0.7 + q.nivelDbfsA * 0.3;
    _maxDb = math.max(_maxDb, q.nivelDbfsA + _s.offsetCalibracao);
    for (var b = 0; b < 7; b++) {
      _bandas[b] = _bandas[b] < -99
          ? q.bandasDbOitava[b]
          : _bandas[b] * 0.8 + q.bandasDbOitava[b] * 0.2;
    }

    final m = _detector.atualizar(q);
    if (m != null) {
      _microfonia = m;
      _ultimaMicrofonia = DateTime.now();
      if (m.nova) {
        HapticFeedback.heavyImpact();
        _historico.insert(0, m);
        if (_historico.length > 20) _historico.removeLast();
      }
    } else if (DateTime.now().difference(_ultimaMicrofonia).inMilliseconds > 2500) {
      _microfonia = null; // mantém o aviso na tela por 2,5 s depois que some
    }

    if (_medindo) {
      for (var b = 0; b < 7; b++) {
        _somaPotencia[b] += math.pow(10, q.bandasDbOitava[b] / 10).toDouble();
      }
      _quadrosMedidos++;
      if (DateTime.now().isAfter(_fimMedicao!)) _concluirMedicao();
    }
  }

  void _iniciarMedicao() {
    for (var b = 0; b < 7; b++) {
      _somaPotencia[b] = 0;
    }
    _quadrosMedidos = 0;
    _sugestao = null;
    _medido = null;
    _fimMedicao = DateTime.now().add(const Duration(seconds: segundosMedicao));
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() => _medindo = true);
  }

  void _concluirMedicao() {
    _medindo = false;
    _tick?.cancel();
    if (_quadrosMedidos == 0) return;
    _medido = [
      for (var b = 0; b < 7; b++)
        10 * math.log(_somaPotencia[b] / _quadrosMedidos) / math.ln10,
    ];
    _sugestao = sugerirCorrecao(_medido!);
  }

  Future<void> _aplicarCorteMicrofonia(DeteccaoMicrofonia m) async {
    final banco = await escolherBanco(context, preferirPa: false);
    if (banco == null) return;
    _s.ajustarBanda(banco, m.banda, -3);
    if (m.banda2 != null) _s.ajustarBanda(banco, m.banda2!, -2);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Simulador atualizado. Agora baixe ${_textoBandas(m)} na mesa.'),
    ));
  }

  Future<void> _aplicarSugestao(List<double> ajuste) async {
    final banco = await escolherBanco(context);
    if (banco == null) return;
    for (var b = 0; b < 7; b++) {
      if (ajuste[b] != 0) _s.ajustarBanda(banco, b, ajuste[b]);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Sugestão somada ao equalizador do simulador. Copie na mesa e meça de novo.'),
    ));
  }

  String _textoBandas(DeteccaoMicrofonia m) {
    final principal = '${bandas[m.banda].rotulo} em 3 dB';
    if (m.banda2 == null) return principal;
    return '$principal e ${bandas[m.banda2!].rotulo} em 2 dB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisador'),
        actions: [
          IconButton(
            tooltip: 'Calibrar medidor',
            icon: const Icon(Icons.speed),
            onPressed: _calibrar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _alternar,
        backgroundColor: _ouvindo ? cs.errorContainer : cs.primaryContainer,
        icon: Icon(_ouvindo ? Icons.stop : Icons.mic),
        label: Text(_ouvindo ? 'Parar' : 'Ouvir'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        children: [
          if (_erro != null)
            Card(
              color: cs.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_erro!, style: TextStyle(color: cs.onErrorContainer)),
              ),
            ),
          if (!_ouvindo && _erro == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Toque em Ouvir e segure o celular na altura do ouvido, sem cobrir o microfone. '
                'Funciona sem internet.',
              ),
            ),
          if (GeradorService.instance.tocando case final sinal?)
            Card(
              child: ListTile(
                leading: const Icon(Icons.surround_sound_outlined),
                title: Text('Tocando: $sinal'),
                trailing: TextButton(
                  onPressed: () async {
                    await GeradorService.instance.parar();
                    setState(() {});
                  },
                  child: const Text('Parar'),
                ),
              ),
            ),
          if (_microfonia != null) _alertaMicrofonia(_microfonia!, cs),
          _medidor(cs),
          const SizedBox(height: 12),
          SpectrumView(
            magDb: _espectro,
            binHz: _proc.binHz,
            destaqueHz: _microfonia?.hz,
          ),
          const SizedBox(height: 12),
          Text('Energia por banda da mesa', style: Theme.of(context).textTheme.titleMedium),
          Text('Comparada com a média. Barra para cima = sobrando.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          _barrasBandas(cs),
          const SizedBox(height: 16),
          _cartaoMedicao(cs),
          const SizedBox(height: 16),
          _cartaoHistorico(cs),
        ],
      ),
    );
  }

  Widget _alertaMicrofonia(DeteccaoMicrofonia m, ColorScheme cs) {
    return Card(
      color: cs.error,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: cs.onError, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Possível microfonia em ${formatarHz(m.hz)}',
                      style: TextStyle(
                          color: cs.onError, fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Baixe ${_textoBandas(m)}. Se o apito vier dos retornos, mexa no banco dos retornos; se vier do PA, no banco do PA.',
              style: TextStyle(color: cs.onError, fontSize: 15),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: () => _aplicarCorteMicrofonia(m),
              child: const Text('Marcar no simulador'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medidor(ColorScheme cs) {
    final db = _ouvindo ? _dbEstimado : null;
    final (faixa, cor) = switch (db) {
      null => ('', cs.onSurfaceVariant),
      < 70 => ('Baixo', cs.primary),
      < 85 => ('Bom para fala', cs.primary),
      < 95 => ('Bom para música', cs.primary),
      < 100 => ('Alto', Colors.amber),
      _ => ('Muito alto: risco para a audição', cs.error),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(db == null ? '--' : db.round().toString(),
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: cor, height: 1)),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('dB(A)\nestimado', style: TextStyle(fontSize: 12)),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(faixa, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_ouvindo ? 'Máximo: ${_maxDb.round()}' : 'Fala 70–85 · Música 85–95',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _barrasBandas(ColorScheme cs) {
    final ref = _bandas.sublist(1, 6).reduce((a, b) => a + b) / 5;
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var b = 0; b < 7; b++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _Barra(
                  desvio: _ouvindo ? (_bandas[b] - ref).clamp(-12.0, 12.0).toDouble() : 0,
                  rotulo: bandas[b].rotulo,
                  cor: cs.primary,
                  corAlta: Colors.amber,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cartaoMedicao(ColorScheme cs) {
    final restante = _fimMedicao == null
        ? 0
        : math.max(0, _fimMedicao!.difference(DateTime.now()).inSeconds);
    final sug = _sugestao;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medir o som da sala', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              '1. Toque ruído rosa pelo PA (tela Gerador, celular ligado na mesa) ou uma música variada.\n'
              '2. Fique no meio do público, celular na altura do ouvido.\n'
              '3. Meça por 15 segundos. O app sugere o ajuste dos sliders.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: !_ouvindo || _medindo ? null : _iniciarMedicao,
                  icon: const Icon(Icons.graphic_eq),
                  label: Text(_medindo ? 'Medindo... ${restante}s' : 'Medir 15 s'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const GeneratorScreen()))
                      .then((_) {
                    if (mounted) setState(() {});
                  }),
                  icon: const Icon(Icons.surround_sound_outlined),
                  label: const Text('Gerador'),
                ),
              ],
            ),
            if (!_ouvindo)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Toque em Ouvir primeiro.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ),
            if (sug != null) ...[
              const SizedBox(height: 14),
              Text('Ajuste sugerido (somar ao que está na mesa)',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              MiniCurve(valores: sug),
              Row(
                children: [
                  for (var b = 0; b < 7; b++)
                    Expanded(
                      child: Column(
                        children: [
                          Text(sug[b] > 0 ? '+${sug[b].toInt()}' : '${sug[b].toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          FittedBox(
                            child: Text(bandas[b].rotulo, style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (sug.every((v) => v == 0))
                const Text('A sala está equilibrada. Nenhum ajuste necessário.')
              else
                FilledButton.tonal(
                  onPressed: () => _aplicarSugestao(sug),
                  child: const Text('Somar ao simulador'),
                ),
              const SizedBox(height: 6),
              Text(
                'O microfone do celular é pouco fiel em 63Hz e 15KHz: por isso o app nunca sugere reforço nesses extremos. Confirme sempre de ouvido.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cartaoHistorico(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Microfonias encontradas',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (_historico.isNotEmpty)
                  IconButton(
                    tooltip: 'Copiar lista',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _historico
                          .map((m) => '${formatarHz(m.hz)} → baixar ${_textoBandas(m)}')
                          .join('\n')));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Lista copiada. Cole nas anotações do evento.')));
                    },
                  ),
                if (_historico.isNotEmpty)
                  IconButton(
                    tooltip: 'Limpar',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(_historico.clear),
                  ),
              ],
            ),
            if (_historico.isEmpty)
              Text(
                'Na passagem de som, suba cada microfone devagar até quase apitar. '
                'Cada apito encontrado aparece aqui, com o slider a baixar.',
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              for (final m in _historico)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(formatarHz(m.hz)),
                  subtitle: Text('Baixar ${_textoBandas(m)}'),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _calibrar() async {
    var offset = _s.offsetCalibracao;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Calibrar o medidor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cada celular tem um microfone diferente, então o valor em dB é uma estimativa. '
                'Para calibrar, coloque o celular ao lado de um decibelímetro (ou de outro app já calibrado) '
                'e ajuste até os dois mostrarem o mesmo número.',
              ),
              const SizedBox(height: 12),
              Text('Ajuste: ${offset.round()}'),
              Slider(
                min: 90,
                max: 160,
                divisions: 70,
                value: offset.clamp(90.0, 160.0).toDouble(),
                onChanged: (v) {
                  set(() => offset = v);
                  _s.setOffsetCalibracao(v);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                set(() => offset = AppState.offsetPadrao);
                _s.setOffsetCalibracao(AppState.offsetPadrao);
              },
              child: const Text('Padrão'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Pronto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.desvio,
    required this.rotulo,
    required this.cor,
    required this.corAlta,
  });

  final double desvio;
  final String rotulo;
  final Color cor;
  final Color corAlta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final meio = c.maxHeight / 2;
            final altura = (desvio.abs() / 12) * meio;
            final acima = desvio >= 0;
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: meio,
                  child: Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: acima ? meio - altura : meio,
                  height: altura,
                  child: Container(
                    decoration: BoxDecoration(
                      color: acima && desvio > 3 ? corAlta : cor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 4),
        FittedBox(child: Text(rotulo, style: const TextStyle(fontSize: 11))),
      ],
    );
  }
}
