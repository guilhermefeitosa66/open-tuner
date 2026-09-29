import 'dart:math' as math;

import 'estado_corda.dart';

/// O que o indicador mostra depois de uma análise.
class Exibicao {
  const Exibicao({
    required this.ponteiro,
    required this.numero,
    required this.afinada,
  });

  /// Onde fica o ponteiro, em cents: contínuo, sem tremor.
  final double ponteiro;

  /// O número escrito no indicador, em cents inteiros, com histerese.
  final int numero;

  /// Se o indicador mostra a marca de afinada (✓) no lugar do número.
  final bool afinada;

  @override
  bool operator ==(Object outro) =>
      outro is Exibicao &&
      outro.ponteiro == ponteiro &&
      outro.numero == numero &&
      outro.afinada == afinada;

  @override
  int get hashCode => Object.hash(ponteiro, numero, afinada);

  @override
  String toString() =>
      'Exibicao(${ponteiro.toStringAsFixed(2)}, $numero'
      '${afinada ? ', afinada' : ''})';
}

/// O estado do filtro num instante: desvio, velocidade e a covariância
/// [[p00, p01], [p01, p11]].
typedef _Estado = ({
  double c,
  double v,
  double p00,
  double p01,
  double p11,
  double tempo,
});

/// Uma leitura recente: se veio no ataque e se o portão a aceitou.
typedef _Leitura = ({double tempo, double cents, bool ataque, bool aceita});

