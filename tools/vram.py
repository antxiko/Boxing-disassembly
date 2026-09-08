#!/usr/bin/env python3
"""Rehace en Python la VRAM que monta el cartucho, paso por paso.

No hay ni una captura de pantalla en este repositorio: las imagenes salen de
ejecutar aqui las mismas operaciones que hace la ROM, en el mismo orden. Cada
funcion lleva al lado la direccion de la rutina que traduce.

La geometria la declaran los ocho bytes de 0x4429 (ver el .notes). R2 = 0x0E,
R3 = 0x7F, R4 = 0x07, R5 = 0x76 y R6 = 0x03, o sea:

    colores            0x0000..0x17FF   (tres bancos de 0x800)
    patrones de sprite 0x1800..0x1FFF
    patrones           0x2000..0x37FF   (tres bancos de 0x800)
    nombres            0x3800..0x3AFF
    atributos de spr   0x3B00..0x3B7F

Los colores DEBAJO de los patrones, que es lo contrario de lo habitual.

Y una trampa que se paga una vez: el cartucho escribe direcciones como 0x7800
o 0x6008. SETWRT solo mira CATORCE bits, asi que 0x7800 es 0x3800 y 0x6008 es
0x2008. Aqui lo hace `dir14`.
"""
import sys

ORG = 0x4000
TAM = 0x4000

