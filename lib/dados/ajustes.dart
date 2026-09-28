import 'package:flutter/foundation.dart';

import '../dominio/estado_corda.dart';
import 'preferencias.dart';

/// Os ajustes da folha de ajustes (RF-17), lidos e gravados nas
/// [Preferencias]. Quem desenha o tema, os nomes das notas e o afinador
/// escuta este objeto.
class Ajustes extends ChangeNotifier {
  Ajustes(this._preferencias)
    : _tema = _preferencias.tema,
      _notacao = _preferencias.notacao,
      _precisao = _preferencias.precisao,
      _a4 = _preferencias.a4,
      _telaLigada = _preferencias.telaLigada;

  final Preferencias _preferencias;

  TemaEscolhido _tema;
  Notacao _notacao;
  Precisao _precisao;
  int _a4;
  bool _telaLigada;

  TemaEscolhido get tema => _tema;
  set tema(TemaEscolhido valor) {
    if (valor == _tema) return;
    _tema = valor;
    _preferencias.tema = valor;
    notifyListeners();
  }

  Notacao get notacao => _notacao;
  set notacao(Notacao valor) {
    if (valor == _notacao) return;
    _notacao = valor;
    _preferencias.notacao = valor;
    notifyListeners();
  }

  Precisao get precisao => _precisao;
  set precisao(Precisao valor) {
    if (valor == _precisao) return;
    _precisao = valor;
    _preferencias.precisao = valor;
    notifyListeners();
  }

  /// Referência do Lá, em Hz inteiros.
  int get a4 => _a4;
  set a4(int valor) {
    final limitado = valor.clamp(a4Minimo, a4Maximo).toInt();
    if (limitado == _a4) return;
    _a4 = limitado;
    _preferencias.a4 = limitado;
    notifyListeners();
  }

  bool get telaLigada => _telaLigada;
  set telaLigada(bool valor) {
    if (valor == _telaLigada) return;
    _telaLigada = valor;
    _preferencias.telaLigada = valor;
    notifyListeners();
  }
}
