import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/idioma.dart';
import '../../app/tema.dart';
import '../../dados/ajustes.dart';
import '../../dados/preferencias.dart';
import '../../dominio/estado_corda.dart';
import '../afinador/desenhos.dart';

/// Conteúdo da folha de ajustes (RF-17): tema, nome das notas, precisão,
/// referência do Lá e tela ligada.
class ConteudoAjustes extends StatelessWidget {
  const ConteudoAjustes({
    super.key,
    required this.ajustes,
    required this.versao,
  });

  final Ajustes ajustes;
  final String versao;

  @override
  Widget build(BuildContext context) {
    final textos = context.textos;
    final cores = context.cores;
    return ListenableBuilder(
      listenable: ajustes,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Secao(
              titulo: textos.tema,
              child: _Segmentos<TemaEscolhido>(
                chave: 'tema',
                valor: ajustes.tema,
                opcoes: {
                  TemaEscolhido.sistema: textos.temaSistema,
                  TemaEscolhido.claro: textos.temaClaro,
                  TemaEscolhido.escuro: textos.temaEscuro,
                },
                aoEscolher: (valor) => ajustes.tema = valor,
              ),
            ),
            const SizedBox(height: 18),
            _Secao(
              titulo: textos.nomeDasNotas,
              child: _Segmentos<Notacao>(
                chave: 'notacao',
                valor: ajustes.notacao,
                opcoes: {
                  Notacao.letras: textos.notasLetras,
                  Notacao.solfejo: textos.notasSolfejo,
                },
                aoEscolher: (valor) => ajustes.notacao = valor,
              ),
            ),
            const SizedBox(height: 18),
            _Secao(
              titulo: textos.precisao,
              child: _Segmentos<Precisao>(
                chave: 'precisao',
                valor: ajustes.precisao,
                opcoes: {
                  Precisao.normal: textos.precisaoNormal,
                  Precisao.fina: textos.precisaoFina,
                },
                aoEscolher: (valor) => ajustes.precisao = valor,
              ),
            ),
            const SizedBox(height: 18),
            _ReferenciaLa(ajustes: ajustes),
            const SizedBox(height: 14),
            _TelaLigada(ajustes: ajustes),
            const SizedBox(height: 14),
            Text(
              textos.sobre(versao),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cores.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.cores.texto,
            ),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Controle segmentado do protótipo: a opção escolhida em madeira.
class _Segmentos<T> extends StatelessWidget {
  const _Segmentos({
    required this.chave,
    required this.valor,
    required this.opcoes,
    required this.aoEscolher,
  });

  final String chave;
  final T valor;
  final Map<T, String> opcoes;
  final ValueChanged<T> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cores.superficieAlta,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: opcao, value: rotulo) in opcoes.entries)
            Expanded(
              child: Semantics(
                selected: opcao == valor,
                button: true,
                inMutuallyExclusiveGroup: true,
                child: Material(
                  color: opcao == valor ? cores.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    key: Key('$chave-${(opcao as Enum).name}'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => aoEscolher(opcao),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Text(
                            rotulo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: opcao == valor
                                  ? cores.sobreAccent
                                  : cores.texto,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReferenciaLa extends StatelessWidget {
  const _ReferenciaLa({required this.ajustes});

  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final idioma = Localizations.localeOf(context).toLanguageTag();
    final valor = textos.frequenciaHz(
      NumberFormat('0', idioma).format(ajustes.a4),
    );

    Widget botao(String simbolo, String rotulo, int passo, bool ativo) =>
        Semantics(
          button: true,
          enabled: ativo,
          label: rotulo,
          excludeSemantics: true,
          child: Material(
            color: cores.superficieAlta,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: Key('a4-$passo'),
              borderRadius: BorderRadius.circular(12),
              onTap: ativo ? () => ajustes.a4 = ajustes.a4 + passo : null,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: Text(
                    simbolo,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: ativo
                          ? cores.texto
                          : cores.textoSecundario.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textos.referenciaLa,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cores.texto,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                textos.referenciaLaDescricao,
                style: TextStyle(fontSize: 13, color: cores.textoSecundario),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        botao('−', textos.diminuirReferencia, -1, ajustes.a4 > a4Minimo),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 76),
          child: Semantics(
            liveRegion: true,
            child: Text(
              valor,
              key: const Key('a4-valor'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: cores.texto,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        botao('+', textos.aumentarReferencia, 1, ajustes.a4 < a4Maximo),
      ],
    );
  }
}

class _TelaLigada extends StatelessWidget {
  const _TelaLigada({required this.ajustes});

  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    return Semantics(
      toggled: ajustes.telaLigada,
      button: true,
      child: InkWell(
        key: const Key('tela-ligada'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => ajustes.telaLigada = !ajustes.telaLigada,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      textos.manterTelaLigada,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cores.texto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      textos.manterTelaLigadaDescricao,
                      style: TextStyle(
                        fontSize: 13,
                        color: cores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TrilhoChave(ligada: ajustes.telaLigada),
            ],
          ),
        ),
      ),
    );
  }
}
