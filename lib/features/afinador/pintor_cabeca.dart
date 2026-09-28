import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../dominio/afinacoes.dart';
import 'cabeca_instrumento.dart';

/// O desenho da cabeça muda com o instrumento (RF-11). As tarraxas ficam
/// sempre nas mesmas alturas ([GeometriaCabeca]), para os botões não saírem
/// do lugar; o que muda é o contorno, a madeira, as tarraxas e as cordas.
enum EstiloCabeca {
  /// Pequena, com a coroa arredondada e tarraxas de botão.
  ukulele,

  /// Maciça, com o bico no alto e tarraxas de metal.
  cavaquinho,

  /// O violão clássico: cabeça vazada, rolos brancos nas fendas e botões
  /// de madrepérola.
  violao,

  /// A viola caipira: recorte em lóbulos, o losango de madrepérola e duas
  /// tarraxas por par.
  viola,

  /// Larga, com o topo inclinado, tarraxas grandes e cordas grossas.
  baixo,
}

/// O estilo do desenho de cada instrumento.
EstiloCabeca estiloDaCabeca(Instrumento instrumento) =>
    switch (instrumento.grupo) {
      GrupoInstrumento.baixo => EstiloCabeca.baixo,
      GrupoInstrumento.ukuleleCavaquinho =>
        instrumento.id == 'cavaquinho'
            ? EstiloCabeca.cavaquinho
            : EstiloCabeca.ukulele,
      GrupoInstrumento.violaoViola =>
        instrumento.pares ? EstiloCabeca.viola : EstiloCabeca.violao,
    };

// Materiais do desenho: iguais nos dois temas, como o objeto de verdade.
const _metal = Color(0xFFCFCAC2);
const _metalBorda = Color(0xFF6F6A64);
const _marfim = Color(0xFFF1E9D8);
const _marfimBorda = Color(0xFF9A8E7A);
const _escala = Color(0xFF2B1C13);
const _fenda = Color(0xFF1C120B);
const _traste = Color(0xFFB9B2A6);
const _pestana = Color(0xFFEDE3CF);
const _corda = Color(0xFFD9D3C9);

/// Tom de cada madeira, misturado à madeira do tema.
const _koa = Color(0xFFB5773F);
const _jacaranda = Color(0xFF4A2616);
const _cedro = Color(0xFF9C5A2C);
const _ebano = Color(0xFF2E2019);

/// A cabeça do instrumento: madeira, veios, pestana, escala, tarraxas, pinos
/// e as cordas até a pestana. A corda alvo fica destacada; as afinadas, em
/// verde.
class PintorCabeca extends CustomPainter {
  const PintorCabeca({
    required this.estilo,
    required this.cordas,
    required this.ativa,
    required this.afinadas,
    required this.madeira,
    required this.madeiraEscura,
    required this.corAtiva,
    required this.corAfinada,
  });

  final EstiloCabeca estilo;
  final int cordas;
  final int? ativa;
  final Set<int> afinadas;
  final Color madeira;
  final Color madeiraEscura;
  final Color corAtiva;
  final Color corAfinada;

  bool get _pares => estilo == EstiloCabeca.viola;

  // ------------------------------------------------------------ contornos ---

