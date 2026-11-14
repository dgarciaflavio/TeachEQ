import 'dart:async';

import 'package:flutter/material.dart';

import '../data/presets.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Abertura: os 7 faders da mesa "dançam" como um equalizador reagindo à
/// música e assentam no preset "Voz + playback". Toque para pular.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _duracao = Duration(milliseconds: 2100);

  late final AnimationController _c = AnimationController(vsync: this, duration: _duracao);
  late final List<Animation<double>> _faders;
  late final Animation<double> _texto;
  bool _saiu = false;

  // Picos de cada fader (dB) antes de assentar: graves mexem mais, como
  // numa música de verdade.
  static const _picos = [
    [9.0, -5.0, 7.0],
    [10.0, -3.0, 8.0],
    [6.0, -7.0, 5.0],
    [4.0, -9.0, 6.0],
    [8.0, -4.0, 10.0],
    [5.0, -8.0, 6.0],
    [7.0, -6.0, 4.0],
  ];

  @override
  void initState() {
    super.initState();
    final alvo = presetsProntos.firstWhere((p) => p.id == 'voz_playback').valores;
    _faders = [
      for (var i = 0; i < 7; i++)
        TweenSequence<double>([
          TweenSequenceItem(
              tween: Tween(begin: 0.0, end: _picos[i][0]).chain(CurveTween(curve: Curves.easeOut)),
              weight: 22),
          TweenSequenceItem(
              tween: Tween(begin: _picos[i][0], end: _picos[i][1])
                  .chain(CurveTween(curve: Curves.easeInOut)),
              weight: 24),
          TweenSequenceItem(
              tween: Tween(begin: _picos[i][1], end: _picos[i][2])
                  .chain(CurveTween(curve: Curves.easeInOut)),
              weight: 22),
          TweenSequenceItem(
              tween: Tween(begin: _picos[i][2], end: alvo[i])
                  .chain(CurveTween(curve: Curves.easeOutBack)),
              weight: 32),
        ]).animate(CurvedAnimation(
          parent: _c,
          // Começo escalonado: a onda passa da esquerda para a direita.
          curve: Interval(i * 0.035, 0.72 + i * 0.035),
        )),
    ];
    _texto = CurvedAnimation(parent: _c, curve: const Interval(0.62, 0.9, curve: Curves.easeOut));
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Pequena pausa com o nome na tela antes de entrar no app.
        _espera = Timer(const Duration(milliseconds: 250), _sair);
      }
    });
    _c.forward();
  }

  Timer? _espera;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita "remover animações" do Android.
    if (MediaQuery.of(context).disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sair());
    }
  }

  void _sair() {
    if (_saiu || !mounted) return;
    _saiu = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  void dispose() {
    _espera?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresTeachEq.fundo,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _sair,
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  height: 200,
                  child: CustomPaint(
                    painter: _FadersPainter([for (final f in _faders) f.value]),
                  ),
                ),
                const SizedBox(height: 36),
                Opacity(
                  opacity: _texto.value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - _texto.value)),
                    child: const Column(
                      children: [
                        Text(
                          'TeachEQ',
                          style: TextStyle(
                            color: CoresTeachEq.creme,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'copiloto de som da sua mesa',
                          style: TextStyle(color: CoresTeachEq.cremeApagado, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Faders no estilo do ícone: trilhos fundos, botões creme com a linha no
/// meio, linha de 0dB e o 2.5KHz (voz) em vermelho.
class _FadersPainter extends CustomPainter {
  _FadersPainter(this.valores);
  final List<double> valores;

  static const _acento = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final n = valores.length;
    final passo = size.width / n;
    final altBotao = size.height * 0.085;
    final largBotao = passo * 0.72;
    final margem = altBotao / 2 + 2;
    final h = size.height - 2 * margem;
    double y(double db) => margem + (12 - db.clamp(-12.0, 12.0).toDouble()) / 24 * h;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, y(0)), width: size.width, height: 3),
        const Radius.circular(2),
      ),
      Paint()..color = CoresTeachEq.linhaZero,
    );

    for (var i = 0; i < n; i++) {
      final cx = passo * (i + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, size.height / 2), width: passo * 0.2, height: size.height),
          Radius.circular(passo * 0.1),
        ),
        Paint()..color = CoresTeachEq.trilho,
      );
      final cy = y(valores[i]);
      final botao = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: largBotao, height: altBotao),
        Radius.circular(altBotao * 0.22),
      );
      canvas.drawRRect(
          botao, Paint()..color = i == _acento ? CoresTeachEq.vermelho : CoresTeachEq.creme);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: largBotao * 0.6, height: altBotao * 0.16),
        Paint()..color = CoresTeachEq.fundo,
      );
    }
  }

  @override
  bool shouldRepaint(_FadersPainter old) => true;
}
