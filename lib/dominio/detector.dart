import 'dart:math' as math;
import 'dart:typed_data';

/// Uma leitura aceita do detector.
class Leitura {
  const Leitura({required this.frequencia, required this.confianca});

  /// Frequência fundamental estimada, em Hz.
  final double frequencia;

  /// De 0 a 1: 1 menos o mínimo da diferença normalizada do YIN.
  final double confianca;

  @override
  String toString() =>
      'Leitura(${frequencia.toStringAsFixed(2)} Hz, '
      'confiança ${confianca.toStringAsFixed(2)})';
}

/// Estimador da frequência fundamental pelo YIN (de Cheveigné e Kawahara,
/// 2002), em Dart puro (RF-02).
///
/// Passos, sobre uma janela de [tamanhoJanela] amostras:
///
/// 1. tira a média (nível DC) e rejeita a janela se o RMS ficar abaixo de
///    [energiaMinima];
/// 2. calcula a função diferença `d(τ) = Σ (x[j] − x[j+τ])²`, com a soma
///    sempre sobre as mesmas `W = janela − τmáx` amostras. O produto cruzado
///    sai de uma correlação por FFT e os quadrados, de somas acumuladas: o
///    custo é O(n log n), e não O(n × τmáx) como na soma direta;
/// 3. normaliza pela média acumulada, `d'(τ) = d(τ) · τ / Σ d(1..τ)`;
/// 4. procura, entre `taxa / frequenciaMaxima` e `taxa / frequenciaMinima`,
///    o primeiro τ com `d'` abaixo do [limiar] e desce até o mínimo local.
///    Pegar o primeiro, e não o mais fundo, é o que evita dar a oitava de
///    baixo numa corda aguda; a normalização pela média acumulada é o que
///    evita dar a oitava de cima num baixo com o 2º harmônico mais forte que
///    a fundamental;
/// 5. refina o período com uma parábola ajustada a `d` ao redor do mínimo;
/// 6. repete tudo sobre as amostras filtradas por um passa-baixas com corte
///    perto da fundamental, para tirar o puxão dos harmônicos inarmônicos
///    (ver [analisar]).
///
/// Guarda buffers entre chamadas para não alocar a cada janela: uma
/// instância não deve ser usada por duas análises ao mesmo tempo.
class DetectorFrequencia {
  DetectorFrequencia({
    required this.taxaAmostragem,
    this.frequenciaMinima = 28,
    this.frequenciaMaxima = 1400,
    this.limiar = 0.15,
    this.energiaMinima = 0.004,
  }) : assert(taxaAmostragem > 0, 'taxa de amostragem inválida'),
       assert(
         frequenciaMinima > 0 && frequenciaMinima < frequenciaMaxima,
         'faixa de frequência inválida',
       ),
       assert(
         frequenciaMaxima < taxaAmostragem / 4,
         'frequência máxima alta demais para a taxa de amostragem',
       );

  /// Hz, ex. 44100 ou 48000.
  final int taxaAmostragem;

  /// Faixa aceita, em Hz. Leituras fora dela são rejeitadas.
  final double frequenciaMinima, frequenciaMaxima;

  /// Limiar do YIN: quanto menor, mais exigente com a periodicidade.
  final double limiar;

  /// RMS mínimo (amostras em −1..1) para tentar a análise.
  final double energiaMinima;

  /// Tamanho da janela que [analisar] espera: potência de 2 que cabe pelo
  /// menos dois períodos da frequência mínima (2048 a 44,1 kHz para >= 43 Hz;
  /// 4096 para o baixo). Aceita 1% a menos que dois períodos, para que 43 Hz
  /// a 44,1 kHz (2051 amostras) ainda caiba em 2048.
  late final int tamanhoJanela = _calcularJanela();

  // Maior atraso calculado (um além do maior buscado, para a parábola) e
  // tamanho da soma da função diferença.
  late final int _atrasoMaximo = math.min(
    (taxaAmostragem / frequenciaMinima).ceil() + 1,
    tamanhoJanela ~/ 2,
  );
  late final int _atrasoMinimo = math.max(
    2,
    (taxaAmostragem / frequenciaMaxima).floor(),
  );
  late final int _largura = tamanhoJanela - _atrasoMaximo;

