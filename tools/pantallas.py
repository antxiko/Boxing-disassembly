#!/usr/bin/env python3
"""Monta pantallas enteras ejecutando en Python los pasos del cartucho.

No hay ni una captura de pantalla en este repositorio. Cada lamina se construye
igual que la construye el juego -descomprimiendo sus guiones en una VRAM de
mentira, con tools/vram.py, y pintando esa VRAM con la paleta del TMS9918-, y
cada funcion lleva al lado la direccion de la rutina que traduce.

Lo que sale:

    presentacion.png     el cartel de KONAMI ya subido a su sitio
    menu.png             la pantalla del titulo, con las cuatro opciones
    rotulo.png           el logotipo recortado, para la cabecera de la web
    fuente.png           las casillas 0x30..0x5D de la fuente
    combate_N.png        el cuadrilatero de cada uno de los seis rivales
    poses_jugador.png    las 19 figuras del archivo del jugador
    poses_rival_N.png    las 19 de cada uno de los SEIS rivales, cuerpo y
                         sprites, con las piezas que (0xE207) manda pintar

Uso: pantallas.py <rom> <org> <carpeta de salida>
"""
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vram as V                                             # noqa: E402
import archivo_de_figuras as A                               # noqa: E402

NOMBRES = V.NOMBRES


# ----------------------------------------------------------------------
# PNG
# ----------------------------------------------------------------------
def png(w, h, filas, fn):
    raw = b"".join(b"\0" + bytes(b for px in fila for b in px) for fila in filas)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def escala(filas, n):
    return [[px for px in fila for _ in range(n)] for fila in filas
            for _ in range(n)]


def guarda(filas, fn, esc=2):
    f = escala(filas, esc)
    png(len(f[0]), len(f), f, fn)
    print("  %-28s %d x %d" % (os.path.basename(fn), len(f[0]), len(f)))


# ----------------------------------------------------------------------
# LAS PANTALLAS
# ----------------------------------------------------------------------
def monta_la_fuente(rom, v):
    """`monta_la_letra` (0x4595): el guion de 0x59C4 en los tres bancos desde
    la casilla 0x30, en blanco sobre transparente."""
    V.en_tres_bancos_desc(rom, v, 0x59C4, 0x2180)
    V.en_tres_bancos_rellena(v, 0x0180, 0x180, 0xF0)


def presentacion(rom):
    """`monta_la_presentacion` (0x42CA) y `sube_el_cartel` (0x462A).

    El cartel son 26 casillas correlativas de la 1 a la 26 en tres filas -3, 11
    y 12-, y (0xE00E) arranca en 0x3AAA. Cada paso resta una fila y (0xE00A)
    cuenta catorce, asi que acaba en 0x3AAA - 14*0x20.
    """
    v = V.Vram()
    # `monta_la_presentacion` (0x42CA) son CUATRO cosas encadenadas: 0x42D0 no
    # lleva `ret` y cae dentro de 0x42E4, asi que el fondo entra tambien.
    V.en_tres_bancos_desc(rom, v, 0x465C, 0x2008)       # monta_el_cartel
    V.en_tres_bancos_rellena(v, 0x0008, 0xD0, 0xF0)
    monta_la_fuente(rom, v)                             # monta_la_letra
    V.descomprime(rom, v, 0x59C4, 0x3600)               # la fuente en 0x3600
    v.rellena(0x1600, 0x180, 0x70)
    V.descomprime(rom, v, 0x5BD6, con_palabra=True)     # el fondo
    v.rellena(V.dir14(0x4480), 0x380, 0x60)
    hl = 0x3AAA - 0x20 * 14
    n = 1
    for cuantas in (3, 11, 12):
        hl = V.escribe_seguidas(v, hl, n, cuantas)
        n += cuantas
    v.rellena(hl, 12, 0x40)      # la fila que el cartel deja debajo al subir
    V.pinta_texto(rom, v, 0x5BBC)                       # KONAMI SOFTWARE
    return v


