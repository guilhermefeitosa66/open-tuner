<p align="center">
  🇺🇸 <a href="README.md">English</a> · 🇧🇷 <a href="README.pt-BR.md">Português</a> · 🇪🇸 <b>Español</b>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/marca/simbolo-escuro.svg">
    <img src="docs/marca/simbolo-claro.svg" alt="" width="96">
  </picture>
</p>

<h1 align="center">OpenTuner</h1>

<p align="center">
  Un afinador de cuerdas que solo afina. Libre y de código abierto, sin anuncios, sin cuenta y sin
  internet: lo abres, tocas una cuerda y te dice si está floja, demasiado tensa o afinada.
</p>

<p align="center">
  <a href="https://github.com/guilhermefeitosa66/open-tuner/releases/latest"><img src="https://img.shields.io/github/v/release/guilhermefeitosa66/open-tuner?style=for-the-badge&label=Descargar&color=6B4226" alt="Descargar la última versión"></a>
  &nbsp;
  <a href="https://guilhermefeitosa66.github.io/open-tuner/"><img src="https://img.shields.io/badge/Sitio-OpenTuner-6B4226?style=for-the-badge" alt="Sitio del proyecto"></a>
  &nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/Licencia-Apache--2.0-6B4226?style=for-the-badge" alt="Licencia Apache-2.0"></a>
</p>

## Descargar

**Ya salió OpenTuner 1.0.0**, para Android 7.0 o más reciente.

