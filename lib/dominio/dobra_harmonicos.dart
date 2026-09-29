import 'detector.dart';
import 'nota.dart';

/// Leva de volta à fundamental as leituras do detector que caem num
/// harmônico (ou numa sub-harmônica) da nota que está soando.
///
/// O microfone do celular quase não capta a fundamental das cordas graves e,
/// com as ressonâncias do corpo, os harmônicos pares dominam: o sinal fica
/// quase periódico em metade (ou um terço) do período, e o YIN às vezes lê
/// 2× ou 3× a nota. Essas leituras vêm com confiança menor que a das corretas
/// da mesma nota (no violão gravado, 0,85 a 0,95 contra 0,99). Mais raramente
/// sai a oitava de baixo, também com confiança menor. No modo automático,
/// cada uma delas empurra a escolha para outra corda (E2 lido como 165 Hz vai
/// para D3) e joga o ponteiro de uma borda à outra.
///
/// O detector não tem como decidir sozinho, numa janela, se 165 Hz limpo é o
/// E2 com a fundamental sumida ou o harmônico da casa 12. Esta classe decide
/// pela continuidade: segue no tempo a frequência que está soando (a
/// âncora) e a confiança típica das leituras dela. Uma leitura perto de k×
/// a âncora (k = 2, 3, 4) ou da âncora dividida por 2 ou 3 é suspeita, e a
/// decisão segue esta ordem:
///
/// 1. **As cordas da afinação.** Se uma das duas hipóteses (a leitura como
///    veio ou a leitura dobrada para a âncora) cai perto de uma corda, até
///    [distanciaCorda] cents, e a outra fica mais de [vantagemCorda] cents
///    mais longe de qualquer corda, ganha a primeira: ninguém afina violão em
///    220 Hz, mas 110 Hz é o A2. Por isso o harmônico da casa 12 tocado logo
///    depois da corda solta é lido como a corda solta, que é o que quer ver
///    quem afina pelo harmônico.
/// 2. **Confiança maior.** Uma leitura mais confiante que a âncora (por mais
///    de [margemAcima]) indica que a âncora é que estava errada, como quando
///    a primeira leitura depois do silêncio sai na oitava de baixo.
/// 3. **Palhetada nova.** Logo depois de uma palhetada (a energia subiu), uma
///    leitura com confiança parecida com a da âncora (até [margemConfianca]
///    abaixo) é uma corda nova de verdade: E2 → B3 no violão, em que B3 é
///    quase exatamente 3 × E2.
/// 4. **Âncora velha.** Depois de [analisesSemConfirmar] leituras suspeitas
///    tão confiantes quanto a âncora, sem nenhuma da própria âncora no meio,
///    a suspeita não se sustenta: a leitura vale como veio (uma corda nova
///    tocada sem a energia subir, com a antiga ainda soando). O harmônico
///    típico vem com confiança menor e não conta para isso.
/// 5. Sem nada disso, a corda não mudou: a leitura é dividida por k (ou
///    multiplicada, na sub-harmônica).
///
/// A leitura dobrada segue a âncora, para acompanhar a mão na tarraxa mesmo
/// quando só o harmônico aparece. Uma leitura sem relação com a âncora (outra
/// nota) passa como veio e só vira a nova âncora se tiver confiança parecida
/// com a dela ou se repetir: um ruído de ataque isolado não desfaz o que se
/// sabe da corda. Sem leitura por [analisesParaEsquecer] análises (silêncio),
/// a âncora é esquecida.
///
/// Na viola caipira ([pares]), a oitava de cima do par é legítima e a
/// EscolhaCorda já a mede contra o dobro do alvo: as relações 2× e ÷2 contam
/// como a própria nota e passam sem mudança.
///
/// Deve receber todas as análises, em ordem, inclusive as que o detector
/// rejeitou (null), com a energia (RMS) de cada janela: é o que marca as
/// palhetadas e o silêncio. Os tempos são contados em análises (25 por
/// segundo no app).
class DobraHarmonicos {
  DobraHarmonicos({
    required List<double> alvos,
    this.pares = false,
    this.tolerancia = 40,
    this.margemConfianca = 0.03,
    this.margemAcima = 0.05,
    this.distanciaCorda = 50,
    this.vantagemCorda = 60,
    this.fatorPalhetada = 1.4,
    this.analisesDepoisDaPalhetada = 8,
    this.analisesSemConfirmar = 15,
    this.analisesParaEsquecer = 25,
    this.pesoConfianca = 0.3,
  }) : _alvos = List.unmodifiable(alvos);

