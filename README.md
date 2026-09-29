<p align="center">
  🇺🇸 <b>English</b> · 🇧🇷 <a href="README.pt-BR.md">Português</a> · 🇪🇸 <a href="README.es.md">Español</a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/marca/simbolo-escuro.svg">
    <img src="docs/marca/simbolo-claro.svg" alt="" width="96">
  </picture>
</p>

<h1 align="center">OpenTuner</h1>

<p align="center">
  A string tuner that only tunes. Free and open source, with no ads, no account and no internet:
  open it, pluck a string, and it tells you if the string is loose, too tight or in tune.
</p>

<p align="center">
  <a href="https://github.com/guilhermefeitosa66/open-tuner/releases/latest"><img src="https://img.shields.io/github/v/release/guilhermefeitosa66/open-tuner?style=for-the-badge&label=Download&color=6B4226" alt="Download the latest release"></a>
  &nbsp;
  <a href="https://guilhermefeitosa66.github.io/open-tuner/"><img src="https://img.shields.io/badge/Site-OpenTuner-6B4226?style=for-the-badge" alt="Project website"></a>
  &nbsp;
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache--2.0-6B4226?style=for-the-badge" alt="Apache-2.0 license"></a>
</p>

## Download

**OpenTuner 1.0.0 is out**, for Android 7.0 or newer.

