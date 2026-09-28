import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Chaves de texto de um ARB, sem os metadados (`@chave`, `@@locale`).
Set<String> chavesDoArb(String idioma) {
  final arquivo = File('lib/l10n/app_$idioma.arb');
  final conteudo =
      jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>;
  return conteudo.keys.where((chave) => !chave.startsWith('@')).toSet();
}

void main() {
  test('os ARBs de todos os idiomas têm as mesmas chaves do inglês', () {
    final modelo = chavesDoArb('en');
    expect(modelo, isNotEmpty);
    for (final idioma in ['pt', 'es']) {
      expect(chavesDoArb(idioma), equals(modelo), reason: 'app_$idioma.arb');
    }
  });
}
