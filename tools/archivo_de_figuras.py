#!/usr/bin/env python3
"""Recorre los cuatro archivos de figuras que ocupan los 20 KB de 0x707E a 0xBFF0.

No hay ni una `ld hl,NNNN` que apunte ahi dentro salvo a la primera tabla: el
resto se alcanza indexando. Asi que la unica forma de saber que hay es hacer lo
mismo que el Z80, y eso es lo que hace esto.

LA FORMA DE UNA FIGURA, sacada de 0x4F87..0x505C leyendo el codigo:

    +0            cuatro punteros (8 B) a los cuatro guiones del fondo, que
                  0x4FC5 y 0x4FD1 vuelcan en patrones y en colores
    +8            N, cuantas piezas moviles lleva la figura
    +9            N registros de TRES bytes (los lee el bucle de 0x5007, que
                  avanza de tres en tres)
    +9+3N         ocho bytes que 0x500C se salta con `ld a,008h`
    +17+3N        N punteros (2N B) a los guiones de las piezas, que el bucle
                  de 0x504A recorre uno a uno
    +17+5N        aqui empiezan los guiones

O sea que la cabecera mide 17 + 5N bytes, y eso NO es una suposicion: para la
figura 0 del primer archivo da 0x721E + 29 = 0x723B, que es exactamente donde
empiezan los cuatro punteros de las piezas, y 0x723B + 8 = 0x7243, que es
exactamente el primer guion.

Cada tabla de archivo se cierra con la regla de siempre -la entrada mas baja
por delante marca el final-, y las cuatro dan 19 entradas clavadas.

Uso: archivo_de_figuras.py <rom> [--huecos]
"""
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0] if "/" in __file__ else ".")
from formatos import figura, pieza                   # noqa: E402

ORG = 0x4000
AMBIGUAS = []
TABLAS = (0x7086, 0x825C, 0x9670, 0xABB4)


def palabra(rom, a):
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def entradas_de_la_tabla(rom, t):
    """Cuantas entradas tiene la tabla: la mas baja por delante la cierra."""
    n, tope = 0, 0xC000
    while t + n * 2 < tope:
        w = palabra(rom, t + n * 2)
        if w > t:
            tope = min(tope, w)
        n += 1
    return [palabra(rom, t + i * 2) for i in range(n)]


def piezas_de_la_figura(rom, p):
    """Cuantas piezas lleva la figura, MEDIDO y no supuesto.

    El byte de +8 dice N, pero el bucle de 0x5007 puede recorrer una pieza mas:
    0x5005 hace `inc b` cuando el bit 1 del contador de cuadros esta puesto.
    Asi que se prueban las dos y se elige la que CIERRA: las piezas de una
    figura son de 32 bytes cada una y van pegadas, asi que la buena es la que
    deja las N (o N+1) piezas encadenadas sin hueco.
    """
    n = rom[p + 8 - ORG]
    buenas = []
    for m in (n, n + 1):
        base = p + 17 + 3 * m
        ptr = [palabra(rom, base + 2 * i) for i in range(m)]
        if not ptr or not all(0x707E <= x < 0xBFF0 for x in ptr):
            continue
        try:
            if any(pieza(rom, x)[0] > 0xBFF0 for x in ptr):
                continue
        except ValueError:
            continue
        buenas.append((m, ptr))
    if not buenas:
        raise ValueError("la figura de 0x%04X no cierra con %d ni con %d piezas"
                         % (p, n, n + 1))
    if len(buenas) > 1:
        AMBIGUAS.append(p)
    return buenas[0][0], buenas[0][1], 0


def recorre_una_figura(rom, p, marca):
    """Marca la cabecera, los cuatro guiones y las piezas de una figura."""
    m, ptr, fin_piezas = piezas_de_la_figura(rom, p)
    for k in range(17 + 5 * m):
        marca(p + k)
    guiones = [palabra(rom, p + 2 * i) for i in range(4)]
    for g in guiones:
        f, _ = figura(rom, g)
        for k in range(g, f):
            marca(k)
    for g in ptr:
        f, _ = pieza(rom, g)
        for k in range(g, f):
            marca(k)
    return m, guiones


def main():
    rom = open(sys.argv[1], "rb").read()
    cub = bytearray(len(rom))

    def marca(a):
        if ORG <= a < ORG + len(rom):
            cub[a - ORG] = 1

    for t in TABLAS:
        ent = entradas_de_la_tabla(rom, t)
        for k in range(len(ent) * 2):
            marca(t + k)
        print("ARCHIVO con tabla en 0x%04X: %d figuras, la tabla acaba en 0x%04X"
              % (t, len(ent), t + len(ent) * 2))
        for i, p in enumerate(ent):
            try:
                n, g = recorre_una_figura(rom, p, marca)
            except ValueError as e:
                print("   %2d  figura 0x%04X  NO CIERRA: %s" % (i, p, e))
                continue
            print("   %2d  figura 0x%04X  %d piezas  cabecera %d B  guiones %s"
                  % (i, p, n, 17 + 5 * n, " ".join("%04X" % x for x in g)))
    if AMBIGUAS:
        print("")
        print("OJO: %d figuras cuadran con las DOS cuentas de piezas: %s"
              % (len(AMBIGUAS), " ".join("%04X" % x for x in AMBIGUAS)))
    ini, fin = 0x707E, 0xBFF0
    huecos, s = [], None
    for a in range(ini, fin):
        if not cub[a - ORG]:
            if s is None:
                s = a
        elif s is not None:
            huecos.append((s, a))
            s = None
    if s is not None:
        huecos.append((s, fin))
    sin = sum(b - a for a, b in huecos)
    print("")
    print("0x%04X..0x%04X: %d bytes, %d explicados, %d sin explicar en %d huecos"
          % (ini, fin, fin - ini, fin - ini - sin, sin, len(huecos)))
    if "--huecos" in sys.argv:
        for a, b in huecos:
            print("   %04X..%04X  %5d" % (a, b, b - a))


if __name__ == "__main__":
    main()
