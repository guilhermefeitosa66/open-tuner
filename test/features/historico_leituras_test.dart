import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/features/afinador/historico_leituras.dart';

void main() {
  test('guarda as últimas leituras, a mais nova primeiro', () {
    final historico = HistoricoLeituras(capacidade: 3);
    historico
      ..adicionar(1)
      ..adicionar(null)
      ..adicionar(3)
      ..adicionar(4);
    expect(historico.valores, [4, 3, null]);
  });

  test('silêncio sobre silêncio não pede redesenho', () {
    final historico = HistoricoLeituras(capacidade: 2);
    var avisos = 0;
    historico.addListener(() => avisos++);
    historico
      ..adicionar(null)
      ..adicionar(null);
    expect(avisos, 0);
    historico.adicionar(5);
    expect(avisos, 1);
    // O 5 ainda está à vista: o silêncio seguinte muda o desenho.
    historico.adicionar(null);
    expect(avisos, 2);
    // Agora o 5 saiu: só silêncio.
    historico.adicionar(null);
    expect(avisos, 2);
  });

  test('limpar esvazia', () {
    final historico = HistoricoLeituras()..adicionar(1);
    historico.limpar();
    expect(historico.length, 0);
  });
}
