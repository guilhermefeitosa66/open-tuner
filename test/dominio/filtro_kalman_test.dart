import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/estado_corda.dart';
import 'package:open_tuner/dominio/filtro_kalman.dart';

/// Intervalo entre análises no app (25 por segundo).
const intervalo = 0.04;

/// Ruído gaussiano reprodutível (Box-Muller).
double gauss(math.Random aleatorio) =>
    math.sqrt(-2 * math.log(1 - aleatorio.nextDouble())) *
    math.cos(2 * math.pi * aleatorio.nextDouble());

/// Um trecho de análises: a leitura em cents (null = rejeitada pelo
/// detector) e o RMS da janela.
typedef Analise = ({double? cents, double rms});

/// [n] análises com a mesma energia [rms] e leituras dadas por [cents] (em
/// função do índice).
List<Analise> trecho(
  int n,
  double? Function(int i) cents, {
  double rms = 0.1,
}) => [for (var i = 0; i < n; i++) (cents: cents(i), rms: rms)];

/// Passa as análises pelo filtro, 25 por segundo a partir de [inicio], e
/// devolve a exibição depois de cada uma.
List<Exibicao?> passar(
  FiltroKalman filtro,
  List<Analise> analises, {
  double inicio = 0,
}) => [
  for (var i = 0; i < analises.length; i++)
    filtro.adicionar(
      tempo: inicio + i * intervalo,
      cents: analises[i].cents,
      rms: analises[i].rms,
    ),
];

/// Quantas vezes o rótulo (✓ ou o número) muda numa sequência de exibições.
int trocasDeRotulo(List<Exibicao?> exibicoes) {
  var trocas = 0;
  String? anterior;
  for (final e in exibicoes) {
    final rotulo = e == null ? null : (e.afinada ? '✓' : '${e.numero}');
    if (anterior != null && rotulo != anterior) trocas++;
    anterior = rotulo;
  }
  return trocas;
}

/// RMS da variação do ponteiro de uma exibição para a seguinte.
double tremor(List<Exibicao?> exibicoes) {
  var soma = 0.0;
  var n = 0;
  for (var i = 1; i < exibicoes.length; i++) {
    final d = exibicoes[i]!.ponteiro - exibicoes[i - 1]!.ponteiro;
    soma += d * d;
    n++;
  }
  return math.sqrt(soma / n);
}

