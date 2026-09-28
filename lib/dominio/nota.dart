import 'dart:math' as math;

/// Nomes das doze notas da oitava, a partir de C, com sustenidos.
const nomesDasNotas = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Uma nota do temperamento igual, identificada por nome e oitava na notação
/// científica (A4 = lá central, C4 = dó central).
///
/// Dart puro, sem Flutter: é o que mantém a matemática do afinador testável
/// sem widget tree.
class Nota {
  /// [nome] tem de estar em [nomesDasNotas] (com sustenido, nunca bemol).
  Nota(this.nome, this.oitava)
    : assert(nomesDasNotas.contains(nome), 'nota desconhecida: $nome');

  /// A nota de número [midi] (69 = A4, 60 = C4).
  factory Nota.dePitch(int midi) =>
      Nota(nomesDasNotas[midi % 12], midi ~/ 12 - 1);

  final String nome;
  final int oitava;

  /// Número MIDI da nota: 12 por oitava, com C-1 = 0.
  int get midi => (oitava + 1) * 12 + nomesDasNotas.indexOf(nome);

  /// Frequência em Hz no temperamento igual, tomando [a4] como referência.
  double frequencia([double a4 = 440]) =>
      a4 * math.pow(2, (midi - 69) / 12).toDouble();

  @override
  bool operator ==(Object outro) =>
      outro is Nota && outro.nome == nome && outro.oitava == oitava;

  @override
  int get hashCode => Object.hash(nome, oitava);

  @override
  String toString() => '$nome$oitava';
}

/// Distância em cents de [frequencia] até [alvo]: positiva quando está acima
/// (aguda), negativa quando está abaixo (grave). 100 cents = um semitom.
double centsEntre(double frequencia, double alvo) =>
    1200 * math.log(frequencia / alvo) / math.ln2;
