// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TextosEn extends Textos {
  TextosEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OpenTuner';

  @override
  String get toqueQualquerCorda => 'Play any string to start';

  @override
  String get aperteACorda => 'Tighten the string';

  @override
  String get afrouxeACorda => 'Loosen the string';

  @override
  String get afinada => 'In tune';

  @override
  String get auto => 'AUTO';

  @override
  String get autoDescricao => 'Detect the string automatically';

  @override
  String get ajustes => 'Settings';

  @override
  String get fechar => 'Close';

  @override
  String get instrumento => 'Instrument';

  @override
  String get afinacao => 'Tuning';

  @override
  String quantidadeCordas(int quantidade) {
    String _temp0 = intl.Intl.pluralLogic(
      quantidade,
      locale: localeName,
      other: '$quantidade strings',
      one: '1 string',
    );
    return '$_temp0';
  }

  @override
  String quantidadePares(int quantidade) {
    String _temp0 = intl.Intl.pluralLogic(
      quantidade,
      locale: localeName,
      other: '$quantidade pairs',
      one: '1 pair',
    );
    return '$_temp0';
  }

  @override
  String cordaNota(String nota) {
    return 'String $nota';
  }

  @override
  String parNota(String nota) {
    return 'Pair $nota';
  }

  @override
  String cordaAfinada(String rotulo) {
    return '$rotulo, in tune';
  }

  @override
  String desvioCents(int cents) {
    return '$cents cents';
  }

  @override
  String get tema => 'Theme';

  @override
  String get temaSistema => 'System';

  @override
  String get temaClaro => 'Light';

  @override
  String get temaEscuro => 'Dark';

  @override
  String get nomeDasNotas => 'Note names';

  @override
  String get notasLetras => 'C D E';

  @override
  String get notasSolfejo => 'Do Re Mi';

  @override
  String get precisao => 'Precision';

  @override
  String get precisaoNormal => 'Normal · ±5';

  @override
  String get precisaoFina => 'Fine · ±2';

  @override
  String get referenciaLa => 'Reference A';

  @override
  String get referenciaLaDescricao =>
      'A4, the note that calibrates all the others';

  @override
  String get diminuirReferencia => 'Lower reference';

  @override
  String get aumentarReferencia => 'Raise reference';

  @override
  String get manterTelaLigada => 'Keep screen on';

  @override
  String get manterTelaLigadaDescricao => 'Only while the tuner is open';

  @override
  String sobre(String versao) {
    return 'OpenTuner $versao · open source, Apache 2.0';
  }

  @override
  String get permissaoTitulo => 'The tuner needs to hear your instrument';

  @override
  String get permissaoTexto =>
      'The microphone is only used to hear the string. Nothing is recorded or leaves your phone.';

  @override
  String get permissaoPermitir => 'Allow microphone';

  @override
  String get permissaoNegada =>
      'Microphone access is off. Turn it on in the system settings to tune.';

  @override
  String get abrirConfiguracoes => 'Open settings';

  @override
  String get grupoUkuleleCavaquinho => 'Ukulele & cavaquinho';

  @override
  String get grupoViolaoViola => 'Guitar & viola';

  @override
  String get grupoBaixo => 'Bass';

  @override
  String get grupoArco => 'Bowed strings';

  @override
  String get instrumentoUkulele => 'Ukulele';

  @override
  String get instrumentoUkuleleBaritono => 'Baritone ukulele';

  @override
  String get instrumentoCavaquinho => 'Cavaquinho';

  @override
  String get instrumentoViolao => 'Guitar';

  @override
  String get instrumentoViolao7 => '7-string guitar';

  @override
  String get instrumentoViolaCaipira => 'Viola caipira';

  @override
  String get instrumentoBaixo => 'Bass';

  @override
  String get instrumentoBaixo5 => '5-string bass';

  @override
  String get instrumentoBaixo6 => '6-string bass';

  @override
  String get instrumentoViolino => 'Violin (beta)';

  @override
  String get afinacaoPadrao => 'Standard';

  @override
  String get afinacaoSolGrave => 'Low G';

  @override
  String get afinacaoEmRe => 'D tuning';

  @override
  String get afinacaoNatural => 'Natural';

  @override
  String get afinacaoDropD => 'Drop D';

  @override
  String get afinacaoMeioTomAbaixo => 'Half step down';

  @override
  String get afinacaoUmTomAbaixo => 'Whole step down';

  @override
  String get afinacaoDadgad => 'DADGAD';

  @override
  String get afinacaoOpenG => 'Open G';

  @override
  String get afinacaoOpenD => 'Open D';

  @override
  String get afinacaoSetimaEmDo => 'Low C 7th';

  @override
  String get afinacaoSetimaEmSi => 'Low B 7th';

  @override
  String get afinacaoCebolaoEmMi => 'Cebolão in E';

  @override
  String get afinacaoCebolaoEmRe => 'Cebolão in D';

  @override
  String get afinacaoRioAbaixo => 'Rio abaixo';

  @override
  String get afinacaoComDoAgudo => 'High C';

  @override
  String get solfejoC => 'Do';

  @override
  String get solfejoD => 'Re';

  @override
  String get solfejoE => 'Mi';

  @override
  String get solfejoF => 'Fa';

  @override
  String get solfejoG => 'Sol';

  @override
  String get solfejoA => 'La';

  @override
  String get solfejoB => 'Ti';

  @override
  String get esperandoCorda => 'Waiting for a string';

  @override
  String frequenciaHz(String frequencia) {
    return '$frequencia Hz';
  }

  @override
  String notaAlvo(String nota) {
    return 'Target note $nota';
  }

  @override
  String get recomecar => 'Start over';

  @override
  String get recomecarDescricao => 'Clear the tuned strings';

  @override
  String get idioma => 'Language';

  @override
  String get idiomaSistema => 'System language';

  @override
  String get nomeIdiomaPt => 'Português (Brasil)';

  @override
  String get nomeIdiomaEn => 'English';

  @override
  String get nomeIdiomaEs => 'Español';
}
