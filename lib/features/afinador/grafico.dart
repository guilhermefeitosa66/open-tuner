import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/idioma.dart';
import '../../app/tema.dart';
import '../../audio/fonte_audio.dart';
import '../../dominio/estado_corda.dart';
import 'controlador_afinador.dart';
import 'desenhos.dart';
import 'historico_leituras.dart';
import 'nomes.dart';

/// Medidas da área do gráfico, a partir do desenho de referência (390 px de
/// largura): tudo na horizontal escala pela largura, e o rastro estica ou
/// encolhe para caber na altura que sobrar.
@immutable
class GeometriaGrafico {
  const GeometriaGrafico(this.tamanho);

  final Size tamanho;

  double get largura => tamanho.width;
  double get altura => tamanho.height;

  /// Escala horizontal em relação aos 390 px do desenho.
  double get escala => largura / 390;
  double get centroX => largura / 2;

  /// ±50 cents vão até ±150 px da linha no desenho de 390.
  static const limiteCents = 50.0;

  double xDe(double cents) =>
      centroX + cents.clamp(-limiteCents, limiteCents) * 3 * escala;

  double get diametroIndicador => 60 * escala;
  double get centroIndicadorY => 44 * escala;

  /// Ponta do triângulo embaixo do indicador.
  double get pontaIndicador => 81 * escala;

  /// Onde começa o rastro (a leitura mais nova).
  double get inicioRastro => 86 * escala;

  /// Distância vertical entre duas leituras do rastro.
  double passoRastro(int capacidade) =>
      math.max(1.0, (altura - inicioRastro - 6 * escala) / (capacidade - 1));

  double get diametroNotaAlvo => 64 * escala;

  /// A nota alvo fica pouco abaixo do meio, mas nunca em cima do indicador.
  double get centroNotaAlvoY => math.max(
    altura * 0.52,
    pontaIndicador + 20 * escala + diametroNotaAlvo / 2,
  );

  /// Altura do esmaecimento do rastro, embaixo.
  double get alturaEsmaecer => math.min(118 * escala, altura * 0.4);
}

/// Grade sutil e a linha do centro. Só redesenha ao mudar de tamanho ou tema.
class PintorGrade extends CustomPainter {
  const PintorGrade({required this.corGrade, required this.corLinha});

  final Color corGrade;
  final Color corLinha;

  @override
  void paint(Canvas canvas, Size size) {
    final geometria = GeometriaGrafico(size);
    final passo = 26 * geometria.escala;
    final grade = Paint()
      ..color = corGrade
      ..strokeWidth = 1;
    for (var x = geometria.centroX % passo; x <= size.width; x += passo) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grade);
    }
    for (var y = 0.0; y <= size.height; y += passo) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }
    canvas.drawLine(
      Offset(geometria.centroX, 0),
      Offset(geometria.centroX, size.height),
      Paint()
        ..color = corLinha
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(PintorGrade antigo) =>
      antigo.corGrade != corGrade || antigo.corLinha != corLinha;
}

/// O rastro (RF-07): cada leitura é um ponto que rola para baixo, ligado ao
/// seguinte, com a cor do estado do trecho. Um null é um vão.
///
/// Redesenha só quando o [historico] avisa, sem reconstruir widget nenhum.
class PintorRastro extends CustomPainter {
  PintorRastro({
    required this.historico,
    required this.precisao,
    required this.corAfinado,
    required this.corPerto,
    required this.corLonge,
  }) : super(repaint: historico);

  final HistoricoLeituras historico;
  final Precisao precisao;
  final Color corAfinado;
  final Color corPerto;
  final Color corLonge;