  /// Todos terminam no braço, de 148 a 242, com a pestana em 232.
  static final Map<EstiloCabeca, Path> _contornos = {
    EstiloCabeca.ukulele: Path()
      ..moveTo(134, 62)
      ..quadraticBezierTo(131, 30, 162, 28)
      ..quadraticBezierTo(184, 27, 195, 44)
      ..quadraticBezierTo(206, 27, 228, 28)
      ..quadraticBezierTo(259, 30, 256, 62)
      ..lineTo(254, 192)
      ..quadraticBezierTo(252, 222, 242, 236)
      ..lineTo(242, 274)
      ..lineTo(148, 274)
      ..lineTo(148, 236)
      ..quadraticBezierTo(138, 222, 136, 192)
      ..close(),
    EstiloCabeca.cavaquinho: Path()
      ..moveTo(124, 50)
      ..lineTo(150, 30)
      ..quadraticBezierTo(178, 24, 195, 8)
      ..quadraticBezierTo(212, 24, 240, 30)
      ..lineTo(266, 50)
      ..lineTo(263, 180)
      ..quadraticBezierTo(260, 216, 242, 236)
      ..lineTo(242, 274)
      ..lineTo(148, 274)
      ..lineTo(148, 236)
      ..quadraticBezierTo(130, 216, 127, 180)
      ..close(),
    EstiloCabeca.violao: Path()
      ..moveTo(122, 40)
      ..quadraticBezierTo(126, 20, 150, 20)
      ..quadraticBezierTo(180, 20, 195, 34)
      ..quadraticBezierTo(210, 20, 240, 20)
      ..quadraticBezierTo(264, 20, 268, 40)
      ..lineTo(266, 208)
      ..quadraticBezierTo(262, 224, 242, 236)
      ..lineTo(242, 274)
      ..lineTo(148, 274)
      ..lineTo(148, 236)
      ..quadraticBezierTo(128, 224, 124, 208)
      ..close(),
    EstiloCabeca.viola: Path()
      ..moveTo(120, 52)
      ..quadraticBezierTo(116, 28, 138, 26)
      ..quadraticBezierTo(152, 25, 160, 36)
      ..quadraticBezierTo(176, 10, 195, 26)
      ..quadraticBezierTo(214, 10, 230, 36)
      ..quadraticBezierTo(238, 25, 252, 26)
      ..quadraticBezierTo(274, 28, 270, 52)
      ..lineTo(266, 200)
      ..quadraticBezierTo(262, 224, 242, 236)
      ..lineTo(242, 274)
      ..lineTo(148, 274)
      ..lineTo(148, 236)
      ..quadraticBezierTo(128, 224, 124, 200)
      ..close(),
    EstiloCabeca.baixo: Path()
      ..moveTo(116, 58)
      ..quadraticBezierTo(114, 26, 148, 22)
      ..lineTo(246, 12)
      ..quadraticBezierTo(280, 10, 278, 44)
      ..lineTo(272, 196)
      ..quadraticBezierTo(266, 226, 242, 238)
      ..lineTo(242, 274)
      ..lineTo(148, 274)
      ..lineTo(148, 238)
      ..quadraticBezierTo(124, 226, 118, 196)
      ..close(),
  };

  static final Path _veios = Path()
    ..moveTo(138, 20)
    ..cubicTo(150, 80, 134, 130, 150, 200)
    ..moveTo(166, 10)
    ..cubicTo(176, 70, 160, 120, 172, 210)
    ..moveTo(224, 10)
    ..cubicTo(216, 76, 234, 126, 220, 214)
    ..moveTo(254, 20)
    ..cubicTo(244, 84, 258, 134, 246, 196);

  // ----------------------------------------------------------- medidas ---

  /// Centro horizontal da chave da tarraxa.
  double _xChave(bool esquerda) {
    final x = switch (estilo) {
      EstiloCabeca.baixo => 97.0,
      EstiloCabeca.ukulele => 112.0,
      _ => 104.0,
    };
    return esquerda ? x : GeometriaCabeca.larguraDesenho - x;
  }

  /// Centro horizontal do pino (ou do rolo, no violão).
  double _xPino(bool esquerda) {
    final x = switch (estilo) {
      EstiloCabeca.violao => 159.0,
      EstiloCabeca.ukulele => 154.0,
      EstiloCabeca.baixo => 146.0,
      _ => 150.0,
    };
    return esquerda ? x : GeometriaCabeca.larguraDesenho - x;
  }

  double get _espessuraCorda => switch (estilo) {
    EstiloCabeca.baixo => 2.9,
    EstiloCabeca.violao => 1.9,
    EstiloCabeca.ukulele => 2.0,
    _ => 1.4,
  };

  /// Cordas graves (as primeiras) mais grossas.
  double _espessura(int indice) {
    if (cordas <= 1) return _espessuraCorda;
    final fator = switch (estilo) {
      EstiloCabeca.baixo || EstiloCabeca.violao => 0.45,
      _ => 0.2,
    };
    return _espessuraCorda * (1 + fator / 2 - fator * indice / (cordas - 1));
  }

