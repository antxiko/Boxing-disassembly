# In the emulator

The pictures on this site are not captures: they are built by running the
cartridge's steps in Python. And to know whether that is right, looking at them
is not enough &mdash;they have to be **subtracted from the real VRAM**.

## How the dump works

```
make vram
```

It launches openMSX twice with two Tcl scripts and compares what comes out:

- `tools/omsx_vram.tcl` does not touch a key. The cartridge chains intro, title
  and **attract match** on its own, and the attract match is scene 2: there the
  left-hand boxer is driven by the machine and the right-hand one by the R
  register, so both of them play by themselves. A breakpoint on
  `monta_el_combate` (0x554B) writes the opponent due into (0xE207) **before it
  is read**, and the cartridge builds THAT bout with its own code. Nothing is
  faked: one byte of state is changed, exactly as a player reaching that
  opponent would.
- `tools/omsx_menu.tcl` goes separately because the menu needs a keypress: it
  presses SPACE once a second until 0x4543 builds it.

Each moment produces two files: the 16 KB of VRAM as they are and a `.txt` with
the state of the game, so it can be said **what** the comparison is against.

## What comes out

```
presentacion    colour 0  patterns 0  names 0   TOTAL 0
menu            colour 0  patterns 0  names 0   TOTAL 0
opponent 1      colour 0  patterns 0  names 0   TOTAL 0
  boxers        attributes 0  patterns 0  body tiles 0 (50 tiles)   TOTAL 0
  (with figures) colour 0  patterns 0  names 0   TOTAL 0
opponents 2..6  colour 0  patterns 0  names 0   TOTAL 0
  boxers        attributes 0  patterns 0  body tiles 0   TOTAL 0
---- 8 screens, 0 bytes different
```

## The boxers are compared on their own

The interrupt hook rebuilds the sprites every frame, so comparing the whole
sprite tables would only measure the delay of the dump. But at the moment of
the dump both boxers are in the action and the column the `.txt` records, so
`tools/coteja_vram.py` builds them with those &mdash;taking each one's starting
pattern from the dump itself, because they alternate with the frame
counter&mdash; and compares the **twelve sprite attributes**, the **32 pattern
bytes of every sprite on screen** and the **body tiles** the name table has in
rows 8 to 15. That is what tells the six opponents apart, and until it was
added the comparison was blind to it: the first version of this site said the
second round was the first three opponents with the colour swapped, and it
was not.

## What is NOT compared, and why

- **The rest of the sprite tables.** What the attributes do not point at is
  left over from earlier frames.
- **The tiles the scoreboard and the clock rewrite.** They are declared one by
  one in `tools/coteja_vram.py`, with the routine that writes them alongside.
- **The figure area, except on the first bout.** The first one starts with that
  area clean and there it is compared in full; on the following ones, whatever
  the new figure does not rewrite is left over from the previous opponent, and
  there is no way to build that without playing the whole match.

## Handles for poking around

You can start on whichever bout you like by writing (0xE207) before
`monta_el_combate` reads it, which is exactly what the script does. And
(0xE000) governs the scene: a 2 in there takes you to the attract match.
