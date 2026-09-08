# Hallazgos

Lo que aparecio al desmontarlo. Cada uno con la medida al lado.

## Seis rivales, tres archivos y una pieza escondida para la segunda vuelta

Los nombres son seis y estan en una tabla de seis punteros (0x5661). Las
**figuras** salen de otra tabla, la de 0x52C9, y esa tiene **tres** palabras:
0x825C, 0x9670 y 0xABB4, que son las tablas de los archivos de figuras 2, 3
y 4. 0x4F8D la indexa con `(0xE207) & 3`, y una cuarta palabra caeria en
0x52CF, que ya es codigo. No se lee nunca: 0x423B fuerza el salto al siguiente
grupo de dieciseis en cuanto el indice llega a 2.

Y aun asi los seis son distintos, y SANCHESS no es RED WOLF con otro color.
Cada figura de los tres archivos de rival lleva **una pieza de mas** de las
que declara su cabecera: el byte de +8 dice N, pero 0x5005 hace `inc b` en el
turno del rival &mdash;el bit 1 del contador de cuadros&mdash; y recorre N+1
registros y N+1 punteros. La primera es la pieza de la **segunda vuelta**, y
0x5034 (para los patrones) y 0x5187 (para los atributos de sprite) deciden que
hacer con ella mirando (0xE207):

| (0xE207) | rival | lo que 0x5034 hace con la primera pieza |
|---|---|---|
| bit 4 a cero | RED WOLF, M.B.ALLI, MOAI KING | se la salta (0x5048) |
| bit 4 puesto, bit 0 a cero | SANCHESS, MOAI Jr. | la pinta **en vez de** la segunda (`ld a,002h`, 0x5040) |
| bit 4 y bit 0 puestos | CHINA KHAN | las pinta **todas** (`inc b`, 0x5045) |

Asi que SANCHESS lleva el cuerpo de RED WOLF con **otra cabeza**: la pieza
escondida del archivo 2 (0x9558) es la misma cara con el pelo hasta el cuello,
donde 0x856E lo lleva corto. CHINA KHAN es M.B.ALLI **mas** un sprite negro
(0xAB2E, color 1): la coleta que le cuelga de la cabeza. Y MOAI Jr. cambia el
sprite vacio de MOAI KING (0xBF7B, color 0) por siete pixeles negros en la
cara (0xBF7D), y encima cambia de color: 0x526F y 0x51BE convierten el color 4
en 0x0C &mdash;el azul oscuro en verde&mdash; solo cuando `(0xE207) & 3` vale
2 y el bit 4 esta puesto. El moai es el unico que cambia de color.

Nada de esto es solo una lectura del codigo. La VRAM de los seis
cuadrilateros, volcada de openMSX con cada rival impuesto en (0xE207), sale
con **cero diferencias** en los doce atributos de sprite, en los bytes de
patron de cada sprite en pantalla y en las casillas del cuerpo de los dos
boxeadores ([En el emulador](EN-EL-EMULADOR.html)).

![RED WOLF](../img/poses_rival_1.png)

![SANCHESS: las mismas diecinueve poses, con el pelo hasta el cuello](../img/poses_rival_4.png)

## Pegar cansa

Al acabarse un golpe, `acaba_el_golpe` (0x49BC) le suma **a quien lo ha dado**
lo que dice la tabla de 0x6854, y el resultado va a su propio castigo:

| golpe | castiga al otro (0x6850) | cansa al que pega (0x6854) |
|---|---|---|
| 5 | 12 | 3 |
| 6 | 10 | 2 |
| 7 | 9 | 1 |
| 8 | 2 | 1 |

Las dos tablas van en el **mismo orden**: el golpe que mas castiga es tambien
el que mas cansa. Y por encima del nivel 7 ya no sube: `cp 007h` en 0x49E4.

## El golpe solo toca en el septimo y el octavo cuadro