- **GitHub Releases:** [última versión](https://github.com/guilhermefeitosa66/open-tuner/releases/latest)
  (hoy, la [v1.0.0](https://github.com/guilhermefeitosa66/open-tuner/releases/tag/v1.0.0)).
- **Google Play:** próximamente.

Cada versión tiene un APK por tipo de procesador. Elige el de tu dispositivo:

| Archivo | Para |
|---|---|
| `opentuner-1.0.0-arm64-v8a.apk` | La mayoría de los teléfonos (ARM de 64 bits). **Si tienes dudas, este.** |
| `opentuner-1.0.0-armeabi-v7a.apk` | Teléfonos más antiguos, con procesador ARM de 32 bits |
| `opentuner-1.0.0-x86_64.apk` | Chromebooks con procesador Intel o AMD, y emuladores |

Abre el APK en el teléfono. Android te pide permitir que el navegador o el gestor de archivos
instale apps ("Instalar apps desconocidas"); permítelo solo para esa app.

Para actualizar, instala el APK nuevo encima del que tienes: los ajustes se mantienen. OpenTuner
nunca busca actualizaciones por su cuenta (no tiene acceso a internet). Para enterarte de una
versión nueva, usa **Watch → Custom → Releases** en este repositorio.

### Verificar lo que descargaste

**El archivo está completo.** `SHA256SUMS.txt`, en la misma versión, tiene el SHA-256 de cada APK.
Con él en la misma carpeta que el APK:

```bash
sha256sum -c --ignore-missing SHA256SUMS.txt       # Linux
shasum -a 256 -c --ignore-missing SHA256SUMS.txt   # macOS
```

La línea de tu APK tiene que terminar en `OK`. En Windows, `Get-FileHash <archivo>.apk` en
PowerShell muestra la suma para compararla con la línea de `SHA256SUMS.txt` (mayúsculas y minúsculas
no importan).

**Lo firmó el proyecto.** Todos los APK de OpenTuner están firmados con el mismo certificado, con
esta huella digital SHA-256 (también está en las notas de la versión):

```
b8b7f73d8b7444f478f2ee19a7d3df61798d86a465b4b0dd5acf69bc9408834f
```

Para verificarla, usa `apksigner`, de las `build-tools` del Android SDK:

```bash
apksigner verify --print-certs opentuner-1.0.0-arm64-v8a.apk
```

La línea `Signer #1 certificate SHA-256 digest` tiene que mostrar exactamente esa huella. Android
también hace su parte: no instala encima de OpenTuner una actualización firmada con otra clave.

## Qué hace

Toda la app es una pantalla. Un marcador se mueve en horizontal sobre una línea central:

- **a la izquierda de la línea:** la cuerda está floja. Ténsala.
- **a la derecha de la línea:** está demasiado tensa. Aflójala.
- **sobre la línea:** afinada.

El número en el marcador es la distancia hasta la nota, en cents. El rastro de abajo baja por la
pantalla y muestra los últimos segundos: cómo llegó la cuerda a la nota. El color nunca es la única
información: cada estado también tiene posición, signo (− o +) y texto.

- **Lectura tranquila.** El número se queda quieto con la cuerda quieta y avanza en escalones al
  girar la clavija. En las cuerdas graves, el micrófono del teléfono a menudo oye los armónicos en
  lugar de la nota; OpenTuner lo corrige.
- **Automático o manual.** Con **AUTO** activado, OpenTuner reconoce la cuerda que tocaste. O toca
  el botón de una cuerda para fijarla: además suena su nota, sintetizada en el teléfono con la
  afinación y la referencia actuales, para afinar de oído.
- **Afinada.** Un anillo verde se cierra alrededor del marcador, suena un aviso corto, el teléfono
  vibra un instante y la cuerda recibe un ✓ verde. Se repite cada vez que la cuerda vuelve a la
  nota. **Reiniciar** borra las marcas para afinar el siguiente instrumento.
- **Ajustes:** tema claro u oscuro (o el del sistema), notas en C D E o Do Re Mi, referencia del La
  (A4) de 430 a 450 Hz, precisión normal (±5 cents) o fina (±2 cents), pantalla encendida mientras
  afinas, y el idioma: español, inglés o portugués. Por defecto sigue el idioma del teléfono y, si no
  está disponible, usa inglés. Todo queda guardado.

### Instrumentos

La primera afinación de cada instrumento es la estándar, que ya viene elegida.

| Instrumento | Afinaciones |
|---|---|
| Ukelele | Estándar, Sol grave (Low G), En Re |
| Ukelele barítono | Estándar |
| Cavaquinho | Estándar, Natural |
| Guitarra (6 cuerdas, acústica o eléctrica) | Estándar, Drop D, Medio tono abajo, Un tono abajo, DADGAD, Open G, Open D |
| Guitarra de 7 cuerdas | Séptima en Do, Séptima en Si |
| Viola caipira | Cebolão en Mi, Cebolão en Re, Rio abaixo |
| Bajo de 4 cuerdas | Estándar, Drop D, Medio tono abajo |
| Bajo de 5 cuerdas | Estándar, Con Do agudo |
| Bajo de 6 cuerdas | Estándar |

El cavaquinho y la viola caipira son brasileños. El cavaquinho es el pequeño instrumento de cuatro
cuerdas de la samba y del choro. La viola caipira tiene diez cuerdas en cinco pares, y los tres pares
más graves se afinan en octava: OpenTuner acepta cualquiera de las dos cuerdas del par. Las notas y
frecuencias de cada afinación están en
[docs/REQUISITOS.md](docs/REQUISITOS.md#2-instrumentos-e-afinações-da-versão-10) (en portugués).

## Privacidad

- **Un solo permiso: el micrófono.** El sonido se analiza en memoria, en el teléfono, y se descarta.
  Nunca se graba ni sale del dispositivo.
- **Sin permiso de internet.** OpenTuner no podría enviar nada aunque quisiera, y funciona sin
  conexión, siempre.
- **Sin anuncios, analíticas, informes de errores remotos ni Google Play Services. Sin cuenta, sin
  compras dentro de la app.** Los ajustes se quedan en el teléfono, y desinstalar los borra.
- El script de release se niega a publicar un APK que pida cualquier permiso de Android además del
  micrófono (`RECORD_AUDIO`).

Texto completo: [política de privacidad](https://guilhermefeitosa66.github.io/open-tuner/es/privacy/)
(en inglés).

**Nunca anuncios.** Mientras el proyecto se pueda costear y mantener en la tienda, no habrá anuncios,
compras dentro de la app ni versión de pago con funciones extra. La promesa es pública, en el
[sitio](https://guilhermefeitosa66.github.io/open-tuner/).

## Próximos pasos

Android primero, iOS después. Previsto después de la 1.0, sin fechas: Google Play, afinaciones
personalizadas, modo cromático, guitarra de 12 cuerdas, más idiomas (con la comunidad), F-Droid e
iOS. El detalle está en la hoja de ruta de [docs/REQUISITOS.md](docs/REQUISITOS.md#8-roteiro).

Fuera del propósito: canciones, acordes, clases, metrónomo, grabación, cuentas, nube, anuncios y
compras dentro de la app.

## Compilar desde el código

Necesitas:

- Flutter 3.38.5, la versión que usa el CI;
- el Android SDK y un JDK que Gradle acepte (el CI usa Java 17);
- un dispositivo o emulador con Android 7.0 o más reciente.

```bash
git clone https://github.com/guilhermefeitosa66/open-tuner.git
cd open-tuner
make verificar      # revisa Flutter, Android SDK, Java, paquetes y dispositivos
make dependencias   # flutter pub get
make rodar          # abre la app en el dispositivo conectado, con hot reload
```

Las tareas de `make` tienen nombres en portugués; `make` sin argumentos las lista todas.

| Comando | Qué hace |
|---|---|
| `make verificar` | Revisa Flutter, Android SDK, Java, paquetes y dispositivos conectados |
| `make dependencias` | `flutter pub get`, que también genera las clases de texto de `lib/l10n/` |
| `make textos` | Regenera `lib/l10n/textos*.dart` a partir de los ARB (`flutter gen-l10n`) |
| `make rodar` | Ejecuta en modo de desarrollo, con hot reload |
| `make emuladores` | Lista los emuladores de Android (AVD) |
| `make emulador AVD=<nombre>` | Abre un emulador que escucha el micrófono de la computadora |
| `make testar` | Formato, análisis y pruebas, como en el CI |
| `make analisar` | Análisis estático (`dart analyze lib test`) |
| `make formatar` | Formatea `lib` y `test` |
| `make apk` | APK de release, uno por arquitectura |
| `make instalar` | Genera los APK e instala el de la arquitectura del dispositivo encima del instalado, sin borrar datos |
| `make aab` | App Bundle de release, el formato de la Play Store |
| `make site` | Sirve `site/` en http://localhost:8000/ |
| `make desatualizadas` | Lista los paquetes que tienen versión más nueva |
| `make limpar` | Borra lo que generaron los builds (`flutter clean`) |

Con más de un dispositivo conectado, agrega `DISPOSITIVO=<id>` (los ids salen de `flutter devices`).
`make chave` y `make release` son para quien guarda la clave de firma:
[docs/assinatura.md](docs/assinatura.md) y [docs/release.md](docs/release.md).

Para ejecutar las pruebas directamente:

```bash
flutter test                                  # todas
flutter test test/dominio/nota_test.dart      # un archivo
flutter test --plain-name 'A4'                # pruebas por nombre
```

Conviene saber:

- **Análisis.** `make analisar` ejecuta `dart analyze lib test` y no `flutter analyze`: en Linux el
  segundo vigila el pub cache con inotify y puede fallar con `Too many open files`. El CI sube ese
  límite y ejecuta `flutter analyze`.
- **Micrófono del emulador.** Un emulador abierto sin `-allow-host-audio` le entrega silencio a la
  app y el marcador nunca se mueve; `make emulador` pasa esa opción. Si aun así no llega sonido,
  activa también "Virtual microphone uses host audio input" en Extended controls → Microphone, en la
  ventana del emulador.
- **Tus propios builds.** Sin `android/key.properties`, el release sale firmado con la clave de
  debug. Se instala y funciona, pero no actualiza un OpenTuner descargado de las releases:
  desinstala ese primero (se pierden sus ajustes).

### Dónde está cada cosa

| Ruta | Qué hay |
|---|---|
| `lib/dominio/` | Dart puro, sin Flutter: notas, la tabla de instrumentos y afinaciones, el detector de frecuencia, la corrección de armónicos, el filtro de Kalman y la elección de cuerda. Las pruebas que importan están aquí. |
| `lib/audio/` | Captura del micrófono, y la nota de cada cuerda y el aviso de afinada, sintetizados en código |
| `lib/features/` | La pantalla del afinador y la hoja de ajustes |
| `lib/dados/` | Preferencias guardadas |
| `lib/app/` | Arranque de la app, tokens de color (`tema.dart`) y elección de idioma (`idioma.dart`) |
| `lib/l10n/` | Textos, un ARB por idioma, y las clases generadas a partir de ellos (versionadas) |
| `test/` | Pruebas, con la misma organización que `lib/` |
| `tool/` | Scripts detrás de `make`: entorno, instalación, clave de firma, release, íconos |
| `site/` | El sitio, publicado en GitHub Pages por el workflow `Site` |
| `docs/` | Documentación del proyecto, en portugués |

## Cómo contribuir

El código está escrito en portugués: nombres de clases, métodos y variables (`Nota`, `centsEntre`),
comentarios, mensajes de commit y la documentación de `docs/`. Los issues son bienvenidos en
español, inglés o portugués.

- **Errores:** [abre un issue](https://github.com/guilhermefeitosa66/open-tuner/issues) con el
  modelo del teléfono, la versión de Android, el instrumento y la afinación, y lo que mostró la
  pantalla.
- **Falta una afinación o un instrumento:** abre un issue con sus notas, de la cuerda de arriba a la
  de abajo. Las afinaciones están en una sola tabla, `lib/dominio/afinacoes.dart`.
- **Traducciones:** los textos están en `lib/l10n/`. `app_en.arb` es el modelo, con la descripción
  de cada texto; `app_pt.arb` y `app_es.arb` son las traducciones. Para corregir un texto, edita los
  ARB y ejecuta `flutter pub get`, que regenera `lib/l10n/textos*.dart`. Un idioma nuevo también
  necesita una entrada en `lib/app/idioma.dart` y en `test/l10n/arb_test.dart`: abre un issue antes
  y lo preparamos juntos. La traducción automática solo se publica después de la revisión de alguien
  que hable el idioma. Está prevista la traducción por la comunidad en un Weblate alojado.
- **Pull requests:** ejecuta `make testar` antes de enviar (el CI hace las mismas revisiones).
  Ningún texto que vea el usuario va escrito en el código: va en los tres ARB, y una prueba falla si
  no tienen las mismas claves. Ninguna dependencia que traiga el permiso de internet, anuncios,
  analíticas o Google Play Services. Y Android primero, pero sin plugins ni código nativo que aten la
  app a Android. Antes de una pantalla o regla nueva, lee [docs/REQUISITOS.md](docs/REQUISITOS.md).

## Documentación

En portugués, en `docs/`:

- [REQUISITOS.md](docs/REQUISITOS.md): qué hace la 1.0, la tabla de afinaciones con frecuencias,
  paleta, arquitectura y hoja de ruta.
- [notas/v1.0.0.md](docs/notas/v1.0.0.md): notas de la versión 1.0.0.
- [release.md](docs/release.md): cómo se genera, firma y publica una versión.
- [assinatura.md](docs/assinatura.md): la clave de firma y cómo verificarla.
- [loja/](docs/loja/README.md): fichas de las tiendas (en, pt, es), seguridad de los datos y lista
  de publicación.
- [marca/](docs/marca/README.md): el símbolo y el ícono de la app.

El [sitio](https://guilhermefeitosa66.github.io/open-tuner/es/), con la [política de privacidad](https://guilhermefeitosa66.github.io/open-tuner/es/privacy/) y los
[términos de uso](https://guilhermefeitosa66.github.io/open-tuner/es/terms/), está en español, [inglés](https://guilhermefeitosa66.github.io/open-tuner/) y [portugués](https://guilhermefeitosa66.github.io/open-tuner/pt/): los botones
de bandera en la parte superior de cada página cambian el idioma. Su código está en `site/`, y un
texto nuevo entra en las tres versiones.

## Licencia

[Apache 2.0](LICENSE). El nombre y el logotipo de OpenTuner no forman parte de la licencia: una
versión derivada necesita otro nombre y otro ícono.
