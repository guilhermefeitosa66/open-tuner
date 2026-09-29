import 'package:flutter/material.dart';

import '../audio/fonte_audio.dart';
import '../audio/tocador.dart';
import '../dados/ajustes.dart';
import '../dados/preferencias.dart';
import '../features/afinador/controlador_afinador.dart';
import '../features/afinador/tela_afinador.dart';
import '../l10n/textos.dart';
import 'idioma.dart';
import 'tema.dart';

/// Versão mostrada nos ajustes. Acompanha o `version` do pubspec.
const versaoApp = '0.1.0';

/// Raiz do aplicativo. O tema segue o ajuste (Sistema, Claro ou Escuro). O
/// idioma é o escolhido nos ajustes ou, por padrão, o do aparelho, com inglês
/// quando nenhum dos preferidos é suportado.
class AppOpenTuner extends StatefulWidget {
  const AppOpenTuner({
    super.key,
    required this.preferencias,
    required this.fonteAudio,
    this.definirTelaLigada,
    this.vibrar,
    this.tocador,
  });

  final Preferencias preferencias;
  final FonteAudio fonteAudio;

  /// Troca o "manter a tela ligada"; os testes passam um que não faz nada.
  final DefinirTelaLigada? definirTelaLigada;

  /// A vibração curta da corda afinada; idem.
  final Future<void> Function()? vibrar;

  /// Os sons (corda de referência e aviso de afinada); idem.
  final Tocador? tocador;

  @override
  State<AppOpenTuner> createState() => _AppOpenTunerState();
}

class _AppOpenTunerState extends State<AppOpenTuner> {
  late final Ajustes _ajustes = Ajustes(widget.preferencias);

  @override
  void dispose() {
    _ajustes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ajustes,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (contexto) => Textos.of(contexto).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: Textos.localizationsDelegates,
        supportedLocales: idiomasSuportados,
        localeListResolutionCallback: resolverIdioma,
        // Escolhido nos ajustes; null segue os idiomas do aparelho.
        locale: switch (_ajustes.idioma) {
          final codigo? => Locale(codigo),
          null => null,
        },
        themeMode: switch (_ajustes.tema) {
          TemaEscolhido.sistema => ThemeMode.system,
          TemaEscolhido.claro => ThemeMode.light,
          TemaEscolhido.escuro => ThemeMode.dark,
        },
        theme: temaClaro,
        darkTheme: temaEscuro,
        home: TelaAfinador(
          fonte: widget.fonteAudio,
          preferencias: widget.preferencias,
          ajustes: _ajustes,
          versao: versaoApp,
          definirTelaLigada: widget.definirTelaLigada,
          vibrar: widget.vibrar,
          tocador: widget.tocador,
        ),
      ),
    );
  }
}
