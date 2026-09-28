import 'package:flutter/material.dart';

import '../features/afinador/tela_afinador.dart';
import '../l10n/textos.dart';
import 'idioma.dart';
import 'tema.dart';

/// Raiz do aplicativo. O tema acompanha o do sistema: claro de dia, escuro à
/// noite, sem opção própria por enquanto. O idioma segue o do aparelho, com
/// inglês quando nenhum dos preferidos é suportado.
class AppOpenTuner extends StatelessWidget {
  const AppOpenTuner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (contexto) => Textos.of(contexto).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: Textos.localizationsDelegates,
      supportedLocales: idiomasSuportados,
      localeListResolutionCallback: resolverIdioma,
      themeMode: ThemeMode.system,
      theme: temaClaro,
      darkTheme: temaEscuro,
      home: const TelaAfinador(),
    );
  }
}
