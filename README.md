<p align="center">
  <img src="docs/marca/simbolo-claro.svg" alt="Open Tuner" width="96">
</p>

<h1 align="center">open tuner</h1>

<p align="center">
  Afinador de instrumentos de corda para Android. Livre, sem anúncios, sem conta e sem internet:
  abre, escuta a corda e diz se ela está frouxa, apertada ou afinada.
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/Licen%C3%A7a-Apache--2.0-6B4226?style=for-the-badge" alt="Licença Apache-2.0"></a>
</p>

## Estado

Em desenvolvimento. A versão atual é o esqueleto do projeto: tema claro e escuro, modelo de nota e
integração contínua. A escuta do microfone ainda não existe. O que falta até a 1.0 está no roteiro de
[docs/REQUISITOS.md](docs/REQUISITOS.md#8-roteiro).

## O que vai fazer

- Ukulele (e barítono), cavaquinho, violão de 6 e 7 cordas, viola caipira e baixo de 4, 5 e 6
  cordas, cada um com as afinações mais usadas. A padrão vem escolhida.
- Detecção automática da corda tocada, ou escolha manual tocando na corda.
- O ponteiro corre na horizontal: à esquerda da linha do centro a corda está frouxa, à direita está
  apertada demais, na linha está afinada. O rastro rola para baixo e mostra como a afinação chegou lá.
- Tema claro e escuro, notas em C D E ou Dó Ré Mi, referência do Lá ajustável.
- Uma permissão só, a do microfone. O áudio não é gravado nem sai do aparelho.

A lista completa, com os critérios de cada item, está em [docs/REQUISITOS.md](docs/REQUISITOS.md).

## Desenvolvimento

Precisa de Flutter 3.38.5 e de um aparelho ou emulador Android 7.0 ou mais novo.

```bash
make                # lista as tarefas
make dependencias   # flutter pub get
make testar         # flutter test
make analisar       # dart analyze lib test
make rodar          # abre no aparelho conectado
make apk            # APK de debug
```

## Licença

[Apache 2.0](LICENSE).
