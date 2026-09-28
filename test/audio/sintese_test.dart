import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/audio/sintese.dart';
import 'package:open_tuner/dominio/detector.dart';

void main() {
  group('cordaDedilhada', () {
    // A corda de referência precisa sair na nota: o detector do próprio app
    // mede a síntese, do baixo de 5 cordas ao cavaquinho.
    for (final frequencia in [30.87, 82.41, 196.0, 392.0, 659.26]) {
      test('soa em $frequencia Hz', () {
        final som = cordaDedilhada(frequencia);
        final detector = DetectorFrequencia(
          taxaAmostragem: taxaSintese,
          frequenciaMinima: 25,
          frequenciaMaxima: 900,
        );
        final tamanho = detector.tamanhoEntradaRecomendada;
        final inicio = (0.2 * taxaSintese).round();
        final leitura = detector.analisar(
          Float64List.sublistView(som, inicio, inicio + tamanho),
        );
        expect(leitura, isNotNull);
        expect(leitura!.frequencia, closeTo(frequencia, frequencia * 0.002));
      });
    }

    test('fica entre −1 e 1, começa e termina em silêncio', () {
      final som = cordaDedilhada(110);
      expect(som.every((a) => a.abs() <= 1), isTrue);
      expect(som.first.abs(), lessThan(1e-3));
      expect(som.last.abs(), lessThan(1e-3));
      expect(duracaoDe(som), closeTo(1.6, 0.001));
    });
  });

  test('o aviso de afinada é curto', () {
    final som = somAfinada();
    expect(duracaoDe(som), lessThan(0.6));
    expect(som.every((a) => a.abs() <= 1), isTrue);
  });

  test('wav: cabeçalho RIFF de PCM 16 bits mono', () {
    final bytes = wav(Float64List.fromList([0, 1, -1]));
    final dados = ByteData.sublistView(bytes);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 16)), 'WAVEfmt ');
    expect(dados.getUint16(22, Endian.little), 1);
    expect(dados.getUint32(24, Endian.little), taxaSintese);
    expect(dados.getUint32(40, Endian.little), 6);
    expect(dados.getInt16(46, Endian.little), 32767);
    expect(dados.getInt16(48, Endian.little), -32767);
    expect(bytes.length, 50);
  });
}