/// Filtro de Kalman entre a leitura em cents e o indicador: estima o desvio
/// da corda e a velocidade com que ele muda (a mão na tarraxa) e decide o
/// que a tela mostra.
///
/// Cada análise traz uma leitura em cents até a corda alvo. Ela treme alguns
/// cents de uma análise para a outra (±3 no violão gravado pelo celular, bem
/// mais com a janela curta do cavaquinho), sai de 10 a 15 cents aguda no
/// ataque da palhetada e, de vez em quando, vem com um erro grosseiro. A tela
/// precisa ficar parada com a corda parada, andar junto com a tarraxa, não
/// pular no ataque e, acima de tudo, não mostrar a marca de afinada numa
/// corda que não está afinada.
///
/// **O modelo.** O estado é o desvio `c` e a velocidade `v`, em cents por
/// segundo. Entre duas análises, `c` anda `v·dt` e a velocidade muda por uma
/// aceleração aleatória (a mão começa e para de girar a tarraxa). Com a corda
/// parada a velocidade estimada fica perto de zero e o filtro faz a média de
/// muitas leituras; com a tarraxa girando a velocidade constante, o modelo
/// prevê o próximo valor, o que uma média simples não faz. A velocidade só
/// vale por [tempoLacuna] segundos sem leitura aceita: depois disso não se
/// sabe se a mão continuou girando ou parou, a velocidade volta a zero e a
/// incerteza do desvio cresce como se a mão pudesse ter girado a tarraxa a
/// [velocidadeLacuna] cents por segundo. Assim, quando o detector perde a
/// nota por meio segundo, o ponteiro não continua andando além da corda, e a
/// primeira leitura depois do buraco pesa quase sozinha.
///
/// **O ruído da leitura** muda muito entre instrumentos, microfones e salas,
/// e o filtro o aprende das próprias leituras: a variância das inovações (a
/// diferença entre a leitura e a previsão) menos a incerteza da previsão, em
/// média exponencial de [constanteRuido] segundos, com a média nunca abaixo
/// de [ruidoMinimo] (o piso vai na média, não em cada amostra, senão o ruído
/// aprendido sai inflado perto do piso). Quando a incerteza da previsão
/// passa do próprio ruído (depois de uma lacuna ou de um recomeço), a
/// inovação quase não diz nada sobre o ruído e não entra na média. A
/// aceleração possível é proporcional a esse ruído, de modo que o filtro
/// responde sempre em uns [tempoResposta] segundos: com um microfone ruidoso
/// o ponteiro treme um pouco mais, mas não fica para trás da tarraxa. Dar à
/// leitura um ruído maior quando a energia cai ou quando a confiança do
/// detector é baixa foi medido na bancada e piorou: o fim da rampa coincide
/// com o fim da nota, e o ponteiro atrasava justo ali. Aprender o ruído dos
/// resíduos em volta de uma reta (para a rampa não contar como ruído)
/// também piorou: o ruído do detector tem uma parte lenta, que a reta
/// absorve, e o portão ficava estreito demais nas gravações reais.
///
/// **Rejeição por inovação.** Uma leitura a mais de [desviosRejeicao] desvios
/// da previsão (o desvio da inovação, que soma a incerteza do estado e o
/// ruído da leitura) não entra: é um erro grosseiro do detector. Numa
/// análise rejeitada o estado não anda (a próxima previsão sai da última
/// leitura aceita), o ponteiro e o número ficam onde estão e a marca de
/// afinada não entra.
///
/// **O salto.** Se a maioria das últimas [leiturasParaSaltar] leituras foi
/// rejeitada (a última inclusive) e elas concordam entre si, o filtro passa
/// a segui-las: a tarraxa girou com a corda muda, a corda mudou, ou a
/// tarraxa gira mais depressa do que o filtro acompanha. Elas concordam se
/// ficam num valor só (da menor à maior, até [desviosRejeicao] desvios do
/// ruído) ou numa reta: a inclinação se distingue do ruído, não passa de
/// [velocidadeMaxima], os resíduos cabem no ruído (nenhum além de
/// [desviosRejeicao] desvios, e a variância deles até o dobro do ruído) e a
/// reta sai de onde o filtro estava (no instante da última leitura aceita,
/// ela caberia no portão). O ajuste só vale se discordar do desvio estimado
/// por mais de [desviosRejeicao] desvios. Com todas rejeitadas, o filtro
/// recomeça no ajuste e o ponteiro salta; com alguma aceita, o estado passa
/// a ser o ajuste e o ponteiro desliza. Sem a reta, uma tarraxa a 40 cents
/// por segundo ou mais deixava o ponteiro preso no valor de partida enquanto
/// girava. As exigências da reta vieram da gravação real, em que um
/// aglomerado de erros grosseiros ou um degrau se ajustam a uma reta
/// íngreme quando o ruído é grande. As leituras do ataque que o portão
/// aceitou ficam de fora da janela: elas não dizem nada sobre um salto. São
/// 5 leituras, as mesmas que a EscolhaCorda pede para trocar de corda, para
/// o ponteiro não saltar para os cents de outra corda uma análise antes da
/// troca.
///
/// **O ataque.** A palhetada se reconhece pela energia: o RMS da janela passa
/// [fatorPalhetada] vezes o menor e também o maior RMS das últimas cinco
/// análises (só a primeira análise da subida conta). Passar o maior evita
/// que o batimento de um par de cordas, que sobe e desce a energia várias
/// vezes por segundo, renove a palhetada a cada ciclo e prenda o filtro na
/// espera do ataque. Nos [tempoAtaque] segundos seguintes a corda soa mais
/// aguda, pela tensão extra da deformação, e isso não é afinação.
///
/// Numa corda que o filtro já segue, a mão que toca soltou a tarraxa: o
/// estado vai até a palhetada, a velocidade volta a zero sem levar nada do
/// intervalo anterior (um degrau entre as palhetadas é desvio, não
/// velocidade) e a incerteza do desvio se renova, porque a tarraxa pode ter
/// girado desde a última leitura aceita (a [velocidadeLacuna] cents por
/// segundo, e nunca abaixo de metade do ruído). As leituras do ataque não
/// entram (o ponteiro espera), a não ser para reconhecer o salto de quem
/// afinou com a corda muda: elas se medem com o ruído multiplicado por
/// [fatorAtaque], menos as mais graves que a previsão, que o ataque não
/// explica e se medem com o ruído normal. Numa corda nova, as leituras do
/// ataque são tudo o que há: entram com o ruído maior e sem mexer na
/// velocidade, e a incerteza não desce abaixo desse ruído, para a primeira
/// leitura assentada pesar mais que todas elas juntas. Esperar mais que uns
/// 0,15 s foi pior na bancada: quando a afinação mudou entre as palhetadas,
/// o ponteiro ficava parado no valor velho e depois saltava.
///
/// **O ponteiro** anda [passoPonteiro] do caminho até o desvio estimado por
/// análise, mais o que a velocidade estimada prevê (para não ficar para trás
/// numa rampa), e só se mexe quando esse alvo passa de uma folga de
/// [folgaPonteiro] × a tolerância: uma correção grande vira um deslize de
/// algumas análises, e o resto do tremor some. Quando a tarraxa para, o
/// modelo de velocidade passa do ponto (uns 3 cents a 20 cents por segundo,
/// voltando em 1 s); para o ponteiro não passar junto, o alvo não vai além
/// das últimas três leituras assentadas (mais meio desvio do ruído) no
/// sentido em que a velocidade empurra. Com a velocidade estimada
/// significativa (acima de dois desvios dela), o alvo também não fica para
/// trás delas, o que encurta o atraso no começo de uma rampa rápida. Com a
/// corda parada o limite de trás não vale: ele puxaria o ponteiro para cada
/// leitura e o faria tremer.
///
/// **O número** sai do ponteiro e só muda quando ele se afasta do número
/// escrito por mais de meio cent mais [histereseNumero] × a tolerância:
/// parado com a corda parada, e em escada, numa direção só, com a tarraxa
/// girando.
///
/// **A marca de afinada** é o que mais importa acertar: um ✓ falso é o pior
/// erro. Ela se decide pelo desvio estimado, limitado às últimas três
/// leituras assentadas (mais um desvio do ruído): quando o modelo passa do
/// ponto, ou ainda carrega o viés do ataque, as leituras o desmentem. Entra
/// numa leitura aceita fora do ataque, passado o ataque desde o recomeço ou
/// a palhetada, com esse desvio dentro de [entradaAfinada] × a tolerância,
/// com pelo menos três leituras assentadas desde o recomeço e a média delas
/// (até [leiturasParaSaltar]) também dentro, e com a energia ainda acima de
/// [fracaoEnergia] do pico da última palhetada: a nota morrendo desafina e
/// dá leituras enviesadas.
///
/// Sai quando o desvio fica além da saída por [analisesSaida] análises
/// aceitas seguidas (o desvio estimado vagueia um pouco, e sem essa espera a
/// marca piscava na borda da precisão fina), ou de uma vez quando passa da
/// saída por mais de meio desvio do ruído (a espera não atrasa a corda que
/// sai de verdade da tolerância), quando as três últimas leituras
/// assentadas passam todas da saída, do mesmo lado, por mais de meio desvio
/// do ruído (a corda saiu da tolerância e o filtro ainda não chegou lá), ou
/// quando duas leituras seguidas rejeitadas, concordando entre si, ficam do
/// mesmo lado além da saída. A saída fica em [saidaAfinada] × a tolerância,
/// mas nunca a menos de [faixaAfinada] desvios do ruído acima da entrada: na
/// precisão fina com um microfone ruidoso, a faixa proporcional à
/// tolerância é mais estreita que o vaivém do próprio desvio estimado. As
/// frações seguem a [precisao]: ±5 cents na normal, ±2 na fina. Ao trocar a
/// precisão, a marca acesa só fica se também entraria na nova.
///
/// Deve receber todas as análises, em ordem, inclusive as rejeitadas pelo
/// detector (cents null), com a energia de cada janela: é o que marca as
/// palhetadas e o intervalo entre análises. Uma leitura que não seja um
/// número finito conta como rejeitada pelo detector, e um relógio que volta
/// esquece a corda e a energia.
class FiltroKalman {
  FiltroKalman({
    Precisao precisao = Precisao.normal,
    this.tempoResposta = 0.4,
    this.ruidoInicial = 4,
    this.ruidoMinimo = 1,
    this.constanteRuido = 2,
    this.velocidadeInicial = 3,
    this.tempoLacuna = 0.2,
    this.velocidadeLacuna = 20,
    this.velocidadeMaxima = 150,
    this.desviosRejeicao = 3.5,
    this.leiturasParaSaltar = 5,
    this.fatorPalhetada = 1.4,
    this.tempoAtaque = 0.15,
    this.fatorAtaque = 3,
    this.passoPonteiro = 0.4,
    this.folgaPonteiro = 0.1,
    this.histereseNumero = 0.4,
    this.entradaAfinada = 1,
    this.saidaAfinada = 1.6,
    this.faixaAfinada = 0.75,
    this.analisesSaida = 5,
    this.fracaoEnergia = 0.15,
  }) : assert(tempoResposta > 0, 'tempoResposta precisa ser positivo'),
       assert(ruidoInicial > 0, 'ruidoInicial precisa ser positivo'),
       assert(ruidoMinimo > 0, 'ruidoMinimo precisa ser positivo'),
       assert(tempoLacuna > 0, 'tempoLacuna precisa ser positivo'),
       assert(leiturasParaSaltar >= 3, 'leiturasParaSaltar precisa ser >= 3'),
       assert(
         passoPonteiro > 0 && passoPonteiro <= 1,
         'passoPonteiro fora de (0, 1]',
       ),
       assert(
         saidaAfinada >= entradaAfinada,
         'a marca não pode sair antes de entrar',
       ),
       assert(analisesSaida >= 1, 'analisesSaida precisa ser >= 1'),
       _precisao = precisao,
       _ruido = _quadrado(math.max(ruidoInicial, ruidoMinimo));

