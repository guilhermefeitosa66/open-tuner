# Tarefas do dia a dia. `make` sem argumento lista todas.
#
# Variáveis:
#   DISPOSITIVO=<id>  aparelho a usar quando há mais de um (ids: flutter devices)
#   ARGS="..."        opções a mais para o Flutter em rodar, apk e release

FLUTTER ?= flutter
# O `dart` avulso pode existir no PATH e mesmo assim não rodar (um shim do asdf
# sem versão escolhida, por exemplo). Quando não roda, usa-se o que vem junto
# com o Flutter, que sempre existe.
DART ?= $(shell if dart --version >/dev/null 2>&1; then echo dart; \
	else echo "$$(dirname "$$(command -v flutter)")/dart"; fi)
DISPOSITIVO ?=
ARGS ?=

.DEFAULT_GOAL := ajuda
.PHONY: ajuda dependencias formatar analisar testar rodar apk release

ajuda: ## Lista as tarefas
	@echo "Uso: make <tarefa>"
	@echo
	@awk -F ':.*## ' '/^[a-z]+:.*## / { printf "  %-15s %s\n", $$1, $$2 }' $(firstword $(MAKEFILE_LIST))
	@echo
	@echo "Mais de um aparelho conectado: DISPOSITIVO=<id> (ids em: flutter devices)."

dependencias: ## Instala os pacotes do pubspec (flutter pub get)
	$(FLUTTER) pub get

formatar: ## Formata o código de lib e test
	$(DART) format lib test

# `dart analyze` no lugar de `flutter analyze`: o segundo vigia o pub cache por
# inotify e estoura o limite padrão do Linux. O CI sobe o limite e roda o
# `flutter analyze`; aqui o resultado é o mesmo sem precisar de sudo.
analisar: ## Análise estática (dart analyze lib test)
	$(DART) analyze lib test

testar: ## Roda a suíte de testes
	$(FLUTTER) test

rodar: ## Roda em modo de desenvolvimento (debug, com hot reload)
	$(FLUTTER) run $(if $(DISPOSITIVO),-d $(DISPOSITIVO)) $(ARGS)

apk: ## Gera o APK de debug
	$(FLUTTER) build apk --debug $(ARGS)

release: ## Gera os APKs de release, um por arquitetura
	$(FLUTTER) build apk --release --split-per-abi $(ARGS)
