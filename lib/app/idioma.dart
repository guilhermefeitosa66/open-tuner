import 'package:flutter/widgets.dart';

import '../l10n/textos.dart';

// Os textos moram só na interface. `lib/dominio/` não importa Flutter nem
// `Textos`: quando instrumentos e afinações entrarem no domínio, eles terão
// ids, e a tradução de cada id para o nome visível é feita aqui na interface.

/// Idiomas com textos próprios. O primeiro, inglês, é a reserva.
const idiomasSuportados = [Locale('en'), Locale('pt'), Locale('es')];

const _reserva = Locale('en');

/// Escolhe o idioma do app a partir dos idiomas preferidos do aparelho, na
/// ordem do usuário.
///
/// Casa só pelo idioma, sem a região: pt_BR e pt_PT viram `pt`, es_MX vira
/// `es`. Se nenhum preferido for suportado (ou a lista vier vazia), usa inglês.
Locale resolverIdioma(List<Locale>? preferidos, Iterable<Locale> suportados) {
  for (final preferido in preferidos ?? const <Locale>[]) {
    for (final suportado in suportados) {
      if (suportado.languageCode == preferido.languageCode) {
        return suportado;
      }
    }
  }
  return _reserva;
}

/// Acesso curto aos textos traduzidos: `context.textos.afinada`.
extension TextosNoContexto on BuildContext {
  Textos get textos => Textos.of(this);
}
