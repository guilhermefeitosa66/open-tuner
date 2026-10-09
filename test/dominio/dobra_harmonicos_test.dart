import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/afinacoes.dart';
import 'package:open_tuner/dominio/detector.dart';
import 'package:open_tuner/dominio/dobra_harmonicos.dart';
import 'package:open_tuner/dominio/escolha_corda.dart';
import 'package:open_tuner/dominio/nota.dart';

import 'sinais.dart';

const taxa = 44100;

List<double> alvosDe(String instrumento) => [
  for (final nota in instrumentoPorId(instrumento).padrao.notas)
    nota.frequencia(),
];

/// Uma leitura do detector.
Leitura leitura(double frequencia, double confianca) =>
    Leitura(frequencia: frequencia, confianca: confianca);

/// Firma a nota [frequencia] com [vezes] leituras confiantes, em energia
/// constante [rms].
void firmar(
  DobraHarmonicos dobra,
  double frequencia, {
  int vezes = 5,
  double confianca = 0.99,
  double rms = 0.1,
}) {
  for (var i = 0; i < vezes; i++) {
    dobra.corrigir(leitura(frequencia, confianca), rms: rms);
  }
}

/// A frequência corrigida de uma leitura; falha se a correção der null.
double corrigida(
  DobraHarmonicos dobra,
  double frequencia,
  double confianca, {
  double rms = 0.1,
}) {
  final resultado = dobra.corrigir(leitura(frequencia, confianca), rms: rms);
  expect(resultado, isNotNull);
  return resultado!.frequencia;
}

/// Uma análise do [sinal] no ritmo do app.
typedef Analise = ({Leitura? bruta, Leitura? corrigida, int? corda});

/// Passa [sinal] pelo detector como o ControladorAfinador (25 análises por
/// segundo, com a entrada recomendada), pela [DobraHarmonicos] e pela
/// [EscolhaCorda] no modo automático.
List<Analise> analisar(List<double> sinal, Instrumento instrumento) {
  final alvos = [
    for (final nota in instrumento.padrao.notas) nota.frequencia(),
  ];
  final detector = DetectorFrequencia(
    taxaAmostragem: taxa,
    frequenciaMinima: instrumento.frequenciaMinima * 0.8,
    frequenciaMaxima: instrumento.frequenciaMaxima * 1.3,
  );
  final dobra = DobraHarmonicos(alvos: alvos, pares: instrumento.pares);
  final escolha = EscolhaCorda(alvos: alvos, pares: instrumento.pares);
  final entrada = detector.tamanhoEntradaRecomendada;
  final n = detector.tamanhoJanela;
  final analises = <Analise>[];
  for (var fim = entrada; fim <= sinal.length; fim += taxa ~/ 25) {
    final janela = sinal.sublist(fim - entrada, fim);
    var energia = 0.0;
    for (var i = entrada - n; i < entrada; i++) {
      energia += janela[i] * janela[i];
    }
    final bruta = detector.analisar(janela);
    final certa = dobra.corrigir(bruta, rms: math.sqrt(energia / n));
    final corda = certa == null ? null : escolha.escolher(certa.frequencia);
    analises.add((bruta: bruta, corrigida: certa, corda: corda));
  }
  return analises;
}

/// Corda "realista" de [frequencia] Hz, com [segundos] de som.
List<double> cordaReal(double frequencia, double segundos, int semente) =>
    cordaInarmonica(frequencia, taxa, segundos, 6e-5, math.Random(semente));

