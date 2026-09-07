# Open questions

What is not known. It goes here and it is not glossed over.

## The machine's scripts

`saca_el_golpe_del_guion` (0x4C02) builds a pointer in (0xE252) out of four
groups of eight triples at 0x6858, indexing it with `(0xE207) & 3` times
twenty-four and `(0xE254) & 7` times three. The **three steps** of each script
are read, and so is the fact that on odd steps it tosses a coin between the
byte before and the byte after (0x4C40). What is **not** measured is whether
the eight triples of each group make up a recognisable repertoire of
combinations &mdash;a one-two, a hook&mdash; or are just a list.

## (0xE21A) and (0xE218), from level 5 on

Each damage level's threshold comes from 0x5445 &mdash;0x1A, 0x14 and 0x10&mdash;
for levels 5, 6 and 7, and it is 0x10 below level 5. That level 5 has the
**highest** threshold of the three breaks the monotonic run and no explanation
has been found inside the code. It may be deliberate &mdash;a breather at the
halfway point&mdash; or it may be a value put in by eye.

## The second button

`lee_el_teclado` (0x44A8) takes bit 6 of keyboard row 7 &mdash;which is
**SELECT**&mdash; and puts it into bit 5, which 0x4467 folds into bit 4, the
punch. It works as a second button, but it has not been checked in the emulator
whether the game does anything different with it or it is only convenience.

## The 32 bytes missing from the figure archives

`tools/archivo_de_figuras.py` explains **20,306 of the 20,338 bytes** of
0x707E..0xBFF0 by walking the four tables and their 76 figures. **32 bytes in
four gaps** are left. They are declared as data and nobody reads them along any
traced path, but what they are is not known.

## Three figures that fit both counts

A figure's piece count is N or N+1 &mdash;0x5005 does an `inc b` depending on
bit 1 of the frame counter&mdash; and it is settled by seeing which of the two
leaves the pieces chained without a gap. On **three** figures (the three of
archive 3 at 0x9653) both fit, so there the choice is whichever the tool tries
first and not a measurement.