def fondo_de_la_presentacion(rom, v):
    """`monta_la_presentacion_entera` (0x4391): el guion gordo de 0x5BD6, el
    color 0x60 en las casillas altas y luego las dieciseis columnas que
    `monta_una_columna_del_fondo` (0x439E) va poniendo de ocho en ocho."""
    # `monta_una_columna_del_fondo` (0x439E): ocho casillas hacia abajo desde
    # la fila 0, columna 8 mas la columna. El codigo sale de sumar siete tantas
    # veces como la columna mas uno y anadirle 0x89, y el `ld a,c` va DESPUES
    # de escribir: por eso la primera casilla de cada columna sale en blanco y
    # el dibujo empieza de verdad en la fila 1.
    for col in range(16):
        de = 0x3808 + col
        cod = (0x89 + 7 * (col + 1)) & 0xFF
        a = 0
        for k in range(8):
            v.setwrt(de + k * 0x20)
            v.pon(a)
            a = cod
            cod = (cod + 1) & 0xFF
    V.pinta_texto(rom, v, 0x5B29)             # el rotulo de la presentacion


def menu(rom, opcion=0):
    """`L_4293`: borra la pantalla, monta la presentacion entera y pinta el
    cursor de dos casillas -0x5C y 0x5D- donde diga (0xE042).

    Se parte de lo que dejo la presentacion, que es lo que hace el cartucho: la
    VRAM no se borra entre escenas.

    `donde_va_el_cursor` (0x43F2): la opcion mas veinte, entre cuatro, en la
    fila 0x1A de la tabla de nombres.
    """
    v = presentacion(rom)
    v.rellena(0x3800, 0x300, 0)               # borra_la_pantalla (0x4567)
    V.descomprime(rom, v, 0x59C4, 0x3600)     # monta_la_fuente_en_0x3600
    v.rellena(0x1600, 0x180, 0x70)
    monta_la_fuente(rom, v)
    fondo_de_la_presentacion(rom, v)
    # `donde_va_el_cursor` (0x43F2): (0xE042) mas veinte, dos rotaciones a la
    # derecha, y eso es la parte baja de una direccion con 0x7A arriba.
    a = (opcion + 0x14) & 0xFF
    for _ in range(2):
        a = ((a >> 1) | (a << 7)) & 0xFF
    v.setwrt(0x7A00 | a)
    v.pon(0x5C)
    v.pon(0x5D)
    return v


def push_space_key(rom):
    """La escena 3: el mismo fondo con el rotulo de 0x5B18 encima, que
    `L_42B9` hace parpadear con el bit 4 del contador de cuadros."""
    v = menu(rom)
    V.pinta_texto(rom, v, 0x5B18)
    return v


def e207_del_rival(rival):
    """Lo que vale (0xE207) con cada uno de los seis rivales, del 0 al 5: los
    dos bits de abajo dicen el archivo y el bit 4 la segunda vuelta."""
    return rival if rival < 3 else 0x10 + (rival - 3)


def piezas_que_se_pintan(m, e207):
    """Que piezas de la figura se pintan, y en que orden. 0x5034..0x5049 lo
    decide para los patrones y 0x5187..0x519D hace lo mismo para los
    atributos.

    El jugador (e207 None) las pinta todas. El rival lleva una pieza de mas
    -la primera, ver archivo_de_figuras.piezas_de_la_figura- y (0xE207) dice
    que se hace con ella:

      - bit 4 a cero, la primera vuelta: se SALTA (0x5048), y van de la 1 a
        la M-1. RED WOLF, M.B.ALLI y MOAI KING.
      - bit 4 puesto y bit 0 a cero, SANCHESS y MOAI Jr.: la primera
        SUSTITUYE a la segunda. El `ld a,002h` de 0x5040 se suma al puntero
        una sola vez, tras la primera pieza, y salta la segunda: 0, 2, 3...
      - bit 4 y bit 0 puestos, CHINA KHAN: el `inc b` de 0x5045 las pinta
        TODAS, de la 0 a la M-1. La de mas es su coleta.
    """
    if e207 is None:
        return list(range(m))
    if not e207 & 0x10:
        return list(range(1, m))
    if e207 & 0x01:
        return list(range(m))
    return [0] + list(range(2, m))


