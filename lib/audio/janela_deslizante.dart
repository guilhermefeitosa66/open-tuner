import 'dart:typed_data';

/// Guarda as últimas [tamanho] amostras e avisa a cada [salto] amostras novas,
/// entregando a janela inteira, da mais antiga para a mais nova.
///
/// Com janela de 2.048 e salto de 1.764 a 44,1 kHz, são 25 análises por
/// segundo, cada uma olhando os últimos 46 ms de som.
class JanelaDeslizante {
  JanelaDeslizante({required this.tamanho, required this.salto})
    : assert(tamanho > 0 && salto > 0),
      _anel = Float64List(tamanho),
      _janela = Float64List(tamanho);

  final int tamanho;
  final int salto;

  final Float64List _anel;

  /// Reaproveitada a cada entrega: quem recebe não deve guardá-la.
  final Float64List _janela;
  int _posicao = 0;
  int _preenchidas = 0;
  int _desdeUltima = 0;

  /// Acrescenta [amostras] e chama [aoCompletar] a cada salto, com a janela
  /// cheia. Antes de juntar [tamanho] amostras não entrega nada.
  void adicionar(
    List<double> amostras,
    void Function(Float64List) aoCompletar,
  ) {
    for (final amostra in amostras) {
      _anel[_posicao] = amostra;
      _posicao = (_posicao + 1) % tamanho;
      if (_preenchidas < tamanho) _preenchidas++;
      _desdeUltima++;
      if (_desdeUltima >= salto && _preenchidas == tamanho) {
        _desdeUltima = 0;
        // A mais antiga está em _posicao.
        final antigas = tamanho - _posicao;
        _janela.setRange(0, antigas, _anel, _posicao);
        _janela.setRange(antigas, tamanho, _anel);
        aoCompletar(_janela);
      }
    }
  }

  /// Esquece o que ouviu.
  void limpar() {
    _posicao = 0;
    _preenchidas = 0;
    _desdeUltima = 0;
  }
}
