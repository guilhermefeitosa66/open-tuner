// O afinador desenhado da página inicial, nas três línguas (#afinador).
//
// Uma corda sendo afinada, em laço: o marcador vai da borda ao centro e deixa
// o rastro rolando para baixo, como no app. Com movimento reduzido, fica parado
// no estado afinado que o SVG já traz.
(function () {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var svg = document.getElementById('afinador');
  if (!svg) return;
  var tracos = {
    longe: document.getElementById('rastro-longe'),
    perto: document.getElementById('rastro-perto'),
    afinado: document.getElementById('rastro-afinado')
  };
  var bolha = document.getElementById('bolha');
  var aro = document.getElementById('bolha-aro');
  var ponta = document.getElementById('bolha-ponta');
  var texto = document.getElementById('bolha-texto');
  var cores = { longe: '#EE8A52', perto: '#E6C24F', afinado: '#5CC592' };
  var historico = [], cents = null, estavel = 0, pausa = 12;

  function x(c) { return 156 + Math.max(-50, Math.min(50, c)) * 2.4; }
  function faixa(c) { var d = Math.abs(c); return d <= 5 ? 'afinado' : d <= 15 ? 'perto' : 'longe'; }

  function passo() {
    if (pausa > 0) {
      pausa--;
      historico.unshift(null);
      if (pausa === 0) { cents = (Math.random() < 0.5 ? -1 : 1) * (18 + Math.random() * 26); estavel = 0; }
    } else {
      cents = cents * 0.955 + (Math.random() - 0.5) * 2.2;
      estavel = Math.abs(cents) <= 3 ? estavel + 1 : 0;
      historico.unshift(cents);
      if (estavel > 18) { pausa = 30; }
    }
    if (historico.length > 80) historico.length = 80;

    var d = { longe: '', perto: '', afinado: '' };
    for (var i = 0; i < historico.length - 1; i++) {
      var a = historico[i], b = historico[i + 1];
      if (a === null || b === null) continue;
      d[faixa((Math.abs(a) + Math.abs(b)) / 2)] += 'M' + x(a).toFixed(1) + ' ' + (92 + i * 3.4) + 'L' + x(b).toFixed(1) + ' ' + (92 + (i + 1) * 3.4);
    }
    for (var k in tracos) tracos[k].setAttribute('d', d[k] || 'M0 0');

    var afinada = pausa > 0 || Math.abs(cents) <= 5;
    var cor = afinada ? cores.afinado : cores[faixa(cents)];
    bolha.setAttribute('transform', 'translate(' + (afinada ? 156 : x(cents)).toFixed(1) + ' 0)');
    aro.setAttribute('stroke', cor);
    ponta.setAttribute('fill', cor);
    texto.textContent = afinada ? '✓' : (cents > 0 ? '+' : '−') + Math.round(Math.abs(cents));
    texto.setAttribute('fill', afinada ? cores.afinado : '#F3EBE0');
  }

  var timer = null;
  function iniciar() { if (!timer) timer = setInterval(passo, 70); }
  function parar() { clearInterval(timer); timer = null; }
  document.addEventListener('visibilitychange', function () { document.hidden ? parar() : iniciar(); });
  iniciar();
})();