  /// Tempo de resposta do filtro, em segundos. Define a aceleração possível
  /// em relação ao ruído (densidade `ruído² · Δ / T⁴`, com Δ o intervalo
  /// entre análises): maior deixa o ponteiro mais parado, menor acompanha
  /// melhor o começo e o fim de uma rampa.
  final double tempoResposta;

  /// Desvio padrão da leitura, em cents, antes de o filtro aprender o ruído.
  final double ruidoInicial;

  /// Piso do desvio padrão aprendido da leitura, em cents.
  final double ruidoMinimo;

  /// Constante de tempo, em segundos, da média que aprende o ruído.
  final double constanteRuido;

  /// Incerteza da velocidade, em cents/s, quando o filtro recomeça ou a
  /// corda é tocada de novo: quem toca a corda raramente está girando a
  /// tarraxa.
  final double velocidadeInicial;

  /// Por quanto tempo, em segundos, a velocidade estimada continua valendo
  /// sem leitura aceita.
  final double tempoLacuna;

  /// Quanto a mão pode girar a tarraxa sem o filtro ver, em cents/s: a
  /// incerteza do desvio cresce assim numa lacuna sem leitura aceita e desde
  /// a última leitura aceita até uma palhetada.
  final double velocidadeLacuna;

  /// A maior velocidade, em cents/s, que uma reta de leituras rejeitadas
  /// pode ter para o filtro saltar para ela.
  final double velocidadeMaxima;

