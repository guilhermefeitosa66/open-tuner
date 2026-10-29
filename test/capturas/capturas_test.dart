@Tags(['capturas'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/abrir_app.dart';
import '../apoio/fonte_audio_falsa.dart';
import '../apoio/fontes.dart';

/// Capturas da App Store, com o áudio da fonte falsa no lugar do microfone.
///
/// Não é teste de regressão: gera as imagens da ficha da loja. Fica fora da
/// rodada normal (ver `dart_test.yaml`) e se gera com
///
///     flutter test --run-skipped --tags capturas --update-goldens
///
/// As imagens saem em `docs/loja/capturas/`, uma série por idioma da ficha,
/// em 1206 × 2622: o iPhone de 6,3 polegadas que a App Store pede.
void main() {
  const destino = '../../docs/loja/capturas';
  const tela = Size(402, 874);

  const e4 = 329.63;
  const a4 = 440.0;
  const b4 = 493.88;

  const idiomas = {
    'en': Locale('en', 'US'),
    'pt': Locale('pt', 'BR'),
    'es': Locale('es', 'MX'),
  };

  // Além das fontes do app, os ícones do Material, que no aparelho vêm do
  // Flutter. No aparelho, o ♭ e o ♯ que a Fraunces e a Manrope não têm vêm
  // da fonte do sistema; o flutter_test não procura glifo em outra fonte,
  // então FONTES_COM_ACIDENTES pode apontar para uma pasta com cópias das
  // duas que já trazem os sinais. Sem ela, eles saem como quadrados.
  Future<void> carregarFontes(WidgetTester tester) async {
    final acidentes = Platform.environment['FONTES_COM_ACIDENTES'];
    if (acidentes == null) await carregarFontesDoApp(tester);
    await tester.runAsync(() async {
      Future<void> carregar(String familia, List<String> arquivos) async {
        final carregador = FontLoader(familia);
        for (final arquivo in arquivos) {
          final bytes = await File(arquivo).readAsBytes();
          carregador.addFont(Future.value(ByteData.sublistView(bytes)));
        }
        await carregador.load();
      }

      if (acidentes != null) {
        await carregar('Manrope', [
          for (final peso in [
            'Regular',
            'Medium',
            'SemiBold',
            'Bold',
            'ExtraBold',
          ])
            '$acidentes/Manrope-$peso.ttf',
        ]);
        await carregar('Fraunces', [
          for (final peso in ['Medium', 'SemiBold', 'Bold'])
            '$acidentes/Fraunces-$peso.ttf',
        ]);
      }
      final flutter = Platform.environment['FLUTTER_ROOT']!;
      await carregar('MaterialIcons', [
        '$flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
  }

  Future<void> capturar(WidgetTester tester, String nome) async {
    // O flutter_test troca sombras por um contorno preto; a captura precisa
    // da sombra. Volta ao padrão antes do fim do teste, quando o flutter_test
    // confere essa variável.
    debugDisableShadows = false;
    try {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$destino/$nome.png'),
      );
    } finally {
      debugDisableShadows = true;
    }
  }

  for (final MapEntry(key: sigla, value: idioma) in idiomas.entries) {
    testWidgets('$sigla: corda frouxa no violão', (tester) async {
      await carregarFontes(tester);
      final app = await abrirApp(
        tester,
        idioma: idioma,
        tela: tela,
        preferencias: {'instrumento': 'violao', 'tema': 'claro'},
      );
      app.fonte.frequencia = FonteAudioFalsa.desviada(e4, -18);
      await esperar(tester, const Duration(milliseconds: 1500));
      await capturar(tester, '$sigla-1-frouxa');
    });

    testWidgets('$sigla: afinada no ukulele', (tester) async {
      await carregarFontes(tester);
      final app = await abrirApp(
        tester,
        idioma: idioma,
        tela: tela,
        preferencias: {'instrumento': 'ukulele', 'tema': 'claro'},
      );
      app.fonte.frequencia = a4;
      await esperar(tester, const Duration(milliseconds: 2500));
      await capturar(tester, '$sigla-2-afinada');
    });

    testWidgets('$sigla: escolha do instrumento', (tester) async {
      await carregarFontes(tester);
      await abrirApp(
        tester,
        idioma: idioma,
        tela: tela,
        preferencias: {'tema': 'claro'},
      );
      await tester.tap(find.byKey(const Key('botao-instrumento')));
      await tester.pumpAndSettle();
      await capturar(tester, '$sigla-3-instrumentos');
    });

    testWidgets('$sigla: tema escuro, corda apertada', (tester) async {
      await carregarFontes(tester);
      final app = await abrirApp(
        tester,
        idioma: idioma,
        tela: tela,
        preferencias: {'instrumento': 'cavaquinho', 'tema': 'escuro'},
      );
      app.fonte.frequencia = FonteAudioFalsa.desviada(b4, 14);
      await esperar(tester, const Duration(milliseconds: 1500));
      await capturar(tester, '$sigla-4-escuro');
    });
  }
}
