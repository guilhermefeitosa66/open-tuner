import 'package:flutter/material.dart';

import '../features/afinador/tela_afinador.dart';
import 'tema.dart';

/// Raiz do aplicativo. O tema acompanha o do sistema: claro de dia, escuro à
/// noite, sem opção própria por enquanto.
class AppOpenTuner extends StatelessWidget {
  const AppOpenTuner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Tuner',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: temaClaro,
      darkTheme: temaEscuro,
      home: const TelaAfinador(),
    );
  }
}
