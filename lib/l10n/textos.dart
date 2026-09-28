import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'textos_en.dart';
import 'textos_es.dart';
import 'textos_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Textos
/// returned by `Textos.of(context)`.
///
/// Applications need to include `Textos.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/textos.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Textos.localizationsDelegates,
///   supportedLocales: Textos.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the Textos.supportedLocales
/// property.
abstract class Textos {
  Textos(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Textos of(BuildContext context) {
    return Localizations.of<Textos>(context, Textos)!;
  }

  static const LocalizationsDelegate<Textos> delegate = _TextosDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// App name, shown in the task switcher and the title
  ///
  /// In en, this message translates to:
  /// **'OpenTuner'**
  String get appTitle;

  /// Shown while no note is being heard
  ///
  /// In en, this message translates to:
  /// **'Play any string to start'**
  String get toqueQualquerCorda;

  /// The string is flat: raise its pitch
  ///
  /// In en, this message translates to:
  /// **'Tighten the string'**
  String get aperteACorda;

  /// The string is sharp: lower its pitch
  ///
  /// In en, this message translates to:
  /// **'Loosen the string'**
  String get afrouxeACorda;

  /// The string is within tolerance
  ///
  /// In en, this message translates to:
  /// **'In tune'**
  String get afinada;

  /// Short label of the automatic string detection toggle
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get auto;

  /// Accessibility description of the AUTO toggle
  ///
  /// In en, this message translates to:
  /// **'Detect the string automatically'**
  String get autoDescricao;

  /// Settings screen title and button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get ajustes;

  /// Closes a sheet or screen
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get fechar;

  /// Label of the instrument picker
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get instrumento;

  /// Label of the tuning picker
  ///
  /// In en, this message translates to:
  /// **'Tuning'**
  String get afinacao;

  /// Number of strings of an instrument
  ///
  /// In en, this message translates to:
  /// **'{quantidade, plural, =1{1 string} other{{quantidade} strings}}'**
  String quantidadeCordas(int quantidade);

  /// Number of string pairs (courses) of an instrument
  ///
  /// In en, this message translates to:
  /// **'{quantidade, plural, =1{1 pair} other{{quantidade} pairs}}'**
  String quantidadePares(int quantidade);

  /// Accessibility label of a single string, by its note
  ///
  /// In en, this message translates to:
  /// **'String {nota}'**
  String cordaNota(String nota);

  /// Accessibility label of a string pair, by its note
  ///
  /// In en, this message translates to:
  /// **'Pair {nota}'**
  String parNota(String nota);

  /// Accessibility label of a string already in tune
  ///
  /// In en, this message translates to:
  /// **'{rotulo}, in tune'**
  String cordaAfinada(String rotulo);

  /// Deviation from the target note, in cents
  ///
  /// In en, this message translates to:
  /// **'{cents} cents'**
  String desvioCents(int cents);

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get tema;

  /// Theme option: follow the system
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get temaSistema;

  /// Theme option: light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get temaClaro;

  /// Theme option: dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get temaEscuro;

  /// Setting: how note names are written
  ///
  /// In en, this message translates to:
  /// **'Note names'**
  String get nomeDasNotas;

  /// Note names option: letters
  ///
  /// In en, this message translates to:
  /// **'C D E'**
  String get notasLetras;

  /// Note names option: solfège
  ///
  /// In en, this message translates to:
  /// **'Do Re Mi'**
  String get notasSolfejo;

  /// Setting: tuning tolerance
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get precisao;

  /// Precision option: ±5 cents
  ///
  /// In en, this message translates to:
  /// **'Normal · ±5'**
  String get precisaoNormal;

  /// Precision option: ±2 cents
  ///
  /// In en, this message translates to:
  /// **'Fine · ±2'**
  String get precisaoFina;

  /// Setting: reference frequency of A4
  ///
  /// In en, this message translates to:
  /// **'Reference A'**
  String get referenciaLa;

  /// Explains the reference A setting
  ///
  /// In en, this message translates to:
  /// **'A4, the note that calibrates all the others'**
  String get referenciaLaDescricao;

  /// Button that lowers the reference A
  ///
  /// In en, this message translates to:
  /// **'Lower reference'**
  String get diminuirReferencia;

  /// Button that raises the reference A
  ///
  /// In en, this message translates to:
  /// **'Raise reference'**
  String get aumentarReferencia;

  /// Setting: keep the screen awake
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get manterTelaLigada;

  /// Explains the keep screen on setting
  ///
  /// In en, this message translates to:
  /// **'Only while the tuner is open'**
  String get manterTelaLigadaDescricao;

  /// About line at the bottom of the settings
  ///
  /// In en, this message translates to:
  /// **'OpenTuner {versao} · open source, Apache 2.0'**
  String sobre(String versao);

  /// Title of the microphone permission screen
  ///
  /// In en, this message translates to:
  /// **'The tuner needs to hear your instrument'**
  String get permissaoTitulo;

  /// Why the microphone is needed
  ///
  /// In en, this message translates to:
  /// **'The microphone is only used to hear the string. Nothing is recorded or leaves your phone.'**
  String get permissaoTexto;

  /// Button that asks for the microphone permission
  ///
  /// In en, this message translates to:
  /// **'Allow microphone'**
  String get permissaoPermitir;

  /// Shown when the microphone permission was denied
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Turn it on in the system settings to tune.'**
  String get permissaoNegada;

  /// Button that opens the system app settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get abrirConfiguracoes;

  /// Instrument group heading
  ///
  /// In en, this message translates to:
  /// **'Ukulele & cavaquinho'**
  String get grupoUkuleleCavaquinho;

  /// Instrument group heading
  ///
  /// In en, this message translates to:
  /// **'Guitar & viola'**
  String get grupoViolaoViola;

  /// Instrument group heading
  ///
  /// In en, this message translates to:
  /// **'Bass'**
  String get grupoBaixo;

  /// Instrument name
  ///
  /// In en, this message translates to:
  /// **'Ukulele'**
  String get instrumentoUkulele;

  /// Instrument name
  ///
  /// In en, this message translates to:
  /// **'Baritone ukulele'**
  String get instrumentoUkuleleBaritono;

  /// Instrument name
  ///
  /// In en, this message translates to:
  /// **'Cavaquinho'**
  String get instrumentoCavaquinho;

  /// Instrument name: acoustic guitar
  ///
  /// In en, this message translates to:
  /// **'Guitar'**
  String get instrumentoViolao;

  /// Instrument name
  ///
  /// In en, this message translates to:
  /// **'7-string guitar'**
  String get instrumentoViolao7;

  /// Instrument name: Brazilian 10-string viola
  ///
  /// In en, this message translates to:
  /// **'Viola caipira'**
  String get instrumentoViolaCaipira;

  /// Instrument name: 4-string bass
  ///
  /// In en, this message translates to:
  /// **'Bass'**
  String get instrumentoBaixo;

  /// Instrument name
  ///
  /// In en, this message translates to:
  /// **'5-string bass'**
  String get instrumentoBaixo5;

  /// Instrument name
  ///
  /// In en, this message translates to:
  /// **'6-string bass'**
  String get instrumentoBaixo6;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get afinacaoPadrao;

  /// Tuning name: ukulele with low G
  ///
  /// In en, this message translates to:
  /// **'Low G'**
  String get afinacaoSolGrave;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'D tuning'**
  String get afinacaoEmRe;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get afinacaoNatural;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'Drop D'**
  String get afinacaoDropD;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'Half step down'**
  String get afinacaoMeioTomAbaixo;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'Whole step down'**
  String get afinacaoUmTomAbaixo;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'DADGAD'**
  String get afinacaoDadgad;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'Open G'**
  String get afinacaoOpenG;

  /// Tuning name
  ///
  /// In en, this message translates to:
  /// **'Open D'**
  String get afinacaoOpenD;

  /// Tuning name: 7-string guitar with low C
  ///
  /// In en, this message translates to:
  /// **'Low C 7th'**
  String get afinacaoSetimaEmDo;

  /// Tuning name: 7-string guitar with low B
  ///
  /// In en, this message translates to:
  /// **'Low B 7th'**
  String get afinacaoSetimaEmSi;

  /// Tuning name: viola caipira
  ///
  /// In en, this message translates to:
  /// **'Cebolão in E'**
  String get afinacaoCebolaoEmMi;

  /// Tuning name: viola caipira
  ///
  /// In en, this message translates to:
  /// **'Cebolão in D'**
  String get afinacaoCebolaoEmRe;

  /// Tuning name: viola caipira
  ///
  /// In en, this message translates to:
  /// **'Rio abaixo'**
  String get afinacaoRioAbaixo;

  /// Tuning name: 6-string bass with high C
  ///
  /// In en, this message translates to:
  /// **'High C'**
  String get afinacaoComDoAgudo;

  /// Solfège name of C
  ///
  /// In en, this message translates to:
  /// **'Do'**
  String get solfejoC;

  /// Solfège name of D
  ///
  /// In en, this message translates to:
  /// **'Re'**
  String get solfejoD;

  /// Solfège name of E
  ///
  /// In en, this message translates to:
  /// **'Mi'**
  String get solfejoE;

  /// Solfège name of F
  ///
  /// In en, this message translates to:
  /// **'Fa'**
  String get solfejoF;

  /// Solfège name of G
  ///
  /// In en, this message translates to:
  /// **'Sol'**
  String get solfejoG;

  /// Solfège name of A
  ///
  /// In en, this message translates to:
  /// **'La'**
  String get solfejoA;

  /// Solfège name of B
  ///
  /// In en, this message translates to:
  /// **'Ti'**
  String get solfejoB;
}

class _TextosDelegate extends LocalizationsDelegate<Textos> {
  const _TextosDelegate();

  @override
  Future<Textos> load(Locale locale) {
    return SynchronousFuture<Textos>(lookupTextos(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_TextosDelegate old) => false;
}

Textos lookupTextos(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TextosEn();
    case 'es':
      return TextosEs();
    case 'pt':
      return TextosPt();
  }

  throw FlutterError(
    'Textos.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