  @override
  void paint(Canvas canvas, Size size) {
    final geometria = GeometriaGrafico(size);
    final passo = geometria.passoRastro(historico.capacidade);
    final afinado = Path();
    final perto = Path();
    final longe = Path();
    for (var i = 0; i < historico.length - 1; i++) {
      final a = historico[i];
      final b = historico[i + 1];
      if (a == null || b == null) continue;
      final media = (a.abs() + b.abs()) / 2;
      final trecho = switch (classificar(media, precisao)) {
        EstadoCorda.afinada => afinado,
        EstadoCorda.perto => perto,
        EstadoCorda.longe => longe,
      };
      final y = geometria.inicioRastro + i * passo;
      trecho
        ..moveTo(geometria.xDe(a), y)
        ..lineTo(geometria.xDe(b), y + passo);
    }
    Paint traco(Color cor) => Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * geometria.escala
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(longe, traco(corLonge))
      ..drawPath(perto, traco(corPerto))
      ..drawPath(afinado, traco(corAfinado));
  }

  @override
  bool shouldRepaint(PintorRastro antigo) =>
      antigo.historico != historico ||
      antigo.precisao != precisao ||
      antigo.corAfinado != corAfinado ||
      antigo.corPerto != corPerto ||
      antigo.corLonge != corLonge;
}

/// Cor do estado: verde, amarelo ou laranja; neutra quando ociosa.
Color corDoEstado(CoresOpenTuner cores, EstadoCorda? estado) =>
    switch (estado) {
      EstadoCorda.afinada => cores.afinado,
      EstadoCorda.perto => cores.perto,
      EstadoCorda.longe => cores.longe,
      null => cores.textoSecundario,
    };

/// O que a leitura pede para a mão fazer.
enum Direcao { apertar, afrouxar, afinada }

Direcao? direcaoDe(LeituraTela leitura) {
  if (leitura.ehOciosa) return null;
  if (leitura.estado == EstadoCorda.afinada) return Direcao.afinada;
  return leitura.cents < 0 ? Direcao.apertar : Direcao.afrouxar;
}

/// Cents com sinal, como no protótipo: "−22", "+11" (sinal de menos de
/// verdade, não hífen).
String centsComSinal(double cents) {
  final inteiro = cents.round();
  if (inteiro == 0) return '0';
  return '${inteiro < 0 ? '−' : '+'}${inteiro.abs()}';
}

/// O indicador (RF-06): o círculo com os cents, a ponta embaixo e a pílula
/// com o que fazer. A posição acompanha a leitura com uma animação curta,
/// para o ponteiro deslizar em vez de saltar.
class IndicadorDesvio extends StatelessWidget {
  const IndicadorDesvio({
    super.key,
    required this.leitura,
    required this.geometria,
  });

  final ValueListenable<LeituraTela> leitura;
  final GeometriaGrafico geometria;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LeituraTela>(
      valueListenable: leitura,
      builder: (context, atual, _) {
        final direcao = direcaoDe(atual);
        final alvoX = direcao == null || direcao == Direcao.afinada
            ? geometria.centroX
            : geometria.xDe(atual.cents);
        return TweenAnimationBuilder<double>(
          tween: Tween(end: alvoX),
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          builder: (context, x, _) =>
              _Indicador(leitura: atual, x: x, geometria: geometria),
        );
      },
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.leitura,
    required this.x,
    required this.geometria,
  });

  final LeituraTela leitura;
  final double x;
  final GeometriaGrafico geometria;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final escala = geometria.escala;
    final direcao = direcaoDe(leitura);
    final cor = corDoEstado(cores, leitura.estado);
    final diametro = geometria.diametroIndicador;

    final textoPilula = switch (direcao) {
      Direcao.apertar => textos.aperteACorda,
      Direcao.afrouxar => textos.afrouxeACorda,
      Direcao.afinada => textos.afinada,
      null => null,
    };
    final rotulo = switch (direcao) {
      null => textos.esperandoCorda,
      Direcao.afinada => textos.afinada,
      _ => '${textos.desvioCents(leitura.cents.round())}, $textoPilula',
    };

    final Widget conteudo = switch (direcao) {
      null => const SizedBox.shrink(),
      Direcao.afinada => Visto(
        cor: cores.afinado,
        tamanho: 26 * escala,
        espessura: 2.8,
      ),
      _ => Text(
        centsComSinal(leitura.cents),
        key: const Key('cents'),
        maxLines: 1,
        style: TextStyle(
          fontSize: 19 * escala,
          fontWeight: FontWeight.w800,
          height: 1,
          color: cores.texto,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    };

    final larguraPilulaMaxima = direcao == Direcao.afrouxar
        ? x - 40 * escala - 8
        : geometria.largura - (x + 40 * escala) - 8;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // A ponta embaixo do círculo.
        Positioned(
          left: x - 7 * escala,
          top: geometria.pontaIndicador - 9 * escala,
          child: CustomPaint(
            size: Size(14 * escala, 9 * escala),
            painter: _PintorPonta(cor),
          ),
        ),
        Positioned(
          key: const Key('indicador'),
          left: x - diametro / 2,
          top: geometria.centroIndicadorY - diametro / 2,
          width: diametro,
          height: diametro,
          child: Semantics(
            label: rotulo,
            container: true,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cores.fundo,
                  border: Border.all(color: cor, width: 3 * escala),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(6 * escala),
                    child: FittedBox(fit: BoxFit.scaleDown, child: conteudo),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (textoPilula != null && larguraPilulaMaxima > 40)
          Positioned(
            top: geometria.centroIndicadorY - 17 * escala,
            left: direcao == Direcao.afrouxar ? null : x + 40 * escala,
            right: direcao == Direcao.afrouxar
                ? geometria.largura - (x - 40 * escala)
                : null,
            child: ExcludeSemantics(
              child: _Pilula(
                texto: textoPilula,
                direcao: direcao!,
                escala: escala,
                larguraMaxima: larguraPilulaMaxima,
              ),
            ),
          ),
      ],
    );
  }
}

