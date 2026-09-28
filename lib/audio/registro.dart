import 'package:flutter/foundation.dart';

/// Mensagem de diagnóstico, só em modo debug: o app de release não escreve
/// nada no log.
void registrar(String mensagem) {
  if (kDebugMode) debugPrint('OpenTuner: $mensagem');
}
