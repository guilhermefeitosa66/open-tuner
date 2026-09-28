import 'nota.dart';

/// Decide qual corda da afinação é o alvo (RF-04 e RF-05).
///
/// No modo automático, o alvo é a corda mais próxima, em cents, da frequência
/// lida; para não pular entre cordas vizinhas, a troca só acontece depois de
/// [leiturasParaTrocar] leituras seguidas apontando para a mesma outra corda.
/// No modo manual, o alvo é a corda fixada e as leituras não mudam nada.
class EscolhaCorda {
  EscolhaCorda({
    required List<double> alvos,
    this.pares = false,
    this.leiturasParaTrocar = 5,
  }) : _alvos = List.unmodifiable(alvos),
       assert(leiturasParaTrocar >= 1, 'leiturasParaTrocar precisa ser >= 1');

  /// Viola caipira: a oitava de cima de um par conta como o próprio par.
  final bool pares;

  /// Quantas leituras seguidas apontando para outra corda trocam o alvo.
  final int leiturasParaTrocar;

  List<double> _alvos;
  int? _atual;
  bool _fixada = false;
  int? _candidata;
  int _seguidas = 0;

  /// Frequências (Hz) das cordas da afinação atual, na ordem física.
  List<double> get alvos => _alvos;

  /// Índice da corda alvo; null antes da primeira leitura (modo auto).
  int? get atual => _atual;

  /// true em modo manual.
  bool get fixada => _fixada;

  /// Modo automático: devolve o índice da corda alvo depois desta leitura, com
  /// histerese (a troca só acontece depois de [leiturasParaTrocar] leituras
  /// seguidas apontando para outra). Em modo manual devolve sempre a corda
  /// fixada.
  int escolher(double frequencia) {
    final atual = _atual;
    if (_fixada && atual != null) return atual;
    if (_alvos.isEmpty) {
      throw StateError('escolha de corda sem nenhuma corda alvo');
    }

    final maisProxima = _maisProxima(frequencia);
    if (atual == null) {
      _atual = maisProxima;
      _zerarContagem();
      return maisProxima;
    }
    if (maisProxima == atual) {
      _zerarContagem();
      return atual;
    }
    if (maisProxima == _candidata) {
      _seguidas++;
    } else {
      _candidata = maisProxima;
      _seguidas = 1;
    }
    if (_seguidas >= leiturasParaTrocar) {
      _atual = maisProxima;
      _zerarContagem();
      return maisProxima;
    }
    return atual;
  }

  /// Cents de [frequencia] até a corda [indice]. Com [pares], se a frequência
  /// estiver mais perto da oitava de cima do par, mede contra a oitava de cima.
  double cents(double frequencia, int indice) {
    final alvo = _alvos[indice];
    final fundamental = centsEntre(frequencia, alvo);
    if (!pares) return fundamental;
    final oitava = centsEntre(frequencia, alvo * 2);
    return oitava.abs() < fundamental.abs() ? oitava : fundamental;
  }

  /// Modo manual: [indice] vira o alvo até [liberar] ou [trocarAlvos].
  void fixar(int indice) {
    RangeError.checkValidIndex(indice, _alvos, 'indice');
    _atual = indice;
    _fixada = true;
    _zerarContagem();
  }

  /// Volta ao automático, mantendo a corda atual como ponto de partida.
  void liberar() {
    _fixada = false;
    _zerarContagem();
  }

  /// Nova afinação: zera a escolha. Volta também ao modo automático, com
  /// [atual] null até a próxima leitura; para continuar no manual, chame
  /// [fixar] de novo.
  void trocarAlvos(List<double> alvos) {
    _alvos = List.unmodifiable(alvos);
    _atual = null;
    _fixada = false;
    _zerarContagem();
  }

  /// A corda mais próxima de [frequencia]. Empate (dentro de uma fração
  /// ínfima de cent) fica com a corda atual e, fora dela, com a nota da
  /// própria corda antes da oitava de cima de outro par: na viola, B3 é a
  /// corda B3 e não a oitava do par B2, a menos que o alvo já seja o par B2.
  int _maisProxima(double frequencia) {
    const empate = 1e-6;
    var melhor = 0;
    var menor = double.infinity;
    for (var i = 0; i < _alvos.length; i++) {
      final distancia = centsEntre(frequencia, _alvos[i]).abs();
      if (distancia < menor - empate) {
        menor = distancia;
        melhor = i;
      }
    }
    if (pares) {
      for (var i = 0; i < _alvos.length; i++) {
        final distancia = centsEntre(frequencia, _alvos[i] * 2).abs();
        if (distancia < menor - empate) {
          menor = distancia;
          melhor = i;
        }
      }
    }
    final atual = _atual;
    if (atual != null &&
        atual < _alvos.length &&
        cents(frequencia, atual).abs() <= menor + empate) {
      return atual;
    }
    return melhor;
  }

  void _zerarContagem() {
    _candidata = null;
    _seguidas = 0;
  }
}
