import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/estado_corda.dart';
import 'package:open_tuner/features/afinador/grafico.dart';

import '../apoio/controlador_sincrono.dart';

/// E4 e A4, a terceira e a quarta corda do ukulele padrão (G4 C4 E4 A4).
const e4 = 329.6275569128699;
const a4 = 440.0;

double desviada(double alvo, double cents) =>
    alvo * math.pow(2, cents / 1200).toDouble();

/// As leituras de [b] a partir da análise [desde], para as mensagens.
String trecho(ControladorSincrono b, int desde) => [
  for (var i = desde; i < b.leituras.length; i++)
    b.leituras[i].ehOciosa
        ? '·'
        : '${b.leituras[i].corda}:${b.leituras[i].numero}'
              '${b.leituras[i].estado == EstadoCorda.afinada ? '✓' : ''}',
].join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ControladorSincrono b;
  tearDown(() => b.descartar());

  group('depois do silêncio', () {
    test(
      'uma leitura na oitava de baixo não leva o ponteiro à borda',
      () async {
        for (final preferencias in [
          const <String, Object>{},
          const <String, Object>{'auto': false, 'cordaFixada': 2},
        ]) {
          b = await ControladorSincrono.abrir(preferencias: preferencias);
          b.tocar(desviada(e4, -8), 25);
          // 2 s de silêncio: a tela volta a ociosa.
          b.tocar(null, 50);
          expect(b.leitura.ehOciosa, isTrue);
          final desde = b.leituras.length;
          // A primeira análise da palhetada sai na oitava de baixo.
          b
            ..tocar(e4 / 2, 1)
            ..tocar(e4, 12);
          for (final l in b.leituras.skip(desde)) {
            expect(
              l.cents.abs(),
              lessThan(50),
              reason: '$preferencias: ${trecho(b, desde)}',
            );
          }
          expect(b.leitura.corda, 2);
          expect(b.leitura.estado, EstadoCorda.afinada);
          b.descartar();
        }
        b = await ControladorSincrono.abrir();
      },
    );

    test('no Auto, a corda seguinte não é medida contra a de antes', () async {
      b = await ControladorSincrono.abrir();
      b.tocar(desviada(e4, -20), 20);
      b.tocar(null, 50);
      final desde = b.leituras.length;
      b.tocar(a4, 10);
      final mostradas = b.leituras.skip(desde).where((l) => !l.ehOciosa);
      expect(mostradas, isNotEmpty);
      for (final l in mostradas) {
        expect(l.corda, 3, reason: trecho(b, desde));
        expect(l.cents.abs(), lessThan(50), reason: trecho(b, desde));
      }
    });

    test('a primeira leitura aparece uma análise depois, confirmada', () async {
      b = await ControladorSincrono.abrir();
      b.tocar(desviada(e4, -20), 2);
      expect(b.leituras[0].ehOciosa, isTrue);
      expect(b.leituras[1].corda, 2);
      expect(b.leituras[1].numero, inInclusiveRange(-30, -10));
      b.tocar(desviada(e4, -20), 30);
      expect(b.leitura.cents, closeTo(-20, 1));
    });
  });

  test('a marca da corda só soma o tempo dentro da tolerância', () async {
    // A tarraxa sobe de −20 a 20 cents/s, passa pela nota e para logo fora
    // da tolerância: o ✓ fica aceso pela histerese, mas a corda não ganha a
    // marca (antes, o marcador contava o ✓ e marcava a corda em +7).
    for (final (fim, precisao) in [(7.0, 'normal'), (3.0, 'fina')]) {
      b = await ControladorSincrono.abrir(preferencias: {'precisao': precisao});
      b.tocar(desviada(e4, -20), 10);
      final cents = <double>[];
      for (var c = -20.0; c < fim;) {
        c = math.min(fim, c + 0.8);
        cents.add(c);
      }
      b
        ..tocar(null, cents.length, frequencias: (i) => desviada(e4, cents[i]))
        ..tocar(desviada(e4, fim), 50);
      expect(b.controlador.afinadas, isEmpty, reason: precisao);
      expect(b.tocador.avisosDeAfinada, 0, reason: precisao);
      b.descartar();
    }
    b = await ControladorSincrono.abrir();
  });

  test('a corda que chega à nota já fraca não recebe instrução', () async {
    // Tocada uma vez, afrouxando a 12 cents/s enquanto a nota morre. Perto
    // do zero o ponteiro erra um ou dois cents para qualquer lado: dentro da
    // tolerância, sem o ✓, a tela não manda girar a tarraxa.
    for (final fim in [-1.5, -0.5, 0.0, 0.5, 1.0, 3.0]) {
      b = await ControladorSincrono.abrir();
      const inicio = 20.0;
      final chegada = ((inicio - fim) / 12 * 25).ceil();
      b.tocar(
        null,
        chegada + 50,
        frequencias: (i) =>
            desviada(e4, math.max(fim, inicio - 12 * i * 0.04).toDouble()),
        amplitudes: (i) => 0.5 * math.exp(-i * 0.04 / 0.5),
      );
      final depois = b.leituras.skip(chegada + 8).where((l) => !l.ehOciosa);
      expect(depois, isNotEmpty);
      for (final l in depois) {
        expect(
          direcaoDe(l, Precisao.normal),
          isIn([Direcao.afinada, Direcao.nenhuma]),
          reason: 'parada em $fim: ${trecho(b, chegada)}',
        );
      }
      b.descartar();
    }
    b = await ControladorSincrono.abrir();
  });

  test(
    'o ✓ não atravessa a palhetada da corda reafinada muda para +7',
    () async {
      b = await ControladorSincrono.abrir();
      // Afinada por pouco tempo (o ✓ acende, a marca ainda não), calada,
      // reafinada para +7 e tocada de novo, com o ataque agudo.
      b.tocar(e4, 14);
      expect(b.leitura.estado, EstadoCorda.afinada);
      expect(b.controlador.afinadas, isEmpty);
      b.tocar(null, 13);
      final desde = b.leituras.length;
      b
        ..tocar(
          null,
          3,
          frequencias: (i) => desviada(e4, 7 + 12 - 4.0 * i),
          amplitude: 0.5,
        )
        ..tocar(desviada(e4, 7), 50, amplitude: 0.4);
      expect(b.controlador.afinadas, isEmpty, reason: trecho(b, desde));
      expect(b.tocador.avisosDeAfinada, 0);
      expect(
        b.leituras
            .skip(desde + 10)
            .where((l) => l.estado == EstadoCorda.afinada),
        isEmpty,
        reason: trecho(b, desde),
      );
    },
  );

  test('marcada, a corda que sai da nota não fica com o anel cheio', () async {
    b = await ControladorSincrono.abrir();
    b.tocar(e4, 65);
    expect(b.controlador.afinadas, {2});
    final desde = b.leituras.length;
    b.tocar(desviada(e4, 12), 45);
    for (final l in b.leituras.skip(desde)) {
      if (l.estado == EstadoCorda.afinada) continue;
      expect(l.progresso, 0, reason: trecho(b, desde));
    }
    // E de volta à nota, o anel enche de novo com o ✓.
    b.tocar(e4, 25);
    expect(b.leitura.estado, EstadoCorda.afinada);
    expect(b.leitura.progresso, 1);
  });

  group('as marcas somem', () {
    test('ao mudar a referência do Lá', () async {
      b = await ControladorSincrono.abrir();
      b.tocar(e4, 40);
      expect(b.controlador.afinadas, {2});
      b.tocar(null, 50);
      b.ajustes.a4 = 430;
      expect(b.controlador.afinadas, isEmpty);
    });

    test('ao passar para a precisão fina, mas não ao voltar', () async {
      b = await ControladorSincrono.abrir();
      b.tocar(e4, 40);
      expect(b.controlador.afinadas, {2});
      b.ajustes.precisao = Precisao.fina;
      expect(b.controlador.afinadas, isEmpty);
      b.tocar(null, 50);
      b.tocar(e4, 40);
      expect(b.controlador.afinadas, {2});
      b.ajustes.precisao = Precisao.normal;
      expect(b.controlador.afinadas, {2});
    });
  });

  test(
    'pausar e voltar não deixa o afinador surdo pelo som de antes',
    () async {
      b = await ControladorSincrono.abrir();
      b.tocar(null, 10);
      b.controlador.tocarCorda(2);
      b.tocar(null, 2);
      await b.controlador.pausar();
      await b.controlador.retomar();
      b.fonte.entregar(List.filled(8192, 0.0));
      final desde = b.leituras.length;
      b.tocar(desviada(e4, -12), 10);
      final primeira = b.leituras
          .skip(desde)
          .toList()
          .indexWhere((l) => !l.ehOciosa);
      expect(primeira, inInclusiveRange(0, 2));

      // O botão da corda tocado sem escutar (antes da permissão, ou com o
      // app pausado) também não deixa a escuta surda depois.
      await b.controlador.pausar();
      b.controlador.tocarCorda(2);
      await b.controlador.retomar();
      b.fonte.entregar(List.filled(8192, 0.0));
      final depois = b.leituras.length;
      b.tocar(desviada(e4, -12), 10);
      expect(
        b.leituras.skip(depois).toList().indexWhere((l) => !l.ehOciosa),
        inInclusiveRange(0, 2),
      );
    },
  );

  test('depois do botão da corda, a palhetada mais fraca que o som de antes '
      'não vira ✓ pelo viés do ataque', () async {
    b = await ControladorSincrono.abrir();
    // A corda soa forte em −7,5 (fora da tolerância, sem ✓).
    b.tocar(desviada(e4, -7.5), 30, amplitude: 0.3);
    expect(b.leitura.estado, isNot(EstadoCorda.afinada));
    // O botão da corda: a referência toca e o afinador fica surdo. A mão cala
    // a corda e toca de novo logo que o som acaba, mais fraco que antes.
    b.controlador.tocarCorda(2);
    b.tocar(null, 47);
    final desde = b.leituras.length;
    b
      ..tocar(
        null,
        4,
        frequencias: (i) => desviada(e4, -7.5 + 12 - 3 * i),
        amplitude: 0.25,
      )
      ..tocar(desviada(e4, -7.5), 75, amplitude: 0.25);
    expect(
      b.leituras.skip(desde).where((l) => l.estado == EstadoCorda.afinada),
      isEmpty,
      reason: trecho(b, desde),
    );
    expect(b.controlador.afinadas, isEmpty);
    expect(b.tocador.avisosDeAfinada, 0);
  });

  test('a nota suave depois de uma forte ganha o ✓ e a marca', () async {
    b = await ControladorSincrono.abrir();
    b.tocar(e4, 40);
    expect(b.controlador.afinadas, {2});
    b.tocar(null, 75);
    // A4 afinado e bem mais fraco (RMS perto de 0,008): o detector lê, mas
    // é pouco para contar como palhetada.
    b.tocar(a4, 125, amplitude: 0.011);
    expect(b.leitura.estado, EstadoCorda.afinada);
    expect(b.controlador.afinadas, {2, 3});
  });
}
