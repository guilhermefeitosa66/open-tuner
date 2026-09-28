# Requisitos do OpenTuner

Versão 1 do documento, setembro de 2026. Descreve o que a versão 1.0 do aplicativo precisa fazer,
o que fica para depois e o que está fora de propósito.

## 1. O que é

Um afinador de instrumentos de corda para Android, livre, sem anúncios e sem conta. Abre, escuta
a corda e mostra se ela está frouxa, apertada ou afinada. Nada além disso.

A interface parte do afinador do GuitarTuna, que resolveu bem a leitura do estado da corda: um
ponteiro que corre na horizontal e deixa um rastro rolando para baixo. O que muda é o resto. A barra
inferior, que lá leva a músicas, aulas e ferramentas, aqui só escolhe instrumento e afinação.

### Princípios

- **Uma tela.** O afinador é o aplicativo. Instrumento, afinação e ajustes abrem por cima dele, em
  folhas que sobem da barra inferior, e fecham de volta para o afinador.
- **Funciona sem internet, sempre.** O APK não declara a permissão de internet.
- **Só o microfone.** É a única permissão pedida. O áudio é analisado em memória e descartado: não
  é gravado em disco nem sai do aparelho.
- **Sem anúncios, sem rastreamento, sem serviços do Google.** Nenhuma biblioteca de analytics,
  crash reporting remoto ou publicidade. Isso também deixa o app apto para o F-Droid.
- **A cor nunca é a única informação.** Todo estado também tem posição (esquerda, centro, direita),
  sinal (−, +) e texto ("Aperte a corda").
- **Nunca anúncios.** Enquanto o projeto puder ser custeado e mantido na loja, não haverá anúncio,
  compra dentro do app nem versão paga com recurso a mais. A promessa está no site, em público.

### Onde vai estar

A distribuição é global, Android primeiro e iOS depois.

- **Google Play**, em Android App Bundle, com a ficha da loja em inglês, português e espanhol. No
  formulário de segurança de dados: nenhum dado coletado nem compartilhado.
- **GitHub Releases**, com os APKs assinados pela mesma chave da loja, para quem não usa a Play Store.
- **F-Droid**, depois da 1.0. Nada no projeto pode impedir isso (seção 4, Privacidade).
- **App Store**, depois que a versão Android estiver estável (seção 4, Plataformas).
- **Site** em `site/`, publicado no GitHub Pages, em inglês: apresentação, a promessa de não ter
  anúncios e a política de privacidade que as lojas exigem
  (`https://guilhermefeitosa66.github.io/open-tuner/privacy/`).

## 2. Instrumentos e afinações da versão 1.0

A afinação **padrão** de cada instrumento é a primeira da lista e é a escolhida ao trocar de
instrumento. As notas estão na ordem física, da corda de cima para a de baixo com o instrumento em
posição de tocar; por isso o ukulele começa em G4, que é mais aguda que a C4 seguinte (afinação
reentrante).

