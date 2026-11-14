import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';

/// Pergunta em qual banco aplicar uma mudança. Se [preferirPa] e o usuário já
/// marcou um banco como PA, usa esse direto, sem perguntar.
Future<int?> escolherBanco(BuildContext context, {bool preferirPa = true}) async {
  final s = AppState.instance;
  if (preferirPa && s.bancoDoPa != null) return s.bancoDoPa;
  String rotulo(int i) {
    final f = s.funcoes[i];
    final nome = i == 0 ? 'Banco de cima' : 'Banco de baixo';
    return f == FuncaoBanco.naoSei ? nome : '$nome · ${nomesFuncao[f]}';
  }

  return showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Aplicar em qual banco?'),
      children: [
        for (var i = 0; i < 2; i++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(rotulo(i)),
            ),
          ),
      ],
    ),
  );
}
