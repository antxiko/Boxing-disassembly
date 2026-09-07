#!/usr/bin/env python3
"""El contenido propio de Konami's Boxing para la portada de la web.

Vive aparte del generador a proposito: asi make_web.py no lleva dentro ni un
texto del cartucho anterior, que es de donde han salido casi todos los restos
de otro juego que se han colado en esta serie.

Cada hallazgo lleva su medida al lado. Si una frase no se puede anclar a una
direccion o a una cuenta, no entra.
"""

HALLAZGOS = {
    "es": [
        ("Seis rivales y solo TRES juegos de figuras",
         "<p>Los nombres salen de una tabla de seis punteros en 0x5661: "
         "RED&middot;WOLF, M.B.ALLI, MOAI&middot;KING, SANCHESS, "
         "CHINA&middot;KHAN y MOAI&middot;Jr. Los <b>dibujos</b>, en cambio, "
         "salen de una tabla de <b>tres</b> palabras en 0x52C9 &mdash;0x825C, "
         "0x9670 y 0xABB4&mdash; que 0x4F8D indexa con "
         "<code>(0xE207) &amp; 3</code>. La cuarta palabra caeria dentro del "
         "codigo, pero no se lee nunca: 0x423B fuerza el salto al siguiente "
         "grupo de dieciseis en cuanto el indice llega a 2.</p>"
         "<p>Los tres rivales de la segunda vuelta son los tres primeros "
         "<b>con el color cambiado</b>: 0x526F y 0x51BE cambian el color 4 "
         "por el 0x0C cuando (0xE207) lleva el bit 4 puesto.</p>"),
        ("Pegar cansa, y el golpe solo toca en dos cuadros",
         "<p>Al acabarse un golpe, 0x49BC le suma <b>a quien lo ha dado</b> lo "
         "que dice la tabla de 0x6854 &mdash;3, 2, 1 y 1&mdash;, y el que mas "
         "castiga al otro (0x6850: 12, 10, 9 y 2) es tambien el que mas cansa. "
         "Las dos tablas van en el mismo orden.</p>"
         "<p>Y el golpe tiene una <b>ventana</b>: 0x49FB carga 0xC0 en "
         "(0xE24C) o (0xE24D), y 0x4CCF lo gasta con un <code>srl</code> por "
         "cuadro. De los dos bits solo sale acarreo en el <b>septimo</b> y el "
         "<b>octavo</b> cuadro: fuera de ahi el golpe no puede tocar.</p>"),
        ("El marcador se lleva al reves",
         "<p>(0xE21E) y (0xE21F) no van sumando puntos: van sumando "
         "<b>faltas</b>. Una por llevar tres niveles mas de castigo que el "
         "otro, otra por haber acertado menos golpes, y el doble de lo que "
         "diga (0xE23E) o (0xE261). Al final, 0x4ECD hace <code>10 - "
         "faltas</code> y sube las dos notas a la vez hasta que una llega al "
         "diez. Es el sistema de los diez puntos del boxeo de verdad.</p>"),
        ("La marca oculta de Konami",
         "<p>En 0xBFF0, detras del relleno, estan el titulo en katakana al "
         "reves, la longitud (13), el numero de catalogo en BCD (0x36) y "
         "0xAA: <b>RC-736</b> y "
         "<span lang=\"ja\">&#12467;&#12490;&#12511;&#12398;"
         "&#12508;&#12463;&#12471;&#12531;&#12464;</span>. El hallazgo del "
         "formato es de <b>Manuel Pazos</b>; aqui solo se lee.</p>"
         "<p>Y en 0x4010 hay una <b>segunda cabecera</b> \"AB\" con 07 36 "
         "detras: la que lee el <i>Konami Game Master</i> desde la otra "
         "ranura. Con este son ocho los cartuchos de la serie que la "
         "llevan.</p>"),
        ("La maquina juega al de la izquierda",
         "<p>Con un solo jugador, el boxeador de la <b>izquierda</b> lo lleva "
         "<code>decide_la_maquina</code> (0x4A6B) y el humano es el de la "
         "<b>derecha</b>, que es el que va con el puerto 1 y el cursor. Lo "
         "dicen tres cosas independientes: al colocarlos (0x49FE) al de "
         "0xE232 le toca la columna 22 y al de 0xE255 la 2; al andar, uno se "
         "acerca sumando y el otro restando; y la maquina se acerca "
         "<b>a la derecha</b> (0x4A83) y se retira a la izquierda (0x4B39), "
         "que es lo que le toca al de ese lado.</p>"
         "<p>En la escena 2 &mdash;la demostracion&mdash; al de la derecha lo "
         "mueve el registro <b>R</b> del Z80 (0x4836): juegan solos los "
         "dos.</p>"),
        ("Un reloj de tres minutos, en cuatro casillas",
         "<p>El tiempo del asalto no es un contador binario: son las cuatro "
         "casillas de (0xE212) a (0xE215), en ASCII, que 0x5798 vuelca a la "
         "fila 1 columna 14. Bajan de una en una por el final; cuando las "
         "unidades pasan de '0' a '9' se llevan una de las decenas, y cuando "
         "las decenas pasan de '0' vuelven a <b>'5'</b>. Arranca en 3:01, que "
         "a la primera bajada queda en <b>3:00</b>.</p>"),
    ],
    "en": [
        ("Six opponents and only THREE sets of figures",
         "<p>The names come from a table of six pointers at 0x5661: "
         "RED&middot;WOLF, M.B.ALLI, MOAI&middot;KING, SANCHESS, "
         "CHINA&middot;KHAN and MOAI&middot;Jr. The <b>drawings</b>, though, "
         "come from a table of <b>three</b> words at 0x52C9 &mdash;0x825C, "
         "0x9670 and 0xABB4&mdash; which 0x4F8D indexes with "
         "<code>(0xE207) &amp; 3</code>. A fourth word would fall inside code, "
         "but it is never read: 0x423B forces the jump to the next group of "
         "sixteen as soon as the index reaches 2.</p>"
         "<p>The three opponents of the second round are the first three "
         "<b>with the colour swapped</b>: 0x526F and 0x51BE turn colour 4 "
         "into 0x0C when (0xE207) has bit 4 set.</p>"),
        ("Throwing a punch tires you, and it only lands on two frames",
         "<p>When a punch ends, 0x49BC adds to <b>whoever threw it</b> what "
         "the table at 0x6854 says &mdash;3, 2, 1 and 1&mdash;, and the punch "
         "that hurts the other most (0x6850: 12, 10, 9 and 2) is also the one "
         "that tires you most. Both tables run in the same order.</p>"
         "<p>And the punch has a <b>window</b>: 0x49FB loads 0xC0 into "
         "(0xE24C) or (0xE24D), and 0x4CCF spends it with one <code>srl</code> "
         "per frame. Of the two bits, carry only comes out on the "
         "<b>seventh</b> and <b>eighth</b> frame: outside that the punch "
         "cannot land.</p>"),
        ("The scorecard is kept upside down",
         "<p>(0xE21E) and (0xE21F) do not add up points: they add up "
         "<b>faults</b>. One for carrying three damage levels more than the "
         "other, one for having landed fewer punches, and twice whatever "
         "(0xE23E) or (0xE261) says. At the end 0x4ECD does <code>10 - "
         "faults</code> and raises both marks together until one reaches ten. "
         "It is the ten-point must system of real boxing.</p>"),
        ("Konami's hidden mark",
         "<p>At 0xBFF0, behind the filler, sit the title in katakana "
         "backwards, the length (13), the catalogue number in BCD (0x36) and "
         "0xAA: <b>RC-736</b> and "
         "<span lang=\"ja\">&#12467;&#12490;&#12511;&#12398;"
         "&#12508;&#12463;&#12471;&#12531;&#12464;</span>. Finding the format "
         "is <b>Manuel Pazos</b>'s work; here it is only read.</p>"
         "<p>And at 0x4010 there is a <b>second header</b> \"AB\" with 07 36 "
         "behind it: the one the <i>Konami Game Master</i> reads from the "
         "other slot. With this one, eight cartridges in the series carry "
         "it.</p>"),
        ("The machine plays the left-hand boxer",
         "<p>With a single player, the boxer on the <b>left</b> is driven by "
         "<code>decide_la_maquina</code> (0x4A6B) and the human is the one on "
         "the <b>right</b>, the one wired to port 1 and the cursor keys. Three "
         "independent things say so: when they are placed (0x49FE) the one at "
         "0xE232 gets column 22 and the one at 0xE255 column 2; when walking, "
         "one closes in by adding and the other by subtracting; and the "
         "machine closes in <b>to the right</b> (0x4A83) and backs off to the "
         "left (0x4B39), which is what the left-hand corner calls for.</p>"
         "<p>In scene 2 &mdash;the attract match&mdash; the right-hand boxer "
         "is driven by the Z80's <b>R</b> register (0x4836): both of them "
         "play on their own.</p>"),
        ("A three-minute clock, in four tiles",
         "<p>The round timer is not a binary counter: it is the four tiles "
         "from (0xE212) to (0xE215), in ASCII, which 0x5798 dumps to row 1, "
         "column 14. They count down from the end; when the units wrap from "
         "'0' to '9' they borrow from the tens, and when the tens wrap from "
         "'0' they go back to <b>'5'</b>. It starts at 3:01, which after the "
         "first tick reads <b>3:00</b>.</p>"),
    ],
}

