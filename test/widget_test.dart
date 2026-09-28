import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/app/app.dart';

void main() {
  // O app segue o idioma do aparelho; aqui o aparelho é simulado.
  Future<void> abrirCom(WidgetTester tester, List<Locale> idiomas) async {
    tester.platformDispatcher.localesTestValue = idiomas;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const AppOpenTuner());
    await tester.pumpAndSettle();
  }

  testWidgets('abre na tela do afinador em inglês', (tester) async {
    await abrirCom(tester, const [Locale('en', 'US')]);

    expect(find.text('Play any string to start'), findsOneWidget);
    expect(find.text('Instrument'), findsOneWidget);
    expect(find.text('Ukulele · 4 strings'), findsOneWidget);
  });

  testWidgets('abre na tela do afinador em português', (tester) async {
    await abrirCom(tester, const [Locale('pt', 'BR')]);

    expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
    expect(find.text('Afinação'), findsOneWidget);
    expect(find.text('Ukulele · 4 cordas'), findsOneWidget);
    expect(find.text('Padrão · G C E A'), findsOneWidget);
  });

  testWidgets('abre na tela do afinador em espanhol', (tester) async {
    await abrirCom(tester, const [Locale('es', 'MX')]);

    expect(find.text('Toca cualquier cuerda para empezar'), findsOneWidget);
    expect(find.text('Ukelele · 4 cuerdas'), findsOneWidget);
  });

  testWidgets('idioma não suportado cai no inglês', (tester) async {
    await abrirCom(tester, const [Locale('fr', 'FR')]);

    expect(find.text('Play any string to start'), findsOneWidget);
  });

  testWidgets('o título é a palavra OpenTuner', (tester) async {
    await abrirCom(tester, const [Locale('pt', 'BR')]);

    expect(find.text('OpenTuner', findRichText: true), findsOneWidget);
  });
}
