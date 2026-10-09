import 'nota.dart';

/// Uma corda (ou par de cordas) de uma afinação: a altura e como escrevê-la.
///
/// A altura fica sempre em [nota], com sustenido (E♭2 vira D#2 por dentro);
/// a grafia original fica em [letra], [acidente] e [oitava], para que a
/// afinação "Meio tom abaixo" apareça como E♭ A♭ D♭ e não como D♯ G♯ C♯.
class NotaAfinacao {
  NotaAfinacao._(
    this.nota,
    this.bemol,
    this.letra,
    this._sustenido,
    this.oitava,
  );

  /// Lê 'E2', 'F#3', 'Eb2' (letra A–G, acidente opcional '#' ou 'b', oitava
  /// 0–8). Aceita também '♯' e '♭'. Lança [FormatException] se não entender.
  factory NotaAfinacao.ler(String texto) {
    final partes = _formato.firstMatch(texto.trim());
    if (partes == null) {
      throw FormatException('nota de afinação inválida', texto);
    }
    final letra = partes.group(1)!;
    final sinal = partes.group(2)!;
    final oitava = int.parse(partes.group(3)!);
    final bemol = sinal == 'b' || sinal == '♭';
    final sustenido = sinal == '#' || sinal == '♯';
    final deslocamento = bemol ? -1 : (sustenido ? 1 : 0);
    final midi =
        (oitava + 1) * 12 + nomesDasNotas.indexOf(letra) + deslocamento;
    return NotaAfinacao._(Nota.dePitch(midi), bemol, letra, sustenido, oitava);
  }

  static final _formato = RegExp(r'^([A-G])([#b♯♭]?)([0-8])$');

  /// A altura, sempre com sustenido (Eb2 -> D#2).
  final Nota nota;

  /// true quando foi escrita com bemol.
  final bool bemol;

  /// A letra como é escrita: 'E' para Eb2, 'D' para D#2.
  final String letra;

  final bool _sustenido;

  /// A oitava como é escrita (a de 'Eb2' é 2).
  final int oitava;

  /// '', '♯' ou '♭'.
  String get acidente => bemol ? '♭' : (_sustenido ? '♯' : '');

  /// Letra e acidente, sem a oitava: 'E♭', 'F♯', 'A'.
  String get nome => '$letra$acidente';

  /// Frequência em Hz no temperamento igual, tomando [a4] como referência.
  double frequencia([double a4 = 440]) => nota.frequencia(a4);

  @override
  bool operator ==(Object outro) =>
      outro is NotaAfinacao &&
      outro.nota == nota &&
      outro.bemol == bemol &&
      outro.letra == letra;

  @override
  int get hashCode => Object.hash(nota, bemol, letra);

  @override
  String toString() => '$nome$oitava';
}

/// Uma afinação de um instrumento.
class Afinacao {
  const Afinacao({required this.id, required this.notas});

  /// Identificador estável (guardado nas preferências e usado nas chaves de
  /// texto): 'padrao', 'drop-d', 'cebolao-em-mi'...
  final String id;

  /// Ordem física: da corda de cima para a de baixo, não da mais grave para a
  /// mais aguda (o ukulele padrão é G4 C4 E4 A4).
  final List<NotaAfinacao> notas;

  @override
  String toString() => '$id (${notas.join(' ')})';
}

/// Os grupos da lista de instrumentos (RF-14).
enum GrupoInstrumento { ukuleleCavaquinho, violaoViola, baixo, arco }

/// Um instrumento e as afinações que o app oferece para ele.
class Instrumento {
  const Instrumento({
    required this.id,
    required this.grupo,
    this.pares = false,
    required this.afinacoes,
  });

  /// Identificador estável: 'ukulele', 'violao', 'baixo-5'...
  final String id;

  final GrupoInstrumento grupo;

  /// Viola caipira: cada "corda" é um par, e o detector aceita também a oitava
  /// de cima do par.
  final bool pares;

  /// A primeira é a padrão.
  final List<Afinacao> afinacoes;

  /// A afinação aplicada ao escolher o instrumento.
  Afinacao get padrao => afinacoes.first;

  /// Quantidade de cordas (ou de pares) da afinação padrão.
  int get cordas => padrao.notas.length;

  /// A afinação de id [id], ou a padrão se o id não existir.
  Afinacao afinacao(String id) =>
      afinacoes.firstWhere((a) => a.id == id, orElse: () => padrao);

  /// Menor frequência (A4 = 440) entre todas as afinações do instrumento.
  double get frequenciaMinima => afinacoes
      .expand((a) => a.notas)
      .map((n) => n.frequencia())
      .reduce((a, b) => a < b ? a : b);

