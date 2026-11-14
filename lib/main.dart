import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.instance.carregar();
  runApp(const TeachEqApp());
}

class TeachEqApp extends StatelessWidget {
  const TeachEqApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema escuro: ambiente de evento costuma ter pouca luz.
    final esquema = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1D9E75),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'TeachEQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: esquema,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