def figura(rom, v, tabla, accion, destino, e207=None):
    """El trozo de `pinta_una_figura` (0x4F66) que redibuja el cuerpo.

    Cuatro punteros: los dos primeros van a los PATRONES desde `destino` y los
    dos siguientes a los COLORES, que estan en la misma posicion con el bit 13
    quitado (el `res 5,a` de 0x4F81). Los de patrones usan el formato de
    `vuelca_un_guion_de_pieza` (0x529D) y los de color el de `vuelca_un_guion`
    (0x5060), que pasa cada byte por 0x526F: en el turno del rival, con el
    bit 4 de (0xE207) y (0xE207) & 3 == 2 -MOAI Jr., y solo el- el color 4
    se cambia por el 0x0C. Es lo que lo pone verde donde MOAI KING es azul.
    """
    p = rom.w(tabla + 2 * accion)
    V.vuelca_guion_de_pieza(rom, v, rom.w(p), destino)
    V.vuelca_guion_de_pieza(rom, v, rom.w(p + 2))
    color = destino & ~0x2000
    verde = e207 is not None and bool(e207 & 0x10) and (e207 & 3) == 2
    V.vuelca_guion(rom, v, rom.w(p + 4), color, cambia_color=verde)
    V.vuelca_guion(rom, v, rom.w(p + 6), cambia_color=verde)


def coloca(rom, v, tabla, accion, base, columna, rival=False):
    """`prepara_la_cuenta` (0x51FF) y su bucle de 0x5213: pone en la tabla de
    nombres las casillas que la figura ocupa.

    Los OCHO bytes que 0x500C se salta -los que van detras de los registros de
    tres, o sea en figura + 9 + 3N- son la DISPOSICION: uno por fila, con el
    nibble alto diciendo cuanto se corre a la derecha y el bajo cuantas
    casillas van seguidas. De 8 en adelante, esa fila no se pinta. Las casillas
    son correlativas desde `base`, que sale de la tabla de 0x52C4: 0xA8, 0x30,
    0x58 y 0x80.

    La figura vive siempre en las filas 8 a 15, que es el `ld h,079h` de
    0x5213, o sea el banco de en medio.
    """
    p = rom.w(tabla + 2 * accion)
    # Cuantas piezas lleva NO se cree del byte de +8: 0x5005 y 0x513E le suman
    # una en los turnos del rival, asi que las figuras de rival llevan un
    # registro de mas. Eso es lo que mide archivo_de_figuras.py, y de ahi
    # sale donde empiezan los ocho bytes de disposicion.
    m, _, _ = A.piezas_de_la_figura(rom.d, p, rival)
    disp = p + 9 + 3 * m
    cod = base
    for f in range(8):
        b = rom.b(disp + f)
        col, cuantas = b >> 4, b & 0x0F
        if col >= 8:
            continue
        # el Z80 solo toca L (`ld h,079h` y `add a,l`), asi que la cuenta va
        # en un solo byte y la figura no se sale nunca del banco de en medio
        v.setwrt(0x3900 + ((columna + f * 0x20 + col) & 0xFF))
        for k in range(cuantas):
            v.pon(cod)
            cod = (cod + 1) & 0xFF


def campana(rom, v, e26c=0xED, e26d=0):
    """`pinta_la_campana` (0x550E): siete filas de seis casillas, del guion que
    (0xE26D) elige en la tabla de parejas de 0x68A8. (0xE26C) dice donde, y
    `monta_el_combate` lo arranca en 0xED, o sea la fila 7 columna 13."""
    p = rom.w(0x68A8 + 2 * e26d)
    hl = 0x7800 | e26c
    for f in range(7):
        v.setwrt(hl + f * 0x20)
        for k in range(6):
            v.pon(rom.b(p))
            p += 1