  /// Maior frequência (A4 = 440) entre todas as afinações; nos pares, o
  /// dobro, por causa da oitava de cima do par.
  double get frequenciaMaxima {
    final maior = afinacoes
        .expand((a) => a.notas)
        .map((n) => n.frequencia())
        .reduce((a, b) => a > b ? a : b);
    return pares ? maior * 2 : maior;
  }

  @override
  String toString() => id;
}

Afinacao _afinacao(String id, String notas) => Afinacao(
  id: id,
  notas: notas.split(' ').map(NotaAfinacao.ler).toList(growable: false),
);

/// Os instrumentos, na ordem da tabela de docs/REQUISITOS.md.
/// Acrescentar uma afinação é acrescentar uma linha aqui.
final List<Instrumento> instrumentos = List.unmodifiable([
  Instrumento(
    id: 'ukulele',
    grupo: GrupoInstrumento.ukuleleCavaquinho,
    afinacoes: [
      _afinacao('padrao', 'G4 C4 E4 A4'),
      _afinacao('sol-grave', 'G3 C4 E4 A4'),
      _afinacao('em-re', 'A4 D4 F#4 B4'),
    ],
  ),
  Instrumento(
    id: 'ukulele-baritono',
    grupo: GrupoInstrumento.ukuleleCavaquinho,
    afinacoes: [_afinacao('padrao', 'D3 G3 B3 E4')],
  ),
  Instrumento(
    id: 'cavaquinho',
    grupo: GrupoInstrumento.ukuleleCavaquinho,
    afinacoes: [
      _afinacao('padrao', 'D4 G4 B4 D5'),
      _afinacao('natural', 'D4 G4 B4 E5'),
    ],
  ),
  Instrumento(
    id: 'violao',
    grupo: GrupoInstrumento.violaoViola,
    afinacoes: [
      _afinacao('padrao', 'E2 A2 D3 G3 B3 E4'),
      _afinacao('drop-d', 'D2 A2 D3 G3 B3 E4'),
      _afinacao('meio-tom-abaixo', 'Eb2 Ab2 Db3 Gb3 Bb3 Eb4'),
      _afinacao('um-tom-abaixo', 'D2 G2 C3 F3 A3 D4'),
      _afinacao('dadgad', 'D2 A2 D3 G3 A3 D4'),
      _afinacao('open-g', 'D2 G2 D3 G3 B3 D4'),
      _afinacao('open-d', 'D2 A2 D3 F#3 A3 D4'),
    ],
  ),
  Instrumento(
    id: 'violao-7',
    grupo: GrupoInstrumento.violaoViola,
    afinacoes: [
      _afinacao('setima-em-do', 'C2 E2 A2 D3 G3 B3 E4'),
      _afinacao('setima-em-si', 'B1 E2 A2 D3 G3 B3 E4'),
    ],
  ),
  Instrumento(
    id: 'viola-caipira',
    grupo: GrupoInstrumento.violaoViola,
    pares: true,
    afinacoes: [
      _afinacao('cebolao-em-mi', 'B2 E3 G#3 B3 E4'),
      _afinacao('cebolao-em-re', 'A2 D3 F#3 A3 D4'),
      _afinacao('rio-abaixo', 'G2 D3 G3 B3 D4'),
    ],
  ),
  Instrumento(
    id: 'baixo',
    grupo: GrupoInstrumento.baixo,
    afinacoes: [
      _afinacao('padrao', 'E1 A1 D2 G2'),
      _afinacao('drop-d', 'D1 A1 D2 G2'),
      _afinacao('meio-tom-abaixo', 'Eb1 Ab1 Db2 Gb2'),
    ],
  ),
  Instrumento(
    id: 'baixo-5',
    grupo: GrupoInstrumento.baixo,
    afinacoes: [
      _afinacao('padrao', 'B0 E1 A1 D2 G2'),
      _afinacao('com-do-agudo', 'E1 A1 D2 G2 C3'),
    ],
  ),
  Instrumento(
    id: 'baixo-6',
    grupo: GrupoInstrumento.baixo,
    afinacoes: [_afinacao('padrao', 'B0 E1 A1 D2 G2 C3')],
  ),
  Instrumento(
    id: 'violino',
    grupo: GrupoInstrumento.arco,
    afinacoes: [_afinacao('padrao', 'G3 D4 A4 E5')],
  ),
]);

/// O instrumento de id [id], ou o primeiro (ukulele) se o id não existir.
Instrumento instrumentoPorId(String id) => instrumentos.firstWhere(
  (i) => i.id == id,
  orElse: () => instrumentos.first,
);
