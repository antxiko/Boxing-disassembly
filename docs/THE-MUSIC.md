# The music

Everything you hear here comes from running the cartridge's own sound engine (`suena_el_cuadro`, 0x6A13, and `pide_un_sonido_aunque_sea_la_demo`, 0x6967, which hands it the voices; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- tune 0xA2, whole, 310 frames, twice;
- tune 0x19, its first 400 frames of 2,291.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`pide_un_sonido_aunque_sea_la_demo` takes the number in A; the low six bits pick the voices (below 7, one; 7 to 0x12, two; from 0x13 up, three) and bit 7 tells the music format from the effect format. The voices take fourteen bytes from 0xE311 and 0xE310 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; others, minutes long, are left out.

## The tunes

**The tune at 0x4289** (0xA2)

Asked for by `L_4289`; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_A2.mp3?v=c9f6491d"></audio>

**The tune at 0x591A** (0xA8)

Asked for by `L_591A`; lasts 5.4 s.

<audio controls preload="none" src="audio/musica_A8.mp3?v=b77dd722"></audio>

**The tune at 0x6FA4** (0x19)

Asked for by `L_6FA4`; lasts 38.2 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_19.mp3?v=541590a8"></audio>

**Table track 0x12** (0x12)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 64.5 s and starts again at second 0.7.

<audio controls preload="none" src="audio/musica_12.mp3?v=a8d9a959"></audio>

**Table track 0x15** (0x15)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 72.1 s and starts again at second 2.4.

<audio controls preload="none" src="audio/musica_15.mp3?v=ce136884"></audio>

**Table track 0x17** (0x17)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 39.3 s and starts again at second 1.2.

<audio controls preload="none" src="audio/musica_17.mp3?v=99019b2b"></audio>

**Table track 0xA3** (0xA3)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_A3.mp3?v=8dcb966f"></audio>

**Table track 0xA4** (0xA4)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_A4.mp3?v=9cd1ac88"></audio>

**Table track 0xA5** (0xA5)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.9 s.

<audio controls preload="none" src="audio/musica_A5.mp3?v=7192a068"></audio>

**Table track 0xA6** (0xA6)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.4 s.

<audio controls preload="none" src="audio/musica_A6.mp3?v=9147c0f1"></audio>

**Table track 0xA7** (0xA7)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.4 s.

<audio controls preload="none" src="audio/musica_A7.mp3?v=5ef7bdf2"></audio>

**Table track 0xA9** (0xA9)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.4 s.

<audio controls preload="none" src="audio/musica_A9.mp3?v=5dc7117f"></audio>

**Table track 0xAA** (0xAA)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.4 s.

<audio controls preload="none" src="audio/musica_AA.mp3?v=867ce508"></audio>
