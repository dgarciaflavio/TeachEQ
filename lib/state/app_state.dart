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

  /// Soma em dB para converter dBFS do microfone em dB SPL estimado.
  /// Varia de celular para celular; o usuário pode calibrar.
  static const double offsetPadrao = 130;
  double offsetCalibracao = offsetPadrao;

  /// Mapa de canais atual da mesa.
  MapaMesa mapa = MapaMesa();
  static const _kMapa = 'mapa';

  /// Placar do modo treino.
  int treinoAcertos = 0;
  int treinoTentativas = 0;
  int treinoSequencia = 0;
  int treinoMelhorSequencia = 0;

  static const _kTreino = 'treino';
  static const _kOffset = 'offsetCalibracao';
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
      offsetCalibracao = p.getDouble(_kOffset) ?? offsetPadrao;
      final m = p.getString(_kMapa);
      if (m != null) mapa = MapaMesa.fromJson(jsonDecode(m) as Map<String, dynamic>);
      final t = p.getStringList(_kTreino);
      if (t != null && t.length == 4) {
        treinoAcertos = int.tryParse(t[0]) ?? 0;
        treinoTentativas = int.tryParse(t[1]) ?? 0;
        treinoSequencia = int.tryParse(t[2]) ?? 0;
        treinoMelhorSequencia = int.tryParse(t[3]) ?? 0;
      }
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
    await p.setDouble(_kOffset, offsetCalibracao);
    await p.setString(_kMapa, jsonEncode(mapa.toJson()));
    await p.setStringList(_kTreino, [
      '$treinoAcertos',
      '$treinoTentativas',
      '$treinoSequencia',
      '$treinoMelhorSequencia',
    ]);
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

  /// Soma [delta] dB a uma banda (ex.: −3 para baixar onde houve microfonia).
  void ajustarBanda(int banco, int banda, double delta) =>
      setBanda(banco, banda, bancos[banco][banda] + delta);

  /// Banco marcado como PA, se o usuário já informou.
  int? get bancoDoPa {
    final i = funcoes.indexOf(FuncaoBanco.pa);
    return i >= 0 ? i : null;
  }

  // ---------- Mapa de canais ----------

  void atualizarMapa() => _mudou();

  void substituirMapa(MapaMesa novo) {
    mapa = novo.copia();
    _mudou();
  }

  // ---------- Treino ----------

  void registrarTreino(bool acertou) {
    treinoTentativas++;
    if (acertou) {
      treinoAcertos++;
      treinoSequencia++;
      if (treinoSequencia > treinoMelhorSequencia) {
        treinoMelhorSequencia = treinoSequencia;
      }
    } else {
      treinoSequencia = 0;
    }
    _mudou();
  }

  void zerarTreino() {
    treinoAcertos = 0;
    treinoTentativas = 0;
    treinoSequencia = 0;
    treinoMelhorSequencia = 0;
    _mudou();
  }

  void setOffsetCalibracao(double v) {
    offsetCalibracao = v;
    _mudou();
  }

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
      mapa: mapa.emUso > 0 ? mapa.copia() : null,
    );
    projetos.insert(0, p);
    _mudou();
    return p;
  }

  void atualizarProjeto() => _mudou();

  /// Adiciona um evento recebido de outro celular.
  void adicionarProjeto(Projeto p) {
    projetos.insert(0, p);
    _mudou();
  }

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
