import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../audio/audio_math.dart';
import '../data/bands.dart';

/// Espectro ao vivo em escala logarítmica (20 Hz a 20 kHz), com as 7
/// frequências da mesa marcadas. [destaqueHz] marca um apito detectado.
class SpectrumView extends StatelessWidget {
  const SpectrumView({
    super.key,
    required this.magDb,
    required this.binHz,
    this.destaqueHz,
    this.altura = 170,
  });

  final Float64List? magDb;
  final double binHz;
  final double? destaqueHz;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: altura,
      decoration: BoxDecoration(
        color: const Color(0xFF16181B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _SpectrumPainter(
          magDb,
          binHz,
          destaqueHz,
          cs.primary,
          cs.error,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter(this.mag, this.binHz, this.destaqueHz, this.cor, this.corAlerta);

  final Float64List? mag;
  final double binHz;
  final double? destaqueHz;
  final Color cor;
  final Color corAlerta;

  static const double dbMin = -100;
  static const double dbMax = 0;
  static const double fMin = 20;
  static const double fMax = 20000;

  double _x(double f, double w) =>
      math.log(f / fMin) / math.log(fMax / fMin) * w;

  double _f(double x, double w) => fMin * math.pow(fMax / fMin, x / w);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - 16; // espaço para os rótulos embaixo
    final grade = Paint()
      ..color = const Color(0xFF34383D)
      ..strokeWidth = 1;
    final estilo = const TextStyle(color: Color(0xFF9EA3A8), fontSize: 10);

    for (var i = 0; i < centrosBandas.length; i++) {
      final x = _x(centrosBandas[i], w);
      canvas.drawLine(Offset(x, 0), Offset(x, h), grade);
      final tp = TextPainter(
        text: TextSpan(text: bandas[i].rotulo, style: estilo),
        textDirection: TextDirection.ltr,
      )..layout();
      final px = (x - tp.width / 2).clamp(0.0, w - tp.width).toDouble();
      tp.paint(canvas, Offset(px, h + 2));
    }

    final m = mag;
    if (m == null) return;

    double y(double db) =>
        h - ((db - dbMin) / (dbMax - dbMin)).clamp(0.0, 1.0) * h;

    final caminho = Path();
    final area = Path()..moveTo(0, h);
    var primeiro = true;
    for (double x = 0; x <= w; x += 2) {
      final k0 = math.max(1, (_f(x, w) / binHz).floor());
      final k1 = math.min(m.length - 1, math.max(k0, (_f(x + 2, w) / binHz).floor()));
      var v = -200.0;
      for (var k = k0; k <= k1; k++) {
        v = math.max(v, m[k]);
      }
      final py = y(v);
      if (primeiro) {
        caminho.moveTo(x, py);
        primeiro = false;
      } else {
        caminho.lineTo(x, py);
      }
      area.lineTo(x, py);
    }
    area
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(area, Paint()..color = cor.withValues(alpha: 0.18));
    canvas.drawPath(
      caminho,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final d = destaqueHz;
    if (d != null) {
      final x = _x(d, w);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = corAlerta
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) => true;
}
