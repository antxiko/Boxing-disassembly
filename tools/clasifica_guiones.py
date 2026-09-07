#!/usr/bin/env python3
"""Empareja cada `ld de,NNNN` con la rutina que se lo lleva justo despues.

Un bloque de datos no se identifica por su aspecto sino por quien lo lee. Aqui
se recorren los tramos de CODIGO del trazado buscando `ld de,NNNN` (0x11) y
`ld hl,NNNN` (0x21), y se mira si en los bytes siguientes -antes de que el
registro vuelva a cambiar- hay un `call`/`jp` a una de las rutinas que comen
guiones. Si lo hay, el bloque queda clasificado, y su longitud sale de
RECORRERLO con tools/formatos.py, no de mirar hasta donde llegan los bytes.

Se trabaja sobre el binario y no sobre el listado a proposito: en cuanto el
.notes declara un bloque, mkasm.py pone su etiqueta en lugar de la constante y
el listado deja de servir para esto.

OJO con la palabra de VRAM: solo 0x45DD la lee del principio del guion. 0x45BA
y 0x45E3 la reciben ya en HL, y contarsela descuadra los bytes escritos.

Uso: clasifica_guiones.py <rom> <traza.json>
"""
import json
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0] if "/" in __file__ else ".")
from formatos import rle, rotulo, filas                # noqa: E402

ORG = 0x4000

# Las rutinas que se comen un guion, y con que formato.
LECTORES = {
    0x407A: ("rotulo", "guion de rotulos, escrito"),
    0x4076: ("rotulo", "guion de rotulos, borrado (mascara 0x00)"),
    0x45DD: ("rle+palabra", "comprimido, con la direccion de VRAM delante"),
    0x45BA: ("rle", "comprimido, volcado en los TRES bancos"),
    0x45E3: ("rle", "comprimido, con la VRAM ya fijada en HL"),
    0x539D: ("filas", "por filas: 0xFF baja una, 0x00 acaba"),
}
CALLS = {0xCD, 0xC3, 0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC,
         0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}


def main():
    rom = open(sys.argv[1], "rb").read()
    bloques = json.load(open(sys.argv[2], encoding="utf-8"))["blocks"]
    hallazgos = {}
    for tipo, ini, fin in bloques:
        if tipo != "c":
            continue
        de = None
        i = ini
        while i < fin - 2:
            op = rom[i - ORG]
            if op == 0x11:                      # ld de,NNNN
                de = (rom[i + 1 - ORG] | (rom[i + 2 - ORG] << 8), i)
                i += 3
                continue
            if op in CALLS:
                dest = rom[i + 1 - ORG] | (rom[i + 2 - ORG] << 8)
                if dest in LECTORES and de:
                    hallazgos.setdefault((de[0], LECTORES[dest][0]),
                                         set()).add(de[1])
                    de = None
                i += 3
                continue
            i += 1
    for (a, modo), quienes in sorted(hallazgos.items()):
        try:
            if modo.startswith("rle"):
                fin, n, tr = rle(rom, a, con_palabra=modo.endswith("palabra"))
                que = "%4d escritos, %d tramos" % (n, len(tr))
            elif modo == "filas":
                fin, n, f = filas(rom, a)
                que = "%4d casillas en %d filas" % (n, f)
            else:
                fin, n, tr = rotulo(rom, a)
                que = "%4d casillas, %d tramos" % (n, len(tr))
        except ValueError as e:
            print("0x%04X  %-11s  NO CUADRA: %s" % (a, modo, e))
            continue
        print("0x%04X..0x%04X  %4d B  %-11s  %-22s  <- %s"
              % (a, fin, fin - a, modo, que,
                 " ".join("%04X" % q for q in sorted(quienes))))


if __name__ == "__main__":
    main()
