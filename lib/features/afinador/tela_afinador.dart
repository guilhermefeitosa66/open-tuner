import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../app/idioma.dart';
import '../../app/tema.dart';
import '../../audio/fonte_audio.dart';
import '../../audio/tocador.dart';
import '../../dados/ajustes.dart';
import '../../dados/preferencias.dart';
import '../ajustes/folha_ajustes.dart';
import 'cabeca_instrumento.dart';
import 'controlador_afinador.dart';
import 'desenhos.dart';
import 'folhas.dart';
import 'grafico.dart';
import 'nomes.dart';

/// A tela do afinador, que é o aplicativo inteiro (seção 1 dos requisitos).
///
/// Cria o [ControladorAfinador] e liga o microfone ao ciclo de vida: escuta
/// só com o app em primeiro plano (RF-01).
class TelaAfinador extends StatefulWidget {
  const TelaAfinador({
    super.key,
    required this.fonte,
    required this.preferencias,
    required this.ajustes,
    required this.versao,
    this.definirTelaLigada,
    this.vibrar,
    this.tocador,
  });

  final FonteAudio fonte;
  final Preferencias preferencias;
  final Ajustes ajustes;
  final String versao;
  final DefinirTelaLigada? definirTelaLigada;
  final Future<void> Function()? vibrar;
  final Tocador? tocador;

  @override
  State<TelaAfinador> createState() => _TelaAfinadorState();
}

class _TelaAfinadorState extends State<TelaAfinador> {
  late final ControladorAfinador _controlador;
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    _controlador = ControladorAfinador(
      fonte: widget.fonte,
      preferencias: widget.preferencias,
      ajustes: widget.ajustes,
      definirTelaLigada: widget.definirTelaLigada,
      vibrar: widget.vibrar,
      tocador: widget.tocador,
    );
    // O pedido de permissão do sistema deixa o app "inativo" por um
    // instante, sem ir para segundo plano: só a pausa de verdade solta o
    // microfone, e a volta reconfere a permissão (que pode ter mudado nas
    // configurações).
    _ciclo = AppLifecycleListener(
      onResume: () => unawaited(_controlador.retomar()),
      onPause: () => unawaited(_controlador.pausar()),
    );
    unawaited(_controlador.retomar());
  }

  @override
  void dispose() {
    _ciclo.dispose();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_controlador, widget.ajustes]),
          builder: (context, _) => Column(
            children: [
              _Topo(
                controlador: _controlador,
                aoAbrirAjustes: () => _abrirAjustes(context),
              ),
              Expanded(child: _AreaAfinador(controlador: _controlador)),
              _BarraInferior(controlador: _controlador),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirAjustes(BuildContext context) {
    unawaited(
      abrirFolha(
        context,
        titulo: context.textos.ajustes,
        conteudo: (_) =>
            ConteudoAjustes(ajustes: widget.ajustes, versao: widget.versao),
      ),
    );
  }
}

/// Topo: a marca, a chave Auto e o botão de ajustes.
class _Topo extends StatelessWidget {
  const _Topo({required this.controlador, required this.aoAbrirAjustes});

  final ControladorAfinador controlador;
  final VoidCallback aoAbrirAjustes;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 6, 2),
      child: Row(
        children: [
          ExcludeSemantics(
            child: CustomPaint(
              size: const Size(24, 26),
              painter: PintorPalheta(cor: cores.accent, corOnda: cores.fundo),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: familiaDisplay,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    height: 1,
                    color: cores.texto,
                  ),
                  // O nome é uma palavra só, "OpenTuner": as duas metades se
                  // distinguem pela cor e pelo peso. Não se traduz.
                  children: [
                    const TextSpan(text: 'Open'),
                    TextSpan(
                      text: 'Tuner',
                      style: TextStyle(
                        color: cores.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
          ),
          Semantics(
            toggled: controlador.auto,
            button: true,
            label: textos.autoDescricao,
            excludeSemantics: true,
            child: InkWell(
              key: const Key('auto'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => controlador.definirAuto(!controlador.auto),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        textos.auto,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.96,
                          color: cores.textoSecundario,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TrilhoChave(ligada: controlador.auto),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('abrir-ajustes'),
            tooltip: textos.ajustes,
            onPressed: aoAbrirAjustes,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            icon: IconeAjustes(cor: cores.textoSecundario),
          ),
        ],
      ),
    );
  }
}

/// O gráfico em cima e a cabeça do instrumento embaixo, com o gráfico
/// encolhendo primeiro quando a tela é baixa.
class _AreaAfinador extends StatelessWidget {
  const _AreaAfinador({required this.controlador});

  final ControladorAfinador controlador;

  /// Altura mínima do gráfico antes de a cabeça começar a encolher.
  static const _graficoMinimo = 200.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final largura = restricoes.maxWidth;
        final altura = restricoes.maxHeight;
        final escala = largura / 390;
        final cordas = controlador.afinacao.notas.length;

        // A cabeça quer 274 px no desenho de 390; cede até a escala em que
        // os botões ainda ficam a 48 dp um do outro, nunca abaixo dela.
        final cabecaMinima =
            GeometriaCabeca.alturaDesenho *
            GeometriaCabeca.escalaMinima(cordas);
        final cabecaIdeal = math.max(
          GeometriaCabeca.alturaDesenho * escala,
          cabecaMinima,
        );
        // O alto da cabeça é vazio: o gráfico entra 26 px nele.
        const entrada = 26 / GeometriaCabeca.alturaDesenho;
        final alturaCabeca = ((altura - _graficoMinimo) / (1 - entrada)).clamp(
          cabecaMinima,
          cabecaIdeal,
        );
        final sobreposicao = alturaCabeca * entrada;
        final alturaGrafico = math.max(
          0.0,
          altura - alturaCabeca + sobreposicao,
        );
        final geometria = GeometriaGrafico(Size(largura, alturaGrafico));

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: alturaGrafico,
              child: _Grafico(
                controlador: controlador,
                geometria: geometria,
                margemInferior: sobreposicao,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: alturaCabeca,
              child: CabecaInstrumento(controlador: controlador),
            ),
          ],
        );
      },
    );
  }
}

