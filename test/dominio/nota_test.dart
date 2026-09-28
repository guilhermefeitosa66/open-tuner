import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/nota.dart';

void main() {
  group('frequência', () {
    test('A4 é 440 Hz', () {
      expect(Nota('A', 4).frequencia(), closeTo(440, 0.01));
    });

    test('E2 (sexta corda do violão)', () {
      expect(Nota('E', 2).frequencia(), closeTo(82.41, 0.01));
    });

    test('B0 (corda mais grave do baixo de cinco cordas)', () {
      expect(Nota('B', 0).frequencia(), closeTo(30.87, 0.01));
    });

    test('C4 (dó central)', () {
      expect(Nota('C', 4).frequencia(), closeTo(261.63, 0.01));
    });

    test('A4 acompanha a referência', () {
      expect(Nota('A', 4).frequencia(442), closeTo(442, 0.01));
    });
  });

  group('MIDI', () {
    test('A4 é 69 e C4 é 60', () {
      expect(Nota('A', 4).midi, 69);
      expect(Nota('C', 4).midi, 60);
    });

    test('dePitch é o inverso de midi', () {
      expect(Nota.dePitch(69), Nota('A', 4));
      expect(Nota.dePitch(61), Nota('C#', 4));
      expect(Nota.dePitch(23), Nota('B', 0));
      for (var midi = 0; midi < 128; midi++) {
        expect(Nota.dePitch(midi).midi, midi);
      }
    });
  });

  group('cents', () {
    test('mesma frequência dá zero', () {
      expect(centsEntre(440, 440), 0);
    });

    test('446,16 Hz está uns 24 cents acima de 440', () {
      expect(centsEntre(446.16, 440), closeTo(24.0, 0.1));
    });

    test('abaixo do alvo é negativo', () {
      expect(centsEntre(440, 446.16), closeTo(-24.0, 0.1));
    });
  });
}
