import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/audio/fonte_audio.dart';
import 'package:open_tuner/dominio/estado_corda.dart';
import 'package:open_tuner/features/afinador/desenhos.dart';
import 'package:open_tuner/features/afinador/folhas.dart';
import 'package:open_tuner/features/afinador/grafico.dart';

import '../apoio/abrir_app.dart';
import '../apoio/fontes.dart';
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

  bool linhaAfinadaAcesa(WidgetTester tester) =>
      tester
          .widget<AnimatedOpacity>(find.byKey(const Key('linha-afinada')))
          .opacity ==
      1;

  double progressoDoIndicador(WidgetTester tester) =>
      (tester
                  .widget<CustomPaint>(find.byKey(const Key('progresso')))
                  .foregroundPainter!
              as PintorProgresso)
          .progresso;

  bool vistoNoIndicador(WidgetTester tester) => find
      .descendant(
        of: find.byKey(const Key('indicador')),
        matching: find.byType(Visto),
      )
      .evaluate()
      .isNotEmpty;

  /// O número escrito no indicador; null sem número (✓ ou ociosa).
  int? numeroNoIndicador(WidgetTester tester) {
    final texto = find.byKey(const Key('cents'));
    if (texto.evaluate().isEmpty) return null;
    return int.parse(
      tester.widget<Text>(texto).data!.replaceAll('−', '-').replaceAll('+', ''),
    );
  }

  /// A instrução da pílula, se houver.
  String? instrucao(WidgetTester tester) {
    for (final texto in const ['Aperte a corda', 'Afrouxe a corda']) {
      if (find.text(texto).evaluate().isNotEmpty) return texto;
    }
    return null;
  }

  PintorRastro rastro(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byWidgetPredicate(
                  (w) =>
                      w is CustomPaint && w.foregroundPainter is PintorRastro,
                ),
              )
              .foregroundPainter!
          as PintorRastro;

  group('sem o ✓', () {
    testWidgets('número e instrução nunca discordam, e dentro da tolerância '
        'não há instrução', (tester) async {
      final app = await abrirApp(tester);
      // Tocada a +16 cents; a nota cai logo para uns 12% da energia, e a
      // tarraxa desce a 10 cents/s até −0,4 (afinada): o ✓ não entra, e o
      // ponteiro erra um pouco para os dois lados do zero.
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, 16);
      await esperar(tester, const Duration(milliseconds: 200));
      final problemas = <String>[];
      for (var i = 0; i < 100; i++) {
        final t = i * 0.04;
        app.fonte
          ..frequencia = FonteAudioFalsa.desviada(
            e4,
            math.max(-0.4, 16 - 10 * t),
          )
          ..amplitude = math.max(0.06, 0.5 * math.exp(-t / 0.15));
        await tester.pump(const Duration(milliseconds: 40));
        final numero = numeroNoIndicador(tester);
        final pilula = instrucao(tester);
        if (numero == null) continue;
        if ((numero.abs() <= 5 && pilula != null) ||
            (pilula == 'Aperte a corda' && numero >= 0) ||
            (pilula == 'Afrouxe a corda' && numero <= 0)) {
          problemas.add('${t.toStringAsFixed(2)} s: $numero "$pilula"');
        }
      }
      expect(problemas, isEmpty);
    });

    testWidgets('a corda afinada não recebe instrução antes do ✓', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = e4;
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(instrucao(tester), isNull, reason: '${40 * (i + 1)} ms');
      }
      expect(vistoNoIndicador(tester), isTrue);
    });

    for (final (de, para, errada, certa) in const [
      (1.0, -11.0, 'Afrouxe a corda', 'Aperte a corda'),
      (0.0, 11.0, 'Aperte a corda', 'Afrouxe a corda'),
    ]) {
      testWidgets('quando o ✓ apaga de uma vez ($de → $para), a instrução '
          'não sai do lado errado', (tester) async {
        final app = await abrirApp(tester);
        app.fonte.frequencia = FonteAudioFalsa.desviada(e4, de);
        await esperar(tester, const Duration(milliseconds: 1800));
        expect(vistoNoIndicador(tester), isTrue);
        app.fonte.frequencia = FonteAudioFalsa.desviada(e4, para);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          expect(instrucao(tester), isNot(errada), reason: '${40 * i} ms');
        }
        expect(instrucao(tester), certa);
      });
    }

    testWidgets('o anel só fica cheio com o ✓', (tester) async {
      // O anel anima até o valor da leitura: confere o valor de chegada e a
      // cor do fundo, que enche de verde com o anel fechado.
      double anelAlvo() => tester
          .widget<TweenAnimationBuilder<double>>(
            find
                .descendant(
                  of: find.byKey(const Key('indicador')),
                  matching: find.byType(TweenAnimationBuilder<double>),
                )
                .first,
          )
          .tween
          .end!;
      Color? fundo() =>
          (tester
                      .widget<AnimatedContainer>(
                        find.descendant(
                          of: find.byKey(const Key('indicador')),
                          matching: find.byType(AnimatedContainer),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color;
      final app = await abrirApp(tester);
      final fundoSemMarca = fundo();
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1800));
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(fundo(), isNot(fundoSemMarca));
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, 11);
      var semVisto = 0;
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        if (vistoNoIndicador(tester)) continue;
        semVisto++;
        expect(anelAlvo(), lessThan(1), reason: '${40 * i} ms');
        expect(fundo(), fundoSemMarca, reason: '${40 * i} ms');
      }
      expect(semVisto, greaterThan(10));
    });

    testWidgets('o rastro tem a cor e a posição do indicador', (tester) async {
      final app = await abrirApp(tester);
      final problemas = <String>[];
      for (final (cents, duracao) in const [
        (0.0, 1800),
        (7.0, 800),
        (11.0, 800),
        (0.0, 800),
      ]) {
        app.fonte.frequencia = FonteAudioFalsa.desviada(e4, cents);
        for (var t = 0; t < duracao; t += 40) {
          await tester.pump(const Duration(milliseconds: 40));
          final historico = rastro(tester).historico;
          if (historico.length == 0) continue;
          final ponto = historico[0];
          if (ponto == null) continue;
          final estado = historico.estado(0);
          if (vistoNoIndicador(tester)
              ? ponto != 0 || estado != EstadoCorda.afinada
              : estado == EstadoCorda.afinada) {
            problemas.add(
              '$cents, $t ms: ✓=${vistoNoIndicador(tester)} rastro em '
              '${ponto.toStringAsFixed(2)} $estado',
            );
          }
        }
      }
      expect(problemas, isEmpty);
    });

    testWidgets('o leitor de tela anuncia "Afinada" e não manda girar a '
        'corda afinada', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final app = await abrirApp(tester);
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(seconds: 4));
      expect(
        [for (final a in tester.takeAnnouncements()) a.message],
        ['Afinada'],
      );
      // A corda sai da nota logo depois de um anúncio: a mudança que cai
      // dentro do intervalo entre falas é dita quando ele acaba.
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, -14);
      await esperar(tester, const Duration(milliseconds: 400));
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 400));
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, 14);
      await esperar(tester, const Duration(seconds: 3));
      final ditos = [for (final a in tester.takeAnnouncements()) a.message];
      expect(ditos.last, 'Afrouxe a corda', reason: '$ditos');
    });
  });

  testWidgets('longe da nota, o anel de progresso não aparece', (tester) async {
    final app = await abrirApp(tester);
    app.fonte.frequencia = FonteAudioFalsa.desviada(e4, 30);
    await esperar(tester, const Duration(milliseconds: 600));
    expect(progressoDoIndicador(tester), 0);
  });

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
      expect(linhaAfinadaAcesa(tester), isFalse);
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

    testWidgets('afinada: ✓ no indicador e, pouco depois, selo e som', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = e4;
      // A primeira leitura espera a segunda confirmar (40 ms), e o ✓ pede o
      // ataque (0,15 s) e três leituras assentadas depois dele.
      await esperar(tester, const Duration(milliseconds: 400));

      expect(find.text('Afinada'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('indicador')),
          matching: find.byType(Visto),
        ),
        findsOneWidget,
      );
      // A linha verde acende e a nota alvo fica verde.
      expect(linhaAfinadaAcesa(tester), isTrue);
      final borda =
          (tester
                      .widget<AnimatedContainer>(
                        find.byKey(const Key('nota-alvo')),
                      )
                      .decoration!
                  as BoxDecoration)
              .border!
              .top
              .color;
      expect(borda, const Color(0xFF2A7353));
      expect(find.byKey(const Key('selo-2')), findsNothing);
      expect(app.vibracoes, 0);
      expect(app.tocador.avisosDeAfinada, 0);
      // O anel de progresso já começou a fechar, sem completar.
      final progresso = progressoDoIndicador(tester);
      expect(progresso, greaterThan(0));
      expect(progresso, lessThan(1));

      await esperar(tester, const Duration(milliseconds: 1100));

      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(app.vibracoes, 1);
      expect(app.tocador.avisosDeAfinada, 1);
      expect(progressoDoIndicador(tester), 1);
      expect(find.bySemanticsLabel('Corda E4, afinada'), findsOneWidget);

      // O silêncio devolve o indicador ao centro, e a marca fica.
      app.fonte.frequencia = null;
      await esperar(tester, const Duration(seconds: 2));
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
    });

    testWidgets('a corda que oscila em volta da nota também é marcada', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      // Como uma corda solta morrendo: entra e sai da tolerância a cada
      // 0,4 s, nunca 1 s seguido dentro dela.
      for (var i = 0; i < 4; i++) {
        app.fonte.frequencia = e4;
        await esperar(tester, const Duration(milliseconds: 400));
        app.fonte.frequencia = FonteAudioFalsa.desviada(e4, 12);
        await esperar(tester, const Duration(milliseconds: 400));
      }
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(app.tocador.avisosDeAfinada, 1);
    });

    testWidgets('corda parada com tremor: o número fica parado', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      // −12 cents, com a leitura tremendo ±3 a cada análise, como a corda
      // de verdade no microfone do celular.
      final numeros = <String>[];
      for (var i = 0; i < 75; i++) {
        app.fonte.frequencia = FonteAudioFalsa.desviada(
          e4,
          -12 + (i.isEven ? 3 : -3),
        );
        await tester.pump(const Duration(milliseconds: 40));
        final texto = find.byKey(const Key('cents'));
        if (i >= 25 && texto.evaluate().isNotEmpty) {
          numeros.add(tester.widget<Text>(texto).data!);
        }
      }
      expect(numeros, isNotEmpty);
      var trocas = 0;
      for (var i = 1; i < numeros.length; i++) {
        if (numeros[i] != numeros[i - 1]) trocas++;
      }
      // Em 2 s de corda parada, no máximo uma troca (o número assentando).
      expect(trocas, lessThanOrEqualTo(1), reason: '$numeros');
      expect(
        int.parse(numeros.last.replaceAll('−', '-')),
        inInclusiveRange(-14, -10),
      );
    });

    testWidgets('tocar de novo a corda já marcada: o anel recomeça e avisa', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(app.tocador.avisosDeAfinada, 1);
      expect(progressoDoIndicador(tester), 1);

      // A corda para e é tocada de novo, ainda afinada.
      app.fonte.frequencia = null;
      await esperar(tester, const Duration(milliseconds: 400));
      app.fonte.frequencia = e4;
      final progressos = <double>[];
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        progressos.add(progressoDoIndicador(tester));
      }
      // O anel recomeçou do zero, encheu de novo e o aviso tocou outra vez;
      // a marca embaixo continua.
      expect(progressos.where((p) => p > 0 && p < 1), isNotEmpty);
      expect(progressos.last, 1);
      expect(app.tocador.avisosDeAfinada, 2);
      expect(app.vibracoes, 2);
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
    });

    testWidgets('tocada de novo sem parar de soar: avisa de novo', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte
        ..frequencia = e4
        ..amplitude = 0.4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(app.tocador.avisosDeAfinada, 1);
      // A nota foi morrendo; a palhetada nova volta com força.
      app.fonte.amplitude = 0.1;
      await esperar(tester, const Duration(milliseconds: 600));
      app.fonte.amplitude = 0.5;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(app.tocador.avisosDeAfinada, 2);
    });

    testWidgets('tocada de novo logo depois do aviso: avisa de novo', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte
        ..frequencia = e4
        ..amplitude = 0.1;
      while (app.tocador.avisosDeAfinada == 0) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      // Palhetada forte assim que o período surdo do aviso acaba (antes de
      // 1 s): fica guardada e vale quando o intervalo passar.
      await esperar(tester, const Duration(milliseconds: 840));
      app.fonte.amplitude = 0.5;
      await esperar(tester, const Duration(milliseconds: 1600));
      expect(app.tocador.avisosDeAfinada, 2);
    });

    testWidgets('Recomeçar aparece com uma corda marcada e limpa as marcas', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      expect(find.byKey(const Key('recomecar')), findsNothing);

      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(find.byKey(const Key('recomecar')), findsOneWidget);
      expect(find.text('Recomeçar'), findsOneWidget);
      // Rótulo com o texto visível, a dica e a ação de toque (Voice Access,
      // Acesso com interruptor); pelo menos 48 dp de altura.
      expect(
        tester.getSemantics(find.byKey(const Key('recomecar'))),
        containsSemantics(
          label: 'Recomeçar',
          hint: 'Limpar as cordas afinadas',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getRect(find.byKey(const Key('recomecar'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('corda-0'))),
        containsSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('auto'))),
        containsSemantics(hasTapAction: true),
      );

      // O instrumento seguinte: as marcas somem, o botão também.
      app.fonte.frequencia = null;
      await esperar(tester, const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('recomecar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('selo-2')), findsNothing);
      expect(find.byKey(const Key('recomecar')), findsNothing);

      // E a corda afinada ganha a marca, o anel e o aviso de novo.
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(app.tocador.avisosDeAfinada, 2);
    });

    testWidgets('Recomeçar com a corda ainda soando não a marca de novo', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte
        ..frequencia = e4
        ..amplitude = 0.4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(app.tocador.avisosDeAfinada, 1);

      // A corda continua soando, afinada, quando o botão é tocado.
      app.fonte.amplitude = 0.2;
      await tester.tap(find.byKey(const Key('recomecar')));
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('selo-2')), findsNothing);
      expect(app.tocador.avisosDeAfinada, 1);
      expect(app.vibracoes, 1);

      // Uma palhetada nova, sim, conta.
      app.fonte.amplitude = 0.5;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(find.byKey(const Key('selo-2')), findsOneWidget);
      expect(app.tocador.avisosDeAfinada, 2);
    });

    testWidgets('a corda que sai da nota e volta avisa de novo', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(app.tocador.avisosDeAfinada, 1);

      // A tarraxa (ou a tensão das outras cordas) tira a corda da nota, com
      // ela soando, e depois ela volta.
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, -20);
      await esperar(tester, const Duration(milliseconds: 800));
      expect(find.text('Afinada'), findsNothing);
      expect(app.tocador.avisosDeAfinada, 1);
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1500));
      expect(app.tocador.avisosDeAfinada, 2);
    });

    testWidgets(
      'a nota afinada soando, com a energia oscilando, avisa uma vez',
      (tester) async {
        final app = await abrirApp(tester);
        app.fonte.frequencia = e4;
        // Batimento de 4 Hz na energia, ±40%, por 6 s: pode parecer palhetada,
        // mas é a mesma nota.
        for (var i = 0; i < 150; i++) {
          app.fonte.amplitude =
              0.3 * (1 + 0.4 * math.sin(2 * math.pi * 4 * i * 0.04));
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(app.tocador.avisosDeAfinada, 1);
      },
    );

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
      // E o som da corda, um G4.
      expect(app.tocador.cordas, hasLength(1));
      expect(app.tocador.cordas.single, closeTo(392.0, 0.01));

      // Enquanto a referência soa, o afinador não se escuta.
      app.fonte.frequencia = 392.0;
      await esperar(tester, const Duration(milliseconds: 1200));
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
      expect(find.byKey(const Key('selo-0')), findsNothing);

      // Com a corda G4 fixada, um E4 é medido contra G4: muito frouxo.
      app.fonte.frequencia = e4;
      await esperar(tester, const Duration(milliseconds: 1200));
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
      expect(find.text('VIOLÃO, GUITARRA E VIOLA'), findsOneWidget);
      expect(find.text('BAIXO'), findsOneWidget);

      await tester.tap(find.byKey(const Key('instrumento-violao')));
      await tester.pumpAndSettle();

      // Violão e guitarra elétrica: a mesma afinação.
      expect(find.text('Violão / Guitarra'), findsOneWidget);
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

    testWidgets('o idioma escolhido nos ajustes vale na hora e fica guardado', (
      tester,
    ) async {
      final app = await abrirApp(tester);
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('abrir-ajustes')));
      await tester.pumpAndSettle();
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Idioma do sistema'), findsOneWidget);

      // O seletor mostra todos os idiomas do app, cada um na própria língua.
      await tester.tap(find.byKey(const Key('idioma')));
      await tester.pumpAndSettle();
      for (final nome in ['Português (Brasil)', 'English', 'Español']) {
        expect(find.text(nome), findsWidgets);
      }
      await tester.tap(find.byKey(const Key('idioma-en')).last);
      await tester.pumpAndSettle();

      expect(app.preferencias.getString('idioma'), 'en');
      expect(find.text('Settings'), findsOneWidget);
      // Até o véu da folha, que o leitor de tela fala, troca de idioma.
      expect(
        ModalRoute.of(tester.element(find.byType(Folha)))!.barrierLabel,
        'Close',
      );
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Play any string to start'), findsOneWidget);

      // De volta ao idioma do aparelho (português, no teste).
      await tester.tap(find.byKey(const Key('idioma')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('idioma-sistema')).last);
      await tester.pumpAndSettle();
      expect(app.preferencias.getString('idioma'), isNull);
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
    });

    testWidgets('abre no idioma guardado', (tester) async {
      await abrirApp(tester, preferencias: {'idioma': 'es'});
      expect(find.text('Toca cualquier cuerda para empezar'), findsOneWidget);
    });

    testWidgets('um idioma guardado que o app não tem segue o aparelho', (
      tester,
    ) async {
      await abrirApp(tester, preferencias: {'idioma': 'fr'});
      expect(find.text('Toque qualquer corda para começar'), findsOneWidget);
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

    testWidgets('a folha aberta acompanha a troca de tema', (tester) async {
      await abrirApp(tester, preferencias: {'tema': 'claro'});
      await tester.tap(find.byKey(const Key('abrir-ajustes')));
      await tester.pumpAndSettle();

      Color fundoDaFolha() =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(Folha),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      Color veu() =>
          ModalRoute.of(tester.element(find.byType(Folha)))!.barrierColor!;

      expect(fundoDaFolha(), const Color(0xFFFFFBF5));
      final veuClaro = veu();

      await tester.tap(find.byKey(const Key('tema-escuro')));
      await tester.pumpAndSettle();

      expect(fundoDaFolha(), const Color(0xFF1E1915));
      expect(veu(), isNot(veuClaro));
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
    for (final escala in const [1.0, 1.3, 2.0]) {
      testWidgets('o nome "Violão / Guitarra" cabe inteiro na barra, sem '
          'desfazer o texto a ${(escala * 100).round()}%', (tester) async {
        await carregarFontesDoApp(tester);
        tester.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await abrirApp(
          tester,
          tela: const Size(360, 640),
          preferencias: {'instrumento': 'violao'},
        );
        final paragrafo = tester.renderObject<RenderParagraph>(
          find.text('Violão / Guitarra'),
        );
        // Inteiro (sem reticências) até 130%, como o projeto garante (a 200%,
        // numa tela de 360, nem "Guitarra" sozinha cabe em meia barra) e, no
        // máximo, 15% menor que o tamanho pedido: quando não cabe assim,
        // quebra em duas linhas, em vez de desfazer o texto grande.
        if (escala <= 1.3) expect(paragrafo.didExceedMaxLines, isFalse);
        final tamanho = paragrafo.textScaler.scale(
          (paragrafo.text as TextSpan).style!.fontSize!,
        );
        expect(tamanho, greaterThanOrEqualTo(16 * escala * 0.85 - 0.01));
      });
    }

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
