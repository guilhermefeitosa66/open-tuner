import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:open_tuner/audio/fonte_audio.dart';

/// Fonte de áudio sintética para os testes: um seno na [frequencia] escolhida
/// (ou silêncio, com null), entregue em blocos por um `Timer` periódico, no
/// ritmo do tempo real. Dentro de `testWidgets` o tempo é falso: cada
/// `tester.pump(duração)` entrega o áudio daquela duração.
class FonteAudioFalsa implements FonteAudio {
  FonteAudioFalsa({
    this.permissao = EstadoPermissao.concedida,
    this.respostaAoPedido = EstadoPermissao.concedida,
    this.frequencia,
    this.amplitude = 0.5,
    this.taxaAmostragem = 44100,
    this.amostrasPorBloco = 1764,
  });

  /// O que [estadoPermissao] responde.
  EstadoPermissao permissao;

  /// O que o "usuário" responde ao pedido do sistema.
  EstadoPermissao respostaAoPedido;

  /// Frequência do seno em Hz; null é silêncio.
  double? frequencia;

  double amplitude;

  @override
  final int taxaAmostragem;

  final int amostrasPorBloco;

  int pedidos = 0;
  int aberturasDeConfiguracoes = 0;
  int inicios = 0;
  int paradas = 0;

  StreamController<List<double>>? _controle;
  Timer? _relogio;
  double _fase = 0;

  bool get escutando => _relogio != null;

  /// Frequência [cents] acima (ou abaixo) de [alvo].
  static double desviada(double alvo, double cents) =>
      alvo * math.pow(2, cents / 1200);

  @override
  Future<EstadoPermissao> estadoPermissao() async => permissao;

  @override
  Future<EstadoPermissao> pedirPermissao() async {
    pedidos++;
    permissao = respostaAoPedido;
    return permissao;
  }

  @override
  Future<void> abrirConfiguracoes() async {
    aberturasDeConfiguracoes++;
  }

  @override
  Future<Stream<List<double>>> iniciar() async {
    inicios++;
    _pararRelogio();
    final controle = _controle = StreamController<List<double>>();
    final intervalo = Duration(
      microseconds: amostrasPorBloco * 1000000 ~/ taxaAmostragem,
    );
    _relogio = Timer.periodic(intervalo, (_) => controle.add(_bloco()));
    return controle.stream;
  }

  Float64List _bloco() {
    final bloco = Float64List(amostrasPorBloco);
    final f = frequencia;
    if (f == null) return bloco;
    final passo = 2 * math.pi * f / taxaAmostragem;
    for (var i = 0; i < amostrasPorBloco; i++) {
      bloco[i] = amplitude * math.sin(_fase);
      _fase += passo;
    }
    _fase %= 2 * math.pi;
    return bloco;
  }

  void _pararRelogio() {
    _relogio?.cancel();
    _relogio = null;
    unawaited(_controle?.close());
    _controle = null;
  }

  @override
  Future<void> parar() async {
    if (_relogio != null) paradas++;
    _pararRelogio();
  }

  @override
  Future<void> descartar() async => _pararRelogio();
}