  /// Distância, em desvios da inovação, a partir da qual a leitura é
  /// rejeitada.
  final double desviosRejeicao;

  /// Quantas leituras recentes o filtro confere para saltar (a maioria delas
  /// rejeitadas) e quantas leituras assentadas entram na média que a marca
  /// de afinada confere.
  final int leiturasParaSaltar;

  /// Palhetada: o RMS da janela passa deste fator sobre o menor RMS das
  /// últimas análises (o mesmo critério da DobraHarmonicos).
  final double fatorPalhetada;

  /// Quanto dura, em segundos, o ataque mais agudo depois da palhetada.
  final double tempoAtaque;

  /// Por quanto o desvio padrão da leitura é multiplicado no ataque.
  final double fatorAtaque;

  /// Fração do caminho até o desvio estimado que o ponteiro anda por
  /// análise (1 = vai direto).
  final double passoPonteiro;

  /// Folga do ponteiro, em frações da tolerância.
  final double folgaPonteiro;

  /// Folga do número, em frações da tolerância, além do meio cent do
  /// arredondamento.
  final double histereseNumero;

  /// A marca de afinada entra dentro desta fração da tolerância.
  final double entradaAfinada;

  /// A marca de afinada sai acima desta fração da tolerância.
  final double saidaAfinada;

  /// Largura mínima, em desvios do ruído aprendido, da faixa entre a entrada
  /// e a saída da marca de afinada.
  final double faixaAfinada;

  /// Quantas análises aceitas seguidas o desvio precisa ficar além da saída
  /// para a marca de afinada sair por ele.
  final int analisesSaida;

  /// A marca de afinada não entra com o RMS abaixo desta fração do pico da
  /// última palhetada (0 desliga).
  final double fracaoEnergia;

  /// Quantas análises de RMS recentes a palhetada compara: ela passa
  /// [fatorPalhetada] vezes o menor e também o maior delas.
  static const int _historicoRms = 5;

  /// RMS mínimo de uma palhetada (amostras em −1..1); abaixo disso é o ruído
  /// de fundo flutuando no silêncio.
  static const double _energiaPalhetada = 0.01;

  /// Intervalo entre análises antes de medir o primeiro (25 por segundo).
  static const double _intervaloPadrao = 0.04;

  /// Quantas leituras assentadas recentes o limite do ponteiro, o desvio da
  /// marca e a saída pelas leituras conferem; também o mínimo delas para a
  /// marca entrar.
  static const int _leiturasMarca = 3;

  /// Margem, em desvios do ruído, do limite do ponteiro e da saída pelas
  /// leituras.
  static const double _margemLeituras = 0.5;

  /// Margem, em desvios do ruído, do limite do desvio que decide a marca.
  static const double _margemMarca = 1;

  /// Piso da incerteza do desvio numa palhetada, em frações do ruído: a
  /// primeira leitura assentada pesa pelo menos um terço.
  static const double _pisoPalhetada = 0.5;

  /// Até quantas vezes o ruído a variância dos resíduos de uma reta pode ir
  /// para o filtro saltar para ela.
  static const double _residuosReta = 2;

  static double _quadrado(double x) => x * x;

  Precisao _precisao;

  /// O desvio, a velocidade e a covariância no instante da última leitura
  /// aceita (ou da última palhetada); null sem corda.
  _Estado? _estado;

  /// Variância aprendida da leitura, em cents².
  double _ruido;

  double? _ultimaAnalise;
  double _intervalo = _intervaloPadrao;

  final List<double> _rmsRecentes = [];
  bool _subindo = false;
  double _palhetada = double.negativeInfinity;
  double _picoPalhetada = 0;

  /// Instante em que o filtro recomeçou (corda nova ou salto).
  double _inicio = double.negativeInfinity;

  /// As últimas [leiturasParaSaltar] leituras, menos as do ataque que o
  /// portão aceitou.
  final List<_Leitura> _recentes = [];

  /// As últimas [leiturasParaSaltar] leituras aceitas fora do ataque, desde
  /// o recomeço.
  final List<double> _assentadas = [];

  double? _alvoPonteiro;
  double? _ponteiro;
  double _tempoExibicao = 0;
  int? _numero;
  bool _afinada = false;
  int _analisesFora = 0;
  Exibicao? _atual;

