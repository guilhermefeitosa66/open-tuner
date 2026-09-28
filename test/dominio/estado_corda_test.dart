import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/estado_corda.dart';

void main() {
  test('tolerâncias', () {
    expect(Precisao.normal.tolerancia, 5);
    expect(Precisao.fina.tolerancia, 2);
  });

  group('precisão normal', () {
    EstadoCorda estado(double cents) => classificar(cents, Precisao.normal);

    test('afinada até 5 cents, dos dois lados', () {
      expect(estado(0), EstadoCorda.afinada);
      expect(estado(5), EstadoCorda.afinada);
      expect(estado(-5), EstadoCorda.afinada);
    });

    test('perto acima de 5 e até 15', () {
      expect(estado(5.01), EstadoCorda.perto);
      expect(estado(-5.01), EstadoCorda.perto);
      expect(estado(15), EstadoCorda.perto);
      expect(estado(-15), EstadoCorda.perto);
    });

    test('longe acima de 15', () {
      expect(estado(15.01), EstadoCorda.longe);
      expect(estado(-15.01), EstadoCorda.longe);
      expect(estado(-120), EstadoCorda.longe);
    });
  });

  group('precisão fina', () {
    EstadoCorda estado(double cents) => classificar(cents, Precisao.fina);

    test('afinada só até 2 cents', () {
      expect(estado(2), EstadoCorda.afinada);
      expect(estado(-2), EstadoCorda.afinada);
      expect(estado(2.01), EstadoCorda.perto);
      expect(estado(-4), EstadoCorda.perto);
    });

    test('perto e longe não mudam', () {
      expect(estado(15), EstadoCorda.perto);
      expect(estado(15.01), EstadoCorda.longe);
    });
  });
}
