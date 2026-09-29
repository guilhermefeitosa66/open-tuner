import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../audio/fonte_audio.dart';
import '../../audio/janela_deslizante.dart';
import '../../audio/registro.dart';
import '../../audio/tocador.dart';
import '../../dados/ajustes.dart';
import '../../dados/preferencias.dart';
import '../../dominio/afinacoes.dart';
import '../../dominio/detector.dart';
import '../../dominio/dobra_harmonicos.dart';
import '../../dominio/escolha_corda.dart';
import '../../dominio/estado_corda.dart';
import '../../dominio/filtro_kalman.dart';
import '../../dominio/marcador_afinada.dart';
import '../../dominio/nota.dart';
import 'historico_leituras.dart';

/// O que o indicador mostra agora.
@immutable
class LeituraTela {
  const LeituraTela({
    required this.corda,
    required this.cents,
    required this.frequencia,
    required this.estado,
    this.numero = 0,
    this.progresso = 0,
  });

  /// Nenhuma corda soando: indicador vazio no centro.
  static const ociosa = LeituraTela(
    corda: null,
    cents: 0,
    frequencia: 0,
    estado: null,
  );

  /// Índice da corda alvo na afinação.
  final int? corda;

  /// Onde fica o ponteiro: o desvio até a corda alvo, em cents, já sem o
  /// tremor da leitura.
  final double cents;

  /// O número escrito no indicador, em cents inteiros. Tem histerese: fica
  /// parado com a corda parada, e anda em escada com a tarraxa.
  final int numero;

  /// Frequência medida, em Hz.
  final double frequencia;

  /// null quando ociosa.
  final EstadoCorda? estado;

  /// Quanto falta para a corda ganhar a marca, de 0 a 1: enche o indicador.
  final double progresso;

  bool get ehOciosa => estado == null;

  @override
  bool operator ==(Object outro) =>
      outro is LeituraTela &&
      outro.corda == corda &&
      outro.cents == cents &&
      outro.frequencia == frequencia &&
      outro.estado == estado &&
      outro.numero == numero &&
      outro.progresso == progresso;

  @override
  int get hashCode =>
      Object.hash(corda, cents, frequencia, estado, numero, progresso);
}

/// Liga e desliga o "manter a tela ligada".
typedef DefinirTelaLigada = Future<void> Function(bool ligada);

Future<void> _telaLigadaPeloPlugin(bool ligada) async {
  try {
    await WakelockPlus.toggle(enable: ligada);
  } catch (erro) {
    registrar('wakelock falhou: $erro');
  }
}

Future<void> _vibrarCurto() => HapticFeedback.vibrate();

/// O afinador por trás da tela: escuta a [FonteAudio], detecta a frequência,
/// leva de volta à fundamental as leituras num harmônico ([DobraHarmonicos]),
/// escolhe a corda, filtra o que a tela mostra ([FiltroKalman]: ponteiro,
/// número e marca de afinada) e marca as cordas afinadas.
///
/// Três canais de aviso, para a tela redesenhar só o que mudou:
/// - o próprio controlador: instrumento, afinação, Auto, corda alvo, cordas
///   afinadas e permissão (muda pouco);
/// - [leitura]: o indicador, a cada análise;
/// - [historico]: o rastro, a cada análise.
class ControladorAfinador extends ChangeNotifier {
  ControladorAfinador({
    required this.fonte,
    required Preferencias preferencias,
    required this.ajustes,
    DefinirTelaLigada? definirTelaLigada,
    Future<void> Function()? vibrar,
    Tocador? tocador,
  }) : _preferencias = preferencias,
       _definirTelaLigada = definirTelaLigada ?? _telaLigadaPeloPlugin,
       _vibrar = vibrar ?? _vibrarCurto,
       _tocador = tocador ?? TocadorAparelho() {
    _instrumento = instrumentoPorId(preferencias.instrumento ?? '');
    _afinacao = _instrumento.afinacao(preferencias.afinacao ?? '');
    _auto = preferencias.auto;
    _escolha = EscolhaCorda(alvos: _alvos(), pares: _instrumento.pares);
    _dobra = DobraHarmonicos(alvos: _alvos(), pares: _instrumento.pares);
    if (!_auto) {
      _escolha.fixar(
        preferencias.cordaFixada.clamp(0, _afinacao.notas.length - 1).toInt(),
      );
    }
    _montarDetector();
    _a4 = ajustes.a4;
    ajustes.addListener(_aoMudarAjustes);
  }

  final FonteAudio fonte;
  final Ajustes ajustes;
  final Preferencias _preferencias;
  final DefinirTelaLigada _definirTelaLigada;
  final Future<void> Function() _vibrar;
  final Tocador _tocador;

