import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/idioma.dart';
import '../../app/tema.dart';
import 'controlador_afinador.dart';
import 'desenhos.dart';
import 'nomes.dart';

/// Posições da cabeça do instrumento no desenho de referência (390 × 274):
/// metade das cordas de cada lado, a mais grave embaixo à esquerda e, com
/// número ímpar, uma a mais à esquerda (RF-11).
@immutable
class GeometriaCabeca {
  const GeometriaCabeca({required this.cordas, required this.tamanho});

  /// Largura e altura do desenho de referência.
  static const larguraDesenho = 390.0;
  static const alturaDesenho = 274.0;

  final int cordas;
  final Size tamanho;

  /// Cordas do lado esquerdo.
  int get esquerda => (cordas + 1) ~/ 2;

  /// Escala do desenho (uniforme, para as tarraxas não ficarem ovais).
  double get escala => tamanho.height / alturaDesenho;

  /// Escala horizontal da tela, para os botões acompanharem as bordas.
  double get escalaLargura => tamanho.width / larguraDesenho;

  /// Deslocamento horizontal que centraliza o desenho.
  double get deslocamentoX => (tamanho.width - larguraDesenho * escala) / 2;

  double get _espaco =>
      esquerda <= 1 ? 0 : math.min(64.0, 150 / (esquerda - 1));

  bool ladoEsquerdo(int indice) => indice < esquerda;

  /// Altura (no desenho) da tarraxa da corda [indice].
  double yDesenho(int indice) {
    final linha = ladoEsquerdo(indice)
        ? esquerda - 1 - indice
        : indice - esquerda;
    final inicio = 50 + (150 - _espaco * (esquerda - 1)) / 2;
    return inicio + linha * _espaco;
  }

  /// Diâmetro do botão da corda: nunca abaixo de 48 dp.
  double get diametroBotao =>
      math.max(48.0, (esquerda >= 4 ? 46 : 56) * escalaLargura);

  /// Centro do botão da corda [indice], na área da cabeça.
  Offset centroBotao(int indice) {
    final x = ladoEsquerdo(indice)
        ? 52 * escalaLargura
        : tamanho.width - 52 * escalaLargura;
    return Offset(x, yDesenho(indice) * escala);
  }

  /// A escala mínima que ainda deixa 48 dp entre os centros dos botões.
  static double escalaMinima(int cordas) {
    final esquerda = (cordas + 1) ~/ 2;
    if (esquerda <= 1) return 0.75;
    final espaco = math.min(64.0, 150 / (esquerda - 1));
    return math.max(0.75, 48 / espaco);
  }
}

// Materiais do desenho: iguais nos dois temas, como o objeto de verdade.
const _metal = Color(0xFFCFCAC2);
const _metalBorda = Color(0xFF6F6A64);
const _escala = Color(0xFF2B1C13);
const _traste = Color(0xFFB9B2A6);
const _pestana = Color(0xFFEDE3CF);
const _corda = Color(0xFFD9D3C9);

/// A cabeça do instrumento: madeira, veios, pestana, escala, tarraxas, pinos
/// e as cordas até a pestana, com a corda alvo destacada.
class PintorCabeca extends CustomPainter {
  const PintorCabeca({
    required this.cordas,
    required this.ativa,
    required this.madeira,
    required this.madeiraEscura,
    required this.corAtiva,
  });

  final int cordas;
  final int? ativa;
  final Color madeira;
  final Color madeiraEscura;
  final Color corAtiva;

  static final Path _cabeca = Path()
    ..moveTo(118, 30)
    ..quadraticBezierTo(195, 0, 272, 30)
    ..lineTo(266, 170)
    ..quadraticBezierTo(262, 212, 242, 236)
    ..lineTo(242, 274)
    ..lineTo(148, 274)
    ..lineTo(148, 236)
    ..quadraticBezierTo(128, 212, 124, 170)
    ..close();

  static final Path _sombra = Path()
    ..moveTo(195, 15)
    ..quadraticBezierTo(236, 17, 272, 30)
    ..lineTo(266, 170)
    ..quadraticBezierTo(262, 212, 242, 236)
    ..lineTo(242, 274)
    ..lineTo(195, 274)
    ..close();

  static final Path _veios = Path()
    ..moveTo(140, 36)
    ..cubicTo(150, 80, 136, 130, 150, 190)
    ..moveTo(168, 22)
    ..cubicTo(176, 70, 162, 120, 172, 200)
    ..moveTo(226, 22)
    ..cubicTo(218, 76, 234, 126, 222, 206)
    ..moveTo(252, 34)
    ..cubicTo(244, 84, 256, 134, 244, 184);

  @override
  void paint(Canvas canvas, Size size) {
    final geometria = GeometriaCabeca(cordas: cordas, tamanho: size);
    canvas
      ..save()
      ..translate(geometria.deslocamentoX, 0)
      ..scale(geometria.escala);

    final preenchimentoMetal = Paint()..color = _metal;
    final bordaMetal = Paint()
      ..color = _metalBorda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Eixos das tarraxas, por baixo da madeira.
    final eixos = Paint()..color = _metalBorda;
    for (var i = 0; i < cordas; i++) {
      final y = geometria.yDesenho(i);
      final x = geometria.ladoEsquerdo(i) ? 112.0 : 264.0;
      canvas.drawRect(Rect.fromLTWH(x, y - 3, 14, 6), eixos);
    }

    canvas
      ..drawPath(_cabeca, Paint()..color = madeira)
      ..drawPath(
        _sombra,
        Paint()..color = madeiraEscura.withValues(alpha: 0.28),
      )
      ..drawPath(
        _veios,
        Paint()
          ..color = madeiraEscura.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      )
      ..drawRect(
        const Rect.fromLTWH(148, 240, 94, 34),
        Paint()..color = _escala,
      )
      ..drawRect(
        const Rect.fromLTWH(148, 264, 94, 2.5),
        Paint()..color = _traste,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(145, 232, 100, 9),
          const Radius.circular(1.5),
        ),
        Paint()..color = _pestana,
      );