# Los seis cuadrilateros, uno por rival. Son la misma pantalla con otro nombre,
# otras figuras y, en la segunda vuelta, otro color.
COMBATES = [
    ("combate_1.png", "RED&middot;WOLF, el primero", "RED&middot;WOLF, the first"),
    ("combate_2.png", "M.B.ALLI", "M.B.ALLI"),
    ("combate_3.png", "MOAI&middot;KING", "MOAI&middot;KING"),
    ("combate_4.png", "SANCHESS, ya en la segunda vuelta (STAGE B)",
     "SANCHESS, second time round (STAGE B)"),
    ("combate_5.png", "CHINA&middot;KHAN", "CHINA&middot;KHAN"),
    ("combate_6.png", "MOAI&middot;Jr., el hijo de MOAI&middot;KING",
     "MOAI&middot;Jr., MOAI&middot;KING's son"),
]

GALERIA = [
    ("menu.png",
     "La pantalla del titulo, con las cuatro opciones. El bit 0 de las "
     "banderas de 0x4563 es el que dice si juegan dos, y el bit 4 la "
     "variante B.",
     "The title screen with its four options. Bit 0 of the flags at 0x4563 "
     "says whether two play, and bit 4 picks variant B."),
    ("presentacion.png",
     "La presentacion. El cartel son 26 casillas correlativas en tres filas "
     "que suben una fila cada dos cuadros, catorce veces (0x462A).",
     "The intro. The sign is 26 consecutive tiles in three rows that climb "
     "one row every two frames, fourteen times (0x462A)."),
    ("poses_jugador.png",
     "Las diecinueve poses del jugador, montadas y colocadas con los ocho "
     "bytes de disposicion de cada figura.",
     "The player's nineteen poses, built and placed with each figure's eight "
     "layout bytes."),
    ("poses_rival_1.png",
     "El primer archivo de rival: RED&middot;WOLF y SANCHESS.",
     "The first opponent archive: RED&middot;WOLF and SANCHESS."),
    ("poses_rival_2.png",
     "El segundo: M.B.ALLI y CHINA&middot;KHAN.",
     "The second: M.B.ALLI and CHINA&middot;KHAN."),
    ("poses_rival_3.png",
     "El tercero es un moai: MOAI&middot;KING y MOAI&middot;Jr.",
     "The third one is a moai: MOAI&middot;KING and MOAI&middot;Jr."),
    ("fuente.png",
     "La fuente: cuarenta y seis casillas desde la 0x30, casi ASCII. No hay "
     "Q &mdash;0x51 es un punto medio&mdash; ni Z, y 0x58 es un glifo con la "
     "\"r\" y el punto juntos, que es lo que hace que el sexto rival se llame "
     "MOAI&middot;Jr.",
     "The font: forty-six tiles from 0x30, near enough ASCII. There is no Q "
     "&mdash;0x51 is a middle dot&mdash; and no Z, and 0x58 is a glyph with "
     "\"r\" and the full stop joined, which is what makes the sixth opponent "
     "MOAI&middot;Jr."),
]
