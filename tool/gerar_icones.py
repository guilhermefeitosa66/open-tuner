#!/usr/bin/env python3
"""Gera os ícones do OpenTuner a partir da marca em `docs/marca/`.

O que sai daqui (tudo versionado; rode de novo quando a marca mudar):

- `android/app/src/main/res/drawable/ic_launcher_foreground.xml`: primeiro
  plano do ícone adaptativo (API 26+), vector drawable na grade de 108 dp;
- `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`: camada do
  ícone temático do Android 13+, o símbolo numa cor só com a onda vazada;
- `android/app/src/main/res/drawable/simbolo_abertura.xml`: o símbolo da tela
  de abertura, com as cores em `@color` (claro e escuro);
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher*.xml`: o ícone
  adaptativo em si (fundo, primeiro plano e monocromático);
- `android/app/src/main/res/values*/colors.xml`: as cores usadas acima;
- `android/app/src/main/res/mipmap-*/ic_launcher*.png`: ícones legados para
  API 24 e 25, quadrado arredondado e redondo, em todas as densidades;
- `docs/loja/icone-512.png` e `docs/loja/destaque-1024x500.png`: ícone e
  imagem de destaque da ficha na Play Store.

A geometria vem de `docs/marca/icone-app.svg`: a palheta e a onda são os
mesmos `d` do SVG, e as proporções do ícone adaptativo são as de lá.

Dependências (só para rodar o script, nada disso vai para o app):

    pip install playwright shapely pillow
    python -m playwright install chromium

Uso, a partir da raiz do projeto:

    python tool/gerar_icones.py [--previa caminho/previa.png]

`--previa` salva uma imagem com todos os ícones lado a lado, para conferir.
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import io
import re
from pathlib import Path

from PIL import Image
from playwright.async_api import async_playwright
from shapely.geometry import LineString

RAIZ = Path(__file__).resolve().parent.parent
RES = RAIZ / "android/app/src/main/res"
LOJA = RAIZ / "docs/loja"
FONTES = RAIZ / "assets/fontes"

# --- Marca -----------------------------------------------------------------

# Os dois caminhos do símbolo, iguais aos de docs/marca/*.svg, na grade de
# 100 × 110 do símbolo.
PALHETA = (
    "M50 106C42 100 6 62 5 34C4 14 22 4 50 4C78 4 96 14 95 34"
    "C94 62 58 100 50 106Z"
)
ONDA = (
    "M50 18C71 21 71 33 50 36C32 39 32 49 50 51C62 53 62 60 50 62"
    "C44 63 44 67 50 68L50 88"
)
ESPESSURA_ONDA = 7

# Caixa da palheta dentro da grade do símbolo: x de 5 a 95, y de 4 a 106.
CENTRO_PALHETA = (50, 55)
ALTURA_PALHETA = 102

# Posição do símbolo no ícone adaptativo (docs/marca/icone-app.svg): grade de
# 108 dp, símbolo dentro da zona segura de 66 dp.
ADAPTATIVO_TRANSLACAO = (33.5, 31.5)
ADAPTATIVO_ESCALA = 0.41

# Fração da área visível (72 dp dos 108) que a altura da palheta ocupa. Os
# ícones legados e o da loja usam a mesma proporção para ficarem iguais ao
# ícone adaptativo depois da máscara do launcher.
PROPORCAO_SIMBOLO = ALTURA_PALHETA * ADAPTATIVO_ESCALA / 72

NOGUEIRA = "#6B4226"
NOGUEIRA_ESCURA = "#4E2E18"
CREME = "#F5EFE6"
MEL = "#C9935F"
FUNDO_ESCURO = "#14110E"

# Densidades do Android e o tamanho do ícone legado (48 dp) em cada uma.
DENSIDADES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# --- Geometria -------------------------------------------------------------


def _pontos_do_caminho(d: str, passos: int = 64) -> list[tuple[float, float]]:
    """Achata um caminho com M, C e L absolutos numa polilinha densa."""
    tokens = re.findall(r"[MCLZ]|-?\d+(?:\.\d+)?", d)
    pontos: list[tuple[float, float]] = []
    atual = (0.0, 0.0)
    i = 0
    comando = ""
    while i < len(tokens):
        if tokens[i] in "MCLZ":
            comando = tokens[i]
            i += 1
            if comando == "Z":
                continue
        numeros = lambda n: [float(t) for t in tokens[i : i + n]]  # noqa: E731
        if comando in "ML":
            x, y = numeros(2)
            i += 2
            atual = (x, y)
            pontos.append(atual)
        elif comando == "C":
            x1, y1, x2, y2, x3, y3 = numeros(6)
            i += 6
            x0, y0 = atual
            for k in range(1, passos + 1):
                t = k / passos
                u = 1 - t
                pontos.append(
                    (
                        u**3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t**3 * x3,
                        u**3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t**3 * y3,
                    )
                )
            atual = (x3, y3)
    return pontos


def contorno_da_onda() -> str:
    """Contorno do traço da onda como um caminho preenchível.

    O vector drawable não tem máscara; para vazar a onda na camada
    monocromática, o traço (7 unidades, pontas e junções redondas) vira um
    polígono fechado, somado à palheta com `fillType="evenOdd"`.
    """
    traco = LineString(_pontos_do_caminho(ONDA)).buffer(
        ESPESSURA_ONDA / 2, quad_segs=16, cap_style="round", join_style="round"
    )
    traco = traco.simplify(0.02)
    assert traco.geom_type == "Polygon" and not traco.interiors
    coords = list(traco.exterior.coords)[:-1]
    partes = [f"M{coords[0][0]:.2f} {coords[0][1]:.2f}"]
    partes += [f"L{x:.2f} {y:.2f}" for x, y in coords[1:]]
    return "".join(partes) + "Z"


# --- Recursos XML do Android -----------------------------------------------

AVISO_XML = "<!-- Gerado por tool/gerar_icones.py a partir de docs/marca/. Não editar à mão. -->"


def _grupo_adaptativo(conteudo: str) -> str:
    tx, ty = ADAPTATIVO_TRANSLACAO
    return f"""    <!-- Mesma translação e escala de docs/marca/icone-app.svg. -->
    <group
        android:translateX="{tx}"
        android:translateY="{ty}"
        android:scaleX="{ADAPTATIVO_ESCALA}"
        android:scaleY="{ADAPTATIVO_ESCALA}">
{conteudo}
    </group>"""


def _vetor(largura: str, altura: str, vl: int, va: int, corpo: str) -> str:
    return f"""<?xml version="1.0" encoding="utf-8"?>
{AVISO_XML}
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="{largura}"
    android:height="{altura}"
    android:viewportWidth="{vl}"
    android:viewportHeight="{va}">
{corpo}
</vector>
"""


def _palheta_e_onda(cor_palheta: str, cor_onda: str, recuo: str) -> str:
    return f"""{recuo}<path
{recuo}    android:fillColor="{cor_palheta}"
{recuo}    android:pathData="{PALHETA}" />
{recuo}<path
{recuo}    android:strokeColor="{cor_onda}"
{recuo}    android:strokeWidth="{ESPESSURA_ONDA}"
{recuo}    android:strokeLineCap="round"
{recuo}    android:strokeLineJoin="round"
{recuo}    android:pathData="{ONDA}" />"""


def escrever_xml() -> None:
    drawable = RES / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)

    # Primeiro plano: palheta creme, onda na cor do fundo (a mesma do SVG).
    (drawable / "ic_launcher_foreground.xml").write_text(
        _vetor(
            "108dp",
            "108dp",
            108,
            108,
            _grupo_adaptativo(_palheta_e_onda(CREME, NOGUEIRA, " " * 8)),
        ),
        encoding="utf-8",
    )

    # Monocromático: o sistema só usa o alfa e pinta com a cor do tema. A
    # onda sai como buraco (palheta + contorno da onda, par-ímpar).
    monocromatico = f"""        <path
            android:fillColor="#FFFFFFFF"
            android:fillType="evenOdd"
            android:pathData="{PALHETA}{contorno_da_onda()}" />"""
    (drawable / "ic_launcher_monochrome.xml").write_text(
        _vetor("108dp", "108dp", 108, 108, _grupo_adaptativo(monocromatico)),
        encoding="utf-8",
    )

    # Tela de abertura: símbolo solto sobre o fundo do tema, com as cores
    # vindas de values/ e values-night/ (nogueira no claro, mel no escuro).
    (drawable / "simbolo_abertura.xml").write_text(
        _vetor(
            "100dp",
            "110dp",
            100,
            110,
            _palheta_e_onda(
                "@color/abertura_palheta", "@color/abertura_onda", " " * 4
            ),
        ),
        encoding="utf-8",
    )

    adaptativo = f"""<?xml version="1.0" encoding="utf-8"?>
{AVISO_XML}
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
"""
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(adaptativo, encoding="utf-8")
    (anydpi / "ic_launcher_round.xml").write_text(adaptativo, encoding="utf-8")

    def cores(fundo: str, palheta: str, onda: str) -> str:
        return f"""<?xml version="1.0" encoding="utf-8"?>
{AVISO_XML}
<resources>
    <!-- Fundo do ícone adaptativo: nogueira. -->
    <color name="ic_launcher_background">{NOGUEIRA}</color>
    <!-- Tela de abertura: fundo do tema e cores do símbolo. -->
    <color name="abertura_fundo">{fundo}</color>
    <color name="abertura_palheta">{palheta}</color>
    <color name="abertura_onda">{onda}</color>
