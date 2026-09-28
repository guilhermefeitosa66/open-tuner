import 'package:flutter/material.dart';

import '../../app/idioma.dart';
import '../../app/tema.dart';

/// Tela principal: o afinador.
///
/// Por enquanto só o esqueleto visual. A captura de áudio, a detecção de
/// frequência e o ponteiro entram depois.
class TelaAfinador extends StatelessWidget {
  const TelaAfinador({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _Titulo(),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Linha central: a referência de "afinado" do ponteiro.
                  Container(width: 2, color: cores.grade),
                  Container(
                    color: cores.fundo,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      context.textos.toqueQualquerCorda,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cores.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _BarraInferior(),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo();

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final estilo = Theme.of(context).textTheme.headlineSmall;
    // O nome é uma palavra só, "OpenTuner": as duas metades se distinguem pela
    // cor e pelo peso, não por espaço. Não se traduz.
    return Align(
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: estilo,
          children: [
            TextSpan(
              text: 'Open',
              style: TextStyle(color: cores.texto, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: 'Tuner',
              style: TextStyle(
                color: cores.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior();

  @override
  Widget build(BuildContext context) {
    final textos = context.textos;
    return Container(
      color: context.cores.superficie,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _BotaoOpcao(
              rotulo: textos.instrumento,
              valor:
                  '${textos.instrumentoUkulele} · ${textos.quantidadeCordas(4)}',
              // A escolha de instrumento ainda não existe.
              aoTocar: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BotaoOpcao(
              rotulo: textos.afinacao,
              valor: '${textos.afinacaoPadrao} · G C E A',
              // A escolha de afinação ainda não existe.
              aoTocar: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão grande da barra inferior: rótulo pequeno em cima, valor embaixo.
class _BotaoOpcao extends StatelessWidget {
  const _BotaoOpcao({
    required this.rotulo,
    required this.valor,
    required this.aoTocar,
  });

  final String rotulo;
  final String valor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textos = Theme.of(context).textTheme;
    return Material(
      color: cores.superficieAlta,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rotulo,
                style: textos.labelMedium?.copyWith(
                  color: cores.textoSecundario,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textos.titleMedium?.copyWith(
                  color: cores.texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
