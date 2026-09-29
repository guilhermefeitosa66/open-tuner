import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/app/idioma.dart';

void main() {
  Locale resolver(List<Locale>? preferidos) =>
      resolverIdioma(preferidos, idiomasSuportados);

  group('resolverIdioma', () {
    test('português do Brasil vira pt', () {
      expect(resolver(const [Locale('pt', 'BR')]), const Locale('pt'));
    });

    test('português de Portugal vira pt', () {
      expect(resolver(const [Locale('pt', 'PT')]), const Locale('pt'));
    });

    test('espanhol do México vira es', () {
      expect(resolver(const [Locale('es', 'MX')]), const Locale('es'));
    });

    test('inglês americano vira en', () {
      expect(resolver(const [Locale('en', 'US')]), const Locale('en'));
    });

    test('idioma não suportado cai no inglês', () {
      expect(resolver(const [Locale('fr', 'FR')]), const Locale('en'));
    });

    test('pula os preferidos não suportados, na ordem do usuário', () {
      expect(
        resolver(const [Locale('fr', 'FR'), Locale('pt', 'BR')]),
        const Locale('pt'),
      );
      expect(resolver(const [Locale('de'), Locale('es')]), const Locale('es'));
    });

    test('sem preferidos, inglês', () {
      expect(resolver(null), const Locale('en'));
      expect(resolver(const []), const Locale('en'));
    });
  });

  test('o seletor dos ajustes tem o idioma do aparelho e todos os do app', () {
    expect(opcoesIdioma.first.codigo, isNull);
    expect(
      opcoesIdioma.skip(1).map((opcao) => opcao.codigo).toSet(),
      idiomasSuportados.map((idioma) => idioma.languageCode).toSet(),
    );
  });
}