| Instrumento | Afinação | Cordas (Hz com A4 = 440) |
|---|---|---|
| Ukulele (soprano, concerto, tenor) | Padrão *(padrão)* | G4 392,00 · C4 261,63 · E4 329,63 · A4 440,00 |
|  | Sol grave (Low G) | G3 196,00 · C4 261,63 · E4 329,63 · A4 440,00 |
|  | Em Ré | A4 440,00 · D4 293,66 · F♯4 369,99 · B4 493,88 |
| Ukulele barítono | Padrão *(padrão)* | D3 146,83 · G3 196,00 · B3 246,94 · E4 329,63 |
| Cavaquinho | Padrão *(padrão)* | D4 293,66 · G4 392,00 · B4 493,88 · D5 587,33 |
|  | Natural | D4 293,66 · G4 392,00 · B4 493,88 · E5 659,26 |
| Violão | Padrão *(padrão)* | E2 82,41 · A2 110,00 · D3 146,83 · G3 196,00 · B3 246,94 · E4 329,63 |
|  | Drop D | D2 73,42 · A2 110,00 · D3 146,83 · G3 196,00 · B3 246,94 · E4 329,63 |
|  | Meio tom abaixo | E♭2 77,78 · A♭2 103,83 · D♭3 138,59 · G♭3 185,00 · B♭3 233,08 · E♭4 311,13 |
|  | Um tom abaixo | D2 73,42 · G2 98,00 · C3 130,81 · F3 174,61 · A3 220,00 · D4 293,66 |
|  | DADGAD | D2 73,42 · A2 110,00 · D3 146,83 · G3 196,00 · A3 220,00 · D4 293,66 |
|  | Open G | D2 73,42 · G2 98,00 · D3 146,83 · G3 196,00 · B3 246,94 · D4 293,66 |
|  | Open D | D2 73,42 · A2 110,00 · D3 146,83 · F♯3 185,00 · A3 220,00 · D4 293,66 |
| Violão 7 cordas | Sétima em Dó *(padrão)* | C2 65,41 · E2 82,41 · A2 110,00 · D3 146,83 · G3 196,00 · B3 246,94 · E4 329,63 |
|  | Sétima em Si | B1 61,74 · E2 82,41 · A2 110,00 · D3 146,83 · G3 196,00 · B3 246,94 · E4 329,63 |
| Viola caipira (5 pares) | Cebolão em Mi *(padrão)* | B2 123,47 · E3 164,81 · G♯3 207,65 · B3 246,94 · E4 329,63 |
|  | Cebolão em Ré | A2 110,00 · D3 146,83 · F♯3 185,00 · A3 220,00 · D4 293,66 |
|  | Rio abaixo | G2 98,00 · D3 146,83 · G3 196,00 · B3 246,94 · D4 293,66 |
| Baixo 4 cordas | Padrão *(padrão)* | E1 41,20 · A1 55,00 · D2 73,42 · G2 98,00 |
|  | Drop D | D1 36,71 · A1 55,00 · D2 73,42 · G2 98,00 |
|  | Meio tom abaixo | E♭1 38,89 · A♭1 51,91 · D♭2 69,30 · G♭2 92,50 |
| Baixo 5 cordas | Padrão *(padrão)* | B0 30,87 · E1 41,20 · A1 55,00 · D2 73,42 · G2 98,00 |
|  | Com Dó agudo | E1 41,20 · A1 55,00 · D2 73,42 · G2 98,00 · C3 130,81 |
| Baixo 6 cordas | Padrão *(padrão)* | B0 30,87 · E1 41,20 · A1 55,00 · D2 73,42 · G2 98,00 · C3 130,81 |

A faixa que o detector precisa cobrir vai de **B0 (30,87 Hz)** a **E5 (659,26 Hz)**, com folga para
uma corda muito frouxa ou muito apertada: 28 Hz a 1.400 Hz.

**Viola caipira.** Os três pares mais graves são afinados em oitava: cada par tem uma corda na nota
da tabela e outra uma oitava acima (o 3º par do Cebolão em Mi é G♯3 e G♯4). Os dois mais agudos são
em uníssono. O alvo de cada par é a nota da tabela, e o detector aceita também a oitava de cima do
mesmo par (RF-04). As oitavas do Rio abaixo precisam ser conferidas com um violeiro antes da versão
1.0 (seção 9).

As afinações vivem numa tabela de dados em `lib/dominio/`, não espalhadas pela interface: acrescentar
uma afinação nova é acrescentar uma linha.

## 3. Requisitos funcionais

### Escuta e detecção

**RF-01 · Captura.** Enquanto a tela do afinador estiver visível, o app captura o microfone em PCM
16 bits, mono, a 44,1 kHz ou 48 kHz (o que o aparelho oferecer). A captura para quando o app vai para
segundo plano ou a tela apaga, e volta sozinha ao retornar.

**RF-02 · Frequência fundamental.** O detector estima a frequência fundamental por YIN ou McLeod
(MPM), implementado em Dart puro para ser testável sem aparelho. Requisitos:

- janela adaptativa: 4.096 amostras quando o instrumento for baixo (B0 tem período de 32 ms e o
  método precisa de pelo menos dois períodos na janela), 2.048 para os demais;
- sobreposição entre janelas para entregar **pelo menos 20 leituras por segundo**;
- precisão de **±1 cent** em sinal limpo de 30 Hz a 1.000 Hz;
- rejeição de leitura quando a confiança do algoritmo ou a energia do sinal ficam abaixo do limiar,
  para que silêncio e ruído de fundo não movam o ponteiro;