void main() {
  // Violão padrão: E2 A2 D3 G3 B3 E4.
  final violao = alvosDe('violao');
  const e2 = 82.41, a2 = 110.0, d3 = 146.83, b3 = 246.94;

  group('leituras', () {
    test('2º e 3º harmônicos com confiança menor voltam à fundamental', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      expect(corrigida(dobra, 2 * e2 * 1.002, 0.88), closeTo(e2 * 1.002, 0.01));
      expect(dobra.ultimoFator, 2);
      expect(corrigida(dobra, 3 * e2, 0.87), closeTo(e2, 0.01));
      expect(dobra.ultimoFator, 3);
      expect(corrigida(dobra, e2, 0.99), e2);
      expect(dobra.ultimoFator, 1);
    });

    test('a oitava de baixo com confiança menor sobe para a nota', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, d3);
      expect(corrigida(dobra, d3 / 2, 0.87), closeTo(d3, 0.01));
      expect(dobra.ultimoFator, 0.5);
    });

    test('a própria nota passa como veio e a âncora acompanha a tarraxa', () {
      final dobra = DobraHarmonicos(alvos: violao);
      // Sobe 60 cents, 2 por leitura: a âncora segue e o harmônico continua
      // reconhecido no fim.
      for (var i = 0; i <= 30; i++) {
        final f = e2 * math.pow(2, (2 * i - 60) / 1200);
        expect(corrigida(dobra, f, 0.99), f);
      }
      expect(dobra.ancora, closeTo(e2, 0.01));
      expect(corrigida(dobra, 2 * e2, 0.88), closeTo(e2, 0.01));
    });

    test('harmônico longe das cordas é dobrado mesmo com palhetada e '
        'confiança alta', () {
      // O A2 tocado de novo e lido só na oitava (220 Hz, que não é corda do
      // violão), com confiança até maior que a de antes.
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, a2, confianca: 0.9, rms: 0.02);
      for (var i = 0; i < 10; i++) {
        expect(
          corrigida(dobra, 220.4, 0.96, rms: 0.13),
          closeTo(110.2, 0.01),
          reason: 'leitura ${i + 1}',
        );
      }
    });

    test('palhetada nova com confiança parecida numa corda que é múltiplo da '
        'anterior é troca de verdade', () {
      // B3 é quase exatamente 3 × E2.
      final dobra = DobraHarmonicos(alvos: violao);
      final escolha = EscolhaCorda(alvos: violao);
      firmar(dobra, e2);
      escolha.escolher(e2);
      for (var i = 0; i < 5; i++) {
        final f = corrigida(dobra, b3, 0.985, rms: 0.3 - 0.01 * i);
        expect(f, b3, reason: 'leitura ${i + 1}');
        escolha.escolher(f);
      }
      expect(escolha.atual, 4);
    });

    test('sem palhetada nova a corda não muda para um harmônico', () {
      final dobra = DobraHarmonicos(alvos: violao);
      final escolha = EscolhaCorda(alvos: violao);
      firmar(dobra, e2);
      escolha.escolher(e2);
      for (var i = 0; i < 40; i++) {
        final f = corrigida(dobra, b3, 0.93);
        expect(f, closeTo(b3 / 3, 0.01), reason: 'leitura ${i + 1}');
        expect(escolha.escolher(f), 0);
      }
    });

    test('suspeita tão confiante quanto a nota, por muito tempo e sem a nota '
        'no meio, acaba valendo', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      for (var i = 0; i < dobra.analisesSemConfirmar; i++) {
        expect(corrigida(dobra, b3, 0.99), closeTo(b3 / 3, 0.01));
      }
      expect(corrigida(dobra, b3, 0.99), b3);
      expect(corrigida(dobra, b3, 0.99), b3);
    });

    test('uma leitura da própria nota no meio renova a suspeita', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      for (var i = 0; i < 3 * dobra.analisesSemConfirmar; i++) {
        final esperada = i % 10 == 9 ? e2 : b3 / 3;
        final f = i % 10 == 9 ? e2 : b3;
        expect(corrigida(dobra, f, 0.99), closeTo(esperada, 0.01));
      }
    });

    test('a âncora que nasceu na oitava de baixo é desfeita pelas cordas', () {
      // Primeira leitura depois do silêncio na sub-harmônica do D3 (73 Hz não
      // é corda do violão); a seguinte, no próprio D3, vale como veio.
      final dobra = DobraHarmonicos(alvos: violao);
      expect(corrigida(dobra, d3 / 2, 0.87), d3 / 2);
      expect(corrigida(dobra, d3, 0.92), d3);
      expect(dobra.ancora, d3);
      expect(corrigida(dobra, d3 / 2, 0.87), closeTo(d3, 0.01));
    });

    test('uma leitura solta de outra nota, pouco confiante, não desfaz a '
        'nota', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      expect(corrigida(dobra, 120, 0.85, rms: 0.3), 120);
      expect(dobra.ancora, e2);
      expect(corrigida(dobra, 3 * e2 * 1.003, 0.87), closeTo(e2 * 1.003, 0.01));
    });

    test('outra nota com confiança parecida vira a nova âncora', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      expect(corrigida(dobra, d3, 0.98, rms: 0.3), d3);
      expect(dobra.ancora, d3);
    });

    test('outra nota pouco confiante que se repete vira a nova âncora', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      expect(corrigida(dobra, d3, 0.9), d3);
      expect(dobra.ancora, e2);
      expect(corrigida(dobra, d3 * 1.001, 0.9), d3 * 1.001);
      expect(dobra.ancora, d3 * 1.001);
    });

    test('silêncio longo faz esquecer a nota', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      for (var i = 0; i < dobra.analisesParaEsquecer - 1; i++) {
        expect(dobra.corrigir(null, rms: 0.001), isNull);
      }
      expect(dobra.ancora, e2, reason: 'uma pausa curta não esquece');
      dobra.corrigir(null, rms: 0.001);
      expect(dobra.ancora, isNull);
      expect(corrigida(dobra, 2 * e2, 0.9), 2 * e2);
    });

    test('pausa curta entre palhetadas da mesma corda mantém a nota', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, d3, rms: 0.05);
      for (var i = 0; i < 20; i++) {
        dobra.corrigir(null, rms: 0.002);
      }
      // A nova palhetada começa na sub-harmônica, com pouca confiança.
      expect(corrigida(dobra, d3 / 2, 0.87, rms: 0.2), closeTo(d3, 0.01));
    });

    test('viola caipira: a oitava de cima do par passa como veio; o 3º '
        'harmônico, não', () {
      final viola = instrumentoPorId('viola-caipira');
      final alvos = alvosDe('viola-caipira');
      final b2 = alvos[0];
      final dobra = DobraHarmonicos(alvos: alvos, pares: viola.pares);
      firmar(dobra, b2);
      expect(corrigida(dobra, 2 * b2, 0.9), 2 * b2);
      expect(dobra.ultimoFator, 1);
      expect(corrigida(dobra, 2 * b2, 0.99), 2 * b2);
      expect(corrigida(dobra, 3 * b2, 0.88), closeTo(b2, 0.01));
      expect(dobra.ultimoFator, 3);
    });

    test('trocarAlvos mantém a nota; reiniciar esquece', () {
      final dobra = DobraHarmonicos(alvos: violao);
      firmar(dobra, e2);
      final dropD = alvosDe('violao')..[0] = 73.42;
      dobra.trocarAlvos(dropD);
      expect(dobra.alvos, dropD);
      expect(dobra.ancora, e2);
      dobra.reiniciar();
      expect(dobra.ancora, isNull);
      expect(corrigida(dobra, 2 * e2, 0.9), 2 * e2);
    });

    test('null continua null', () {
      final dobra = DobraHarmonicos(alvos: violao);
      expect(dobra.corrigir(null, rms: 0), isNull);
      firmar(dobra, e2);
      expect(dobra.corrigir(null, rms: 0.1), isNull);
    });
  });

  group('com o detector', () {
    final instrumentoViolao = instrumentoPorId('violao');

    for (final (nome, f, indice) in [('E2', e2, 0), ('A2', a2, 1)]) {
      test('$nome com harmônicos pares fortes e a fundamental sumindo: a '
          'leitura corrigida fica na fundamental', () {
        final analises = analisar(
          cordaParesFortes(f, taxa, 2.0),
          instrumentoViolao,
        );
        // O caso existe: o detector sozinho passa a ler a oitava de cima.
        final naOitava = analises
            .where(
              (a) =>
                  a.bruta != null &&
                  centsEntre(a.bruta!.frequencia, 2 * f).abs() < 30,
            )
            .length;
        expect(naOitava, greaterThan(20));
        for (final (i, analise) in analises.indexed) {
          final certa = analise.corrigida;
          expect(certa, isNotNull, reason: 'análise $i');
          expect(
            centsEntre(certa!.frequencia, f).abs(),
            lessThan(20),
            reason: 'análise $i: ${analise.bruta}',
          );
          expect(analise.corda, indice, reason: 'análise $i');
        }
      });
    }

    for (final (id, f, indice) in [
      ('ukulele', 440.0, 3),
      ('cavaquinho', 587.33, 3),
      ('cavaquinho', 293.66, 0),
      ('violino', 196.0, 0),
      ('violino', 659.26, 3),
    ]) {
      test('$id: nota limpa de $f Hz não cai uma oitava', () {
        final analises = analisar(cordaReal(f, 1.5, 3), instrumentoPorId(id));
        var lidas = 0;
        for (final (i, analise) in analises.indexed) {
          if (analise.bruta == null) continue;
          lidas++;
          expect(
            analise.corrigida!.frequencia,
            analise.bruta!.frequencia,
            reason: 'análise $i',
          );
          expect(analise.corda, indice, reason: 'análise $i');
        }
        expect(lidas, greaterThan(30));
      });
    }

    for (final (id, grave, aguda, indice) in [
      ('violao', e2, b3, 4), // B3 ≈ 3 × E2
      ('violao', e2, 329.63, 5), // E4 = 4 × E2
      ('violao', a2, 329.63, 5), // E4 ≈ 3 × A2
      ('cavaquinho', 293.66, 587.33, 3), // D5 = 2 × D4
      ('violino', 196.0, 293.66, 1), // D4 ≈ 1,5 × G3
      ('violino', 440.0, 659.26, 3), // E5 ≈ 1,5 × A4
    ]) {
      test('$id: abafar a corda de $grave Hz e tocar a de $aguda Hz troca a '
          'corda', () {
        final sinal = somar(
          tocada(cordaReal(grave, 1.2, 3), taxa, inicio: 0, fim: 1, total: 2),
          tocada(cordaReal(aguda, 1.0, 5), taxa, inicio: 1, total: 2),
        );
        final analises = analisar(sinal, instrumentoPorId(id));
        // Nas últimas 15 análises (de uns 0,45 s depois da palhetada em
        // diante), a corda nova já está escolhida e as leituras dela passam
        // como vieram.
        final depois = analises.sublist(analises.length - 15);
        for (final (i, analise) in depois.indexed) {
          expect(analise.corda, indice, reason: 'análise ${i + 1} do fim');
          expect(
            analise.corrigida!.frequencia,
            analise.bruta!.frequencia,
            reason: 'análise ${i + 1} do fim',
          );
        }
      });
    }
  });
}