- **GitHub Releases:** [latest version](https://github.com/guilhermefeitosa66/open-tuner/releases/latest)
  (today, [v1.0.0](https://github.com/guilhermefeitosa66/open-tuner/releases/tag/v1.0.0)).
- **Google Play:** coming soon.

Each release has one APK per processor type. Pick the one for your device:

| File | For |
|---|---|
| `opentuner-1.0.0-arm64-v8a.apk` | Most phones (64-bit ARM). **Not sure? Pick this one.** |
| `opentuner-1.0.0-armeabi-v7a.apk` | Older phones with a 32-bit ARM processor |
| `opentuner-1.0.0-x86_64.apk` | Chromebooks with an Intel or AMD processor, and emulators |

Open the APK on the phone. Android asks you to allow the browser or file manager to install apps
("Install unknown apps"); allow it for that app only.

To update, install the new APK over the one you have: your settings stay. OpenTuner never checks
for updates on its own (it has no internet access). To hear about new versions, use **Watch →
Custom → Releases** on this repository.

### Check what you downloaded

**The file is intact.** `SHA256SUMS.txt`, in the same release, has the SHA-256 of every APK. With
it in the same folder as the APK:

```bash
sha256sum -c --ignore-missing SHA256SUMS.txt       # Linux
shasum -a 256 -c --ignore-missing SHA256SUMS.txt   # macOS
```

The line of your APK must end in `OK`. On Windows, `Get-FileHash <file>.apk` in PowerShell prints
the hash to compare with the line in `SHA256SUMS.txt` (letter case does not matter).

**It was signed by the project.** Every OpenTuner APK is signed with the same certificate, and
this is its SHA-256 fingerprint (it is also in the release notes):

```
b8b7f73d8b7444f478f2ee19a7d3df61798d86a465b4b0dd5acf69bc9408834f
```

To check it, use `apksigner` from the Android SDK build tools:

```bash
apksigner verify --print-certs opentuner-1.0.0-arm64-v8a.apk
```

The line `Signer #1 certificate SHA-256 digest` must show exactly that fingerprint. Android does
its own part too: it refuses to install an update signed with any other key over OpenTuner.

## What it does

The whole app is one screen. A marker runs sideways over a center line:

- **left of the line:** the string is loose (flat). Tighten it.
- **right of the line:** it is too tight (sharp). Loosen it.
- **on the line:** in tune.

The number in the marker is how far the string is from the note, in cents. The trail below scrolls
down and shows the last few seconds, so you see how the string got there. Color is never the only
cue: every state also has a position, a sign (− or +) and a written instruction.

- **Calm display.** The number holds still while the string rings and moves in steps as you turn
  the peg. On low strings a phone microphone often hears the overtones instead of the note itself;
  OpenTuner corrects that.
- **Auto or manual.** With **AUTO** on, OpenTuner hears which string you played. Or tap a string's
  button to lock it: it also plays that string's note, synthesized on the phone for the current
  tuning and reference, so you can tune by ear.
- **In tune.** A green ring closes around the marker, a short chime plays, the phone gives a short
  vibration and the string gets a green ✓. It happens again every time the string comes back to the
  note. **Start over** clears the checks, to tune the next instrument.
- **Settings:** light or dark theme (or the system's), C D E or Do Re Mi note names, reference A4
  from 430 to 450 Hz, normal (±5 cents) or fine (±2 cents) precision, keep the screen on while
  tuning, and the language: English, Português or Español. By default it follows the phone's
  language, and falls back to English. Everything is remembered.

### Instruments

The first tuning of each instrument is the standard one, already picked when you choose it.

| Instrument | Tunings |
|---|---|
| Ukulele | Standard, Low G, D tuning |
| Baritone ukulele | Standard |
| Cavaquinho | Standard, Natural |
| Guitar (6 strings, acoustic or electric) | Standard, Drop D, Half step down, Whole step down, DADGAD, Open G, Open D |
| 7-string guitar | Low C 7th, Low B 7th |
| Viola caipira | Cebolão in E, Cebolão in D, Rio abaixo |
| 4-string bass | Standard, Drop D, Half step down |
| 5-string bass | Standard, High C |
| 6-string bass | Standard |

The cavaquinho and the viola caipira are Brazilian. The cavaquinho is the small four-string
instrument of samba and choro. The viola caipira has ten strings in five pairs, the three lower
pairs tuned in octaves: OpenTuner accepts either string of a pair. The notes and frequencies of
every tuning are in [docs/REQUISITOS.md](docs/REQUISITOS.md#2-instrumentos-e-afinações-da-versão-10) (in Portuguese).

## Privacy

- **One permission: the microphone.** Sound is analyzed in memory, on the phone, and thrown away.
  It is never recorded and never sent anywhere.
- **No internet permission.** OpenTuner could not send anything even if it wanted to, and it works
  offline, always.
- **No ads, analytics, crash reporting or Google Play Services. No account, no in-app purchases.**
  Your settings stay on the phone, and uninstalling removes them.
- The release script refuses to publish an APK that asks for any Android permission other than the
  microphone (`RECORD_AUDIO`).

Full text: [privacy policy](https://guilhermefeitosa66.github.io/open-tuner/privacy/).

**Never ads.** For as long as the project can be paid for and kept in the store, there will be no
ads, no in-app purchases and no paid version with extra features. The promise is public, on the
[website](https://guilhermefeitosa66.github.io/open-tuner/).

## What's next

Android first, iOS later. Planned after 1.0, with no dates: Google Play, custom tunings, a chromatic
mode, 12-string guitar, more languages (by the community), F-Droid and iOS. The details are in the
roadmap of [docs/REQUISITOS.md](docs/REQUISITOS.md#8-roteiro).

Out of scope, on purpose: songs, chords, lessons, metronome, recording, accounts, cloud, ads and
in-app purchases.

## Building from source

You need:

- Flutter 3.38.5, the version the CI uses;
- the Android SDK and a JDK that Gradle accepts (the CI uses Java 17);
- a device or emulator with Android 7.0 or newer.

```bash
git clone https://github.com/guilhermefeitosa66/open-tuner.git
cd open-tuner
make verificar      # checks Flutter, Android SDK, Java, packages and devices
make dependencias   # flutter pub get
make rodar          # runs on the connected device, with hot reload
```

The `make` targets have Portuguese names; `make` alone lists them all.

| Command | What it does |
|---|---|
| `make verificar` | Checks Flutter, Android SDK, Java, packages and connected devices |
| `make dependencias` | `flutter pub get`, which also generates the text classes in `lib/l10n/` |
| `make textos` | Regenerates `lib/l10n/textos*.dart` from the ARB files (`flutter gen-l10n`) |
| `make rodar` | Runs in debug mode, with hot reload |
| `make emuladores` | Lists the Android emulators (AVDs) |
| `make emulador AVD=<name>` | Opens an emulator that hears the computer's microphone |
| `make testar` | Format check, analysis and tests, like the CI |
| `make analisar` | Static analysis (`dart analyze lib test`) |
| `make formatar` | Formats `lib` and `test` |
| `make apk` | Release APKs, one per architecture |
| `make instalar` | Builds the APKs and installs the one for the device's architecture over the current install, keeping its data |
| `make aab` | Release App Bundle, the Play Store format |
| `make site` | Serves `site/` at http://localhost:8000/ |
| `make desatualizadas` | Lists the packages that have newer versions |
| `make limpar` | Deletes the build output (`flutter clean`) |

With more than one device connected, add `DISPOSITIVO=<id>` (ids from `flutter devices`). `make
chave` and `make release` are for the maintainer, who holds the signing key:
[docs/assinatura.md](docs/assinatura.md) and [docs/release.md](docs/release.md).

To run the tests directly:

```bash
flutter test                                  # full suite
flutter test test/dominio/nota_test.dart      # one file
flutter test --plain-name 'A4'                # tests by name
```

Good to know:

- **Analysis.** `make analisar` runs `dart analyze lib test` and not `flutter analyze`: on Linux the
  latter watches the pub cache through inotify and can fail with `Too many open files`. The CI raises
  that limit and runs `flutter analyze`.
- **Emulator microphone.** An emulator started without `-allow-host-audio` gives the app silence,
  and the marker never moves; `make emulador` passes that flag. If there is still no sound, also turn
  on "Virtual microphone uses host audio input" in the emulator's Extended controls → Microphone.
- **Your own builds.** Without `android/key.properties`, release builds are signed with the debug
  key. They install and run, but cannot update an OpenTuner downloaded from the releases: uninstall
  that one first (it removes its settings).

### Where things are

| Path | What is there |
|---|---|
| `lib/dominio/` | Pure Dart, no Flutter: notes, the instruments and tunings table, the pitch detector, the harmonic correction, the Kalman filter and the string choice. The tests that matter live here. |
| `lib/audio/` | Microphone capture, and the string notes and chime, synthesized in code |
| `lib/features/` | The tuner screen and the settings sheet |
| `lib/dados/` | Saved preferences |
| `lib/app/` | App setup, color tokens (`tema.dart`) and language choice (`idioma.dart`) |
| `lib/l10n/` | Texts, one ARB file per language, and the classes generated from them (committed) |
| `test/` | Tests, in the same layout as `lib/` |
| `tool/` | Scripts behind `make`: environment check, install, signing key, release, icons |
| `site/` | The website, published to GitHub Pages by the `Site` workflow |
| `docs/` | Project documentation, in Portuguese |

## Contributing

The code is written in Portuguese: class, method and variable names (`Nota`, `centsEntre`),
comments, commit messages and the documentation in `docs/`. Issues are welcome in English,
Portuguese or Spanish.

- **Bugs:** [open an issue](https://github.com/guilhermefeitosa66/open-tuner/issues) with the phone
  model, the Android version, the instrument and tuning, and what the screen showed.
- **A missing tuning or instrument:** open an issue with its notes, from the top string to the
  bottom one. Tunings live in a single table, `lib/dominio/afinacoes.dart`.
- **Translations:** the texts are in `lib/l10n/`. `app_en.arb` is the template, with a description
  of each text; `app_pt.arb` and `app_es.arb` are the translations. To fix a text, edit the ARB
  files and run `flutter pub get`, which regenerates `lib/l10n/textos*.dart`. A new language also
  needs an entry in `lib/app/idioma.dart` and in `test/l10n/arb_test.dart`: open an issue first and
  we will set it up together. Machine translation is only published after review by someone who
  speaks the language. Community translation on a hosted Weblate is planned.
- **Pull requests:** run `make testar` before sending (the CI runs the same checks). No text the
  user sees is written in the code: it goes in the three ARB files, and a test fails if they do not
  have the same keys. No dependency that adds the internet permission, ads, analytics or Google Play
  Services. And Android first, but no plugin or native code that ties the app to Android. Before a
  new screen or rule, read [docs/REQUISITOS.md](docs/REQUISITOS.md).

## Documentation

In Portuguese, in `docs/`:

- [REQUISITOS.md](docs/REQUISITOS.md): what 1.0 does, the tunings table with frequencies, palette,
  architecture and roadmap.
- [notas/v1.0.0.md](docs/notas/v1.0.0.md): release notes of 1.0.0.
- [release.md](docs/release.md): how a release is built, signed and published.
- [assinatura.md](docs/assinatura.md): the signing key and how to check it.
- [loja/](docs/loja/README.md): store listings (en, pt, es), data safety answers and publishing
  checklist.
- [marca/](docs/marca/README.md): the symbol and the app icon.

The [website](https://guilhermefeitosa66.github.io/open-tuner/), with the [privacy policy](https://guilhermefeitosa66.github.io/open-tuner/privacy/) and the
[terms of use](https://guilhermefeitosa66.github.io/open-tuner/terms/), is in English, [Portuguese](https://guilhermefeitosa66.github.io/open-tuner/pt/) and [Spanish](https://guilhermefeitosa66.github.io/open-tuner/es/): the flag
buttons at the top of each page switch the language. Its source is in `site/`, and a new text goes
into all three versions.

## License

[Apache 2.0](LICENSE). The OpenTuner name and logo are not part of the license: a derived version
needs another name and another icon.