- suavização da leitura (mediana curta mais média exponencial) sem atraso perceptível: o ponteiro
  precisa acompanhar a mão girando a tarraxa.

**RF-03 · Cents.** O desvio é `1200 × log2(f_medida / f_alvo)`, com `f_alvo` calculada pelo
temperamento igual a partir da referência A4 (RF-17).

**RF-04 · Modo automático** (ligado por padrão, chave "Auto" no topo). O alvo é a corda da afinação
mais próxima da nota tocada, em cents. Para não pular entre cordas vizinhas, a troca de alvo só
acontece depois de 5 leituras consecutivas apontando para outra corda. Na viola caipira, a oitava de
cima de um par conta como o próprio par.

**RF-05 · Modo manual.** Tocar no botão de uma corda fixa aquela corda como alvo, desliga o Auto e
toca o som da corda, na afinação e na referência A4 atuais, para afinar de ouvido. O som é
sintetizado no próprio app (harmônicos de corda dedilhada na frequência exata), então serve para
qualquer afinação sem gravação nenhuma. Enquanto ele soa, o afinador ignora o microfone, senão a
referência marcaria a si mesma como afinada. Ligar o Auto de novo devolve a escolha ao detector.

### O afinador

**RF-06 · Indicador.** Um círculo no alto da área do gráfico mostra o desvio em cents, com sinal
(−22, +11). A posição horizontal é proporcional ao desvio, de −50 cents na borda esquerda a +50 na
direita, passando pela linha vertical do centro:

- **à esquerda da linha:** corda frouxa, texto "Aperte a corda" e seta para cima;
- **à direita da linha:** corda apertada demais, texto "Afrouxe a corda" e seta para baixo;
- **na linha:** afinada, o número dá lugar a um ✓ e o texto passa a "Afinada".

Além de ±50 cents o círculo fica preso na borda. Os símbolos ♭ e ♯ marcam os dois lados.

**RF-07 · Rastro.** Abaixo do indicador, cada leitura deixa um ponto que rola para baixo, formando a
onda do que aconteceu nos últimos 5 segundos (cerca de 80 leituras), a mais nova no alto. Leituras
rejeitadas (silêncio) deixam um vão. O rastro esmaece perto da cabeça do instrumento.

**RF-08 · Estados e cores.** A distância define a cor do indicador e de cada trecho do rastro:

| Estado | Condição | Claro | Escuro |
|---|---|---|---|
| Afinado | dentro da tolerância (±5 cents; ±2 na precisão fina) | `#2A7353` | `#5CC592` |
| Perto | até 15 cents | `#8A6400` | `#E6C24F` |
| Longe | mais de 15 cents | `#B04A1C` | `#EE8A52` |

**RF-09 · Corda afinada.** A corda solta oscila em volta da nota enquanto morre, então o tempo na
nota é somado, não seguido: 1 segundo dentro da tolerância, com idas e vindas, nos últimos 2,5
segundos marca a corda. Enquanto soma, um anel verde fecha pela borda do indicador (só perto ou
afinada; longe, não aparece); fechado, o indicador enche de verde. Marcada, a corda fica verde no
botão (fundo, anel e selo), na tarraxa e no fio; o aparelho vibra uma vez, curto, e toca um aviso
curto de dois sinos, também sintetizado. As marcas somem ao trocar de
instrumento ou de afinação, e depois de 2 minutos sem nenhuma corda tocada.

**RF-10 · Nota alvo.** Sobre a linha do centro, um círculo menor mostra a nota alvo com a oitava
(E⁴), e embaixo dele a frequência medida ("327,4 Hz").