  /// Análises por segundo (o salto da janela sai daqui).
  static const analisesPorSegundo = 25;

  /// Depois de um som do próprio app, quanto tempo a mais o afinador fica
  /// surdo, pelo eco e pelo atraso do alto-falante.
  static const folgaDoSom = 0.25;

  /// Sem nenhuma corda soando por este tempo, as marcas somem (RF-09).
  static const tempoParaLimparMarcas = 120.0;

  /// Silêncio depois do qual o indicador volta ao centro, vazio.
  static const tempoParaOcioso = 1.5;

  final HistoricoLeituras historico = HistoricoLeituras();
  final ValueNotifier<LeituraTela> leitura = ValueNotifier(LeituraTela.ociosa);

  late Instrumento _instrumento;
  late Afinacao _afinacao;
  late bool _auto;
  late EscolhaCorda _escolha;
  late DobraHarmonicos _dobra;
  late DetectorFrequencia _detector;
  late JanelaDeslizante _janela;
  late int _a4;
  late final FiltroKalman _filtro = FiltroKalman(precisao: ajustes.precisao);
  final MarcadorAfinada _marcador = MarcadorAfinada();
  final Set<int> _afinadas = {};
  EstadoPermissao _permissao = EstadoPermissao.desconhecida;

  bool _visivel = false;
  bool _descartado = false;
  bool _iniciando = false;
  StreamSubscription<List<double>>? _assinatura;

  /// Relógio do áudio, em segundos de som analisado. Mede o tempo afinado e
  /// os 2 min sem som sem depender do relógio de parede.
  double _tempo = 0;
  double _ultimoSom = 0;

  /// Até este instante do relógio do áudio o microfone está ouvindo o som do
  /// próprio app (a corda de referência, o aviso): as leituras são ignoradas,
  /// senão a corda de referência marcaria a si mesma como afinada.
  double _surdoAte = -1;
  int? _cordaDaLeitura;

  // Medição do detector em modo debug.
  final Stopwatch _cronometro = Stopwatch();
  int _analisesMedidas = 0;

  Instrumento get instrumento => _instrumento;
  Afinacao get afinacao => _afinacao;
  bool get auto => _auto;
  EstadoPermissao get permissao => _permissao;
  bool get escutando => _assinatura != null;

  /// Cordas marcadas como afinadas, por índice.
  Set<int> get afinadas => Set.unmodifiable(_afinadas);

  /// A corda alvo: a fixada no modo manual, ou a que o Auto escolheu.
  int? get cordaAlvo => _escolha.atual;

  /// Frequência da corda [indice] com a referência atual.
  double frequenciaAlvo(int indice) =>
      _afinacao.notas[indice].frequencia(_a4.toDouble());

  List<double> _alvos() => [
    for (final nota in _afinacao.notas) nota.frequencia(ajustes.a4.toDouble()),
  ];

  void _montarDetector() {
    _detector = DetectorFrequencia(
      taxaAmostragem: fonte.taxaAmostragem,
      frequenciaMinima: _instrumento.frequenciaMinima * 0.8,
      frequenciaMaxima: _instrumento.frequenciaMaxima * 1.3,
    );
    _janela = JanelaDeslizante(
      tamanho: _detector.tamanhoEntradaRecomendada,
      salto: (fonte.taxaAmostragem / analisesPorSegundo).round(),
    );
  }

  // ------------------------------------------------------------ escolhas ---

  void escolherInstrumento(Instrumento instrumento) {
    if (instrumento.id == _instrumento.id) return;
    _instrumento = instrumento;
    _preferencias.instrumento = instrumento.id;
    _montarDetector();
    _trocarAfinacao(instrumento.padrao);
  }

  void escolherAfinacao(Afinacao afinacao) {
    if (afinacao.id == _afinacao.id) return;
    _trocarAfinacao(afinacao);
  }

  void _trocarAfinacao(Afinacao afinacao) {
    _afinacao = afinacao;
    _preferencias.afinacao = afinacao.id;
    _afinadas.clear();
    _escolha = EscolhaCorda(alvos: _alvos(), pares: _instrumento.pares);
    _dobra = DobraHarmonicos(alvos: _alvos(), pares: _instrumento.pares);
    if (!_auto) {
      _escolha.fixar(0);
      _preferencias.cordaFixada = 0;
    }
    _recomecarLeitura();
    notifyListeners();
  }

  /// Liga ou desliga o Auto. Desligar fixa a corda atual (ou a primeira).
  void definirAuto(bool ligado) {
    if (ligado == _auto) return;
    _auto = ligado;
    _preferencias.auto = ligado;
    if (ligado) {
      _escolha.liberar();
    } else {
      final corda = _escolha.atual ?? 0;
      _escolha.fixar(corda);
      _preferencias.cordaFixada = corda;
    }
    notifyListeners();
  }

