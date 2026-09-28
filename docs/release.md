# Processo de release

Uma release sai de um commit da `main` com o CI verde, é gerada e assinada **na máquina de quem
guarda a chave** e vai para dois lugares: os APKs para o **GitHub Releases** e o App Bundle
(`.aab`) para a **Play Store**. O CI nunca assina.

## Antes da primeira vez

- Chave de release gerada e com cópias guardadas: [assinatura.md](assinatura.md).
- Flutter na versão do CI (`.github/workflows/ci.yml`; `make verificar` confere) e o Android SDK
  com `ANDROID_HOME`: o script usa o `apksigner` e o `aapt2` dele.
- App cadastrado no Play Console com **a própria chave** como chave de assinatura
  ([assinatura.md](assinatura.md#play-store-play-app-signing)) e o material de
  [loja/](loja/README.md) preenchido. A verificação de desenvolvedor que o Android passou a exigir
  para instalar APK de fora da loja (no Brasil, desde 30/09/2026) se faz pelo mesmo Play Console,
  com o pacote registrado junto do certificado **público** da chave. Confira os passos atuais na
  documentação do Google: o processo é novo e ainda muda.

## Passo a passo

1. **Versão.** Em `pubspec.yaml`, `version: X.Y.Z+N`. `X.Y.Z` é o nome que as pessoas veem; `N` é
   o código da versão, que **só cresce** (o Android e a Play Store recusam um código menor ou
   repetido).

2. **Notas.** Em `docs/notas/vX.Y.Z.md`, no mesmo commit da versão: o que mudou. `{{certificado}}`
   no texto é trocado pela impressão digital do certificado.

3. **Gerar**, com a `main` atualizada e sem mudanças locais:

   ```bash
   make release      # o mesmo que tool/gerar_release.sh
   ```

   Recusa sem `android/key.properties`, com mudanças não commitadas, sem as notas ou se a tag da
   versão já apontar para outro commit. Gera em `build/release/vX.Y.Z/`:

   | Arquivo | Para quê |
   |---|---|
   | `opentuner-X.Y.Z-arm64-v8a.apk` | GitHub: a maioria dos celulares |
   | `opentuner-X.Y.Z-armeabi-v7a.apk` | GitHub: celulares ARM de 32 bits |
   | `opentuner-X.Y.Z-x86_64.apk` | GitHub: Chromebooks e emuladores x86 |
   | `opentuner-X.Y.Z.aab` | Play Store |
   | `SHA256SUMS.txt` | somas para quem baixa conferir |
   | `notas.md` | notas com a impressão digital preenchida |

   E confere: nenhuma chave de debug, o mesmo certificado em todos os APKs, nenhuma permissão do
   Android além de `RECORD_AUDIO`, e avisa se um APK passar dos 20 MB. A impressão digital do fim
   tem de ser a anotada em [assinatura.md](assinatura.md#onde-ela-está).

4. **Testar** num aparelho que já tem a versão anterior, por cima:
   `adb install -r build/release/vX.Y.Z/opentuner-X.Y.Z-arm64-v8a.apk`. Instalou sem desinstalar, a
   assinatura é a mesma. Depois, afinar uma corda de verdade.

5. **Marcar o commit:** `git tag -a vX.Y.Z -m "OpenTuner X.Y.Z" && git push origin vX.Y.Z`.

6. **GitHub Releases**, a partir da tag: os três APKs, o `SHA256SUMS.txt` e as notas. O fim da saída
   do script traz o `gh release create` pronto. O `.aab` **não** vai para o GitHub: o celular não
   abre esse arquivo.

7. **Play Store:** enviar o `.aab` ao **teste interno** no Play Console e, depois de instalar pela
   loja e conferir, promover para produção.

## Se der errado depois de publicado

Não se troca o arquivo de uma versão publicada: quem já baixou fica com o anterior, e a Play Store
não aceita o mesmo código duas vezes. Corrige-se com a versão seguinte (`X.Y.Z+1`, código `N+1`).
