import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/presets.dart';
import '../models/models.dart';

/// Estado global do app, salvo localmente (funciona 100% offline).
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  SharedPreferences? _prefs;

  /// bancos[0] = banco de cima, bancos[1] = banco de baixo.
  final List<List<double>> bancos = [eqPlano(), eqPlano()];
  final List<FuncaoBanco> funcoes = [FuncaoBanco.naoSei, FuncaoBanco.naoSei];
  bool espelhar = false;

  final List<Projeto> projetos = [];
  final List<Preset> presetsPersonalizados = [];
  final Set<String> checklistMarcados = {};

  static const _kBancos = 'bancos';
  static const _kFuncoes = 'funcoes';
  static const _kEspelhar = 'espelhar';
  static const _kProjetos = 'projetos';
  static const _kPresets = 'presets';
  static const _kChecklist = 'checklist';

  Future<void> carregar() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    try {
      final b = p.getString(_kBancos);
      if (b != null) {
        final lista = jsonDecode(b) as List;
        for (var i = 0; i < 2 && i < lista.length; i++) {
          bancos[i] = lerValores(lista[i]);
        }
      }
      final f = p.getStringList(_kFuncoes);
      if (f != null) {
        for (var i = 0; i < 2 && i < f.length; i++) {
          funcoes[i] = FuncaoBanco.values.firstWhere(
            (e) => e.name == f[i],
            orElse: () => FuncaoBanco.naoSei,
          );
        }
      }
      espelhar = p.getBool(_kEspelhar) ?? false;
      final pr = p.getString(_kProjetos);
      if (pr != null) {
        projetos
          ..clear()
          ..addAll((jsonDecode(pr) as List)
              .map((e) => Projeto.fromJson(e as Map<String, dynamic>)));
      }
      final ps = p.getString(_kPresets);
      if (ps != null) {
        presetsPersonalizados
          ..clear()
          ..addAll((jsonDecode(ps) as List)
              .map((e) => Preset.fromJson(e as Map<String, dynamic>)));
      }
      checklistMarcados
        ..clear()
        ..addAll(p.getStringList(_kChecklist) ?? const []);
    } catch (e) {
      debugPrint('Falha ao carregar dados salvos: $e');
    }
    notifyListeners();
  }

  Future<void> _salvar() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kBancos, jsonEncode(bancos));
    await p.setStringList(_kFuncoes, funcoes.map((e) => e.name).toList());
    await p.setBool(_kEspelhar, espelhar);
    await p.setString(
        _kProjetos, jsonEncode(projetos.map((e) => e.toJson()).toList()));
    await p.setString(_kPresets,
        jsonEncode(presetsPersonalizados.map((e) => e.toJson()).toList()));
    await p.setStringList(_kChecklist, checklistMarcados.toList());
  }

  void _mudou() {
    notifyListeners();
    _salvar();
  }

  // ---------- Equalizador ----------

  void setBanda(int banco, int banda, double valor) {
    final v = valor.clamp(-12.0, 12.0).roundToDouble();
    if (bancos[banco][banda] == v) return;
    bancos[banco][banda] = v;
    if (espelhar) bancos[1 - banco][banda] = v;
    _mudou();
  }

  void aplicarValores(int banco, List<double> valores) {
    bancos[banco] = List<double>.of(valores);
    if (espelhar) bancos[1 - banco] = List<double>.of(valores);
    _mudou();
  }

  void zerar(int banco) => aplicarValores(banco, eqPlano());

  void setFuncao(int banco, FuncaoBanco f) {
    funcoes[banco] = f;
    _mudou();
  }

  void setEspelhar(bool v, {int origem = 0}) {
    espelhar = v;
    if (v) bancos[1 - origem] = List<double>.of(bancos[origem]);
    _mudou();
  }

  // ---------- Presets ----------

  List<Preset> get todosPresets => [...presetsProntos, ...presetsPersonalizados];

  void salvarPreset(String nome, String quando, List<double> valores) {
    presetsPersonalizados.add(Preset(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      nome: nome,
      quando: quando,
      valores: List<double>.of(valores),
      personalizado: true,
    ));
    _mudou();
  }

  void excluirPreset(String id) {
    presetsPersonalizados.removeWhere((p) => p.id == id);
    _mudou();
  }

  // ---------- Projetos ----------

  Projeto novoProjeto(String nome, String local) {
    final p = Projeto(
      id: 'e${DateTime.now().millisecondsSinceEpoch}',
      nome: nome,
      local: local,
      eqCima: List<double>.of(bancos[0]),
      eqBaixo: List<double>.of(bancos[1]),
    );
    projetos.insert(0, p);
    _mudou();
    return p;
  }

  void atualizarProjeto() => _mudou();

  void excluirProjeto(String id) {
    projetos.removeWhere((p) => p.id == id);
    _mudou();
  }

  void carregarEqDoProjeto(Projeto p) {
    bancos[0] = List<double>.of(p.eqCima);
    bancos[1] = List<double>.of(p.eqBaixo);
    _mudou();
  }

  void salvarEqNoProjeto(Projeto p) {
    p.eqCima = List<double>.of(bancos[0]);
    p.eqBaixo = List<double>.of(bancos[1]);
    _mudou();
  }

  /// Último projeto salvo no mesmo local (para reaproveitar o ajuste).
  Projeto? ultimoNoLocal(String local, {String? exceto}) {
    final alvo = local.trim().toLowerCase();
    if (alvo.isEmpty) return null;
    for (final p in projetos) {
      if (p.id != exceto && p.local.trim().toLowerCase() == alvo) return p;
    }
    return null;
  }

  String exportarProjetoJson(Projeto p) =>
      const JsonEncoder.withIndent('  ').convert(p.toJson());

  /// Importa um projeto colado como texto JSON. Retorna null se inválido.
  Projeto? importarProjetoJson(String texto) {
    try {
      final j = jsonDecode(texto) as Map<String, dynamic>;
      final p = Projeto.fromJson({
        ...j,
        'id': 'e${DateTime.now().millisecondsSinceEpoch}',
      });
      projetos.insert(0, p);
      _mudou();
      return p;
    } catch (_) {
      return null;
    }
  }

  // ---------- Checklist ----------

  void marcarItem(String chave, bool marcado) {
    if (marcado) {
      checklistMarcados.add(chave);
    } else {
      checklistMarcados.remove(chave);
    }
    _mudou();
  }

  void limparChecklist() {
    checklistMarcados.clear();
    _mudou();
  }
}
