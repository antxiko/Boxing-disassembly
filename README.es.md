# Konami's Boxing (Konami, MSX1) — desensamblado comentado

*(Also [in English](README.md).)* ·
**[Leerlo en la web](https://antxiko.github.io/Boxing-disassembly/es/)**

Desensamblado completo y comentado de **Konami's Boxing**, de Konami para MSX
(RC-736, 32 KB, 1985). Los 32.768 bytes estan explicados, y el listado vuelve a
dar la ROM **byte a byte**.

    explicado          32.768 de 32.768   100 %
    densidad           1.966 de 3.740     52,6 %
    rutinas bajo 10 %        0 de 475
    destinos de call sin nombre  0
    tests                   42, en verde
    cotejo de VRAM      8 pantallas, 0 bytes distintos
    reensamblado       el mismo sha256 que el cartucho

## Que hay aqui

    src/boxing.asm       el listado comentado, generado
    src/boxing.notes     los comentarios y los bloques de datos, con su medida
    src/boxing.entries   los puntos de entrada que no se deducen solos
    tools/               las herramientas: trazado, listado, dibujos, cotejo
    tests/               42 comprobaciones que no necesitan el cartucho
    docs/                la web bilingue

## El cartucho no esta aqui

`boxing.rom` no se distribuye. Pon tu copia en la raiz; son exactamente 32.768
bytes y

    sha256  43b23739d63b636922f0a98c33322bfdeafbefeccc01dd74fb0a45107581d0e6

## Como reproducirlo

    make comprueba     # comprueba que tu ROM es la misma
    make               # listado, reensamblado, comprobaciones y tests
    make imagenes      # dibuja las catorce laminas desde la ROM
    make vram          # vuelca la VRAM de openMSX y compara byte a byte

## Ni una captura

Todas las imagenes de la web estan **dibujadas desde los bytes de la ROM**,
ejecutando en Python los mismos descompresores, montadores de figuras y
pintores de sprites que corre el Z80. Y eso no es una opinion: `make vram` las
resta de la VRAM que openMSX tiene de verdad, y las ocho pantallas volcadas
—la presentacion, el titulo y los seis cuadrilateros— dan **cero** diferencias
en color, patrones y las 768 casillas de la pantalla.

## Lo que aparecio

- **Seis rivales y solo tres juegos de figuras.** Los tres de la segunda vuelta
  son los tres primeros con el color cambiado.
- **El marcador se lleva al reves**: va sumando faltas y al final hace
  `10 - faltas`, que es el sistema de los diez puntos del boxeo de verdad.
- **Pegar cansa**, y el golpe solo toca en el septimo y el octavo cuadro desde
  que sale.
- **El sexto rival se llama MOAI Jr.**, no "MOAI JX": la casilla 0x58 es un
  glifo con la "r" y el punto juntos.
- La **marca escondida** de Konami en 0xBFF0 (RC-736), y una **segunda
  cabecera** en 0x4010 para el *Konami Game Master*.

La lista entera, con sus medidas, esta en
[HALLAZGOS](https://antxiko.github.io/Boxing-disassembly/es/HALLAZGOS.html).

## A quien hay que citar

El formato de la marca escondida de Konami lo descubrio **Manuel Pazos**
(@ManuelPazosMSX). `tools/marca_konami.py` solo lo lee.

## Licencia

Las herramientas, los comentarios y la documentacion son MIT (ver `LICENSE`).
El juego no queda cubierto: ver `AVISO-LEGAL.md`.