  /// A tolerância da marca de afinada; pode mudar a qualquer momento.
  Precisao get precisao => _precisao;
  set precisao(Precisao nova) {
    if (nova == _precisao) return;
    _precisao = nova;
    _analisesFora = 0;
    final estado = _estado;
    if (!_afinada || estado == null) return;
    // A marca acesa na precisão anterior só fica se entraria na nova: senão
    // uma corda a 3 cents, afinada na normal, ficaria marcada na fina.
    final entrada = entradaAfinada * nova.tolerancia;
    if (_desvioMarca(estado).abs() <= entrada &&
        _media(_assentadas).abs() <= entrada) {
      return;
    }
    _afinada = false;
    final atual = _atual;
    if (atual != null) {
      _atual = Exibicao(
        ponteiro: atual.ponteiro,
        numero: atual.numero,
        afinada: false,
      );
    }
  }

  /// A última exibição; null antes da primeira leitura e depois de
  /// [reiniciar].
  Exibicao? get atual => _atual;

  /// O desvio estimado, em cents, antes da suavização do ponteiro; null
  /// antes da primeira leitura.
  double? get desvio => _estado?.c;

  /// A velocidade estimada, em cents por segundo.
  double get velocidade => _estado?.v ?? 0;

  /// O desvio padrão aprendido da leitura, em cents.
  double get ruido => math.sqrt(_ruido);

  /// Esquece a corda (corda nova, silêncio longo). O ruído aprendido e a
  /// energia recente ficam: são do instrumento e do microfone.
  void reiniciar() {
    _estado = null;
    _recentes.clear();
    _assentadas.clear();
    _alvoPonteiro = null;
    _ponteiro = null;
    _numero = null;
    _afinada = false;
    _analisesFora = 0;
    _atual = null;
  }

  /// Esquece tudo, inclusive o ruído aprendido e a energia (outro
  /// instrumento, outra afinação, microfone reaberto).
  void esquecerTudo() {
    reiniciar();
    _ruido = _quadrado(math.max(ruidoInicial, ruidoMinimo));
    _esquecerTempo();
  }

  void _esquecerTempo() {
    _ultimaAnalise = null;
    _intervalo = _intervaloPadrao;
    _rmsRecentes.clear();
    _subindo = false;
    _palhetada = double.negativeInfinity;
    _picoPalhetada = 0;
    _inicio = double.negativeInfinity;
  }

  /// Uma análise no instante [tempo] (em segundos): [cents] até a corda
  /// alvo, null quando o detector rejeitou a janela, e o [rms] da janela.
  /// [cordaNova] avisa que a corda alvo mudou: o filtro recomeça nesta
  /// leitura. Devolve o que mostrar; null enquanto não houver leitura.
  Exibicao? adicionar({
    required double tempo,
    required double? cents,
    required double rms,
    bool cordaNova = false,
  }) {
    final anterior = _ultimaAnalise;
    if (anterior != null && tempo < anterior) {
      // O relógio voltou (outra sessão de áudio): a palhetada e a corda de
      // antes ficariam no futuro, e o filtro esperaria o ataque para sempre.
      _esquecerTempo();
      reiniciar();
    } else if (anterior != null && tempo > anterior) {
      // Uma lacuna entre chamadas muda o intervalo aos poucos, sem apagar o
      // ruído aprendido nem soltar a aceleração possível de uma vez.
      _intervalo = (tempo - anterior).clamp(_intervalo / 2, 2 * _intervalo);
    }
    _ultimaAnalise = tempo;
    _acompanharEnergia(tempo, rms.isFinite ? rms : 0);
    if (cordaNova) reiniciar();
    if (cents == null || !cents.isFinite) return _atual;

    final emAtaque = tempo - _palhetada < tempoAtaque;
    final r = _ruido * (emAtaque ? fatorAtaque * fatorAtaque : 1);
    final estado = _estado;
    if (estado == null) {
      _recomecar(tempo, cents, r);
      return _atual = _exibir(tempo);
    }
    // Palhetada numa corda que o filtro já segue: o ponteiro espera o ataque
    // passar, a menos que as leituras fujam até do ataque.
    final esperar = emAtaque && _inicio < _palhetada;
    final previsto = _prever(estado, tempo);
    final inovacao = cents - previsto.c;
    // O ataque só deixa a corda mais aguda: na espera, uma leitura mais
    // grave que a previsão não é do ataque e se mede com o ruído normal.
    final rPortao = esperar && inovacao < 0 ? _ruido : r;
    final aceita =
        inovacao * inovacao <=
        desviosRejeicao * desviosRejeicao * (previsto.p00 + rPortao);
    if (aceita && esperar) return _atual;
    if (aceita) {
      if (!emAtaque) {
        _aprenderRuido(inovacao, previsto.p00);
        _assentadas.add(cents);
        if (_assentadas.length > leiturasParaSaltar) _assentadas.removeAt(0);
      }
      final corrigido = _corrigir(previsto, inovacao, r);
      // No ataque de uma corda nova, a primeira leitura assentada precisa
      // pesar mais que todas as do ataque: a incerteza não desce do ruído do
      // ataque, e a velocidade não aprende com ele.
      _estado = emAtaque
          ? (
              c: corrigido.c,
              v: 0,
              p00: math.max(corrigido.p00, r),
              p01: 0,
              p11: velocidadeInicial * velocidadeInicial,
              tempo: tempo,
            )
          : corrigido;
    }
    if (!aceita || !emAtaque) {
      _recentes.add((
        tempo: tempo,
        cents: cents,
        ataque: emAtaque,
        aceita: aceita,
      ));
      if (_recentes.length > leiturasParaSaltar) _recentes.removeAt(0);
    }
    if (_saltar(tempo)) return _atual = _exibir(tempo);
    if (!aceita) return _atual = _exibirRejeitada(r);
    return _atual = _exibir(tempo);
  }