</resources>
"""

    (RES / "values").mkdir(exist_ok=True)
    (RES / "values-night").mkdir(exist_ok=True)
    (RES / "values/colors.xml").write_text(
        cores(CREME, NOGUEIRA, CREME), encoding="utf-8"
    )
    (RES / "values-night/colors.xml").write_text(
        cores(FUNDO_ESCURO, MEL, FUNDO_ESCURO), encoding="utf-8"
    )


# --- SVG para rasterizar ---------------------------------------------------


def svg_simbolo(cx: float, cy: float, altura: float, palheta: str, onda: str) -> str:
    """Símbolo centrado em (cx, cy), com a palheta na altura pedida."""
    s = altura / ALTURA_PALHETA
    tx = cx - CENTRO_PALHETA[0] * s
    ty = cy - CENTRO_PALHETA[1] * s
    return f"""<g transform="translate({tx:.3f} {ty:.3f}) scale({s:.5f})">
  <path d="{PALHETA}" fill="{palheta}"/>
  <path d="{ONDA}" fill="none" stroke="{onda}" stroke-width="{ESPESSURA_ONDA}"
        stroke-linecap="round" stroke-linejoin="round"/>
</g>"""


def svg_legado(redondo: bool) -> str:
    """Ícone legado na grade de 48: forma de 44 com 2 de margem."""
    if redondo:
        forma = f'<circle cx="24" cy="24" r="22" fill="{NOGUEIRA}"/>'
    else:
        forma = f'<rect x="2" y="2" width="44" height="44" rx="8" fill="{NOGUEIRA}"/>'
    simbolo = svg_simbolo(24, 24, 44 * PROPORCAO_SIMBOLO, CREME, NOGUEIRA)
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">{forma}{simbolo}</svg>'


def svg_loja() -> str:
    """Ícone da Play Store: quadrado cheio, sem transparência (a loja aplica
    a própria máscara de cantos)."""
    simbolo = svg_simbolo(256, 256, 512 * PROPORCAO_SIMBOLO, CREME, NOGUEIRA)
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">'
        f'<rect width="512" height="512" fill="{NOGUEIRA}"/>{simbolo}</svg>'
    )


def _fonte_css(familia: str, arquivo: str, peso: int) -> str:
    dados = base64.b64encode((FONTES / arquivo).read_bytes()).decode()
    return (
        f"@font-face{{font-family:'{familia}';font-weight:{peso};"
        f"src:url(data:font/ttf;base64,{dados}) format('truetype');}}"
    )


def html_destaque() -> str:
    """Imagem de destaque (1024 × 500): madeira de nogueira, símbolo e nome.

    O conteúdo fica no centro, longe das bordas, porque a loja pode recortar
    ou sobrepor o botão de play nas laterais.
    """
    fontes = _fonte_css("Fraunces", "Fraunces-Medium.ttf", 500) + _fonte_css(
        "Fraunces", "Fraunces-Bold.ttf", 700
    )
    simbolo = svg_simbolo(80, 88, 168, CREME, NOGUEIRA)
    return f"""<!doctype html><html><head><style>
{fontes}
html,body{{margin:0;width:1024px;height:500px;overflow:hidden}}
body{{position:relative;background:
  radial-gradient(ellipse 70% 90% at 50% 50%, #6E4428 0%, #5A361E 55%, #3F2513 100%);}}
svg.veios{{position:absolute;inset:0}}
.marca{{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;gap:34px}}
.nome{{font-family:'Fraunces';font-size:112px;line-height:1;letter-spacing:-0.02em;
  color:{CREME};font-weight:500;padding-bottom:10px}}
.nome b{{font-weight:700;color:#D9A56E;margin-left:-0.03em}}
</style></head><body>
<svg class="veios" width="1024" height="500" viewBox="0 0 1024 500">
  <!-- Veios da madeira: ruído esticado na horizontal, bem discreto. -->
  <filter id="veio" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.0025 0.07" numOctaves="3" seed="7"/>
    <feColorMatrix type="matrix" values="0 0 0 0 0.12  0 0 0 0 0.06  0 0 0 0 0.02  0 0 0 1.1 -0.45"/>
  </filter>
  <rect width="1024" height="500" filter="url(#veio)" opacity="0.55"/>
</svg>
<div class="marca">
  <svg width="160" height="176" viewBox="0 0 160 176">{simbolo}</svg>
  <div class="nome">Open<b>Tuner</b></div>
</div>
</body></html>"""


# --- Prévia ----------------------------------------------------------------


def html_previa(pngs: dict[str, bytes]) -> str:
    def img(nome: str, tamanho: int | None = None) -> str:
        dados = base64.b64encode(pngs[nome]).decode()
        estilo = f' style="width:{tamanho}px"' if tamanho else ""
        return f'<img src="data:image/png;base64,{dados}"{estilo}>'

    # Simulações do ícone adaptativo com as máscaras de launcher mais comuns:
    # só os 72 dp do centro aparecem.
    def adaptativo(mascara: str, fundo_monocromatico: str | None = None) -> str:
        if fundo_monocromatico:
            fundo = f'<rect x="18" y="18" width="72" height="72" fill="{fundo_monocromatico}"/>'
            tx, ty = ADAPTATIVO_TRANSLACAO
            corpo = (
                f'<g transform="translate({tx} {ty}) scale({ADAPTATIVO_ESCALA})">'
                f'<path fill="#2F3F5C" fill-rule="evenodd" d="{PALHETA}{contorno_da_onda()}"/></g>'
            )
        else:
            fundo = f'<rect x="18" y="18" width="72" height="72" fill="{NOGUEIRA}"/>'
            corpo = svg_simbolo(54, 54.05, ALTURA_PALHETA * ADAPTATIVO_ESCALA, CREME, NOGUEIRA)
        return (
            '<svg viewBox="18 18 72 72" width="144" height="144">'
            f'<clipPath id="m{id(mascara)}{len(mascara)}">{mascara}</clipPath>'
            f'<g clip-path="url(#m{id(mascara)}{len(mascara)})">{fundo}{corpo}</g></svg>'
        )

    circulo = '<circle cx="54" cy="54" r="36"/>'
    quadrado = '<rect x="18" y="18" width="72" height="72" rx="16"/>'
    gota = '<path d="M54 18H90V54A36 36 0 0 1 54 90A36 36 0 0 1 18 54A36 36 0 0 1 54 18Z"/>'

    legados = "".join(
        f'<figure>{img(f"legado-{d}")}{img(f"legado-redondo-{d}")}<figcaption>{d}</figcaption></figure>'
        for d in DENSIDADES
    )

    def abertura(fundo: str, palheta: str, onda: str) -> str:
        # Tela de 360 × 720 dp em escala 0,5; símbolo de 96 × 106 dp.
        simbolo = svg_simbolo(90, 180, 53 * 102 / 110, palheta, onda)
        return f'<svg width="180" height="360" style="background:{fundo};border-radius:18px">{simbolo}</svg>'

    return f"""<!doctype html><html><head><style>
body{{margin:0;padding:24px;background:#DDD6CC;font:14px sans-serif;color:#231A13;width:1100px}}
h2{{font-size:15px;margin:18px 0 8px}}
.linha{{display:flex;gap:18px;align-items:flex-end;flex-wrap:wrap}}
figure{{margin:0;display:flex;gap:6px;align-items:flex-end}}
figcaption{{font-size:11px;color:#6E5E50}}
.tema{{background:#E8EEF8;padding:10px;border-radius:12px}}
</style></head><body>
<h2>Legados (API 24–25), tamanho real: quadrado arredondado e redondo</h2>
<div class="linha">{legados}</div>
<h2>Adaptativo (API 26+): círculo, quadrado arredondado, gota · monocromático (Android 13, tema)</h2>
<div class="linha">{adaptativo(circulo)}{adaptativo(quadrado)}{adaptativo(gota)}
<span class="tema">{adaptativo(circulo, "#D6E3FF")}</span></div>
<h2>Abertura (claro e escuro) · Play Store 512 (reduzido)</h2>
<div class="linha">{abertura(CREME, NOGUEIRA, CREME)}{abertura(FUNDO_ESCURO, MEL, FUNDO_ESCURO)}{img("loja-512", 256)}</div>
<h2>Destaque 1024 × 500 (reduzido)</h2>
<div class="linha">{img("destaque", 768)}</div>
</body></html>"""


# --- Rasterização ----------------------------------------------------------


async def _rasterizar(pagina, html: str, largura: int, altura: int, transparente: bool) -> bytes:
    await pagina.set_viewport_size({"width": largura, "height": altura})
    await pagina.set_content(html)
    await pagina.evaluate("document.fonts.ready")
    return await pagina.screenshot(omit_background=transparente)


def _html_svg(svg: str, tamanho: int) -> str:
    svg = svg.replace("<svg ", f'<svg width="{tamanho}" height="{tamanho}" ', 1)
    return (
        "<!doctype html><html><body style='margin:0;background:transparent'>"
        f"{svg}</body></html>"
    )


async def rasterizar(previa: Path | None) -> None:
    pngs: dict[str, bytes] = {}
    async with async_playwright() as p:
        navegador = await p.chromium.launch()
        pagina = await navegador.new_page(device_scale_factor=1)

        for densidade, tamanho in DENSIDADES.items():
            pasta = RES / f"mipmap-{densidade}"
            pasta.mkdir(parents=True, exist_ok=True)
            for redondo, nome in ((False, "ic_launcher"), (True, "ic_launcher_round")):
                png = await _rasterizar(
                    pagina, _html_svg(svg_legado(redondo), tamanho), tamanho, tamanho, True
                )
                (pasta / f"{nome}.png").write_bytes(png)
                chave = "legado-redondo" if redondo else "legado"
                pngs[f"{chave}-{densidade}"] = png

        LOJA.mkdir(parents=True, exist_ok=True)
        # A Play Store pede PNG de 32 bits (com canal alfa), mas todo opaco.
        # O Chromium grava RGB quando não há transparência; o Pillow só
        # acrescenta o canal alfa, 255 em tudo.
        opaco = await _rasterizar(pagina, _html_svg(svg_loja(), 512), 512, 512, False)
        saida = io.BytesIO()
        Image.open(io.BytesIO(opaco)).convert("RGBA").save(saida, "PNG", optimize=True)
        pngs["loja-512"] = saida.getvalue()
        (LOJA / "icone-512.png").write_bytes(pngs["loja-512"])

        # A imagem de destaque, ao contrário, é PNG de 24 bits, sem alfa.
        pngs["destaque"] = await _rasterizar(pagina, html_destaque(), 1024, 500, False)
        (LOJA / "destaque-1024x500.png").write_bytes(pngs["destaque"])

        if previa:
            await pagina.set_viewport_size({"width": 1148, "height": 400})
            await pagina.set_content(html_previa(pngs))
            previa.parent.mkdir(parents=True, exist_ok=True)
            await pagina.screenshot(path=str(previa), full_page=True)

        await navegador.close()


def main() -> None:
    argumentos = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    argumentos.add_argument("--previa", type=Path, help="salva uma prévia lado a lado")
    opcoes = argumentos.parse_args()
    escrever_xml()
    asyncio.run(rasterizar(opcoes.previa))
    print("Ícones gerados.")


if __name__ == "__main__":
    main()
