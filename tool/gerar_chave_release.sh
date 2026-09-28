#!/usr/bin/env bash
# Gera a chave de assinatura de release e o android/key.properties.
#
# Roda só na máquina de quem guarda a chave, nunca no CI. O keystore fica fora
# do repositório (padrão: ~/.opentuner-chaves/), e nada de senha ou alias é
# impresso. Ver docs/assinatura.md antes de rodar.
#
#   tool/gerar_chave_release.sh                  gera uma chave nova
#   tool/gerar_chave_release.sh --existente ARQ  só escreve o key.properties
#                                                para um keystore já existente
#                                                (computador novo, cópia
#                                                restaurada)
#
# Variável opcional: OPENTUNER_DIR_CHAVES, a pasta onde o keystore novo é
# criado.

set -euo pipefail

falhar() {
  printf 'Erro: %s\n' "$1" >&2
  exit 1
}

if [[ -n "${CI:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
  falhar "este script não roda em CI. A chave é gerada e guardada só localmente."
fi

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
propriedades="$raiz/android/key.properties"

command -v keytool >/dev/null 2>&1 ||
  falhar "keytool não encontrado. Ele vem com o JDK (o mesmo que o Android Studio usa)."

[[ -e "$propriedades" ]] &&
  falhar "android/key.properties já existe. Não sobrescrevo: apague-o à mão se for mesmo o caso."

# Caminho absoluto, sem precisar que o arquivo exista.
absoluto() {
  local dir base
  dir="$(dirname "$1")"
  base="$(basename "$1")"
  mkdir -p "$dir"
  printf '%s/%s\n' "$(cd "$dir" && pwd -P)" "$base"
}

dentro_do_repositorio() {
  [[ "$1" == "$raiz" || "$1" == "$raiz/"* ]]
}

existente=""
if [[ "${1:-}" == "--existente" ]]; then
  [[ -n "${2:-}" ]] || falhar "informe o caminho do keystore depois de --existente."
  [[ -f "$2" ]] || falhar "keystore não encontrado: $2"
  existente="$(absoluto "$2")"
  dentro_do_repositorio "$existente" &&
    falhar "o keystore está dentro do repositório. Mova-o para fora antes."
elif [[ $# -gt 0 ]]; then
  falhar "opção desconhecida: $1"
fi

if [[ -n "$existente" ]]; then
  keystore="$existente"
else
  keystore="$(absoluto "${OPENTUNER_DIR_CHAVES:-$HOME/.opentuner-chaves}/opentuner-release.jks")"
  dentro_do_repositorio "$keystore" &&
    falhar "OPENTUNER_DIR_CHAVES aponta para dentro do repositório."
  [[ -e "$keystore" ]] &&
    falhar "$keystore já existe. Uma chave de release nunca é substituída (docs/assinatura.md)."
fi

# Antes de escrever a senha em disco, a garantia de que ela não vai para o git.
git -C "$raiz" check-ignore -q "$propriedades" ||
  falhar "android/key.properties não está no .gitignore. Corrija o .gitignore antes."

# Só ASCII imprimível: o key.properties é lido pelo Gradle, e a senha precisa
# poder ser digitada igual em qualquer teclado, anos depois.
ascii_imprimivel() {
  local LC_ALL=C
  [[ "$1" =~ ^[[:graph:]]([[:print:]]*[[:graph:]])?$ ]]
}

read -r -p "Alias da chave (letras, números, - e _): " apelido
[[ "$apelido" =~ ^[A-Za-z0-9_-]+$ ]] || falhar "alias inválido."

read -r -s -p "Senha do keystore: " senha
printf '\n'
if [[ -z "$existente" ]]; then
  read -r -s -p "Repita a senha: " confirmacao
  printf '\n'
  [[ "$senha" == "$confirmacao" ]] || falhar "as senhas não conferem."
  unset confirmacao
  [[ ${#senha} -ge 12 ]] || falhar "use pelo menos 12 caracteres."
fi
ascii_imprimivel "$senha" ||
  falhar "use só caracteres ASCII imprimíveis, sem espaço no começo ou no fim."

# Todas as perguntas antes do keytool, que lê a entrada por conta própria.
read -r -p "Gravar a senha no key.properties? Se não, ela vem de OPENTUNER_SENHA_CHAVE a cada build. [s/N] " gravar

if [[ -z "$existente" ]]; then
  chmod 700 "$(dirname "$keystore")"
  printf '\nO keytool vai perguntar nome e organização (vão no certificado, que é público).\n\n'
  # A senha vai por variável de ambiente, não por argumento: argumentos
  # aparecem na lista de processos.
  (
    umask 077
    OPENTUNER_SENHA_CHAVE="$senha" keytool -genkeypair \
      -storetype PKCS12 \
      -keystore "$keystore" \
      -alias "$apelido" \
      -keyalg RSA -keysize 4096 \
      -validity 10000 \
      -storepass:env OPENTUNER_SENHA_CHAVE \
      -keypass:env OPENTUNER_SENHA_CHAVE
  )
else
  OPENTUNER_SENHA_CHAVE="$senha" keytool -list \
    -keystore "$keystore" \
    -alias "$apelido" \
    -storepass:env OPENTUNER_SENHA_CHAVE >/dev/null 2>&1 ||
    falhar "senha ou alias não conferem com esse keystore."
fi

# Formato .properties: a barra invertida é escape.
escapar() { printf '%s' "${1//\\/\\\\}"; }

(
  umask 077
  {
    printf '# Gerado por tool/gerar_chave_release.sh. Fora do versionamento.\n'
    printf 'storeFile=%s\n' "$(escapar "$keystore")"
    printf 'keyAlias=%s\n' "$apelido"
    if [[ "$gravar" =~ ^[sS]$ ]]; then
      printf 'storePassword=%s\n' "$(escapar "$senha")"
      printf 'keyPassword=%s\n' "$(escapar "$senha")"
    fi
  } >"$propriedades"
)
unset senha

cat <<FIM

Pronto.
  keystore:        $keystore
  key.properties:  android/key.properties (permissão 600, fora do git)

Agora, antes de publicar qualquer coisa:
  1. Guarde uma cópia do keystore FORA deste computador (docs/assinatura.md).
  2. Guarde a senha e o alias num cofre de senhas, separados do arquivo.
  3. Anote em docs/assinatura.md onde ficou a cópia: o lugar, não a senha.
FIM
