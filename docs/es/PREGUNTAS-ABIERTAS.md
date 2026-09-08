# Preguntas abiertas

Lo que no se sabe. Va aqui y no se disimula.

## Los guiones de la maquina

`saca_el_golpe_del_guion` (0x4C02) monta un puntero en (0xE252) a partir de
cuatro grupos de ocho ternas en 0x6858, y lo indexa con `(0xE207) & 3` por
veinticuatro y `(0xE254) & 7` por tres. Los **tres pasos** de cada guion estan
leidos, y tambien que en los impares se echa a suertes coger el byte de antes o
el de despues (0x4C40). Lo que **no** esta medido es si las ocho ternas de cada
grupo forman un repertorio de combinaciones reconocible &mdash;un uno-dos, un
gancho&mdash; o si son una lista sin mas.

## (0xE21A) y (0xE218), a partir del nivel 5

El tope de cada nivel de castigo sale de 0x5445 &mdash;0x1A, 0x14 y 0x10&mdash;
para los niveles 5, 6 y 7, y es 0x10 por debajo del 5. Que el 5 tenga el tope
**mas alto** de los tres rompe la monotonia y no se ha encontrado explicacion
dentro del codigo. Puede ser deliberado &mdash;un respiro al llegar a la mitad&mdash;
o puede ser un valor puesto a ojo.

## El segundo boton

`lee_el_teclado` (0x44A8) coge el bit 6 de la fila 7 del teclado &mdash;que es
**SELECT**&mdash; y lo mete en el bit 5, que 0x4467 suma al bit 4, o sea al
golpe. Funciona como un segundo boton, pero no se ha comprobado en el emulador
si el juego hace algo distinto con el o si es solo comodidad.

## Los 26 bytes que faltan en los archivos de figuras

`tools/archivo_de_figuras.py` explica **20.312 de los 20.338 bytes** de
0x707E..0xBFF0 recorriendo las cuatro tablas y sus 76 figuras, cada una con la
cuenta de piezas que recorre el Z80 de verdad. Quedan **26 bytes en dos
huecos**: ocho delante de la primera tabla (0x707E) y dieciocho justo antes de
la marca oculta de Konami (0xBFDE). Estan declarados como datos y no los lee
nadie por ninguno de los caminos trazados, pero no se sabe que son.