  /// Viola caipira: a oitava de cima do par conta como a própria nota.
  final bool pares;

  /// Até quantos cents de k × âncora uma leitura conta como o harmônico k.
  /// Cobre a inarmonicidade (os harmônicos de uma corda real são um pouco
  /// agudos) e a imprecisão de ler um período curto.
  final double tolerancia;

  /// Com palhetada nova, uma leitura suspeita com confiança até esta margem
  /// abaixo da confiança da âncora ainda vale como corda nova.
  final double margemConfianca;

  /// Uma leitura suspeita mais confiante que a âncora por esta margem desfaz
  /// a âncora, mesmo sem palhetada.
  final double margemAcima;

  /// Até quantos cents de uma corda (ou da oitava de cima, nos pares) uma
  /// frequência conta como "perto de uma corda" ao estimar a vantagem.
  final double distanciaCorda;

  /// Diferença, em cents, entre as distâncias às cordas das duas hipóteses
  /// (a leitura e a leitura dobrada) a partir da qual as cordas decidem.
  final double vantagemCorda;

  /// Palhetada: o RMS da janela passa deste fator sobre o menor RMS das
  /// últimas cinco análises.
  final double fatorPalhetada;

  /// Por quantas análises depois de uma palhetada uma leitura ainda conta
  /// como "logo depois da palhetada".
  final int analisesDepoisDaPalhetada;

  /// Leituras dobradas tão confiantes quanto a âncora (até
  /// [margemConfianca] abaixo), sem nenhuma da própria âncora no meio, a
  /// partir das quais a confiança e a continuidade não bastam mais para
  /// dobrar. As dobradas com confiança menor não contam: são o erro típico.
  final int analisesSemConfirmar;

  /// Análises sem leitura que fazem esquecer a âncora.
  final int analisesParaEsquecer;

  /// Peso da leitura nova na média da confiança da âncora.
  final double pesoConfianca;

  /// Quantas análises de RMS entram no mínimo que detecta a palhetada.
  static const int _historicoRms = 5;

  /// RMS mínimo de uma palhetada (amostras em −1..1).
  static const double _energiaPalhetada = 0.01;

  List<double> _alvos;

  double? _ancora;
  double _confianca = 0;
  int _semConfirmar = 0;
  int _semLeitura = 0;
  // Análises desde a última palhetada; para de contar depois da janela de
  // [analisesDepoisDaPalhetada].
  late int _desdePalhetada = analisesDepoisDaPalhetada + 1;
  final List<double> _rmsRecentes = [];

  // Leitura sem relação com a âncora e com pouca confiança: se a próxima
  // concordar com ela, as duas viram a nova âncora.
  double? _outra;

  double _fator = 1;

  /// Frequências (Hz) das cordas da afinação atual.
  List<double> get alvos => _alvos;

  /// A frequência que está soando, em Hz; null antes da primeira leitura e
  /// depois de um silêncio.
  double? get ancora => _ancora;

  /// Por quanto a última leitura foi dividida: 1 quando passou como veio, 2,
  /// 3 ou 4 num harmônico, 1/2 ou 1/3 numa sub-harmônica.
  double get ultimoFator => _fator;

  /// Nova afinação: as cordas mudam, a nota que está soando não.
  void trocarAlvos(List<double> alvos) {
    _alvos = List.unmodifiable(alvos);
  }

  /// Esquece a nota e a energia (troca de instrumento, microfone reaberto).
  void reiniciar() {
    _ancora = null;
    _outra = null;
    _confianca = 0;
    _semConfirmar = 0;
    _semLeitura = 0;
    _desdePalhetada = analisesDepoisDaPalhetada + 1;
    _rmsRecentes.clear();
    _fator = 1;
  }

