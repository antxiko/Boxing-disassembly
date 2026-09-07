# Konami's Boxing (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como boxing.rom, y
# `make comprueba` verifica su sha256.

ROM      = boxing.rom
SHA      = 43b23739d63b636922f0a98c33322bfdeafbefeccc01dd74fb0a45107581d0e6
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = KONAMI'S BOXING - Konami - MSX1 - cartucho RC-736 de 32 KB en las paginas 1 y 2

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Konami's Boxing (Konami, RC-736) para MSX, 32768 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/boxing.trace.json: $(ROM) $(SRC)/boxing.entries $(SRC)/boxing.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/boxing.entries \
	        $(WORK)/boxing $(SRC)/boxing.nocode

trace: $(WORK)/boxing.trace.json

listado: $(WORK)/boxing.trace.json $(SRC)/boxing.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/boxing.trace.json \
	        $(SRC)/boxing.notes work/msx.sym $(SRC)/boxing.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/boxing.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/boxing.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/boxing.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/boxing.trace.json $(SRC)/boxing.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/boxing.entries $(SRC)/boxing.notes \
	        $(SRC)/boxing.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/boxing.asm

# LAS IMAGENES
#
# No hay ni una captura de pantalla en este repositorio. Cada lamina se monta
# ejecutando en Python los pasos del cartucho -tools/vram.py traduce las
# rutinas de carga y tools/pantallas.py las encadena-, y se REHACEN aqui: si
# una herramienta de dibujo se queda fuera de este target, la lamina se queda
# vieja sin que nadie proteste.
IMG = docs/img
imagenes: $(ROM)
	@mkdir -p $(IMG)
	python3 tools/pantallas.py $(ROM) $(ORG) $(IMG)

# Y la comprobacion de que esas imagenes son las de verdad: se deja correr el
# cartucho en openMSX, se vuelca su VRAM y se compara BYTE A BYTE. Mirar el
# dibujo no basta.
OPENMSX = C:/Program Files/openMSX/openmsx.exe
vram: $(ROM)
	@rm -rf work/omsx && mkdir -p work/omsx
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_vram.tcl
	"$(OPENMSX)" -machine Philips_VG_8020 -cart $(ROM) -script tools/omsx_menu.tcl
	@python3 tools/coteja_vram.py $(ROM) $(ORG) work/omsx

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; las dos portadas las
# monta make_web.py, que declara las cifras medidas de ESTE cartucho.
#
# Las imagenes se REHACEN aqui, no se copian a mano: si una herramienta de
# dibujo se queda fuera de este target, la lamina se queda vieja sin que nadie
# proteste.
web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py $(IMG) docs/index.html en
	python3 tools/make_web.py $(IMG) docs/es/index.html es
	@python3 tools/check_enlaces.py docs

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/boxing.trace.json $(WORK)/boxing.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes vram web clean
