// O afinador desenhado da página inicial, nas três línguas (#afinador).
//
// Uma corda sendo afinada, em laço, como no app: o marcador vai da borda ao
// centro e deixa o rastro rolando para baixo. Perto da nota, um anel verde
// fecha pela borda do marcador enquanto a corda soma tempo na tolerância;
// fechado, a corda se confirma afinada e o marcador enche de verde. Com
// movimento reduzido, fica parado no estado confirmado que o SVG já traz.
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
  var anel = document.getElementById('bolha-anel');
  var ponta = document.getElementById('bolha-ponta');
  var texto = document.getElementById('bolha-texto');
  var linha = document.getElementById('linha-afinada');
  var notaAro = document.getElementById('nota-aro');
  var notaTextos = svg.querySelectorAll('.nota-texto');
  var cores = { longe: '#EE8A52', perto: '#E6C24F', afinado: '#5CC592' };
  var fundo = '#14110E', fundoConfirmado = '#24392B', texto0 = '#F3EBE0', aroNota = '#4A3F35';

  // Os tempos do app: 70 ms por passo, 0,6 s na tolerância para confirmar.
  var passoS = 0.07, necessario = 0.6;
  var voltaAnel = 2 * Math.PI * 26;
  var historico = [], cents = null, progresso = 0, confirmada = false;
  var segurar = 0, pausa = 12;

  function x(c) { return 156 + Math.max(-50, Math.min(50, c)) * 2.4; }
  function faixa(c) { var d = Math.abs(c); return d <= 5 ? 'afinado' : d <= 15 ? 'perto' : 'longe'; }

  function passo() {
    if (pausa > 0) {
      // Silêncio entre uma palhetada e outra: o rastro para e o marcador
      // continua mostrando a última corda confirmada.
      pausa--;
      historico.unshift(null);
      if (pausa === 0) {
        cents = (Math.random() < 0.5 ? -1 : 1) * (18 + Math.random() * 26);
        progresso = 0;
        confirmada = false;
      }
    } else {
      // Perto da nota a leitura oscila mais, entrando e saindo da
      // tolerância: o anel avança só enquanto ela está dentro.
      if (!confirmada) cents = cents * 0.955 + (Math.random() - 0.5) * (Math.abs(cents) < 10 ? 3.2 : 2.2);
      else cents = (Math.random() - 0.5) * 2;
      if (Math.abs(cents) <= 5) {
        progresso = Math.min(1, progresso + passoS / necessario);
      } else {
        progresso = Math.max(0, progresso - passoS / 2);
      }
      if (progresso >= 1 && !confirmada) { confirmada = true; segurar = 22; }
      if (confirmada && --segurar <= 0) pausa = 12;
      // Afinada, o ponto do rastro fica na linha do centro, com o marcador.
      historico.unshift(Math.abs(cents) <= 5 ? 0 : cents);
    }
    if (historico.length > 80) historico.length = 80;

    var d = { longe: '', perto: '', afinado: '' };
    for (var i = 0; i < historico.length - 1; i++) {
      var a = historico[i], b = historico[i + 1];
      if (a === null || b === null) continue;
      d[faixa((Math.abs(a) + Math.abs(b)) / 2)] += 'M' + x(a).toFixed(1) + ' ' + (92 + i * 3.4) + 'L' + x(b).toFixed(1) + ' ' + (92 + (i + 1) * 3.4);
    }
    for (var k in tracos) tracos[k].setAttribute('d', d[k] || 'M0 0');

    var afinada = confirmada || Math.abs(cents) <= 5;
    var estado = afinada ? 'afinado' : faixa(cents);
    var cor = cores[estado];
    bolha.setAttribute('transform', 'translate(' + (afinada ? 156 : x(cents)).toFixed(1) + ' 0)');
    aro.setAttribute('stroke', cor);
    aro.setAttribute('fill', confirmada ? fundoConfirmado : fundo);
    ponta.setAttribute('fill', cor);
    texto.textContent = afinada ? '✓' : (cents > 0 ? '+' : '−') + Math.round(Math.abs(cents));
    texto.setAttribute('fill', afinada ? cores.afinado : texto0);

    // Longe, sem anel: ele só aparece quando falta pouco.
    var p = confirmada ? 1 : estado === 'longe' ? 0 : progresso;
    anel.setAttribute('stroke-dashoffset', (voltaAnel * (1 - p)).toFixed(1));
    anel.setAttribute('opacity', p > 0 ? 1 : 0);

    linha.setAttribute('opacity', afinada ? 1 : 0);
    notaAro.setAttribute('stroke', afinada ? cores.afinado : aroNota);
    notaAro.setAttribute('stroke-width', afinada ? 2.5 : 2);
    for (var n = 0; n < notaTextos.length; n++) notaTextos[n].setAttribute('fill', afinada ? cores.afinado : texto0);
  }

  var timer = null;
  function iniciar() { if (!timer) timer = setInterval(passo, 70); }
  function parar() { clearInterval(timer); timer = null; }
  document.addEventListener('visibilitychange', function () { document.hidden ? parar() : iniciar(); });
  iniciar();
})();
