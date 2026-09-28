# Chave de assinatura

O Android só instala uma atualização se ela vier assinada com a **mesma chave** da versão já
instalada. Sem a chave, não sai atualização: quem tem o OpenTuner precisa desinstalar e instalar de
novo. Por isso a chave é gerada uma vez, guardada com cópia, e **nunca** trocada.

## Onde ela está

Preencha depois de gerar e de guardar as cópias. Aqui vai o **lugar**, nunca a senha, o alias ou o
arquivo (o repositório é público).

| | |
|---|---|
| Keystore principal | _a preencher: computador e pasta (fora do repositório)_ |
| Cópia 1 | _a preencher: ex. pendrive cifrado guardado em ..._ |
| Cópia 2 | _a preencher: ex. anexo no cofre de senhas_ |
| Senha e alias | _a preencher: cofre de senhas, separado do arquivo_ |
| Última conferência das cópias | _a preencher: data_ |
| Impressão digital SHA-256 do certificado | _a preencher na primeira release_ |

## Gerar (uma vez só)

Na máquina de quem guarda a chave, **nunca no CI**:

```bash
make chave        # o mesmo que tool/gerar_chave_release.sh
```

O script pergunta o alias, a senha (duas vezes, sem mostrar) e se a senha fica gravada no
`key.properties`; o `keytool` pergunta nome e organização, que vão no certificado e são públicos.
Ele cria `~/.opentuner-chaves/opentuner-release.jks` (RSA 4096, PKCS12, 10 000 dias; outra pasta com
`OPENTUNER_DIR_CHAVES=...`) e escreve `android/key.properties` com permissão `600`. Recusa rodar em
CI, sobrescrever keystore ou `key.properties`, criar o keystore dentro do repositório ou escrever o
`key.properties` se o `.gitignore` não o barrar.

Sem a senha gravada, o build a lê da variável `OPENTUNER_SENHA_CHAVE`:

```bash
read -rs OPENTUNER_SENHA_CHAVE && export OPENTUNER_SENHA_CHAVE
make release
```

## Guardar as cópias

Antes da primeira release, e não depois:

1. **Duas cópias do `.jks` fora deste computador**, em lugares diferentes (pendrive cifrado, anexo
   no cofre de senhas).
2. **Senha e alias num cofre de senhas**, separados do arquivo.
3. **Conferir que a cópia abre** noutra máquina, sem `key.properties`:

   ```bash
   tool/gerar_chave_release.sh --existente /caminho/da/copia/opentuner-release.jks
   ```

   Confere senha e alias contra o arquivo e escreve o `key.properties`. É o mesmo comando para
   montar um computador novo.
4. Preencher a tabela acima.

## Como o build usa a chave

`android/app/build.gradle.kts` lê `android/key.properties` quando ele existe:

- **com o arquivo**, o release (APK e `.aab`) sai assinado com a chave de release;
- **sem o arquivo**, sai com a chave de debug, e o Gradle e o `make apk`/`make aab` avisam. Clonar e
  compilar funciona para qualquer pessoa, mas esse build não atualiza a versão publicada e a Play
  Store recusa o `.aab`.

O `.gitignore` barra `key.properties`, `*.jks` e `*.keystore`. O CI só gera APK de debug; a chave
não entra nos segredos do GitHub.

Para conferir um APK: `apksigner verify --print-certs <apk>` (do `build-tools` do Android SDK). A
linha `Signer #1 certificate SHA-256 digest` é a impressão digital, pública e **sempre a mesma**.
`CN=Android Debug` quer dizer que o `key.properties` não foi encontrado. O `make release` faz essa
conferência sozinho.

## Play Store: Play App Signing

Na Play Store existem duas chaves: a **de assinatura do app**, com que o Google assina o que entrega
aos aparelhos, e a **de upload**, com que se assina o `.aab` enviado ao Play Console. A escolha é
feita **uma vez**, ao cadastrar o app:

- **Google gera a chave de assinatura** (o padrão). A daqui vira só a de upload. Mas o APK da loja e o
  do GitHub ficam com assinaturas diferentes, e quem trocar de canal precisa desinstalar.
- **Usar a própria chave** ("use my own key", exportada cifrada com a ferramenta que o Play Console
  indica). Loja e GitHub ficam com a mesma assinatura, e o Google guarda uma cópia dela.

**Escolha: a segunda**, porque `docs/REQUISITOS.md` pede os APKs do GitHub assinados pela mesma
chave da loja. A mesma chave pode seguir como chave de upload; uma chave de upload separada é
opcional e pode ser registrada depois no Play Console.

## Se algo der errado

- **A chave foi perdida.** Na Play Store, o Google tem a chave de assinatura e o Play Console
  permite trocar a de upload. No GitHub não há volta: nenhum APK novo atualiza os instalados, e quem
  usa precisa desinstalar e instalar de novo (perde as preferências). É por isso que ela **não pode**
  ser perdida.
- **A chave vazou** (arquivo e senha juntos). Pedir a troca da chave de upload no Play Console; para
  o GitHub, planejar a rotação com `apksigner rotate` (esquema v3, Android 9+) e publicar a nova
  impressão digital.
- **Nunca**: gerar uma chave nova "porque a senha se perdeu" e publicar com ela; pôr a chave, a
  senha ou o alias em commit, issue, chat, log ou segredo do CI.