  /// A [leitura] desta análise, corrigida; null quando ela é null. [rms] é a
  /// energia da janela analisada, a mesma que o detector viu.
  Leitura? corrigir(Leitura? leitura, {required double rms}) {
    _acompanharEnergia(rms);
    _fator = 1;
    if (leitura == null) {
      if (++_semLeitura >= analisesParaEsquecer) {
        _ancora = null;
        _outra = null;
      }
      return null;
    }
    _semLeitura = 0;

    final f = leitura.frequencia;
    final c = leitura.confianca;
    final ancora = _ancora;
    if (ancora == null) {
      _ancorar(f, c);
      return leitura;
    }

    final k = _relacao(f, ancora);
    if (k == null) {
      // Outra nota: passa como veio. Só vira âncora com confiança parecida ou
      // se repetir, para um ruído de ataque não apagar a corda.
      final outra = _outra;
      if (c >= _confianca - margemConfianca ||
          (outra != null && centsEntre(f, outra).abs() < tolerancia)) {
        _ancorar(f, c);
      } else {
        _outra = f;
      }
      return leitura;
    }
    _outra = null;
    if (k == 1 || (pares && (k == 2 || k == 0.5))) {
      _confirmar(f / k, c);
      return leitura;
    }

    final dobrada = f / k;
    if (_dobrar(f, dobrada, c)) {
      _ancora = dobrada;
      if (c >= _confianca - margemConfianca) _semConfirmar++;
      _fator = k;
      return Leitura(frequencia: dobrada, confianca: c);
    }
    _ancorar(f, c);
    return leitura;
  }

  /// Decide se a leitura [f], suspeita de ser um múltiplo (ou divisor) da
  /// âncora, deve virar [dobrada] (ver a ordem na documentação da classe).
  bool _dobrar(double f, double dobrada, double c) {
    final daLeitura = _distanciaCorda(f);
    final daDobrada = _distanciaCorda(dobrada);
    if (daDobrada <= distanciaCorda && daLeitura - daDobrada > vantagemCorda) {
      return true;
    }
    if (daLeitura <= distanciaCorda && daDobrada - daLeitura > vantagemCorda) {
      return false;
    }
    if (c > _confianca + margemAcima) return false;
    if (_desdePalhetada <= analisesDepoisDaPalhetada &&
        c >= _confianca - margemConfianca) {
      return false;
    }
    return _semConfirmar < analisesSemConfirmar;
  }

  /// As relações procuradas entre uma leitura e a âncora: a própria nota, os
  /// harmônicos 2 a 4 e as sub-harmônicas 1/2 e 1/3.
  static const List<double> _fatores = [1, 2, 3, 4, 1 / 2, 1 / 3];

  /// O k de [_fatores] tal que [f] ≈ k × [ancora] (até [tolerancia] cents),
  /// ou null se não houver relação.
  double? _relacao(double f, double ancora) {
    for (final k in _fatores) {
      if (centsEntre(f / k, ancora).abs() < tolerancia) return k;
    }
    return null;
  }

  /// Distância, em cents, de [f] até a corda mais próxima (ou a oitava de
  /// cima dela, nos pares).
  double _distanciaCorda(double f) {
    var menor = double.infinity;
    for (final alvo in _alvos) {
      final d = centsEntre(f, alvo).abs();
      if (d < menor) menor = d;
      if (pares) {
        final oitava = centsEntre(f, alvo * 2).abs();
        if (oitava < menor) menor = oitava;
      }
    }
    return menor;
  }

  void _ancorar(double f, double c) {
    _ancora = f;
    _confianca = c;
    _semConfirmar = 0;
    _outra = null;
  }

  void _confirmar(double f, double c) {
    _ancora = f;
    _confianca += pesoConfianca * (c - _confianca);
    _semConfirmar = 0;
  }

  /// Marca a palhetada: a energia sobe [fatorPalhetada] vezes sobre o menor
  /// RMS das últimas análises, e passa de [_energiaPalhetada] (abaixo disso,
  /// é o ruído de fundo flutuando no silêncio).
  void _acompanharEnergia(double rms) {
    if (_desdePalhetada <= analisesDepoisDaPalhetada) _desdePalhetada++;
    if (_rmsRecentes.isNotEmpty && rms >= _energiaPalhetada) {
      var menor = _rmsRecentes.first;
      for (final r in _rmsRecentes) {
        if (r < menor) menor = r;
      }
      if (rms > fatorPalhetada * menor) _desdePalhetada = 0;
    }
    _rmsRecentes.add(rms);
    if (_rmsRecentes.length > _historicoRms) _rmsRecentes.removeAt(0);
  }
}