# Los quince colores del TMS9918 mas el transparente, en RGB.
PALETA = [(0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
          (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
          (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
          (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255)]

COLORES = 0x0000
SPR_PATRONES = 0x1800
PATRONES = 0x2000
NOMBRES = 0x3800
SPR_ATRIBUTOS = 0x3B00


class Rom:
    def __init__(self, path, org=ORG):
        self.d = open(path, "rb").read()
        self.org = org

    def b(self, a):
        return self.d[a - self.org]

    def w(self, a):
        return self.b(a) | (self.b(a + 1) << 8)


def dir14(a):
    """Lo que de verdad le llega al VDP: SETWRT solo pone catorce bits."""
    return a & 0x3FFF


class Vram:
    """Los 16 KB del VDP y el puntero de escritura, que se autoincrementa."""

    def __init__(self):
        self.v = bytearray(TAM)
        self.p = 0

    def setwrt(self, a):
        self.p = dir14(a)

    def pon(self, b):
        self.v[self.p] = b & 0xFF
        self.p = (self.p + 1) & 0x3FFF

    def rellena(self, a, n, b):
        """`rellena_la_vram` (0x4571): B veces el mismo byte desde HL."""
        self.setwrt(a)
        for _ in range(n):
            self.pon(b)

    def vuelca(self, a, datos):
        """`vuelca_en_la_vram` (0x4586): BC bytes de (DE) a la VRAM."""
        self.setwrt(a)
        for b in datos:
            self.pon(b)


def descomprime(rom, v, p, destino=None, con_palabra=False):
    """`descomprime` (0x45E3) y `descomprime_desde_palabra` (0x45DD).

    El codigo lleva la cuenta en los siete bits de abajo y el modo en el 7:
    puesto son bytes seguidos y a cero es un byte repetido. Con la cuenta a
    cero hay dos marcas: 0x00 acaba y 0x80 cambia el destino, que viene en la
    palabra de detras. Devuelve donde acaba el guion.
    """
    if con_palabra:
        destino = rom.w(p)
        p += 2
    if destino is not None:
        v.setwrt(destino)
    while True:
        a = rom.b(p)
        c = a & 0x7F
        p += 1
        if c == 0:
            if a == 0:                       # 0x00: se acabo
                return p
            v.setwrt(rom.w(p))               # 0x80: cambia de sitio
            p += 2
            continue
        if a != c:                           # bit 7 puesto: bytes seguidos
            for _ in range(c):
                v.pon(rom.b(p))
                p += 1
        else:                                # bit 7 a cero: uno repetido
            b = rom.b(p)
            p += 1
            for _ in range(c):
                v.pon(b)


def en_tres_bancos_desc(rom, v, p, destino):
    """`descomprime_en_tres_bancos` (0x45BA): el mismo guion en los tres
    tercios, 0x800 mas alla cada vez."""
    for k in range(3):
        descomprime(rom, v, p, destino + k * 0x800)


def en_tres_bancos_rellena(v, destino, n, b):
    """`rellena_los_tres_bancos` (0x45A9)."""
    for k in range(3):
        v.rellena(destino + k * 0x800, n, b)


def cambia_6_por_9(b):
    """`cambia_el_color_6_por_el_9` (0x564C): el color 6 pasa a 9 en la tinta y
    en el fondo, que es lo unico que separa un cuadrilatero del siguiente."""
    alto, bajo = b & 0xF0, b & 0x0F
    if bajo == 6:
        bajo = 9
    if alto == 0x60:
        alto = 0x90
    return alto | bajo


def descomprime_cambiando_el_color(rom, v, p, destino=None):
    """`descomprime_cambiando_el_color` (0x5624): el mismo guion comprimido,
    con cada byte pasado por el cambio de color."""
    if destino is not None:
        v.setwrt(destino)
    while True:
        a = rom.b(p)
        c = a & 0x7F
        if c == 0:
            return p + 1
        p += 1
        if a != c:                           # bit 7 puesto: bytes seguidos
            for _ in range(c):
                v.pon(cambia_6_por_9(rom.b(p)))
                p += 1
        else:
            b = cambia_6_por_9(rom.b(p))
            p += 1
            for _ in range(c):
                v.pon(b)


def pinta_texto(rom, v, p, mascara=0xFF):
    """`pinta_texto` (0x407A) y `borra_texto` (0x4076).

    Palabra con la direccion de VRAM, codigos de casilla, 0xFE para cambiar de
    sitio -y volver a leer la palabra- y 0xFF para acabar. La mascara es lo
    unico que separa pintar de borrar.
    """
    while True:
        v.setwrt(rom.w(p))
        p += 2
        while True:
            a = rom.b(p)
            p += 1
            if a == 0xFF:
                return p
            if a == 0xFE:
                break
            v.pon(a & mascara)


def pinta_por_filas(rom, v, p, destino, desplaza=0):
    """`pinta_por_filas` (0x539D): 0xFF baja una fila, 0x00 acaba, y B
    desplaza el codigo de casilla."""
    hl = destino
    while True:
        hl = (hl + 0x20) & 0xFFFF
        v.setwrt(hl)
        while True:
            a = rom.b(p)
            if a == 0:
                return p + 1
            p += 1
            if a == 0xFF:
                break
            v.pon((a + desplaza) & 0xFF)


def escribe_seguidas(v, destino, primera, cuantas):
    """`escribe_una_fila_del_cartel` (0x464E): B casillas correlativas desde
    A, y devuelve la direccion una fila mas abajo."""
    v.setwrt(destino)
    for k in range(cuantas):
        v.pon(primera + k)
    return destino + 0x20


def cambia_4_por_C(b):
    """`saca_el_byte_con_el_color_cambiado` (0x526F): el fondo que valga 4
    pasa a 0x0C, y la tinta que valga 4 tambien. Del azul oscuro al verde."""
    fondo, tinta = b & 0x0F, b & 0xF0
    if fondo == 0x04:
        fondo = 0x0C
    if tinta == 0x40:
        tinta = 0xC0
    return tinta | fondo


def vuelca_guion(rom, v, p, destino=None, cambia_color=False):
    """`vuelca_un_guion` (0x5060), el de los colores del cuerpo de una figura.

    Mismo formato que `descomprime` pero sin la marca de cambio de sitio: la
    cuenta a cero acaba y ya. Cada byte -los seguidos en 0x506E y el repetido
    en 0x5079- pasa por `saca_el_byte_con_el_color_cambiado` (0x526F), que
    solo cambia algo en el turno del rival, con el bit 4 de (0xE207) puesto y
    (0xE207) & 3 == 2: o sea, para MOAI Jr. y para nadie mas. Eso es
    `cambia_color`, y es lo que lo pone verde donde MOAI KING es azul.
    """
    if destino is not None:
        v.setwrt(destino)
    while True:
        a = rom.b(p)
        c = a & 0x7F
        if c == 0:
            return p + 1
        p += 1
        if a != c:                           # bit 7 puesto: bytes seguidos
            for _ in range(c):
                b = rom.b(p)
                v.pon(cambia_4_por_C(b) if cambia_color else b)
                p += 1
        else:
            b = rom.b(p)
            if cambia_color:
                b = cambia_4_por_C(b)
            p += 1
            for _ in range(c):
                v.pon(b)


def vuelca_guion_de_pieza(rom, v, p, destino=None):
    """`vuelca_un_guion_de_pieza` (0x529D): el codigo lleva la cuenta en los
    siete de abajo y el bit 7 dice si son bytes seguidos (`outi`) o el mismo
    repetido. La cuenta a cero acaba."""
    if destino is not None:
        v.setwrt(destino)
    while True:
        a = rom.b(p)
        c = a & 0x7F
        if c == 0:
            return p + 1
        p += 1
        if a & 0x80:                         # bytes seguidos
            for _ in range(c):
                v.pon(rom.b(p))
                p += 1
        else:                                # el mismo repetido
            b = rom.b(p)
            p += 1
            for _ in range(c):
                v.pon(b)


def pinta_pieza(rom, v, p, destino):
    """`pinta_una_pieza` (0x54F1): 32 bytes exactos, con el 0x00 haciendo de
    marca de hueco -el byte de detras dice cuantos- para no tocar lo que ya
    hay. Aqui el hueco se escribe como cero, que es lo que hace el cartucho."""
    v.setwrt(destino)
    quedan = 0x20
    while quedan > 0:
        b = rom.b(p)
        p += 1
        if b:
            v.pon(b)
            quedan -= 1
        else:
            n = rom.b(p)
            p += 1
            for _ in range(n):
                v.pon(0)
            quedan -= n
    return p


def casilla(v, n, banda):
    """Los 8x8 pixeles de la casilla n en el tercio que se pida."""
    pat = PATRONES + banda * 0x800 + n * 8
    col = COLORES + banda * 0x800 + n * 8
    out = []
    for f in range(8):
        forma, c = v.v[pat + f], v.v[col + f]
        tinta, papel = PALETA[c >> 4], PALETA[c & 0x0F]
        out.append([tinta if forma & (0x80 >> b) else papel for b in range(8)])
    return out


def pinta_sprites(v, px):
    """Los sprites, encima de las casillas.

    R1 = 0xE2 los pone de 16x16 sin ampliar, asi que cada uno son 32 bytes: los
    dieciseis primeros la mitad IZQUIERDA y los dieciseis siguientes la
    DERECHA. En la tabla de atributos van cuatro bytes -fila, columna, patron y
    color-, la fila se pinta una linea mas abajo de lo que dice, 0xD0 acaba la
    lista y el bit 7 del color corre el sprite 32 pixeles a la izquierda.
    """
    for k in range(32):
        a = SPR_ATRIBUTOS + k * 4
        y, x, pat, col = v.v[a], v.v[a + 1], v.v[a + 2], v.v[a + 3]
        if y == 0xD0:
            break
        if col & 0x80:
            x -= 32
        tinta = col & 0x0F
        if tinta == 0:
            continue
        fy = y + 1 if y < 0xE1 else y - 255
        base = SPR_PATRONES + (pat & 0xFC) * 8
        for mitad in range(2):
            for f in range(16):
                fila = v.v[base + mitad * 16 + f]
                for b in range(8):
                    if not fila & (0x80 >> b):
                        continue
                    yy, xx = fy + f, x + mitad * 8 + b
                    if 0 <= yy < 192 and 0 <= xx < 256:
                        px[yy][xx] = PALETA[tinta]


def pinta_pantalla(v, fondo=None, con_sprites=True):
    """Los 256x192 pixeles: 24 filas de 32 casillas, cada tercio con su banco.

    El fondo NO es el de la tabla de arranque. R7 = 0xE4 sale de la tabla de
    0x4429, pero `monta_una_columna_del_fondo` (0x439E) lo reescribe a 0xE1 en
    cada llamada, y desde la presentacion en adelante el borde es el color 1,
    o sea NEGRO. Con el color 0 -transparente- el VDP saca ese.
    """
    if fondo is None:
        fondo = PALETA[1]
    px = [[fondo] * 256 for _ in range(192)]
    for f in range(24):
        for c in range(32):
            d = casilla(v, v.v[NOMBRES + f * 32 + c], f // 8)
            for y in range(8):
                for x in range(8):
                    col = d[y][x]
                    px[f * 8 + y][c * 8 + x] = fondo if col == PALETA[0] else col
    if con_sprites:
        pinta_sprites(v, px)
    return px


if __name__ == "__main__":
    r = Rom(sys.argv[1] if len(sys.argv) > 1 else "boxing.rom")
    v = Vram()
    descomprime(r, v, 0x59C4, 0x2180)
    print("la fuente ocupa %d bytes desde 0x2180"
          % sum(1 for k in range(0x180) if v.v[0x2180 + k]))