  /// Tocar no botão de uma corda: fixa a corda, desliga o Auto e toca o som
  /// dela, na afinação e na referência atuais (RF-05).
  void tocarCorda(int indice) {
    _auto = false;
    _preferencias.auto = false;
    _preferencias.cordaFixada = indice;
    _escolha.fixar(indice);
    final duracao = _tocador.tocarCorda(frequenciaAlvo(indice));
    _ensurdecer(duracao);
    _filtro.reiniciar();
    _marcador.reiniciar();
    _dobra.reiniciar();
    _cordaDaLeitura = null;
    leitura.value = LeituraTela.ociosa;
    notifyListeners();
  }

  void _ensurdecer(Duration duracao) {
    _surdoAte = math.max(
      _surdoAte,
      _tempo + duracao.inMicroseconds / 1e6 + folgaDoSom,
    );
  }

  void _aoMudarAjustes() {
    _filtro.precisao = ajustes.precisao;
    if (ajustes.a4 != _a4) {
      _a4 = ajustes.a4;
      final fixada = _auto ? null : _escolha.atual;
      _escolha.trocarAlvos(_alvos());
      _dobra.trocarAlvos(_alvos());
      if (fixada != null) _escolha.fixar(fixada);
      _recomecarLeitura();
      notifyListeners();
    }
    _aplicarTelaLigada();
  }

  void _recomecarLeitura() {
    _filtro.esquecerTudo();
    _janela.limpar();
    _marcador.reiniciar();
    _dobra.reiniciar();
    _cordaDaLeitura = null;
    historico.limpar();
    leitura.value = LeituraTela.ociosa;
  }

  // ----------------------------------------------------------- permissão ---

  Future<void> pedirPermissao() async {
    _definirPermissao(await fonte.pedirPermissao());
    await _iniciarSePuder();
  }

  Future<void> abrirConfiguracoes() => fonte.abrirConfiguracoes();

  void _definirPermissao(EstadoPermissao estado) {
    if (_descartado || estado == _permissao) return;
    _permissao = estado;
    notifyListeners();
  }

  // --------------------------------------------------------- ciclo de vida ---

  /// A tela ficou visível (abriu, ou o app voltou para a frente): confere a
  /// permissão, que pode ter mudado nas configurações, e volta a escutar.
  Future<void> retomar() async {
    _visivel = true;
    _aplicarTelaLigada();
    _definirPermissao(await fonte.estadoPermissao());
    await _iniciarSePuder();
  }

  /// O app foi para segundo plano ou a tela apagou: solta o microfone.
  Future<void> pausar() async {
    _visivel = false;
    _aplicarTelaLigada();
    await _pararEscuta();
  }

  void _aplicarTelaLigada() {
    if (_descartado) return;
    unawaited(_definirTelaLigada(_visivel && ajustes.telaLigada));
  }

  Future<void> _iniciarSePuder() async {
    if (_descartado ||
        !_visivel ||
        _permissao != EstadoPermissao.concedida ||
        _assinatura != null ||
        _iniciando) {
      return;
    }
    _iniciando = true;
    try {
      final amostras = await fonte.iniciar();
      if (_descartado || !_visivel) {
        await fonte.parar();
        return;
      }
      _assinatura = amostras.listen(
        _aoReceber,
        onError: (Object erro) => registrar('erro na captura: $erro'),
      );
      notifyListeners();
    } catch (erro) {
      registrar('não foi possível escutar: $erro');
    } finally {
      _iniciando = false;
    }
  }

  Future<void> _pararEscuta() async {
    final assinatura = _assinatura;
    _assinatura = null;
    // Depois do cancel nenhum bloco chega mais; não precisa esperar.
    unawaited(assinatura?.cancel());
    await fonte.parar();
    if (_descartado) return;
    _recomecarLeitura();
    notifyListeners();
  }

  // ------------------------------------------------------------- análise ---

  void _aoReceber(List<double> amostras) {
    if (_descartado) return;
    _janela.adicionar(amostras, _analisar);
  }