def piezas_y_sprites(rom, v, tabla, accion, base_patron, pixel, atrib,
                     e207=None):
    """Las piezas moviles de una figura: la cabeza, el pelo y los guantes, que
    NO son casillas sino SPRITES de 16x16.

    `pinta_una_pieza` (0x54F1) suelta los 32 bytes de cada pieza seguidos en la
    tabla de patrones de sprite, desde 0x1800 mas el desplazamiento que dice el
    contador de cuadros (0x5013), y ese mismo desplazamiento entre ocho es el
    numero de patron de partida. Que piezas, y en que orden, lo dice
    `piezas_que_se_pintan`: el rival no las pinta todas.

    `monta_los_sprites_de_una_figura` (0x5178) escribe los cuatro bytes de cada
    sprite del tiron: la fila es 0x3F mas el primer byte del registro, la
    columna el pixel del boxeador mas el segundo, el patron sube de cuatro en
    cuatro y el color es el tercero... salvo para MOAI Jr.: de los patrones
    0x30 en adelante -los del rival-, con los bits 4 y 1 de (0xE207) puestos,
    0x51BE cambia el color 4 por el 0x0C. Los sprites que sobran hasta seis se
    aparcan en la fila 0xCF.
    """
    p = rom.w(tabla + 2 * accion)
    m, ptr, _ = A.piezas_de_la_figura(rom.d, p, e207 is not None)
    cuales = piezas_que_se_pintan(m, e207)
    destino = 0x1800 + base_patron * 8
    v.setwrt(destino)
    for k in cuales:
        V.pinta_pieza(rom, v, ptr[k], destino)
        destino += 0x20
    v.setwrt(atrib)
    patron = base_patron
    verde = e207 is not None and (e207 & 0x12) == 0x12
    for k in cuales:
        reg = p + 9 + 3 * k
        v.pon((0x3F + rom.b(reg)) & 0xFF)
        v.pon((pixel + rom.b(reg + 1)) & 0xFF)
        v.pon(patron)
        color = rom.b(reg + 2)
        if patron >= 0x30 and verde and color == 0x04:
            color = 0x0C
        v.pon(color)
        patron = (patron + 4) & 0xFF
    for k in range(6 - len(cuales)):
        for _ in range(4):
            v.pon(0xCF)


