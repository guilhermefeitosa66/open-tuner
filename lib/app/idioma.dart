import 'package:flutter/widgets.dart';

import '../l10n/textos.dart';

// Os textos moram só na interface. `lib/dominio/` não importa Flutter nem
// `Textos`: quando instrumentos e afinações entrarem no domínio, eles terão
// ids, e a tradução de cada id para o nome visível é feita aqui na interface.

/// Idiomas com textos próprios. O primeiro, inglês, é a reserva.
const idiomasSuportados = [Locale('en'), Locale('pt'), Locale('es')];

const _reserva = Locale('en');

/// Uma opção do seletor de idioma dos ajustes: o código (null = o idioma do
/// aparelho) e a bandeira que o acompanha.
class OpcaoIdioma {
  const OpcaoIdioma(this.codigo, this.bandeira);

  final String? codigo;
  final String bandeira;
}

/// As opções do seletor, na ordem em que aparecem: o idioma do aparelho e,
/// depois, cada idioma com textos próprios, com a bandeira do país da
/// variante que os textos usam (o português é o do Brasil).
const opcoesIdioma = [
  OpcaoIdioma(null, '🌐'),
  OpcaoIdioma('pt', '🇧🇷'),
  OpcaoIdioma('en', '🇺🇸'),
  OpcaoIdioma('es', '🇪🇸'),
];

/// O nome de uma opção de idioma. Os idiomas aparecem na própria língua
/// ("English", "Español"), que é como quem os fala os procura; só "Idioma do
/// sistema" segue o idioma da tela.
String nomeIdioma(Textos textos, String? codigo) => switch (codigo) {
  null => textos.idiomaSistema,
  'pt' => textos.nomeIdiomaPt,
  'en' => textos.nomeIdiomaEn,
  'es' => textos.nomeIdiomaEs,
  _ => codigo,
};

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
