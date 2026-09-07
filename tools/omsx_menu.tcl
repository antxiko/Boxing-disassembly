# Vuelca la VRAM del MENU, que necesita una pulsacion y por eso va aparte.
#
# `lee_el_menu` (0x4502) solo corre en la escena 7, la del "PUSH SPACE KEY", y
# de ahi salta a 0x4543, que monta el menu. Aqui se pulsa ESPACIO una vez por
# segundo desde el arranque hasta que 0x4543 se ejecuta, y se vuelca medio
# segundo despues. En ese momento la VRAM solo lleva encima lo de la
# presentacion, que es lo que hace la lamina comparable.

set renderer none
set throttle off

set carpeta "work/omsx"

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
    puts $f "opcion [debug read memory 0xE042]"
    close $f
}

proc pulsa_espacio {} {
    keymatrixdown 8 1
    after time 0.2 {keymatrixup 8 1}
    after time 1 pulsa_espacio
}

after time 1 pulsa_espacio

set hecho 0
debug set_bp 0x4543 {} {
    global hecho
    if {$hecho == 0} {
        set hecho 1
        after time 0.5 {vuelca "menu"}
        after time 2 exit
    }
}

after time 120 exit
