# Tarefas do dia a dia. `make` sem argumento lista todas.
#
# Não há ambientes (desenvolvimento, homologação, produção): o aplicativo
# funciona sozinho no aparelho, sem servidor e sem internet. O APK instalado é
# a versão de uso.
#
# Variáveis:
#   DISPOSITIVO=<id>  aparelho a usar quando há mais de um (ids: flutter devices)
#   ARGS="..."        opções a mais para o Flutter em rodar, apk e aab
#   AVD=<nome>        emulador a abrir em `emulador` (nomes: make emuladores)
#   PORTA=<n>         porta do servidor local de `site` (padrão 8000)

FLUTTER ?= flutter
# O `dart` avulso pode existir no PATH e mesmo assim não rodar (um shim do asdf
# sem versão escolhida, por exemplo). Quando não roda, usa-se o que vem junto
# com o Flutter, que sempre existe.
DART ?= $(shell if dart --version >/dev/null 2>&1; then echo dart; \
	else echo "$$(dirname "$$(command -v flutter)")/dart"; fi)
DISPOSITIVO ?=
ARGS ?=
PORTA ?= 8000

APKS := build/app/outputs/flutter-apk
AAB := build/app/outputs/bundle/release/app-release.aab

# Sem android/key.properties o release sai com a chave de debug. Instala e
# serve para testar, mas não atualiza uma versão publicada, e a Play Store
# recusa o .aab (docs/assinatura.md).
define AVISO_CHAVE
	@if [ ! -f android/key.properties ]; then \
	  echo "Atenção: assinado com a chave de debug, porque não há android/key.properties."; \
	  echo "Serve para testar, mas não atualiza uma versão publicada (docs/assinatura.md)."; \
	fi
endef

# ------------------------------------------------------------- emuladores ---
#
#   make emuladores                     lista os AVDs
#   make emulador AVD=Medium_Phone      abre um emulador, com o microfone do
#                                       computador ligado ao dele
#
# O afinador precisa ouvir. Sem -allow-host-audio o emulador entrega silêncio
# ao app (zeros no lugar do áudio), e o ponteiro nunca se mexe; com ele, o
# microfone do computador vira o microfone do emulador. Se ainda assim não
# chegar som, libere também na janela do emulador: Extended controls (os três
# pontos) → Microphone → "Virtual microphone uses host audio input".
#
# O Android Studio instalado por Flatpak guarda os AVDs dentro do sandbox, e
# não em ~/.android/avd, onde o emulador avulso procura. AVD_HOME aponta para
# lá quando a pasta existe.
EMULADOR := $(HOME)/Android/Sdk/emulator/emulator
AVD_FLATPAK := $(HOME)/.var/app/com.google.AndroidStudio/config/.android/avd
AVD_HOME ?= $(shell if [ -d "$(AVD_FLATPAK)" ] && [ -n "$$(ls -A $(AVD_FLATPAK) 2>/dev/null)" ]; \
	then echo "$(AVD_FLATPAK)"; else echo "$(HOME)/.android/avd"; fi)
AVD ?=

# O caminho de GPU padrão estoura com SIGSEGV nesta máquina, durante o boot do
# convidado. Sem Vulkan, a aceleração por hardware continua e o emulador sobe.
# Se ainda assim cair, GPU=swiftshader_indirect desenha por software.
GPU ?= host -feature -Vulkan

.DEFAULT_GOAL := ajuda
.PHONY: ajuda dependencias textos verificar desatualizadas rodar apk aab \
	instalar formatar analisar testar site limpar emuladores emulador \
	chave release

ajuda: ## Lista as tarefas
	@echo "Uso: make <tarefa>"
	@echo
	@awk -F ':.*## ' '/^[a-z]+:.*## / { printf "  %-15s %s\n", $$1, $$2 }' $(firstword $(MAKEFILE_LIST))
	@echo
	@echo "Mais de um aparelho conectado: DISPOSITIVO=<id> (ids em: flutter devices)."

# Com `generate: true` no pubspec, o pub get também gera as classes de texto
# (lib/l10n/textos*.dart) a partir dos ARB.
dependencias: ## Instala os pacotes do pubspec e gera os textos (flutter pub get)
	$(FLUTTER) pub get

# O `flutter run` e o build já regeneram sozinhos; isto é para ver o resultado
# de uma mudança nos ARB (lib/l10n/app_*.arb) sem rodar o app, por exemplo
# antes de `make testar`.
textos: ## Gera lib/l10n/textos*.dart a partir dos ARB (flutter gen-l10n)
	$(FLUTTER) gen-l10n