  void _recomecar(double tempo, double cents, double r) {
    _estado = (
      c: cents,
      v: 0,
      p00: r,
      p01: 0,
      p11: velocidadeInicial * velocidadeInicial,
      tempo: tempo,
    );
    _inicio = tempo;
    _recentes.clear();
    _assentadas.clear();
    _alvoPonteiro = null;
    _ponteiro = null;
    _analisesFora = 0;
  }

  /// O estado [e] levado até [tempo]: o desvio anda com a velocidade e a
  /// incerteza cresce com a aceleração possível no intervalo; passado
  /// [tempoLacuna], a velocidade volta a zero e a incerteza cresce com
  /// [velocidadeLacuna].
  _Estado _prever(_Estado e, double tempo) {
    final dt = tempo - e.tempo;
    if (dt <= 0) return e;
    final t2 = tempoResposta * tempoResposta;
    final q = _ruido * _intervalo / (t2 * t2);
    final v0 = velocidadeInicial;
    final resto = math.max(0.0, dt - tempoLacuna);
    final lacuna = resto * resto;
    if (e.tempo <= _palhetada) {
      // Desde a palhetada, nenhuma leitura aceita: a mão que tocou a corda
      // não estava na tarraxa, e a diferença para a próxima leitura é do
      // desvio, não de uma velocidade.
      return (
        c: e.c,
        v: 0,
        p00:
            e.p00 +
            q * dt * dt * dt / 3 +
            velocidadeLacuna * velocidadeLacuna * lacuna,
        p01: 0,
        p11: v0 * v0,
        tempo: tempo,
      );
    }
    final h = dt - resto;
    final c = e.c + e.v * h;
    final p00 = e.p00 + 2 * h * e.p01 + h * h * e.p11 + q * h * h * h / 3;
    if (resto > 0) {
      return (
        c: c,
        v: 0,
        p00: p00 + (e.v * e.v + velocidadeLacuna * velocidadeLacuna) * lacuna,
        p01: 0,
        p11: v0 * v0,
        tempo: tempo,
      );
    }
    return (
      c: c,
      v: e.v,
      p00: p00,
      p01: e.p01 + h * e.p11 + q * h * h / 2,
      p11: e.p11 + q * h,
      tempo: tempo,
    );
  }

  _Estado _corrigir(_Estado e, double inovacao, double r) {
    final s = e.p00 + r;
    final k0 = e.p00 / s;
    final k1 = e.p01 / s;
    return (
      c: e.c + k0 * inovacao,
      v: e.v + k1 * inovacao,
      p00: (1 - k0) * e.p00,
      p01: (1 - k0) * e.p01,
      p11: e.p11 - k1 * e.p01,
      tempo: e.tempo,
    );
  }

