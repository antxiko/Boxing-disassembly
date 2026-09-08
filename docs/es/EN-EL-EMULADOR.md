# En el emulador

Las imagenes de esta web no son capturas: se montan ejecutando en Python los
pasos del cartucho. Y para saber si eso esta bien hecho no vale mirarlas, hay
que **restarlas de la VRAM de verdad**.

## Como se vuelca

```
make vram
```

Lanza openMSX dos veces con dos guiones de Tcl y compara lo que sale:

- `tools/omsx_vram.tcl` no toca una tecla. El cartucho encadena solo
  presentacion, titulo y **demostracion**, y la demostracion es la escena 2:
  ahi el boxeador de la izquierda lo lleva la maquina y el de la derecha el
  registro R, asi que juegan solos los dos. Un punto de interrupcion en
  `monta_el_combate` (0x554B) escribe el rival que toca en (0xE207) **antes de
  que lo lea**, y el cartucho monta ESE combate con su propio codigo. No se
  falsea nada: se cambia un byte de partida, como haria un jugador llegando a
  ese rival.
- `tools/omsx_menu.tcl` va aparte porque el menu necesita una pulsacion:
  pulsa ESPACIO una vez por segundo hasta que 0x4543 lo monta.

De cada instante salen dos ficheros: los 16 KB de VRAM tal cual y un `.txt` con
el estado del juego, para poder decir **contra que** se compara.

## Lo que sale

```
presentacion    color 0  patrones 0  nombres 0   TOTAL 0
menu            color 0  patrones 0  nombres 0   TOTAL 0
rival 1         color 0  patrones 0  nombres 0   TOTAL 0
  boxeadores    atributos 0  patrones 0  casillas del cuerpo 0 (50 casillas)   TOTAL 0
  (con figuras) color 0  patrones 0  nombres 0   TOTAL 0
rival 2..6      color 0  patrones 0  nombres 0   TOTAL 0
  boxeadores    atributos 0  patrones 0  casillas del cuerpo 0   TOTAL 0
---- 8 pantallas, 0 bytes distintos
```

## Los boxeadores se comparan aparte

El gancho de interrupcion rehace los sprites cada cuadro, asi que comparar las
tablas de sprite enteras solo mediria el retardo del volcado. Pero en el
instante del volcado los dos boxeadores estan en la accion y la columna que
apunta el `.txt`, asi que `tools/coteja_vram.py` los monta con esas
&mdash;leyendo el patron de partida de cada uno del propio volcado, porque se
turnan con el contador de cuadros&mdash; y compara los **doce atributos de
sprite**, los **32 bytes de patron de cada sprite en pantalla** y las
**casillas del cuerpo** que la tabla de nombres tiene en las filas 8 a 15. Eso
es lo que distingue a los seis rivales, y hasta que se anadio el cotejo era
ciego a ello: la primera version de esta web decia que la segunda vuelta eran
los tres primeros rivales con el color cambiado, y no era verdad.

## Lo que NO se compara, y por que

- **El resto de las tablas de sprite.** Lo que los atributos no apuntan se
  queda de cuadros anteriores.
- **Las casillas que el marcador y el reloj reescriben.** Van declaradas una a
  una en `tools/coteja_vram.py`, con la rutina que las escribe al lado.
- **La zona de las figuras, salvo en el primer combate.** El primero arranca
  con esa zona limpia y ahi si se compara entera; en los siguientes, lo que la
  figura nueva no reescribe se queda del rival anterior, y eso no hay forma de
  montarlo sin jugar la partida entera.

## Trucos para mirar

Se puede arrancar en el combate que se quiera escribiendo (0xE207) antes de que
`monta_el_combate` lo lea, que es justo lo que hace el guion. Y (0xE000)
gobierna la escena: un 2 ahi lleva a la demostracion.
