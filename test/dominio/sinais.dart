import 'dart:math' as math;

/// Geradores de sinais sintéticos para os testes do detector.

/// Seno puro de [frequencia] Hz, amplitude [amplitude], [n] amostras.
List<double> seno(
  double frequencia,
  int taxa,
  int n, {
  double amplitude = 0.5,
  double fase = 0.3,
}) => List.generate(
  n,
  (i) => amplitude * math.sin(2 * math.pi * frequencia * i / taxa + fase),
);

/// Sinal "de corda": a fundamental e os harmônicos seguintes, com as
/// amplitudes relativas de [amplitudes] (a primeira é a da fundamental), cada
/// um com uma fase diferente. O resultado é escalado para pico perto de
/// [pico].
List<double> corda(
  double frequencia,
  int taxa,
  int n, {
  List<double> amplitudes = const [1, 0.6, 0.4, 0.25, 0.15, 0.1],
  double pico = 0.5,
}) {
  final soma = amplitudes.fold<double>(0, (a, b) => a + b);
  return List.generate(n, (i) {
    var valor = 0.0;
    for (var k = 0; k < amplitudes.length; k++) {
      final harmonico = k + 1;
      valor +=
          amplitudes[k] *
          math.sin(2 * math.pi * frequencia * harmonico * i / taxa + 0.7 * k);
    }
    return pico * valor / soma;
  });
}

/// Ruído branco gaussiano de desvio padrão [desvio], com semente fixa.
List<double> ruido(int n, double desvio, {int semente = 7}) {
  final aleatorio = math.Random(semente);
  return List.generate(n, (_) {
    // Box–Muller.
    final u1 = 1 - aleatorio.nextDouble();
    final u2 = aleatorio.nextDouble();
    return desvio * math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  });
}

/// Soma amostra a amostra.
List<double> somar(List<double> a, List<double> b) =>
    List.generate(a.length, (i) => a[i] + b[i]);

/// RMS do sinal.
double rms(List<double> sinal) =>
    math.sqrt(sinal.fold<double>(0, (s, v) => s + v * v) / sinal.length);

/// Corda "realista", por síntese aditiva: harmônicos 1 a 12 com
/// inarmonicidade [inarmonicidade] (B: o harmônico h soa em
/// `h · f0 · √(1 + B·h²)`), fases aleatórias, decaimento mais rápido nos
/// agudos, ataque com ruído nos primeiros 30 ms e um chiado de fundo.
List<double> cordaInarmonica(
  double frequencia,
  int taxa,
  double segundos,
  double inarmonicidade,
  math.Random aleatorio,
) {
  final n = (taxa * segundos).round();
  final saida = List<double>.filled(n, 0);
  for (var h = 1; h <= 12; h++) {
    final parcial = h * frequencia * math.sqrt(1 + inarmonicidade * h * h);
    if (parcial > taxa / 2.2) break;
    final amplitude = (h == 2 ? 1.3 : 1.0) / h;
    final fase = aleatorio.nextDouble() * 2 * math.pi;
    final decaimento = 2.5 / (1 + 0.35 * h);
    for (var k = 0; k < n; k++) {
      final t = k / taxa;
      saida[k] +=
          amplitude *
          math.exp(-t / decaimento) *
          math.sin(2 * math.pi * parcial * t + fase);
    }
  }
  for (var k = 0; k < n; k++) {
    final t = k / taxa;
    final ataque = t < 0.03
        ? (aleatorio.nextDouble() - 0.5) * 1.5 * (1 - t / 0.03)
        : 0.0;
    saida[k] =
        0.3 * saida[k] + ataque * 0.3 + (aleatorio.nextDouble() - 0.5) * 0.003;
  }
  return saida;
}
