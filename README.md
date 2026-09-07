# Konami's Boxing (Konami, MSX1) — a commented disassembly

*(También [en castellano](README.es.md).)* ·
**[Read it on the web](https://antxiko.github.io/Boxing-disassembly/)**

A complete, commented disassembly of Konami's **Konami's Boxing** for the MSX
(RC-736, 32 KB, 1985). Every one of the 32,768 bytes is accounted for, and the
listing reassembles into the ROM **byte for byte**.

    explained          32,768 of 32,768   100 %
    comment density    1,966 of 3,740     52.6 %
    routines below 10 %      0 of 475
    call targets unnamed     0
    tests                   42, green
    VRAM comparison     8 screens, 0 bytes different
    reassembly         same sha256 as the cartridge

## What is here

    src/boxing.asm       the commented listing, generated
    src/boxing.notes     the comments and the data blocks, with their measure
    src/boxing.entries   the entry points that cannot be deduced statically
    tools/               the tools: trace, listing, pictures, VRAM check
    tests/               42 checks that do not need the cartridge
    docs/                the bilingual website

## The cartridge is not here

`boxing.rom` is not distributed. Put your own copy in the root; it is exactly
32,768 bytes and

    sha256  43b23739d63b636922f0a98c33322bfdeafbefeccc01dd74fb0a45107581d0e6

## Reproducing it

    make comprueba     # checks your ROM is the same one
    make               # listing, reassembly, sanity checks and tests
    make imagenes      # draws the fourteen plates from the ROM
    make vram          # dumps openMSX's VRAM and compares byte for byte

## Not one capture

Every picture on the website is **drawn from the bytes of the ROM**, by running
in Python the same decompressors, figure builders and sprite painters the Z80
runs. And that is not an opinion: `make vram` subtracts them from the VRAM
openMSX really holds, and the eight screens dumped —the intro, the title and
the six rings— come out with **zero** differences in colour, patterns and the
768 tiles of the screen.

## What turned up

- **Six opponents and only three sets of figures.** The three of the second
  round are the first three with the colour swapped.
- **The scorecard is kept upside down**: it adds up faults and finishes with
  `10 - faults`, the ten-point must system of real boxing.
- **Throwing a punch tires you**, and the punch only lands on the seventh and
  eighth frame after it is thrown.
- **The sixth opponent is called MOAI Jr.**, not "MOAI JX": tile 0x58 is a
  glyph with "r" and the full stop joined.
- Konami's **hidden mark** at 0xBFF0 (RC-736), and a **second header** at
  0x4010 for the *Konami Game Master*.

The full list, with its measurements, is in
[FINDINGS](https://antxiko.github.io/Boxing-disassembly/FINDINGS.html).

## Credit where it is due

The format of the hidden Konami mark was worked out by **Manuel Pazos**
(@ManuelPazosMSX). `tools/marca_konami.py` only reads it.

## Licence

The tools, comments and documentation are MIT (see `LICENSE`). The game itself
is not covered: see `LEGAL-NOTICE.md`.
