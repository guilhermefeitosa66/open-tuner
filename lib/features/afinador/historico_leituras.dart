import 'package:flutter/foundation.dart';

import '../../dominio/estado_corda.dart';

/// As últimas [capacidade] leituras em cents, a mais nova em `[0]`, cada uma
/// com o estado que o indicador mostrava nela (a cor do trecho do rastro).
/// Um null é uma leitura rejeitada (silêncio), que vira um vão no rastro.
///
/// Avisa quem escuta a cada leitura nova: é o que faz o rastro rolar, sem
/// reconstruir widget nenhum.
class HistoricoLeituras extends ChangeNotifier {
  HistoricoLeituras({this.capacidade = 80})
    : _valores = List<double?>.filled(capacidade, null),
      _estados = List<EstadoCorda?>.filled(capacidade, null);

  final int capacidade;
  final List<double?> _valores;
  final List<EstadoCorda?> _estados;

  /// Posição da leitura mais nova em [_valores].
  int _inicio = 0;
  int _quantidade = 0;

  /// Quantas leituras não nulas há: com zero, o rastro está vazio e um
  /// silêncio a mais não muda o desenho.
  int _naoNulas = 0;

  /// Quantas leituras há (no máximo [capacidade]).
  int get length => _quantidade;

  /// A leitura de [indice] passos atrás (0 é a mais nova).
  double? operator [](int indice) {
    RangeError.checkValidIndex(indice, this, 'indice', _quantidade);
    return _valores[(_inicio + indice) % capacidade];
  }

  /// O estado da leitura de [indice] passos atrás; null num vão ou quando
  /// ela veio sem estado.
  EstadoCorda? estado(int indice) {
    RangeError.checkValidIndex(indice, this, 'indice', _quantidade);
    return _estados[(_inicio + indice) % capacidade];
  }

  /// Todos os valores, do mais novo para o mais antigo.
  List<double?> get valores => [for (var i = 0; i < _quantidade; i++) this[i]];

  void adicionar(double? cents, {EstadoCorda? estado}) {
    _inicio = (_inicio - 1 + capacidade) % capacidade;
    if (_quantidade == capacidade && _valores[_inicio] != null) _naoNulas--;
    _valores[_inicio] = cents;
    _estados[_inicio] = cents == null ? null : estado;
    if (_quantidade < capacidade) _quantidade++;
    if (cents != null) _naoNulas++;
    // Silêncio sobre silêncio: nada a redesenhar.
    if (cents == null && _naoNulas == 0) return;
    notifyListeners();
  }

  void limpar() {
    if (_quantidade == 0) return;
    _quantidade = 0;
    _inicio = 0;
    _naoNulas = 0;
    notifyListeners();
  }
}