  Color get _tomMadeira {
    final (tom, quanto) = switch (estilo) {
      EstiloCabeca.ukulele => (_koa, 0.55),
      EstiloCabeca.cavaquinho => (_jacaranda, 0.5),
      EstiloCabeca.violao => (madeira, 0.0),
      EstiloCabeca.viola => (_cedro, 0.5),
      EstiloCabeca.baixo => (_ebano, 0.55),
    };
    return Color.lerp(madeira, tom, quanto)!;
  }

  /// Altura de cada tarraxa da corda [indice]: uma, ou duas nos pares.
  List<double> _alturas(GeometriaCabeca geometria, int indice) {
    final y = geometria.yDesenho(indice);
    return _pares ? [y - 10, y + 10] : [y];
  }

  Color? _corDoEstado(int indice) => indice == ativa
      ? corAtiva
      : (afinadas.contains(indice) ? corAfinada : null);

  // ------------------------------------------------------------ desenho ---

  @override
  void paint(Canvas canvas, Size size) {
    final geometria = GeometriaCabeca(cordas: cordas, tamanho: size);
    canvas
      ..save()
      ..translate(geometria.deslocamentoX, 0)
      ..scale(geometria.escala);

    final contorno = _contornos[estilo]!;
    _eixos(canvas, geometria);
    _madeira(canvas, contorno, geometria);
    if (estilo == EstiloCabeca.violao) _fendas(canvas, geometria);
    if (estilo == EstiloCabeca.viola) _losango(canvas);
    _braco(canvas);
    _cordas(canvas, geometria);
    if (estilo == EstiloCabeca.violao) {
      _rolos(canvas, geometria);
    } else {
      _pinos(canvas, geometria);
    }
    _chaves(canvas, geometria);
    canvas.restore();
  }

  /// Eixos das tarraxas, por baixo da madeira.
  void _eixos(Canvas canvas, GeometriaCabeca geometria) {
    final eixo = Paint()..color = _metalBorda;
    final grossura = estilo == EstiloCabeca.baixo ? 9.0 : 6.0;
    for (var i = 0; i < cordas; i++) {
      final esquerda = geometria.ladoEsquerdo(i);
      final x1 = _xChave(esquerda);
      final x2 = _xPino(esquerda);
      for (final y in _alturas(geometria, i)) {
        canvas.drawRect(
          Rect.fromLTRB(
            math.min(x1, x2),
            y - grossura / 2,
            math.max(x1, x2),
            y + grossura / 2,
          ),
          eixo,
        );
      }
    }
  }

