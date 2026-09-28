import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'registro.dart';

/// Situação da permissão do microfone, do ponto de vista da tela.
enum EstadoPermissao {
  /// Ainda não se sabe (antes da primeira consulta).
  desconhecida,

  /// Pode ser pedida: nunca foi pedida, ou foi negada uma vez.
  pendente,

  /// Liberada: o afinador pode escutar.
  concedida,

  /// Negada de vez (ou restrita pelo sistema): só pelas configurações do app.
  negadaDeVez,
}

/// De onde vem o som. A tela e o controlador só conhecem esta interface; o
/// microfone de verdade é [FonteAudioMicrofone], e os testes usam uma fonte
/// sintética.
abstract class FonteAudio {
  /// Amostras por segundo do que [iniciar] entrega.
  int get taxaAmostragem;

  Future<EstadoPermissao> estadoPermissao();

  /// Mostra o pedido do sistema e devolve o resultado.
  Future<EstadoPermissao> pedirPermissao();

  /// Abre a página do app nas configurações do sistema.
  Future<void> abrirConfiguracoes();

  /// Começa a escutar. As amostras chegam em blocos, mono, de −1 a 1, na
  /// taxa [taxaAmostragem].
  Future<Stream<List<double>>> iniciar();

  /// Para de escutar e solta o microfone. Pode ser chamado sem ter iniciado.
  Future<void> parar();

  /// Solta tudo de vez.
  Future<void> descartar();
}

/// O microfone do aparelho, pelo plugin `record`, com a permissão pelo
/// `permission_handler`.
class FonteAudioMicrofone implements FonteAudio {
  FonteAudioMicrofone();

  /// 44,1 kHz é a única taxa que todo Android garante no `AudioRecord`.
  static const _taxa = 44100;

  /// Fontes de áudio do Android, da mais crua para a mais comum. A de
  /// reconhecimento de voz é a que o Android pede sem ganho automático nem
  /// supressão de ruído, que achatam a nota e atrapalham o detector; a
  /// `unprocessed` é opcional no aparelho e, em vários, chega muda. Se uma
  /// falhar ao abrir, tenta a seguinte.
  static const _fontesAndroid = [
    AndroidAudioSource.voiceRecognition,
    AndroidAudioSource.mic,
    AndroidAudioSource.defaultSource,
  ];

  AudioRecorder? _gravador;

  @override
  int get taxaAmostragem => _taxa;

  @override
  Future<EstadoPermissao> estadoPermissao() async =>
      _traduzir(await Permission.microphone.status);

  @override
  Future<EstadoPermissao> pedirPermissao() async =>
      _traduzir(await Permission.microphone.request());

  @override
  Future<void> abrirConfiguracoes() async {
    await openAppSettings();
  }

  static EstadoPermissao _traduzir(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return EstadoPermissao.concedida;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return EstadoPermissao.negadaDeVez;
      case PermissionStatus.denied:
        return EstadoPermissao.pendente;
    }
  }

  @override
  Future<Stream<List<double>>> iniciar() async {
    final gravador = _gravador ??= AudioRecorder();
    Object? ultimoErro;
    for (final fonte in _fontesAndroid) {
      try {
        final bytes = await gravador.startStream(_configuracao(fonte));
        return bytes.transform(const ConversorPcm16());
      } catch (erro) {
        ultimoErro = erro;
        registrar('fonte de áudio $fonte falhou: $erro');
      }
    }
    throw StateError('Nenhuma fonte de áudio abriu: $ultimoErro');
  }

  RecordConfig _configuracao(AndroidAudioSource fonte) => RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: _taxa,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
    androidConfig: AndroidRecordConfig(
      audioSource: fonte,
      // Um fone Bluetooth puxaria o áudio para o SCO, de 8 ou 16 kHz.
      manageBluetooth: false,
    ),
  );

  @override
  Future<void> parar() async {
    final gravador = _gravador;
    if (gravador == null) return;
    try {
      await gravador.stop();
    } catch (erro) {
      registrar('falha ao parar o microfone: $erro');
    }
  }

  @override
  Future<void> descartar() async {
    final gravador = _gravador;
    _gravador = null;
    await gravador?.dispose();
  }
}

/// Converte PCM de 16 bits little-endian em amostras de −1 a 1. Um byte que
/// sobre no fim de um bloco (meia amostra) fica guardado para o seguinte.
class ConversorPcm16 extends StreamTransformerBase<Uint8List, List<double>> {
  const ConversorPcm16();

  @override
  Stream<List<double>> bind(Stream<Uint8List> origem) {
    int? sobra;
    return origem.map((bloco) {
      final bytes = sobra == null
          ? bloco
          : (Uint8List(bloco.length + 1)
              ..[0] = sobra!
              ..setRange(1, bloco.length + 1, bloco));
      sobra = bytes.length.isOdd ? bytes.last : null;
      return converterPcm16(bytes);
    });
  }
}

/// Amostras de 16 bits little-endian em [bytes], de −1 a 1. Um byte ímpar no
/// fim é ignorado.
Float64List converterPcm16(Uint8List bytes) {
  final quantidade = bytes.length ~/ 2;
  final dados = ByteData.sublistView(bytes);
  final amostras = Float64List(quantidade);
  for (var i = 0; i < quantidade; i++) {
    amostras[i] = dados.getInt16(i * 2, Endian.little) / 32768;
  }
  return amostras;
}