  late final _Fft _fft = _Fft(tamanhoJanela);
  late final Float64List _sinal = Float64List(tamanhoJanela);
  late final Float64List _real = Float64List(tamanhoJanela);
  late final Float64List _imaginario = Float64List(tamanhoJanela);
  late final Float64List _correlacaoReal = Float64List(tamanhoJanela);
  late final Float64List _correlacaoImaginaria = Float64List(tamanhoJanela);
  late final Float64List _quadradosAcumulados = Float64List(tamanhoJanela + 1);
  late final Float64List _diferenca = Float64List(_atrasoMaximo + 1);
  late final Float64List _normalizada = Float64List(_atrasoMaximo + 1);

  int _calcularJanela() {
    final minimo = 2 * taxaAmostragem / frequenciaMinima * 0.99;
    var tamanho = 256;
    while (tamanho < minimo) {
      tamanho *= 2;
    }
    return tamanho;
  }

  /// Quantas amostras entregar a [analisar] para ter a leitura refinada: o
  /// dobro de [tamanhoJanela]. A primeira metade só esquenta o passa-baixas
  /// do refino (ver [analisar]); a análise é sempre sobre as últimas
  /// [tamanhoJanela]. Na prática: guardar um anel com as últimas
  /// `tamanhoEntradaRecomendada` amostras e entregá-lo inteiro a cada leitura.
  int get tamanhoEntradaRecomendada => 2 * tamanhoJanela;

  /// Até quantas amostras [analisar] aproveita (as últimas); o que vier antes
  /// é ignorado.
  int get _entradaMaxima => 3 * tamanhoJanela;

  late final Float64List _filtrado = Float64List(_entradaMaxima);

  /// Corte do passa-baixas do refino, em múltiplos da frequência bruta.
  static const double _fatorCorte = 1.5;

  /// Estima a frequência fundamental das últimas [tamanhoJanela] amostras.
  /// null quando silêncio, ruído, confiança baixa ou frequência fora da faixa,
  /// e também quando vierem menos amostras que [tamanhoJanela].
  ///
  /// Duas passadas:
  ///
  /// 1. **Bruta.** O YIN sobre as amostras cruas. Se ela não achar nada, a
  ///    resposta é null.
  /// 2. **Refino.** Numa corda de verdade os harmônicos são um pouco mais
  ///    agudos que os múltiplos exatos da fundamental (inarmonicidade), e o
  ///    período que o YIN acha é um meio-termo entre eles, puxado para cima
  ///    (+2 a +7 cents numa corda comum, mais no ataque). O refino passa as
  ///    amostras por um passa-baixas Butterworth de 4ª ordem com corte em
  ///    1,5× a frequência bruta, que deixa quase só a fundamental, e roda o
  ///    YIN de novo, buscando só a ±1,5 semitom do período bruto (não há como
  ///    pular de oitava). Se o refino falhar, fica a leitura bruta.
  ///
  /// O filtro leva uns períodos para assentar. Por isso [analisar] aproveita
  /// as amostras que vierem além de [tamanhoJanela] (até três janelas): filtra
  /// tudo e analisa só as últimas [tamanhoJanela] já filtradas. O refino só é
  /// feito quando sobram antes da janela pelo menos dois períodos da
  /// frequência bruta, e com som neles (RMS de pelo menos metade do da
  /// janela; se a corda acabou de ser tocada, espera a próxima); com exatamente [tamanhoJanela] amostras, ou poucas a
  /// mais, a leitura é a bruta (a mesma de sempre, só sem a correção da
  /// inarmonicidade). Entregue [tamanhoEntradaRecomendada] amostras para
  /// refinar em toda a faixa.
  Leitura? analisar(List<double> amostras) {
    final n = tamanhoJanela;
    if (amostras.length < n) return null;

    // 1ª passada: amostras cruas.
    final sinal = _sinal;
    final inicio = amostras.length - n;
    for (var i = 0; i < n; i++) {
      sinal[i] = amostras[inicio + i];
    }
    final rms = _tirarMedia();
    if (!(rms >= energiaMinima)) return null; // também pega NaN
    _calcularDiferenca();
    _normalizar();

    // Periódico já abaixo do menor atraso buscado: o som está acima da faixa,
    // e o que apareceria dentro dela seria uma sub-harmônica (3 kHz lido
    // como 1 kHz).
    final dn = _normalizada;
    for (var tau = 2; tau < _atrasoMinimo; tau++) {
      if (dn[tau] < limiar) return null;
    }

    // Primeiro atraso abaixo do limiar, e daí até o mínimo local.
    final ultimo = _atrasoMaximo - 1; // o maior atraso buscado
    var tau = _atrasoMinimo;
    while (tau <= ultimo && dn[tau] >= limiar) {
      tau++;
    }
    if (tau > ultimo) return null;
    while (tau < ultimo && dn[tau + 1] < dn[tau]) {
      tau++;
    }
    // Ainda descendo na borda: o período é maior que o maior buscado.
    if (tau == ultimo && dn[tau + 1] < dn[tau]) return null;
    // Já subindo desde a borda de baixo: o período é menor que o menor.
    if (tau == _atrasoMinimo && dn[tau - 1] < dn[tau]) return null;

    final confianca = (1 - dn[tau]).clamp(0.0, 1.0);

    final periodoBruto = _refinar(tau);
    if (periodoBruto == null) return null;
    final bruta = taxaAmostragem / periodoBruto;
    if (bruta < frequenciaMinima || bruta > frequenciaMaxima) return null;

    // 2ª passada: só a fundamental.
    final periodo =
        _refinarFiltrando(amostras, periodoBruto, rms) ?? periodoBruto;
    final frequencia = taxaAmostragem / periodo;
    if (frequencia < frequenciaMinima || frequencia > frequenciaMaxima) {
      return Leitura(frequencia: bruta, confianca: confianca);
    }
    return Leitura(frequencia: frequencia, confianca: confianca);
  }