  void _analisar(Float64List janela) {
    _tempo += _janela.salto / fonte.taxaAmostragem;
    if (_tempo < _surdoAte) {
      historico.adicionar(null);
      return;
    }

    Leitura? medida;
    if (kDebugMode) {
      _cronometro.start();
      medida = _detector.analisar(janela);
      _cronometro.stop();
      if (++_analisesMedidas == 100) {
        final media = _cronometro.elapsedMicroseconds / _analisesMedidas / 1000;
        registrar(
          'detector: ${media.toStringAsFixed(2)} ms por análise '
          '(${janela.length} amostras), pico ${_pico(janela)}, '
          'última leitura ${medida?.frequencia.toStringAsFixed(1)} Hz',
        );
        _cronometro.reset();
        _analisesMedidas = 0;
      }
    } else {
      medida = _detector.analisar(janela);
    }

    // Leituras num harmônico (ou sub-harmônico) da nota que está soando
    // voltam à fundamental; a dobra precisa de todas as análises, com a
    // energia, para seguir a nota e reconhecer a palhetada.
    final rms = _rms(janela);
    final corrigida = _dobra.corrigir(medida, rms: rms);
    if (corrigida == null) {
      // O filtro também precisa das análises sem leitura: é a energia delas
      // que marca a palhetada seguinte.
      _filtro.adicionar(tempo: _tempo, cents: null, rms: rms);
      _aoSilenciar();
    } else {
      _aoOuvir(corrigida.frequencia, rms);
    }
  }

  /// Energia das amostras que o detector analisa (as últimas da janela).
  double _rms(Float64List janela) {
    final n = math.min(_detector.tamanhoJanela, janela.length);
    var soma = 0.0;
    for (var i = janela.length - n; i < janela.length; i++) {
      soma += janela[i] * janela[i];
    }
    return n == 0 ? 0 : math.sqrt(soma / n);
  }

  static String _pico(List<double> amostras) {
    var pico = 0.0;
    for (final a in amostras) {
      if (a.abs() > pico) pico = a.abs();
    }
    return pico.toStringAsFixed(3);
  }

  void _aoSilenciar() {
    historico.adicionar(null);
    _marcador.adicionar(
      tempo: _tempo,
      duracao: _janela.salto / fonte.taxaAmostragem,
      afinada: false,
    );
    if (!leitura.value.ehOciosa && _tempo - _ultimoSom >= tempoParaOcioso) {
      leitura.value = LeituraTela.ociosa;
      _filtro.reiniciar();
    }
    if (_afinadas.isNotEmpty && _tempo - _ultimoSom >= tempoParaLimparMarcas) {
      _afinadas.clear();
      notifyListeners();
    }
  }

  void _aoOuvir(double frequencia, double rms) {
    _ultimoSom = _tempo;
    final anterior = _escolha.atual;
    final corda = _escolha.escolher(frequencia);
    final cordaNova = corda != _cordaDaLeitura;
    if (cordaNova) {
      _cordaDaLeitura = corda;
      _marcador.reiniciar();
    }
    final exibicao = _filtro.adicionar(
      tempo: _tempo,
      cents: _escolha.cents(frequencia, corda),
      rms: rms,
      cordaNova: cordaNova,
    )!;
    final cents = exibicao.ponteiro;
    // A marca de afinada vem do filtro, com histerese: não pisca na borda da
    // tolerância. Fora dela, a cor segue a distância do ponteiro.
    final estado = exibicao.afinada
        ? EstadoCorda.afinada
        : (cents.abs() <= limitePerto ? EstadoCorda.perto : EstadoCorda.longe);
    historico.adicionar(cents);

    // A frequência mostrada sai do ponteiro, para andar junto com ele. Num par da viola, a oitava de cima mede contra o dobro.
    var alvo = frequenciaAlvo(corda);
    if (_instrumento.pares &&
        centsEntre(frequencia, alvo * 2).abs() <
            centsEntre(frequencia, alvo).abs()) {
      alvo *= 2;
    }
    var avisar = corda != anterior;
    final afinada = _marcador.adicionar(
      tempo: _tempo,
      duracao: _janela.salto / fonte.taxaAmostragem,
      afinada: estado == EstadoCorda.afinada,
    );
    if (afinada && _afinadas.add(corda)) {
      unawaited(_vibrar());
      _ensurdecer(_tocador.tocarAfinada());
      avisar = true;
    }
    leitura.value = LeituraTela(
      corda: corda,
      cents: cents,
      frequencia: alvo * math.pow(2, cents / 1200),
      estado: estado,
      numero: exibicao.numero,
      // Corda já marcada e ainda na nota: o indicador fica cheio.
      progresso: _afinadas.contains(corda) && estado == EstadoCorda.afinada
          ? 1
          : _marcador.progresso,
    );
    if (avisar) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    ajustes.removeListener(_aoMudarAjustes);
    unawaited(_assinatura?.cancel());
    _assinatura = null;
    unawaited(fonte.parar());
    unawaited(_definirTelaLigada(false));
    _tocador.descartar();
    historico.dispose();
    leitura.dispose();
    super.dispose();
  }
}
