import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bands.dart';

/// Réplica de um banco do equalizador gráfico da K-Audio HX-1202USB:
/// escala +12 / 0dB / -12 dos dois lados, linhas a cada 3 dB e
/// 7 sliders (63Hz a 15KHz).
class EqBankPanel extends StatelessWidget {
  const EqBankPanel({
    super.key,
    required this.valores,
    required this.onChanged,
    this.bandaSelecionada,
    this.onSelecionar,
    this.altura = 240,
  });

  final List<double> valores;
  final void Function(int banda, double valor) onChanged;
  final int? bandaSelecionada;
  final ValueChanged<int>? onSelecionar;
  final double altura;

  static const double larguraEscala = 34;
  static const double margem = 14;
  static const Color corPainel = Color(0xFF3B3D40);
  static const Color corLinha = Color(0xFF8E9196);
  static const Color corTexto = Color(0xFFD9DBDE);

  @override
  Widget build(BuildContext context) {
    final destaque = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      decoration: BoxDecoration(
        color: corPainel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: larguraEscala),
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    _formatar(valores[i]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == bandaSelecionada ? destaque : corTexto,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(width: larguraEscala),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: altura,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  width: larguraEscala,
                  child: CustomPaint(painter: _EscalaPainter(alinharDireita: true)),
                ),
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _Fader(
                      valor: valores[i],
                      selecionado: i == bandaSelecionada,
                      corDestaque: destaque,
                      onTocar: () => onSelecionar?.call(i),
                      onChanged: (v) => onChanged(i, v),
                    ),
                  ),
                const SizedBox(
                  width: larguraEscala,
                  child: CustomPaint(painter: _EscalaPainter(alinharDireita: false)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: larguraEscala),
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelecionar?.call(i),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bandas[i].rotulo,
                        style: TextStyle(
                          color: i == bandaSelecionada ? destaque : corTexto,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: larguraEscala),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatar(double v) {
    if (v == 0) return '0';
    return v > 0 ? '+${v.toInt()}' : '${v.toInt()}';
  }
}

double _yDoValor(double v, double altura) {
  final h = altura - 2 * EqBankPanel.margem;
  return EqBankPanel.margem + (12 - v) / 24 * h;
}

double _valorDoY(double y, double altura) {
  final h = altura - 2 * EqBankPanel.margem;
  final t = ((y - EqBankPanel.margem) / h).clamp(0.0, 1.0);
  return (12 - t * 24).roundToDouble();
}

class _Fader extends StatelessWidget {
  const _Fader({
    required this.valor,
    required this.selecionado,
    required this.corDestaque,
    required this.onTocar,
    required this.onChanged,
  });

  final double valor;
  final bool selecionado;
  final Color corDestaque;
  final VoidCallback onTocar;
  final ValueChanged<double> onChanged;

  void _mudar(double novo) {
    if (novo != valor) {
      HapticFeedback.selectionClick();
      onChanged(novo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final altura = c.maxHeight;
      return Semantics(
        slider: true,
        value: '${valor.toInt()} dB',
        onIncrease: () => _mudar((valor + 1).clamp(-12, 12).toDouble()),
        onDecrease: () => _mudar((valor - 1).clamp(-12, 12).toDouble()),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTocar,
          onDoubleTap: () {
            onTocar();
            _mudar(0);
          },
          onVerticalDragStart: (d) {
            onTocar();
            _mudar(_valorDoY(d.localPosition.dy, altura));
          },
          onVerticalDragUpdate: (d) =>
              _mudar(_valorDoY(d.localPosition.dy, altura)),
          child: CustomPaint(
            painter: _FaderPainter(valor, selecionado, corDestaque),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

class _FaderPainter extends CustomPainter {
  _FaderPainter(this.valor, this.selecionado, this.corDestaque);

  final double valor;
  final bool selecionado;
  final Color corDestaque;

  @override
  void paint(Canvas canvas, Size size) {
    final linha = Paint()
      ..color = EqBankPanel.corLinha
      ..strokeWidth = 1;
    final linhaZero = Paint()
      ..color = EqBankPanel.corTexto
      ..strokeWidth = 2;

    for (var k = 0; k <= 8; k++) {
      final v = 12.0 - k * 3;
      final y = _yDoValor(v, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), v == 0 ? linhaZero : linha);
    }

    final cx = size.width / 2;
    final trilho = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, size.height / 2),
        width: 9,
        height: size.height - 4,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(trilho, Paint()..color = const Color(0xFF111214));

    final y = _yDoValor(valor, size.height);
    final larguraKnob = (size.width * 0.62).clamp(18.0, 30.0).toDouble();
    final knob = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, y), width: larguraKnob, height: 20),
      const Radius.circular(3),
    );
    canvas.drawRRect(knob, Paint()..color = const Color(0xFF2A2B2E));
    canvas.drawRRect(
      knob,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selecionado ? 2.5 : 1
        ..color = selecionado ? corDestaque : const Color(0xFF6B6E73),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, y), width: larguraKnob * 0.55, height: 5),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_FaderPainter old) =>
      old.valor != valor ||
      old.selecionado != selecionado ||
      old.corDestaque != corDestaque;
}

class _EscalaPainter extends CustomPainter {
  const _EscalaPainter({required this.alinharDireita});
  final bool alinharDireita;

  @override
  void paint(Canvas canvas, Size size) {
    const marcas = {12.0: '+12', 0.0: '0dB', -12.0: '-12'};
    for (final e in marcas.entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.value,
          style: const TextStyle(color: EqBankPanel.corTexto, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final y = _yDoValor(e.key, size.height) - tp.height / 2;
      final x = alinharDireita ? size.width - tp.width - 3 : 3.0;
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_EscalaPainter old) => old.alinharDireita != alinharDireita;
}
