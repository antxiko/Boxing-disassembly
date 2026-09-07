# The cartridge

32 KB on pages 1 and 2, from 0x4000 to 0xBFFF. The split, measured:

| what | bytes | of the total |
|---|---|---|
| traced code | 6,932 | 21.15% |
| identified data | 25,836 | 78.85% |
| **unexplained** | **0** | **0.00%** |

## The TWO headers

At 0x4000 sits the ordinary MSX header: `"AB"`, the INIT address (**0x4091**)
and twelve zeros. STATEMENT, DEVICE and TEXT go unused.

At **0x4010** there is a second one: `"AB"` followed by `07 36`. It belongs to
the *Konami Game Master*, the cheat cartridge that plugs into the other slot
and looks for this signature to know which game it has in front of it. With
this one, **eight** cartridges in the series are known to carry it.

## The hidden mark

At 0xBFF0, behind the 0xFF filler, come thirteen bytes of katakana
**backwards**, the length, the catalogue number in BCD and 0xAA:

```
RC-736   コナミのボクシング
```

The format was worked out by **Manuel Pazos** (@ManuelPazosMSX).
`tools/marca_konami.py` only reads it.

## INIT and the hook

INIT (0x4091) does five things and stops:

1. RSLREG and EXPTBL to find out which slot it is in, and **ENASLT** to leave
   the whole cartridge visible at 0x4000..0xBFFF;
2. interrupt mode 1 and a `jp` to the 0x403D hook in **H.KEYI** (0xFD9A);
3. the stack at 0xE7FF, just below the variables;
4. 0x7EF bytes from 0xE000 zeroed;
5. the PSG silenced, all 16 KB of VRAM zeroed and the eight VDP registers set.

And then a `jr $` at 0x40D9. **The whole game happens inside the interrupt.**

## VRAM, the other way round

The eight bytes at 0x4429 are `02 E2 0E 7F 07 76 03 E4`. R3 = 0x7F and
R4 = 0x07 put the **colours below** the patterns:

```
colour             0x0000..0x17FF   three banks of 0x800
sprite patterns    0x1800..0x1FFF
patterns           0x2000..0x37FF   three banks of 0x800
names              0x3800..0x3AFF
sprite attributes  0x3B00..0x3B7F
```

R7 = 0xE4 says the border is blue... but it does not last:
`monta_una_columna_del_fondo` (0x439E) rewrites it to **0xE1** on every call,
and from the intro onwards the backdrop is **black**.

And a trap you pay for once: the cartridge writes addresses like 0x7800 or
0x6008. SETWRT only looks at **fourteen bits**, so 0x7800 is 0x3800 and 0x6008
is 0x2008.

## The controls

`lee_el_mando` (0x443C) reads **one** joystick through the PSG, and bit 7 of
(0xE002) flips on every call between port 1 (0x8F) and port 2 (0xCF). Since the
hook calls it twice a frame, the bit returns to where it was on its own.

The keyboard uses the same bit layout, and each boxer has his own set:

| | up | down | left | right | punch |
|---|---|---|---|---|---|
| one | cursor up | cursor down | cursor left | cursor right | SPACE |
| other | E | C | S | F | SHIFT |

The second set is the diamond around **D**. And there is a second button: bit 6
of keyboard row 7, which is SELECT.
