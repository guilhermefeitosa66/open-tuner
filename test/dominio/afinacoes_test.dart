import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/dominio/afinacoes.dart';
import 'package:open_tuner/dominio/nota.dart';

void main() {
  group('NotaAfinacao.ler', () {
    test('natural', () {
      final e2 = NotaAfinacao.ler('E2');
      expect(e2.nota, Nota('E', 2));
      expect(e2.letra, 'E');
      expect(e2.acidente, '');
      expect(e2.oitava, 2);
      expect(e2.bemol, isFalse);
      expect(e2.frequencia(), closeTo(82.41, 0.01));
    });

    test('sustenido', () {
      final fa = NotaAfinacao.ler('F#3');
      expect(fa.nota, Nota('F#', 3));
      expect(fa.letra, 'F');
      expect(fa.acidente, '♯');
      expect(fa.toString(), 'F♯3');
    });

    test('Eb2 é escrita com ♭ e tem a altura de D#2', () {
      final mib = NotaAfinacao.ler('Eb2');
      final reSustenido = NotaAfinacao.ler('D#2');
      expect(mib.bemol, isTrue);
      expect(mib.letra, 'E');
      expect(mib.acidente, '♭');
      expect(mib.oitava, 2);
      expect(mib.nota, Nota('D#', 2));
      expect(mib.nota, reSustenido.nota);
      expect(mib.frequencia(), reSustenido.frequencia());
      expect(mib.frequencia(), closeTo(77.78, 0.01));
      expect(reSustenido.letra, 'D');
      expect(mib.toString(), 'E♭2');
    });

    test('bemol que muda de oitava: Cb4 soa como B3', () {
      expect(NotaAfinacao.ler('Cb4').nota, Nota('B', 3));
    });

    test('segue a referência do Lá', () {
      expect(NotaAfinacao.ler('A4').frequencia(442), closeTo(442, 1e-9));
    });

    test('recusa texto inválido', () {
      for (final texto in ['', 'H2', 'E', 'E9', 'Ex2', 'e2']) {
        expect(
          () => NotaAfinacao.ler(texto),
          throwsFormatException,
          reason: texto,
        );
      }
    });
  });

  group('tabela', () {
    const idsInstrumento = [
      'ukulele',
      'ukulele-baritono',
      'cavaquinho',
      'violao',
      'violao-7',
      'viola-caipira',
      'baixo',
      'baixo-5',
      'baixo-6',
    ];

    const idsAfinacao = {
      'ukulele': ['padrao', 'sol-grave', 'em-re'],
      'ukulele-baritono': ['padrao'],
      'cavaquinho': ['padrao', 'natural'],
      'violao': [
        'padrao',
        'drop-d',
        'meio-tom-abaixo',
        'um-tom-abaixo',
        'dadgad',
        'open-g',
        'open-d',
      ],
      'violao-7': ['setima-em-do', 'setima-em-si'],
      'viola-caipira': ['cebolao-em-mi', 'cebolao-em-re', 'rio-abaixo'],
      'baixo': ['padrao', 'drop-d', 'meio-tom-abaixo'],
      'baixo-5': ['padrao', 'com-do-agudo'],
      'baixo-6': ['padrao'],
    };

    String notas(Afinacao afinacao) => afinacao.notas.join(' ');

    test('todos os instrumentos, na ordem da tabela', () {
      expect(instrumentos.map((i) => i.id), idsInstrumento);
    });

    test('todas as afinações de cada instrumento, na ordem', () {
      for (final instrumento in instrumentos) {
        expect(
          instrumento.afinacoes.map((a) => a.id),
          idsAfinacao[instrumento.id],
          reason: instrumento.id,
        );
      }
    });

    test('a padrão é a primeira', () {
      for (final instrumento in instrumentos) {
        expect(instrumento.padrao, same(instrumento.afinacoes.first));
        expect(instrumento.cordas, instrumento.padrao.notas.length);
      }
    });

    test('quantidade de cordas', () {
      expect(instrumentoPorId('violao').cordas, 6);
      expect(instrumentoPorId('violao-7').cordas, 7);
      expect(instrumentoPorId('viola-caipira').cordas, 5);
      expect(instrumentoPorId('baixo').cordas, 4);
      expect(instrumentoPorId('baixo-6').cordas, 6);
    });

    test('grupos e pares', () {
      expect(
        instrumentoPorId('cavaquinho').grupo,
        GrupoInstrumento.ukuleleCavaquinho,
      );
      expect(
        instrumentoPorId('viola-caipira').grupo,
        GrupoInstrumento.violaoViola,
      );
      expect(instrumentoPorId('baixo-5').grupo, GrupoInstrumento.baixo);
      expect(instrumentos.where((i) => i.pares).map((i) => i.id), [
        'viola-caipira',
      ]);
    });

    test('ordem física: ukulele padrão é reentrante', () {
      expect(notas(instrumentoPorId('ukulele').padrao), 'G4 C4 E4 A4');
    });

    test('meio tom abaixo é escrito com bemol', () {
      final violao = instrumentoPorId('violao').afinacao('meio-tom-abaixo');
      expect(notas(violao), 'E♭2 A♭2 D♭3 G♭3 B♭3 E♭4');
      expect(violao.notas.every((n) => n.bemol), isTrue);
      final baixo = instrumentoPorId('baixo').afinacao('meio-tom-abaixo');
      expect(notas(baixo), 'E♭1 A♭1 D♭2 G♭2');
    });

    test('frequências de E2, B0 e G♯3 conferem', () {
      final violao = instrumentoPorId('violao').padrao;
      expect(violao.notas.first.frequencia(), closeTo(82.41, 0.01));
      final baixo5 = instrumentoPorId('baixo-5').padrao;
      expect(baixo5.notas.first.frequencia(), closeTo(30.87, 0.01));
      final viola = instrumentoPorId('viola-caipira').padrao;
      expect(viola.notas[2].toString(), 'G♯3');
      expect(viola.notas[2].frequencia(), closeTo(207.65, 0.01));
    });

    test('afinação desconhecida cai na padrão', () {
      final violao = instrumentoPorId('violao');
      expect(violao.afinacao('drop-d').id, 'drop-d');
      expect(violao.afinacao('nao-existe'), same(violao.padrao));
    });

    test('instrumento desconhecido cai no ukulele', () {
      expect(instrumentoPorId('violao').id, 'violao');
      expect(instrumentoPorId('nao-existe').id, 'ukulele');
      expect(instrumentoPorId(''), same(instrumentos.first));
    });

    test('faixa de frequência de cada instrumento', () {
      expect(
        instrumentoPorId('baixo-5').frequenciaMinima,
        closeTo(30.87, 0.01),
      );
      expect(instrumentoPorId('baixo').frequenciaMinima, closeTo(36.71, 0.01));
      expect(instrumentoPorId('violao').frequenciaMinima, closeTo(73.42, 0.01));
      expect(
        instrumentoPorId('violao').frequenciaMaxima,
        closeTo(329.63, 0.01),
      );
      expect(
        instrumentoPorId('ukulele').frequenciaMinima,
        closeTo(196.0, 0.01),
      );
      expect(
        instrumentoPorId('cavaquinho').frequenciaMaxima,
        closeTo(659.26, 0.01),
      );
      // Viola: o dobro da mais aguda (E4), por causa da oitava do par.
      expect(
        instrumentoPorId('viola-caipira').frequenciaMaxima,
        closeTo(659.26, 0.01),
      );
    });
  });
}
