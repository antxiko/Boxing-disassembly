# El juego

*Konami's Boxing* es un combate de boxeo visto de lado, para uno o dos
jugadores. Konami lo publico para MSX en 1985 con el numero de catalogo
**RC-736**.

![La pantalla del titulo](../img/menu.png)

## Las cuatro opciones

La pantalla del titulo ofrece cuatro, y las cuatro se resuelven en **un solo
byte de banderas** que `lee_el_menu` (0x4502) copia a (0xE002) desde la tabla
de 0x4563:

| opcion | byte | bit 0 | bit 4 |
|---|---|---|---|
| 1PLAYER GAME A | 0x40 | | |
| 1PLAYER GAME B | 0x50 | | dura |
| 2PLAYERS GAME A | 0x61 | dos juegan | |
| 2PLAYERS GAME B | 0x71 | dos juegan | dura |

El **bit 0** es el que decide si la maquina juega: con el puesto, 0x47C0 se
salta `decide_la_maquina` y los dos boxeadores leen su mando. El **bit 4**
elige la variante dura, que 0x42F5 traduce en (0xE206) = 3 y (0xE207) = 0x10.

## Los seis rivales

![RED WOLF](../img/combate_1.png)

Los nombres salen de una tabla de seis punteros en 0x5661, y se leen con la
fuente del propio cartucho: **RED&middot;WOLF**, **M.B.ALLI**,
**MOAI&middot;KING**, **SANCHESS**, **CHINA&middot;KHAN** y
**MOAI&middot;Jr.** El jugador se llama siempre **RYU** (0x56AF), y su nombre
no sale de la tabla: lo pone 0x55A0 aparte.

![MOAI KING](../img/combate_3.png)

Las **figuras** salen de tres archivos, y aun asi los seis son distintos:
cada archivo esconde una pieza que solo pinta la segunda vuelta. Ver
[Hallazgos](HALLAZGOS.html).

## El asalto

Tres minutos, contados en cuatro casillas ASCII de (0xE212) a (0xE215) que
arrancan en 3:01 y a la primera bajada quedan en **3:00**. Tres asaltos por
combate: (0xE210) los cuenta y 0x57C7 lo sube.

Debajo, la tira de **veintidos casillas** de la fila 22 es una sola barra que
los dos boxeadores se comen por los extremos: la del de la izquierda desde el
principio y la del de la derecha desde el final (0x5448). Cuando el castigo
pasa del nivel 6, las dos casillas del borde **parpadean** con el bit 4 del
contador de cuadros.

## Los boxeadores

![Las diecinueve poses del jugador](../img/poses_jugador.png)

Cada boxeador tiene **diecinueve** poses. El cuerpo son **casillas** que se
redefinen cada cuadro; la cabeza, el pelo y los guantes son **sprites** de
16x16. Las hojas se montan igual que el cuadrilatero: las casillas colocadas
con los ocho bytes de disposicion de cada figura y los sprites encima, con las
piezas que dice (0xE207). Las poses van desde la guardia hasta el derribo, y
la ultima es la de la victoria, con los dos guantes en alto.

![MOAI KING](../img/poses_rival_3.png)

![MOAI Jr.: el mismo archivo con el color 4 cambiado por el 0x0C](../img/poses_rival_6.png)
