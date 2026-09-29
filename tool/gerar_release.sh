#!/usr/bin/env bash
# Gera os arquivos de uma release assinada: os APKs do GitHub Releases, um por
# arquitetura, o App Bundle da Play Store e as somas SHA-256, em
# build/release/v<versão>/.
#
# Roda só na máquina de quem guarda a chave, nunca no CI. Recusa gerar com a
# chave de debug, com mudanças não commitadas, ou com uma tag da versão que
# aponte para outro commit. Ver docs/release.md.

set -euo pipefail

falhar() {
  printf 'Erro: %s\n' "$1" >&2
  exit 1
}

aviso() {
  printf 'Aviso: %s\n' "$1" >&2
}

if [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
  falhar "a release é gerada e assinada localmente, não no CI."
fi

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$raiz"

FLUTTER="${FLUTTER:-flutter}"

[[ -f android/key.properties ]] ||
  falhar "android/key.properties não encontrado: o build sairia com a chave de debug. Ver docs/assinatura.md."

linha="$(grep -E '^version:' pubspec.yaml || true)"
[[ "$linha" =~ ^version:\ *([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\ *$ ]] ||
  falhar "a versão do pubspec.yaml precisa estar no formato X.Y.Z+N."
versao="${BASH_REMATCH[1]}"
codigo="${BASH_REMATCH[2]}"
tag="v$versao"

[[ -z "$(git status --porcelain)" ]] ||
  falhar "há mudanças não commitadas. A release sai de um commit, para poder ser refeita."

notas="docs/notas/$tag.md"
[[ -f "$notas" ]] ||
  falhar "escreva as notas da versão em $notas antes (ver docs/release.md)."

commit="$(git rev-parse HEAD)"
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  [[ "$(git rev-list -n 1 "$tag")" == "$commit" ]] ||
    falhar "a tag $tag já existe e aponta para outro commit. Aumente a versão no pubspec.yaml."
fi

printf 'Release %s (código %s), commit %s\n\n' "$versao" "$codigo" "${commit:0:12}"

"$FLUTTER" build apk --release --split-per-abi
"$FLUTTER" build appbundle --release

destino="build/release/$tag"
rm -rf "$destino"
mkdir -p "$destino"
# Se algo falhar daqui em diante, não fica pasta de release pela metade, nem
# APK com assinatura errada com cara de pronto.
concluido=""
trap '[[ -n "$concluido" ]] || rm -rf "$destino"' EXIT

# As três arquiteturas que o Flutter compila em release. A lista é a de
# docs/REQUISITOS.md: quem baixa do GitHub escolhe a do aparelho (arm64-v8a
# serve à grande maioria dos celulares de hoje).
apks=()
for abi in arm64-v8a armeabi-v7a x86_64; do
  origem="build/app/outputs/flutter-apk/app-$abi-release.apk"
  [[ -f "$origem" ]] || falhar "o build não gerou $origem."
  copia="$destino/opentuner-$versao-$abi.apk"
  cp "$origem" "$copia"
  apks+=("$copia")
done

bundle="build/app/outputs/bundle/release/app-release.aab"
[[ -f "$bundle" ]] || falhar "o build não gerou $bundle."
cp "$bundle" "$destino/opentuner-$versao.aab"

# Ferramentas do Android SDK, para as conferências abaixo.
build_tools=""
for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
  [[ -n "$sdk" && -d "$sdk/build-tools" ]] || continue
  build_tools="$(find "$sdk/build-tools" -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
    sort -V | tail -n 1)"
  [[ -n "$build_tools" ]] && break
done

# Conferência da assinatura: nenhuma chave de debug, e o mesmo certificado em
# todos os APKs. A impressão digital é pública; é ela que se compara com a
# anotada em docs/assinatura.md.
impressao=""
if [[ -n "$build_tools" && -x "$build_tools/apksigner" ]]; then
  for apk in "${apks[@]}"; do
    certificado="$("$build_tools/apksigner" verify --print-certs "$apk")" ||
      falhar "$apk não passou na verificação de assinatura."
    grep -q 'CN=Android Debug' <<<"$certificado" &&
      falhar "$apk saiu assinado com a chave de debug."
    digest="$(sed -n 's/^Signer #1 certificate SHA-256 digest: //p' <<<"$certificado")"
    [[ -n "$digest" ]] || falhar "não consegui ler o certificado de $apk."
    [[ -z "$impressao" || "$impressao" == "$digest" ]] ||
      falhar "os APKs saíram com certificados diferentes."
    impressao="$digest"
  done
else
  aviso "apksigner não encontrado (defina ANDROID_HOME). A assinatura dos APKs não foi conferida."
fi

# Só o microfone: nenhuma permissão do Android além de RECORD_AUDIO no
# manifest mesclado (CLAUDE.md). Uma dependência que traga INTERNET, por
# exemplo, barra a release aqui. As permissões internas que a AndroidX declara
# com o nome do pacote não contam.
if [[ -n "$build_tools" && -x "$build_tools/aapt2" ]]; then
  permissoes="$("$build_tools/aapt2" dump permissions "${apks[0]}" |
    sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p" | sort -u)"
  estranhas="$(grep '^android\.permission\.' <<<"$permissoes" |
    grep -v '^android\.permission\.RECORD_AUDIO$' || true)"
  [[ -z "$estranhas" ]] ||
    falhar "o APK pede permissões além do microfone: $(tr '\n' ' ' <<<"$estranhas")"
  printf 'Permissões do Android: só RECORD_AUDIO.\n'
else
  aviso "aapt2 não encontrado. As permissões do APK não foram conferidas."
fi

# O teto de tamanho de docs/REQUISITOS.md: 20 MB por APK.
for apk in "${apks[@]}"; do
  tamanho="$(wc -c <"$apk")"
  ((tamanho <= 20 * 1024 * 1024)) ||
    aviso "${apk##*/} tem $((tamanho / 1024 / 1024)) MB, acima dos 20 MB de docs/REQUISITOS.md."
done

# SHA256SUMS.txt vai para o GitHub junto dos APKs e lista só eles: com o
# .aab (que não vai), `sha256sum -c` de quem baixou acusaria o arquivo que
# falta. A soma do .aab fica à parte, para conferir o que foi à Play Store.
(
  cd "$destino"
  if command -v sha256sum >/dev/null 2>&1; then
    soma() { sha256sum -- "$@"; }
  else
    soma() { shasum -a 256 -- "$@"; }
  fi
  soma *.apk >SHA256SUMS.txt
  soma *.aab >SHA256SUMS-aab.txt
)

# As notas vão com a impressão digital do certificado preenchida: é o que
# quem baixa usa para conferir o APK.
if [[ -n "$impressao" ]]; then
  sed "s/{{certificado}}/$impressao/" "$notas" >"$destino/notas.md"
else
  cp "$notas" "$destino/notas.md"
  aviso "preencha {{certificado}} em $destino/notas.md com a impressão digital antes de publicar."
fi

concluido=1

printf '\nArquivos em %s:\n' "$destino"
for arquivo in "$destino"/*; do
  printf '  %s\n' "${arquivo##*/}"
done
if [[ -n "$impressao" ]]; then
  printf '\nCertificado (SHA-256): %s\n' "$impressao"
  printf 'Confira com a impressão digital anotada em docs/assinatura.md.\n'
fi
if ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  printf '\nDepois de testar os APKs, marque o commit:\n  git tag -a %s -m "OpenTuner %s" && git push origin %s\n' \
    "$tag" "$versao" "$tag"
fi
printf '\nPublique os APKs no GitHub (ou pela página de Releases, com os mesmos arquivos):\n'
printf '  gh release create %s --verify-tag --title "OpenTuner %s" --notes-file %s/notas.md %s/*.apk %s/SHA256SUMS.txt\n' \
  "$tag" "$versao" "$destino" "$destino" "$destino"
printf '\nE envie %s/opentuner-%s.aab ao Play Console (teste interno primeiro).\n' "$destino" "$versao"
