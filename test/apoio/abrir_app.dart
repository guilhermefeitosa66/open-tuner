import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/app/app.dart';
import 'package:open_tuner/audio/tocador.dart';
import 'package:open_tuner/dados/preferencias.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fonte_audio_falsa.dart';

/// O app aberto num teste, com o que dá para inspecionar por fora.
class AppAberto {
  AppAberto(this.fonte, this.preferencias);

  final FonteAudioFalsa fonte;
  final SharedPreferences preferencias;
  int vibracoes = 0;
  final List<bool> telaLigada = [];
  final TocadorFalso tocador = TocadorFalso();
}

/// Anota o que o app mandou tocar, sem som nenhum.
class TocadorFalso implements Tocador {
  /// Frequências das cordas tocadas, na ordem.
  final List<double> cordas = [];
  int avisosDeAfinada = 0;

  @override
  Duration tocarCorda(double frequencia) {
    cordas.add(frequencia);
    return const Duration(milliseconds: 1600);
  }

  @override
  Duration tocarAfinada() {
    avisosDeAfinada++;
    return const Duration(milliseconds: 550);
  }

  @override
  void descartar() {}
}

/// Abre o OpenTuner num aparelho simulado de 390 × 844, no [idioma] dado,
/// com as [preferencias] já gravadas e a [fonte] de áudio falsa.
Future<AppAberto> abrirApp(
  WidgetTester tester, {
  Locale idioma = const Locale('pt', 'BR'),
  Map<String, Object> preferencias = const {},
  FonteAudioFalsa? fonte,
  Size tela = const Size(390, 844),
}) async {
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = tela * 3
    ..padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [idioma];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  // Num aparelho, o app abre em primeiro plano; no teste o estado começa
  // indefinido.
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

  SharedPreferences.setMockInitialValues(preferencias);
  final disco = await SharedPreferences.getInstance();
  final prefs = await Preferencias.carregar();
  final aberto = AppAberto(fonte ?? FonteAudioFalsa(), disco);

  await tester.pumpWidget(
    AppOpenTuner(
      preferencias: prefs,
      fonteAudio: aberto.fonte,
      definirTelaLigada: (ligada) async => aberto.telaLigada.add(ligada),
      vibrar: () async => aberto.vibracoes++,
      tocador: aberto.tocador,
    ),
  );
  // Localizações, permissão e início da escuta.
  await tester.pump();
  await tester.pump();
  return aberto;
}

/// Deixa o tempo (falso) correr em passos de 40 ms, o ritmo dos blocos de
/// áudio da fonte falsa.
Future<void> esperar(WidgetTester tester, Duration duracao) async {
  const passo = Duration(milliseconds: 40);
  var passado = Duration.zero;
  while (passado < duracao) {
    await tester.pump(passo);
    passado += passo;
  }
}
