import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// Cores derivadas dos tokens que o protótipo usa e o tema não expõe.
extension CoresDerivadas on CoresOpenTuner {
  /// Linha do centro do gráfico, contorno da nota alvo e alça das folhas: um
  /// pouco mais forte que a grade.
  Color get linha => Color.lerp(grade, textoSecundario, 0.25)!;

  /// Grade do gráfico, mais sutil que a das divisórias.
  Color get gradeSutil => Color.lerp(fundo, grade, 0.6)!;

  /// Fundo escurecido atrás das folhas.
  Color get veu => texto.computeLuminance() > 0.5
      ? const Color(0x9E000000)
      : const Color(0x73231A13);
}

/// O símbolo do OpenTuner: a palheta com a onda que se acalma no centro
/// (docs/marca/simbolo-claro.svg, viewBox 100 × 110).
class PintorPalheta extends CustomPainter {
  const PintorPalheta({required this.cor, required this.corOnda});

  final Color cor;
  final Color corOnda;

  static final Path _palheta = Path()
    ..moveTo(50, 106)
    ..cubicTo(42, 100, 6, 62, 5, 34)
    ..cubicTo(4, 14, 22, 4, 50, 4)
    ..cubicTo(78, 4, 96, 14, 95, 34)
    ..cubicTo(94, 62, 58, 100, 50, 106)
    ..close();

  static final Path _onda = Path()
    ..moveTo(50, 18)
    ..cubicTo(71, 21, 71, 33, 50, 36)
    ..cubicTo(32, 39, 32, 49, 50, 51)
    ..cubicTo(62, 53, 62, 60, 50, 62)
    ..cubicTo(44, 63, 44, 67, 50, 68)
    ..lineTo(50, 88);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 110);
    canvas.drawPath(_palheta, Paint()..color = cor);
    canvas.drawPath(
      _onda,
      Paint()
        ..color = corOnda
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(PintorPalheta antigo) =>
      antigo.cor != cor || antigo.corOnda != corOnda;
}

/// O ✓ do protótipo, num quadrado de 24 × 24.
class Visto extends StatelessWidget {
  const Visto({
    super.key,
    required this.cor,
    this.tamanho = 22,
    this.espessura = 2.6,
  });

  final Color cor;
  final double tamanho;
  final double espessura;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(tamanho),
    painter: _PintorVisto(cor, espessura),
  );
}

class _PintorVisto extends CustomPainter {
  const _PintorVisto(this.cor, this.espessura);

  final Color cor;
  final double espessura;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(5, 12.5)
        ..lineTo(9.5, 17)
        ..lineTo(19, 7.5),
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PintorVisto antigo) =>
      antigo.cor != cor || antigo.espessura != espessura;
}

/// Ícone de ajustes do protótipo: dois controles deslizantes.
class IconeAjustes extends StatelessWidget {
  const IconeAjustes({super.key, required this.cor, this.tamanho = 22});

  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(tamanho), painter: _PintorAjustes(cor));
}

class _PintorAjustes extends CustomPainter {
  const _PintorAjustes(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final traco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(4, 7), const Offset(13, 7), traco)
      ..drawLine(const Offset(17, 7), const Offset(20, 7), traco)
      ..drawLine(const Offset(4, 17), const Offset(7, 17), traco)
      ..drawLine(const Offset(11, 17), const Offset(20, 17), traco)
      ..drawCircle(const Offset(15, 7), 2.2, traco)
      ..drawCircle(const Offset(9, 17), 2.2, traco);
  }

  @override
  bool shouldRepaint(_PintorAjustes antigo) => antigo.cor != cor;
}

/// Uma nota com a oitava pequena, sobrescrita: E⁴.
class NotaComOitava extends StatelessWidget {
  const NotaComOitava({
    super.key,
    required this.nota,
    required this.oitava,
    required this.tamanho,
    required this.tamanhoOitava,
    required this.cor,
    this.opacidadeOitava = 0.8,
    this.peso = FontWeight.w600,
  });

  final String nota;
  final String oitava;
  final double tamanho;
  final double tamanhoOitava;
  final Color cor;
  final double opacidadeOitava;
  final FontWeight peso;

  /// Fraunces não tem ♭ nem ♯: o sinal vem da fonte do sistema, menor que
  /// a letra. Um pouco maior, ele fica do tamanho dela.
  List<InlineSpan> _letraEAcidente(TextStyle estilo) {
    final ultimo = nota.isEmpty ? '' : nota.substring(nota.length - 1);
    if (ultimo != '♭' && ultimo != '♯') {
      return [TextSpan(text: nota, style: estilo)];
    }
    return [
      TextSpan(text: nota.substring(0, nota.length - 1), style: estilo),
      TextSpan(
        text: ultimo,
        style: estilo.copyWith(fontSize: estilo.fontSize! * 1.2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontFamily: familiaDisplay,
      fontWeight: peso,
      height: 1,
      color: cor,
    );
    return Text.rich(
      TextSpan(
        children: [
          ..._letraEAcidente(estilo.copyWith(fontSize: tamanho)),
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: EdgeInsets.only(left: 1, top: tamanho * 0.05),
              child: Text(
                oitava,
                style: estilo.copyWith(
                  fontSize: tamanhoOitava,
                  color: cor.withValues(alpha: opacidadeOitava),
                ),
              ),
            ),
          ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
    );
  }
}

/// A chave liga/desliga do protótipo: trilho de 42 × 24 com o botão
/// deslizando. Só o desenho; quem usa cuida do toque e da semântica.
class TrilhoChave extends StatelessWidget {
  const TrilhoChave({super.key, required this.ligada});

  final bool ligada;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 42,
      height: 24,
      decoration: BoxDecoration(
        color: ligada ? cores.accent : cores.superficieAlta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ligada ? cores.accent : cores.linha),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: ligada ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ligada ? cores.sobreAccent : cores.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}