  /// Confere as últimas [leiturasParaSaltar] leituras: com a maioria
  /// rejeitada (a última inclusive), se elas seguem uma reta ou um valor só
  /// e discordam do desvio estimado, o filtro passa a seguir o ajuste delas.
  /// Diz se passou.
  bool _saltar(double tempo) {
    final n = leiturasParaSaltar;
    final janela = _recentes;
    if (janela.length < n || janela.last.aceita) return false;
    if (janela.where((x) => !x.aceita).length < (n + 1) ~/ 2) return false;
    final comAtaque = janela.any((x) => x.ataque);
    var mediaT = 0.0, mediaC = 0.0;
    for (final x in janela) {
      mediaT += x.tempo / n;
      mediaC += x.cents / n;
    }
    var sxx = 0.0, sxy = 0.0;
    for (final x in janela) {
      sxx += (x.tempo - mediaT) * (x.tempo - mediaT);
      sxy += (x.tempo - mediaT) * (x.cents - mediaC);
    }
    final ruido = _ruido;
    final inclinacao = sxx > 0 ? sxy / sxx : 0.0;
    final d = tempo - mediaT;
    final estado = _estado!;
    final _Estado novo;
    final double incerteza;
    if (!comAtaque &&
        inclinacao * inclinacao * sxx > 4 * ruido &&
        inclinacao.abs() <= velocidadeMaxima) {
      // A tarraxa girando: uma reta que cabe no ruído e sai de onde o filtro
      // estava.
      final limite = desviosRejeicao * math.sqrt(ruido);
      var residuos = 0.0;
      for (final x in janela) {
        final residuo = x.cents - mediaC - inclinacao * (x.tempo - mediaT);
        if (residuo.abs() > limite) return false;
        residuos += residuo * residuo;
      }
      if (residuos / (n - 2) > _residuosReta * ruido) return false;
      final partida = mediaC + inclinacao * (estado.tempo - mediaT) - estado.c;
      if (partida * partida >
          desviosRejeicao * desviosRejeicao * (estado.p00 + ruido)) {
        return false;
      }
      incerteza = ruido * (1 / n + d * d / sxx);
      novo = (
        c: mediaC + inclinacao * d,
        v: inclinacao,
        p00: incerteza,
        p01: ruido * d / sxx,
        p11: ruido / sxx,
        tempo: tempo,
      );
    } else {
      // Um valor só; com leituras do ataque, a mediana, que as deixa de fora.
      final r = ruido * (comAtaque ? fatorAtaque * fatorAtaque : 1);
      var menor = janela.first.cents, maior = menor;
      for (final x in janela) {
        menor = math.min(menor, x.cents);
        maior = math.max(maior, x.cents);
      }
      if (maior - menor > desviosRejeicao * math.sqrt(r)) return false;
      final ordenadas = [for (final x in janela) x.cents]..sort();
      incerteza = r / n;
      novo = (
        c: comAtaque ? ordenadas[n ~/ 2] : mediaC,
        v: 0,
        p00: r,
        p01: 0,
        p11: velocidadeInicial * velocidadeInicial,
        tempo: tempo,
      );
    }
    final atual = _prever(estado, tempo);
    final diferenca = novo.c - atual.c;
    if (diferenca * diferenca <=
        desviosRejeicao * desviosRejeicao * (atual.p00 + incerteza)) {
      return false;
    }
    final assentadas = [
      for (final x in janela)
        if (!x.ataque) x.cents,
    ];
    if (janela.every((x) => !x.aceita)) _recomecar(tempo, novo.c, novo.p00);
    _estado = novo;
    _recentes.clear();
    _assentadas
      ..clear()
      ..addAll(assentadas);
    _analisesFora = 0;
    return true;
  }

  /// Média exponencial da variância da leitura: a inovação ao quadrado menos
  /// a parte que vem da incerteza da previsão [p00], com o piso na média.
  void _aprenderRuido(double inovacao, double p00) {
    if (p00 >= _ruido) return;
    final peso = 1 - math.exp(-_intervalo / constanteRuido);
    _ruido = math.max(
      _ruido + peso * (inovacao * inovacao - p00 - _ruido),
      ruidoMinimo * ruidoMinimo,
    );
  }

  Exibicao _exibir(double tempo) {
    final estado = _estado!;
    final c = estado.c;
    final tolerancia = _precisao.tolerancia;
    final sigma = math.sqrt(_ruido);

    // O ponteiro: um passo até o desvio estimado, mais o que a velocidade
    // prevê (no máximo por tempoLacuna), dentro das últimas leituras, e a
    // folga.
    final anterior = _alvoPonteiro;
    var alvo = c;
    if (anterior != null) {
      final passou = math.min(tempo - _tempoExibicao, tempoLacuna);
      final extrapolado = anterior + estado.v * passou;
      alvo = extrapolado + passoPonteiro * (c - extrapolado);
    }
    final ultimas = _ultimasAssentadas;
    if (ultimas != null) {
      final margem = _margemLeituras * sigma;
      final menor = ultimas.reduce(math.min) - margem;
      final maior = ultimas.reduce(math.max) + margem;
      if (estado.v * estado.v > 4 * estado.p11) {
        alvo = alvo.clamp(menor, maior);
      } else if (estado.v > 0 && alvo > maior) {
        alvo = maior;
      } else if (estado.v < 0 && alvo < menor) {
        alvo = menor;
      }
    }
    _alvoPonteiro = alvo;
    _tempoExibicao = tempo;
    final folga = folgaPonteiro * tolerancia;
    final ponteiro = _ponteiro;
    if (ponteiro == null) {
      _ponteiro = alvo;
    } else if (alvo > ponteiro + folga) {
      _ponteiro = alvo - folga;
    } else if (alvo < ponteiro - folga) {
      _ponteiro = alvo + folga;
    }
    final p = _ponteiro!;

    final numero = _numero;
    if (numero == null ||
        (p - numero).abs() > 0.5 + histereseNumero * tolerancia) {
      _numero = p.round();
    }

    final entrada = entradaAfinada * tolerancia;
    final desvio = _desvioMarca(estado);
    final saida = _saida;
    if (_afinada) {
      final alem = saida + _margemLeituras * sigma;
      _analisesFora = desvio.abs() > saida ? _analisesFora + 1 : 0;
      if (_analisesFora >= analisesSaida ||
          desvio.abs() > alem ||
          (ultimas != null && _todasAlem(ultimas, alem))) {
        _afinada = false;
        _analisesFora = 0;
      }
    } else if (desvio.abs() <= entrada &&
        tempo - math.max(_inicio, _palhetada) >= tempoAtaque &&
        _assentadas.length >= _leiturasMarca &&
        _media(_assentadas).abs() <= entrada &&
        _rmsRecentes.last >= fracaoEnergia * _picoPalhetada) {
      _afinada = true;
    }
    return Exibicao(ponteiro: p, numero: _numero!, afinada: _afinada);
  }

