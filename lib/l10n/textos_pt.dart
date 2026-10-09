// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class TextosPt extends Textos {
  TextosPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'OpenTuner';

  @override
  String get toqueQualquerCorda => 'Toque qualquer corda para começar';

  @override
  String get aperteACorda => 'Aperte a corda';

  @override
  String get afrouxeACorda => 'Afrouxe a corda';

  @override
  String get afinada => 'Afinada';

  @override
  String get auto => 'AUTO';

  @override
  String get autoDescricao => 'Detectar a corda automaticamente';

  @override
  String get ajustes => 'Ajustes';

  @override
  String get fechar => 'Fechar';

  @override
  String get instrumento => 'Instrumento';

  @override
  String get afinacao => 'Afinação';

  @override
  String quantidadeCordas(int quantidade) {
    String _temp0 = intl.Intl.pluralLogic(
      quantidade,
      locale: localeName,
      other: '$quantidade cordas',
      one: '1 corda',
    );
    return '$_temp0';
  }

  @override
  String quantidadePares(int quantidade) {
    String _temp0 = intl.Intl.pluralLogic(
      quantidade,
      locale: localeName,
      other: '$quantidade pares',
      one: '1 par',
    );
    return '$_temp0';
  }

  @override
  String cordaNota(String nota) {
    return 'Corda $nota';
  }

  @override
  String parNota(String nota) {
    return 'Par $nota';
  }

  @override
  String cordaAfinada(String rotulo) {
    return '$rotulo, afinada';
  }

  @override
  String desvioCents(int cents) {
    return '$cents cents';
  }

  @override
  String get tema => 'Tema';

  @override
  String get temaSistema => 'Sistema';

  @override
  String get temaClaro => 'Claro';

  @override
  String get temaEscuro => 'Escuro';

  @override
  String get nomeDasNotas => 'Nome das notas';

  @override
  String get notasLetras => 'C D E';

  @override
  String get notasSolfejo => 'Dó Ré Mi';

  @override
  String get precisao => 'Precisão';

  @override
  String get precisaoNormal => 'Normal · ±5';

  @override
  String get precisaoFina => 'Fina · ±2';

  @override
  String get referenciaLa => 'Referência do Lá';

  @override
  String get referenciaLaDescricao => 'A4, a nota que calibra todas as outras';

  @override
  String get diminuirReferencia => 'Diminuir referência';

  @override
  String get aumentarReferencia => 'Aumentar referência';

  @override
  String get manterTelaLigada => 'Manter a tela ligada';

  @override
  String get manterTelaLigadaDescricao =>
      'Só enquanto o afinador estiver aberto';

  @override
  String sobre(String versao) {
    return 'OpenTuner $versao · código aberto, Apache 2.0';
  }

  @override
  String get permissaoTitulo => 'O afinador precisa ouvir o instrumento';

  @override
  String get permissaoTexto =>
      'O microfone é usado só para ouvir a corda. Nada é gravado nem sai do aparelho.';

  @override
  String get permissaoPermitir => 'Permitir o microfone';

  @override
  String get permissaoNegada =>
      'O acesso ao microfone está desligado. Ligue nas configurações do sistema para afinar.';

  @override
  String get abrirConfiguracoes => 'Abrir configurações';

  @override
  String get grupoUkuleleCavaquinho => 'Ukulele e cavaquinho';

  @override
  String get grupoViolaoViola => 'Violão, guitarra e viola';

  @override
  String get grupoBaixo => 'Baixo';

  @override
  String get grupoArco => 'Arco';

  @override
  String get instrumentoUkulele => 'Ukulele';

  @override
  String get instrumentoUkuleleBaritono => 'Ukulele barítono';

  @override
  String get instrumentoCavaquinho => 'Cavaquinho';

  @override
  String get instrumentoViolao => 'Violão / Guitarra';

  @override
  String get instrumentoViolao7 => 'Violão 7 cordas';

  @override
  String get instrumentoViolaCaipira => 'Viola caipira';

  @override
  String get instrumentoBaixo => 'Baixo';

  @override
  String get instrumentoBaixo5 => 'Baixo 5 cordas';

  @override
  String get instrumentoBaixo6 => 'Baixo 6 cordas';

  @override
  String get instrumentoViolino => 'Violino (beta)';

  @override
  String get afinacaoPadrao => 'Padrão';

  @override
  String get afinacaoSolGrave => 'Sol grave (Low G)';

  @override
  String get afinacaoEmRe => 'Em Ré';

  @override
  String get afinacaoNatural => 'Natural';

  @override
  String get afinacaoDropD => 'Drop D';

  @override
  String get afinacaoMeioTomAbaixo => 'Meio tom abaixo';

  @override
  String get afinacaoUmTomAbaixo => 'Um tom abaixo';

  @override
  String get afinacaoDadgad => 'DADGAD';

  @override
  String get afinacaoOpenG => 'Open G';

  @override
  String get afinacaoOpenD => 'Open D';

  @override
  String get afinacaoSetimaEmDo => 'Sétima em Dó';

  @override
  String get afinacaoSetimaEmSi => 'Sétima em Si';

  @override
  String get afinacaoCebolaoEmMi => 'Cebolão em Mi';

  @override
  String get afinacaoCebolaoEmRe => 'Cebolão em Ré';

  @override
  String get afinacaoRioAbaixo => 'Rio abaixo';

  @override
  String get afinacaoComDoAgudo => 'Com Dó agudo';

  @override
  String get solfejoC => 'Dó';

  @override
  String get solfejoD => 'Ré';

  @override
  String get solfejoE => 'Mi';

  @override
  String get solfejoF => 'Fá';

  @override
  String get solfejoG => 'Sol';

  @override
  String get solfejoA => 'Lá';

  @override
  String get solfejoB => 'Si';

  @override
  String get esperandoCorda => 'Esperando uma corda';

  @override
  String frequenciaHz(String frequencia) {
    return '$frequencia Hz';
  }

  @override
  String notaAlvo(String nota) {
    return 'Nota alvo $nota';
  }

  @override
  String get recomecar => 'Recomeçar';

  @override
  String get recomecarDescricao => 'Limpar as cordas afinadas';

  @override
  String get idioma => 'Idioma';

  @override
  String get idiomaSistema => 'Idioma do sistema';

  @override
  String get nomeIdiomaPt => 'Português (Brasil)';

  @override
  String get nomeIdiomaEn => 'English';

  @override
  String get nomeIdiomaEs => 'Español';
}
