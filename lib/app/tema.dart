import 'package:flutter/material.dart';

// TODO: empacotar as fontes em assets/fontes e declará-las no pubspec:
// Fraunces (display: título e nota em destaque) e Manrope (texto corrido e
// botões). Vão versionadas junto com a licença SIL OFL, e não pelo
// google_fonts em tempo de execução: o aplicativo não tem permissão de
// internet.

/// Tokens de cor do tema "Nogueira".
///
/// O `ColorScheme` do Material cobre a estrutura da interface; o que é próprio
/// de um afinador (afinado, perto, longe) e a madeira do instrumento vivem
/// aqui. Acesso por `context.cores`.
@immutable
class CoresOpenTuner extends ThemeExtension<CoresOpenTuner> {
  const CoresOpenTuner({
    required this.fundo,
    required this.superficie,
    required this.superficieAlta,
    required this.grade,
    required this.texto,
    required this.textoSecundario,
    required this.accent,
    required this.sobreAccent,
    required this.afinado,
    required this.perto,
    required this.longe,
    required this.madeira,
    required this.madeiraEscura,
  });

  /// Fundo da tela.
  final Color fundo;

  /// Cartões e barras sobre o fundo.
  final Color superficie;

  /// Superfície em destaque (botões da barra inferior, por exemplo).
  final Color superficieAlta;

  /// Linhas de escala e divisórias.
  final Color grade;

  final Color texto;
  final Color textoSecundario;

  /// Cor de marca: destaques e ações principais.
  final Color accent;

  /// Texto e ícones sobre [accent].
  final Color sobreAccent;

  /// Corda dentro da tolerância.
  final Color afinado;

  /// Corda próxima, mas ainda fora da tolerância.
  final Color perto;

  /// Corda longe da nota alvo.
  final Color longe;

  /// Madeira do instrumento desenhado.
  final Color madeira;
  final Color madeiraEscura;

  static const claro = CoresOpenTuner(
    fundo: Color(0xFFF5EFE6),
    superficie: Color(0xFFFFFBF5),
    superficieAlta: Color(0xFFEDE4D6),
    grade: Color(0xFFE3D8C8),
    texto: Color(0xFF231A13),
    textoSecundario: Color(0xFF6E5E50),
    accent: Color(0xFF6B4226),
    sobreAccent: Color(0xFFFFF8EF),
    afinado: Color(0xFF2A7353),
    perto: Color(0xFF8A6400),
    longe: Color(0xFFB04A1C),
    madeira: Color(0xFF7A4A2A),
    madeiraEscura: Color(0xFF4E2E18),
  );

  static const escuro = CoresOpenTuner(
    fundo: Color(0xFF14110E),
    superficie: Color(0xFF1E1915),
    superficieAlta: Color(0xFF2A231D),
    grade: Color(0xFF2A241E),
    texto: Color(0xFFF3EBE0),
    textoSecundario: Color(0xFFB3A597),
    accent: Color(0xFFC9935F),
    sobreAccent: Color(0xFF1A120B),
    afinado: Color(0xFF5CC592),
    perto: Color(0xFFE6C24F),
    longe: Color(0xFFEE8A52),
    madeira: Color(0xFF7A4A2A),
    madeiraEscura: Color(0xFF4E2E18),
  );

  @override
  CoresOpenTuner copyWith({
    Color? fundo,
    Color? superficie,
    Color? superficieAlta,
    Color? grade,
    Color? texto,
    Color? textoSecundario,
    Color? accent,
    Color? sobreAccent,
    Color? afinado,
    Color? perto,
    Color? longe,
    Color? madeira,
    Color? madeiraEscura,
  }) {
    return CoresOpenTuner(
      fundo: fundo ?? this.fundo,
      superficie: superficie ?? this.superficie,
      superficieAlta: superficieAlta ?? this.superficieAlta,
      grade: grade ?? this.grade,
      texto: texto ?? this.texto,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      accent: accent ?? this.accent,
      sobreAccent: sobreAccent ?? this.sobreAccent,
      afinado: afinado ?? this.afinado,
      perto: perto ?? this.perto,
      longe: longe ?? this.longe,
      madeira: madeira ?? this.madeira,
      madeiraEscura: madeiraEscura ?? this.madeiraEscura,
    );
  }

  @override
  CoresOpenTuner lerp(CoresOpenTuner? outro, double t) {
    if (outro == null) return this;
    Color misturar(Color a, Color b) => Color.lerp(a, b, t)!;
    return CoresOpenTuner(
      fundo: misturar(fundo, outro.fundo),
      superficie: misturar(superficie, outro.superficie),
      superficieAlta: misturar(superficieAlta, outro.superficieAlta),
      grade: misturar(grade, outro.grade),
      texto: misturar(texto, outro.texto),
      textoSecundario: misturar(textoSecundario, outro.textoSecundario),
      accent: misturar(accent, outro.accent),
      sobreAccent: misturar(sobreAccent, outro.sobreAccent),
      afinado: misturar(afinado, outro.afinado),
      perto: misturar(perto, outro.perto),
      longe: misturar(longe, outro.longe),
      madeira: misturar(madeira, outro.madeira),
      madeiraEscura: misturar(madeiraEscura, outro.madeiraEscura),
    );
  }
}

/// Monta o `ThemeData` a partir dos tokens, sem `ColorScheme.fromSeed`: a
/// paleta é fechada, e as cores derivadas do seed não batem com ela.
ThemeData _montarTema(Brightness brilho, CoresOpenTuner cores) {
  final esquema = ColorScheme(
    brightness: brilho,
    primary: cores.accent,
    onPrimary: cores.sobreAccent,
    secondary: cores.madeira,
    onSecondary: cores.sobreAccent,
    tertiary: cores.afinado,
    onTertiary: cores.sobreAccent,
    error: cores.longe,
    onError: cores.sobreAccent,
    surface: cores.superficie,
    onSurface: cores.texto,
    onSurfaceVariant: cores.textoSecundario,
    surfaceContainerLowest: cores.fundo,
    surfaceContainerLow: cores.superficie,
    surfaceContainer: cores.superficie,
    surfaceContainerHigh: cores.superficieAlta,
    surfaceContainerHighest: cores.superficieAlta,
    outline: cores.textoSecundario,
    outlineVariant: cores.grade,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: esquema,
    scaffoldBackgroundColor: cores.fundo,
    dividerColor: cores.grade,
    extensions: [cores],
  );
}

final ThemeData temaClaro = _montarTema(Brightness.light, CoresOpenTuner.claro);

final ThemeData temaEscuro = _montarTema(
  Brightness.dark,
  CoresOpenTuner.escuro,
);

extension CoresDoContexto on BuildContext {
  /// Tokens do tema ativo (claro ou escuro).
  CoresOpenTuner get cores => Theme.of(this).extension<CoresOpenTuner>()!;
}
