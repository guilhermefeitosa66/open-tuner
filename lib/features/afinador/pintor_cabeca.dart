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

  /// O violino: caixa de cravelhas aberta, a voluta no alto e cravelhas de
  /// ébano atravessando a caixa.
  violino,
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
      GrupoInstrumento.arco => EstiloCabeca.violino,
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
const _ebano = Color(0xFF231812);

/// Tom de cada madeira, misturado à madeira do tema.
const _koa = Color(0xFFB5773F);
const _jacaranda = Color(0xFF4A2616);
const _cedro = Color(0xFF9C5A2C);
const _bordo = Color(0xFFD8A560);
const _verniz = Color(0xFF9A4420);

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

  /// Todos saem do braço (de 148 a 242, pestana em 236) e abrem para cima,
  /// como a cabeça de verdade: estreita na pestana, larga no alto.
  static final Map<EstiloCabeca, Path> _contornos = {
    // Estilo Martin: lados retos, cantos marcados e uma ponta suave no meio.
    EstiloCabeca.ukulele: Path()
      ..moveTo(148, 274)
      ..lineTo(148, 236)
      ..lineTo(133, 62)
      ..quadraticBezierTo(131, 44, 147, 40)
      ..lineTo(183, 30)
      ..quadraticBezierTo(195, 25, 207, 30)
      ..lineTo(243, 40)
      ..quadraticBezierTo(259, 44, 257, 62)
      ..lineTo(242, 236)
      ..lineTo(242, 274)
      ..close(),
    // Ombros retos e um arco largo no meio.
    EstiloCabeca.cavaquinho: Path()
      ..moveTo(148, 274)
      ..lineTo(148, 236)
      ..lineTo(128, 60)
      ..quadraticBezierTo(126, 42, 143, 39)
      ..lineTo(160, 36)
      ..quadraticBezierTo(195, 6, 230, 36)
      ..lineTo(247, 39)
      ..quadraticBezierTo(264, 42, 262, 60)
      ..lineTo(242, 236)
      ..lineTo(242, 274)
      ..close(),
    // O clássico: lados quase paralelos, pontas nos cantos e o arco no meio.
    EstiloCabeca.violao: Path()
      ..moveTo(148, 274)
      ..lineTo(148, 236)
      ..quadraticBezierTo(127, 228, 125, 208)
      ..lineTo(121, 42)
      ..lineTo(124, 26)
      ..quadraticBezierTo(152, 38, 168, 30)
      ..quadraticBezierTo(181, 16, 195, 15)
      ..quadraticBezierTo(209, 16, 222, 30)
      ..quadraticBezierTo(238, 38, 266, 26)
      ..lineTo(269, 42)
      ..lineTo(265, 208)
      ..quadraticBezierTo(263, 228, 242, 236)
      ..lineTo(242, 274)
      ..close(),
    // A viola: ombros redondos e a ponta em chama no meio.
    EstiloCabeca.viola: Path()
      ..moveTo(148, 274)
      ..lineTo(148, 236)
      ..quadraticBezierTo(128, 226, 124, 204)
      ..lineTo(118, 52)
      ..quadraticBezierTo(118, 32, 137, 31)
      ..quadraticBezierTo(160, 32, 172, 24)
      ..quadraticBezierTo(186, 14, 195, 8)
      ..quadraticBezierTo(204, 14, 218, 24)
      ..quadraticBezierTo(230, 32, 253, 31)
      ..quadraticBezierTo(272, 32, 272, 52)
      ..lineTo(266, 204)
      ..quadraticBezierTo(262, 226, 242, 236)
      ..lineTo(242, 274)
      ..close(),
    // Larga, com o topo inclinado.
    EstiloCabeca.baixo: Path()
      ..moveTo(148, 274)
      ..lineTo(148, 238)
      ..quadraticBezierTo(124, 226, 118, 196)
      ..lineTo(116, 58)
      ..quadraticBezierTo(114, 26, 148, 22)
      ..lineTo(246, 12)
      ..quadraticBezierTo(280, 10, 278, 44)
      ..lineTo(272, 196)
      ..quadraticBezierTo(266, 226, 242, 238)
      ..lineTo(242, 274)
      ..close(),
    // O violino: a caixa estreita, que afina para cima, e a voluta redonda.
    EstiloCabeca.violino: Path.combine(
      PathOperation.union,
      Path()
        ..moveTo(148, 274)
        ..lineTo(148, 236)
        ..quadraticBezierTo(152, 222, 154, 204)
        ..lineTo(160, 70)
        ..lineTo(230, 70)
        ..lineTo(236, 204)
        ..quadraticBezierTo(238, 222, 242, 236)
        ..lineTo(242, 274)
        ..close(),
      Path()..addOval(Rect.fromCircle(center: _centroVoluta, radius: 30)),
    ),
  };

  static const _centroVoluta = Offset(195, 44);

  // ----------------------------------------------------------- medidas ---

  /// Centro horizontal da chave da tarraxa.
  double _xChave(bool esquerda) {
    final x = switch (estilo) {
      EstiloCabeca.baixo => 97.0,
      EstiloCabeca.ukulele => 113.0,
      EstiloCabeca.violino => 124.0,
      _ => 104.0,
    };
    return esquerda ? x : GeometriaCabeca.larguraDesenho - x;
  }

  /// Centro horizontal do pino (ou do rolo, no violão).
  double _xPino(bool esquerda) {
    final x = switch (estilo) {
      EstiloCabeca.violao => 159.0,
      EstiloCabeca.ukulele => 153.0,
      EstiloCabeca.baixo => 146.0,
      EstiloCabeca.violino => 182.0,
      _ => 150.0,
    };
    return esquerda ? x : GeometriaCabeca.larguraDesenho - x;
  }

  double get _espessuraCorda => switch (estilo) {
    EstiloCabeca.baixo => 2.9,
    EstiloCabeca.violao => 1.9,
    EstiloCabeca.ukulele => 2.0,
    EstiloCabeca.violino => 1.3,
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
      EstiloCabeca.cavaquinho => (_jacaranda, 0.3),
      EstiloCabeca.violao => (madeira, 0.0),
      EstiloCabeca.viola => (_cedro, 0.5),
      EstiloCabeca.baixo => (_bordo, 0.6),
      EstiloCabeca.violino => (_verniz, 0.55),
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
    if (estilo == EstiloCabeca.violino) _caixaCravelhas(canvas, geometria);
    _braco(canvas);
    _cordas(canvas, geometria);
    if (estilo == EstiloCabeca.violao) {
      _rolos(canvas, geometria);
    } else if (estilo != EstiloCabeca.violino) {
      _pinos(canvas, geometria);
    }
    _chaves(canvas, geometria);
    canvas.restore();
  }

  /// Eixos das tarraxas, por baixo da madeira.
  void _eixos(Canvas canvas, GeometriaCabeca geometria) {
    final eixo = Paint()
      ..color = estilo == EstiloCabeca.violino ? _ebano : _metalBorda;
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

  /// Flat: a madeira chapada, a metade direita um tom abaixo e o contorno.
  void _madeira(Canvas canvas, Path contorno, GeometriaCabeca geometria) {
    final tom = _tomMadeira;
    final escura = Color.lerp(madeiraEscura, tom, 0.25)!;
    canvas
      ..drawPath(contorno, Paint()..color = tom)
      ..save()
      ..clipPath(contorno)
      ..drawRect(
        const Rect.fromLTRB(195, 0, 300, 274),
        Paint()..color = escura.withValues(alpha: 0.22),
      )
      ..restore()
      ..drawPath(
        contorno,
        Paint()
          ..color = escura
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
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
      ..moveTo(195, 36)
      ..lineTo(202, 47)
      ..lineTo(195, 58)
      ..lineTo(188, 47)
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

  /// A caixa aberta do violino, com as cravelhas de lado a lado, e o
  /// caracol da voluta.
  void _caixaCravelhas(Canvas canvas, GeometriaCabeca geometria) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(170, 80, 220, 226),
        const Radius.circular(12),
      ),
      Paint()..color = _fenda,
    );
    final cravelha = Paint()..color = Color.lerp(_ebano, _marfimBorda, 0.25)!;
    for (var i = 0; i < cordas; i++) {
      final y = geometria.yDesenho(i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(162, y - 3.5, 228, y + 3.5),
          const Radius.circular(3.5),
        ),
        cravelha,
      );
    }

    // O caracol: uma espiral que fecha no olho da voluta.
    final espiral = Path();
    const voltas = 2.25;
    const passos = 60;
    for (var k = 0; k <= passos; k++) {
      final t = k / passos;
      final angulo = -math.pi / 2 + t * voltas * 2 * math.pi;
      final raio = 25 * (1 - t) + 4 * t;
      final ponto =
          _centroVoluta + Offset(math.cos(angulo), math.sin(angulo)) * raio;
      if (k == 0) {
        espiral.moveTo(ponto.dx, ponto.dy);
      } else {
        espiral.lineTo(ponto.dx, ponto.dy);
      }
    }
    canvas
      ..drawPath(
        espiral,
        Paint()
          ..color = Color.lerp(madeiraEscura, _tomMadeira, 0.25)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(_centroVoluta, 3.5, Paint()..color = madeiraEscura);
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
      // No violino as cordas chegam à pestana bem juntas.
      final xn = estilo == EstiloCabeca.violino
          ? (cordas == 1 ? 195.0 : 174 + i * (42 / (cordas - 1)))
          : (cordas == 1 ? 195.0 : 158 + i * (74 / (cordas - 1)));
      final cor = _corDoEstado(i);
      final espessura = _espessura(i) * (cor == null ? 1 : 1.3);
      final tinta = Paint()
        ..color = cor ?? _corda.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura;

      // No violino a corda desce reta da cravelha, pelo meio da caixa.
      var xp = estilo == EstiloCabeca.violino ? xn : _xPino(esquerda);
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
    if (estilo != EstiloCabeca.baixo && estilo != EstiloCabeca.violino) {
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
          ..drawCircle(centro, 10, preenchimento)
          ..drawCircle(centro, 10, borda)
          ..drawCircle(
            centro,
            4,
            Paint()..color = _marfimBorda.withValues(alpha: 0.35),
          );
      case EstiloCabeca.viola:
        final chave = Rect.fromCenter(center: centro, width: 14, height: 15);
        canvas
          ..drawOval(chave, preenchimento)
          ..drawOval(chave, borda);
      case EstiloCabeca.violino:
        // Cravelha de ébano: a cabeça em gota, o colar junto da caixa e o
        // olho de madrepérola.
        final ebano = Paint()..color = cor ?? _ebano;
        final contorno = Paint()
          ..color = _marfimBorda
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        final colar = Rect.fromCenter(
          center: centro.translate(sentido * 14, 0),
          width: 6,
          height: 10,
        );
        final chave = Rect.fromCenter(center: centro, width: 18, height: 28);
        canvas
          ..drawRect(colar, ebano)
          ..drawRect(colar, contorno)
          ..drawOval(chave, ebano)
          ..drawOval(chave, contorno)
          ..drawCircle(centro, 2.6, Paint()..color = _marfim);
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
