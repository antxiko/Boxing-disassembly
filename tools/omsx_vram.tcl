# Vuelca la VRAM de Konami's Boxing en los instantes que importan.
#
# No hace falta jugar. El cartucho encadena solo presentacion -> menu ->
# "PUSH SPACE KEY" -> DEMOSTRACION, y la demostracion es la escena 2: ahi el
# boxeador de la izquierda lo lleva `decide_la_maquina` (0x4A6B) y el de la
# derecha el registro R (0x4836), asi que juegan solos los dos y el
# cuadrilatero se monta sin tocar una tecla.
#
# EL CUADRILATERO DE CADA RIVAL EN UN SOLO ARRANQUE. `monta_el_combate`
# (0x554B) saca TODO de (0xE207): el nombre de la tabla de 0x5661, las figuras
# de la de 0x52C9 y el cambio de color de 0x526F. Un punto de interrupcion en
# 0x554B -antes de que lo lea- escribe ahi el rival que toque, y el cartucho
# monta ESE combate con su propio codigo. No se falsea nada: se cambia un byte
# de partida, como haria un jugador llegando a ese rival.
#
# De cada instante salen dos ficheros: vram_NN.bin con los 16 KB tal cual e
# info_NN.txt con el estado del juego, para poder decir CONTRA QUE se compara.
#
# Trampas de Tcl ya pagadas en esta serie y respetadas aqui: nada de corchetes
# dentro de un `format`, el binario con -translation binary, y `debug
# read_block` en vez de `debug save_to_file`, que no existe.

set renderer none
set throttle off

set carpeta "work/omsx"
set rival 0

proc vuelca {nombre} {
    global carpeta
    set d [debug read_block VRAM 0 16384]
    set f [open [file join $carpeta "vram_$nombre.bin"] w]
    fconfigure $f -translation binary
    puts -nonewline $f $d
    close $f

    set f [open [file join $carpeta "info_$nombre.txt"] w]
    puts $f "tiempo [machine_info time]"
    puts $f "escena [debug read memory 0xE000]"
    puts $f "paso [debug read memory 0xE001]"
    puts $f "banderas [debug read memory 0xE002]"
    puts $f "rival [debug read memory 0xE207]"
    puts $f "stage [debug read memory 0xE208]"
    puts $f "asalto [debug read memory 0xE210]"
    puts $f "partidas [debug read memory 0xE051]"
    puts $f "columna_derecha [debug read memory 0xE23A]"
    puts $f "columna_izquierda [debug read memory 0xE25D]"
    puts $f "accion_derecha [debug read memory 0xE239]"
    puts $f "accion_izquierda [debug read memory 0xE25C]"
    close $f
}

# La presentacion, en el instante EXACTO en que el cartel acaba de subir: el
# `call pinta_texto` de 0x4140 es lo ultimo que hace el paso 1 de la escena 0,
# asi que un punto de interrupcion en 0x4143 -la instruccion de detras- cae
# justo ahi. Solo la primera vez, que la presentacion se repite en bucle.
set presentacion_hecha 0
debug set_bp 0x4143 {} {
    global presentacion_hecha
    if {$presentacion_hecha == 0} {
        set presentacion_hecha 1
        vuelca "presentacion"
    }
}

# Y cada rival, imponiendo (0xE207) justo antes de que `monta_el_combate` lo
# lea. El volcado va MEDIO segundo despues: ya estan subidos los patrones, el
# color y la tabla de nombres, y el combate todavia no ha empezado a moverse.
debug set_bp 0x554B {} {
    global rival
    if {$rival < 6} {
        if {$rival < 3} {
            debug write memory 0xE207 $rival
        } else {
            debug write memory 0xE207 [expr {16 + $rival - 3}]
        }
        after time 0.5 "vuelca rival$rival"
        incr rival
    } else {
        after time 1 exit
    }
}

# Y un cierre por si el cartucho no llega a los seis combates solo.
after time 900 exit