  /// O período refinado com o passa-baixas (2ª passada de [analisar]), ou
  /// null se não houver amostras para o filtro assentar (dois períodos antes
  /// da janela, com pelo menos metade do RMS dela) ou se o YIN não achar um
  /// mínimo claro perto de [periodoBruto].
  double? _refinarFiltrando(
    List<double> amostras,
    double periodoBruto,
    double rmsJanela,
  ) {
    final n = tamanhoJanela;
    final total = math.min(amostras.length, _entradaMaxima);
    final aquecimento = (2 * periodoBruto).ceil();
    if (total - n < aquecimento) return null;

    // Tira a média antes de filtrar: um nível DC entraria como um degrau no
    // começo e demoraria a sumir.
    final inicio = amostras.length - total;
    var soma = 0.0;
    for (var i = 0; i < total; i++) {
      soma += amostras[inicio + i];
    }
    final media = soma / total;
    final filtrado = _filtrado;
    for (var i = 0; i < total; i++) {
      filtrado[i] = amostras[inicio + i] - media;
    }

    // O aquecimento só vale se o som já estava lá: se a corda foi tocada
    // agora, logo antes da janela, o transitório do filtro cairia dentro dela.
    var energiaAquecimento = 0.0;
    for (var i = total - n - aquecimento; i < total - n; i++) {
      energiaAquecimento += filtrado[i] * filtrado[i];
    }
    final rmsAquecimento = math.sqrt(energiaAquecimento / aquecimento);
    if (rmsAquecimento < 0.5 * rmsJanela) return null;

    _passaBaixas(filtrado, total, _fatorCorte * taxaAmostragem / periodoBruto);

    final sinal = _sinal;
    for (var i = 0; i < n; i++) {
      sinal[i] = filtrado[total - n + i];
    }
    _tirarMedia();
    _calcularDiferenca();
    _normalizar();

    // O menor d' a ±1,5 semitom do período bruto.
    final dn = _normalizada;
    final fator = math.pow(2, 1.5 / 12).toDouble();
    final menor = math.max(_atrasoMinimo, (periodoBruto / fator).floor());
    final maior = math.min(_atrasoMaximo - 1, (periodoBruto * fator).ceil());
    if (maior - menor < 2) return null;
    var tau = menor;
    for (var t = menor + 1; t <= maior; t++) {
      if (dn[t] < dn[tau]) tau = t;
    }
    if (tau == menor || tau == maior || dn[tau] >= limiar) return null;
    return _refinar(tau);
  }