**RF-11 · Cabeça do instrumento.** Na metade de baixo, o desenho da cabeça do instrumento com as
tarraxas. Metade das cordas de cada lado, a mais grave embaixo à esquerda; com número ímpar de cordas
o lado esquerdo fica com uma a mais. Cada tarraxa tem ao lado um botão redondo com a nota da corda.
A corda alvo fica destacada no botão, na tarraxa e no fio da corda. O desenho é vetorial e muda
com o instrumento, com as tarraxas sempre nas mesmas alturas para os botões não saírem do lugar:
ukulele (coroa arredondada, tarraxas de botão), cavaquinho (bico no alto, tarraxas borboleta de
metal), violão (cabeça vazada com rolos, estilo clássico), viola caipira (recorte em lóbulos,
losango de madrepérola e duas tarraxas por par) e baixo (topo inclinado, tarraxas grandes, cordas
grossas). Trocar de instrumento funde um desenho no outro.

**RF-12 · Espera.** Sem corda tocada, o indicador fica no centro, vazio, e uma mensagem pede "Toque
qualquer corda para começar".

### Barra inferior e seletores

**RF-13 · Barra inferior.** Dois botões, lado a lado, e nada mais:

- **Instrumento**, com o nome e a quantidade de cordas ("Violão · 6 cordas", "Viola caipira · 5 pares");
- **Afinação**, com o nome e as notas ("Drop D · D A D G B E").

Cada um abre uma folha que sobe de baixo. A folha fecha ao escolher, ao tocar fora dela, ao
arrastar para baixo ou com o botão voltar.

**RF-14 · Escolher instrumento.** Lista agrupada (Ukulele e cavaquinho · Violão e viola · Baixo).
Cada linha mostra a quantidade de cordas, o nome e as notas da afinação padrão; a linha atual tem ✓.
Escolher um instrumento aplica a afinação padrão dele.

**RF-15 · Escolher afinação.** Lista das afinações do instrumento atual, cada uma com o nome e as
notas em fichas. A atual fica destacada com borda na cor de destaque e ✓.

**RF-16 · Sustenido ou bemol.** O nome das notas segue a afinação: "Meio tom abaixo" mostra E♭ A♭
D♭, e não D♯ G♯ C♯.

### Ajustes

Abertos pelo ícone no canto do topo, na mesma folha que sobe de baixo.

**RF-17 · Opções.**

| Ajuste | Opções | Padrão |
|---|---|---|
| Tema | Sistema · Claro · Escuro | Sistema |
| Nome das notas | C D E · Dó Ré Mi | C D E |
| Precisão | Normal (±5 cents) · Fina (±2 cents) | Normal |
| Referência do Lá (A4) | 430 a 450 Hz, de 1 em 1 | 440 Hz |
| Manter a tela ligada | ligado · desligado | ligado, só com o afinador aberto |

**RF-18 · Memória.** Instrumento, afinação, modo Auto e ajustes são guardados no aparelho e
restaurados ao abrir.

### Permissão do microfone

**RF-19.** Na primeira abertura, antes do pedido do sistema, uma explicação curta: o microfone é
usado só para ouvir a corda, e nada é gravado. Se a permissão for negada, a área do gráfico mostra o
motivo e um botão que abre as configurações do app no Android. O resto da interface continua
utilizável: dá para escolher instrumento e afinação.

## 4. Requisitos não funcionais

**Desempenho.** Do som ao ponteiro, no máximo 100 ms. O rastro anima a 60 quadros por segundo em
aparelho intermediário. A detecção roda num isolate próprio se medir mais de 5 ms por janela no
aparelho mais fraco de teste.

**Bateria.** Nenhum trabalho em segundo plano. O microfone só fica aberto com a tela do afinador em
primeiro plano (RF-01).

**Compatibilidade.** Android 7.0 (API 24) ou mais novo, com o `targetSdk` que a Play Store exigir
na data da publicação. Android App Bundle na loja; APKs separados por ABI (arm64-v8a, armeabi-v7a,
x86_64) no GitHub. Só orientação retrato na versão 1.0.

**Plataformas.** Android primeiro, iOS depois, e nenhuma escolha de agora pode prender o código ao
Android:

- plugins de áudio, permissão e tela ligada precisam ter suporte a iOS (`record`,
  `permission_handler` e `wakelock_plus` têm);
- código nativo só com o equivalente em iOS planejado;
- a pasta `ios/` entra quando a versão iOS começar, com o texto de `NSMicrophoneUsageDescription`
  traduzido em cada idioma (`InfoPlist.strings`).

