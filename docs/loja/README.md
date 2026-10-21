# Material das lojas

Tudo o que as lojas pedem no cadastro, pronto para colar. Os textos da ficha ficam em
`ficha-en.md`, `ficha-pt.md` e `ficha-es.md`; os limites de caracteres de cada campo foram
conferidos.

## Dados do app

| Campo | Valor |
|---|---|
| Nome | OpenTuner |
| Id do pacote | `io.github.guilhermefeitosa66.opentuner` (não muda depois de publicado) |
| Categoria | Música e áudio |
| Preço | Grátis, sem compras no app |
| Contém anúncios | **Não** |
| Site | https://guilhermefeitosa66.github.io/open-tuner/ |
| Política de privacidade | https://guilhermefeitosa66.github.io/open-tuner/privacy/ |
| Termos de uso | https://guilhermefeitosa66.github.io/open-tuner/terms/ |
| E-mail de contato | [SEU E-MAIL DE DESENVOLVEDOR]: a Play Store exige e mostra na ficha |
| Idioma padrão da ficha | Inglês (en-US), com traduções pt-BR e es-419 |

As URLs só respondem depois do primeiro push na `main` com o GitHub Pages ligado (Settings → Pages
→ Source: "GitHub Actions").

## Google Play

### Segurança dos dados (Data safety)

- O app coleta ou compartilha algum dos tipos de dados obrigatórios? **Não.**
- Justificativa, se pedida: o áudio do microfone é processado em memória, no aparelho, e descartado.
  Não é gravado nem transmitido, e o app não tem permissão de internet. As preferências ficam só no
  aparelho.
- Os dados são criptografados em trânsito? Não se aplica (nada é transmitido).
- O usuário pode pedir a exclusão dos dados? Não se aplica (nada é coletado). Desinstalar apaga as
  preferências.

### Declaração de permissões

`RECORD_AUDIO`: "Used only while the tuner screen is open, to detect the pitch of the string being
played. Audio is analyzed in memory and never recorded or transmitted."

### Classificação de conteúdo (questionário IARC)

Todas as respostas são "não": sem violência, sexo, linguagem imprópria, drogas, jogos de azar,
interação entre usuários, compartilhamento de localização ou compras. O resultado esperado é
classificação livre (PEGI 3, ESRB Everyone, Livre no Brasil).

### Público-alvo

Recomendação para a primeira publicação: **13 anos ou mais**. Marcar faixas abaixo de 13 põe o app
no programa Famílias, com revisão mais demorada. Como o app não coleta nada, dá para incluir as
faixas infantis depois, sem mudar o código.

### Outras declarações

- Anúncios: não contém.
- App de notícias, saúde, finanças, governo: não.
- Acesso ao app: tudo disponível sem login.

### Imagens que faltam

| Item | Tamanho | Origem |
|---|---|---|
| Ícone | 512 × 512 PNG | `docs/marca/icone-app.svg` |
| Imagem de destaque (feature graphic) | 1024 × 500 PNG | a fazer, com o símbolo e o nome sobre a madeira |
| Capturas de celular | 2 a 8, 1080 × 1920 ou maiores | do app real, uma por idioma da ficha |

## App Store

| Campo | Valor |
|---|---|
| Bundle ID | `io.github.guilhermefeitosa66.opentuner` (o mesmo id do Android) |
| Aparelhos | Só iPhone, em retrato. No iPad roda no modo de compatibilidade e a ficha não pede capturas de iPad |
| Categoria | Música (secundária: Utilidades) |
| Subtítulo (30) | Ukulele, guitar & bass tuner |
| Palavras-chave (100) | tuner,ukulele,guitar,bass,cavaquinho,viola,chromatic,pitch,tuning,strings,acoustic |
| Privacidade (rótulo nutricional) | Data Not Collected |
| Criptografia | Não usa (`ITSAppUsesNonExemptEncryption` = falso no `Info.plist`) |
| `NSMicrophoneUsageDescription` | Em `ios/Runner/*.lproj/InfoPlist.strings`, um por idioma |
| Licença de uso | EULA padrão da Apple, citado nos termos de uso |
| Classificação etária | 4+: todas as respostas do questionário são "nenhum" |

### Build e envio

Não precisa de Mac. O workflow `iOS` (`.github/workflows/ios.yml`) compila sem assinatura em todo
push e, rodado à mão na aba Actions, assina e envia o build ao App Store Connect. A assinatura é a
gerenciada pela nuvem da Apple: nenhum certificado sai da conta da Apple. Diferente do Android,
aqui uma chave vai para os segredos do GitHub: a da API do App Store Connect. Ela pode ser revogada
a qualquer momento em Users and Access → Integrations, sem afetar o app publicado.

Configuração, uma vez só, depois que a conta de desenvolvedor estiver ativa:

1. **Bundle ID**: developer.apple.com → Certificates, IDs & Profiles → Identifiers → "+" → App IDs →
   App, com o id explícito acima e nenhuma capability marcada.
2. **App no App Store Connect**: Apps → "+" → New App: iOS, nome OpenTuner, idioma principal English
   (U.S.), o bundle id acima, SKU `opentuner`.
3. **Chave da API**: App Store Connect → Users and Access → Integrations → App Store Connect API →
   Team Keys → "+", papel **Admin** (o necessário para a assinatura na nuvem). Baixar o `.p8`, que
   só pode ser baixado uma vez, e anotar o Key ID e o Issuer ID.
4. **GitHub** (Settings → Secrets and variables → Actions):
   - segredos `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID` e `APP_STORE_CONNECT_KEY`
     (o conteúdo do `.p8`);
   - variável `APPLE_TEAM_ID`, o Team ID de developer.apple.com → Membership details.
5. Apagar o `.p8` da máquina depois de colar no GitHub, ou guardar junto da chave do Android.

A cada versão: Actions → iOS → Run workflow. O número do build é o da rodada do workflow; a versão
vem do `pubspec.yaml`. O build aparece no TestFlight em uns 15 minutos.

### Antes de mandar para a revisão

- [ ] Testar pelo TestFlight num iPhone de verdade: microfone, corda de referência tocando sem
      cortar o microfone, aviso de afinada, troca de idioma.
- [ ] Capturas de 6,9" (1320 × 2868 ou 1290 × 2796), de 3 a 10, uma série por idioma da ficha.
- [ ] URL de suporte (o site) e de política de privacidade preenchidas.
- [ ] App Privacy: "Data Not Collected".
- [ ] Notas para o revisor: o app só usa o microfone, não tem login; para testar, tocar qualquer
      corda ou assobiar perto do aparelho.

## Checklist antes de enviar

- [ ] Repositório público no GitHub e Pages publicado (site, privacy, terms abrindo).
- [ ] E-mail de contato definido.
- [ ] Chave de upload criada e guardada fora do repositório, com cópia de segurança.
- [ ] Ícones `mipmap-*` gerados a partir de `docs/marca/`.
- [ ] Capturas e imagem de destaque.
- [ ] `targetSdk` no mínimo o exigido pela Play Store na data.
- [ ] Manifest mesclado do release só com `RECORD_AUDIO` (`aapt2 dump permissions`).
- [ ] Busca do nome "OpenTuner" nas lojas e na WIPO Global Brand Database.
