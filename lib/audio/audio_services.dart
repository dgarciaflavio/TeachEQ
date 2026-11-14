import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

import 'signal_generator.dart';

/// Captura o microfone do celular como amostras −1..1 (PCM 16 bits, mono).
/// Ganho automático, cancelamento de eco e supressão de ruído ficam
/// desligados: queremos o som real da sala, sem tratamento do Android.
class MicrofoneService {
  MicrofoneService({this.sampleRate = 44100});

  final int sampleRate;
  final AudioRecorder _rec = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;

  Future<bool> temPermissao() => _rec.hasPermission();

  RecordConfig _config(AndroidAudioSource fonte) => RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        androidConfig: AndroidRecordConfig(audioSource: fonte),
      );

  Future<void> iniciar(void Function(List<double> amostras) aoReceber) async {
    await parar();
    Stream<Uint8List> stream;
    try {
      // "unprocessed" entrega o som cru (ideal para medir), mas nem todo
      // celular suporta. "voiceRecognition" é a alternativa menos tratada.
      stream = await _rec.startStream(_config(AndroidAudioSource.unprocessed));
    } catch (_) {
      if (await _rec.isRecording()) await _rec.stop();
      stream = await _rec.startStream(_config(AndroidAudioSource.voiceRecognition));
    }
    _sub = stream.listen((dados) {
      final bd = ByteData.sublistView(dados);
      final n = dados.length ~/ 2;
      final amostras = List<double>.filled(n, 0);
      for (var i = 0; i < n; i++) {
        amostras[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
      }
      aoReceber(amostras);
    });
  }

  Future<void> parar() async {
    await _sub?.cancel();
    _sub = null;
    if (await _rec.isRecording()) await _rec.stop();
  }

  Future<void> descartar() async {
    await parar();
    await _rec.dispose();
  }
}

/// Toca os sinais de teste. Um único player para o app inteiro.
class GeradorService {
  GeradorService._();
  static final GeradorService instance = GeradorService._();

  final AudioPlayer _player = AudioPlayer();
  Uint8List? _rosaCache;
  final Map<int, Uint8List> _tomCache = {};

  /// Descrição do que está tocando agora (null = parado).
  String? tocando;

  Future<void> tocarRuidoRosa({double volume = 0.5}) async {
    _rosaCache ??= montarWav(ruidoRosa());
    await _tocar(_rosaCache!, loop: true, volume: volume);
    tocando = 'Ruído rosa';
  }

  Future<void> tocarTom(double hz, {double volume = 0.5, bool loop = true}) async {
    final chave = hz.round() * (loop ? 1 : -1);
    final wav = _tomCache[chave] ??=
        montarWav(loop ? tomSenoidal(hz) : tomCurto(hz));
    await _tocar(wav, loop: loop, volume: volume);
    tocando = loop ? 'Tom ${hz.round()} Hz' : null;
  }

  /// Toca um áudio qualquer gerado no app (ex.: exercício de treino).
  Future<void> tocarAmostras(Float64List amostras, String rotulo,
      {double volume = 0.6, bool loop = true}) async {
    await _tocar(montarWav(amostras), loop: loop, volume: volume);
    tocando = rotulo;
  }

  Future<void> setVolume(double v) => _player.setVolume(v);

  Future<void> parar() async {
    tocando = null;
    await _player.stop();
  }

  Future<void> _tocar(Uint8List wav, {required bool loop, required double volume}) async {
    await _player.stop();
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await _player.setVolume(volume);
    await _player.play(BytesSource(wav));
  }
}
