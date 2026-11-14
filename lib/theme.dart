import 'package:flutter/material.dart';

/// Paleta do TeachEQ, tirada do ícone e da própria mesa: painel grafite,
/// botões creme e o vermelho do visor do DSP.
abstract final class CoresTeachEq {
  static const fundo = Color(0xFF1C1D21);
  static const trilho = Color(0xFF0B0C0E);
  static const creme = Color(0xFFEDE6D6);
  static const cremeApagado = Color(0xFFA8A296);
  static const linhaZero = Color(0xFF5C5A54);
  static const vermelho = Color(0xFFFF5A36);
}

ThemeData temaTeachEq() {
  final base = ColorScheme.fromSeed(
    seedColor: CoresTeachEq.vermelho,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  // Superfícies neutras (grafite), sem o tom avermelhado que o seed daria.
  final esquema = base.copyWith(
    surface: CoresTeachEq.fundo,
    surfaceContainerLowest: const Color(0xFF151619),
    surfaceContainerLow: const Color(0xFF202125),
    surfaceContainer: const Color(0xFF25262B),
    surfaceContainerHigh: const Color(0xFF2C2E33),
    surfaceContainerHighest: const Color(0xFF34363C),
    onSurface: CoresTeachEq.creme,
    onSurfaceVariant: CoresTeachEq.cremeApagado,
    outlineVariant: const Color(0xFF3E4046),
  );
  return ThemeData(
    colorScheme: esquema,
    useMaterial3: true,
    scaffoldBackgroundColor: CoresTeachEq.fundo,
    appBarTheme: const AppBarTheme(
      backgroundColor: CoresTeachEq.fundo,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