def combate(rom, rival=0, accion_jugador=1, accion_rival=1, stage=None,
            base_jugador=0x30, base_rival=0x48):
    """`monta_el_combate` (0x554B), entero y en el orden en que lo hace.

    Los guiones se encadenan: unos siguen por donde acabo el anterior, que es
    lo que hace que la cola se comparta. Y el nombre del rival sale de la tabla
    de 0x5661 indexada con (0xE207) mas tres si lleva el bit 4.
    """
    e207 = e207_del_rival(rival)
    # `monta_el_combate` NO borra la VRAM: apaga la pantalla, escribe lo suyo
    # encima y la vuelve a encender. Asi que se parte de lo que dejo la
    # pantalla anterior -la letra en los tres bancos y hasta los restos del
    # cartel de KONAMI, que siguen ahi debajo-. Sin esto no salen ni los
    # nombres de la fila 1 ni el ROUND / STAGE del marcador, que es justo lo
    # que destapo el volcado del emulador.
    v = push_space_key(rom)
    V.descomprime(rom, v, 0x59C4, 0x3480)              # la fuente en 0x90
    p = V.descomprime(rom, v, 0x5AF4, con_palabra=True)  # el borde
    p = V.descomprime(rom, v, 0x67C3, con_palabra=True)
    p = V.descomprime(rom, v, 0x5D60, con_palabra=True)  # el cuadrilatero
    p = V.descomprime(rom, v, p)                         # y lo que sigue
    p = V.descomprime(rom, v, p, con_palabra=True)
    p = V.descomprime(rom, v, 0x6632, 0x2450)
    V.descomprime(rom, v, 0x66DC)
    # el nombre del rival y el del jugador
    idx = (e207 + 3) & 0x0F if e207 & 0x10 else e207 & 0x0F
    V.descomprime(rom, v, rom.w(0x5661 + 2 * idx), 0x3822)
    V.descomprime(rom, v, 0x56AF, 0x3837)
    V.descomprime_cambiando_el_color(rom, v, 0x6710, 0x0450)
    # el arbitro, en medio y a la izquierda
    V.pinta_por_filas(rom, v, 0x680C, 0x3830)
    V.pinta_por_filas(rom, v, 0x67C8, 0x3820)
    # el marcador
    v.setwrt(0x3A5A)
    v.pon(stage if stage is not None else
          (0x42 if e207 & 0x10 else 0x41))             # (0xE208)
    dos_cifras(v, 0x3A5C, 1, 0x30)                     # el asalto, (0xE051)
    dos_cifras(v, 0x3A9A, 0, 0x90)                     # (0xE21C)
    dos_cifras(v, 0x3A89, 0, 0x90)                     # (0xE21D)
    v.setwrt(0x3A4A)
    v.pon(0x31)                                        # el asalto, en ASCII
    campana(rom, v)
    # el reloj, que 0x5798 vuelca en el primer cuadro que corre
    v.vuelca(0x382E, bytes([0x33, 0x1C, 0x30, 0x30]))
    v.vuelca(0x3AC5, bytes(rom.b(0x54A1 + k) for k in range(22)))
    # las tarjetas de los jueces, que arrancan en blanco
    dos_cifras(v, 0x3A07, 0, 0x30)
    dos_cifras(v, 0x3A17, 0, 0x30)
    # y los dos boxeadores en su esquina
    # Los dos boxeadores. El de la DERECHA es el jugador -archivo 1, columna
    # 22- y el de la IZQUIERDA el rival, en la columna 2. Cada uno tiene DOS
    # juegos de casillas y se van turnando cuadro a cuadro: 0x30 y 0x80 para el
    # jugador, 0x58 y 0xA8 para el rival. Aqui se usan los mismos que tenia el
    # VDP en el instante que volco el emulador.
    arch = rom.w(0x52C9 + 2 * (e207 & 3))
    for destino in (0x2980, 0x2C00):
        figura(rom, v, 0x7086, accion_jugador, destino)
    for destino in (0x2AC0, 0x2D40):
        figura(rom, v, arch, accion_rival, destino, e207)
    coloca(rom, v, 0x7086, accion_jugador, 0x80, 22)
    coloca(rom, v, arch, accion_rival, 0x58, 2, rival=True)
    # y sus piezas moviles, que son sprites: el jugador en los sprites 0 a 5
    # y el rival en los 6 a 11. Los patrones de partida van turnandose con
    # los bits 1 y 2 del contador de cuadros -0x00 o 0x18 el jugador, 0x30 o
    # 0x48 el rival-; aqui se eligen, y el cotejo pasa los del volcado.
    piezas_y_sprites(rom, v, 0x7086, accion_jugador, base_jugador,
                     22 * 8 + 24, 0x3B00)
    piezas_y_sprites(rom, v, arch, accion_rival, base_rival,
                     2 * 8 + 24, 0x3B18, e207)
    return v


def dos_cifras(v, destino, n, base):
    """`pinta_dos_cifras` (0x4E78) y `pinta_dos_cifras_grandes` (0x4E7C): el
    numero va en BCD y la cifra de las decenas se deja en blanco si es cero."""
    alto, bajo = (n >> 4) & 0x0F, n & 0x0F
    v.setwrt(destino)
    v.pon(0 if alto == 0 else base | alto)
    v.pon(base | bajo)


