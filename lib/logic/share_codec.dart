import 'dart:convert';
import 'dart:io' show gzip;

import '../data/presets.dart';
import '../models/models.dart';

/// Formato dos códigos de compartilhamento (QR ou texto):
///   TEQ1:<base64url(gzip(json))>
/// O json tem {"k": tipo, "d": dados}. Comprimido, um evento com EQ, mapa e
/// anotações cabe num QR code que a câmera lê com facilidade.
const String prefixoCodigo = 'TEQ1:';

/// Acima disso o QR fica denso demais para ler da tela de outro celular.
const int limiteCaracteresQr = 1500;

enum TipoPacote { preset, evento, mapa }

class Pacote {
  const Pacote(this.tipo, this.codigo, {this.cortouNotas = false, this.cortouMapa = false});
  final TipoPacote tipo;
  final String codigo;

  /// Anotações do evento ficaram de fora para caber no QR.
  final bool cortouNotas;

  /// O mapa de canais do evento também ficou de fora.
  final bool cortouMapa;
}

String _empacotar(String tipo, Map<String, dynamic> dados) {
  final json = jsonEncode({'k': tipo, 'd': dados});
  return prefixoCodigo + base64Url.encode(gzip.encode(utf8.encode(json)));
}

Pacote codificarPreset(Preset p) => Pacote(
      TipoPacote.preset,
      _empacotar('preset', {'nome': p.nome, 'quando': p.quando, 'valores': p.valores}),
    );

Pacote codificarEvento(Projeto p) {
  final dados = p.toJson()..remove('id');
  var codigo = _empacotar('evento', dados);
  var cortouNotas = false, cortouMapa = false;
  if (codigo.length > limiteCaracteresQr) {
    dados
      ..remove('notas')
      ..remove('problemas');
    cortouNotas = true;
    codigo = _empacotar('evento', dados);
  }
  if (codigo.length > limiteCaracteresQr) {
    dados.remove('mapa');
    cortouMapa = true;
    codigo = _empacotar('evento', dados);
  }
  return Pacote(TipoPacote.evento, codigo, cortouNotas: cortouNotas, cortouMapa: cortouMapa);
}

/// Código de evento sem limite de tamanho (para copiar e colar por texto).
String codificarEventoCompleto(Map<String, dynamic> dados) => _empacotar('evento', dados);

Pacote codificarMapa(MapaMesa m) => Pacote(TipoPacote.mapa, _empacotar('mapa', m.toJson()));

/// Conteúdo lido de um código.
sealed class ConteudoLido {}

class PresetLido extends ConteudoLido {
  PresetLido(this.preset);
  final Preset preset;
}

class EventoLido extends ConteudoLido {
  EventoLido(this.projeto);
  final Projeto projeto;
}

class MapaLido extends ConteudoLido {
  MapaLido(this.mapa);
  final MapaMesa mapa;
}

/// Lê um código TEQ1 (ou o JSON antigo de evento, copiado na versão 1).
/// Devolve null se o texto não for um código válido do TeachEQ.
ConteudoLido? decodificar(String texto) {
  final t = texto.trim();
  try {
    if (t.startsWith(prefixoCodigo)) {
      final bytes = gzip.decode(base64Url.decode(t.substring(prefixoCodigo.length)));
      final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final d = j['d'] as Map<String, dynamic>;
      final novoId = DateTime.now().millisecondsSinceEpoch;
      switch (j['k']) {
        case 'preset':
          return PresetLido(Preset.fromJson({...d, 'id': 'p$novoId'}));
        case 'evento':
          return EventoLido(Projeto.fromJson({...d, 'id': 'e$novoId'}));
        case 'mapa':
          return MapaLido(MapaMesa.fromJson(d));
      }
      return null;
    }
    if (t.startsWith('{')) {
      final j = jsonDecode(t) as Map<String, dynamic>;
      if (j.containsKey('eqCima')) {
        return EventoLido(Projeto.fromJson(
            {...j, 'id': 'e${DateTime.now().millisecondsSinceEpoch}'}));
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
