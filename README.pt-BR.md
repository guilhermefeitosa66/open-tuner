<p align="center">
  🇺🇸 <a href="README.md">English</a> · 🇧🇷 <b>Português</b> · 🇪🇸 <a href="README.es.md">Español</a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/marca/simbolo-escuro.svg">
    <img src="docs/marca/simbolo-claro.svg" alt="" width="96">
  </picture>
</p>

<h1 align="center">OpenTuner</h1>

<p align="center">
  Afinador de instrumentos de corda. Livre, sem anúncios, sem conta e sem internet: abre, escuta a
  corda e diz se ela está frouxa, apertada ou afinada.
</p>

<p align="center">
  <a href="https://github.com/guilhermefeitosa66/open-tuner/releases/latest"><img src="https://img.shields.io/github/v/release/guilhermefeitosa66/open-tuner?style=for-the-badge&label=Baixar&color=6B4226" alt="Baixar a última versão"></a>
  &nbsp;
  <a href="https://guilhermefeitosa66.github.io/open-tuner/"><img src="https://img.shields.io/badge/Site-OpenTuner-6B4226?style=for-the-badge" alt="Site do projeto"></a>
  &nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/Licen%C3%A7a-Apache--2.0-6B4226?style=for-the-badge" alt="Licença Apache-2.0"></a>
</p>

## Baixar

**O OpenTuner 1.0.0 saiu**, para Android 7.0 ou mais novo.

