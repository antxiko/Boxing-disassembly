#!/usr/bin/env python3
"""Recorre los cuatro archivos de figuras que ocupan los 20 KB de 0x707E a 0xBFF0.

No hay ni una `ld hl,NNNN` que apunte ahi dentro salvo a la primera tabla: el
resto se alcanza indexando. Asi que la unica forma de saber que hay es hacer lo
mismo que el Z80, y eso es lo que hace esto.

LA FORMA DE UNA FIGURA, sacada de 0x4F87..0x505C leyendo el codigo:

    +0            cuatro punteros (8 B) a los cuatro guiones del fondo, que
                  0x4FC5 y 0x4FD1 vuelcan en patrones y en colores
    +8            N, la cuenta de piezas moviles que declara la figura
    +9            M registros de TRES bytes -fila, columna y color del
                  sprite-, que el bucle de 0x5007 recorre de tres en tres.
                  M = N en el archivo del jugador y M = N+1 en los tres del
                  rival: 0x4FFE (y 0x513E) hace `inc b` cuando el bit 1 del
                  contador de cuadros esta puesto, y ese bit es el que
                  reparte los turnos (0x4F8A): pares el jugador, impares el
                  rival. La pieza de mas es la de la SEGUNDA VUELTA, ver
                  pantallas.piezas_que_se_pintan
    +9+3M         ocho bytes de disposicion, que 0x500C se salta con
                  `ld a,008h` y 0x51FF lee para colocar las casillas
    +17+3M        M punteros (2M B) a los guiones de las piezas, que el bucle
                  de 0x504A recorre uno a uno
    +17+5M        aqui empiezan los guiones

O sea que la cabecera mide 17 + 5M bytes, y eso NO es una suposicion: para la
figura 0 del primer archivo (M = N = 4) da 0x721E + 29 = 0x723B, que es
exactamente donde empiezan los cuatro punteros de las piezas, y 0x723B + 8 =
0x7243, que es exactamente el primer guion. Y en los tres archivos de rival
las 57 figuras cierran con N+1 y NO con N: con N la tabla de punteros se lee
tres bytes desplazada y se sale del archivo a la primera.

Cada tabla de archivo se cierra con la regla de siempre -la entrada mas baja
por delante marca el final-, y las cuatro dan 19 entradas clavadas.

Uso: archivo_de_figuras.py <rom> [--huecos]
"""
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0] if "/" in __file__ else ".")
from formatos import figura, pieza                   # noqa: E402

ORG = 0x4000
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


def piezas_de_la_figura(rom, p, rival):
    """Cuantas piezas lleva la figura de verdad, y donde estan sus punteros.

    El byte de +8 dice N, pero no es la cuenta que recorre el Z80: 0x4FFE (y
    0x513E para los atributos) hace `inc b` cuando el bit 1 del contador de
    cuadros esta puesto, y ese bit es el que reparte los turnos -en los pares
    se pinta al jugador y en los impares al rival, 0x4F8A-. Asi que las
    figuras del archivo del jugador llevan N registros y N punteros, y las de
    los tres archivos de rival llevan N+1: la pieza de mas es la que 0x5034
    reserva para la segunda vuelta (pantallas.piezas_que_se_pintan).

    Y se comprueba que esa cuenta CIERRA: las piezas son de 32 bytes y van
    pegadas, asi que con la cuenta buena los punteros caen dentro del archivo
    y cada pieza acaba antes del final. Con la otra no.
    """
    n = rom[p + 8 - ORG]
    m = n + 1 if rival else n
    base = p + 17 + 3 * m
    ptr = [palabra(rom, base + 2 * i) for i in range(m)]
    if not ptr or not all(0x707E <= x < 0xBFF0 for x in ptr):
        raise ValueError("la figura de 0x%04X no cierra con %d piezas"
                         % (p, m))
    for x in ptr:
        if pieza(rom, x)[0] > 0xBFF0:
            raise ValueError("la pieza 0x%04X de la figura 0x%04X se sale del "
                             "archivo" % (x, p))
    return m, ptr, 0


def recorre_una_figura(rom, p, marca, rival):
    """Marca la cabecera, los cuatro guiones y las piezas de una figura."""
    m, ptr, fin_piezas = piezas_de_la_figura(rom, p, rival)
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
                n, g = recorre_una_figura(rom, p, marca, t != TABLAS[0])
            except ValueError as e:
                print("   %2d  figura 0x%04X  NO CIERRA: %s" % (i, p, e))
                continue
            print("   %2d  figura 0x%04X  %d piezas  cabecera %d B  guiones %s"
                  % (i, p, n, 17 + 5 * n, " ".join("%04X" % x for x in g)))
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