**Tamanho.** APK de release de no máximo 20 MB por ABI, com as fontes incluídas.

**Privacidade.** Única permissão declarada: `RECORD_AUDIO`. O áudio nunca é gravado nem transmitido.
Sem analytics, anúncios, crash reporting remoto ou dependência do Google Play Services. Política de
privacidade publicada junto com o app.

**Acessibilidade.**

- alvos de toque de no mínimo 48 dp;
- contraste AA em todo texto nos dois temas (conferido na paleta, seção 5);
- estado da corda anunciado pelo TalkBack só quando muda (frouxa, apertada, afinada), no máximo uma
  vez por segundo, para não atropelar o leitor;
- botões de corda com rótulo falado ("Corda E4, afinada");
- texto até 130% do tamanho do sistema sem cortar nem sobrepor;
- nenhuma informação só por cor (princípios, seção 1).

**Idiomas.** O app segue o idioma do aparelho. Se nenhum dos idiomas preferidos do usuário for
suportado, usa inglês.

- idiomas da 1.0: inglês (modelo e reserva), português e espanhol, em `lib/l10n/app_*.arb`. Um
  teste garante que todos os arquivos têm as mesmas chaves;
- a escolha é pelo idioma, não pelo país: pt-PT e pt-BR usam `pt`, es-MX usa `es`. Uma variante
  regional ganha arquivo próprio só quando algum texto precisar mudar;
- no Android 13 ou mais novo, o idioma do app pode ser trocado nas configurações do sistema
  (`res/xml/locales_config.xml`), sem ajuste dentro do app;
- nomes de instrumentos e afinações são textos traduzidos. O domínio só conhece ids;
- números no formato do idioma, pelo `intl`: 327,4 Hz em português e espanhol, 327.4 Hz em inglês.
  Nunca vírgula ou ponto fixos no código;
- nomes das notas: C D E em todos os idiomas por padrão, ou solfejo com a grafia do idioma (Dó Ré Mi
  em português, Do Re Mi em espanhol). A notação alemã (H para Si, B para Si bemol) entra junto com
  o alemão;
- idiomas escritos da direita para a esquerda (árabe, hebraico, persa): a interface espelha, **o
  gráfico do afinador não**. Grave à esquerda e agudo à direita é convenção musical, e ♭ e ♯ ficam
  onde estão;
- textos mais longos (alemão, russo) precisam caber: os botões da barra inferior cortam com
  reticências e nunca escondem a quantidade de cordas;
- depois da 1.0, tradução pela comunidade num Weblate hospedado (gratuito para projeto livre).
  Tradução automática não é publicada sem revisão de quem fala o idioma.

**Qualidade.**

- testes unitários do detector com sinais sintéticos: seno puro, seno com harmônicos fortes (o caso
  do baixo, em que o segundo harmônico pode ser mais forte que a fundamental), ruído branco e
  silêncio, de 30 Hz a 1.000 Hz, exigindo ±1 cent;
- testes da escolha de corda do modo Auto, inclusive a histerese e as oitavas da viola;
- testes de widget dos estados da tela;
- CI rodando formatação, análise, testes e build do APK a cada push.

## 5. Interface

O design está no canvas do Claude Design do projeto (paleta, marca e 14 telas, com um protótipo
interativo do afinador). Resumo do que o código precisa reproduzir:

**Paleta "Nogueira".** Madeira escura como cor de destaque, reservada ao acabamento (marca, botões
selecionados, chaves). Verde, amarelo e laranja pertencem só aos estados da corda.

| Token | Claro | Escuro |
|---|---|---|
| fundo | `#F5EFE6` | `#14110E` |
| superfície | `#FFFBF5` | `#1E1915` |
| superfície alta | `#EDE4D6` | `#2A231D` |
| grade | `#E3D8C8` | `#2A241E` |
| texto | `#231A13` | `#F3EBE0` |
| texto secundário | `#6E5E50` | `#B3A597` |
| destaque (accent) | `#6B4226` | `#C9935F` |
| sobre o destaque | `#FFF8EF` | `#1A120B` |
| madeira da cabeça | `#7A4A2A` | `#7A4A2A` |
| madeira escura | `#4E2E18` | `#4E2E18` |