  /// Numa análise rejeitada, o ponteiro e o número ficam, mas a marca de
  /// afinada apaga se as duas últimas leituras, rejeitadas e concordando
  /// entre si, estão do mesmo lado além da saída: a corda saiu da
  /// tolerância mais depressa do que o filtro aceita.
  Exibicao? _exibirRejeitada(double r) {
    final atual = _atual;
    final n = _recentes.length;
    if (atual == null || !_afinada || n < 2) return atual;
    final a = _recentes[n - 2], b = _recentes[n - 1];
    if (a.aceita ||
        b.aceita ||
        !_todasAlem([a.cents, b.cents], _saida) ||
        (a.cents - b.cents).abs() > desviosRejeicao * math.sqrt(r)) {
      return atual;
    }
    _afinada = false;
    _analisesFora = 0;
    return Exibicao(
      ponteiro: atual.ponteiro,
      numero: atual.numero,
      afinada: false,
    );
  }

  /// As últimas [_leiturasMarca] leituras assentadas; null se ainda não há
  /// tantas.
  List<double>? get _ultimasAssentadas => _assentadas.length < _leiturasMarca
      ? null
      : _assentadas.sublist(_assentadas.length - _leiturasMarca);

  /// O desvio que decide a marca: o estimado, sem sair das últimas leituras
  /// assentadas por mais de [_margemMarca] desvios do ruído.
  double _desvioMarca(_Estado estado) {
    final ultimas = _ultimasAssentadas;
    if (ultimas == null) return estado.c;
    final margem = _margemMarca * math.sqrt(_ruido);
    return estado.c.clamp(
      ultimas.reduce(math.min) - margem,
      ultimas.reduce(math.max) + margem,
    );
  }

  /// Onde a marca de afinada sai, em cents.
  double get _saida {
    final tolerancia = _precisao.tolerancia;
    return math.max(
      saidaAfinada * tolerancia,
      entradaAfinada * tolerancia + faixaAfinada * math.sqrt(_ruido),
    );
  }

  /// Se todos os [valores] ficam do mesmo lado, além de [limite].
  static bool _todasAlem(List<double> valores, double limite) =>
      valores.every((x) => x > limite) || valores.every((x) => x < -limite);

  static double _media(List<double> valores) =>
      valores.isEmpty ? 0 : valores.reduce((a, b) => a + b) / valores.length;

  /// Marca a palhetada na primeira análise em que o RMS passa
  /// [fatorPalhetada] vezes o menor RMS recente, o maior deles e
  /// [_energiaPalhetada]. Nas análises seguintes da mesma subida o mínimo
  /// recente ainda é o de antes dela, e elas não contam: senão o ataque se
  /// estenderia por toda a subida.
  void _acompanharEnergia(double tempo, double rms) {
    var subiu = false;
    if (_rmsRecentes.isNotEmpty && rms >= _energiaPalhetada) {
      var menor = double.infinity, maior = 0.0;
      for (final valor in _rmsRecentes) {
        menor = math.min(menor, valor);
        maior = math.max(maior, valor);
      }
      subiu = rms > fatorPalhetada * menor && rms > maior;
    }
    if (subiu && !_subindo) {
      // Quem toca a corda soltou a tarraxa: o estado vai até a palhetada, a
      // velocidade recomeça dali, e o desvio pode ter mudado desde a última
      // leitura aceita.
      final e = _estado;
      if (e != null) {
        final previsto = _prever(e, tempo);
        final desde = tempo - e.tempo;
        final p00 = math.max(
          previsto.p00,
          e.p00 + velocidadeLacuna * velocidadeLacuna * desde * desde,
        );
        _estado = (
          c: previsto.c,
          v: 0,
          p00: math.max(p00, _pisoPalhetada * _ruido),
          p01: 0,
          p11: velocidadeInicial * velocidadeInicial,
          tempo: tempo,
        );
      }
      _palhetada = tempo;
      _picoPalhetada = rms;
    }
    _picoPalhetada = math.max(_picoPalhetada, rms);
    _subindo = subiu;
    _rmsRecentes.add(rms);
    if (_rmsRecentes.length > _historicoRms) _rmsRecentes.removeAt(0);
  }
}
