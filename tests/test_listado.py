#!/usr/bin/env python3
"""Comprobaciones sobre el listado de Konami's Boxing, y sobre lo que afirma.

Ninguna necesita el cartucho. Las que miran bytes los sacan de los `defb` del
propio listado, que es lo mismo que hay en la ROM: eso lo garantiza
`make verify`, que reensambla y compara el sha256.

Lo que se vigila:

  - que el listado no se degrade sin que nadie se entere: densidad, rutinas por
    debajo del 10 %, destinos de `call` sin bautizar y bloques de datos sin
    explicar
  - que las afirmaciones que se publican SE COMPRUEBEN sobre los bytes: los
    seis nombres de rivales y el del jugador leidos como ASCII, la tabla que
    traduce el mando a accion, las dos tablas de golpe -la del castigo y la del
    cansancio-, la rampa de la maquina, las banderas de las cuatro opciones del
    menu, las tres tablas de archivo del rival y el reloj de tres minutos
  - que no se cuele el nombre de otro juego de la serie, que ya ha pasado
"""
import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "boxing.asm")
NOTES = os.path.join(RAIZ, "src", "boxing.notes")
ENTRIES = os.path.join(RAIZ, "src", "boxing.entries")
DOCS = os.path.join(RAIZ, "docs")
ORG, FIN = 0x4000, 0xC000

sys.path.insert(0, os.path.join(RAIZ, "tools"))

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega: ya paso con cinco ficheros LICENSE, con
# el pie de catorce paginas de otro proyecto y con los tests de Hyper Sports 3,
# que llegaron copiados de otro cartucho y apuntaban a su listado.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Nemesis", "Demonia", "Cabbage", "Hole in One",
    "Casio World Open", "3D Golf", "Baseball", "Yie Ar Kung-Fu",
    "Kings Valley", "Sky Jaguar", "Mopi Ranger", "Descubrimiento",
    "War in Middle Earth", "Ping Pong", "Soccer", "Football", "Road Fighter",
    "Hyper Sports", "Hyper Olympic", "Goonies", "Knightmare", "Trailblazer",
    "Game Master",
)


