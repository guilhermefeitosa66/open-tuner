import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'audio/fonte_audio.dart';
import 'dados/preferencias.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Só retrato na versão 1.0.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final preferencias = await Preferencias.carregar();
  runApp(
    AppOpenTuner(preferencias: preferencias, fonteAudio: FonteAudioMicrofone()),
  );
}
