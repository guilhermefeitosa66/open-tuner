import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:open_tuner/audio/fonte_audio.dart';
import 'package:open_tuner/dados/ajustes.dart';
import 'package:open_tuner/dados/preferencias.dart';
import 'package:open_tuner/features/afinador/controlador_afinador.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'abrir_app.dart';

/// Fonte de áudio síncrona: cada bloco entregue por [ControladorSincrono]
/// chega ao controlador na hora, sem relógio nenhum.
class FonteSincrona implements FonteAudio {
  StreamController<List<double>>? _controle;

  @override
  final int taxaAmostragem = 44100;

  bool get escutando => _controle != null;

  void entregar(List<double> bloco) => _controle?.add(bloco);

  @override
  Future<EstadoPermissao> estadoPermissao() async => EstadoPermissao.concedida;

  @override
  Future<EstadoPermissao> pedirPermissao() async => EstadoPermissao.concedida;

  @override
  Future<void> abrirConfiguracoes() async {}

  @override
  Future<Stream<List<double>>> iniciar() async {
    final controle = _controle = StreamController<List<double>>(sync: true);
    return controle.stream;
  }

  @override
  Future<void> parar() async {
    unawaited(_controle?.close());
    _controle = null;
  }

  @override
  Future<void> descartar() => parar();
}

/// O ControladorAfinador com uma fonte síncrona: cada bloco de
/// [amostrasPorAnalise] amostras vira uma análise, e a leitura da tela depois
/// de cada uma fica em [leituras].
class ControladorSincrono {
  ControladorSincrono._(
    this.controlador,
    this.fonte,
    this.tocador,
    this.ajustes,
  );

  /// Abre o controlador já escutando, com as [preferencias] gravadas.
  static Future<ControladorSincrono> abrir({
    Map<String, Object> preferencias = const {},
  }) async {
    SharedPreferences.setMockInitialValues(preferencias);
    final prefs = await Preferencias.carregar();
    final ajustes = Ajustes(prefs);
    final fonte = FonteSincrona();
    final tocador = TocadorFalso();
    late final ControladorSincrono sincrono;
    final controlador = ControladorAfinador(
      fonte: fonte,
      preferencias: prefs,
      ajustes: ajustes,
      definirTelaLigada: (_) async {},
      vibrar: () async => sincrono.vibracoes++,
      tocador: tocador,
    );
    sincrono = ControladorSincrono._(controlador, fonte, tocador, ajustes);
    await controlador.retomar();
    // Enche a janela do detector em silêncio, para que cada bloco seguinte
    // seja exatamente uma análise.
    fonte.entregar(Float64List(8192));
    sincrono.leituras.clear();
    sincrono.tempos.clear();
    return sincrono;
  }

  static const amostrasPorAnalise = 1764;

  final ControladorAfinador controlador;
  final FonteSincrona fonte;
  final TocadorFalso tocador;
  final Ajustes ajustes;
  int vibracoes = 0;

  /// A leitura da tela depois de cada análise, e o instante dela.
  final List<LeituraTela> leituras = [];
  final List<double> tempos = [];
  double _tempo = 0;
  double _fase = 0;

  /// Segundos de som entregues.
  double get tempo => _tempo;

  LeituraTela get leitura => controlador.leitura.value;

  /// [analises] análises de um seno em [frequencia] (null: silêncio), com
  /// [amplitude]. [frequencia] e [amplitude] também podem variar por
  /// análise, com [frequencias] e [amplitudes].
  void tocar(
    double? frequencia,
    int analises, {
    double amplitude = 0.5,
    double? Function(int i)? frequencias,
    double Function(int i)? amplitudes,
  }) {
    const taxa = 44100;
    for (var i = 0; i < analises; i++) {
      final f = frequencias != null ? frequencias(i) : frequencia;
      final a = amplitudes != null ? amplitudes(i) : amplitude;
      final bloco = Float64List(amostrasPorAnalise);
      if (f != null) {
        final passo = 2 * math.pi * f / taxa;
        for (var k = 0; k < amostrasPorAnalise; k++) {
          bloco[k] = a * math.sin(_fase);
          _fase += passo;
        }
        _fase %= 2 * math.pi;
      }
      fonte.entregar(bloco);
      _tempo += amostrasPorAnalise / taxa;
      leituras.add(controlador.leitura.value);
      tempos.add(_tempo);
    }
  }

  void descartar() => controlador.dispose();
}