class _Grafico extends StatelessWidget {
  const _Grafico({
    required this.controlador,
    required this.geometria,
    required this.margemInferior,
  });

  final ControladorAfinador controlador;
  final GeometriaGrafico geometria;

  /// Faixa de baixo que a cabeça do instrumento cobre.
  final double margemInferior;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final permitido = controlador.permissao == EstadoPermissao.concedida;
    final pedir =
        controlador.permissao == EstadoPermissao.pendente ||
        controlador.permissao == EstadoPermissao.negadaDeVez;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: PintorGrade(
                corGrade: cores.gradeSutil,
                corLinha: cores.linha,
              ),
              foregroundPainter: PintorRastro(
                historico: controlador.historico,
                precisao: controlador.ajustes.precisao,
                corAfinado: cores.afinado,
                corPerto: cores.perto,
                corLonge: cores.longe,
              ),
            ),
          ),
        ),
        // O rastro esmaece perto da cabeça do instrumento.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: geometria.alturaEsmaecer,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cores.fundo.withValues(alpha: 0), cores.fundo],
                ),
              ),
            ),
          ),
        ),
        if (!pedir)
          Positioned.fill(child: MarcasBemolSustenido(geometria: geometria)),
        if (pedir)
          Positioned.fill(
            top: 8,
            bottom: margemInferior,
            child: PainelPermissao(controlador: controlador),
          )
        else ...[
          if (permitido)
            Positioned.fill(
              child: LinhaAfinada(
                leitura: controlador.leitura,
                geometria: geometria,
              ),
            ),
          if (permitido)
            Positioned.fill(
              child: NotaAlvo(controlador: controlador, geometria: geometria),
            ),
          Positioned.fill(
            child: RepaintBoundary(
              child: IndicadorDesvio(
                leitura: controlador.leitura,
                geometria: geometria,
              ),
            ),
          ),
          _Anunciador(leitura: controlador.leitura),
        ],
      ],
    );
  }
}

