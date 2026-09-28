import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/audio/fonte_audio.dart';
import 'package:open_tuner/features/afinador/desenhos.dart';

import '../apoio/abrir_app.dart';
import '../apoio/fonte_audio_falsa.dart';

/// E4, a terceira corda do ukulele padrão (G4 C4 E4 A4).
const e4 = 329.6275569128699;

/// Leva o app para segundo plano e o traz de volta, passando pelos estados
/// intermediários como o sistema faz.
Future<void> irParaSegundoPlano(WidgetTester tester) async {
  for (final estado in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(estado);
  }
  await tester.pump();
}

Future<void> voltarAoPrimeiroPlano(WidgetTester tester) async {
  for (final estado in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(estado);
  }
  await tester.pump();
  await tester.pump();
}

void main() {
  double centroDoIndicador(WidgetTester tester) =>
      tester.getCenter(find.byKey(const Key('indicador'))).dx;

  double centroDaTela(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

  bool autoLigado(WidgetTester tester) => tester
      .widget<TrilhoChave>(
        find.descendant(
          of: find.byKey(const Key('auto')),
          matching: find.byType(TrilhoChave),
        ),
      )
      .ligada;

  group('indicador', () {
    testWidgets('abre esperando uma corda, com o indicador no centro', (
      tester,
    ) async {
      final app = await abrirApp(tester);

      expect(app.fonte.escutando, isTrue);
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
      expect(centroDoIndicador(tester), closeTo(centroDaTela(tester), 0.5));
      expect(find.byKey(const Key('cents')), findsNothing);
      expect(app.telaLigada.last, isTrue);
    });

    testWidgets('corda frouxa: "Aperte a corda" e o círculo à esquerda', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, -20);
      await esperar(tester, const Duration(milliseconds: 600));

      expect(find.text('Aperte a corda'), findsOneWidget);
      expect(find.text('Toque qualquer corda para começar'), findsNothing);
      expect(find.text('−20'), findsOneWidget);
      expect(centroDoIndicador(tester), lessThan(centroDaTela(tester) - 40));
      // A nota alvo e a frequência medida, com vírgula em português.
      expect(find.bySemanticsLabel('Nota alvo E4'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^325,[6-9] Hz$')), findsOneWidget);
    });

    testWidgets('em inglês, "Tighten the string" e ponto decimal', (
      tester,
    ) async {
      final app = await abrirApp(tester, idioma: const Locale('en', 'US'));
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, -20);
      await esperar(tester, const Duration(milliseconds: 600));

      expect(find.text('Tighten the string'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^325\.[6-9] Hz$')), findsOneWidget);
      expect(centroDoIndicador(tester), lessThan(centroDaTela(tester)));
    });

    testWidgets('corda apertada: "Afrouxe a corda" e o círculo à direita', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, 20);
      await esperar(tester, const Duration(milliseconds: 600));

      expect(find.text('Afrouxe a corda'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\+(19|20|21)$')), findsOneWidget);
      expect(centroDoIndicador(tester), greaterThan(centroDaTela(tester) + 40));
    });

    testWidgets('afinada: ✓ no indicador e, depois de 1 s, o selo na corda', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 300));

      expect(find.text('Afinada'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('indicador')),
          matching: find.byType(Visto),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('selo-2')), findsNothing);
      expect(app.vibracoes, 0);

      await esperar(tester, const Duration(milliseconds: 1100));

      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(app.vibracoes, 1);
      expect(find.bySemanticsLabel('Corda E4, afinada'), findsOneWidget);

      // O silêncio devolve o indicador ao centro, e a marca fica.
      app.fonte.frequencia = null;
      await esperar(tester, const Duration(seconds: 2));
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
    });

    testWidgets('as marcas somem ao trocar de afinação', (tester) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      app.fonte.frequencia = null;
      await esperar(tester, const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('botao-afinacao')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('afinacao-sol-grave')));
      await tester.pumpAndSettle();

      expect(find.text('Sol grave (Low G)'), findsOneWidget);
      expect(find.byKey(const Key('selo-2')), findsNothing);
    });
  });

  group('cordas e Auto', () {
    testWidgets('tocar numa corda fixa a corda e desliga o AUTO', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      expect(autoLigado(tester), isTrue);

      await tester.tap(find.byKey(const Key('corda-0')));
      await tester.pump();

      expect(autoLigado(tester), isFalse);
      expect(app.preferencias.getBool('auto'), isFalse);
      expect(app.preferencias.getInt('cordaFixada'), 0);

      // Com a corda G4 fixada, um E4 é medido contra G4: muito frouxo.
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 600));
      expect(find.text('Aperte a corda'), findsOneWidget);

      // Ligar o AUTO devolve a escolha ao detector.
      await tester.tap(find.byKey(const Key('auto')));
      await esperar(tester, const Duration(milliseconds: 600));
      expect(autoLigado(tester), isTrue);
      expect(find.text('Afinada'), findsOneWidget);
    });
  });

  group('folhas', () {
    testWidgets('escolher Violão mostra 6 cordas e a afinação padrão', (
      tester,
    ) async {
      final app = await abrirApp(tester);

      await tester.tap(find.byKey(const Key('botao-instrumento')));
      await tester.pumpAndSettle();
      expect(find.text('UKULELE E CAVAQUINHO'), findsOneWidget);
      expect(find.text('BAIXO'), findsOneWidget);

      await tester.tap(find.byKey(const Key('instrumento-violao')));
      await tester.pumpAndSettle();

      expect(find.text('Violão'), findsOneWidget);
      expect(find.text('6 cordas'), findsOneWidget);
      expect(find.text('Padrão'), findsOneWidget);
      expect(find.text('E A D G B E'), findsOneWidget);
      expect(find.byKey(const Key('corda-5')), findsOneWidget);
      expect(app.preferencias.getString('instrumento'), 'violao');
      expect(app.preferencias.getString('afinacao'), 'padrao');
    });

    testWidgets('meio tom abaixo aparece com bemóis', (tester) async {
      await abrirApp(tester, preferencias: {'instrumento': 'violao'});

      await tester.tap(find.byKey(const Key('botao-afinacao')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('afinacao-meio-tom-abaixo')));
      await tester.pumpAndSettle();

      expect(find.text('Meio tom abaixo'), findsOneWidget);
      expect(find.text('E♭ A♭ D♭ G♭ B♭ E♭'), findsOneWidget);
    });

    testWidgets('a viola caipira conta pares', (tester) async {
      await abrirApp(tester, preferencias: {'instrumento': 'viola-caipira'});

      expect(find.text('5 pares'), findsOneWidget);
      expect(find.bySemanticsLabel('Par B2'), findsOneWidget);
    });

    testWidgets('os ajustes trocam o tema e ficam guardados', (tester) async {
      final app = await abrirApp(tester);
      ThemeMode modo() =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
      expect(modo(), ThemeMode.system);

      await tester.tap(find.byKey(const Key('abrir-ajustes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tema-escuro')));
      await tester.pumpAndSettle();

      expect(modo(), ThemeMode.dark);
      expect(app.preferencias.getString('tema'), 'escuro');

      await tester.tap(find.byKey(const Key('tema-claro')));
      await tester.pumpAndSettle();
      expect(modo(), ThemeMode.light);
    });

    testWidgets('a referência do Lá vai de 430 a 450', (tester) async {
      final app = await abrirApp(tester, preferencias: {'a4': 449});

      await tester.tap(find.byKey(const Key('abrir-ajustes')));
      await tester.pumpAndSettle();
      expect(find.text('449 Hz'), findsOneWidget);

      await tester.tap(find.byKey(const Key('a4-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a4-1')));
      await tester.pump();
      expect(find.text('450 Hz'), findsOneWidget);
      expect(app.preferencias.getInt('a4'), 450);

      await tester.tap(find.byKey(const Key('a4--1')));
      await tester.pump();
      expect(find.text('449 Hz'), findsOneWidget);
    });

    testWidgets('desligar a tela ligada solta o wakelock', (tester) async {
      final app = await abrirApp(tester);
      expect(app.telaLigada.last, isTrue);

      await tester.tap(find.byKey(const Key('abrir-ajustes')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tela-ligada')));
      await tester.pump();

      expect(app.telaLigada.last, isFalse);
      expect(app.preferencias.getBool('telaLigada'), isFalse);
    });
  });

  group('permissão', () {
    testWidgets('primeira abertura explica e pede o microfone', (tester) async {
      final fonte = FonteAudioFalsa(permissao: EstadoPermissao.pendente);
      await abrirApp(tester, fonte: fonte);

      expect(
        find.text('O afinador precisa ouvir o instrumento'),
        findsOneWidget,
      );
      expect(fonte.escutando, isFalse);
      // O resto continua usável.
      expect(find.byKey(const Key('botao-instrumento')), findsOneWidget);

      await tester.ensureVisible(find.text('Permitir o microfone'));
      await tester.tap(find.text('Permitir o microfone'));
      await tester.pump();
      await tester.pump();

      expect(fonte.pedidos, 1);
      expect(fonte.escutando, isTrue);
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
    });

    testWidgets('negada de vez mostra o botão das configurações', (
      tester,
    ) async {
      final fonte = FonteAudioFalsa(permissao: EstadoPermissao.negadaDeVez);
      await abrirApp(tester, fonte: fonte);

      expect(
        find.textContaining('O acesso ao microfone está desligado'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Abrir configurações'));
      await tester.tap(find.text('Abrir configurações'));
      await tester.pump();
      expect(fonte.aberturasDeConfiguracoes, 1);

      // Volta das configurações com a permissão liberada.
      fonte.permissao = EstadoPermissao.concedida;
      await irParaSegundoPlano(tester);
      await voltarAoPrimeiroPlano(tester);

      expect(find.text('Abrir configurações'), findsNothing);
      expect(fonte.escutando, isTrue);
    });
  });

  group('ciclo de vida e memória', () {
    testWidgets('para de escutar em segundo plano e volta ao retornar', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      expect(app.fonte.escutando, isTrue);

      await irParaSegundoPlano(tester);
      expect(app.fonte.escutando, isFalse);
      expect(app.telaLigada.last, isFalse);

      await voltarAoPrimeiroPlano(tester);
      expect(app.fonte.escutando, isTrue);
      expect(app.telaLigada.last, isTrue);
    });

    testWidgets('restaura instrumento, afinação, Auto e ajustes', (
      tester,
    ) async {
      await abrirApp(
        tester,
        preferencias: {
          'instrumento': 'baixo',
          'afinacao': 'drop-d',
          'auto': false,
          'cordaFixada': 1,
          'tema': 'escuro',
          'notacao': 'solfejo',
        },
      );

      expect(find.text('Baixo'), findsOneWidget);
      expect(find.text('Drop D'), findsOneWidget);
      expect(find.text('Ré Lá Ré Sol'), findsOneWidget);
      expect(autoLigado(tester), isFalse);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        tester
            .widget<Semantics>(
              find
                  .descendant(
                    of: find.byKey(const Key('corda-1')),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .selected,
        isTrue,
      );
    });
  });

  group('telas de tamanhos diferentes', () {
    for (final tela in const [Size(360, 640), Size(430, 932), Size(360, 780)]) {
      testWidgets('cabe em ${tela.width.toInt()} × ${tela.height.toInt()} '
          'com texto a 130%', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final app = await abrirApp(
          tester,
          tela: tela,
          preferencias: {'instrumento': 'violao-7'},
        );
        app.fonte.frequencia = FonteAudioFalsa.desviada(82.41, -12);
        await esperar(tester, const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
        expect(find.text('Aperte a corda'), findsOneWidget);
        // Botões de corda com pelo menos 48 dp e sem se sobrepor.
        final retangulos = [
          for (var i = 0; i < 7; i++)
            tester.getRect(find.byKey(Key('corda-$i'))),
        ];
        for (final r in retangulos) {
          expect(r.width, greaterThanOrEqualTo(48));
        }
        for (var i = 0; i < 7; i++) {
          for (var j = i + 1; j < 7; j++) {
            expect(
              retangulos[i].overlaps(retangulos[j]),
              isFalse,
              reason: 'corda $i e corda $j',
            );
          }
        }
      });
    }
  });
}