class _PintorPonta extends CustomPainter {
  const _PintorPonta(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = cor,
    );
  }

  @override
  bool shouldRepaint(_PintorPonta antigo) => antigo.cor != cor;
}

class _Pilula extends StatelessWidget {
  const _Pilula({
    required this.texto,
    required this.direcao,
    required this.escala,
    required this.larguraMaxima,
  });

  final String texto;
  final Direcao direcao;
  final double escala;
  final double larguraMaxima;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final cor = direcao == Direcao.afinada ? cores.afinado : cores.texto;
    final seta = switch (direcao) {
      Direcao.apertar => Icons.arrow_upward_rounded,
      Direcao.afrouxar => Icons.arrow_downward_rounded,
      Direcao.afinada => null,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: larguraMaxima),
      child: Container(
        height: 34 * escala,
        padding: EdgeInsets.fromLTRB(
          (seta == null ? 14 : 11) * escala,
          0,
          14 * escala,
          0,
        ),
        decoration: BoxDecoration(
          color: cores.superficieAlta,
          borderRadius: BorderRadius.circular(17 * escala),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (seta != null) ...[
                Icon(seta, size: 17 * escala, color: cor),
                SizedBox(width: 6 * escala),
              ],
              Text(
                texto,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15 * escala,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: cor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A nota alvo sobre a linha do centro e, embaixo, a frequência medida
/// (RF-10). Ociosa, dá lugar ao convite para tocar uma corda (RF-12).
class NotaAlvo extends StatelessWidget {
  const NotaAlvo({
    super.key,
    required this.controlador,
    required this.geometria,
  });

  final ControladorAfinador controlador;
  final GeometriaGrafico geometria;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LeituraTela>(
      valueListenable: controlador.leitura,
      builder: (context, leitura, _) {
        final corda = leitura.corda;
        if (leitura.ehOciosa || corda == null) {
          return _ConviteTocar(geometria: geometria);
        }
        return _NotaEFrequencia(
          controlador: controlador,
          corda: corda,
          frequencia: leitura.frequencia,
          geometria: geometria,
        );
      },
    );
  }
}

class _NotaEFrequencia extends StatelessWidget {
  const _NotaEFrequencia({
    required this.controlador,
    required this.corda,
    required this.frequencia,
    required this.geometria,
  });

  final ControladorAfinador controlador;
  final int corda;
  final double frequencia;
  final GeometriaGrafico geometria;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final escala = geometria.escala;
    final notas = controlador.afinacao.notas;
    if (corda >= notas.length) return const SizedBox.shrink();
    final nota = notas[corda];
    final ajustes = controlador.ajustes;
    final rotulo = rotuloNota(textos, nota, ajustes.notacao);
    final idioma = Localizations.localeOf(context).toLanguageTag();
    final hz = textos.frequenciaHz(
      NumberFormat('0.0', idioma).format(frequencia),
    );
    final diametro = geometria.diametroNotaAlvo;
    final centroY = geometria.centroNotaAlvoY;

    return Stack(
      children: [
        Positioned(
          left: geometria.centroX - diametro / 2,
          top: centroY - diametro / 2,
          width: diametro,
          height: diametro,
          child: Semantics(
            label: textos.notaAlvo('$rotulo${nota.oitava}'),
            excludeSemantics: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cores.superficie,
                border: Border.all(color: cores.linha, width: 2),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6 * escala),
                    child: NotaComOitava(
                      nota: rotulo,
                      oitava: '${nota.oitava}',
                      tamanho: 27 * escala,
                      tamanhoOitava: 14 * escala,
                      cor: cores.texto,
                      opacidadeOitava: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: centroY + diametro / 2 + 6 * escala,
          child: Center(
            // Fundo para o rastro não passar por cima dos números.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cores.fundo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * escala,
                  vertical: 2 * escala,
                ),
                child: Text(
                  hz,
                  key: const Key('frequencia'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13 * escala,
                    fontWeight: FontWeight.w600,
                    color: cores.textoSecundario,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConviteTocar extends StatelessWidget {
  const _ConviteTocar({required this.geometria});

  final GeometriaGrafico geometria;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final escala = geometria.escala;
    return Stack(
      children: [
        Positioned(
          left: 16,
          right: 16,
          top: geometria.centroNotaAlvoY + 6 * escala,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 22 * escala,
                vertical: 14 * escala,
              ),
              decoration: BoxDecoration(
                color: cores.superficieAlta,
                borderRadius: BorderRadius.circular(26 * escala),
              ),
              child: Text(
                context.textos.toqueQualquerCorda,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * escala,
                  fontWeight: FontWeight.w600,
                  color: cores.texto,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Os símbolos ♭ e ♯ nas bordas de cima do gráfico.
class MarcasBemolSustenido extends StatelessWidget {
  const MarcasBemolSustenido({super.key, required this.geometria});

  final GeometriaGrafico geometria;

  @override
  Widget build(BuildContext context) {
    final escala = geometria.escala;
    final estilo = TextStyle(
      fontFamily: familiaDisplay,
      fontSize: 30 * escala,
      height: 1,
      color: context.cores.textoSecundario,
    );
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: Stack(
          children: [
            Positioned(
              left: 22 * escala,
              top: 20 * escala,
              child: Text('♭', style: estilo),
            ),
            Positioned(
              right: 22 * escala,
              top: 20 * escala,
              child: Text('♯', style: estilo),
            ),
          ],
        ),
      ),
    );
  }
}

/// O painel que toma o lugar do indicador quando falta a permissão do
/// microfone (RF-19).
class PainelPermissao extends StatelessWidget {
  const PainelPermissao({super.key, required this.controlador});

  final ControladorAfinador controlador;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final negada = controlador.permissao == EstadoPermissao.negadaDeVez;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cores.grade),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                negada ? Icons.mic_off_rounded : Icons.mic_none_rounded,
                color: cores.accent,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                textos.permissaoTitulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: familiaDisplay,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: cores.texto,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                negada ? textos.permissaoNegada : textos.permissaoTexto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: cores.textoSecundario,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cores.accent,
                  foregroundColor: cores.sobreAccent,
                  minimumSize: const Size(48, 48),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: negada
                    ? controlador.abrirConfiguracoes
                    : controlador.pedirPermissao,
                child: Text(
                  negada ? textos.abrirConfiguracoes : textos.permissaoPermitir,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