# ----------------------------------------------------------------------
# LAS HOJAS
# ----------------------------------------------------------------------
def hoja_de_casillas(v, ini, n, banda=0, cols=16, esc=3, sep=1):
    """Las casillas ini..ini+n del banco que se pida, en rejilla."""
    filas = (n + cols - 1) // cols
    w, h = cols * (8 + sep) + sep, filas * (8 + sep) + sep
    lienzo = [[(0x18, 0x18, 0x20)] * w for _ in range(h)]
    for k in range(n):
        d = V.casilla(v, ini + k, banda)
        ox = sep + (k % cols) * (8 + sep)
        oy = sep + (k // cols) * (8 + sep)
        for y in range(8):
            lienzo[oy + y][ox:ox + 8] = d[y]
    return escala(lienzo, esc)


def recorta(px, fila, col, alto, ancho):
    return [f[col * 8:(col + ancho) * 8] for f in px[fila * 8:(fila + alto) * 8]]


def main():
    rom = V.Rom(sys.argv[1], int(sys.argv[2], 0))
    out = sys.argv[3]
    os.makedirs(out, exist_ok=True)

    guarda(V.pinta_pantalla(presentacion(rom)),
           os.path.join(out, "presentacion.png"))

    px = V.pinta_pantalla(menu(rom))
    guarda(px, os.path.join(out, "menu.png"))
    guarda(recorta(px, 1, 8, 7, 16), os.path.join(out, "rotulo.png"), 3)
    v = V.Vram()
    monta_la_fuente(rom, v)
    guarda(hoja_de_casillas(v, 0x30, 46), os.path.join(out, "fuente.png"), 1)

    for r in range(6):
        guarda(V.pinta_pantalla(combate(rom, r)),
               os.path.join(out, "combate_%d.png" % (r + 1)))

    guarda(hoja_de_figuras(rom, 0x7086),
           os.path.join(out, "poses_jugador.png"), 2)
    for r in range(6):
        e207 = e207_del_rival(r)
        guarda(hoja_de_figuras(rom, rom.w(0x52C9 + 2 * (e207 & 3)), e207),
               os.path.join(out, "poses_rival_%d.png" % (r + 1)), 2)


def hoja_de_figuras(rom, tabla, e207=None, cuantas=19, cols=7, sep=2):
    """Las poses de un boxeador, cada una montada ENTERA: las casillas del
    cuerpo colocadas con sus ocho bytes de disposicion y, encima, los sprites
    de la cabeza y los guantes con las piezas que (0xE207) manda pintar. Sin
    los sprites la hoja miente: la mitad de los guantes no estan en las
    casillas, y lo que distingue a SANCHESS de RED WOLF es un sprite.

    Cada pose se monta en una VRAM limpia por el mismo camino que el
    cuadrilatero -la figura en la columna 4 y las filas 8 a 15, donde viven
    los boxeadores- y se recorta con margen, porque los sprites asoman por
    fuera del cuerpo: el registro mas alto de un rival cae 0x38 lineas por
    debajo de la figura y el mas ancho 0x30 pixeles a la derecha.
    """
    X0, Y0, ANCHO, ALTO = 16, 48, 104, 88
    cw, ch = ANCHO + sep, ALTO + sep
    filas = (cuantas + cols - 1) // cols
    fondo = (0x18, 0x18, 0x20)
    lienzo = [[fondo] * (cols * cw + sep) for _ in range(filas * ch + sep)]
    rival = e207 is not None
    for k in range(cuantas):
        v = V.Vram()
        figura(rom, v, tabla, k, 0x2980, e207)
        coloca(rom, v, tabla, k, 0x30, 4, rival)
        piezas_y_sprites(rom, v, tabla, k, 0x30, 4 * 8 + 24, 0x3B00, e207)
        px = V.pinta_pantalla(v, fondo)
        ox, oy = sep + (k % cols) * cw, sep + (k // cols) * ch
        for y in range(ALTO):
            lienzo[oy + y][ox:ox + ANCHO] = px[Y0 + y][X0:X0 + ANCHO]
    return lienzo


if __name__ == "__main__":
    main()
