import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.carregar();
  runApp(const TeachEqApp());
}

class TeachEqApp extends StatelessWidget {
  const TeachEqApp({super.key, this.comAbertura = true});

  /// Mostra a animação de abertura (desligada nos testes).
  final bool comAbertura;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeachEQ',
      debugShowCheckedModeBanner: false,
      theme: temaTeachEq(),
      home: comAbertura ? const SplashScreen() : const HomeScreen(),
    );
  }
}
