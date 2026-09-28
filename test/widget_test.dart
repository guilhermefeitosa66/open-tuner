import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoio/abrir_app.dart';

void main() {
  // O app segue o idioma do aparelho; aqui o aparelho é simulado.

  testWidgets('abre na tela do afinador em inglês', (tester) async {
    await abrirApp(tester, idioma: const Locale('en', 'US'));

    expect(find.text('Play any string to start'), findsOneWidget);
    expect(find.text('INSTRUMENT'), findsOneWidget);
    expect(find.text('Ukulele'), findsOneWidget);
    expect(find.text('4 strings'), findsOneWidget);
  });

  testWidgets('abre na tela do afinador em português', (tester) async {
    await abrirApp(tester);

    expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
    expect(find.text('AFINAÇÃO'), findsOneWidget);
    expect(find.text('Ukulele'), findsOneWidget);
    expect(find.text('4 cordas'), findsOneWidget);
    expect(find.text('Padrão'), findsOneWidget);
    expect(find.text('G C E A'), findsOneWidget);
  });

  testWidgets('abre na tela do afinador em espanhol', (tester) async {
    await abrirApp(tester, idioma: const Locale('es', 'MX'));

    expect(find.text('Toca cualquier cuerda para empezar'), findsOneWidget);
    expect(find.text('Ukelele'), findsOneWidget);
    expect(find.text('4 cuerdas'), findsOneWidget);
  });

  testWidgets('idioma não suportado cai no inglês', (tester) async {
    await abrirApp(tester, idioma: const Locale('fr', 'FR'));

    expect(find.text('Play any string to start'), findsOneWidget);
  });

  testWidgets('o título é a palavra OpenTuner', (tester) async {
    await abrirApp(tester);

    expect(find.text('OpenTuner', findRichText: true), findsOneWidget);
  });
}
