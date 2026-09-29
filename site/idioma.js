// Idiomas do site: inglês na raiz, português em pt/ e espanhol em es/.
//
// Os botões de bandeira do alto de cada página levam à mesma página na outra
// língua, e o clique guarda a escolha. Só a página inicial da raiz (a única com
// data-idioma-automatico no <html>, que carrega este arquivo sem defer para
// decidir antes de desenhar) troca de idioma sozinha: vale a escolha guardada
// e, sem ela, o navegador, como o app faz com o aparelho (o primeiro idioma
// preferido que o site tem; nenhum deles, inglês). As outras páginas nunca
// redirecionam: quem abre a política de privacidade pela loja lê o texto que
// abriu.
//
// O armazenamento pode faltar ou recusar (navegação privada, dados do site
// bloqueados). Sem ele, o site funciona igual e só não lembra a escolha.
(function () {
  'use strict';

  var CHAVE = 'opentuner.idioma';
  var IDIOMAS = ['en', 'pt', 'es'];

  // "pt-BR" → "pt", "es-419" → "es".
  function codigo(etiqueta) {
    return String(etiqueta || '').toLowerCase().split('-')[0];
  }

  function escolhaGuardada() {
    try {
      var valor = window.localStorage.getItem(CHAVE);
      return IDIOMAS.indexOf(valor) >= 0 ? valor : null;
    } catch (e) {
      return null;
    }
  }

  function guardarEscolha(idioma) {
    try {
      window.localStorage.setItem(CHAVE, idioma);
    } catch (e) {
      // Sem armazenamento: a escolha vale só para o clique.
    }
  }

  function idiomaDoNavegador() {
    var preferidos = navigator.languages && navigator.languages.length
      ? navigator.languages
      : [navigator.language];
    for (var i = 0; i < preferidos.length; i++) {
      var idioma = codigo(preferidos[i]);
      if (IDIOMAS.indexOf(idioma) >= 0) return idioma;
    }
    return 'en';
  }

  if (document.documentElement.hasAttribute('data-idioma-automatico')) {
    var idioma = escolhaGuardada() || idiomaDoNavegador();
    if (idioma !== 'en') {
      // replace: o voltar do navegador não cai de novo aqui.
      window.location.replace(idioma + '/' + window.location.hash);
      return;
    }
  }

  function ligarBotoes() {
    var botoes = document.querySelectorAll('.idiomas a[hreflang]');
    for (var i = 0; i < botoes.length; i++) {
      botoes[i].addEventListener('click', function () {
        guardarEscolha(codigo(this.getAttribute('hreflang')));
      });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', ligarBotoes);
  } else {
    ligarBotoes();
  }
})();
