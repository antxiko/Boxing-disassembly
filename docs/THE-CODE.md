# The code

The cartridge shares its frame with the other Konami titles of the period: 561
bytes in common with *Knightmare* (RC-739) and 562 with *The Goonies*
(RC-734), measured with `tools/comun_normalizado.py`. The dispatcher even falls
at the **same address** as in Knightmare, 0x406C.

## The interrupt hook

0x403D is the whole program. Every frame:

1. it reads the VDP status, which is what lowers the interrupt request;
2. the **sound**, always, even if the previous frame has not finished;
3. a **latch** in (0xE005): if the previous frame is still inside, it does not
   re-enter;
4. the controls of both boxers, one with HL' = 0xE300 and the other with
   HL' = 0xE009;
5. `avanza_el_reloj` (0x40DB), which counts down the three timers and
   dispatches the scene;
6. and on the way out, if the VDP says there was a collision, another pass of
   sound.

## The eleven scenes

(0xE000) says which one we are in and (0xE001) the step within it. The table at
0x411C hands out, and nearly all of them start with chained `djnz`: the step
arrives in B and each `djnz` eats one.

Scene **2** is the match. Its per-frame loop is 0x4338, and in thirteen calls
it does the whole game: the bell, the sprites, the two boxers, the referee, the
punches that land, the damage, the bars and the round.

## The two boxers

Each one has an **eleven-byte** block, and the trick is that there is only
**one** work area: 0x46F9 copies whichever one is due to 0xE221, does
everything there and puts it back. That way the code carries no player index.

| block | who | starting column |
|---|---|---|
| 0xE232 | the **right-hand** one | 22 |
| 0xE255 | the **left-hand** one | 2 |

(0xE22F) alternates between 0 and 1 on every call and is what says which is
which. And each one comes in knowing **the other's action**, which is the only
thing it knows about its opponent.

## The actions

(0xE228) says what he is doing. The table at 0x4C72 turns the five control bits
into one of them:

| pressed | action | |
|---|---|---|
| up | 3 | stand up |
| down | 1 | duck |
| left / right | 9 / 0x0A | walk |
| punch | 8 | |
| punch + up | 5 | |
| punch + down | 6 | |
| punch + left / right | 4 / 7 | |

The other 23 combinations give zero. When a punch starts, 0x48D6 adds four to
it: actions 9 to 0x0C mean "throwing punch 5 to 8". And 0x0D to 0x10 are wait,
take it, back off and **go down**.

## The punch that lands

`mira_si_entra_el_golpe` (0x4C92) settles it once per boxer, and the order is
decided by the parity of (0xE23E)+(0xE261). The two index registers are the
split: **IY** to the block of the one throwing and **IX** to the action of the
one receiving. Hence the punch lands with a `ld (ix+000h),00eh`, which is the
action of taking it, and when the threshold is passed (ix+0) becomes 0x10,
which is going down.

Damage is **two bytes**: the level, 0 to 8, and what has piled up inside the
level. Each level's threshold comes from 0x5445, and it **falls**: the more
battered you are, the sooner you go down.

## The drawing

`pinta_una_figura` (0x4F66) redraws a boxer's body by **redefining tiles** the
screen already has in place. Four pointers per figure: two to the patterns and
two to the colour, which sits at the same offset with bit 13 cleared (the
`res 5,a` at 0x4F81).

Each boxer has **two** sets of tiles and they take turns frame by frame: 0x30
and 0x80 for the player, 0x58 and 0xA8 for the opponent. While one is on
screen, the other is being built.

And the head and the gloves are not tiles: they are 16x16 **sprites** that
`monta_los_sprites_de_una_figura` (0x5178) writes in one go, four bytes each,
with the spare ones parked on row 0xCF.

## The sound

Three voices with a fourteen-byte block each from 0xE311. The sound number acts
as **state and priority** at the same time: a new one only gets in if its
number is not lower than the one already playing. And how many voices it takes
depends on the number: below 7 only the third, from 7 to 0x12 two, and from
0x13 up all three.
