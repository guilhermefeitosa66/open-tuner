import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'registro.dart';
import 'sintese.dart';

/// Quem toca os sons do app: a corda de referência e o aviso de afinada.
/// Devolve quanto tempo o som dura, para o afinador não se escutar.
abstract class Tocador {
  /// Toca a corda na [frequencia] exata e devolve a duração do som.
  Duration tocarCorda(double frequencia);

  /// Toca o aviso de corda afinada e devolve a duração do som.
  Duration tocarAfinada();

  void descartar();
}

/// O [Tocador] do aparelho, pelo plugin `audioplayers`, com os sons
/// sintetizados em memória ([cordaDedilhada] e [somAfinada]).
class TocadorAparelho implements Tocador {
  TocadorAparelho();

  AudioPlayer? _jogador;
  final Map<int, _Som> _cordas = {};
  _Som? _afinada;

  /// Um só jogador: uma corda nova corta a anterior, como a mão na corda.
  AudioPlayer get _pronto => _jogador ??= AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop)
    ..setAudioContext(_contexto);

  /// No iOS a sessão de áudio é uma só para o app: a categoria `playback`,
  /// que o plugin escolhe por padrão, desligaria o microfone a cada corda
  /// tocada. Fica em `playAndRecord`, com as opções do gravador
  /// (`FonteAudioMicrofone`) mais o `duckOthers`, saindo pelo alto-falante e
  /// não pelo fone de ouvido do telefone.
  static final _contexto = AudioContext(
    android: AudioContextConfig(
      focus: AudioContextConfigFocus.duckOthers,
    ).buildAndroid(),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playAndRecord,
      options: const {
        AVAudioSessionOptions.defaultToSpeaker,
        AVAudioSessionOptions.allowBluetoothA2DP,
        AVAudioSessionOptions.duckOthers,
      },
    ),
  );

  @override
  Duration tocarCorda(double frequencia) {
    // Centésimos de hertz bastam para a chave (bem abaixo de 1 cent).
    final som = _cordas.putIfAbsent(
      (frequencia * 100).round(),
      () => _Som(cordaDedilhada(frequencia)),
    );
    _tocar(som);
    return som.duracao;
  }

  @override
  Duration tocarAfinada() {
    final som = _afinada ??= _Som(somAfinada());
    _tocar(som);
    return som.duracao;
  }

  void _tocar(_Som som) {
    final jogador = _pronto;
    unawaited(() async {
      try {
        await jogador.stop();
        await jogador.play(BytesSource(som.bytes, mimeType: 'audio/wav'));
      } catch (erro) {
        registrar('não foi possível tocar: $erro');
      }
    }());
  }

  @override
  void descartar() {
    unawaited(_jogador?.dispose());
    _jogador = null;
  }
}

class _Som {
  _Som(Float64List amostras)
    : bytes = wav(amostras),
      duracao = Duration(microseconds: (duracaoDe(amostras) * 1000000).round());

  final Uint8List bytes;
  final Duration duracao;
}
