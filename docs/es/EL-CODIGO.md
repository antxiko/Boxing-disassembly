# El codigo

El cartucho comparte armazon con los otros Konami de la epoca: 561 bytes en
comun con *Knightmare* (RC-739) y 562 con *The Goonies* (RC-734), medidos con
`tools/comun_normalizado.py`. El despachador cae hasta en la **misma
direccion** que en Knightmare, 0x406C.

## El gancho de interrupcion

0x403D es todo el programa. Cada cuadro:

1. lee el estado del VDP, que es lo que baja la peticion de interrupcion;
2. el **sonido**, siempre, aunque el cuadro anterior no haya acabado;
3. un **cerrojo** en (0xE005): si el cuadro anterior sigue dentro, no se entra;
4. los mandos de los dos boxeadores, uno con HL' = 0xE300 y otro con
   HL' = 0xE009;
5. `avanza_el_reloj` (0x40DB), que baja los tres temporizadores y despacha la
   escena;
6. y de salida, si el VDP dice que hubo colision, otra pasada de sonido.

## Las once escenas

(0xE000) dice en cual estamos y (0xE001) el paso dentro de ella. La tabla de
0x411C reparte, y casi todas empiezan con `djnz` encadenados: el paso llega en
B y cada `djnz` se come uno.

La escena **2** es la partida. Su bucle de cada cuadro es 0x4338, y en trece
llamadas hace todo el juego: la campana, los sprites, los dos boxeadores, el
arbitro, los golpes que entran, el castigo, las barras y el asalto.

## Los dos boxeadores

Cada uno tiene un bloque de **once bytes**, y el truco es que solo hay **una**
zona de trabajo: 0x46F9 copia la del que toca a 0xE221, lo hace todo ahi y la
devuelve. Asi el codigo no lleva indice de jugador.

| bloque | quien | columna al empezar |
|---|---|---|
| 0xE232 | el de la **derecha** | 22 |
| 0xE255 | el de la **izquierda** | 2 |

(0xE22F) alterna entre 0 y 1 en cada llamada y es lo que dice de cual se trata.
Y cada uno entra sabiendo **la accion del otro**, que es lo unico que sabe del
rival.

## Las acciones

(0xE228) dice que esta haciendo. La tabla de 0x4C72 traduce los cinco bits del
mando a una de ellas:

| pulsado | accion | |
|---|---|---|
| arriba | 3 | ponerse de pie |
| abajo | 1 | agacharse |
| izquierda / derecha | 9 / 0x0A | andar |
| golpe | 8 | |
| golpe + arriba | 5 | |
| golpe + abajo | 6 | |
| golpe + izquierda / derecha | 4 / 7 | |

Las otras 23 combinaciones dan cero. Al empezar un golpe, 0x48D6 le suma
cuatro: las acciones 9 a 0x0C son "dando el golpe 5 a 8". Y de 0x0D a 0x10 van
esperar, encajar, retroceder y **caer**.

## El golpe que entra

`mira_si_entra_el_golpe` (0x4C92) lo resuelve una vez por boxeador, y el orden
lo echa a suertes la paridad de (0xE23E)+(0xE261). Los dos punteros son el
reparto: **IY** al bloque del que pega e **IX** a la accion del que recibe. De
ahi que el golpe entre con un `ld (ix+000h),00eh`, que es la accion de
encajarlo, y que al pasar del tope (ix+0) pase a 0x10, que es caer.

El castigo son **dos bytes**: el nivel, de 0 a 8, y lo acumulado dentro del
nivel. El tope de cada nivel sale de 0x5445, y **baja**: cuanto mas castigado
esta uno, antes cae.

## El dibujo

`pinta_una_figura` (0x4F66) redibuja el cuerpo de un boxeador **redefiniendo
casillas** que la pantalla ya tiene puestas. Cuatro punteros por figura: dos a
los patrones y dos al color, que esta en la misma posicion con el bit 13
quitado (el `res 5,a` de 0x4F81).

Cada boxeador tiene **dos** juegos de casillas y se turnan cuadro a cuadro:
0x30 y 0x80 para el jugador, 0x58 y 0xA8 para el rival. Mientras uno se ve, el
otro se esta montando.

Y la cabeza y los guantes no son casillas: son **sprites** de 16x16 que
`monta_los_sprites_de_una_figura` (0x5178) escribe del tiron, cuatro bytes por
sprite, con los que sobran aparcados en la fila 0xCF.

## El sonido

Tres voces con su bloque de catorce bytes desde 0xE311. El numero de sonido
hace de **estado y de prioridad** a la vez: uno nuevo solo se cuela si su
numero no es menor que el que ya suena. Y cuantas voces se reparten depende del
numero: por debajo del 7 solo la tercera, del 7 al 0x12 dos, y del 0x13 en
adelante las tres.