    // Cordas: do pino até a pestana e dali pela escala.
    final corda = Paint()
      ..color = _corda.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final cordaAtiva = Paint()
      ..color = corAtiva
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (var i = 0; i < cordas; i++) {
      final y = geometria.yDesenho(i);
      final px = geometria.ladoEsquerdo(i) ? 150.0 : 240.0;
      final xn = cordas == 1 ? 195.0 : 158 + i * (74 / (cordas - 1));
      canvas.drawPath(
        Path()
          ..moveTo(px, y)
          ..lineTo(xn, 236)
          ..lineTo(xn, 274),
        i == ativa ? cordaAtiva : corda,
      );
    }

    // Pinos e tarraxas.
    for (var i = 0; i < cordas; i++) {
      final y = geometria.yDesenho(i);
      final esquerda = geometria.ladoEsquerdo(i);
      final pino = Offset(esquerda ? 150 : 240, y);
      canvas
        ..drawCircle(pino, 6, preenchimentoMetal)
        ..drawCircle(pino, 6, bordaMetal);
      final chave = Rect.fromCenter(
        center: Offset(esquerda ? 104 : 286, y),
        width: 18,
        height: 26,
      );
      final ehAtiva = i == ativa;
      canvas
        ..drawOval(
          chave,
          ehAtiva ? (Paint()..color = corAtiva) : preenchimentoMetal,
        )
        // A borda de metal fica também na ativa: no tema claro o creme dela
        // sumiria contra o fundo.
        ..drawOval(chave, bordaMetal);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorCabeca antigo) =>
      antigo.cordas != cordas ||
      antigo.ativa != ativa ||
      antigo.madeira != madeira ||
      antigo.madeiraEscura != madeiraEscura ||
      antigo.corAtiva != corAtiva;
}

/// A cabeça desenhada e os botões das cordas por cima. Escuta o controlador:
/// muda quando a corda alvo, as marcas ou a afinação mudam, não a cada
/// leitura.
class CabecaInstrumento extends StatelessWidget {
  const CabecaInstrumento({super.key, required this.controlador});

  final ControladorAfinador controlador;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, restricoes) {
        final tamanho = restricoes.biggest;
        final notas = controlador.afinacao.notas;
        final geometria = GeometriaCabeca(
          cordas: notas.length,
          tamanho: tamanho,
        );
        final ativa = controlador.cordaAlvo;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // O desenho não recebe toque: o alto dele, vazio, fica sobre o
            // gráfico.
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: PintorCabeca(
                      cordas: notas.length,
                      ativa: ativa,
                      madeira: cores.madeira,
                      madeiraEscura: cores.madeiraEscura,
                      corAtiva: escuro ? cores.texto : cores.sobreAccent,
                    ),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < notas.length; i++)
              Positioned(
                left: geometria.centroBotao(i).dx - geometria.diametroBotao / 2,
                top: geometria.centroBotao(i).dy - geometria.diametroBotao / 2,
                width: geometria.diametroBotao,
                height: geometria.diametroBotao,
                child: BotaoCorda(
                  key: Key('corda-$i'),
                  controlador: controlador,
                  indice: i,
                  ativa: i == ativa,
                  afinada: controlador.afinadas.contains(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Botão redondo da corda, com a nota e a oitava. Afinada, ganha anel e selo
/// verdes (RF-09). Tocar fixa a corda e desliga o Auto (RF-05).
class BotaoCorda extends StatelessWidget {
  const BotaoCorda({
    super.key,
    required this.controlador,
    required this.indice,
    required this.ativa,
    required this.afinada,
  });

  final ControladorAfinador controlador;
  final int indice;
  final bool ativa;
  final bool afinada;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final notacao = controlador.ajustes.notacao;
    final nota = controlador.afinacao.notas[indice];
    final grande = (controlador.afinacao.notas.length + 1) ~/ 2 < 4;
    final corTexto = ativa ? cores.fundo : cores.texto;

    return Semantics(
      button: true,
      selected: ativa,
      label: rotuloFaladoCorda(
        textos,
        controlador.instrumento,
        nota,
        notacao,
        afinada: afinada,
      ),
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: ativa ? cores.texto : cores.superficieAlta,
              shape: CircleBorder(
                side: afinada
                    ? BorderSide(color: cores.afinado, width: 3)
                    : BorderSide.none,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => controlador.tocarCorda(indice),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: NotaComOitava(
                        nota: rotuloNota(textos, nota, notacao),
                        oitava: '${nota.oitava}',
                        tamanho: grande ? 23 : 19,
                        tamanhoOitava: 12,
                        cor: corTexto,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (afinada)
            Positioned(
              key: Key('selo-$indice'),
              right: -4,
              top: -4,
              width: 20,
              height: 20,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cores.afinado,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Visto(cor: cores.fundo, tamanho: 12, espessura: 3.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
