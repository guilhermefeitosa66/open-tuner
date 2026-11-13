import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/features/sobre/tela_sobre.dart';

import '../apoio/abrir_app.dart';

void main() {
  testWidgets('os ajustes abrem a tela Sobre, com a versão', (tester) async {
    await abrirApp(tester);

    await tester.tap(find.byKey(const Key('abrir-ajustes')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('abrir-sobre')));
    await tester.tap(find.byKey(const Key('abrir-sobre')));
    await tester.pumpAndSettle();

    expect(find.byType(TelaSobre), findsOneWidget);
    expect(find.text('Sobre o OpenTuner'), findsWidgets);
    expect(find.byKey(const Key('sobre-versao')), findsOneWidget);
    for (final chave in [
      'sobre-site',
      'sobre-fundacao',
      'sobre-codigo',
      'sobre-privacidade',
      'sobre-termos',
      'sobre-licencas',
    ]) {
      expect(find.byKey(Key(chave)), findsOneWidget, reason: chave);
    }
  });

  for (final (idioma, site, privacidade, termos, titulo) in [
    (
      const Locale('pt', 'BR'),
      'https://opentuner.libre-apps.org/pt/',
      'https://opentuner.libre-apps.org/pt/privacy/',
      'https://opentuner.libre-apps.org/pt/terms/',
      'Sobre o OpenTuner',
    ),
    (
      const Locale('en', 'US'),
      'https://opentuner.libre-apps.org/',
      'https://opentuner.libre-apps.org/privacy/',
      'https://opentuner.libre-apps.org/terms/',
      'About OpenTuner',
    ),
    (
      const Locale('es', 'MX'),
      'https://opentuner.libre-apps.org/es/',
      'https://opentuner.libre-apps.org/es/privacy/',
      'https://opentuner.libre-apps.org/es/terms/',
      'Acerca de OpenTuner',
    ),
  ]) {
    testWidgets('os links abrem no idioma do app (${idioma.languageCode})', (
      tester,
    ) async {
      final abertos = <String>[];
      await abrirApp(tester, idioma: idioma);
      final contexto = tester.element(find.byKey(const Key('abrir-ajustes')));
      unawaited(
        Navigator.of(contexto).push(
          MaterialPageRoute<void>(
            builder: (_) => TelaSobre(
              versao: '9.9.9',
              abrir: (endereco) async => abertos.add(endereco.toString()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(titulo), findsOneWidget);
      expect(find.textContaining('9.9.9'), findsOneWidget);

      for (final chave in [
        'sobre-site',
        'sobre-fundacao',
        'sobre-codigo',
        'sobre-privacidade',
        'sobre-termos',
      ]) {
        await tester.ensureVisible(find.byKey(Key(chave)));
        await tester.tap(find.byKey(Key(chave)));
        await tester.pump();
      }
      expect(abertos, [
        site,
        'https://libre-apps.org/',
        'https://github.com/guilhermefeitosa66/open-tuner',
        privacidade,
        termos,
      ]);
    });
  }

  testWidgets('as licenças abrem a página de licenças', (tester) async {
    await abrirApp(tester);
    final contexto = tester.element(find.byKey(const Key('abrir-ajustes')));
    unawaited(
      Navigator.of(contexto).push(
        MaterialPageRoute<void>(builder: (_) => const TelaSobre(versao: '1.0')),
      ),
    );
    await tester.pumpAndSettle();

    // Numa tela pequena a lista rola até as licenças.
    await tester.drag(
      find.descendant(
        of: find.byType(TelaSobre),
        matching: find.byType(ListView),
      ),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sobre-licencas')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
