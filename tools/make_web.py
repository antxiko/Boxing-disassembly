#!/usr/bin/env python3
"""Genera la portada de la web de Konami's Boxing, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibujan tools/vram.py y
tools/pantallas.py a partir de los propios bytes de la ROM, ejecutando en
Python los mismos descompresores, montadores de figuras y pintores de sprites
que corre el Z80. Ninguna se ha retocado, y todas estan cotejadas byte a byte
contra la VRAM del emulador con tools/coteja_vram.py.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a
# ojo: 32768 = 6932 + 25836, que es lo que imprime tools/presupuesto.py
# (make sanity). RUTINAS son los bloques con nombre que cuenta densidad.py y
# DENSIDAD la proporcion de instrucciones comentadas, las dos de
# tools/densidad.py (make densidad).
CODIGO = 6932
DATOS = 25836
RUTINAS = 475
INSTRUCCIONES = 3740
COMENTARIOS = 1966
DENSIDAD = "52,6"
DENSIDAD_EN = "52.6"


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Konami's Boxing - desensamblado comentado",
        aviso="<b>Aqui no hay ninguna captura.</b> Todas las imagenes "
              "estan <b>dibujadas desde los bytes de la ROM</b>, ejecutando "
              "en Python los mismos descompresores, montadores de figuras y "
              "pintores de sprites que corre el Z80, y <b>cotejadas byte a "
              "byte contra la VRAM de openMSX</b>: las <b>ocho</b> pantallas "
              "volcadas del emulador &mdash;la presentacion, el titulo y los "
              "seis cuadrilateros&mdash; dan <b>cero</b> diferencias en color "
              "(6.144 bytes), patrones (6.144) y las 768 casillas de la "
              "pantalla, y en el primer combate tambien en las figuras de los "
              "dos boxeadores. El listado y las cifras se reproducen con "
              "<code>make</code>, y el reensamblado devuelve la ROM <b>byte a "
              "byte</b>.",
        claim="<b>Seis rivales, y solo tres dibujados.</b> Los nombres son "
              "seis, pero las figuras salen de una tabla de <b>tres</b> "
              "palabras: los tres de la segunda vuelta son los tres primeros "
              "con el color cambiado. Y el cartucho lleva la puntuacion al "
              "reves de como se lee &mdash;va sumando <b>faltas</b> y al final "
              "hace <code>10 - faltas</code>&mdash;, que es el sistema de los "
              "diez puntos del boxeo de verdad.",
        ficha=["Konami - <b>(c) Konami 1985</b>",
               "Cartucho <b>RC-736</b>, 32 KB",
               "MSX1 - <b>paginas 1 y 2</b>", "Volcado <b>43b23739...</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#stages", "Los seis rivales"), ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El codigo"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que aparecio al desmontarlo",
        h_fas="Los seis rivales, uno a uno",
        nota_fas="La misma pantalla seis veces, montada desde la ROM con lo "
                 "que cambia en cada una: el nombre de la tabla de 0x5661, la "
                 "figura de la de 0x52C9 y, en la segunda vuelta, el cambio "
                 "de color de 0x526F. Ninguna es una captura, y las seis dan "
                 "cero diferencias contra la VRAM del emulador.",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "bloques de codigo medidos"),
                (DENSIDAD + " %", "del listado comentado"),
                (mil(CODIGO, "es"), "bytes de codigo"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen esta de donde sale y que se esta "
                 "viendo.",
        pie_leg="Esto es trabajo de documentacion y preservacion: el codigo y "
                "los graficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Konami's Boxing - a commented disassembly",
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b>, by running in Python the very same "
              "decompressors, figure builders and sprite painters the Z80 "
              "runs, and then <b>checked byte for byte against openMSX's "
              "VRAM</b>: the <b>eight</b> screens dumped from the emulator "
              "&mdash;the intro, the title and the six rings&mdash; come out "
              "with <b>zero</b> differences in colour (6,144 bytes), patterns "
              "(6,144) and the 768 tiles of the screen, and on the first bout "
              "in the two boxers' figures as well. The listing and the "
              "numbers are reproducible with <code>make</code>, and "
              "reassembling gives back the ROM <b>byte for byte</b>.",
        claim="<b>Six opponents, and only three of them drawn.</b> There are "
              "six names, but the figures come out of a table of <b>three</b> "
              "words: the three of the second round are the first three with "
              "the colour swapped. And the cartridge keeps the score upside "
              "down &mdash;it adds up <b>faults</b> and finishes with "
              "<code>10 - faults</code>&mdash;, which is the ten-point must "
              "system of real boxing.",
        ficha=["Konami - <b>(c) Konami 1985</b>",
               "An <b>RC-736</b> 32 KB cartridge",
               "MSX1 - <b>pages 1 and 2</b>", "Dump <b>43b23739...</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#stages", "The six opponents"), ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_fas="The six opponents, one by one",
        nota_fas="The same screen six times, built from the ROM with what "
                 "changes on each: the name from the table at 0x5661, the "
                 "figure from the one at 0x52C9 and, on the second round, the "
                 "colour swap at 0x526F. Not one is a capture, and all six "
                 "come out with zero differences against the emulator's "
                 "VRAM.",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "code blocks measured"),
                (DENSIDAD_EN + "%", "of the listing commented"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

# El contenido propio de este cartucho vive aparte, en contenido_web.py:
# asi el generador no lleva dentro ni un texto del juego anterior.
from contenido_web import HALLAZGOS, GALERIA, COMBATES  # noqa: E402


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es la
    # pantalla de titulo que el propio cartucho pinta, dibujada desde la ROM
    # por pantallas.py. Si el PNG no esta, el trabajo NO esta hecho: se cae al
    # texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Konami&#39;s Boxing">'
                if os.path.exists(ruta_logo)
                else "<h1>Konami&#39;s Boxing</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    # los seis cuadrilateros
    tiras = ""
    for fich, es, en in COMBATES:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        tiras += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                  f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' - '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="stages">
  <h2>{t['h_fas']}</h2>
  <p class="n">{t['nota_fas']}</p>
  <div class="galeria">{tiras}</div>
</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
