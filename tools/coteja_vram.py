#!/usr/bin/env python3
"""Compara la VRAM que monta tools/vram.py con la del emulador, byte a byte.

Mirar el dibujo no basta. Las imagenes de este repositorio se montan ejecutando
en Python los pasos del cartucho, y la unica forma de saber si el formato esta
bien leido es coger la VRAM que el VDP tiene DE VERDAD -volcada con
tools/omsx_vram.tcl mientras la demostracion se juega sola- y restarle la de
Python.

La geometria de este cartucho va al reves de lo normal, y por eso las tablas no
estan donde uno espera (lo dicen los ocho bytes de 0x4429: R3 = 0x7F y
R4 = 0x07):

    color      0x0000..0x17FF   tres bancos de 0x800
    spr patr   0x1800..0x1FFF   los 64 patrones de sprite
    patrones   0x2000..0x37FF   tres bancos de 0x800
    nombres    0x3800..0x3AFF   que casilla va en cada sitio
    spr atrib  0x3B00..0x3B7F

Lo que se compara y lo que NO:

  - color, patrones y nombres SI: son lo que dibuja la lamina, y se montan al
    entrar en la pantalla.
  - los patrones de sprite y sus atributos se comparan APARTE, en los
    combates: los rehace el gancho de interrupcion cada cuadro, pero en el
    instante del volcado los dos boxeadores estan en la accion y la columna
    que apunta info_rivalN.txt, asi que se montan con esas y se comparan los
    doce atributos y los 32 bytes de patron de cada sprite que se pinta. Los
    patrones de partida se turnan con el contador de cuadros, y se leen del
    propio volcado. Y lo mismo con las casillas del cuerpo que la tabla de
    nombres tiene puestas en las filas 8 a 15. Sin esto el cotejo era ciego a
    lo que distingue a los seis rivales -la melena de SANCHESS, la coleta de
    CHINA KHAN y el verde de MOAI Jr. son sprites, color de sprite y color de
    casilla-, y se publico que eran tres con el color cambiado.
  - de la tabla de nombres se dejan fuera las casillas que el marcador y el
    reloj reescriben cuadro a cuadro; van declaradas abajo, una a una.

Uso: coteja_vram.py <rom> <org> <carpeta con los volcados>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vram as V                                             # noqa: E402
import pantallas as P                                        # noqa: E402

# Las casillas de la tabla de nombres que cambian solas mientras corre el
# combate, con la rutina que las escribe al lado. No se comparan porque el
# volcado se hace medio segundo despues de montar la pantalla y para entonces
# ya han corrido treinta cuadros.
VIVAS = [
    (0x3A07, 2, "la tarjeta del de la izquierda (0x4E2D)"),
    (0x3A17, 2, "la tarjeta del de la derecha (0x4E36)"),
    (0x382E, 4, "el reloj del asalto (0x5798)"),
    (0x3A5C, 2, "el asalto (0x4E72)"),
    (0x3A89, 2, "la cifra grande de la izquierda (0x4F42)"),
    (0x3A9A, 2, "la cifra grande de la derecha (0x4F3C)"),
    (0x3AC5, 22, "las barras de castigo (0x5448)"),
    (0x3B00, 0x100, "los atributos de sprite (0x5178)"),
]

# Y estas, ademas, en los combates que NO son el primero: lo que la figura
# nueva no reescribe se queda del rival anterior.
FIGURAS = [
    (0x2980, 0x500, "los cuatro juegos de casillas de los boxeadores (0x4FC1)"),
    (0x0980, 0x500, "y su color (0x4FE0)"),
]

TRAMOS = [
    ("color", 0x0000, 0x1800),
    ("patrones", 0x2000, 0x3800),
    ("nombres", 0x3800, 0x3B00),
]


def enmascara(a, con_figuras=True):
    for ini, n, _ in VIVAS + (FIGURAS if con_figuras else []):
        if ini <= a < ini + n:
            return True
    return False


def compara(nombre, mio, real, con_mascara=True):
    print("  %-14s" % nombre, end="")
    total = 0
    for que, ini, fin in TRAMOS:
        malos = [a for a in range(ini, fin)
                 if mio[a] != real[a] and not enmascara(a, con_mascara)]
        total += len(malos)
        print("  %s %d" % (que, len(malos)), end="")
        if malos:
            print(" (primero 0x%04X: %02X != %02X)"
                  % (malos[0], mio[malos[0]], real[malos[0]]), end="")
    print("   TOTAL %d" % total)
    return total


def compara_boxeadores(v, real):
    """Los dos boxeadores tal como estan en el volcado: los doce atributos de
    sprite (0 a 5 el jugador, 6 a 11 el rival), los 32 bytes de patron de cada
    sprite que se pinta -los aparcados en la fila 0xCF no- y las casillas del
    cuerpo -patron y color- que la tabla de nombres tiene puestas en las filas
    8 a 15, que son las que `coloca` escribe."""
    atrib = [a for a in range(0x3B00, 0x3B30) if v.v[a] != real[a]]
    patrones = []
    for k in range(12):
        a = 0x3B00 + 4 * k
        if real[a] == 0xCF:
            continue
        base = 0x1800 + (real[a + 2] & 0xFC) * 8
        patrones += [x for x in range(base, base + 0x20) if v.v[x] != real[x]]
    casillas = []
    usadas = sorted({real[0x3800 + f * 32 + c] for f in range(8, 16)
                     for c in range(32) if 0x30 <= real[0x3800 + f * 32 + c]
                     < 0xD0})
    for n in usadas:
        for t in (0x2800 + n * 8, 0x0800 + n * 8):
            casillas += [x for x in range(t, t + 8) if v.v[x] != real[x]]
    print("  %-14s  atributos %d  patrones %d  casillas del cuerpo %d (%d "
          "casillas)" % ("  boxeadores", len(atrib), len(patrones),
                         len(casillas), len(usadas)), end="")
    for que, malos in (("atributo", atrib), ("patron", patrones),
                       ("casilla", casillas)):
        if malos:
            print(" (primer %s 0x%04X: %02X != %02X)"
                  % (que, malos[0], v.v[malos[0]], real[malos[0]]), end="")
    print("   TOTAL %d" % (len(atrib) + len(patrones) + len(casillas)))
    return len(atrib) + len(patrones) + len(casillas)


def main():
    rom = V.Rom(sys.argv[1], int(sys.argv[2], 0))
    carpeta = sys.argv[3]
    malos = 0
    hechos = 0
    for nombre, monta in (("presentacion", P.presentacion),
                          ("menu", P.menu)):
        fn = os.path.join(carpeta, "vram_%s.bin" % nombre)
        if not os.path.exists(fn):
            continue
        malos += compara(nombre, monta(rom).v, open(fn, "rb").read())
        hechos += 1
    for r in range(6):
        fn = os.path.join(carpeta, "vram_rival%d.bin" % r)
        if not os.path.exists(fn):
            continue
        real = open(fn, "rb").read()
        # (0xE208) sale de `prepara_la_partida`, que corre ANTES de que la
        # sonda imponga el rival, asi que se lee del volcado y no se supone.
        stage = None
        accion = {"accion_derecha": 1, "accion_izquierda": 1}
        info = os.path.join(carpeta, "info_rival%d.txt" % r)
        if os.path.exists(info):
            for ln in open(info, encoding="utf-8"):
                if ln.startswith("stage "):
                    stage = int(ln.split()[1])
                elif ln.split()[0] in accion:
                    accion[ln.split()[0]] = int(ln.split()[1])
        # el patron de partida de cada boxeador, del sprite 0 y del 6
        v = P.combate(rom, r, accion["accion_derecha"],
                      accion["accion_izquierda"], stage=stage,
                      base_jugador=real[0x3B02], base_rival=real[0x3B1A])
        malos += compara("rival %d" % (r + 1), v.v, real)
        malos += compara_boxeadores(v, real)
        hechos += 1
        if r == 0:
            # El PRIMER combate arranca con la zona de las figuras limpia, asi
            # que ahi si se puede comparar tambien el dibujo de los dos
            # boxeadores. En los siguientes no: lo que no reescribe la figura
            # nueva se queda del rival anterior, y eso no hay forma de montarlo
            # sin jugar la partida entera.
            malos += compara("  (con figuras)", v.v, real, con_mascara=False)
    if not hechos:
        print("  no hay volcados en %s: pasa antes `make vram`" % carpeta)
        return 2
    print("  ---- %d pantallas, %d bytes distintos" % (hechos, malos))
    return 0 if malos == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
