# Marca

Uma palheta com a onda do afinador dentro: a onda oscila, vai se acalmando e termina reta, na linha
do centro. É a corda chegando à nota.

| Arquivo | Uso |
|---|---|
| `simbolo-claro.svg` | Sobre fundo claro. Palheta em nogueira `#6B4226`. |
| `simbolo-escuro.svg` | Sobre fundo escuro. Palheta em mel `#C9935F`. |
| `simbolo-mono.svg` | Uma cor, com a onda vazada. Base do ícone temático do Android 13+. |
| `icone-app.svg` | Ícone adaptativo, na grade de 108 dp com o símbolo dentro da zona segura de 66 dp. |

O nome é **OpenTuner**, uma palavra só, em camel case. No logotipo vai em Fraunces: "Open" em peso
500 na cor do texto e "Tuner" em peso 700 na cor de destaque. Em texto corrido, sempre "OpenTuner",
nunca "Open Tuner" nem "opentuner".

Abaixo de 32 px a onda perde as voltas menores e engrossa o traço, para continuar legível na barra
de notificação. Os ícones do Android (adaptativo, monocromático do Android 13 e os PNG legados), a tela de abertura
e as imagens da loja (`docs/loja/icone-512.png`, `docs/loja/destaque-1024x500.png`) saem destes SVGs
por `tool/gerar_icones.py`. Mudou a marca, rode o script de novo.