/// Anuncia pelo leitor de tela o estado da corda (frouxa, apertada, afinada)
/// só quando muda, e no máximo uma vez por segundo.
class _Anunciador extends StatefulWidget {
  const _Anunciador({required this.leitura});

  final ValueListenable<LeituraTela> leitura;

  @override
  State<_Anunciador> createState() => _AnunciadorState();
}

class _AnunciadorState extends State<_Anunciador> {
  static const _intervalo = Duration(seconds: 1);

  final Stopwatch _desdeUltimo = Stopwatch();
  Direcao? _anunciada;

  @override
  void initState() {
    super.initState();
    widget.leitura.addListener(_aoMudar);
  }

  @override
  void didUpdateWidget(_Anunciador antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.leitura != widget.leitura) {
      antigo.leitura.removeListener(_aoMudar);
      widget.leitura.addListener(_aoMudar);
    }
  }

  @override
  void dispose() {
    widget.leitura.removeListener(_aoMudar);
    super.dispose();
  }

  void _aoMudar() {
    if (!mounted || !MediaQuery.of(context).accessibleNavigation) return;
    final direcao = direcaoDe(widget.leitura.value);
    if (direcao == null || direcao == _anunciada) return;
    if (_desdeUltimo.isRunning && _desdeUltimo.elapsed < _intervalo) return;
    _anunciada = direcao;
    _desdeUltimo
      ..reset()
      ..start();
    final textos = context.textos;
    final mensagem = switch (direcao) {
      Direcao.apertar => textos.aperteACorda,
      Direcao.afrouxar => textos.afrouxeACorda,
      Direcao.afinada => textos.afinada,
    };
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        mensagem,
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Barra inferior: Instrumento e Afinação, e nada mais (RF-13).
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.controlador});

  final ControladorAfinador controlador;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final instrumento = controlador.instrumento;
    final notacao = controlador.ajustes.notacao;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficie,
        border: Border(top: BorderSide(color: cores.grade)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        // Os dois botões com a mesma altura, a do mais alto.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BotaoBarra(
                  key: const Key('botao-instrumento'),
                  rotulo: textos.instrumento,
                  valor: nomeInstrumento(textos, instrumento.id),
                  detalhe: quantidadeDeCordas(textos, instrumento),
                  aoTocar: () => abrirFolha(
                    context,
                    titulo: textos.instrumento,
                    conteudo: (_) =>
                        ListaInstrumentos(controlador: controlador),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BotaoBarra(
                  key: const Key('botao-afinacao'),
                  rotulo: textos.afinacao,
                  valor: nomeAfinacao(textos, controlador.afinacao.id),
                  detalhe: notasDaAfinacao(
                    textos,
                    controlador.afinacao,
                    notacao,
                  ),
                  aoTocar: () => abrirFolha(
                    context,
                    titulo: textos.afinacao,
                    subtitulo: nomeInstrumento(textos, instrumento.id),
                    conteudo: (_) => ListaAfinacoes(controlador: controlador),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão grande da barra: rótulo pequeno, valor e detalhe, e a seta.
class _BotaoBarra extends StatelessWidget {
  const _BotaoBarra({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.detalhe,
    required this.aoTocar,
  });

  final String rotulo;
  final String valor;
  final String detalhe;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Material(
      color: cores.superficieAlta,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rotulo.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.88,
                        color: cores.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      valor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cores.texto,
                      ),
                    ),
                    Text(
                      detalhe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 24,
                color: cores.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
