# Empezar

Este repositorio no trae el cartucho. Trae el **listado comentado** y las
herramientas que lo generan, lo comprueban y dibujan sus pantallas.

## Lo que hace falta

- `make`, `python3` y **pasmo** para reensamblar
- **z80dasm** solo si se quiere volver a trazar desde cero
- **openMSX** para el cotejo contra la VRAM (opcional)
- el cartucho, `boxing.rom`, 32.768 bytes exactos, con este sha256:

```
43b23739d63b636922f0a98c33322bfdeafbefeccc01dd74fb0a45107581d0e6
```

## Los cuatro pasos

```
make comprueba   # que el cartucho es el que dice ser
make listado     # genera src/boxing.asm desde el trazado y las notas
make verify      # lo reensambla y compara el sha256 con el original
make all         # todo lo anterior, mas las comprobaciones y los 42 tests
```

`make verify` es el que decide si el desensamblado es fiable: si el listado no
devuelve la ROM **byte a byte**, no vale nada de lo que diga.

## Lo que comprueba `make sanity`

El reensamblado no lo caza todo. Un bloque de datos leido como codigo sale
igual, porque los bytes no cambian; lo unico que cambia es lo que decimos de
el. Por eso hay cuatro comprobaciones mas:

| comprobacion | que vigila |
|---|---|
| `check_trace.py` | que el trazado no se cuele en zonas declaradas de datos |
| `check_datos_como_codigo.py` | que ninguna de las 416 zonas de datos salga como codigo |
| `check_entradas.py` | que ningun punto de entrada caiga dentro de una zona de datos |
| `presupuesto.py` | que no quede **ni un byte** del cartucho sin asignar |

## Las imagenes

```
make imagenes    # las catorce laminas de docs/img, dibujadas desde la ROM
make vram        # openMSX vuelca su VRAM y se compara byte a byte
```

Ninguna imagen de esta web es una captura. Se montan ejecutando en Python los
mismos pasos que hace el cartucho, y el cotejo contra la VRAM del emulador da
**cero** diferencias en las ocho pantallas.
