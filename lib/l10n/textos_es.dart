// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class TextosEs extends Textos {
  TextosEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OpenTuner';

  @override
  String get toqueQualquerCorda => 'Toca cualquier cuerda para empezar';

  @override
  String get aperteACorda => 'Tensa la cuerda';

  @override
  String get afrouxeACorda => 'Afloja la cuerda';

  @override
  String get afinada => 'Afinada';

  @override
  String get auto => 'AUTO';

  @override
  String get autoDescricao => 'Detectar la cuerda automáticamente';

  @override
  String get ajustes => 'Ajustes';

  @override
  String get fechar => 'Cerrar';

  @override
  String get instrumento => 'Instrumento';

  @override
  String get afinacao => 'Afinación';

  @override
  String quantidadeCordas(int quantidade) {
    String _temp0 = intl.Intl.pluralLogic(
      quantidade,
      locale: localeName,
      other: '$quantidade cuerdas',
      one: '1 cuerda',
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
    return 'Cuerda $nota';
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
  String get temaEscuro => 'Oscuro';

  @override
  String get nomeDasNotas => 'Nombre de las notas';

  @override
  String get notasLetras => 'C D E';

  @override
  String get notasSolfejo => 'Do Re Mi';

  @override
  String get precisao => 'Precisión';

  @override
  String get precisaoNormal => 'Normal · ±5';

  @override
  String get precisaoFina => 'Fina · ±2';

  @override
  String get referenciaLa => 'Referencia del La';

  @override
  String get referenciaLaDescricao => 'A4, la nota que calibra todas las demás';

  @override
  String get diminuirReferencia => 'Bajar referencia';

  @override
  String get aumentarReferencia => 'Subir referencia';

  @override
  String get manterTelaLigada => 'Mantener la pantalla encendida';

  @override
  String get manterTelaLigadaDescricao =>
      'Solo mientras el afinador esté abierto';

  @override
  String sobre(String versao) {
    return 'OpenTuner $versao · código abierto, Apache 2.0';
  }

  @override
  String get permissaoTitulo => 'El afinador necesita escuchar tu instrumento';

  @override
  String get permissaoTexto =>
      'El micrófono solo se usa para escuchar la cuerda. Nada se graba ni sale del teléfono.';

  @override
  String get permissaoPermitir => 'Permitir el micrófono';

  @override
  String get permissaoNegada =>
      'El acceso al micrófono está desactivado. Actívalo en los ajustes del sistema para afinar.';

  @override
  String get abrirConfiguracoes => 'Abrir ajustes';

  @override
  String get grupoUkuleleCavaquinho => 'Ukelele y cavaquinho';

  @override
  String get grupoViolaoViola => 'Guitarra y viola';

  @override
  String get grupoBaixo => 'Bajo';

  @override
  String get grupoArco => 'Arco';

  @override
  String get instrumentoUkulele => 'Ukelele';

  @override
  String get instrumentoUkuleleBaritono => 'Ukelele barítono';

  @override
  String get instrumentoCavaquinho => 'Cavaquinho';

  @override
  String get instrumentoViolao => 'Guitarra';

  @override
  String get instrumentoViolao7 => 'Guitarra de 7 cuerdas';

  @override
  String get instrumentoViolaCaipira => 'Viola caipira';

  @override
  String get instrumentoBaixo => 'Bajo';

  @override
  String get instrumentoBaixo5 => 'Bajo de 5 cuerdas';

  @override
  String get instrumentoBaixo6 => 'Bajo de 6 cuerdas';

  @override
  String get instrumentoViolino => 'Violín (beta)';

  @override
  String get afinacaoPadrao => 'Estándar';

  @override
  String get afinacaoSolGrave => 'Sol grave (Low G)';

  @override
  String get afinacaoEmRe => 'En Re';

  @override
  String get afinacaoNatural => 'Natural';

  @override
  String get afinacaoDropD => 'Drop D';

  @override
  String get afinacaoMeioTomAbaixo => 'Medio tono abajo';

  @override
  String get afinacaoUmTomAbaixo => 'Un tono abajo';

  @override
  String get afinacaoDadgad => 'DADGAD';

  @override
  String get afinacaoOpenG => 'Open G';

  @override
  String get afinacaoOpenD => 'Open D';

  @override
  String get afinacaoSetimaEmDo => 'Séptima en Do';

  @override
  String get afinacaoSetimaEmSi => 'Séptima en Si';

  @override
  String get afinacaoCebolaoEmMi => 'Cebolão en Mi';

  @override
  String get afinacaoCebolaoEmRe => 'Cebolão en Re';

  @override
  String get afinacaoRioAbaixo => 'Rio abaixo';

  @override
  String get afinacaoComDoAgudo => 'Con Do agudo';

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
  String get solfejoB => 'Si';

  @override
  String get esperandoCorda => 'Esperando una cuerda';

  @override
  String frequenciaHz(String frequencia) {
    return '$frequencia Hz';
  }

  @override
  String notaAlvo(String nota) {
    return 'Nota objetivo $nota';
  }

  @override
  String get recomecar => 'Reiniciar';

  @override
  String get recomecarDescricao => 'Borrar las cuerdas afinadas';

  @override
  String get idioma => 'Idioma';

  @override
  String get idiomaSistema => 'Idioma del sistema';

  @override
  String get nomeIdiomaPt => 'Português (Brasil)';

  @override
  String get nomeIdiomaEn => 'English';

  @override
  String get nomeIdiomaEs => 'Español';
}