  /// Passa-baixas Butterworth de 2ª ordem (biquad do RBJ, Q = 1/√2) aplicado
  /// duas vezes em cascata, no lugar, sobre as [total] primeiras amostras.
  void _passaBaixas(Float64List x, int total, double corte) {
    final w0 = 2 * math.pi * corte / taxaAmostragem;
    final alfa = math.sin(w0) / (2 * math.sqrt1_2);
    final cosseno = math.cos(w0);
    final a0 = 1 + alfa;
    final b0 = (1 - cosseno) / 2 / a0;
    final b1 = (1 - cosseno) / a0;
    final b2 = b0;
    final a1 = -2 * cosseno / a0;
    final a2 = (1 - alfa) / a0;
    // Estado dos dois estágios: entradas e saídas anteriores.
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    var u1 = 0.0, u2 = 0.0, v1 = 0.0, v2 = 0.0;
    for (var i = 0; i < total; i++) {
      final entrada = x[i];
      final y = b0 * entrada + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
      x2 = x1;
      x1 = entrada;
      y2 = y1;
      y1 = y;
      final v = b0 * y + b1 * u1 + b2 * u2 - a1 * v1 - a2 * v2;
      u2 = u1;
      u1 = y;
      v2 = v1;
      v1 = v;
      x[i] = v;
    }
  }

  /// Tira a média de [_sinal] e devolve o RMS que sobra.
  double _tirarMedia() {
    final n = tamanhoJanela;
    final sinal = _sinal;
    var soma = 0.0;
    for (var i = 0; i < n; i++) {
      soma += sinal[i];
    }
    final media = soma / n;
    var energia = 0.0;
    for (var i = 0; i < n; i++) {
      final amostra = sinal[i] - media;
      sinal[i] = amostra;
      energia += amostra * amostra;
    }
    return math.sqrt(energia / n);
  }

  /// Diferença normalizada pela média acumulada, de [_diferenca] para
  /// [_normalizada].
  void _normalizar() {
    final d = _diferenca;
    final dn = _normalizada;
    dn[0] = 1;
    var acumulado = 0.0;
    for (var tau = 1; tau <= _atrasoMaximo; tau++) {
      acumulado += d[tau];
      dn[tau] = acumulado > 0 ? d[tau] * tau / acumulado : 1;
    }
  }

  /// O período com fração de amostra, a partir do mínimo inteiro [tau].
  ///
  /// Ajusta, por mínimos quadrados, uma parábola a `d` em ±h atrasos em volta
  /// do mínimo, com h de 1/80 do período (pelo menos 1, que é a interpolação
  /// parabólica clássica de três pontos). Nas notas graves o período passa de
  /// mil amostras e `d` fica tão plano em ±1 atraso que o ruído decide sozinho
  /// onde está o fundo; com a janela maior a parábola atravessa o ruído, e 1/80
  /// do período ainda é estreito o bastante para o 6º harmônico caber na
  /// parte parabólica. Se o vértice cair a mais de meia amostra do centro,
  /// recentra e ajusta de novo.
  double? _refinar(int tau) {
    final d = _diferenca;
    final meiaLargura = math.max(1, (tau / 80).round());
    var centro = tau;
    for (var tentativa = 0; tentativa < 4; tentativa++) {
      final h = math.min(
        meiaLargura,
        math.min(centro - 1, _atrasoMaximo - centro),
      );
      if (h < 1) return null;
      var somaY = 0.0;
      var somaXY = 0.0;
      var somaX2Y = 0.0;
      for (var x = -h; x <= h; x++) {
        final y = d[centro + x];
        somaY += y;
        somaXY += x * y;
        somaX2Y += x * x * y;
      }
      final pontos = 2 * h + 1;
      final somaX2 = h * (h + 1) * (2 * h + 1) / 3;
      final somaX4 = h * (h + 1) * (2 * h + 1) * (3 * h * h + 3 * h - 1) / 15;
      final a =
          (somaX2Y - somaX2 / pontos * somaY) /
          (somaX4 - somaX2 * somaX2 / pontos);
      final b = somaXY / somaX2;
      if (!(a > 0)) return null;
      final deslocamento = -b / (2 * a);
      if (deslocamento.abs() <= 0.5 || tentativa == 3) {
        return deslocamento.abs() <= h ? centro + deslocamento : null;
      }
      centro = (centro + deslocamento.clamp(-h, h)).round();
    }
    return null;
  }

