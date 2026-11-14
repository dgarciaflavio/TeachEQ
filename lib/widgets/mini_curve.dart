import 'package:flutter/material.dart';

/// Desenho pequeno da curva de um preset, para listas e prévias.
class MiniCurve extends StatelessWidget {
  const MiniCurve({super.key, required this.valores, this.altura = 44});
  final List<double> valores;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: altura,
      child: CustomPaint(
        painter: _MiniCurvePainter(valores, cs.primary, cs.outlineVariant),
        size: Size.infinite,
      ),
    );
  }
}

class _MiniCurvePainter extends CustomPainter {
  _MiniCurvePainter(this.valores, this.cor, this.corZero);
  final List<double> valores;
  final Color cor;
  final Color corZero;

  @override
  void paint(Canvas canvas, Size size) {
    double y(double v) => 4 + (12 - v) / 24 * (size.height - 8);
    canvas.drawLine(
      Offset(0, y(0)),
      Offset(size.width, y(0)),
      Paint()
        ..color = corZero
        ..strokeWidth = 1,
    );
    final passo = size.width / (valores.length - 1);
    final caminho = Path();
    for (var i = 0; i < valores.length; i++) {
      final p = Offset(i * passo, y(valores[i]));
      if (i == 0) {
        caminho.moveTo(p.dx, p.dy);
      } else {
        caminho.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      caminho,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < valores.length; i++) {
      canvas.drawCircle(Offset(i * passo, y(valores[i])), 2.5, Paint()..color = cor);
    }
  }

  @override
  bool shouldRepaint(_MiniCurvePainter old) =>
      old.valores != valores || old.cor != cor;
}
