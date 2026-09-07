# Getting started

This repository does not ship the cartridge. It ships the **commented
listing** and the tools that generate it, check it and draw its screens.

## What you need

- `make`, `python3` and **pasmo** to reassemble
- **z80dasm** only if you want to trace again from scratch
- **openMSX** for the VRAM comparison (optional)
- the cartridge, `boxing.rom`, exactly 32,768 bytes, with this sha256:

```
43b23739d63b636922f0a98c33322bfdeafbefeccc01dd74fb0a45107581d0e6
```

## The four steps

```
make comprueba   # that the cartridge is what it claims to be
make listado     # builds src/boxing.asm from the trace and the notes
make verify      # reassembles it and compares the sha256 with the original
make all         # all of the above, plus the checks and the 42 tests
```

`make verify` is what decides whether the disassembly is trustworthy: if the
listing does not give back the ROM **byte for byte**, nothing it says is worth
anything.

## What `make sanity` checks

Reassembling does not catch everything. A block of data read as code comes out
the same, because the bytes do not change; only what we say about them does.
Hence four more checks:

| check | what it watches |
|---|---|
| `check_trace.py` | that the trace never wanders into declared data |
| `check_datos_como_codigo.py` | that none of the 416 data areas comes out as code |
| `check_entradas.py` | that no entry point falls inside a data area |
| `presupuesto.py` | that **not one byte** of the cartridge is left unassigned |

## The pictures

```
make imagenes    # the fourteen plates in docs/img, drawn from the ROM
make vram        # openMSX dumps its VRAM and it is compared byte for byte
```

Not one picture on this site is a capture. They are built by running in Python
the same steps the cartridge takes, and the comparison against the emulator's
VRAM comes out with **zero** differences on all eight screens.
