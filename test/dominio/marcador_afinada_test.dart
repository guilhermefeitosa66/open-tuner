import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/marcador_afinada.dart';

void main() {
  const passo = 0.04;

  /// Passa [leituras] pelo marcador a partir de [inicio], uma a cada 40 ms,
  /// e diz se alguma delas marcou.
  bool passar(
    MarcadorAfinada marcador,
    List<bool> leituras, [
    double inicio = 0,
  ]) {
    var marcou = false;
    for (var i = 0; i < leituras.length; i++) {
      marcou |= marcador.adicionar(
        tempo: inicio + i * passo,
        duracao: passo,
        afinada: leituras[i],
      );
    }
    return marcou;
  }

  test('1 s seguido dentro da tolerância marca, com o progresso subindo', () {
    final marcador = MarcadorAfinada();
    expect(marcador.progresso, 0);
    expect(passar(marcador, List.filled(12, true)), isFalse);
    expect(marcador.progresso, closeTo(0.48, 1e-9));
    expect(passar(marcador, List.filled(12, true), 0.48), isFalse);
    expect(
      marcador.adicionar(tempo: 0.96, duracao: passo, afinada: true),
      isTrue,
    );
    expect(marcador.progresso, 1);
  });

  test('idas e vindas somam dentro da janela', () {
    final marcador = MarcadorAfinada();
    // 3 afinadas, 2 fora, repetido: 60% do tempo dentro.
    final leituras = [
      for (var i = 0; i < 12; i++) ...[true, true, true, false, false],
    ];
    expect(passar(marcador, leituras), isTrue);
  });

  test('passar pela nota girando a tarraxa não marca', () {
    final marcador = MarcadorAfinada();
    // 0,2 s dentro a cada 2 s: só a passagem.
    final leituras = [
      for (var i = 0; i < 4; i++) ...[
        ...List.filled(5, true),
        ...List.filled(45, false),
      ],
    ];
    expect(passar(marcador, leituras), isFalse);
  });

  test('o que ficou para trás da janela não conta', () {
    final marcador = MarcadorAfinada();
    expect(passar(marcador, List.filled(20, true)), isFalse);
    expect(passar(marcador, List.filled(20, true), 5), isFalse);
  });

  test('reiniciar esquece o tempo somado', () {
    final marcador = MarcadorAfinada();
    passar(marcador, List.filled(20, true));
    marcador.reiniciar();
    expect(marcador.progresso, 0);
    expect(passar(marcador, List.filled(10, true), 0.8), isFalse);
  });
}
