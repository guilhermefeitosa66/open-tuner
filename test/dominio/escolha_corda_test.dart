import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/afinacoes.dart';
import 'package:open_tuner/dominio/escolha_corda.dart';

List<double> alvosDe(String instrumento, [String afinacao = '']) =>
    instrumentoPorId(
      instrumento,
    ).afinacao(afinacao).notas.map((n) => n.frequencia()).toList();

/// [frequencia] deslocada de [cents].
double desvio(double frequencia, double cents) =>
    frequencia * math.pow(2, cents / 1200).toDouble();

void main() {
  // Violão padrão: E2 A2 D3 G3 B3 E4.
  final violao = alvosDe('violao');

  group('modo automático', () {
    test('sem leitura ainda não há corda', () {
      final escolha = EscolhaCorda(alvos: violao);
      expect(escolha.atual, isNull);
      expect(escolha.fixada, isFalse);
    });

    test('a primeira leitura escolhe a corda mais próxima', () {
      final escolha = EscolhaCorda(alvos: violao);
      expect(escolha.escolher(desvio(110, -30)), 1); // A2 frouxa
      expect(escolha.atual, 1);
    });

    test('escolhe a mais próxima em cents para cada corda', () {
      for (var i = 0; i < violao.length; i++) {
        final escolha = EscolhaCorda(alvos: violao);
        expect(escolha.escolher(desvio(violao[i], 40)), i);
      }
    });

    test('histerese: 4 leituras de outra corda não trocam, a 5ª troca', () {
      final escolha = EscolhaCorda(alvos: violao);
      escolha.escolher(82.41); // E2
      for (var i = 0; i < 4; i++) {
        expect(escolha.escolher(146.83), 0, reason: 'leitura ${i + 1}');
      }
      expect(escolha.escolher(146.83), 2);
      expect(escolha.atual, 2);
    });

    test('uma leitura da corda atual no meio zera a contagem', () {
      final escolha = EscolhaCorda(alvos: violao);
      escolha.escolher(82.41);
      for (var i = 0; i < 4; i++) {
        escolha.escolher(146.83);
      }
      expect(escolha.escolher(82.41), 0);
      for (var i = 0; i < 4; i++) {
        expect(escolha.escolher(146.83), 0);
      }
      expect(escolha.escolher(146.83), 2);
    });

    test('leituras alternando entre outras cordas não trocam', () {
      final escolha = EscolhaCorda(alvos: violao);
      escolha.escolher(82.41);
      for (var i = 0; i < 10; i++) {
        expect(escolha.escolher(i.isEven ? 110 : 146.83), 0);
      }
    });

    test('leiturasParaTrocar configurável', () {
      final escolha = EscolhaCorda(alvos: violao, leiturasParaTrocar: 2);
      escolha.escolher(82.41);
      expect(escolha.escolher(110), 0);
      expect(escolha.escolher(110), 1);
    });

    test('ukulele reentrante G4 C4 E4 A4 escolhe certo', () {
      final ukulele = alvosDe('ukulele');
      final esperado = {392.0: 0, 261.63: 1, 329.63: 2, 440.0: 3};
      esperado.forEach((frequencia, indice) {
        final escolha = EscolhaCorda(alvos: ukulele);
        expect(escolha.escolher(desvio(frequencia, -20)), indice);
        expect(
          escolha.cents(desvio(frequencia, -20), indice),
          closeTo(-20, 0.1),
        );
      });
    });
  });

  group('cents', () {
    test('mede contra a corda pedida, com sinal', () {
      final escolha = EscolhaCorda(alvos: violao);
      expect(escolha.cents(desvio(110, -18), 1), closeTo(-18, 1e-6));
      expect(escolha.cents(desvio(110, 7), 1), closeTo(7, 1e-6));
    });

    test('sem pares, a oitava de cima é longe', () {
      final escolha = EscolhaCorda(alvos: violao);
      expect(escolha.cents(220, 1), closeTo(1200, 1e-6));
    });

    test('pares: mede contra a oitava de cima quando está mais perto dela', () {
      // Viola, Cebolão em Mi: B2 E3 G♯3 B3 E4. O 3º par é G♯3 e G♯4.
      final viola = alvosDe('viola-caipira');
      final escolha = EscolhaCorda(alvos: viola, pares: true);
      final gSustenido4 = viola[2] * 2;
      expect(escolha.cents(desvio(gSustenido4, -10), 2), closeTo(-10, 1e-6));
      expect(escolha.cents(desvio(viola[2], 12), 2), closeTo(12, 1e-6));
    });
  });

  group('pares (viola caipira)', () {
    final viola = alvosDe('viola-caipira');

    test('a oitava de cima de um par conta como o próprio par', () {
      final escolha = EscolhaCorda(alvos: viola, pares: true);
      expect(escolha.escolher(desvio(viola[2] * 2, 8)), 2); // G♯4
    });

    test('nota que é corda e oitava de outro par: fica a corda', () {
      // B3 é o 4º par e também a oitava do 1º (B2).
      final escolha = EscolhaCorda(alvos: viola, pares: true);
      expect(escolha.escolher(viola[3]), 3);
    });

    test('mas, afinando o par B2, a oitava B3 não rouba o alvo', () {
      final escolha = EscolhaCorda(alvos: viola, pares: true);
      escolha.escolher(viola[0]); // B2
      for (var i = 0; i < 10; i++) {
        expect(escolha.escolher(desvio(viola[0] * 2, 3)), 0);
      }
    });
  });

  group('modo manual', () {
    test('fixar ignora as leituras', () {
      final escolha = EscolhaCorda(alvos: violao);
      escolha.escolher(82.41);
      escolha.fixar(4);
      expect(escolha.fixada, isTrue);
      expect(escolha.atual, 4);
      for (var i = 0; i < 10; i++) {
        expect(escolha.escolher(82.41), 4);
      }
    });

    test('fixar antes de qualquer leitura', () {
      final escolha = EscolhaCorda(alvos: violao);
      escolha.fixar(5);
      expect(escolha.escolher(82.41), 5);
    });

    test('fixar fora da afinação é erro', () {
      final escolha = EscolhaCorda(alvos: violao);
      expect(() => escolha.fixar(6), throwsRangeError);
    });

    test('liberar volta ao automático a partir da corda atual', () {
      final escolha = EscolhaCorda(alvos: violao);
      escolha.fixar(4);
      escolha.liberar();
      expect(escolha.fixada, isFalse);
      expect(escolha.atual, 4);
      for (var i = 0; i < 4; i++) {
        expect(escolha.escolher(82.41), 4);
      }
      expect(escolha.escolher(82.41), 0);
    });
  });

  test('trocarAlvos zera a escolha e volta ao automático', () {
    final escolha = EscolhaCorda(alvos: violao);
    escolha.fixar(3);
    escolha.trocarAlvos(alvosDe('violao', 'drop-d'));
    expect(escolha.atual, isNull);
    expect(escolha.fixada, isFalse);
    expect(escolha.escolher(73.42), 0);
  });
}
