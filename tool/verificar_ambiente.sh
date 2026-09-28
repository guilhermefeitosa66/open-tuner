#!/usr/bin/env bash
# Confere se a máquina tem o que o projeto precisa, antes de descobrir no meio
# do build: o Flutter na versão do CI, o Android SDK com um Java que o Gradle
# aceita, os pacotes do pubspec.lock e um aparelho para rodar. Uso: make
# verificar.
#
# Sai com erro só quando falta algo; versão diferente e aparelho ausente são
# avisos.

set -uo pipefail

FLUTTER="${FLUTTER:-flutter}"
erros=0
avisos=0

ok() { printf '  ok     %s\n' "$1"; }
aviso() {
  printf '  aviso  %s\n' "$1"
  avisos=$((avisos + 1))
}
falta() {
  printf '  falta  %s\n' "$1"
  erros=$((erros + 1))
}
detalhe() { printf '         %s\n' "$1"; }

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$raiz" || exit 1

# A versão vem do CI, para haver um lugar só.
esperada="$(sed -n 's/^ *FLUTTER_VERSION: *"\([^"]*\)".*/\1/p' .github/workflows/ci.yml)"

echo "Flutter"
if ! command -v "$FLUTTER" >/dev/null 2>&1; then
  falta "flutter não está no PATH"
  detalhe "Instale a versão $esperada: https://docs.flutter.dev/install/archive"
  echo
  echo "Sem o Flutter, o resto não dá para conferir."
  exit 1
fi
versao="$("$FLUTTER" --version --machine 2>/dev/null |
  sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p')"
if [[ "$versao" == "$esperada" ]]; then
  ok "Flutter $versao, a mesma do CI"
else
  aviso "Flutter ${versao:-desconhecido}; o CI usa $esperada"
  detalhe "Com outra versão, a formatação, a análise e o build podem sair diferentes."
  detalhe "Versões: https://docs.flutter.dev/install/archive"
fi

# O doctor acha o SDK e o Java do mesmo jeito que o build: pela configuração do
# Flutter, pelo ANDROID_HOME ou pelo Android Studio.
echo
echo "Android"
doctor="$("$FLUTTER" doctor -v 2>/dev/null)"
bloco="$(printf '%s\n' "$doctor" |
  awk '/^\[[^]]*\] Android toolchain/ { p = 1; print; next } /^\[/ { p = 0 } p')"
if [[ -z "$bloco" ]]; then
  falta "o flutter doctor não informou o Android toolchain"
  detalhe "Rode flutter doctor -v para ver o motivo."
else
  cabecalho="$(printf '%s\n' "$bloco" | head -n 1)"
  informacoes="$(printf '%s\n' "$bloco" | grep -E 'Android SDK at|Java binary at|Java version' |
    sed 's/^ *• *//')"
  problemas="$(printf '%s\n' "$bloco" | grep -E '^ *(✗|!)' | sed 's/^ *//')"
  case "$cabecalho" in
    '[✓]'*) ok "Android SDK e Java prontos para o build" ;;
    '[!]'*) aviso "Android SDK com pendências" ;;
    *)
      falta "Android SDK ou Java"
      detalhe "Detalhes em flutter doctor -v."
      ;;
  esac
  while IFS= read -r linha; do
    [[ -n "$linha" ]] && detalhe "$linha"
  done <<<"$informacoes"$'\n'"$problemas"
  if printf '%s\n' "$problemas" | grep -q -i 'licenses'; then
    detalhe "Para aceitar as licenças: flutter doctor --android-licenses"
  fi
fi

echo
echo "Pacotes"
if saida="$("$FLUTTER" pub get --enforce-lockfile --dry-run 2>&1)"; then
  ok "o pubspec.lock resolve sem mudanças"
else
  falta "os pacotes do pubspec.lock não resolvem"
  printf '%s\n' "$saida" | tail -n 5 | while IFS= read -r linha; do detalhe "$linha"; done
fi
if [[ -f .dart_tool/package_config.json ]]; then
  ok "pacotes instalados"
else
  aviso "pacotes ainda não instalados"
  detalhe "Rode make dependencias."
fi

echo
echo "Aparelhos"
android="$("$FLUTTER" devices --machine 2>/dev/null | grep -c '"targetPlatform": *"android' || true)"
if [[ "$android" -gt 0 ]]; then
  ok "$android aparelho(s) Android conectado(s)"
else
  aviso "nenhum aparelho Android conectado"
  detalhe "make rodar e make instalar precisam de um celular com depuração USB ligada, ou de um emulador."
  detalhe "No emulador, o microfone do computador só chega ao app se ele subir por make emulador."
fi

echo
if ((erros > 0)); then
  echo "Falta(m) $erros item(ns); veja acima."
  exit 1
elif ((avisos > 0)); then
  echo "Pronto, com $avisos aviso(s)."
else
  echo "Tudo pronto."
fi