  /// Preenche [_diferenca] de 0 a [_atrasoMaximo]:
  /// `d(τ) = Σ x[j]² + Σ x[j+τ]² − 2 Σ x[j]·x[j+τ]`, j de 0 a W−1.
  ///
  /// A correlação cruzada entre as W primeiras amostras (a) e a janela
  /// inteira (x) sai de uma única FFT complexa de `a + i·x`: como
  /// j + τ < W + τmáx = n, a correlação circular não dá a volta.
  void _calcularDiferenca() {
    final n = tamanhoJanela;
    final largura = _largura;
    final x = _sinal;
    final re = _real;
    final im = _imaginario;

    for (var i = 0; i < n; i++) {
      re[i] = i < largura ? x[i] : 0.0;
      im[i] = x[i];
    }
    _fft.transformar(re, im);

    // Separa A (de a) e X (de x) e monta conj(A)·X. Para a correlação real
    // sair da mesma FFT direta, guarda o conjugado: IFFT(C) = conj(FFT(conj
    // C)) / n, e só a parte real interessa.
    final cr = _correlacaoReal;
    final ci = _correlacaoImaginaria;
    for (var k = 0; k < n; k++) {
      final espelho = (n - k) & (n - 1);
      final zr = re[k];
      final zi = im[k];
      final wr = re[espelho];
      final wi = -im[espelho];
      final ar = (zr + wr) / 2;
      final ai = (zi + wi) / 2;
      final xr = (zi - wi) / 2;
      final xi = -(zr - wr) / 2;
      cr[k] = ar * xr + ai * xi;
      ci[k] = -(ar * xi - ai * xr);
    }
    _fft.transformar(cr, ci);

    final quadrados = _quadradosAcumulados;
    quadrados[0] = 0;
    for (var i = 0; i < n; i++) {
      quadrados[i + 1] = quadrados[i] + x[i] * x[i];
    }
    final energiaInicio = quadrados[largura];
    final d = _diferenca;
    d[0] = 0;
    for (var tau = 1; tau <= _atrasoMaximo; tau++) {
      final energiaDeslocada = quadrados[tau + largura] - quadrados[tau];
      final valor = energiaInicio + energiaDeslocada - 2 * cr[tau] / n;
      d[tau] = valor > 0 ? valor : 0;
    }
  }
}

/// FFT complexa radix-2, iterativa e no lugar, com tabelas pré-calculadas.
class _Fft {
  _Fft(this.n)
    : assert(n > 1 && n & (n - 1) == 0, 'tamanho da FFT não é potência de 2'),
      _cosseno = Float64List(n ~/ 2),
      _seno = Float64List(n ~/ 2),
      _invertido = Int32List(n) {
    for (var k = 0; k < n ~/ 2; k++) {
      final angulo = 2 * math.pi * k / n;
      _cosseno[k] = math.cos(angulo);
      _seno[k] = -math.sin(angulo);
    }
    var bits = 0;
    while (1 << bits < n) {
      bits++;
    }
    for (var i = 0; i < n; i++) {
      var r = 0;
      for (var b = 0; b < bits; b++) {
        if (i & (1 << b) != 0) r |= 1 << (bits - 1 - b);
      }
      _invertido[i] = r;
    }
  }

  final int n;
  final Float64List _cosseno;
  final Float64List _seno;
  final Int32List _invertido;

  /// Transformada direta (expoente negativo), sem normalizar.
  void transformar(Float64List re, Float64List im) {
    for (var i = 0; i < n; i++) {
      final j = _invertido[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (var tamanho = 2; tamanho <= n; tamanho <<= 1) {
      final metade = tamanho >> 1;
      final passo = n ~/ tamanho;
      for (var inicio = 0; inicio < n; inicio += tamanho) {
        var t = 0;
        for (var k = 0; k < metade; k++) {
          final wr = _cosseno[t];
          final wi = _seno[t];
          t += passo;
          final i = inicio + k;
          final j = i + metade;
          final rj = re[j];
          final ij = im[j];
          final tr = wr * rj - wi * ij;
          final ti = wr * ij + wi * rj;
          re[j] = re[i] - tr;
          im[j] = im[i] - ti;
          re[i] += tr;
          im[i] += ti;
        }
      }
    }
  }
}