  void _madeira(Canvas canvas, Path contorno, GeometriaCabeca geometria) {
    final tom = _tomMadeira;
    final escura = Color.lerp(madeiraEscura, tom, 0.3)!;
    canvas
      ..drawPath(contorno, Paint()..color = tom)
      ..save()
      ..clipPath(contorno)
      ..drawRect(
        const Rect.fromLTRB(195, 0, 300, 274),
        Paint()..color = escura.withValues(alpha: 0.28),
      )
      ..drawPath(
        _veios,
        Paint()
          ..color = escura.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      )
      ..restore()
      ..drawPath(
        contorno,
        Paint()
          ..color = escura.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

    // O violão tem a placa das tarraxas por fora, de cada lado.
    if (estilo == EstiloCabeca.violao) {
      final (topo, base) = _faixa(geometria);
      final placa = Paint()..color = _metal;
      final borda = Paint()
        ..color = _metalBorda
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final x in [114.0, 266.0]) {
        final retangulo = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topo - 14, 10, base - topo + 28),
          const Radius.circular(3),
        );
        canvas
          ..drawRRect(retangulo, placa)
          ..drawRRect(retangulo, borda);
      }
    }
  }

  /// Altura da primeira e da última tarraxa.
  (double, double) _faixa(GeometriaCabeca geometria) {
    var topo = double.infinity;
    var base = double.negativeInfinity;
    for (var i = 0; i < cordas; i++) {
      final y = geometria.yDesenho(i);
      topo = math.min(topo, y);
      base = math.max(base, y);
    }
    return (topo, base);
  }

  /// As duas fendas do violão clássico.
  void _fendas(Canvas canvas, GeometriaCabeca geometria) {
    final (topo, base) = _faixa(geometria);
    final fenda = Paint()..color = _fenda;
    for (final x in [148.0, 220.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x, topo - 16, x + 22, base + 20),
          const Radius.circular(11),
        ),
        fenda,
      );
    }
  }

  /// O losango de madrepérola da viola.
  void _losango(Canvas canvas) {
    final losango = Path()
      ..moveTo(195, 34)
      ..lineTo(203, 46)
      ..lineTo(195, 58)
      ..lineTo(187, 46)
      ..close();
    canvas
      ..drawPath(losango, Paint()..color = _marfim)
      ..drawPath(
        losango,
        Paint()
          ..color = _marfimBorda
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  void _braco(Canvas canvas) {
    canvas
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
  }

  /// Do pino (ou do rolo) até a pestana, e dali pela escala.
  void _cordas(Canvas canvas, GeometriaCabeca geometria) {
    // Lado esquerdo e direito contados à parte, para espalhar as cordas ao
    // longo dos rolos do violão.
    final porLado = [geometria.esquerda, cordas - geometria.esquerda];
    for (var i = 0; i < cordas; i++) {
      final esquerda = geometria.ladoEsquerdo(i);
      final xn = cordas == 1 ? 195.0 : 158 + i * (74 / (cordas - 1));
      final cor = _corDoEstado(i);
      final espessura = _espessura(i) * (cor == null ? 1 : 1.3);
      final tinta = Paint()
        ..color = cor ?? _corda.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura;

      var xp = _xPino(esquerda);
      if (estilo == EstiloCabeca.violao) {
        // Cada corda se enrola num ponto diferente do rolo.
        final lado = esquerda ? i : i - geometria.esquerda;
        final quantas = porLado[esquerda ? 0 : 1];
        final passo = quantas <= 1 ? 0.0 : 12 / (quantas - 1);
        xp += (esquerda ? -6 + lado * passo : 6 - lado * passo);
      }
      final alturas = _alturas(geometria, i);
      for (var k = 0; k < alturas.length; k++) {
        // No par, a corda de cima (a oitava) é mais fina.
        final desvio = _pares ? (k == 0 ? -2.0 : 2.0) : 0.0;
        canvas.drawPath(
          Path()
            ..moveTo(xp, alturas[k])
            ..lineTo(xn + desvio, 236)
            ..lineTo(xn + desvio, 274),
          _pares && k == 0
              ? (Paint()
                  ..color = tinta.color
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = espessura * 0.7)
              : tinta,
        );
      }
    }
  }

  /// Os rolos brancos que atravessam as fendas do violão.
  void _rolos(Canvas canvas, GeometriaCabeca geometria) {
    final rolo = Paint()..color = _marfim;
    final borda = Paint()
      ..color = _marfimBorda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < cordas; i++) {
      final y = geometria.yDesenho(i);
      final x = geometria.ladoEsquerdo(i) ? 144.0 : 216.0;
      final retangulo = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y - 4.5, 30, 9),
        const Radius.circular(4.5),
      );
      canvas
        ..drawRRect(retangulo, rolo)
        ..drawRRect(retangulo, borda);
    }
  }

  void _pinos(Canvas canvas, GeometriaCabeca geometria) {
    final raio = switch (estilo) {
      EstiloCabeca.baixo => 9.0,
      EstiloCabeca.viola => 4.5,
      EstiloCabeca.ukulele => 5.0,
      _ => 6.0,
    };
    final metal = Paint()..color = _metal;
    final borda = Paint()
      ..color = _metalBorda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < cordas; i++) {
      final x = _xPino(geometria.ladoEsquerdo(i));
      for (final y in _alturas(geometria, i)) {
        final centro = Offset(x, y);
        canvas
          ..drawCircle(centro, raio, metal)
          ..drawCircle(centro, raio, borda);
        if (estilo == EstiloCabeca.baixo) {
          canvas.drawCircle(centro, raio * 0.45, borda);
        }
      }
    }
  }

  void _chaves(Canvas canvas, GeometriaCabeca geometria) {
    for (var i = 0; i < cordas; i++) {
      final esquerda = geometria.ladoEsquerdo(i);
      final x = _xChave(esquerda);
      final cor = _corDoEstado(i);
      for (final y in _alturas(geometria, i)) {
        _chave(canvas, Offset(x, y), esquerda, cor);
      }
    }
  }

  /// Uma chave de tarraxa. A borda fica também na ativa: no tema claro o
  /// creme dela sumiria contra o fundo.
  void _chave(Canvas canvas, Offset centro, bool esquerda, Color? cor) {
    final perolada = switch (estilo) {
      EstiloCabeca.violao || EstiloCabeca.ukulele || EstiloCabeca.viola => true,
      _ => false,
    };
    final preenchimento = Paint()..color = cor ?? (perolada ? _marfim : _metal);
    final borda = Paint()
      ..color = perolada && cor == null ? _marfimBorda : _metalBorda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final sentido = esquerda ? 1.0 : -1.0;

    // A bucha de metal entre a chave e a madeira.
    if (estilo != EstiloCabeca.baixo) {
      final bucha = Rect.fromCenter(
        center: centro.translate(sentido * 11, 0),
        width: 6,
        height: 9,
      );
      canvas
        ..drawRect(bucha, Paint()..color = _metal)
        ..drawRect(
          bucha,
          Paint()
            ..color = _metalBorda
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
    }

    switch (estilo) {
      case EstiloCabeca.ukulele:
        canvas
          ..drawCircle(centro, 9, preenchimento)
          ..drawCircle(centro, 9, borda);
      case EstiloCabeca.viola:
        final chave = Rect.fromCenter(center: centro, width: 14, height: 15);
        canvas
          ..drawOval(chave, preenchimento)
          ..drawOval(chave, borda);
      case EstiloCabeca.violao:
        final chave = Rect.fromCenter(center: centro, width: 18, height: 26);
        canvas
          ..drawOval(chave, preenchimento)
          ..drawOval(chave, borda);
      case EstiloCabeca.cavaquinho:
        // Borboleta: larga na ponta, estreita junto da bucha.
        final ponta = centro.dx - sentido * 5;
        final raiz = centro.dx + sentido * 7;
        final chave = Path()
          ..moveTo(raiz, centro.dy - 4)
          ..quadraticBezierTo(
            ponta,
            centro.dy - 16,
            ponta - sentido * 5,
            centro.dy - 9,
          )
          ..quadraticBezierTo(
            ponta - sentido * 8,
            centro.dy,
            ponta - sentido * 5,
            centro.dy + 9,
          )
          ..quadraticBezierTo(ponta, centro.dy + 16, raiz, centro.dy + 4)
          ..close();
        canvas
          ..drawPath(chave, preenchimento)
          ..drawPath(chave, borda);
      case EstiloCabeca.baixo:
        // Orelha grande, com o friso no meio.
        final chave = Rect.fromCenter(center: centro, width: 24, height: 34);
        canvas
          ..drawOval(chave, preenchimento)
          ..drawOval(chave, borda)
          ..drawLine(
            centro.translate(0, -10),
            centro.translate(0, 10),
            Paint()
              ..color = _metalBorda.withValues(alpha: 0.7)
              ..strokeWidth = 1.2,
          )
          ..drawRect(
            Rect.fromCenter(
              center: centro.translate(sentido * 14, 0),
              width: 8,
              height: 12,
            ),
            Paint()..color = _metalBorda,
          );
    }
  }

  @override
  bool shouldRepaint(PintorCabeca antigo) =>
      antigo.estilo != estilo ||
      antigo.cordas != cordas ||
      antigo.ativa != ativa ||
      !setEquals(antigo.afinadas, afinadas) ||
      antigo.madeira != madeira ||
      antigo.madeiraEscura != madeiraEscura ||
      antigo.corAtiva != corAtiva ||
      antigo.corAfinada != corAfinada;
}
