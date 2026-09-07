#!/usr/bin/env python3
"""Los dos formatos con los que este cartucho mete cosas en la VRAM.

Ninguno de los dos lleva la longitud delante, asi que el final de cada bloque
no se puede poner a ojo: se saca RECORRIENDOLO con el mismo algoritmo que el
Z80. Eso es lo que da los limites de las directivas D del .notes.

  1. EL GUION COMPRIMIDO (lo lee 0x45E3, y 0x45DD si ademas trae la direccion
     de VRAM delante). Una tira de ordenes:

         nn        con nn & 0x7F = 0 y nn != 0  -> 0x80: cambia de sitio, y
                   detras vienen los dos bytes de la nueva direccion de VRAM
         0x00      se acabo
         nn        con el bit 7 a uno -> copia (nn & 0x7F) bytes tal cual
         nn        con el bit 7 a cero -> repite nn veces el byte siguiente

     El Z80 lo decide asi: `and 07Fh` deja la cuenta en C y el flag Z; luego
     `cp c` separa el literal (bit 7 puesto, A != C) de la repeticion.

  2. EL GUION POR FILAS (lo lee 0x539D, y el bucle de 0x53B3). La direccion de
     VRAM llega en HL, y el guion son codigos de casilla seguidos:

         0x00      se acabo
         0xFF      fila siguiente: HL += 0x20 y se vuelve a fijar la escritura
         nn        casilla nn + B, donde B es 0 casi siempre y 0x2A cuando
                   0x53AD lo cambia para resaltar

  3. EL GUION DE FIGURA (lo lee 0x529D). El mas corto de los cuatro, sin
     cambio de sitio: la direccion de VRAM ya viene fijada.

         nn        con nn & 0x7F = 0 -> se acabo
         nn        bit 7 puesto -> copia (nn & 0x7F) bytes tal cual
         nn        bit 7 a cero  -> repite nn veces el byte siguiente

  4. LA PIEZA DE SPRITE (la lee 0x54F1). Siempre escribe 0x20 bytes exactos,
     que son los cuatro cuartos de un sprite de 16x16, y lo unico comprimido
     son las carreras de ceros:

         nn (!=0)  el byte tal cual
         0x00 dd   dd ceros seguidos

     El Z80 lleva la cuenta en B empezando por 0x20, y por eso el final no hay
     que buscarlo: se para solo al escribir el byte 32.

  5. EL GUION DE ROTULOS (lo lee 0x407A, y 0x4076 con la mascara a cero para
     borrar lo mismo que el otro escribe). Empieza por la direccion de VRAM y
     sigue con codigos de casilla:

         0xFF      se acabo
         0xFE      cambia de sitio: detras van los dos bytes de la direccion

Uso:  formatos.py <rom> rle    <dir> [<dir> ...]
      formatos.py <rom> rotulo <dir> [<dir> ...]
      formatos.py <rom> filas  <dir> [<dir> ...]
      formatos.py <rom> figura <dir> [<dir> ...]
      formatos.py <rom> pieza  <dir> [<dir> ...]
"""
import sys

ORG = 0x4000


def rle(rom, ini, con_palabra=True):
    """Recorre un guion comprimido y devuelve (fin, bytes_escritos, tramos).

    `tramos` es la lista de (direccion_de_vram, cuantos) que el guion vuelca,
    que es lo que permite cotejarlo contra la VRAM de verdad.
    """
    p = ini - ORG
    tramos, vram, escritos = [], None, 0
    if con_palabra:
        vram = rom[p] | (rom[p + 1] << 8)
        p += 2
    cuenta = 0
    while True:
        if p >= len(rom):
            raise ValueError("el guion de 0x%04X se sale de la ROM" % ini)
        n = rom[p]
        p += 1
        bajos = n & 0x7F
        if bajos == 0:
            if n == 0:                      # 0x00: se acabo
                if cuenta:
                    tramos.append((vram, cuenta))
                return p + ORG, escritos, tramos
            # 0x80: cambia de sitio
            if cuenta:
                tramos.append((vram, cuenta))
            vram = rom[p] | (rom[p + 1] << 8)
            p += 2
            cuenta = 0
            continue
        if n & 0x80:                        # literal
            p += bajos
        else:                               # repeticion
            p += 1
        cuenta += bajos
        escritos += bajos


