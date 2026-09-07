# El cartucho

32 KB en las paginas 1 y 2, de 0x4000 a 0xBFFF. El reparto, medido:

| que | bytes | del total |
|---|---|---|
| codigo trazado | 6.932 | 21,15 % |
| datos identificados | 25.836 | 78,85 % |
| **sin explicar** | **0** | **0,00 %** |

## Las DOS cabeceras

En 0x4000 esta la cabecera normal del MSX: `"AB"`, la direccion de INIT
(**0x4091**) y doce ceros. STATEMENT, DEVICE y TEXT no se usan.

En **0x4010** hay una segunda: `"AB"` seguido de `07 36`. Es la del *Konami
Game Master*, el cartucho de trucos que se pincha en la otra ranura y busca
esta firma para saber que juego tiene delante. Con este son **ocho** los
cartuchos de la serie a los que se le ha encontrado.

## La marca escondida

En 0xBFF0, detras del relleno 0xFF, van trece bytes de katakana **al reves**,
la longitud, el numero de catalogo en BCD y 0xAA:

```
RC-736   コナミのボクシング
```

El formato lo descubrio **Manuel Pazos** (@ManuelPazosMSX). `tools/marca_konami.py`
solo lo lee.

## INIT y el gancho

INIT (0x4091) hace cinco cosas y se para:

1. RSLREG y EXPTBL para saber en que ranura esta, y **ENASLT** para dejar el
   cartucho entero visible en 0x4000..0xBFFF;
2. modo de interrupcion 1 y un `jp` al gancho de 0x403D en **H.KEYI** (0xFD9A);
3. la pila en 0xE7FF, justo debajo de las variables;
4. 0x7EF bytes desde 0xE000 a cero;
5. el PSG en silencio, los 16 KB de VRAM a cero y los ocho registros del VDP.

Y despues, un `jr $` en 0x40D9. **Todo el juego ocurre dentro de la
interrupcion.**

## La VRAM, al reves de lo habitual

Los ocho bytes de 0x4429 son `02 E2 0E 7F 07 76 03 E4`. R3 = 0x7F y R4 = 0x07
ponen los **colores debajo** de los patrones:

```
colores            0x0000..0x17FF   tres bancos de 0x800
patrones de sprite 0x1800..0x1FFF
patrones           0x2000..0x37FF   tres bancos de 0x800
nombres            0x3800..0x3AFF
atributos de sprite 0x3B00..0x3B7F
```

R7 = 0xE4 dice borde azul... pero no dura: `monta_una_columna_del_fondo`
(0x439E) lo reescribe a **0xE1** en cada llamada, y de la presentacion en
adelante el fondo es **negro**.

Y una trampa que se paga una vez: el cartucho escribe direcciones como 0x7800 o
0x6008. SETWRT solo mira **catorce bits**, asi que 0x7800 es 0x3800 y 0x6008 es
0x2008.

## Los mandos

`lee_el_mando` (0x443C) lee **un** mando por el PSG, y el bit 7 de (0xE002)
alterna en cada llamada entre el puerto 1 (0x8F) y el 2 (0xCF). Como el gancho
llama dos veces por cuadro, el bit vuelve solo a donde estaba.

El teclado va con el mismo reparto de bits, y cada boxeador tiene su juego:

| | arriba | abajo | izquierda | derecha | golpe |
|---|---|---|---|---|---|
| uno | cursor arriba | cursor abajo | cursor izq. | cursor der. | ESPACIO |
| otro | E | C | S | F | SHIFT |

El segundo juego es el rombo alrededor de la **D**. Y hay un segundo boton: el
bit 6 de la fila 7 del teclado, que es SELECT.
