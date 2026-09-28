#!/usr/bin/env bash
# Instala o APK de release por cima do que está no aparelho, mantendo os dados.
# Uso: make instalar (ou tool/instalar_apk.sh <pasta ou apk> [dispositivo]).
#
# Por adb, e não por `flutter install`: ele desinstala a versão anterior antes
# de instalar, e desinstalar apaga as preferências e a permissão do microfone
# já concedida.
#
# Com uma pasta, escolhe o APK da arquitetura do aparelho entre os que o
# `flutter build apk --split-per-abi` gerou (app-<abi>-release.apk). A ordem é
# a de preferência do próprio aparelho (ro.product.cpu.abilist): um celular
# arm64 recebe o arm64-v8a; um emulador, o x86_64. Não há APK universal nesse
# build, e gerar um só para instalar dobraria o tempo de `make instalar`.

set -euo pipefail

alvo="${1:?informe a pasta dos APKs ou o caminho de um APK}"
dispositivo="${2:-}"

falhar() {
  printf 'Erro: %s\n' "$1" >&2
  exit 1
}

adb="$(command -v adb || true)"
if [[ -z "$adb" ]]; then
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
    if [[ -n "$sdk" && -x "$sdk/platform-tools/adb" ]]; then
      adb="$sdk/platform-tools/adb"
      break
    fi
  done
fi
[[ -n "$adb" ]] ||
  falhar "adb não encontrado. Ele vem no Android SDK, em platform-tools; defina ANDROID_HOME ou ponha o adb no PATH."

# Array vazio com set -u quebra no bash 3.2 do macOS; daí o ${...+...}.
opcoes=()
[[ -n "$dispositivo" ]] && opcoes=(-s "$dispositivo")

if [[ -f "$alvo" ]]; then
  apk="$alvo"
elif [[ -d "$alvo" ]]; then
  abis="$("$adb" ${opcoes[@]+"${opcoes[@]}"} shell getprop ro.product.cpu.abilist | tr -d '\r')" ||
    falhar "não consegui perguntar a arquitetura ao aparelho. Há um conectado? Mais de um pede DISPOSITIVO=<id>."
  [[ -n "$abis" ]] || falhar "o aparelho não informou a arquitetura (ro.product.cpu.abilist vazio)."
  apk=""
  IFS=',' read -r -a lista <<<"$abis"
  for abi in "${lista[@]}"; do
    if [[ -f "$alvo/app-$abi-release.apk" ]]; then
      apk="$alvo/app-$abi-release.apk"
      break
    fi
  done
  [[ -n "$apk" ]] ||
    falhar "nenhum APK em $alvo serve a este aparelho ($abis). Gere antes com make apk."
else
  falhar "$alvo não existe. Gere antes com make apk."
fi

printf 'Instalando %s\n' "$apk"
if ! "$adb" ${opcoes[@]+"${opcoes[@]}"} install -r "$apk"; then
  cat >&2 <<'FIM'

A instalação por cima falhou. Se o erro é INSTALL_FAILED_UPDATE_INCOMPATIBLE, o
OpenTuner do aparelho foi assinado com outra chave (o da Play Store, ou um build
de outra máquina); se é INSTALL_FAILED_VERSION_DOWNGRADE, ele é de versão mais
nova. Nos dois casos, só desinstalando antes, e aí as preferências se perdem.
FIM
  exit 1
fi
