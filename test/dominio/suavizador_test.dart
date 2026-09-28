import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/suavizador.dart';

void main() {
  test('a primeira leitura passa direto', () {
    final suavizador = Suavizador();
    expect(suavizador.valor, isNull);
    expect(suavizador.adicionar(-12), -12);
    expect(suavizador.valor, -12);
  });

  test('converge para uma leitura constante', () {
    final suavizador = Suavizador();
    suavizador.adicionar(0);
    var valor = 0.0;
    for (var i = 0; i < 20; i++) {
      valor = suavizador.adicionar(10);
    }
    expect(valor, closeTo(10, 0.01));
  });

  test('segue a tarraxa sem atraso perceptível', () {
    // Rampa de 1 cent por leitura (a mão apertando a corda): o valor
    // suavizado fica a poucos cents da leitura.
    final suavizador = Suavizador();
    var valor = 0.0;
    for (var i = -30; i <= 0; i++) {
      valor = suavizador.adicionar(i.toDouble());
    }
    expect(valor, closeTo(0, 6));
  });

  test('mediana corta um pico isolado', () {
    final suavizador = Suavizador();
    for (var i = 0; i < 10; i++) {
      suavizador.adicionar(2);
    }
    final depoisDoPico = suavizador.adicionar(40);
    expect(depoisDoPico, closeTo(2, 1e-9));
    expect(suavizador.adicionar(2), closeTo(2, 1e-9));
  });

  test('tira o tremor', () {
    final suavizador = Suavizador();
    final leituras = [3.0, -3.0, 3.0, -3.0, 3.0, -3.0, 3.0, -3.0, 3.0, -3.0];
    final saidas = leituras.map(suavizador.adicionar).toList();
    for (final saida in saidas.skip(4)) {
      expect(saida.abs(), lessThan(3));
    }
  });

  test('salto maior que 50 cents reinicia (corda nova)', () {
    final suavizador = Suavizador();
    for (var i = 0; i < 10; i++) {
      suavizador.adicionar(0);
    }
    expect(suavizador.adicionar(-60), -60);
    expect(suavizador.adicionar(-60), -60);
  });

  test('salto de até 50 cents não reinicia', () {
    final suavizador = Suavizador();
    for (var i = 0; i < 10; i++) {
      suavizador.adicionar(0);
    }
    expect(suavizador.adicionar(50), closeTo(0, 1e-9));
  });

  test('reiniciar esquece tudo', () {
    final suavizador = Suavizador();
    for (var i = 0; i < 10; i++) {
      suavizador.adicionar(20);
    }
    suavizador.reiniciar();
    expect(suavizador.valor, isNull);
    expect(suavizador.adicionar(-10), -10);
  });
}
