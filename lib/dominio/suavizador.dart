/// Mediana curta (5) seguida de média exponencial, para o ponteiro não tremer.
/// Um salto maior que 50 cents em relação ao valor suavizado reinicia o filtro
/// (corda nova).
///
/// A mediana corta leituras isoladas absurdas (um pico de um quadro); a média
/// exponencial tira o tremor fino sem atrasar a mão na tarraxa.
class Suavizador {
  Suavizador({this.alfa = 0.35, this.tamanhoMediana = 5})
    : assert(alfa > 0 && alfa <= 1, 'alfa fora de (0, 1]: $alfa'),
      assert(tamanhoMediana >= 1, 'mediana precisa de pelo menos 1 leitura');

  /// Peso da leitura nova na média exponencial (1 = sem suavização).
  final double alfa;

  /// Quantas leituras entram na mediana.
  final int tamanhoMediana;

  /// Salto, em cents, a partir do qual o filtro recomeça do zero.
  static const double saltoParaReiniciar = 50;

  final List<double> _recentes = [];
  double? _valor;

  /// O último valor suavizado; null antes da primeira leitura ou depois de
  /// [reiniciar].
  double? get valor => _valor;

  /// Acrescenta uma leitura em cents e devolve o valor suavizado.
  double adicionar(double cents) {
    final anterior = _valor;
    if (anterior != null && (cents - anterior).abs() > saltoParaReiniciar) {
      reiniciar();
    }
    _recentes.add(cents);
    if (_recentes.length > tamanhoMediana) _recentes.removeAt(0);
    final mediana = _mediana();
    final atual = _valor;
    final novo = atual == null ? mediana : atual + alfa * (mediana - atual);
    _valor = novo;
    return novo;
  }

  /// Esquece tudo: a próxima leitura entra sem suavização.
  void reiniciar() {
    _recentes.clear();
    _valor = null;
  }

  double _mediana() {
    final ordenadas = [..._recentes]..sort();
    final meio = ordenadas.length ~/ 2;
    return ordenadas.length.isOdd
        ? ordenadas[meio]
        : (ordenadas[meio - 1] + ordenadas[meio]) / 2;
  }
}