def lee(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def lineas_del_asm():
    return lee(ASM).splitlines()


def bytes_de_los_defb():
    """Reconstruye los bloques de datos leyendo los `defb` del listado."""
    fuera = {}
    for ln in lineas_del_asm():
        m = re.match(r"^\tdef[bw] (.*?)\t*; ?([0-9a-f]{4})", ln)
        if not m:
            continue
        dire = int(m.group(2), 16)
        vals = []
        for tr in m.group(1).split(","):
            tr = tr.strip()
            if not tr:
                continue
            v = int(tr[:-1], 16) if tr.endswith("h") else int(tr, 0)
            if ln.lstrip().startswith("defw"):
                vals += [v & 0xFF, v >> 8]
            else:
                vals.append(v & 0xFF)
        for i, v in enumerate(vals):
            fuera[dire + i] = v
    return fuera


DATOS = bytes_de_los_defb()


def trozo(dire, n):
    """n bytes seguidos desde una direccion, sacados de los `defb`."""
    fuera = []
    for k in range(n):
        if dire + k not in DATOS:
            raise AssertionError("0x%04X no esta en los datos del listado"
                                 % (dire + k))
        fuera.append(DATOS[dire + k])
    return fuera


def rom_parcial():
    """Una imagen de 32 KB con los bytes de datos puestos en su sitio.

    Los tramos de codigo quedan a cero, que es lo que hace que solo se pueda
    usar para recorrer guiones, que son datos de principio a fin.
    """
    rom = bytearray(FIN - ORG)
    for a, v in DATOS.items():
        rom[a - ORG] = v
    return bytes(rom)


def texto(bs):
    """Las casillas del cartucho son ASCII, con tres glifos cambiados.

    La fuente se carga en las casillas 0x30 a 0x5D desde el guion de 0x59C4, y
    coincide con el ASCII salvo que 0x3A es un circulo, 0x40 un guion y 0x51 un
    punto medio en vez de la Q. El punto medio se lee aqui como un punto, que
    es lo que separa las palabras de los nombres.
    """
    fuera = ""
    for b in bs:
        if b == 0x51:
            fuera += "."
        elif 0x30 <= b <= 0x5D:
            fuera += chr(b)
        elif b == 0x00:
            fuera += " "
        else:
            fuera += "?"
    return fuera


class TestListado(unittest.TestCase):
    """Que el listado siga siendo el que se publica."""

    def setUp(self):
        self.lineas = lineas_del_asm()

    def test_el_encabezado_dice_de_que_cartucho_es(self):
        cabeza = "\n".join(self.lineas[:12])
        self.assertIn("BOXING", cabeza)

    def test_todas_las_instrucciones_llevan_su_direccion(self):
        malas = [ln for ln in self.lineas
                 if ln.startswith("\t")
                 and not re.match(r"^\tdef[bw] ", ln)
                 and not re.match(r"^\torg ", ln)
                 and not re.search(r";[0-9a-f]{4}", ln)]
        self.assertEqual(malas, [], "instrucciones sin direccion: %s"
                         % malas[:3])

    def test_las_direcciones_van_en_orden_y_dentro_del_cartucho(self):
        ant = ORG - 1
        for ln in self.lineas:
            if not ln.startswith("\t"):
                continue
            m = re.search(r";([0-9a-f]{4})", ln)
            if not m:
                continue
            a = int(m.group(1), 16)
            self.assertGreater(a, ant, "0x%04X no va detras de 0x%04X"
                               % (a, ant))
            self.assertTrue(ORG <= a < FIN, "0x%04X fuera del cartucho" % a)
            ant = a


class TestDensidad(unittest.TestCase):
    """La vara: 22 % de media y ninguna rutina por debajo del 10 %."""

    def setUp(self):
        self.rutinas = []
        cur = None
        for ln in lineas_del_asm():
            m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", ln)
            if m:
                cur = None if m.group(1).startswith("DATA_") else [m.group(1),
                                                                   0, 0]
                if cur:
                    self.rutinas.append(cur)
                continue
            m = re.match(r"^\t(.*?);([0-9a-f]{4})(.*)$", ln)
            if m and cur is not None and not re.match(r"^\s*def[bw] ",
                                                      m.group(1)):
                cur[1] += 1
                if m.group(3).strip().startswith(";"):
                    cur[2] += 1

    def test_densidad_por_encima_del_liston(self):
        tot = sum(r[1] for r in self.rutinas)
        com = sum(r[2] for r in self.rutinas)
        self.assertGreater(tot, 3000, "el listado ha encogido: %d" % tot)
        self.assertGreaterEqual(100.0 * com / tot, 22.0,
                                "densidad %.1f %%, por debajo del liston"
                                % (100.0 * com / tot))

    def test_ninguna_rutina_por_debajo_del_diez_por_ciento(self):
        flojas = [r[0] for r in self.rutinas
                  if r[1] >= 6 and 100 * r[2] < 10 * r[1]]
        self.assertEqual(flojas, [], "rutinas flojas: %s" % flojas[:8])


class TestBautizo(unittest.TestCase):
    """Lo que se LLAMA lleva nombre; lo que solo recibe saltos puede no."""

    def test_ningun_destino_de_call_se_queda_en_l_xxxx(self):
        llamadas = set()
        for ln in lineas_del_asm():
            for m in re.finditer(r"\bcall (?:n?[zcpm],)?(L_[0-9A-F]{4})", ln):
                llamadas.add(m.group(1))
        etiquetas = set(re.findall(r"^(L_[0-9A-F]{4}):", lee(ASM), re.M))
        sin = sorted(llamadas & etiquetas)
        self.assertEqual(sin, [], "destinos de call sin bautizar: %s" % sin[:8])


class TestBloquesDeDatos(unittest.TestCase):
    """Cada bloque de datos tiene que decir QUE es, no solo donde empieza."""

    def test_todos_los_bloques_llevan_nombre_y_explicacion(self):
        cortos = []
        for ln in lee(NOTES).splitlines():
            m = re.match(r"^D (0x[0-9a-f]{4}) (0x[0-9a-f]{4}) (\S+)\s+(.*)$",
                         ln)
            if m and len(m.group(4).strip()) < 20:
                cortos.append((m.group(1), m.group(3)))
        self.assertEqual(cortos, [], "bloques mal explicados: %s" % cortos[:5])

    def test_ningun_bloque_se_llama_por_su_direccion(self):
        malos = [ln.split()[3] for ln in lee(NOTES).splitlines()
                 if ln.startswith("D 0x") and "0x" in ln.split()[3]]
        self.assertEqual(malos, [], "bloques sin identificar: %s" % malos[:5])

    def test_las_entradas_estan_justificadas(self):
        sin_razon = []
        for ln in lee(ENTRIES).splitlines():
            ln = ln.strip()
            if not ln or ln.startswith("#"):
                continue
            if "#" not in ln and ";" not in ln:
                sin_razon.append(ln)
        self.assertEqual(sin_razon, [], "entradas sin justificar: %s"
                         % sin_razon[:5])


class TestLasDosCabeceras(unittest.TestCase):
    """La del MSX en 0x4000 y la del Konami Game Master en 0x4010."""

    def test_la_cabecera_del_msx_declara_init_en_0x4091(self):
        bs = trozo(0x4000, 16)
        self.assertEqual(bs[:2], [0x41, 0x42], "no empieza por AB")
        self.assertEqual(bs[2] | (bs[3] << 8), 0x4091)
        self.assertEqual(bs[4:], [0] * 12,
                         "STATEMENT, DEVICE y TEXT no estan a cero")

    def test_la_segunda_cabecera_es_la_del_game_master(self):
        bs = trozo(0x4010, 4)
        self.assertEqual(bs[:2], [0x41, 0x42], "la segunda tampoco es AB")
        self.assertEqual(bs[2:], [0x07, 0x36], "no lleva el 07 36 del RC-736")

    def test_la_marca_oculta_de_konami_dice_rc_736(self):
        """El hallazgo es de Manuel Pazos: titulo en katakana al reves,
        longitud, las cifras del RC en BCD y 0xAA."""
        bs = trozo(0xBFF0, 16)
        self.assertEqual(bs[13], 13, "la longitud no son 13 casillas")
        self.assertEqual(bs[14], 0x36, "el RC en BCD no es 36")
        self.assertEqual(bs[15], 0xAA, "no cierra con 0xAA")


class TestElMando(unittest.TestCase):
    """La tabla de 0x4C72: cinco bits de mando a una de las once acciones."""

    UTILES = {0x01: 3, 0x02: 1, 0x04: 9, 0x08: 0x0A, 0x10: 8,
              0x11: 5, 0x12: 6, 0x14: 4, 0x18: 7}

    def setUp(self):
        self.tabla = trozo(0x4C72, 32)

    def test_las_nueve_combinaciones_utiles(self):
        for pulsado, accion in self.UTILES.items():
            self.assertEqual(self.tabla[pulsado], accion,
                             "el mando 0x%02X no da la accion %d"
                             % (pulsado, accion))

    def test_las_otras_veintitres_no_hacen_nada(self):
        ceros = [i for i, v in enumerate(self.tabla) if v == 0]
        self.assertEqual(len(ceros), 23)
        self.assertEqual(sorted(set(ceros) | set(self.UTILES)),
                         list(range(32)))

    def test_las_nueve_acciones_son_distintas(self):
        self.assertEqual(len(set(self.UTILES.values())), 9)

    def test_golpe_mas_direccion_da_los_dos_golpes_de_lado(self):
        """0x14 y 0x18 son golpe+izquierda y golpe+derecha, y son las dos
        combinaciones que 0x4483 cambia una por otra en el boxeador de la
        derecha: el mismo golpe visto desde el otro lado."""
        self.assertEqual(self.tabla[0x14], 4)
        self.assertEqual(self.tabla[0x18], 7)
        self.assertNotEqual(self.tabla[0x14], self.tabla[0x18])


class TestLosNombres(unittest.TestCase):
    """Los seis rivales y el jugador, leidos de los bytes con la fuente."""

    RIVALES = ("RED.WOLF", "M.B.ALLI", "MOAI.KING", "SANCHESS",
               "CHINA.KHAN", "MOAI.J")   # la ultima casilla es el glifo "r." de 0x58

    def test_la_tabla_apunta_a_seis_nombres(self):
        p = trozo(0x5661, 12)
        dirs = [p[2 * i] | (p[2 * i + 1] << 8) for i in range(6)]
        self.assertEqual(dirs, [0x566D, 0x5678, 0x5683, 0x568E, 0x5699,
                                0x56A5])
        self.assertEqual(sorted(dirs), dirs, "no van en orden")

    def test_los_seis_nombres_dicen_lo_que_se_publica(self):
        p = trozo(0x5661, 12)
        for i, esperado in enumerate(self.RIVALES):
            ini = p[2 * i] | (p[2 * i + 1] << 8)
            n = trozo(ini, 1)[0] & 0x7F      # guion comprimido: literal de n
            leido = texto(trozo(ini + 1, n)).replace("?", "")
            self.assertTrue(leido.startswith(esperado),
                            "el rival %d dice %s y no %s"
                            % (i, leido, esperado))

    def test_el_jugador_se_llama_ryu(self):
        n = trozo(0x56AF, 1)[0] & 0x7F
        self.assertEqual(texto(trozo(0x56B0, n)), "RYU")

    def test_seis_nombres_pero_solo_tres_juegos_de_figuras(self):
        """0x4F8D indexa con (0xE207) & 3, y solo hay tres palabras: los tres
        rivales de la segunda vuelta son los tres primeros con otro color."""
        p = trozo(0x52C9, 6)
        tablas = [p[2 * i] | (p[2 * i + 1] << 8) for i in range(3)]
        self.assertEqual(tablas, [0x825C, 0x9670, 0xABB4])
        self.assertEqual(len(self.RIVALES), 2 * len(tablas))


class TestLosRotulos(unittest.TestCase):
    """Los guiones de rotulos llevan delante la direccion de VRAM."""

    def fila_y_columna(self, dire):
        bs = trozo(dire, 2)
        v = (bs[0] | (bs[1] << 8)) & 0x3FFF
        self.assertTrue(0x3800 <= v < 0x3B00,
                        "0x%04X no cae en la tabla de nombres" % v)
        return divmod(v - 0x3800, 32)

    def test_push_space_key(self):
        self.assertEqual(self.fila_y_columna(0x5B18), (16, 9))
        self.assertEqual(texto(trozo(0x5B1A, 14)), "PUSH SPACE KEY")
        self.assertEqual(trozo(0x5B28, 1), [0xFF], "el rotulo no cierra")

    def test_game_over(self):
        self.assertEqual(self.fila_y_columna(0x5BAF), (11, 11))
        self.assertEqual(texto(trozo(0x5BB1, 10)), "GAME  OVER")
        self.assertEqual(trozo(0x5BBB, 1), [0xFF], "el rotulo no cierra")


class TestElCastigo(unittest.TestCase):
    """Las dos tablas del golpe y los topes de nivel."""

    def test_el_castigo_de_cada_golpe(self):
        self.assertEqual(trozo(0x6850, 4), [12, 10, 9, 2])

    def test_lo_que_cansa_cada_golpe(self):
        self.assertEqual(trozo(0x6854, 4), [3, 2, 1, 1])

    def test_el_golpe_que_mas_castiga_es_el_que_mas_cansa(self):
        """No es casualidad: las dos tablas van en el mismo orden."""
        castigo = trozo(0x6850, 4)
        cansa = trozo(0x6854, 4)
        for i in range(3):
            self.assertGreaterEqual(castigo[i], castigo[i + 1])
            self.assertGreaterEqual(cansa[i], cansa[i + 1])

    def test_los_tres_topes(self):
        self.assertEqual(trozo(0x5445, 3), [0x1A, 0x14, 0x10])

    def test_los_cuatro_ruidos_de_golpe(self):
        self.assertEqual(trozo(0x4DFD, 5), [0x0C, 0x51, 0x4F, 0x51, 0x4D])


class TestLaMaquina(unittest.TestCase):
    """La rampa que decide cada cuanto golpea."""

    def test_la_rampa_no_sube_nunca(self):
        r = trozo(0x4DDE, 31)
        for i in range(30):
            self.assertGreaterEqual(r[i], r[i + 1],
                                    "la rampa sube en el puesto %d" % i)

    def test_la_rampa_arranca_alta_y_acaba_plana(self):
        r = trozo(0x4DDE, 31)
        self.assertEqual(r[0], 0x4C)
        self.assertEqual(r[-4:], [0x0C] * 4, "no se queda plana al final")

    def test_las_nueve_ternas_de_la_campana(self):
        t = trozo(0x5254, 27)
        self.assertEqual(len(t) // 3, 9)
        for i in range(9):
            self.assertTrue(0 < t[3 * i] <= 0x20, "la tira %d no cabe" % i)


class TestElMenuYElReloj(unittest.TestCase):

    def test_las_cuatro_opciones_del_menu(self):
        self.assertEqual(trozo(0x4563, 4), [0x40, 0x50, 0x61, 0x71])

    def test_el_bit_0_marca_las_dos_opciones_de_dos_jugadores(self):
        """Con el bit 0 puesto, 0x47C0 se salta a decide_la_maquina."""
        b = trozo(0x4563, 4)
        self.assertEqual([v & 1 for v in b], [0, 0, 1, 1])

    def test_el_bit_4_alterna_la_variante_dura(self):
        b = trozo(0x4563, 4)
        self.assertEqual([(v >> 4) & 1 for v in b], [0, 1, 0, 1])

    def test_el_reloj_arranca_en_tres_minutos(self):
        """0x560E copia estos cinco a 0xE211: el estado y las cuatro casillas
        del reloj. La primera bajada de 0x5768 deja el 1 en 0."""
        b = trozo(0x561F, 5)
        self.assertEqual(b[0], 0x00, "el byte de estado no arranca a cero")
        self.assertEqual(texto([b[1]]), "3")
        self.assertEqual(texto([b[3], b[4]]), "01")

    def test_las_cuatro_direcciones_de_vram_del_dibujo(self):
        """0x4F76 las indexa; con los catorce bits que mira SETWRT caen en la
        tabla de patrones, que este cartucho pone en 0x2000."""
        p = trozo(0x52BC, 8)
        ds = [(p[2 * i] | (p[2 * i + 1] << 8)) & 0x3FFF for i in range(4)]
        self.assertEqual(ds, [0x2980, 0x2AC0, 0x2C00, 0x2D40])
        for d in ds:
            self.assertTrue(0x2000 <= d < 0x3800,
                            "0x%04X no cae en los patrones" % d)


class TestLaCadenaDeGuiones(unittest.TestCase):
    """De 0x59C4 a 0x695A cada guion acaba donde empieza el siguiente."""

    def test_los_guiones_declarados_teselan_sin_hueco_ni_solape(self):
        bloques = []
        for ln in lee(NOTES).splitlines():
            m = re.match(r"^D (0x[0-9a-f]{4}) (0x[0-9a-f]{4}) ", ln)
            if m:
                a, b = int(m.group(1), 16), int(m.group(2), 16)
                if 0x59C4 <= a < 0x695A:
                    bloques.append((a, b))
        bloques.sort()
        self.assertTrue(bloques, "no hay bloques declarados en la cadena")
        self.assertEqual(bloques[0][0], 0x59C4)
        for (a, b), (c, _) in zip(bloques, bloques[1:]):
            self.assertEqual(b, c, "hueco o solape en 0x%04X" % b)
        self.assertEqual(bloques[-1][1], 0x695A)

    def test_el_guion_de_la_fuente_se_recorre_entero(self):
        import formatos
        fin, escritos, _ = formatos.rle(rom_parcial(), 0x59C4,
                                        con_palabra=False)
        self.assertEqual(fin, 0x5AF4,
                         "el guion de la fuente no acaba donde dice")
        self.assertEqual(escritos, 368, "no escribe 368 bytes")

    def test_el_rotulo_de_push_space_key_se_recorre_entero(self):
        import formatos
        fin, casillas, _ = formatos.rotulo(rom_parcial(), 0x5B18)
        self.assertEqual(fin, 0x5B29)
        self.assertEqual(casillas, 14,
                         "no son las catorce casillas del texto")


class TestLaWeb(unittest.TestCase):
    """Las cifras que se publican tienen que ser las del listado de AHORA."""

    def setUp(self):
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        import make_web
        self.w = make_web

    def test_la_suma_de_bytes_da_el_cartucho(self):
        self.assertEqual(self.w.CODIGO + self.w.DATOS, 0xC000 - 0x4000)

    def test_las_cifras_de_la_portada_son_las_del_listado(self):
        """CODIGO y DATOS salen de presupuesto.py, y las de densidad de
        contar el propio .asm. Si el listado cambia, esto salta."""
        codigo = 0
        for ln in lee(ASM).splitlines():
            m = re.match(r"^; CODIGO 0x([0-9a-f]{4})\.\.0x([0-9a-f]{4})", ln)
            if m:
                codigo += int(m.group(2), 16) - int(m.group(1), 16)
        self.assertEqual(codigo, self.w.CODIGO,
                         "la portada dice %d bytes de codigo y el listado %d"
                         % (self.w.CODIGO, codigo))

    def test_la_densidad_declarada_cuadra_con_las_dos_cuentas(self):
        d = 100.0 * self.w.COMENTARIOS / self.w.INSTRUCCIONES
        self.assertEqual("%.1f" % d, self.w.DENSIDAD_EN)
        self.assertEqual(self.w.DENSIDAD.replace(",", "."), self.w.DENSIDAD_EN)

    def test_las_paginas_de_los_dos_idiomas_estan_las_catorce(self):
        for carpeta, nombres in (
                (DOCS, ("GETTING-STARTED", "THE-GAME", "THE-CARTRIDGE",
                        "THE-CODE", "FINDINGS", "IN-THE-EMULATOR",
                        "OPEN-QUESTIONS")),
                (os.path.join(DOCS, "es"),
                 ("EMPEZAR", "EL-JUEGO", "EL-CARTUCHO", "EL-CODIGO",
                  "HALLAZGOS", "EN-EL-EMULADOR", "PREGUNTAS-ABIERTAS"))):
            for n in nombres:
                for ext in (".md", ".html"):
                    p = os.path.join(carpeta, n + ext)
                    self.assertTrue(os.path.exists(p), "falta %s" % p)
            self.assertTrue(os.path.exists(os.path.join(carpeta, "index.html")))

    def test_las_paginas_en_castellano_suben_un_nivel_para_las_imagenes(self):
        """docs/es vive un nivel mas abajo: las imagenes van a ../img/."""
        malas = []
        for fn in sorted(os.listdir(os.path.join(DOCS, "es"))):
            if not fn.endswith(".md"):
                continue
            t = lee(os.path.join(DOCS, "es", fn))
            if re.search(r"\]\(img/", t):
                malas.append(fn)
        self.assertEqual(malas, [], "imagenes sin subir un nivel: %s" % malas)

    def test_toda_imagen_citada_existe(self):
        faltan = []
        for carpeta in (DOCS, os.path.join(DOCS, "es")):
            for fn in sorted(os.listdir(carpeta)):
                if not fn.endswith(".md"):
                    continue
                for ruta in re.findall(r"!\[[^\]]*\]\(([^)]+)\)",
                                       lee(os.path.join(carpeta, fn))):
                    p = os.path.normpath(os.path.join(carpeta, ruta))
                    if not os.path.exists(p):
                        faltan.append((fn, ruta))
        self.assertEqual(faltan, [], "imagenes que no existen: %s" % faltan[:5])

    def test_las_catorce_laminas_estan_dibujadas(self):
        img = os.path.join(DOCS, "img")
        self.assertTrue(os.path.isdir(img), "no hay docs/img: pasa make imagenes")
        pngs = [f for f in os.listdir(img) if f.endswith(".png")]
        self.assertEqual(len(pngs), 14, "hay %d laminas y son 14" % len(pngs))
        for f in pngs:
            self.assertGreater(os.path.getsize(os.path.join(img, f)), 500,
                               "%s pesa demasiado poco para ser un dibujo" % f)


class TestNoSeCuelaOtroJuego(unittest.TestCase):
    """Cinco LICENSE de la serie nombraban otro juego. No otra vez."""

    def test_el_encabezado_del_listado_es_de_este_juego(self):
        cabeza = "\n".join(lineas_del_asm()[:12])
        for otro in OTROS_JUEGOS:
            self.assertNotIn(otro, cabeza, "el listado nombra %s" % otro)

    def test_ni_las_notas_ni_los_tests_apuntan_a_otro_fichero(self):
        for ruta in (NOTES, ENTRIES, os.path.abspath(__file__)):
            t = lee(ruta)
            for otro in ("goonies", "knightmare", "soccer", "tennis",
                         "pingpong", "roadfighter"):
                self.assertNotIn("src/%s.asm" % otro, t,
                                 "%s apunta a src/%s.asm"
                                 % (os.path.basename(ruta), otro))

    def test_los_ficheros_del_repositorio_existen(self):
        for ruta in (ASM, NOTES, ENTRIES):
            self.assertTrue(os.path.exists(ruta), "falta %s" % ruta)


if __name__ == "__main__":
    unittest.main()