def rotulo(rom, ini):
    """Recorre un guion de rotulos y devuelve (fin, casillas, tramos)."""
    p = ini - ORG
    vram = rom[p] | (rom[p + 1] << 8)
    p += 2
    tramos, cuenta, casillas = [], 0, 0
    while True:
        if p >= len(rom):
            raise ValueError("el guion de 0x%04X se sale de la ROM" % ini)
        b = rom[p]
        p += 1
        if b == 0xFF:
            if cuenta:
                tramos.append((vram, cuenta))
            return p + ORG, casillas, tramos
        if b == 0xFE:
            if cuenta:
                tramos.append((vram, cuenta))
            vram = rom[p] | (rom[p + 1] << 8)
            p += 2
            cuenta = 0
            continue
        cuenta += 1
        casillas += 1


def filas(rom, ini):
    """Recorre un guion por filas y devuelve (fin, casillas, cuantas_filas)."""
    p = ini - ORG
    casillas, fils = 0, 1
    while True:
        if p >= len(rom):
            raise ValueError("el guion de 0x%04X se sale de la ROM" % ini)
        b = rom[p]
        p += 1
        if b == 0x00:
            return p + ORG, casillas, fils
        if b == 0xFF:
            fils += 1
            continue
        casillas += 1


def figura(rom, ini):
    """Recorre un guion de figura y devuelve (fin, bytes_escritos)."""
    p = ini - ORG
    escritos = 0
    while True:
        if p >= len(rom):
            raise ValueError("el guion de 0x%04X se sale de la ROM" % ini)
        n = rom[p]
        bajos = n & 0x7F
        p += 1
        if bajos == 0:
            return p + ORG, escritos
        p += bajos if (n & 0x80) else 1
        escritos += bajos


def pieza(rom, ini):
    """Recorre una pieza de sprite. Devuelve (fin, ceros) tras 32 bytes."""
    p = ini - ORG
    puestos, ceros = 0, 0
    while puestos < 0x20:
        if p >= len(rom):
            raise ValueError("la pieza de 0x%04X se sale de la ROM" % ini)
        b = rom[p]
        p += 1
        if b:
            puestos += 1
            continue
        d = rom[p]
        p += 1
        # El bucle de 0x5506 escribe D bytes y descuenta B otras tantas veces,
        # con un `inc b` de mas: por eso una carrera de D pone D ceros.
        puestos += d
        ceros += d
    return p + ORG, ceros


def main():
    rom = open(sys.argv[1], "rb").read()
    modo = sys.argv[2]
    for a in sys.argv[3:]:
        ini = int(a, 0)
        if modo == "rle":
            fin, n, tr = rle(rom, ini)
            que = "escribe %d bytes" % n
        elif modo == "pieza":
            fin, n = pieza(rom, ini)
            tr, que = [], "32 bytes de sprite, %d por carreras de ceros" % n
        elif modo == "figura":
            fin, n = figura(rom, ini)
            tr, que = [], "escribe %d bytes" % n
        elif modo == "filas":
            fin, n, f = filas(rom, ini)
            tr = [None] * f
            que = "pone %d casillas en %d filas" % (n, f)
        else:
            fin, n, tr = rotulo(rom, ini)
            que = "pone %d casillas" % n
        print("0x%04X..0x%04X  %4d bytes  %s%s"
              % (ini, fin, fin - ini, que,
                 "" if modo in ("filas", "figura", "pieza") else
                 " en %d tramos: %s" % (len(tr), " ".join(
                     "%s+%d" % ("%04X" % v if v is not None else "-", c)
                     for v, c in tr))))


if __name__ == "__main__":
    main()
