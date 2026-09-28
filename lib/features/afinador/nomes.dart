import '../../dados/preferencias.dart';
import '../../dominio/afinacoes.dart';
import '../../l10n/textos.dart';

// O domínio só conhece ids. Aqui cada id vira o nome no idioma do aparelho.

String nomeInstrumento(Textos textos, String id) => switch (id) {
  'ukulele' => textos.instrumentoUkulele,
  'ukulele-baritono' => textos.instrumentoUkuleleBaritono,
  'cavaquinho' => textos.instrumentoCavaquinho,
  'violao' => textos.instrumentoViolao,
  'violao-7' => textos.instrumentoViolao7,
  'viola-caipira' => textos.instrumentoViolaCaipira,
  'baixo' => textos.instrumentoBaixo,
  'baixo-5' => textos.instrumentoBaixo5,
  'baixo-6' => textos.instrumentoBaixo6,
  _ => id,
};

String nomeGrupo(Textos textos, GrupoInstrumento grupo) => switch (grupo) {
  GrupoInstrumento.ukuleleCavaquinho => textos.grupoUkuleleCavaquinho,
  GrupoInstrumento.violaoViola => textos.grupoViolaoViola,
  GrupoInstrumento.baixo => textos.grupoBaixo,
};

String nomeAfinacao(Textos textos, String id) => switch (id) {
  'padrao' => textos.afinacaoPadrao,
  'sol-grave' => textos.afinacaoSolGrave,
  'em-re' => textos.afinacaoEmRe,
  'natural' => textos.afinacaoNatural,
  'drop-d' => textos.afinacaoDropD,
  'meio-tom-abaixo' => textos.afinacaoMeioTomAbaixo,
  'um-tom-abaixo' => textos.afinacaoUmTomAbaixo,
  'dadgad' => textos.afinacaoDadgad,
  'open-g' => textos.afinacaoOpenG,
  'open-d' => textos.afinacaoOpenD,
  'setima-em-do' => textos.afinacaoSetimaEmDo,
  'setima-em-si' => textos.afinacaoSetimaEmSi,
  'cebolao-em-mi' => textos.afinacaoCebolaoEmMi,
  'cebolao-em-re' => textos.afinacaoCebolaoEmRe,
  'rio-abaixo' => textos.afinacaoRioAbaixo,
  'com-do-agudo' => textos.afinacaoComDoAgudo,
  _ => id,
};

/// "3 cordas" ou, na viola, "5 pares".
String quantidadeDeCordas(Textos textos, Instrumento instrumento) =>
    instrumento.pares
    ? textos.quantidadePares(instrumento.cordas)
    : textos.quantidadeCordas(instrumento.cordas);

/// Nome da nota sem a oitava, com o acidente como está escrito na afinação
/// (E♭, e não D♯): "E♭", ou "Mi♭" no solfejo.
String rotuloNota(Textos textos, NotaAfinacao nota, Notacao notacao) {
  final letra = notacao == Notacao.letras
      ? nota.letra
      : switch (nota.letra) {
          'C' => textos.solfejoC,
          'D' => textos.solfejoD,
          'E' => textos.solfejoE,
          'F' => textos.solfejoF,
          'G' => textos.solfejoG,
          'A' => textos.solfejoA,
          'B' => textos.solfejoB,
          _ => nota.letra,
        };
  return '$letra${nota.acidente}';
}

/// As notas de uma afinação, separadas por espaço: "D A D G B E".
String notasDaAfinacao(Textos textos, Afinacao afinacao, Notacao notacao) =>
    afinacao.notas.map((nota) => rotuloNota(textos, nota, notacao)).join(' ');

/// Rótulo falado de um botão de corda: "Corda E4", "Par G♯3, afinada".
String rotuloFaladoCorda(
  Textos textos,
  Instrumento instrumento,
  NotaAfinacao nota,
  Notacao notacao, {
  required bool afinada,
}) {
  final nome = '${rotuloNota(textos, nota, notacao)}${nota.oitava}';
  final rotulo = instrumento.pares
      ? textos.parNota(nome)
      : textos.cordaNota(nome);
  return afinada ? textos.cordaAfinada(rotulo) : rotulo;
}
