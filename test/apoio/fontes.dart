import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carrega as fontes empacotadas do app (Manrope e Fraunces). Sem isto, o
/// teste desenha tudo com a Ahem, em que cada letra é um quadrado: bom para
/// comparar posições, ruim para medir se um texto cabe.
Future<void> carregarFontesDoApp(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final (familia, pesos) in const [
      ('Manrope', ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']),
      ('Fraunces', ['Medium', 'SemiBold', 'Bold']),
    ]) {
      final carregador = FontLoader(familia);
      for (final peso in pesos) {
        carregador.addFont(rootBundle.load('assets/fontes/$familia-$peso.ttf'));
      }
      await carregador.load();
    }
  });
}
