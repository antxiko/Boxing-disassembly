# Findings

What turned up when we took it apart. Each one with its measurement.

## Six opponents, three archives, and a hidden piece for the second round

There are six names, in a table of six pointers (0x5661). The **figures** come
from another table, the one at 0x52C9, and that one has **three** words:
0x825C, 0x9670 and 0xABB4, the tables of figure archives 2, 3 and 4. 0x4F8D
indexes it with `(0xE207) & 3`, and a fourth word would fall at 0x52CF, which
is already code. It is never read: 0x423B forces the jump to the next group of
sixteen as soon as the index reaches 2.

And yet the six look different, and SANCHESS is not RED WOLF in another
colour. Every figure in the three opponent archives carries **one piece more**
than its header declares: the byte at +8 says N, but 0x5005 does an `inc b`
on the opponent's turn &mdash;bit 1 of the frame counter&mdash; and walks N+1
records and N+1 pointers. The first one is the piece of the **second round**,
and 0x5034 (for the patterns) and 0x5187 (for the sprite attributes) decide
what to do with it by looking at (0xE207):

| (0xE207) | opponent | what 0x5034 does with the first piece |
|---|---|---|
| bit 4 clear | RED WOLF, M.B.ALLI, MOAI KING | skips it (0x5048) |
| bit 4 set, bit 0 clear | SANCHESS, MOAI Jr. | paints it **instead of** the second (`ld a,002h`, 0x5040) |
| bit 4 and bit 0 set | CHINA KHAN | paints **all** of them (`inc b`, 0x5045) |

So SANCHESS wears RED WOLF's body with **another head**: the hidden piece of
archive 2 (0x9558) is the same face with the hair down to the neck, where
0x856E keeps it short. CHINA KHAN is M.B.ALLI **plus** a black sprite (0xAB2E,
colour 1): the pigtail hanging from his head. And MOAI Jr. swaps MOAI KING's
empty sprite (0xBF7B, colour 0) for seven black pixels on the face (0xBF7D),
and on top of that changes colour: 0x526F and 0x51BE turn colour 4 into 0x0C
&mdash;dark blue into dark green&mdash; only when `(0xE207) & 3` is 2 and bit
4 is set. The moai is the only one that changes colour.

None of this is a reading of the code alone. The VRAM of the six rings, dumped
from openMSX with each opponent forced into (0xE207), comes out with **zero
differences** in the twelve sprite attributes, in the pattern bytes of every
sprite on screen and in the body tiles of both boxers
([In the emulator](IN-THE-EMULATOR.html)).

![RED WOLF](img/poses_rival_1.png)

![SANCHESS: the same nineteen poses, with the hair down to the neck](img/poses_rival_4.png)

## Throwing a punch tires you

When a punch ends, `acaba_el_golpe` (0x49BC) adds to **whoever threw it** what
the table at 0x6854 says, and the result goes onto his own damage:

| punch | hurts the other (0x6850) | tires the thrower (0x6854) |
|---|---|---|
| 5 | 12 | 3 |
| 6 | 10 | 2 |
| 7 | 9 | 1 |
| 8 | 2 | 1 |

Both tables run in the **same order**: the punch that hurts most is also the
one that tires most. And above level 7 it stops rising: `cp 007h` at 0x49E4.

## The punch only lands on the seventh and eighth frame

0x49FB loads **0xC0** into (0xE24C) or (0xE24D), and `pega_el_de_la_derecha`
(0x4CCF) spends it with one `srl` per frame, bailing out with `ret nc` while
there is no carry. Out of 0xC0, carry only comes on the seventh and eighth
turn. Outside that window the punch cannot land.

## The scorecard is kept upside down

(0xE21E) and (0xE21F) are the judges' cards, and they do not add up points:
they add up **faults**.

- one if a boxer carries **three levels or more** of damage than the other;
- one to whoever landed fewer punches;
- and twice whatever (0xE23E) or (0xE261) says.

At the end, 0x4ECD does `10 - faults` on both and then **raises them together**
until one reaches ten. It is the ten-point must system of real boxing.

## The machine plays the left-hand boxer

With a single player, the left-hand boxer is driven by `decide_la_maquina`
(0x4A6B) and the human is the one on the right, the one wired to port 1 and the
cursor keys. Three independent things say so:

1. when they are placed (0x49FE), the one at 0xE232 gets column 22 and the one
   at 0xE255 column 2;
2. when walking, the one at 0xE255 closes in by **adding** and the one at
   0xE232 by **subtracting**, and the column limits are 22 above for one and 2
   below for the other;
3. the machine closes in **walking right** (0x4A83) and backs off to the left
   (0x4B39), which is what the left-hand corner calls for.

In scene 2 &mdash;the attract match&mdash; the right-hand boxer is driven by
the Z80's **R** register (0x4836): both of them play on their own.

The machine returns the action in B with a bonus number in the high nibble, and
that number is added to (0xE254) **while it walks**. (0xE254) is what later
picks the punch script at 0x4C1C: the more it walks, the more what it is about
to do changes.

## The eight bytes nobody was reading

A figure's header is `17 + 5N` long. Of that, the **eight bytes** 0x500C skips
with a `ld a,008h` &mdash;the ones at `figure + 9 + 3N`&mdash; are the
**layout**: one per row, the high nibble saying how far right to shift and the
low one how many tiles run together. From 8 upwards, that row is not drawn.

With them the figure places itself, and the proof is not that it looks right:
the name table that comes out matches the emulator's **byte for byte**.

## The sixth opponent is called MOAI Jr.

Tile 0x58 is not the ASCII X. Drawing the font shows it is a glyph with the
**"r" and the full stop joined**, so the name `04 4D 4F 41 49 51 4A 58` reads
**MOAI&middot;Jr.** &mdash;MOAI&middot;KING's son, with whom he shares figure
archive 4, which is a moai.

![The font](img/fuente.png)

## The backdrop is not the one in the boot table

R7 = 0xE4 comes from the eight registers at 0x4429, and it says the border is
blue. But `monta_una_columna_del_fondo` (0x439E) writes **0xE1** into R7 on
every call, and from the intro onwards the backdrop is **black**. It showed up
against the emulator: building the screen with the blue from the table leaves
it a different colour.

## Code nobody calls

Three stretches that are valid instructions, fit between the routines either
side of them, and that **no `call`, no `jp` and no word of any table** reaches
&mdash;checked by searching for the two bytes across the whole ROM:

- **0x4038**, which leaves the VDP data port in C, the same as the tail of
  `prepara_la_escritura`;
- **0x45CA**, a sibling of `descomprime_en_tres_bancos` that uses
  `vuelca_en_la_vram` instead of the decompressor;
- **0x54EC**, an alternative entry to the piece painter.

And one more that does run and does nothing: 0x470D writes to 0x4F84, which is
**ROM**.
