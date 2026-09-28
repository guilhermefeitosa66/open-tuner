import 'package:flutter/material.dart';

import '../../app/idioma.dart';
import '../../app/tema.dart';
import '../../dominio/afinacoes.dart';
import 'controlador_afinador.dart';
import 'desenhos.dart';
import 'nomes.dart';

/// Abre uma folha que sobe da barra inferior (RF-13): fecha ao escolher, ao
/// tocar fora, ao arrastar para baixo ou com o voltar.
Future<void> abrirFolha(
  BuildContext context, {
  required String titulo,
  String? subtitulo,
  required WidgetBuilder conteudo,
}) {
  final cores = context.cores;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: cores.superficie,
    barrierColor: cores.veu,
    barrierLabel: context.textos.fechar,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) =>
        Folha(titulo: titulo, subtitulo: subtitulo, conteudo: conteudo),
  );
}

/// Moldura comum das folhas: alça, título e o conteúdo, que rola se não
/// couber.
class Folha extends StatelessWidget {
  const Folha({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.conteudo,
  });

  final String titulo;
  final String? subtitulo;
  final WidgetBuilder conteudo;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: titulo,
      explicitChildNodes: true,
      child: Padding(
        // Embaixo, acima da barra de gestos do sistema.
        padding: EdgeInsets.fromLTRB(
          14,
          10,
          14,
          18 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: cores.linha,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontFamily: familiaDisplay,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: cores.texto,
                    ),
                  ),
                  if (subtitulo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        subtitulo!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cores.textoSecundario,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(child: Builder(builder: conteudo)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de instrumentos agrupada (RF-14).
class ListaInstrumentos extends StatelessWidget {
  const ListaInstrumentos({super.key, required this.controlador});

  final ControladorAfinador controlador;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final notacao = controlador.ajustes.notacao;
    final atual = controlador.instrumento;
    final filhos = <Widget>[];
    GrupoInstrumento? grupo;
    for (final instrumento in instrumentos) {
      if (instrumento.grupo != grupo) {
        grupo = instrumento.grupo;
        filhos.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            child: Semantics(
              header: true,
              child: Text(
                nomeGrupo(textos, grupo).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.88,
                  color: cores.textoSecundario,
                ),
              ),
            ),
          ),
        );
      }
      final ativo = instrumento.id == atual.id;
      final notas = notasDaAfinacao(textos, instrumento.padrao, notacao);
      filhos.add(
        _ItemLista(
          key: Key('instrumento-${instrumento.id}'),
          ativo: ativo,
          aoTocar: () {
            controlador.escolherInstrumento(instrumento);
            Navigator.of(context).pop();
          },
          conteudo: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ativo ? cores.accent : cores.superficieAlta,
                ),
                child: Text(
                  '${instrumento.cordas}',
                  style: TextStyle(
                    fontFamily: familiaDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: ativo ? cores.sobreAccent : cores.texto,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomeInstrumento(textos, instrumento.id),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cores.texto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instrumento.pares
                          ? '${quantidadeDeCordas(textos, instrumento)} · $notas'
                          : notas,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              if (ativo) Visto(cor: cores.accent),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: filhos,
    );
  }
}

/// Lista das afinações do instrumento atual, com as notas em fichas (RF-15).
class ListaAfinacoes extends StatelessWidget {
  const ListaAfinacoes({super.key, required this.controlador});

  final ControladorAfinador controlador;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = context.textos;
    final notacao = controlador.ajustes.notacao;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final afinacao in controlador.instrumento.afinacoes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ItemLista(
                key: Key('afinacao-${afinacao.id}'),
                ativo: afinacao.id == controlador.afinacao.id,
                borda: true,
                aoTocar: () {
                  controlador.escolherAfinacao(afinacao);
                  Navigator.of(context).pop();
                },
                conteudo: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomeAfinacao(textos, afinacao.id),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: cores.texto,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              for (final nota in afinacao.notas)
                                _Ficha(
                                  nota: rotuloNota(textos, nota, notacao),
                                  oitava: '${nota.oitava}',
                                  destacada:
                                      afinacao.id == controlador.afinacao.id,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (afinacao.id == controlador.afinacao.id) ...[
                      const SizedBox(width: 12),
                      Visto(cor: cores.accent),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({
    required this.nota,
    required this.oitava,
    required this.destacada,
  });

  final String nota;
  final String oitava;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Container(
      constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: destacada ? cores.fundo : cores.superficieAlta,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        widthFactor: 1,
        child: NotaComOitava(
          nota: nota,
          oitava: oitava,
          tamanho: 15,
          tamanhoOitava: 10,
          cor: cores.texto,
          opacidadeOitava: 0.75,
        ),
      ),
    );
  }
}

/// Linha tocável das listas: fundo realçado e, nas afinações, borda na cor de
/// destaque quando é a atual.
class _ItemLista extends StatelessWidget {
  const _ItemLista({
    super.key,
    required this.ativo,
    required this.aoTocar,
    required this.conteudo,
    this.borda = false,
  });

  final bool ativo;
  final VoidCallback aoTocar;
  final Widget conteudo;
  final bool borda;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final raio = BorderRadius.circular(borda ? 16 : 14);
    return Semantics(
      selected: ativo,
      button: true,
      child: Material(
        color: ativo ? cores.superficieAlta : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: raio,
          side: borda && ativo
              ? BorderSide(color: cores.accent, width: 2)
              : BorderSide(color: Colors.transparent, width: borda ? 2 : 0),
        ),
        child: InkWell(
          borderRadius: raio,
          onTap: aoTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: borda
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: conteudo,
            ),
          ),
        ),
      ),
    );
  }
}
