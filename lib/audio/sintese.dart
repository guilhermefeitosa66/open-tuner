import 'dart:math' as math;
import 'dart:typed_data';

/// Sons do app, sintetizados aqui mesmo: nenhuma gravação de terceiros, nenhum
/// arquivo com licença para acompanhar. Dart puro, testável sem aparelho.

/// Taxa dos sons gerados.
const taxaSintese = 44100;

/// Uma corda dedilhada na [frequencia] exata (qualquer afinação, qualquer
/// referência A4), por síntese aditiva: harmônicos com a amplitude de uma
/// corda puxada perto do cavalete, os agudos morrendo antes dos graves.
///
/// No alto-falante de um celular a fundamental de um baixo quase não sai; os
/// harmônicos fazem o ouvido reconstruir a nota.
Float64List cordaDedilhada(
  double frequencia, {
  double duracao = 1.6,
  int taxa = taxaSintese,
}) {
  final total = (duracao * taxa).round();
  final amostras = Float64List(total);
  // Onde a corda é puxada, em fração do comprimento: define o timbre.
  const ponto = 0.18;
  final limite = math.min(taxa / 2 * 0.9, 9000.0);
  final harmonicos = math.max(1, math.min(24, limite ~/ frequencia));
  // Cordas graves soam por mais tempo.
  final decaimento = 1.2 + frequencia / 250;
  for (var k = 1; k <= harmonicos; k++) {
    final amplitude = (math.sin(math.pi * k * ponto) / math.pow(k, 1.1)).abs();
    if (amplitude < 1e-4) continue;
    final omega = 2 * math.pi * frequencia * k / taxa;
    final queda = math.exp(-(decaimento * (1 + 0.45 * (k - 1))) / taxa);
    var envelope = amplitude;
    for (var i = 0; i < total; i++) {
      amostras[i] += envelope * math.sin(omega * i);
      envelope *= queda;
    }
  }
  _moldar(amostras, taxa, ataque: 0.004, soltura: 0.25);
  _normalizar(amostras, 0.8);
  return amostras;
}

/// O aviso de corda afinada: duas notas curtas de sino, subindo uma quinta
/// (E6 e B6). Agudo de propósito, acima de toda corda que o detector procura.
Float64List somAfinada({int taxa = taxaSintese}) {
  const duracao = 0.55;
  final total = (duracao * taxa).round();
  final amostras = Float64List(total);
  void sino(double frequencia, double inicio, double peso) {
    final primeira = (inicio * taxa).round();
    for (var i = primeira; i < total; i++) {
      final t = (i - primeira) / taxa;
      final envelope = math.exp(-t * 9) * math.min(1, t / 0.003);
      amostras[i] +=
          peso *
          envelope *
          (math.sin(2 * math.pi * frequencia * t) +
              0.3 *
                  math.sin(2 * math.pi * frequencia * 2.76 * t) *
                  math.exp(-t * 14));
    }
  }

  sino(1318.51, 0, 1);
  sino(1975.53, 0.09, 0.9);
  _moldar(amostras, taxa, ataque: 0.002, soltura: 0.08);
  _normalizar(amostras, 0.6);
  return amostras;
}

/// Duração, em segundos, de [amostras] na [taxa].
double duracaoDe(Float64List amostras, {int taxa = taxaSintese}) =>
    amostras.length / taxa;

/// Empacota [amostras] (−1 a 1) num WAV PCM de 16 bits, mono.
Uint8List wav(Float64List amostras, {int taxa = taxaSintese}) {
  final dados = amostras.length * 2;
  final bytes = ByteData(44 + dados);
  void texto(int posicao, String valor) {
    for (var i = 0; i < valor.length; i++) {
      bytes.setUint8(posicao + i, valor.codeUnitAt(i));
    }
  }

  texto(0, 'RIFF');
  bytes.setUint32(4, 36 + dados, Endian.little);
  texto(8, 'WAVE');
  texto(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, taxa, Endian.little)
    ..setUint32(28, taxa * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  texto(36, 'data');
  bytes.setUint32(40, dados, Endian.little);
  for (var i = 0; i < amostras.length; i++) {
    final valor = (amostras[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + i * 2, valor, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// Rampa de entrada (sem estalo no começo) e de saída (sem corte no fim).
void _moldar(
  Float64List amostras,
  int taxa, {
  required double ataque,
  required double soltura,
}) {
  final entrada = math.max(1, (ataque * taxa).round());
  final saida = math.max(1, (soltura * taxa).round());
  for (var i = 0; i < entrada && i < amostras.length; i++) {
    amostras[i] *= i / entrada;
  }
  for (var i = 0; i < saida && i < amostras.length; i++) {
    amostras[amostras.length - 1 - i] *= i / saida;
  }
}

void _normalizar(Float64List amostras, double pico) {
  var maior = 0.0;
  for (final a in amostras) {
    if (a.abs() > maior) maior = a.abs();
  }
  if (maior == 0) return;
  final fator = pico / maior;
  for (var i = 0; i < amostras.length; i++) {
    amostras[i] *= fator;
  }
}
