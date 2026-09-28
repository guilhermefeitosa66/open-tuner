import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/audio/fonte_audio.dart';
import 'package:open_tuner/audio/janela_deslizante.dart';

void main() {
  group('JanelaDeslizante', () {
    test('só entrega com a janela cheia, e depois a cada salto', () {
      final janela = JanelaDeslizante(tamanho: 4, salto: 2);
      final entregas = <List<double>>[];
      void guardar(Float64List j) => entregas.add(List.of(j));

      janela.adicionar([1, 2, 3], guardar);
      expect(entregas, isEmpty);
      janela.adicionar([4], guardar);
      expect(entregas, [
        [1, 2, 3, 4],
      ]);
      janela.adicionar([5, 6, 7], guardar);
      expect(entregas.last, [3, 4, 5, 6]);
      expect(entregas, hasLength(2));
      janela.adicionar([8], guardar);
      expect(entregas.last, [5, 6, 7, 8]);
    });

    test('um bloco grande entrega um salto de cada vez', () {
      final janela = JanelaDeslizante(tamanho: 2048, salto: 1764);
      var entregas = 0;
      janela.adicionar(Float64List(2048 + 1764 * 3), (_) => entregas++);
      expect(entregas, 4);
    });

    test('limpar esquece o que ouviu', () {
      final janela = JanelaDeslizante(tamanho: 2, salto: 1);
      var entregas = 0;
      janela.adicionar([1, 2], (_) => entregas++);
      janela.limpar();
      janela.adicionar([3], (_) => entregas++);
      expect(entregas, 1);
    });
  });

  group('PCM 16 bits', () {
    test('converte little-endian para −1..1', () {
      final bytes = Uint8List.fromList([0x00, 0x00, 0xFF, 0x7F, 0x00, 0x80]);
      expect(converterPcm16(bytes), [0, 32767 / 32768, -1]);
    });

    test('meia amostra no fim do bloco passa para o seguinte', () async {
      final origem = Stream.fromIterable([
        Uint8List.fromList([0x00, 0x40, 0x00]),
        Uint8List.fromList([0xC0]),
      ]);
      final blocos = await origem.transform(const ConversorPcm16()).toList();
      expect(blocos.expand((b) => b), [0.5, -0.5]);
    });
  });
}