verificar: ## Confere Flutter, Android SDK, Java, pacotes e aparelhos
	@FLUTTER="$(FLUTTER)" tool/verificar_ambiente.sh

desatualizadas: ## Lista os pacotes que têm versão mais nova
	$(FLUTTER) pub outdated

# Se a instalação falhar (o OpenTuner do aparelho foi assinado com outra chave,
# ou é de versão mais nova), o `flutter run` desinstala e instala de novo, e
# desinstalar apaga as preferências. Use num aparelho de teste.
rodar: ## Roda em modo de desenvolvimento (debug, com hot reload)
	$(FLUTTER) run $(if $(DISPOSITIVO),-d $(DISPOSITIVO)) $(ARGS)

# Um APK por arquitetura, cada um bem menor que o universal. São os mesmos que
# vão para o GitHub Releases (docs/release.md).
apk: ## Gera os APKs de release, um por arquitetura (Android 7.0+)
	$(FLUTTER) build apk --release --split-per-abi $(ARGS)
	@echo
	@echo "APKs em $(APKS):"
	@ls -1 $(APKS)/app-*-release.apk | sed 's|.*/|  |'
	$(AVISO_CHAVE)

aab: ## Gera o App Bundle de release, o formato da Play Store
	$(FLUTTER) build appbundle --release $(ARGS)
	@echo
	@echo "App Bundle: $(AAB)"
	$(AVISO_CHAVE)

# Por adb, e não por `flutter install`, que desinstala a versão anterior antes
# de instalar e apaga as preferências. O script pergunta a arquitetura ao
# aparelho e escolhe o APK dela entre os que `make apk` gerou.
instalar: apk ## Gera os APKs e instala o da arquitetura do aparelho, sem apagar dados
	@tool/instalar_apk.sh "$(APKS)" "$(DISPOSITIVO)"

formatar: ## Formata o código de lib e test
	$(DART) format lib test

# `dart analyze` no lugar de `flutter analyze`: o segundo vigia o pub cache por
# inotify e estoura o limite padrão do Linux. O CI sobe o limite e roda o
# `flutter analyze`; aqui o resultado é o mesmo sem precisar de sudo.
analisar: ## Análise estática (dart analyze lib test)
	$(DART) analyze lib test

testar: ## Formatação, análise e testes, como no CI
	$(DART) format --output=none --set-exit-if-changed lib test
	$(DART) analyze lib test
	$(FLUTTER) test

# O site não tem etapa de geração: o que está em site/ é o que o GitHub Pages
# publica. Só em localhost, para não expor o servidor na rede. Ctrl+C encerra.
site: ## Serve site/ em localhost para conferir antes de publicar [PORTA=8000]
	@echo "Site em http://localhost:$(PORTA)/ (Ctrl+C para parar)"
	python3 -m http.server --bind 127.0.0.1 --directory site $(PORTA)

limpar: ## Apaga o que os builds geraram (flutter clean)
	$(FLUTTER) clean

emuladores: ## Lista os emuladores disponíveis (AVDs)
	@ANDROID_AVD_HOME="$(AVD_HOME)" $(EMULADOR) -list-avds

# Em segundo plano e sem terminal preso: o emulador fica aberto depois que o
# make termina, e o `make rodar` seguinte já o encontra.
emulador: ## Abre um emulador com o microfone do computador: AVD=<nome>
	@if [ -z "$(AVD)" ]; then \
	  echo "Informe o AVD: make emulador AVD=<nome> (nomes: make emuladores)"; \
	  exit 1; \
	fi
	@echo "Abrindo $(AVD) com o microfone do computador…"
	@ANDROID_AVD_HOME="$(AVD_HOME)" nohup $(EMULADOR) @$(AVD) \
	  -gpu $(GPU) -no-boot-anim -allow-host-audio \
	  > /tmp/emulador-$(AVD).log 2>&1 & \
	  echo "Registro em /tmp/emulador-$(AVD).log"

# Uma vez só, na máquina de quem guarda a chave. Pergunta alias e senha; o
# keystore fica fora do repositório. Ler docs/assinatura.md antes.
chave: ## Gera a chave de release e o android/key.properties (uma vez só)
	@tool/gerar_chave_release.sh

# Recusa sem key.properties, com mudanças não commitadas ou sem as notas da
# versão em docs/notas/. Passo a passo em docs/release.md.
release: ## Gera APKs, App Bundle e somas assinados em build/release/
	@FLUTTER="$(FLUTTER)" tool/gerar_release.sh
