/// Endereços que o app abre no navegador.
///
/// O site do OpenTuner mora em opentuner.libre-apps.org (até 2026-11 ficava
/// no GitHub Pages, em guilhermefeitosa66.github.io/open-tuner, que hoje só
/// redireciona). A libre-apps.org é a fundação de apps livres de que o
/// OpenTuner faz parte. O site tem inglês na raiz, português em `pt/` e
/// espanhol em `es/`; os links abrem no idioma do app.
library;

const String _site = 'https://opentuner.libre-apps.org/';

/// A fundação de apps livres de que o OpenTuner faz parte.
const String enderecoFundacao = 'https://libre-apps.org/';

/// O código-fonte.
const String enderecoCodigo =
    'https://github.com/guilhermefeitosa66/open-tuner';

String _prefixo(String idioma) => switch (idioma) {
  'pt' => 'pt/',
  'es' => 'es/',
  _ => '',
};

/// O site do OpenTuner no [idioma] do app.
String enderecoSite(String idioma) => '$_site${_prefixo(idioma)}';

/// A política de privacidade no [idioma] do app.
String enderecoPrivacidade(String idioma) =>
    '$_site${_prefixo(idioma)}privacy/';

/// Os termos de uso no [idioma] do app.
String enderecoTermos(String idioma) => '$_site${_prefixo(idioma)}terms/';
