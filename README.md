<p align="center">
  <img src="docs/marca/simbolo-claro.svg" alt="" width="96">
</p>

<h1 align="center">OpenTuner</h1>

<p align="center">
  Afinador de instrumentos de corda. Livre, sem anúncios, sem conta e sem internet: abre, escuta a
  corda e diz se ela está frouxa, apertada ou afinada.
</p>

<p align="center">
  <a href="https://guilhermefeitosa66.github.io/open-tuner/"><img src="https://img.shields.io/badge/Site-OpenTuner-6B4226?style=for-the-badge" alt="Site do projeto"></a>
  &nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/Licen%C3%A7a-Apache--2.0-6B4226?style=for-the-badge" alt="Licença Apache-2.0"></a>
</p>

## Estado

Em desenvolvimento. A versão atual é o esqueleto do projeto: tema claro e escuro, modelo de nota,
textos em inglês, português e espanhol, site e integração contínua. A escuta do microfone ainda não
existe. O que falta até a 1.0 está no roteiro de
[docs/REQUISITOS.md](docs/REQUISITOS.md#8-roteiro).

Android primeiro, com distribuição global; iOS depois.

## O que vai fazer

- Ukulele (e barítono), cavaquinho, violão de 6 e 7 cordas, viola caipira e baixo de 4, 5 e 6
  cordas, cada um com as afinações mais usadas. A padrão vem escolhida.
- Detecção automática da corda tocada, ou escolha manual tocando na corda.
- O ponteiro corre na horizontal: à esquerda da linha do centro a corda está frouxa, à direita está
  apertada demais, na linha está afinada. O rastro rola para baixo e mostra como a afinação chegou lá.
- Tema claro e escuro, notas em C D E ou Dó Ré Mi, referência do Lá ajustável.
- No idioma do aparelho; quando o idioma não é suportado, em inglês.
- Uma permissão só, a do microfone. O áudio não é gravado nem sai do aparelho.
- **Nunca anúncios**, enquanto o projeto puder ser custeado e mantido na loja.

A lista completa, com os critérios de cada item, está em [docs/REQUISITOS.md](docs/REQUISITOS.md).

## Site

`site/` é publicado no GitHub Pages pelo workflow `Site`, em inglês: apresentação,
[política de privacidade](https://guilhermefeitosa66.github.io/open-tuner/privacy/) e
[termos de uso](https://guilhermefeitosa66.github.io/open-tuner/terms/). O material das lojas
(descrições, segurança de dados, checklist) está em [docs/loja/](docs/loja/README.md).

## Desenvolvimento

Precisa de Flutter 3.38.5 e de um aparelho ou emulador Android 7.0 ou mais novo.

```bash
make                # lista as tarefas
make dependencias   # flutter pub get (gera também as classes de lib/l10n)
make testar         # flutter test
make analisar       # dart analyze lib test
make rodar          # abre no aparelho conectado, com hot reload
make emulador AVD=<nome>   # emulador com o microfone do computador
make apk            # APKs de release, um por arquitetura
make aab            # pacote da Play Store
make site           # serve o site em http://localhost:8000/
```

Assinatura e publicação: [docs/assinatura.md](docs/assinatura.md) e [docs/release.md](docs/release.md).

Para mudar um texto, edite `lib/l10n/app_en.arb` (o modelo) e os outros `app_*.arb`, e rode
`flutter pub get`.

## Licença

[Apache 2.0](LICENSE). O nome e o logotipo do OpenTuner não fazem parte da licença: uma versão
derivada precisa de outro nome e outro ícone.