void main() {
  test('a primeira leitura vai direto para o ponteiro e o número', () {
    final filtro = FiltroKalman();
    expect(filtro.atual, isNull);
    final e = filtro.adicionar(tempo: 0, cents: -12.3, rms: 0.1)!;
    expect(e.ponteiro, closeTo(-12.3, 1e-9));
    expect(e.numero, -12);
    expect(e.afinada, isFalse);
    expect(filtro.atual, e);
  });

  test('leitura rejeitada pelo detector não muda a exibição', () {
    final filtro = FiltroKalman();
    final antes = filtro.adicionar(tempo: 0, cents: 7, rms: 0.1);
    expect(filtro.adicionar(tempo: 0.04, cents: null, rms: 0.1), antes);
    expect(filtro.adicionar(tempo: 0.08, cents: null, rms: 0.1), antes);
  });

  test('corda parada: número e ✓ parados, ponteiro sem tremor', () {
    // Tremor natural de ±3 cents (desvio padrão 2,5) em volta de 3 cents,
    // dentro da tolerância normal.
    final aleatorio = math.Random(7);
    final filtro = FiltroKalman();
    final exibicoes = passar(
      filtro,
      trecho(150, (_) => 3 + 2.5 * gauss(aleatorio)),
    );
    final depois = exibicoes.sublist(25);
    // As leituras cruas pulam uns 3,5 cents de uma análise para a outra.
    expect(tremor(depois), lessThan(0.4));
    expect(trocasDeRotulo(depois), 0);
    expect(depois.every((e) => e!.afinada), isTrue);
  });

  test('corda parada fora da tolerância: o número quase não troca', () {
    final aleatorio = math.Random(11);
    final filtro = FiltroKalman();
    final exibicoes = passar(
      filtro,
      trecho(250, (_) => -18 + 3 * gauss(aleatorio)),
    );
    final depois = exibicoes.sublist(25);
    // 9 segundos: no máximo uma troca a cada 3 segundos.
    expect(trocasDeRotulo(depois), lessThanOrEqualTo(3));
    for (final e in depois) {
      expect(e!.afinada, isFalse);
      expect(e.numero, inInclusiveRange(-21, -15));
    }
  });

  test('segue a tarraxa sem atraso perceptível', () {
    // Parada em −30 por 1 s, depois a tarraxa sobe 20 cents por segundo.
    final aleatorio = math.Random(3);
    double verdade(int i) => i < 25 ? -30 : -30 + 20 * (i - 25) * intervalo;
    final filtro = FiltroKalman();
    final exibicoes = passar(
      filtro,
      trecho(60, (i) => verdade(i) + 2 * gauss(aleatorio)),
    );
    // O ponteiro fica a menos de 5 cents da verdade (o que a tarraxa anda em
    // 0,25 s) desde o começo da rampa e, com a velocidade aprendida, a menos
    // de 3 (0,15 s) depois de 1 s de rampa.
    for (var i = 30; i < 60; i++) {
      expect(exibicoes[i]!.ponteiro, closeTo(verdade(i), 5), reason: 'i=$i');
    }
    for (var i = 50; i < 60; i++) {
      expect(exibicoes[i]!.ponteiro, closeTo(verdade(i), 3), reason: 'i=$i');
    }
  });

  test('com a tarraxa girando, o número anda numa direção só', () {
    final aleatorio = math.Random(5);
    final filtro = FiltroKalman();
    final exibicoes = passar(
      filtro,
      trecho(75, (i) => -30 + 15 * i * intervalo + 1.5 * gauss(aleatorio)),
    );
    final numeros = [for (final e in exibicoes.skip(10)) e!.numero];
    for (var i = 1; i < numeros.length; i++) {
      expect(numeros[i], greaterThanOrEqualTo(numeros[i - 1]));
    }
    expect(numeros.last, greaterThan(numeros.first + 20));
  });

  test('a marca de afinada entra na tolerância e sai só depois da folga', () {
    // Precisão normal: entra dentro de 5 cents, sai acima de 8.
    final filtro = FiltroKalman();
    var inicio = 0.0;
    Exibicao ultima(double cents) {
      final e = passar(filtro, trecho(50, (_) => cents), inicio: inicio);
      inicio += 50 * intervalo;
      return e.last!;
    }

    expect(ultima(4).afinada, isTrue);
    expect(ultima(7).afinada, isTrue, reason: 'dentro da folga de saída');
    expect(ultima(9).afinada, isFalse);
    expect(ultima(6).afinada, isFalse, reason: 'fora da tolerância de entrada');
    expect(ultima(-4.5).afinada, isTrue);
  });

  test('na precisão fina a histerese encolhe junto com a tolerância', () {
    // Fina: entra dentro de 2 cents, sai acima de 3,2.
    final filtro = FiltroKalman(precisao: Precisao.fina);
    var inicio = 0.0;
    Exibicao ultima(double cents) {
      final e = passar(filtro, trecho(50, (_) => cents), inicio: inicio);
      inicio += 50 * intervalo;
      return e.last!;
    }

    // O modelo de velocidade passa um pouco do degrau antes de assentar
    // (uns 20% dele): os degraus aqui são pequenos o bastante.
    expect(ultima(1.5).afinada, isTrue);
    expect(ultima(2.7).afinada, isTrue);
    expect(ultima(3.6).afinada, isFalse);
    expect(ultima(2.5).afinada, isFalse);
    // A precisão pode mudar com o filtro rodando: 2,5 cabe na normal.
    filtro.precisao = Precisao.normal;
    expect(ultima(2.5).afinada, isTrue);
  });

  test('a marca não aparece antes de o ataque de uma corda nova passar', () {
    final filtro = FiltroKalman();
    final exibicoes = passar(filtro, trecho(10, (_) => 0));
    // tempoAtaque = 0,15 s: as análises em 0, 0,04, 0,08 e 0,12 s não têm ✓.
    expect(
      [for (final e in exibicoes) e!.afinada],
      [false, false, false, false, true, true, true, true, true, true],
    );
  });

  test('o ataque agudo da palhetada não mexe no ponteiro', () {
    List<Exibicao?> tocar(FiltroKalman filtro) {
      final aleatorio = math.Random(23);
      // A corda soando afinada, com um tremor de ±4 cents, até calar.
      passar(filtro, trecho(50, (_) => 0.5 + 4 * gauss(aleatorio)));
      passar(filtro, trecho(8, (_) => null, rms: 0.003), inicio: 2);
      // Palhetada: a energia sobe e as leituras saem 10 cents agudas por
      // 0,12 s (dentro do tremor, não são rejeitadas), depois assentam.
      return passar(filtro, [
        ...trecho(3, (_) => 10.5, rms: 0.2),
        ...trecho(20, (_) => 0.5 + 4 * gauss(aleatorio), rms: 0.15),
      ], inicio: 2.32);
    }

    double maior(List<Exibicao?> exibicoes) =>
        exibicoes.map((e) => e!.ponteiro).reduce(math.max);
    final com = tocar(FiltroKalman());
    expect(maior(com), lessThan(1.5));
    expect(com.every((e) => e!.afinada), isTrue);
    // Sem esperar o ataque, as mesmas leituras levariam o ponteiro junto.
    final sem = tocar(FiltroKalman(tempoAtaque: 1e-6));
    expect(maior(sem), greaterThan(2.2));
  });

  test(
    'palhetada depois de afinar com a corda muda: vai para o valor novo',
    () {
      final filtro = FiltroKalman();
      passar(filtro, trecho(25, (_) => -50));
      // Silêncio (o detector rejeita), a tarraxa gira, e a corda é tocada de
      // novo em −20, com o ataque 10 cents agudo.
      passar(filtro, trecho(12, (_) => null, rms: 0.002), inicio: 1);
      final exibicoes = passar(filtro, [
        ...trecho(3, (_) => -10, rms: 0.3),
        ...trecho(20, (_) => -20, rms: 0.25),
      ], inicio: 1.48);
      // Em até 0,4 s o ponteiro está no valor novo.
      for (final e in exibicoes.skip(10)) {
        expect(e!.ponteiro, closeTo(-20, 2));
      }
    },
  );

  test('um erro grosseiro isolado não mexe no ponteiro', () {
    final aleatorio = math.Random(13);
    final filtro = FiltroKalman();
    final antes = passar(filtro, trecho(50, (_) => 2 + 0.5 * gauss(aleatorio)));
    final pico = filtro.adicionar(tempo: 2, cents: 40, rms: 0.1)!;
    expect(pico.ponteiro, closeTo(antes.last!.ponteiro, 0.5));
  });

  test('leituras rejeitadas que concordam entre si: o filtro salta', () {
    final filtro = FiltroKalman();
    passar(filtro, trecho(50, (_) => 0));
    final exibicoes = passar(filtro, trecho(8, (_) => 30), inicio: 2);
    // As quatro primeiras ficam de fora; a quinta confirma o salto.
    for (final e in exibicoes.take(4)) {
      expect(e!.ponteiro, closeTo(0, 0.5));
    }
    expect(exibicoes[4]!.ponteiro, closeTo(30, 1e-9));
    expect(exibicoes.last!.afinada, isFalse);
  });

  test('corda nova recomeça na leitura', () {
    final filtro = FiltroKalman();
    passar(filtro, trecho(50, (_) => 1));
    expect(filtro.atual!.afinada, isTrue);
    final e = filtro.adicionar(
      tempo: 2,
      cents: -40,
      rms: 0.1,
      cordaNova: true,
    )!;
    expect(e.ponteiro, closeTo(-40, 1e-9));
    expect(e.numero, -40);
    expect(e.afinada, isFalse);
  });

  test('aprende o ruído da leitura', () {
    final aleatorio = math.Random(17);
    final filtro = FiltroKalman();
    passar(filtro, trecho(500, (_) => -5 + 6 * gauss(aleatorio)));
    expect(filtro.ruido, closeTo(6, 1.5));
    final calmo = FiltroKalman();
    passar(calmo, trecho(500, (_) => -5 + 1.5 * gauss(aleatorio)));
    expect(calmo.ruido, closeTo(1.5, 0.5));
  });

  test('reiniciar esquece a corda', () {
    final filtro = FiltroKalman();
    passar(filtro, trecho(50, (_) => 20));
    filtro.reiniciar();
    expect(filtro.atual, isNull);
    expect(filtro.desvio, isNull);
    final e = filtro.adicionar(tempo: 3, cents: -3, rms: 0.1)!;
    expect(e.ponteiro, closeTo(-3, 1e-9));
    expect(e.afinada, isFalse);
  });

  test('esquecerTudo volta o ruído ao inicial', () {
    final aleatorio = math.Random(19);
    final filtro = FiltroKalman(ruidoInicial: 4);
    passar(filtro, trecho(500, (_) => 8 * gauss(aleatorio)));
    expect(filtro.ruido, greaterThan(6));
    filtro.esquecerTudo();
    expect(filtro.ruido, closeTo(4, 1e-9));
    expect(filtro.atual, isNull);
  });

  group('tarraxa rápida', () {
    test('a 100 cents/s o ponteiro não fica preso no valor de partida', () {
      final aleatorio = math.Random(1);
      double verdade(double t) =>
          t < 3 ? -60 : math.min(-60 + 100 * (t - 3), 0).toDouble();
      final filtro = FiltroKalman();
      for (var i = 0; i < 125; i++) {
        final t = i * intervalo;
        final e = filtro.adicionar(
          tempo: t,
          cents: verdade(t) + gauss(aleatorio),
          rms: 0.1,
        )!;
        if (t > 3.2) {
          expect(e.ponteiro, closeTo(verdade(t), 10), reason: 't=$t');
        }
      }
    });

    test('acelerando até 40 a 100 cents/s, o ponteiro segue a corda', () {
      for (final velocidade in [40.0, 60.0, 80.0, 100.0]) {
        var somaPior = 0.0, somaTempo = 0.0;
        for (var semente = 0; semente < 10; semente++) {
          final aleatorio = math.Random(100 + semente);
          final filtro = FiltroKalman();
          // 2 s parada, acelera em 0,25 s e sobe até 0.
          var x = -1.6 * velocidade;
          var pior = 0.0;
          for (var i = 0; i < 200; i++) {
            final t = i * intervalo;
            if (t >= 2) {
              final v = math.min(velocidade, velocidade * (t - 2) / 0.25);
              x = math.min(0, x + v * intervalo);
            }
            final e = filtro.adicionar(
              tempo: t,
              cents: x + gauss(aleatorio),
              rms: 0.1,
            )!;
            if (t > 2 && x < 0) {
              final erro = (e.ponteiro - x).abs();
              pior = math.max(pior, erro);
              if (erro > 15) somaTempo += intervalo;
            }
          }
          somaPior += pior;
        }
        // O ponteiro fica para trás no máximo o que a tarraxa anda em 0,22 s
        // (o salto pede algumas leituras rejeitadas numa reta) e quase nunca
        // a mais de 15 cents. Antes, a 60 cents/s ficava até 20 cents para
        // trás e a mais de 15 por 0,8 s; a 80, até 42, e a 100, até 146.
        expect(
          somaPior / 10,
          lessThan(0.22 * velocidade),
          reason: '$velocidade c/s',
        );
        expect(somaTempo / 10, lessThan(0.05), reason: '$velocidade c/s');
      }
    });

    test(
      'saindo do afinado a 40 cents/s, o ✓ apaga e o ponteiro vai junto',
      () {
        final aleatorio = math.Random(1);
        final filtro = FiltroKalman();
        passar(filtro, trecho(300, (_) => 0.5 * gauss(aleatorio)));
        expect(filtro.atual!.afinada, isTrue);
        for (var i = 0; i < 26; i++) {
          final verdade = 40 * i * intervalo;
          final e = filtro.adicionar(
            tempo: (300 + i) * intervalo,
            cents: verdade + 0.5 * gauss(aleatorio),
            rms: 0.1,
          )!;
          if (verdade > 9) expect(e.afinada, isFalse, reason: 'i=$i');
          expect(e.ponteiro, closeTo(verdade, 8), reason: 'i=$i');
        }
      },
    );
  });

  group('transitórios', () {
    /// Silêncio, palhetada numa corda nova com [ataques] análises 12 cents
    /// agudas, e a corda assentada em [corda].
    List<Analise> cordaNova(
      double corda, {
      int ataques = 4,
      double ruido = 0,
      math.Random? aleatorio,
    }) {
      double r() => aleatorio == null ? 0 : ruido * gauss(aleatorio);
      return [
        ...trecho(12, (_) => null, rms: 0.002),
        ...trecho(ataques, (_) => corda + 12 + r(), rms: 0.2),
        ...trecho(100, (_) => corda + r(), rms: 0.15),
      ];
    }

    test('o viés do ataque de uma corda nova não vira ✓', () {
      final limpa = passar(FiltroKalman(), cordaNova(-7));
      expect([for (final e in limpa) e?.afinada ?? false], everyElement(false));
      final fina = passar(FiltroKalman(precisao: Precisao.fina), cordaNova(-3));
      expect([for (final e in fina) e?.afinada ?? false], everyElement(false));
      for (var semente = 0; semente < 30; semente++) {
        final exibicoes = passar(
          FiltroKalman(),
          cordaNova(-7.5, ruido: 1, aleatorio: math.Random(semente)),
        );
        expect(
          exibicoes.where((e) => e?.afinada ?? false),
          isEmpty,
          reason: 'semente $semente',
        );
      }
    });

    /// Parada em [de] por 2 s, depois a tarraxa anda [velocidade] cents por
    /// segundo até [ate] e para.
    List<Analise> rampa(
      double de,
      double ate,
      double velocidade, {
      double ruido = 0,
      math.Random? aleatorio,
      int depois = 100,
    }) {
      double r() => aleatorio == null ? 0 : ruido * gauss(aleatorio);
      final analises = trecho(50, (_) => de + r());
      var x = de;
      while (x != ate) {
        x = ate > de
            ? math.min(ate, x + velocidade * intervalo)
            : math.max(ate, x - velocidade * intervalo);
        analises.add((cents: x + r(), rms: 0.1));
      }
      return [...analises, ...trecho(depois, (_) => ate + r())];
    }

    test('a tarraxa parando logo fora da tolerância não acende o ✓', () {
      for (final (de, ate, velocidade) in [
        (-30.0, -7.0, 20.0),
        (-40.0, -9.8, 40.0),
        (-50.0, -11.0, 40.0),
        (30.0, 7.0, 30.0),
      ]) {
        final exibicoes = passar(FiltroKalman(), rampa(de, ate, velocidade));
        expect(
          exibicoes.where((e) => e!.afinada),
          isEmpty,
          reason: '$de → $ate a $velocidade c/s',
        );
      }
      for (var semente = 0; semente < 20; semente++) {
        final exibicoes = passar(
          FiltroKalman(),
          rampa(-60, -7.5, 50, ruido: 1, aleatorio: math.Random(semente)),
        );
        expect(
          exibicoes.where((e) => e!.afinada),
          isEmpty,
          reason: 'semente $semente',
        );
      }
    });

    test(
      'quando a tarraxa para, o ponteiro e o número não passam do ponto',
      () {
        // Antes: parando em −12 a 20 cents/s, o número ia a −9 e o ponteiro a
        // −9,2, e só voltavam depois de 1 s.
        final exibicoes = passar(FiltroKalman(), rampa(-30, -12, 20));
        for (final e in exibicoes) {
          expect(e!.ponteiro, lessThanOrEqualTo(-11), reason: '$e');
          expect(e.numero, lessThanOrEqualTo(-12), reason: '$e');
        }
        // Parando dentro da tolerância, o ✓ que entrou não apaga (antes, o
        // desvio passava de 8 cents e o ✓ sumia por quase 1 s).
        for (final (ate, velocidade, precisao) in [
          (3.0, 30.0, Precisao.normal),
          (1.0, 20.0, Precisao.fina),
        ]) {
          final analises = rampa(-40, ate, velocidade);
          final depois = passar(
            FiltroKalman(precisao: precisao),
            analises,
          ).sublist(analises.length - 100);
          final entrou = depois.indexWhere((e) => e!.afinada);
          expect(entrou, greaterThanOrEqualTo(0), reason: '$precisao');
          expect(
            depois.skip(entrou).where((e) => !e!.afinada),
            isEmpty,
            reason: '$precisao',
          );
        }
      },
    );

    test('a marca não entra com a nota morrendo', () {
      // Palhetada numa corda 12 cents aguda; a tarraxa a leva a 1 cent
      // quando a energia já caiu. Com a nota morrendo (constante de 0,5 s, a
      // energia abaixo de 15% do pico), as leituras são enviesadas e o ✓ não
      // entra; com a nota ainda soando (3 s), entra.
      List<Analise> nota(double constante) => [
        ...trecho(5, (_) => null, rms: 0.002),
        for (var i = 0; i < 55; i++)
          (
            cents: i < 30 ? 12.0 : 1.0,
            rms: 0.3 * math.exp(-i * intervalo / constante),
          ),
      ];
      final morrendo = passar(FiltroKalman(), nota(0.5));
      expect(morrendo.where((e) => e?.afinada ?? false), isEmpty);
      final soando = passar(FiltroKalman(), nota(3));
      expect(soando.last!.afinada, isTrue);
    });

    test('depois de um buraco sem leituras, a velocidade não leva o '
        'ponteiro além da corda', () {
      for (final nulas in [14, 18, 25]) {
        // A mão para em −14 no mesmo instante em que o detector perde a
        // nota, e ele volta a lê-la sem uma palhetada nova.
        final antes = [
          ...rampa(-54, -14, 20, depois: 0),
          ...trecho(nulas, (_) => null, rms: 0.08),
        ];
        final exibicoes = passar(FiltroKalman(), [
          ...antes,
          ...trecho(25, (_) => -14, rms: 0.08),
        ]);
        for (final e in exibicoes.skip(antes.length)) {
          expect(e!.afinada, isFalse, reason: '$nulas nulas');
          expect(e.ponteiro, closeTo(-14, 2.5), reason: '$nulas nulas');
        }
      }
    });
  });

  group('palhetada', () {
    /// A corda afinada em 0, silêncio de 0,6 s, e a corda tocada de novo em
    /// [nova] (reafinada com ela muda), com o ataque agudo.
    List<Analise> reafinada(double nova) => [
      ...trecho(50, (_) => 0),
      ...trecho(15, (_) => null, rms: 0.003),
      for (var i = 0; i < 40; i++)
        (
          cents: nova + 12 * math.max(0, 1 - i * intervalo / 0.08),
          rms: i < 3 ? 0.3 : 0.25,
        ),
    ];

    test('a corda reafinada muda e tocada de novo apaga o ✓ antigo logo', () {
      for (final nova in [-30.0, -12.0, 12.0, 20.0]) {
        final exibicoes = passar(FiltroKalman(), reafinada(nova)).sublist(65);
        // No máximo durante o ataque (0,15 s, 4 análises): a primeira
        // leitura assentada já decide.
        final comMarca = exibicoes.where((e) => e!.afinada).length;
        expect(comMarca, lessThanOrEqualTo(4), reason: 'reafinada em $nova');
        expect(exibicoes.last!.ponteiro, closeTo(nova, 1), reason: '$nova');
      }
    });

    test('o degrau entre palhetadas não vira velocidade', () {
      final exibicoes = passar(FiltroKalman(), reafinada(-12)).sublist(65);
      for (final e in exibicoes) {
        expect(e!.numero, greaterThanOrEqualTo(-13));
        expect(e.ponteiro, greaterThanOrEqualTo(-13));
      }
    });

    test('a energia de um batimento não prende o filtro no ataque', () {
      // O RMS de duas cordas de um par batendo a 10 Hz: sobe e desce a cada
      // 0,1 s, e cada subida parecia uma palhetada nova.
      double batimento(int i) =>
          0.05 *
          math.sqrt(1 + 0.687 * math.cos(2 * math.pi * 10 * i * intervalo));
      final exibicoes = passar(FiltroKalman(), [
        for (var i = 0; i < 125; i++)
          (cents: i < 50 ? 0.0 : 9.0, rms: batimento(i)),
      ]);
      expect(exibicoes[49]!.afinada, isTrue);
      expect(exibicoes.last!.afinada, isFalse);
      expect(exibicoes.last!.ponteiro, closeTo(9, 1));
    });
  });

  test('na precisão fina o ✓ não pisca com o tremor na borda', () {
    for (final (precisao, corda) in [
      (Precisao.normal, 4.0),
      (Precisao.fina, 1.6),
    ]) {
      final aleatorio = math.Random(500);
      final exibicoes = passar(
        FiltroKalman(precisao: precisao),
        trecho(1500, (_) => corda + 2.5 * gauss(aleatorio)),
      ).sublist(50);
      expect(
        trocasDeRotulo(exibicoes),
        lessThanOrEqualTo(4),
        reason: '$precisao',
      );
    }
  });

  test('trocar para a fina com o ✓ aceso reavalia a marca', () {
    final filtro = FiltroKalman();
    passar(filtro, trecho(50, (_) => 3));
    expect(filtro.atual!.afinada, isTrue);
    filtro.precisao = Precisao.fina;
    expect(filtro.atual!.afinada, isFalse);
    final depois = passar(filtro, trecho(250, (_) => 3), inicio: 2);
    expect(depois.where((e) => e!.afinada), isEmpty);
    // E de volta para a normal: 3 cents voltam a ter ✓.
    filtro.precisao = Precisao.normal;
    expect(
      passar(filtro, trecho(10, (_) => 3), inicio: 12).last!.afinada,
      isTrue,
    );
  });

  group('robustez', () {
    test('um intervalo longo entre chamadas não apaga o ruído aprendido', () {
      final aleatorio = math.Random(4);
      final filtro = FiltroKalman();
      final antes = passar(
        filtro,
        trecho(500, (_) => 2 + 3 * gauss(aleatorio)),
      ).last!;
      final ruido = filtro.ruido;
      final depois = passar(
        filtro,
        trecho(25, (_) => 2 + 3 * gauss(aleatorio)),
        inicio: 30,
      );
      expect(filtro.ruido, closeTo(ruido, 0.3 * ruido));
      for (final e in depois) {
        expect(e!.ponteiro, closeTo(antes.ponteiro, 3));
      }
    });

    test('o relógio que volta recomeça a corda e a palhetada', () {
      final filtro = FiltroKalman();
      passar(filtro, [
        ...trecho(3, (_) => 20, rms: 0.001),
        ...trecho(22, (_) => 20),
      ], inicio: 100);
      filtro.reiniciar();
      final exibicoes = passar(filtro, [
        ...trecho(10, (_) => 10),
        ...trecho(90, (_) => 0),
      ]);
      expect(exibicoes.last!.ponteiro, closeTo(0, 0.5));
      expect(exibicoes.last!.afinada, isTrue);
    });

    test('o piso do ruído vale para a média, não para cada amostra', () {
      var soma = 0.0;
      for (var semente = 0; semente < 20; semente++) {
        final aleatorio = math.Random(semente);
        final filtro = FiltroKalman();
        passar(filtro, trecho(1500, (_) => 3 + gauss(aleatorio)));
        soma += filtro.ruido;
      }
      expect(soma / 20, closeTo(1, 0.1));
    });

    test('leituras não finitas contam como rejeitadas pelo detector', () {
      final filtro = FiltroKalman();
      final antes = passar(filtro, trecho(50, (_) => 1)).last;
      expect(filtro.adicionar(tempo: 2, cents: double.nan, rms: 0.1), antes);
      expect(
        filtro.adicionar(tempo: 2.04, cents: double.infinity, rms: 0.1),
        antes,
      );
      expect(filtro.ruido.isFinite, isTrue);
      filtro.reiniciar();
      final depois = passar(filtro, trecho(50, (i) => 30.0 + i), inicio: 3);
      expect(depois.last!.ponteiro, closeTo(79, 3));
      expect(
        FiltroKalman().adicionar(
          tempo: 0,
          cents: double.negativeInfinity,
          rms: double.nan,
        ),
        isNull,
      );
      expect(
        () => FiltroKalman(ruidoInicial: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
