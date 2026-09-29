import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/idioma.dart';
import '../../app/tema.dart';
import 'controlador_afinador.dart';
import 'desenhos.dart';
import 'nomes.dart';
import 'pintor_cabeca.dart';

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

/// A cabeça desenhada ([PintorCabeca]) e os botões das cordas por cima.
/// Escuta o controlador: muda quando a corda alvo, as marcas ou a afinação
/// mudam, não a cada leitura.
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
            // Trocar de instrumento funde um desenho no outro.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (atual, anteriores) => Stack(
                    fit: StackFit.expand,
                    children: [...anteriores, ?atual],
                  ),
                  child: RepaintBoundary(
                    key: ValueKey(controlador.instrumento.id),
                    child: CustomPaint(
                      painter: PintorCabeca(
                        estilo: estiloDaCabeca(controlador.instrumento),
                        cordas: notas.length,
                        ativa: ativa,
                        afinadas: controlador.afinadas,
                        madeira: cores.madeira,
                        madeiraEscura: cores.madeiraEscura,
                        corAtiva: escuro ? cores.texto : cores.sobreAccent,
                        corAfinada: cores.afinado,
                      ),
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
            // Recomeçar: só aparece com alguma corda marcada, junto das
            // marcas que ele limpa, sobre o braço.
            Positioned(
              left: 0,
              right: 0,
              bottom: 8 * geometria.escala,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (filho, animacao) => FadeTransition(
                    opacity: animacao,
                    child: ScaleTransition(scale: animacao, child: filho),
                  ),
                  child: controlador.afinadas.isEmpty
                      ? const SizedBox.shrink()
                      : BotaoRecomecar(
                          key: const Key('recomecar'),
                          aoTocar: controlador.limparMarcas,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// O botão que limpa as marcas de corda afinada: uma pílula de alto
/// contraste sobre a madeira, com o ícone de recomeçar.
class BotaoRecomecar extends StatelessWidget {
  const BotaoRecomecar({super.key, required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    return Semantics(
      button: true,
      // O rótulo começa pelo texto visível ("toque em Recomeçar", por voz);
      // a dica diz o que ele faz.
      label: textos.recomecar,
      hint: textos.recomecarDescricao,
      onTap: aoTocar,
      excludeSemantics: true,
      child: Material(
        color: cores.texto,
        shape: const StadiumBorder(),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 18, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restart_alt_rounded, size: 20, color: cores.fundo),
                  const SizedBox(width: 6),
                  Text(
                    textos.recomecar,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cores.fundo,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
      // O excludeSemantics tira a semântica do InkWell, e com ela a ação de
      // toque: sem o onTap aqui, o Acesso com interruptor e o Voice Access
      // não acham o botão.
      onTap: () => controlador.tocarCorda(indice),
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: ativa
                  ? cores.texto
                  : (afinada
                        ? Color.lerp(cores.superficieAlta, cores.afinado, 0.28)
                        : cores.superficieAlta),
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