- **GitHub Releases:** [versão mais recente](https://github.com/guilhermefeitosa66/open-tuner/releases/latest)
  (hoje, a [v1.0.0](https://github.com/guilhermefeitosa66/open-tuner/releases/tag/v1.0.0)).
- **Google Play:** em breve.

Cada versão tem um APK por tipo de processador. Escolha o do seu aparelho:

| Arquivo | Para |
|---|---|
| `opentuner-1.0.0-arm64-v8a.apk` | A maioria dos celulares (ARM de 64 bits). **Na dúvida, este.** |
| `opentuner-1.0.0-armeabi-v7a.apk` | Celulares mais antigos, com processador ARM de 32 bits |
| `opentuner-1.0.0-x86_64.apk` | Chromebooks com processador Intel ou AMD, e emuladores |

Abra o APK no celular. O Android pede para deixar o navegador ou o gerenciador de arquivos instalar
apps ("Instalar apps desconhecidos"); libere só para esse app.

Para atualizar, instale o APK novo por cima do que você tem: os ajustes continuam. O OpenTuner não
procura atualização sozinho (não tem acesso à internet). Para saber de uma versão nova, use **Watch
→ Custom → Releases** neste repositório.

### Conferir o que baixou

**O arquivo está inteiro.** O `SHA256SUMS.txt`, na mesma versão, traz o SHA-256 de cada APK. Com ele
na mesma pasta do APK:

```bash
sha256sum -c --ignore-missing SHA256SUMS.txt       # Linux
shasum -a 256 -c --ignore-missing SHA256SUMS.txt   # macOS
```

A linha do seu APK tem de terminar em `OK`. No Windows, `Get-FileHash <arquivo>.apk` no PowerShell
mostra a soma para comparar com a linha do `SHA256SUMS.txt` (maiúsculas e minúsculas não importam).

**Foi assinado pelo projeto.** Todos os APKs do OpenTuner são assinados pelo mesmo certificado, com
esta impressão digital SHA-256 (que também está nas notas da versão):

```
b8b7f73d8b7444f478f2ee19a7d3df61798d86a465b4b0dd5acf69bc9408834f
```

Para conferir, use o `apksigner` do `build-tools` do Android SDK:

```bash
apksigner verify --print-certs opentuner-1.0.0-arm64-v8a.apk
```

A linha `Signer #1 certificate SHA-256 digest` tem de mostrar exatamente essa impressão digital. O
Android faz a parte dele: recusa instalar por cima do OpenTuner uma atualização assinada com outra
chave.

## O que faz

O app inteiro é uma tela. Um marcador corre na horizontal sobre uma linha no centro:

- **à esquerda da linha:** a corda está frouxa. Aperte.
- **à direita da linha:** está apertada demais. Afrouxe.
- **na linha:** afinada.

O número no marcador é a distância até a nota, em cents. O rastro embaixo rola para baixo e mostra
os últimos segundos, o caminho da corda até a nota. A cor nunca é a única informação: todo estado
também tem posição, sinal (− ou +) e texto.

- **Exibição calma.** O número fica parado com a corda parada e anda em escada com a tarraxa. Nas
  cordas graves, o microfone do celular muitas vezes ouve os harmônicos no lugar da nota; o
  OpenTuner corrige isso.
- **Automático ou manual.** Com o **AUTO** ligado, o OpenTuner reconhece a corda tocada. Ou toque no
  botão de uma corda para fixá-la: ele também toca a nota dela, sintetizada no celular na afinação e
  na referência atuais, para afinar de ouvido.
- **Afinada.** Um anel verde fecha em volta do marcador, toca um aviso curto, o celular vibra de
  leve e a corda ganha um ✓ verde. Isso se repete toda vez que a corda volta à nota. **Recomeçar**
  limpa as marcas para afinar o próximo instrumento.
- **Ajustes:** tema claro ou escuro (ou o do sistema), notas em C D E ou Dó Ré Mi, referência do Lá
  (A4) de 430 a 450 Hz, precisão normal (±5 cents) ou fina (±2 cents), tela ligada enquanto afina,
  e o idioma: português, inglês ou espanhol. Por padrão segue o idioma do aparelho e, quando ele não
  é suportado, fica em inglês. Tudo fica guardado.

### Instrumentos

A primeira afinação de cada instrumento é a padrão, que já vem escolhida.

| Instrumento | Afinações |
|---|---|
| Ukulele | Padrão, Sol grave (Low G), Em Ré |
| Ukulele barítono | Padrão |
| Cavaquinho | Padrão, Natural |
| Violão / Guitarra (6 cordas) | Padrão, Drop D, Meio tom abaixo, Um tom abaixo, DADGAD, Open G, Open D |
| Violão 7 cordas | Sétima em Dó, Sétima em Si |
| Viola caipira | Cebolão em Mi, Cebolão em Ré, Rio abaixo |
| Baixo 4 cordas | Padrão, Drop D, Meio tom abaixo |
| Baixo 5 cordas | Padrão, Com Dó agudo |
| Baixo 6 cordas | Padrão |

Na viola caipira, os três pares mais graves são afinados em oitava, e o OpenTuner aceita qualquer
uma das duas cordas do par. As notas e frequências de cada afinação estão em
[docs/REQUISITOS.md](docs/REQUISITOS.md#2-instrumentos-e-afinações-da-versão-10).

## Privacidade

- **Uma permissão só, a do microfone.** O som é analisado na memória, no celular, e descartado.
  Nunca é gravado nem sai do aparelho.
- **Sem permissão de internet.** O OpenTuner não conseguiria enviar nada nem se quisesse, e
  funciona offline, sempre.
- **Sem anúncios, analytics, relatório de falhas remoto nem Google Play Services. Sem conta, sem
  compras no app.** Os ajustes ficam no celular, e desinstalar apaga tudo.
- O script de release recusa publicar um APK que peça qualquer permissão do Android além do
  microfone (`RECORD_AUDIO`).

Texto completo: [política de privacidade](https://guilhermefeitosa66.github.io/open-tuner/pt/privacy/)
(em inglês).

**Nunca anúncios.** Enquanto o projeto puder ser custeado e mantido na loja, não haverá anúncio,
compra dentro do app nem versão paga com recurso a mais. A promessa está no
[site](https://guilhermefeitosa66.github.io/open-tuner/), em público.

## Próximos passos

Android primeiro, iOS depois. Previsto depois da 1.0, sem data: Google Play, afinações
personalizadas, modo cromático, violão de 12 cordas, mais idiomas (pela comunidade), F-Droid e iOS.
O detalhe está no roteiro de [docs/REQUISITOS.md](docs/REQUISITOS.md#8-roteiro).

Fora de propósito: músicas, cifras, aulas, metrônomo, gravação, conta de usuário, nuvem, anúncios e
compras dentro do app.

## Desenvolvimento

Precisa de:

- Flutter 3.38.5, a versão do CI;
- Android SDK e um JDK que o Gradle aceite (o CI usa Java 17);
- um aparelho ou emulador com Android 7.0 ou mais novo.

```bash
git clone https://github.com/guilhermefeitosa66/open-tuner.git
cd open-tuner
make verificar      # confere Flutter, Android SDK, Java, pacotes e aparelhos
make dependencias   # flutter pub get
make rodar          # abre no aparelho conectado, com hot reload
```

`make` sem argumento lista todas as tarefas.

| Comando | O que faz |
|---|---|
| `make verificar` | Confere Flutter, Android SDK, Java, pacotes e aparelhos conectados |
| `make dependencias` | `flutter pub get`, que gera também as classes de texto de `lib/l10n/` |
| `make textos` | Gera `lib/l10n/textos*.dart` a partir dos ARB (`flutter gen-l10n`) |
| `make rodar` | Roda em modo de desenvolvimento, com hot reload |
| `make emuladores` | Lista os emuladores Android (AVDs) |
| `make emulador AVD=<nome>` | Abre um emulador que escuta o microfone do computador |
| `make testar` | Formatação, análise e testes, como no CI |
| `make analisar` | Análise estática (`dart analyze lib test`) |
| `make formatar` | Formata o código de `lib` e `test` |
| `make apk` | APKs de release, um por arquitetura |
| `make instalar` | Gera os APKs e instala o da arquitetura do aparelho por cima do instalado, sem apagar dados |
| `make aab` | App Bundle de release, o formato da Play Store |
| `make site` | Serve `site/` em http://localhost:8000/ |
| `make desatualizadas` | Lista os pacotes que têm versão mais nova |
| `make limpar` | Apaga o que os builds geraram (`flutter clean`) |

Com mais de um aparelho conectado, acrescente `DISPOSITIVO=<id>` (ids em `flutter devices`). `make
chave` e `make release` são de quem guarda a chave de assinatura:
[docs/assinatura.md](docs/assinatura.md) e [docs/release.md](docs/release.md).

Para rodar os testes direto:

```bash
flutter test                                  # suíte completa
flutter test test/dominio/nota_test.dart      # um arquivo
flutter test --plain-name 'A4'                # testes por nome
```

Bom saber:

- **Análise.** `make analisar` roda `dart analyze lib test`, e não `flutter analyze`: no Linux o
  segundo vigia o pub cache por inotify e pode falhar com `Too many open files`. O CI sobe esse
  limite e roda o `flutter analyze`.
- **Microfone do emulador.** Aberto sem `-allow-host-audio`, o emulador entrega silêncio ao app e o
  ponteiro nunca se mexe; o `make emulador` passa essa opção. Se ainda assim não chegar som, libere
  também "Virtual microphone uses host audio input" em Extended controls → Microphone, na janela do
  emulador.
- **O seu próprio build.** Sem `android/key.properties`, o release sai assinado com a chave de
  debug. Instala e roda, mas não atualiza um OpenTuner baixado das releases: desinstale aquele antes
  (os ajustes dele se perdem).

### Onde está o quê

| Caminho | O que tem |
|---|---|
| `lib/dominio/` | Dart puro, sem Flutter: nota, tabela de instrumentos e afinações, detector de frequência, correção de harmônicos, filtro de Kalman e escolha de corda. Os testes que importam moram aqui. |
| `lib/audio/` | Captura do microfone, e a nota de cada corda e o aviso de afinada, sintetizados no código |
| `lib/features/` | A tela do afinador e a folha de ajustes |
| `lib/dados/` | Preferências guardadas |
| `lib/app/` | Montagem do app, tokens de cor (`tema.dart`) e escolha do idioma (`idioma.dart`) |
| `lib/l10n/` | Textos, um ARB por idioma, e as classes geradas deles (versionadas) |
| `test/` | Testes, na mesma organização de `lib/` |
| `tool/` | Scripts por trás do `make`: ambiente, instalação, chave, release, ícones |
| `site/` | O site, publicado no GitHub Pages pelo workflow `Site` |
| `docs/` | Documentação do projeto |

## Como contribuir

O código é escrito em português: nomes de classes, métodos e variáveis (`Nota`, `centsEntre`),
comentários, mensagens de commit e a documentação de `docs/`. Issues são bem-vindas em português,
inglês ou espanhol.

- **Erros:** [abra uma issue](https://github.com/guilhermefeitosa66/open-tuner/issues) com o modelo
  do celular, a versão do Android, o instrumento e a afinação, e o que a tela mostrou.
- **Falta uma afinação ou instrumento:** abra uma issue com as notas, da corda de cima para a de
  baixo. As afinações vivem numa tabela só, `lib/dominio/afinacoes.dart`.
- **Traduções:** os textos ficam em `lib/l10n/`. `app_en.arb` é o modelo, com a descrição de cada
  texto; `app_pt.arb` e `app_es.arb` são as traduções. Para corrigir um texto, edite os ARB e rode
  `flutter pub get`, que regenera `lib/l10n/textos*.dart`. Um idioma novo precisa também de uma
  entrada em `lib/app/idioma.dart` e em `test/l10n/arb_test.dart`: abra uma issue antes e a gente
  monta junto. Tradução automática só é publicada depois da revisão de quem fala o idioma. A
  tradução pela comunidade num Weblate hospedado está prevista.
- **Pull requests:** rode `make testar` antes de enviar (o CI faz as mesmas conferências). Nenhum
  texto visível ao usuário fica escrito no código: vai nos três ARB, e um teste reprova se eles não
  tiverem as mesmas chaves. Nenhuma dependência que traga a permissão de internet, anúncios,
  analytics ou Google Play Services. E Android primeiro, mas sem plugin nem código nativo que prenda
  o app ao Android. Antes de uma tela ou regra nova, leia [docs/REQUISITOS.md](docs/REQUISITOS.md).

## Documentação

Em `docs/`:

- [REQUISITOS.md](docs/REQUISITOS.md): o que a 1.0 faz, tabela de afinações com frequências,
  paleta, arquitetura e roteiro.
- [notas/v1.0.0.md](docs/notas/v1.0.0.md): notas da versão 1.0.0.
- [release.md](docs/release.md): como uma release é gerada, assinada e publicada.
- [assinatura.md](docs/assinatura.md): a chave de assinatura e como conferir.
- [loja/](docs/loja/README.md): fichas das lojas (en, pt, es), segurança de dados e checklist de
  publicação.
- [marca/](docs/marca/README.md): o símbolo e o ícone do app.

O [site](https://guilhermefeitosa66.github.io/open-tuner/pt/), com a [política de privacidade](https://guilhermefeitosa66.github.io/open-tuner/pt/privacy/) e os
[termos de uso](https://guilhermefeitosa66.github.io/open-tuner/pt/terms/), está em português, [inglês](https://guilhermefeitosa66.github.io/open-tuner/) e [espanhol](https://guilhermefeitosa66.github.io/open-tuner/es/): os botões de
bandeira no alto de cada página trocam o idioma. O código dele está em `site/`, e um texto novo
entra nas três versões.

## Licença

[Apache 2.0](LICENSE). O nome e o logotipo do OpenTuner não fazem parte da licença: uma versão
derivada precisa de outro nome e outro ícone.
