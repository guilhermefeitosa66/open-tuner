/// Decide quando uma corda ganha a marca de afinada (RF-09).
///
/// A corda solta não fica parada na nota: o ataque sai um pouco agudo e, ao
/// morrer, ela desafina e oscila em volta da tolerância. Exigir um segundo
/// seguido dentro dela reprova a corda que está afinada. Por isso o marcador
/// soma o tempo dentro da tolerância numa janela recente: basta [necessario]
/// segundos afinados, mesmo com idas e vindas, dentro dos últimos [janela]
/// segundos. O [progresso] é o que a tela mostra enchendo o indicador.
class MarcadorAfinada {
  MarcadorAfinada({this.necessario = 1.0, this.janela = 2.5})
    : assert(necessario > 0 && necessario <= janela, 'tempos inválidos');

  /// Tempo somado dentro da tolerância para marcar, em segundos.
  final double necessario;

  /// Até quanto tempo para trás uma leitura afinada ainda conta.
  final double janela;

  /// Início e duração de cada leitura afinada ainda dentro da janela.
  final List<(double, double)> _dentro = [];

  double _soma = 0;

  /// Quanto falta para marcar, de 0 (nada) a 1 (marca).
  double get progresso => (_soma / necessario).clamp(0.0, 1.0);

  /// Registra uma leitura no instante [tempo] (em segundos), que cobre
  /// [duracao] segundos de som, e diz se a corda já conta como afinada.
  bool adicionar({
    required double tempo,
    required double duracao,
    required bool afinada,
  }) {
    if (afinada) _dentro.add((tempo, duracao));
    _dentro.removeWhere((leitura) => leitura.$1 <= tempo - janela);
    var soma = 0.0;
    for (final leitura in _dentro) {
      soma += leitura.$2;
    }
    _soma = soma;
    return soma >= necessario - 1e-9;
  }

  /// Esquece tudo (corda nova, afinação nova).
  void reiniciar() {
    _dentro.clear();
    _soma = 0;
  }
}
