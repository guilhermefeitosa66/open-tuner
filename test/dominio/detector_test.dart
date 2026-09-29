import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/detector.dart';
import 'package:open_tuner/dominio/nota.dart';

import 'sinais.dart';

const taxas = [44100, 48000];

/// Frequências de 30 a 1000 Hz, com as cordas-limite do app.
const frequenciasSeno = [
  30.87, // B0
  36.71, // D1
  41.20, // E1
  55.00, // A1
  82.41, // E2
  110.00, // A2
  146.83, // D3
  196.00, // G3
  261.63, // C4
  329.63, // E4
  440.00, // A4
  587.33, // D5
  659.26, // E5
  800.00,
  1000.00,
];

/// Cents do que o detector leu até [esperada]; falha se não leu nada.
double erroEmCents(
  DetectorFrequencia detector,
  List<double> sinal,
  double esperada,
) {
  final leitura = detector.analisar(sinal);
  expect(leitura, isNotNull, reason: 'nenhuma leitura para $esperada Hz');
  return centsEntre(leitura!.frequencia, esperada);
}

void main() {
  group('tamanho da janela', () {
    test('4096 com a faixa padrão (28 Hz), a 44,1 e 48 kHz', () {
      expect(DetectorFrequencia(taxaAmostragem: 44100).tamanhoJanela, 4096);
      expect(DetectorFrequencia(taxaAmostragem: 48000).tamanhoJanela, 4096);
    });

    test('2048 a 44,1 kHz a partir de 43 Hz', () {
      final detector = DetectorFrequencia(
        taxaAmostragem: 44100,
        frequenciaMinima: 43,
      );
      expect(detector.tamanhoJanela, 2048);
    });

    test('usa só as últimas amostras e recusa janela curta', () {
      final detector = DetectorFrequencia(taxaAmostragem: 44100);
      final n = detector.tamanhoJanela;
      final longo = [...List.filled(1000, 0.0), ...seno(440, 44100, n)];
      expect(erroEmCents(detector, longo, 440).abs(), lessThan(1));
      expect(detector.analisar(seno(440, 44100, n - 1)), isNull);
    });
  });

  // Com a entrada do tamanho da janela, a leitura é só a bruta; com o dobro,
  // passa também pelo refino com o passa-baixas. Os dois têm de acertar.
  for (final taxa in taxas) {
    for (final entrada in [1, 2]) {
      group('a $taxa Hz, entrada de $entrada× a janela', () {
        final detector = DetectorFrequencia(taxaAmostragem: taxa);
        final n = detector.tamanhoJanela * entrada;

        test('seno puro de 30 a 1000 Hz: erro de até 1 cent', () {
          for (final f in frequenciasSeno) {
            expect(
              erroEmCents(detector, seno(f, taxa, n), f).abs(),
              lessThanOrEqualTo(1),
              reason: '$f Hz',
            );
          }
        });

        test('seno fraco, mas acima da energia mínima, ainda é lido', () {
          final sinal = seno(110, taxa, n, amplitude: 0.01);
          expect(erroEmCents(detector, sinal, 110).abs(), lessThanOrEqualTo(1));
        });

        test('corda com harmônicos 2 a 6: dá a fundamental, até 1 cent', () {
          for (final f in [
            41.20,
            55.0,
            82.41,
            110.0,
            196.0,
            329.63,
            440.0,
            659.26,
          ]) {
            expect(
              erroEmCents(detector, corda(f, taxa, n), f).abs(),
              lessThanOrEqualTo(1),
              reason: '$f Hz',
            );
          }
        });

        test('baixo com o 2º harmônico 2× mais forte: dá a fundamental', () {
          for (final f in [30.87, 41.20, 55.0, 73.42, 98.0]) {
            final sinal = corda(
              f,
              taxa,
              n,
              amplitudes: const [1, 2, 0.6, 0.4, 0.25, 0.1],
            );
            expect(
              erroEmCents(detector, sinal, f).abs(),
              lessThanOrEqualTo(1),
              reason: '$f Hz',
            );
          }
        });

        test('corda aguda não dá a oitava de baixo', () {
          for (final f in [329.63, 440.0, 587.33, 659.26, 1000.0]) {
            final sinal = corda(f, taxa, n, amplitudes: const [1, 0.1, 0.05]);
            expect(
              erroEmCents(detector, sinal, f).abs(),
              lessThanOrEqualTo(1),
              reason: '$f Hz',
            );
          }
        });

        // O caso do microfone do celular: a fundamental quase some e os
        // harmônicos pares dominam. O mergulho de d' em meio período fica
        // abaixo do limiar do YIN (~0,07 no primeiro timbre, ~0,13 no
        // segundo, como na gravação real), e o primeiro abaixo do limiar
        // dava a oitava de cima.
        test(
          'fundamental fraca e harmônicos pares fortes: dá a fundamental',
          () {
            var semente = 20;
            for (final amplitudes in const [
              [0.2, 1.0, 0.1, 0.6, 0.05, 0.3],
              [0.25, 1.0, 0.2, 0.7, 0.1, 0.4],
            ]) {
              for (final f in [41.2, 55.0, 73.42, 82.41, 110.0, 146.83]) {
                final sinal = somar(
                  corda(f, taxa, n, amplitudes: amplitudes),
                  ruido(n, 0.005, semente: semente++),
                );
                expect(
                  erroEmCents(detector, sinal, f).abs(),
                  lessThanOrEqualTo(1),
                  reason: '$f Hz, $amplitudes',
                );
              }
            }
          },
        );

        // Um sinal periódico em τ também é em 2τ, 3τ... e o ruído pode deixar
        // d' num desses múltiplos um pouco abaixo do de τ: a escolha é o
        // primeiro mergulho perto do mais fundo, não o mais fundo. O mais
        // fundo pode cair longe (o 13º múltiplo no 880 Hz a 48 kHz), onde o
        // atraso inteiro de τ, multiplicado, já erra por algumas amostras.
        test('nota aguda com ruído (SNR ~14 dB) não cai uma oitava', () {
          var semente = 40;
          for (final f in [
            261.63,
            329.63,
            392.0,
            440.0,
            587.33,
            659.26,
            880.0,
            1000.0,
          ]) {
            final limpo = corda(f, taxa, n, amplitudes: const [1, 0.3, 0.1]);
            final sinal = somar(
              limpo,
              ruido(n, rms(limpo) / 5, semente: semente++),
            );
            expect(
              erroEmCents(detector, sinal, f).abs(),
              lessThanOrEqualTo(6),
              reason: '$f Hz',
            );
          }
        });

        // A corda solta uma oitava (ou uma 12ª) abaixo soando por simpatia,
        // como o D4 sob o D5 do cavaquinho: o sinal passa a ser periódico
        // no múltiplo, e d' ali fica abaixo do d' do período da nota tocada.
        // A outra corda puxa a leitura uns cents (como já puxava antes), mas
        // não pode levar à oitava de baixo.
        test('corda uma oitava ou 12ª abaixo, a 20%: a aguda não cai', () {
          var semente = 60;
          for (final divisor in [2, 3]) {
            for (final f in [293.66, 392.0, 440.0, 587.33, 659.26, 1000.0]) {
              final sinal = somar(
                somar(
                  corda(f, taxa, n, amplitudes: const [1, 0.4, 0.2, 0.1]),
                  corda(f / divisor, taxa, n, pico: 0.1),
                ),
                ruido(n, 0.005, semente: semente++),
              );
              expect(
                erroEmCents(detector, sinal, f).abs(),
                lessThanOrEqualTo(5),
                reason: '$f Hz com $f/$divisor',
              );
            }
          }
        });

        test('com ruído branco (SNR ~20 dB): erro de até 3 cents', () {
          var semente = 1;
          for (final f in [30.87, 41.20, 82.41, 196.0, 440.0, 659.26]) {
            final limpo = corda(f, taxa, n);
            // SNR de 20 dB: potência do ruído = potência do sinal / 100.
            final sujo = somar(
              limpo,
              ruido(n, rms(limpo) / 10, semente: semente++),
            );
            expect(
              erroEmCents(detector, sujo, f).abs(),
              lessThanOrEqualTo(3),
              reason: '$f Hz',
            );
          }
        });

        test('silêncio não dá leitura', () {
          expect(detector.analisar(List.filled(n, 0.0)), isNull);
          // Chiado bem baixo, abaixo da energia mínima.
          expect(detector.analisar(ruido(n, 0.001)), isNull);
          // Nível DC sem som.
          expect(detector.analisar(List.filled(n, 0.3)), isNull);
        });

        test('ruído puro não dá leitura', () {
          for (var semente = 1; semente <= 10; semente++) {
            expect(
              detector.analisar(ruido(n, 0.2, semente: semente)),
              isNull,
              reason: 'semente $semente',
            );
          }
        });

        test('frequência acima da faixa não dá leitura', () {
          expect(detector.analisar(seno(3000, taxa, n)), isNull);
        });

        test('A4 desafinado 18 cents abaixo dá −18 ± 1 cent', () {
          final f = 440 * math.pow(2, -18 / 1200).toDouble();
          final leitura = detector.analisar(corda(f, taxa, n))!;
          expect(centsEntre(leitura.frequencia, 440), closeTo(-18, 1));
        });

        test('confiança alta em sinal limpo', () {
          final leitura = detector.analisar(corda(110, taxa, n))!;
          expect(leitura.confianca, greaterThan(0.9));
          expect(leitura.confianca, lessThanOrEqualTo(1));
        });
      });
    }
  }

  group('janela de 2048', () {
    for (final taxa in taxas) {
      test('a $taxa Hz acerta de E2 a E5 com até 1 cent', () {
        final detector = DetectorFrequencia(
          taxaAmostragem: taxa,
          frequenciaMinima: 50,
        );
        final n = detector.tamanhoJanela;
        expect(n, 2048);
        for (final f in [55.0, 82.41, 146.83, 329.63, 659.26, 1000.0]) {
          expect(
            erroEmCents(detector, corda(f, taxa, n), f).abs(),
            lessThanOrEqualTo(1),
            reason: '$f Hz',
          );
        }
      });

      test('a $taxa Hz rejeita abaixo da frequência mínima', () {
        final detector = DetectorFrequencia(
          taxaAmostragem: taxa,
          frequenciaMinima: 60,
        );
        expect(
          detector.analisar(seno(41.2, taxa, detector.tamanhoJanela)),
          isNull,
        );
      });
    }
  });

  // Na faixa do violão (até E4 × 1,3), o meio período de um E4 cai abaixo
  // do menor atraso buscado. Com o 2º harmônico dominante, d' mergulha ali
  // abaixo do limiar, e a regra "periódico abaixo da faixa é som acima da
  // faixa" descartava a leitura; só um mergulho perto do mais fundo conta.
  group('faixa do violão', () {
    for (final taxa in taxas) {
      test('a $taxa Hz lê as cordas agudas com o 2º harmônico dominante', () {
        final detector = DetectorFrequencia(
          taxaAmostragem: taxa,
          frequenciaMinima: 82.41 * 0.8,
          frequenciaMaxima: 329.63 * 1.3,
        );
        final n = detector.tamanhoEntradaRecomendada;
        var semente = 80;
        for (final f in [246.94, 293.66, 329.63]) {
          final sinal = somar(
            corda(f, taxa, n, amplitudes: const [0.25, 1, 0.2, 0.6, 0.1, 0.3]),
            ruido(n, 0.005, semente: semente++),
          );
          expect(
            erroEmCents(detector, sinal, f).abs(),
            lessThanOrEqualTo(1),
            reason: '$f Hz',
          );
        }
      });

      test('a $taxa Hz continua sem leitura acima da faixa', () {
        final detector = DetectorFrequencia(
          taxaAmostragem: taxa,
          frequenciaMinima: 82.41 * 0.8,
          frequenciaMaxima: 329.63 * 1.3,
        );
        final n = detector.tamanhoEntradaRecomendada;
        for (final f in [700.0, 1000.0, 1500.0]) {
          final sinal = corda(f, taxa, n, amplitudes: const [1, 0.5, 0.3]);
          expect(detector.analisar(sinal), isNull, reason: '$f Hz');
        }
      });
    }
  });

  group('corda inarmônica, entrada de 2× a janela deslizando a 25 Hz', () {
    // Numa corda de verdade os harmônicos são esticados (B > 0) e puxam o
    // período para cima; o refino com o passa-baixas tem de tirar isso.
    for (final taxa in taxas) {
      for (final inarmonicidade in [0.0002, 0.0008]) {
        for (final f in [30.87, 41.2, 82.41, 196.0, 440.0, 659.26]) {
          test('$taxa Hz, B = $inarmonicidade, $f Hz', () {
            final detector = DetectorFrequencia(
              taxaAmostragem: taxa,
              frequenciaMinima: f < 60 ? 28 : 55,
            );
            final entrada = detector.tamanhoEntradaRecomendada;
            final sinal = cordaInarmonica(
              f,
              taxa,
              3,
              inarmonicidade,
              math.Random(3),
            );
            final erros = <double>[];
            for (var fim = entrada; fim <= sinal.length; fim += taxa ~/ 25) {
              final leitura = detector.analisar(
                sinal.sublist(fim - entrada, fim),
              );
              expect(leitura, isNotNull, reason: 'amostra final $fim');
              erros.add(centsEntre(leitura!.frequencia, f).abs());
            }
            final primeiroSegundo = erros.take(25).reduce(math.max);
            final ordenados = [...erros]..sort();
            final mediana = ordenados[ordenados.length ~/ 2];
            expect(mediana, lessThanOrEqualTo(1.5), reason: 'mediana');
            expect(primeiroSegundo, lessThanOrEqualTo(5), reason: '1º segundo');
          });
        }
      }
    }
  });

  test('entrada recomendada é o dobro da janela', () {
    final detector = DetectorFrequencia(taxaAmostragem: 48000);
    expect(detector.tamanhoEntradaRecomendada, 2 * detector.tamanhoJanela);
  });

  test('entrada maior que a recomendada também serve', () {
    final detector = DetectorFrequencia(taxaAmostragem: 44100);
    final sinal = cordaInarmonica(82.41, 44100, 1, 0.0008, math.Random(5));
    final leitura = detector.analisar(sinal)!; // ~10 janelas; usa as 3 últimas
    expect(centsEntre(leitura.frequencia, 82.41).abs(), lessThanOrEqualTo(2));
  });

  test('desempenho: janela de 4096 com entrada de 2× bem abaixo de 3 ms', () {
    final detector = DetectorFrequencia(taxaAmostragem: 48000);
    final sinal = corda(82.41, 48000, detector.tamanhoEntradaRecomendada);
    for (var i = 0; i < 50; i++) {
      detector.analisar(sinal);
    }
    const repeticoes = 200;
    final cronometro = Stopwatch()..start();
    for (var i = 0; i < repeticoes; i++) {
      detector.analisar(sinal);
    }
    final milissegundos = cronometro.elapsedMicroseconds / repeticoes / 1000;
    // Folga larga para máquina de CI lenta; medido localmente em ~0,35 ms.
    expect(milissegundos, lessThan(3));
  });
}
