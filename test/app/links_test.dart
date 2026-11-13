import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/app/links.dart';

void main() {
  test('o site, a privacidade e os termos abrem no idioma do app', () {
    expect(enderecoSite('pt'), 'https://opentuner.libre-apps.org/pt/');
    expect(enderecoSite('es'), 'https://opentuner.libre-apps.org/es/');
    expect(enderecoSite('en'), 'https://opentuner.libre-apps.org/');
    expect(enderecoSite('fr'), 'https://opentuner.libre-apps.org/');
    expect(
      enderecoPrivacidade('pt'),
      'https://opentuner.libre-apps.org/pt/privacy/',
    );
    expect(
      enderecoPrivacidade('en'),
      'https://opentuner.libre-apps.org/privacy/',
    );
    expect(enderecoTermos('es'), 'https://opentuner.libre-apps.org/es/terms/');
    expect(enderecoTermos('en'), 'https://opentuner.libre-apps.org/terms/');
  });

  test('nenhum link aponta para o endereço antigo do GitHub Pages', () {
    for (final idioma in ['pt', 'en', 'es']) {
      for (final endereco in [
        enderecoFundacao,
        enderecoCodigo,
        enderecoSite(idioma),
        enderecoPrivacidade(idioma),
        enderecoTermos(idioma),
      ]) {
        expect(endereco, isNot(contains('github.io')));
        expect(Uri.parse(endereco).scheme, 'https');
      }
    }
  });
}