0x49FB carga **0xC0** en (0xE24C) o (0xE24D), y `pega_el_de_la_derecha`
(0x4CCF) lo gasta con un `srl` por cuadro, saliendose con `ret nc` mientras no
haya acarreo. De 0xC0, el acarreo solo sale en la septima y la octava vuelta.
Fuera de esa ventana el golpe no puede tocar.

## El marcador se lleva al reves

(0xE21E) y (0xE21F) son las tarjetas de los jueces, y no van sumando puntos:
van sumando **faltas**.

- una si un boxeador lleva **tres niveles o mas** de castigo que el otro;
- otra al que menos golpes haya acertado;
- y el doble de lo que diga (0xE23E) o (0xE261).

Al final, 0x4ECD hace `10 - faltas` en las dos y luego las **sube a la vez**
hasta que una llega al diez. Es el sistema de los diez puntos del boxeo de
verdad.

## La maquina juega al de la izquierda

Con un solo jugador, el boxeador de la izquierda lo lleva `decide_la_maquina`
(0x4A6B) y el humano es el de la derecha, que es el que va con el puerto 1 y el
cursor. Lo dicen tres cosas independientes:

1. al colocarlos (0x49FE), al de 0xE232 le toca la columna 22 y al de 0xE255 la 2;
2. al andar, el de 0xE255 se acerca **sumando** y el de 0xE232 **restando**, y
   los topes de columna son 22 por arriba para uno y 2 por abajo para el otro;
3. la maquina se acerca **andando a la derecha** (0x4A83) y se retira a la
   izquierda (0x4B39), que es lo que le toca al de ese lado.

En la escena 2 &mdash;la demostracion&mdash; al de la derecha lo mueve el
registro **R** del Z80 (0x4836): juegan solos los dos.

La maquina devuelve la accion en B con un numero de propina en el nibble alto,
y ese numero se va sumando a (0xE254) **mientras anda**. (0xE254) es lo que
luego elige el guion de golpes en 0x4C1C: cuanto mas anda, mas cambia lo que
va a hacer.

## Los ocho bytes que nadie leia

La cabecera de una figura mide `17 + 5N`. De ella, los **ocho bytes** que
0x500C se salta con un `ld a,008h` &mdash;los que van en `figura + 9 + 3N`&mdash;
son la **disposicion**: uno por fila, con el nibble alto diciendo cuanto se
corre a la derecha y el bajo cuantas casillas van seguidas. De 8 en adelante,
esa fila no se pinta.

Con ellos la figura se coloca sola, y la prueba no es que quede bonita: la
tabla de nombres que sale cuadra **byte a byte** con la del emulador.

## El sexto rival se llama MOAI Jr.

La casilla 0x58 no es la X del ASCII. Dibujando la fuente se ve que es un glifo
con la **"r" y el punto juntos**, asi que el nombre `04 4D 4F 41 49 51 4A 58`
se lee **MOAI&middot;Jr.** &mdash;el hijo de MOAI&middot;KING, con el que
comparte el archivo de figuras 4, que es un moai.

![La fuente](../img/fuente.png)

## El fondo no es el de la tabla de arranque

R7 = 0xE4 sale de los ocho registros de 0x4429, y dice borde azul. Pero
`monta_una_columna_del_fondo` (0x439E) escribe **0xE1** en R7 en cada llamada,
y de la presentacion en adelante el fondo es **negro**. Se vio comparando con
el emulador: montar la pantalla con el azul de la tabla la deja de otro color.

## Codigo que no llama nadie

Tres trozos que son instrucciones validas, encajan entre las rutinas de al lado
y a los que **no llega ni un `call`, ni un `jp`, ni una palabra de ninguna
tabla** &mdash;comprobado buscando los dos bytes en toda la ROM:

- **0x4038**, que deja el puerto de datos del VDP en C, lo mismo que la cola de
  `prepara_la_escritura`;
- **0x45CA**, hermana de `descomprime_en_tres_bancos` que usa
  `vuelca_en_la_vram` en vez del descompresor;
- **0x54EC**, una entrada alternativa al pintor de piezas.

Y uno mas que si se ejecuta y no hace nada: 0x470D escribe en 0x4F84, que es
**ROM**.