Os tokens já estão em `lib/app/tema.dart` como `CoresOpenTuner`.

**Tipografia.** Fraunces para a marca, os nomes das notas e os títulos das folhas; Manrope para o
resto, com algarismos tabulares nos cents e na frequência. As duas vão empacotadas em
`assets/fontes/`, porque o app não tem internet.

**Disposição**, de cima para baixo: topo com a marca, a chave Auto e o ícone de ajustes; área do
gráfico (indicador, rastro, nota alvo) ocupando metade da tela; cabeça do instrumento com os botões
de corda; barra inferior com Instrumento e Afinação.

**Marca.** Uma palheta com a onda do afinador dentro, oscilando e se acalmando até a linha do centro.
Arquivos em `docs/marca/`.

## 6. Arquitetura proposta

Mesma organização do slap-mobile: código, nomes e comentários em português, camadas que só dependem
para baixo.

```
features → dominio → core
   ↓
 dados (preferências)
```

- `lib/dominio/`: Dart puro, sem Flutter. `Nota`, tabela de instrumentos e afinações, detector de
  frequência, escolha de corda (Auto com histerese), classificação do estado (afinado, perto, longe).
  É onde estão os testes que importam.
- `lib/dados/`: preferências do usuário (`shared_preferences`).
- `lib/l10n/`: os textos, um ARB por idioma, e as classes geradas pelo `gen-l10n` (versionadas).
  `lib/app/idioma.dart` escolhe o idioma a partir das preferências do aparelho.
- `lib/features/afinador/`: a tela, o rastro (um `CustomPainter`), a cabeça do instrumento (outro
  `CustomPainter`) e as folhas de seleção.
- Captura de áudio: o plugin `record`, que entrega PCM em stream no Android. Se ele não servir, um
  canal de plataforma com `AudioRecord` é pequeno o bastante para escrever à mão.
- Estado: `ChangeNotifier` e `ValueNotifier` (`ControladorAfinador`), sem Riverpod: é uma tela só, e o
  ponteiro escuta só o que muda a cada leitura, sem reconstruir a árvore.
- Tela ligada: `wakelock_plus`, só enquanto o afinador estiver em primeiro plano.

## 7. Fora da versão 1.0

**Depois (1.1 em diante):**

- afinações personalizadas, criadas e salvas pelo usuário;
- versão iOS;
- tom de referência: toque longo no botão da corda toca a nota;
- modo cromático, sem instrumento, mostrando qualquer nota;
- violão de 12 cordas;
- mais idiomas pela comunidade (francês, alemão, italiano, japonês e outros), com a notação alemã;
- publicação no F-Droid.

**Fora de propósito:** músicas, cifras, aulas, metrônomo, gravação, conta de usuário, nuvem,
anúncios, compras dentro do app.

## 8. Roteiro

| Versão | Entrega |
|---|---|
| 0.1 | Esqueleto: projeto, tema claro e escuro, modelo de nota, idiomas (en, pt, es), site, CI. **Feito.** |
| 0.2 | Detector de frequência e escolha de corda, com a suíte de testes de sinais sintéticos. **Feito.** |
| 0.3 | Captura do microfone e tela do afinador: indicador, rastro, nota alvo. **Feito.** |
| 0.4 | Cabeça do instrumento, barra inferior, folhas de instrumento e afinação, memória. **Feito.** |
| 0.5 | Ajustes, permissão, acessibilidade, fontes e ícone do app. **Feito; falta validar num aparelho.** |
| 1.0 | Teste com instrumentos reais (ukulele, violão, baixo, viola), publicação na Play Store e no GitHub Releases. |

## 9. Em aberto

- **Oitavas da viola caipira no Rio abaixo.** Conferir com um violeiro, ou numa referência
  confiável, antes da 1.0.
- **Nome na loja.** Verificar se "OpenTuner" colide com outro app ou marca na Play Store, no F-Droid
  e na App Store antes de publicar. Com distribuição global, vale uma busca nas bases de marcas
  (WIPO Global Brand Database) também.
- **Critério para limpar as marcas de corda afinada.** Os 2 minutos da RF-09 são um palpite; ajustar
  depois de usar com o instrumento na mão.
