#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `pide_un_sonido_aunque_sea_la_demo` (0x6967, A = numero;
`pide_un_sonido`, 0x695A, no suena en la escena 2, la demostracion) y corre
`suena_el_cuadro` (0x6A13), que la interrupcion llama cada cuadro. Tres voces
de 14 bytes desde 0xE311; la copia del registro 7 del PSG, en 0xE310.
Uso:  musica.py registros 0xA2 [cuadros] | mp3 0xA2 f.mp3 | todas docs/audio
      musica.py barrido 0x00 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0xA2, "La pieza del 0x4289", "The tune at 0x4289", "`L_4289`"),
    P(0xA8, "La pieza del 0x591A", "The tune at 0x591A", "`L_591A`"),
    P(0x19, "La pieza del 0x6FA4", "The tune at 0x6FA4", "`L_6FA4`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x12, 0x15, 0x17, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA9, 0xAA)]

PAGINA = motor_musica.pagina_basica(
    "`suena_el_cuadro`, 0x6A13, y `pide_un_sonido_aunque_sea_la_demo`, "
    "0x6967, que le reparte las voces; lo llama la interrupción",
    "`suena_el_cuadro`, 0x6A13, and `pide_un_sonido_aunque_sea_la_demo`, "
    "0x6967, which hands it the voices; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la pieza 0xA2 entera, 310 cuadros, dos veces",
      "tune 0xA2, whole, 310 frames, twice"),
     ("la pieza 0x19, sus primeros 400 cuadros de 2.291",
      "tune 0x19, its first 400 frames of 2,291")],
    [("Cómo se pide una pieza",
      "`pide_un_sonido_aunque_sea_la_demo` recibe el número en A; con los "
      "seis bits bajos elige las voces (por debajo de 7, una; del 7 al 0x12, "
      "dos; del 0x13 en adelante, tres) y el bit 7 distingue el formato de "
      "música del de efecto. Las voces ocupan catorce bytes desde 0xE311 y "
      "0xE310 guarda la copia del mezclador del PSG, que el arranque deja "
      "en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero "
      "ninguna rutina las pide con un `ld a`; se omiten otras, de minutos "
      "de duración.",
      "How a piece is asked for",
      "`pide_un_sonido_aunque_sea_la_demo` takes the number in A; the low "
      "six bits pick the voices (below 7, one; 7 to 0x12, two; from 0x13 up, "
      "three) and bit 7 tells the music format from the effect format. The "
      "voices take fourteen bytes from 0xE311 and 0xE310 holds the copy of "
      "the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in "
      "the table» are in the track table but no routine asks for them with "
      "an `ld a`; others, minutes long, are left out.")])

CFG = dict(rom="boxing.rom", org=0x4000, frame=0x6A13, pide=0x6967,
           ram=(0xE310, 0xE33C), ram0=[(0xE310, 0xB8)],
           excluye=[0xE31A, 0xE328, 0xE336], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0xA2, 310, None), (0x19, 2291, 1)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
