# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`suena_el_cuadro`, 0x6A13, y `pide_un_sonido_aunque_sea_la_demo`, 0x6967, que le reparte las voces; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la pieza 0xA2 entera, 310 cuadros, dos veces;
- la pieza 0x19, sus primeros 400 cuadros de 2.291.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`pide_un_sonido_aunque_sea_la_demo` recibe el número en A; con los seis bits bajos elige las voces (por debajo de 7, una; del 7 al 0x12, dos; del 0x13 en adelante, tres) y el bit 7 distingue el formato de música del de efecto. Las voces ocupan catorce bytes desde 0xE311 y 0xE310 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten otras, de minutos de duración.

## Las músicas

**La pieza del 0x4289** (0xA2)

Lo pide `L_4289`; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_A2.mp3?v=c9f6491d"></audio>

**La pieza del 0x591A** (0xA8)

Lo pide `L_591A`; dura 5,4 s.

<audio controls preload="none" src="../audio/musica_A8.mp3?v=b77dd722"></audio>

**La pieza del 0x6FA4** (0x19)

Lo pide `L_6FA4`; dura 38,2 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_19.mp3?v=541590a8"></audio>

**Pista 0x12 de la tabla** (0x12)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 64,5 s y vuelve a empezar en el segundo 0,7.

<audio controls preload="none" src="../audio/musica_12.mp3?v=a8d9a959"></audio>

**Pista 0x15 de la tabla** (0x15)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 72,1 s y vuelve a empezar en el segundo 2,4.

<audio controls preload="none" src="../audio/musica_15.mp3?v=ce136884"></audio>

**Pista 0x17 de la tabla** (0x17)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 39,3 s y vuelve a empezar en el segundo 1,2.

<audio controls preload="none" src="../audio/musica_17.mp3?v=99019b2b"></audio>

**Pista 0xA3 de la tabla** (0xA3)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_A3.mp3?v=8dcb966f"></audio>

**Pista 0xA4 de la tabla** (0xA4)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_A4.mp3?v=9cd1ac88"></audio>

**Pista 0xA5 de la tabla** (0xA5)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,9 s.

<audio controls preload="none" src="../audio/musica_A5.mp3?v=7192a068"></audio>

**Pista 0xA6 de la tabla** (0xA6)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,4 s.

<audio controls preload="none" src="../audio/musica_A6.mp3?v=9147c0f1"></audio>

**Pista 0xA7 de la tabla** (0xA7)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,4 s.

<audio controls preload="none" src="../audio/musica_A7.mp3?v=5ef7bdf2"></audio>

**Pista 0xA9 de la tabla** (0xA9)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,4 s.

<audio controls preload="none" src="../audio/musica_A9.mp3?v=5dc7117f"></audio>

**Pista 0xAA de la tabla** (0xAA)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,4 s.

<audio controls preload="none" src="../audio/musica_AA.mp3?v=867ce508"></audio>
