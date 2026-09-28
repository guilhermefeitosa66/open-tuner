/// Quanto a corda pode fugir do alvo e ainda contar como afinada (RF-17).
enum Precisao { normal, fina }

/// Tolerância de cada [Precisao], em cents: ±5 na normal, ±2 na fina.
extension ToleranciaPrecisao on Precisao {
  double get tolerancia => switch (this) {
    Precisao.normal => 5,
    Precisao.fina => 2,
  };
}

/// Estado da corda, que define a cor do indicador e do rastro (RF-08).
enum EstadoCorda { afinada, perto, longe }

/// Até quantos cents, fora da tolerância, a corda conta como "perto".
const double limitePerto = 15;

/// Classifica o desvio [cents] (com sinal) segundo a [precisao]: afinada dentro
/// da tolerância, perto até [limitePerto] cents, longe acima disso. As
/// fronteiras são inclusivas (5 cents ainda é afinada; 15, ainda perto).
EstadoCorda classificar(double cents, Precisao precisao) {
  final distancia = cents.abs();
  if (distancia <= precisao.tolerancia) return EstadoCorda.afinada;
  if (distancia <= limitePerto) return EstadoCorda.perto;
  return EstadoCorda.longe;
}
