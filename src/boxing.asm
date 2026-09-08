; ==========================================================================
; KONAMI'S BOXING - Konami - MSX1 - cartucho RC-736 de 32 KB en las paginas 1 y 2
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x4091);
;   STATEMENT, DEVICE y TEXT a cero, y los seis bytes reservados tambien
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defb 041h,042h	; 4000
	defw 04091h,00000h,00000h,00000h	; 4002  -> L_4091 0x0000 0x0000 0x0000
	defb 000h,000h,000h,000h,000h,000h	; 400a

; ----------------------------------------------------------------------
; DATOS cabecera_del_game_master: la SEGUNDA cabecera, la vieja: "AB" 07 36 y
;   los 19 bytes que el Konami Game Master se lleva tal cual de 0x4012 a
;   0xD300
;   0x4010..0x4025  (21 bytes)
DATA_cabecera_del_game_master:
	defb 041h,042h	; 4010
	defb 007h,036h,000h,063h,000h,0e0h,002h,0e0h,000h,000h,051h,0e0h,000h,000h,000h,000h,000h,000h,008h	; 4012  .6.c......Q........

; ----------------------------------------------------------------------
; DATOS relleno_tras_la_cabecera: Un byte a cero entre la cabecera del Game
;   Master y la primera rutina
;   0x4025..0x4026  (1 bytes)
DATA_relleno_tras_la_cabecera:
	defb 000h	; 4025

; ======================================================================
; CODIGO 0x4026..0x411c  (246 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; EL ARMAZON
; ======================================================================
; Lo que este cartucho comparte con los demas Konami de la epoca. No es
; de oidas: comun_normalizado.py da 561 bytes en comun con Knightmare
; (RC-739) y 562 con The Goonies (RC-734), y el despachador cae hasta en
; la MISMA direccion que en Knightmare, 0x406C.
; ----------------------------------------------------------------------
escribe_una_casilla:		; Escribe A en el puerto de datos del VDP, fijando antes la direccion
	call prepara_la_escritura		;4026   ; A, al puerto de datos del VDP, fijando antes la direccion
	exx			;4029
	out (c),a		;402a
	exx			;402c
	ret			;402d
suma_a_hl:		; HL += A, sin signo
	add a,l			;402e   ; HL += A, sin signo; el `ret nc` se ahorra el acarreo
	ld l,a			;402f
	ret nc			;4030
	inc h			;4031
	ret			;4032
suma_a_de:		; DE += A, sin signo
	add a,e			;4033   ; lo mismo con DE
	ld e,a			;4034
	ret nc			;4035
	inc d			;4036
	ret			;4037
L_4038:
	ld a,(00006h)		;4038   ; el puerto de datos del VDP en C. Nadie llama aqui
	ld c,a			;403b
	ret			;403c

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El gancho de interrupcion. INIT lo cuelga de H.KEYI y se queda en un
; `jr $`, asi que TODO el juego pasa por aqui, una vez por cuadro.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
gancho_de_interrupcion:		; Lo que hace el cartucho en cada cuadro. INIT lo cuelga de H.KEYI (0xFD9A)
	call 0013eh		;403d   ; BIOS RDVDP - Reads VDP status register | leer el estado del VDP es lo que baja la peticion de interrupcion
	di			;4040
	call suena_el_cuadro		;4041   ; el sonido, siempre, aunque el cuadro anterior no haya acabado
	ld hl,0e005h		;4044   ; el cerrojo: si el cuadro anterior sigue dentro, no se entra otra vez
	bit 0,(hl)		;4047
	jr nz,L_4062		;4049
	inc (hl)			;404b   ; se echa el cerrojo
	ei			;404c   ; y a partir de aqui ya se puede interrumpir
	ld hl,0e300h		;404d
	exx			;4050
	call lee_los_mandos_de_uno		;4051   ; los dos juegos de sprites, uno en cada banco de registros
	ld hl,0e009h		;4054
	exx			;4057
	call lee_los_mandos_de_uno		;4058
	call avanza_el_reloj		;405b   ; el reloj y la escena que toque
	xor a			;405e
	ld (0e005h),a		;405f   ; y se levanta el cerrojo
L_4062:
	call 0013eh		;4062   ; BIOS RDVDP - Reads VDP status register
	or a			;4065
	di			;4066
	call m,suena_el_cuadro		;4067   ; si el VDP dice que hubo colision, el sonido otra vez
	ei			;406a
	ret			;406b

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El despachador. La tabla NO se le pasa: es la direccion de retorno, o
; sea las palabras que van justo detras del `call`.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
despacha:		; Salta a la entrada A de la tabla de palabras que sigue al `call`: saca de la pila la direccion de retorno, que ES la tabla
	add a,a			;406c   ; A por dos, que las entradas son palabras
	pop hl			;406d   ; la direccion de retorno ES la tabla
	call suma_a_hl		;406e
	ld e,(hl)			;4071   ; la entrada que toca, a HL
	inc hl			;4072
	ld d,(hl)			;4073
	ex de,hl			;4074
	jp (hl)			;4075   ; y se salta ahi sin volver

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El guion de rotulos: una palabra con la direccion de VRAM y detras los
; codigos de casilla. 0xFE cambia de sitio y 0xFF acaba. C lleva una
; mascara que se aplica a cada casilla, y de ahi salen las dos entradas:
; con 0xFF se escribe el rotulo y con 0x00 se escriben ceros, o sea que
; SE BORRA. Asi parpadea el "PUSH SPACE KEY".
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
borra_texto:		; Como pinta_texto pero con la mascara a 0x00: escribe ceros donde el otro escribe las casillas, o sea que BORRA el mismo rotulo
	ld c,000h		;4076   ; mascara a cero: borrar
	jr pinta_texto_con_mascara		;4078
pinta_texto:		; Guion de rotulos: palabra con la direccion de VRAM, codigos de casilla, 0xFE para cambiar de sitio y 0xFF para acabar
	ld c,0ffh		;407a   ; mascara a 0xFF: escribir
pinta_texto_con_mascara:		; El cuerpo comun a los dos: C ya trae la mascara
	ex de,hl			;407c
	ld e,(hl)			;407d   ; los dos primeros bytes son la direccion de VRAM
	inc hl			;407e
	ld d,(hl)			;407f
	ex de,hl			;4080
	inc de			;4081   ; y el guion sigue detras
byte_del_guion:		; Cada vuelta lee un codigo del guion
	ld a,(de)			;4082   ; el codigo de casilla que toca
	inc de			;4083
	ld b,a			;4084
	inc b			;4085   ; 0xFF: se acabo
	ret z			;4086
	inc b			;4087   ; 0xFE: cambia de sitio y vuelve a leer la direccion
	jr z,pinta_texto_con_mascara		;4088
	and c			;408a   ; aqui es donde la mascara decide si se escribe o se borra
	call escribe_una_casilla		;408b
	inc hl			;408e   ; la casilla siguiente
	jr byte_del_guion		;408f

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; INIT, la direccion que declara la cabecera "AB". Se ejecuta una vez.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
L_4091:
	di			;4091
	call 00138h		;4092   ; BIOS RSLREG - Reads the primary slot register | en que ranura primaria estamos
	rrca			;4095
	rrca			;4096
	and 003h		;4097
	ld c,a			;4099
	ld b,000h		;409a
	ld hl,0fcc1h		;409c   ; EXPTBL, para saber si la ranura esta expandida
	add hl,bc			;409f
	or (hl)			;40a0
	ld c,a			;40a1
	inc hl			;40a2
	inc hl			;40a3
	inc hl			;40a4
	inc hl			;40a5
	ld a,(hl)			;40a6
	and 00ch		;40a7
	or c			;40a9
	ld h,080h		;40aa
	call 00024h		;40ac   ; BIOS ENASLT - Switches to specified slot and page definitively | deja el cartucho fijo en la pagina 2
	di			;40af
	im 1		;40b0
	ld a,0c3h		;40b2   ; modo 1: la interrupcion entra por 0x0038 y de ahi a H.KEYI
	ld (0fd9ah),a		;40b4   ; un `jp` en H.KEYI (0xFD9A)...
	ld hl,gancho_de_interrupcion		;40b7   ; ...que apunta al gancho de 0x403D
	ld (0fd9bh),hl		;40ba
	ld sp,0e7ffh		;40bd   ; la pila, justo debajo de las variables
	ld hl,0e000h		;40c0   ; y las variables, a cero de golpe
	ld bc,007efh		;40c3
	call rellena_de_ceros		;40c6
	ld a,001h		;40c9
	ld (0e005h),a		;40cb   ; el cerrojo, echado, para que el primer cuadro no entre a medias
	call arranca_el_psg_y_el_vdp		;40ce   ; los registros del VDP y la pantalla en negro
	xor a			;40d1
	ld (0e005h),a		;40d2
	call 0013eh		;40d5   ; BIOS RDVDP - Reads VDP status register | se lee el VDP antes de abrir
	ei			;40d8
L_40D9:
	jr L_40D9		;40d9   ; y aqui se queda: lo demas pasa en la interrupcion

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El reloj y el reparto. Se llama una vez por cuadro desde el gancho.
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
avanza_el_reloj:		; Baja los tres temporizadores y despacha la escena
	ld hl,0e003h		;40db   ; el contador de cuadros, que casi todo el cartucho consulta
	inc (hl)			;40de
	ld a,(hl)			;40df
	and 01fh		;40e0   ; los tres temporizadores solo bajan una vez cada 32 cuadros
	jr nz,L_4102		;40e2
	ld a,(0e1ffh)		;40e4
	or a			;40e7
	jr z,L_40EE		;40e8
	dec a			;40ea
	ld (0e1ffh),a		;40eb
L_40EE:
	ld a,(0e1feh)		;40ee   ; (0xE1FE), el aviso de que el de la derecha ha pegado
	or a			;40f1
	jr z,L_40F8		;40f2   ; a cero no baja mas
	dec a			;40f4
	ld (0e1feh),a		;40f5   ; y uno menos cada cuadro
L_40F8:
	ld a,(0e22eh)		;40f8   ; (0xE22E)
	or a			;40fb
	jr z,L_4102		;40fc   ; a cero no baja mas
	dec a			;40fe
	ld (0e22eh),a		;40ff   ; y uno menos cada cuadro
L_4102:
	ld a,(0e002h)		;4102   ; con el bit 6 de (0xE002) puesto se vuelve a 0x419F al acabar...
	and 040h		;4105
	ld hl,0419fh		;4107
	jr nz,L_410F		;410a
	ld hl,04502h		;410c   ; ...y si no, a 0x4502
L_410F:
	ld bc,(0e000h)		;410f   ; (0xE000) es la escena y (0xE001) el paso dentro de ella
	ld a,c			;4113
	cp 003h		;4114   ; la escena 3 es la unica que no lleva vuelta de hoja
	jr z,L_4119		;4116
	push hl			;4118   ; la direccion de vuelta, a la pila
L_4119:
	call despacha		;4119   ; y a la escena que toque, de la tabla de once que va detras

; ----------------------------------------------------------------------
; DATOS tabla_de_las_escenas: Las ONCE escenas del juego, indexadas por
;   (0xE000). Va detras del unico `call 406Ch` del cartucho, que es lo que
;   fija su tamano: la entrada mas baja, 0x4132, es la primera escena
;   0x411c..0x4132  (22 bytes)
DATA_tabla_de_las_escenas:
	defw 04132h,04177h,04187h,04270h,041a0h,041c1h,041c4h,041fah	; 411c
	defw 0422bh,042a2h,041f0h	; 412c  -> L_422B L_42A2 L_41F0

; ======================================================================
; CODIGO 0x4132..0x432c  (506 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; LAS ONCE ESCENAS
; ======================================================================
; (0xE000) dice en cual estamos y (0xE001) el paso dentro de ella. La
; tabla de 0x411C reparte, y casi todas empiezan con `djnz` encadenados:
; el paso llega en B, y cada `djnz` se come uno.
; ----------------------------------------------------------------------
L_4132:
	djnz L_4146		;4132   ; paso 1: bajar el cartel
	ld a,(0e003h)		;4134   ; el contador de cuadros
	rra			;4137   ; uno de cada dos
	ret nc			;4138
	call sube_el_cartel		;4139   ; baja el cartel un paso; vuelve con Z cuando ya no queda
	ret nz			;413c
	ld de,05bbch		;413d   ; y al acabar, el rotulo de KONAMI SOFTWARE
	call pinta_texto		;4140
	xor a			;4143   ; el paso siguiente arranca en cero
	jr L_4198		;4144
L_4146:
	djnz L_4159		;4146   ; paso 2: esperar
	ld hl,0e004h		;4148   ; el temporizador de la escena
	dec (hl)			;414b
	ret nz			;414c
	ld de,05d59h		;414d   ; al agotarse, el guion corto de 0x5D59
	call descomprime_desde_palabra		;4150
	xor a			;4153
	ld (0e00ah),a		;4154
	jr L_419B		;4157
L_4159:
	djnz L_4162		;4159   ; paso 3
	call monta_una_columna_del_fondo		;415b   ; si devuelve acarreo, todavia no toca
	ret c			;415e
	xor a			;415f
	jr L_41AC		;4160
L_4162:
	call apaga_la_pantalla		;4162   ; paso 4 en adelante
	ld bc,0e407h		;4165   ; R4 = 0x07: los patrones en 0x2000
	call 00047h		;4168   ; BIOS WRTVDP - Writes data in the VDP-register
	call baja_el_telon		;416b   ; espera al gatillo; vuelve con el signo puesto si no lo hay
	ret p			;416e
	call monta_la_presentacion		;416f
	call enciende_la_pantalla		;4172
	jr L_419B		;4175
L_4177:
	call enciende_la_pantalla		;4177   ; la escena 1
	ld hl,0e004h		;417a   ; su temporizador
	dec (hl)			;417d
	jp nz,L_43D8		;417e
	xor a			;4181
	ld (0e210h),a		;4182   ; borra la marca de 0xE210
	jr L_41AA		;4185
L_4187:
	djnz L_418F		;4187   ; la escena 2 es el juego: paso 1, montar
	jp L_4338		;4189   ; y de ahi en adelante, el bucle de cada cuadro
L_418C:
	xor a			;418c
	jr L_41E6		;418d
L_418F:
	call baja_el_telon		;418f   ; espera al gatillo
	ret p			;4192
	call prepara_y_monta_el_combate		;4193
	ld a,020h		;4196   ; 0x20 cuadros de espera
L_4198:
	ld (0e004h),a		;4198   ; el temporizador de la escena
L_419B:
	ld hl,0e001h		;419b   ; y un paso mas
	inc (hl)			;419e
	ret			;419f
L_41A0:
	djnz L_41B8		;41a0   ; la escena 4
	ld hl,0e004h		;41a2
	dec (hl)			;41a5
	ret nz			;41a6
	call monta_el_combate		;41a7
L_41AA:
	ld a,020h		;41aa   ; 0x20 cuadros
L_41AC:
	ld (0e004h),a		;41ac
L_41AF:
	ld hl,0e000h		;41af   ; a la escena siguiente
	inc (hl)			;41b2
L_41B3:
	xor a			;41b3   ; y su paso, a cero
	ld (0e001h),a		;41b4
	ret			;41b7
L_41B8:
	call baja_el_telon		;41b8   ; el telon, un paso mas
	ret p			;41bb   ; mientras siga bajando, nada
	ld a,001h		;41bc   ; a la escena 2, la demostracion
	inc a			;41be
	jr L_4198		;41bf
L_41C1:
	jp L_4338		;41c1   ; la escena 5 es el bucle de cada cuadro otra vez
L_41C4:
	ld a,(0e313h)		;41c4   ; la escena 6 espera a que 0xE313 se calle
	or a			;41c7
	ret nz			;41c8
	call apaga_la_pantalla		;41c9
	call baja_el_telon		;41cc
	ret p			;41cf
	call monta_la_letra		;41d0
	call enciende_la_pantalla		;41d3
	ld de,05bafh		;41d6   ; "GAME  OVER"
	call pinta_texto		;41d9
	ld a,006h		;41dc
	ld (0e000h),a		;41de   ; y se pasa a la escena 6... que es esta misma
	xor a			;41e1
	jr L_41AC		;41e2
L_41E4:
	ld a,004h		;41e4   ; la escena 4, desde fuera
L_41E6:
	ld (0e000h),a		;41e6   ; la escena
	ld a,020h		;41e9   ; y 32 cuadros de temporizador
	ld (0e004h),a		;41eb
	jr L_41B3		;41ee
L_41F0:
	call borra_la_zona_de_trabajo		;41f0   ; la escena 10
	ld a,004h		;41f3
	ld (0e000h),a		;41f5
	jr L_41AF		;41f8
L_41FA:
	call lee_el_menu		;41fa   ; la escena 7
	ld a,(0e000h)		;41fd
	cp 007h		;4200   ; la 7 es la unica que mira su temporizador aqui
	ld de,0e002h		;4202
	jr z,espera_y_quita_dos_bits		;4205
	ld a,(de)			;4207
	and 0beh		;4208   ; apaga los bits 0 y 6 de (0xE002)
	ld (de),a			;420a
	pop de			;420b
	ld a,02bh		;420c   ; y suena el 0x2B
	jp pide_un_sonido		;420e

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
espera_y_quita_dos_bits:
	ld hl,0e004h		;4211   ; el temporizador de la escena
	dec (hl)			;4214
	ret nz			;4215   ; mientras corra, nada
	ld a,(de)			;4216   ; y al acabar se le quitan los bits 0 y 6 a (DE)
	and 0beh		;4217
	ld (de),a			;4219
	jp L_418C		;421a   ; y al paso siguiente
borra_de_0xe210_en_adelante:
	ld hl,0e210h		;421d   ; 0xFF bytes desde 0xE210, a cero
	ld bc,000ffh		;4220   ; los 0xFF de 0xE210 a 0xE30F
rellena_de_ceros:		; Pone a cero BC+1 bytes desde HL, con el `ldir` que se copia a si mismo
	ld (hl),000h		;4223   ; el `ldir` que se copia a si mismo: HL a cero, DE = HL+1
	push hl			;4225
	pop de			;4226
	inc de			;4227
	ldir		;4228
	ret			;422a
L_422B:
	ld a,(0e321h)		;422b   ; la escena 8 espera a que 0xE321 se calle
	or a			;422e
	ret nz			;422f
	ld ix,0e206h		;4230   ; (0xE206) y (0xE207): el asalto y el rival
	ld a,(ix+001h)		;4234
	ld b,a			;4237
	and 003h		;4238   ; los dos de abajo
	inc b			;423a   ; un rival mas
	cp 002h		;423b   ; con el 2...
	jr nz,L_4245		;423d
	ld a,010h		;423f   ; ...se salta al siguiente grupo de dieciseis
	add a,b			;4241
	and 0f0h		;4242
	ld b,a			;4244
L_4245:
	ld (ix+001h),b		;4245   ; el rival siguiente
	inc (ix+000h)		;4248   ; y un asalto mas
	ld hl,0e050h		;424b   ; (0xE050), la cuenta de partidas
	inc (hl)			;424e
	ld a,(0e218h)		;424f   ; con menos de cinco, dos pasos en vez de uno
	cp 005h		;4252
	jr nc,L_425A		;4254
	inc (hl)			;4256
	inc (ix+000h)		;4257
L_425A:
	inc hl			;425a
	ld a,(hl)			;425b   ; y la cuenta de 0xE051, en BCD
	add a,001h		;425c
	daa			;425e
	ld (hl),a			;425f
	xor a			;4260   ; (0xE00D) a cero
	ld (0e00dh),a		;4261
	call borra_de_0xe210_en_adelante		;4264   ; borra la zona de trabajo
	jp L_41AF		;4267
L_426A:
	call prepara_la_partida		;426a   ; se prepara otra partida
	jp L_41AA		;426d
L_4270:
	djnz L_4289		;4270   ; la escena 3
	ld hl,0e004h		;4272   ; el temporizador de la escena
	dec (hl)			;4275
	jr z,L_426A		;4276
	bit 3,(hl)		;4278   ; el bit 3 del temporizador hace parpadear
	jp z,L_43D0		;427a
	call donde_va_el_cursor		;427d   ; el cursor
	inc hl			;4280   ; dos casillas mas alla
	inc hl			;4281
	ld bc,00019h		;4282   ; y veinticinco a cero
	xor a			;4285
	jp rellena_la_vram		;4286
L_4289:
	ld a,0a2h		;4289   ; suena el 0xA2 y se esperan 0x50 cuadros
	call pide_un_sonido		;428b
	ld a,050h		;428e
	ld (0e004h),a		;4290
L_4293:
	call borra_la_pantalla		;4293
	call monta_la_presentacion_entera		;4296   ; la presentacion entera
	ld bc,05c5dh		;4299   ; el guion de 0x5C5D
	call pinta_el_cursor		;429c   ; el guion de 0x5C5D
	jp L_419B		;429f
L_42A2:
	ld a,(0e008h)		;42a2   ; la escena 9
	ld b,a			;42a5   ; lo que dio un mando
	ld a,(0e2ffh)		;42a6   ; lo que dio el otro mando
	or b			;42a9   ; los dos juntos
	cp 010h		;42aa   ; con 0x10 o mas, se acabo
	jr c,L_42B9		;42ac
	call apaga_la_pantalla		;42ae   ; la pantalla, apagada
	ld c,0cfh		;42b1   ; el color 0xCF
	call pinta_los_tres_sprites_con_el_color_de_c		;42b3   ; el sonido 0xCF
	jp L_41E4		;42b6
L_42B9:
	ld de,05b18h		;42b9   ; "PUSH SPACE KEY"...
	ld hl,0407ah		;42bc
	ld a,(0e003h)		;42bf   ; ...que parpadea con el bit 4 del contador de cuadros:
	bit 4,a		;42c2
	jr z,L_42C9		;42c4
	ld hl,04076h		;42c6   ; con el bit puesto, la mascara a cero, o sea BORRAR
L_42C9:
	jp (hl)			;42c9   ; y al pintor que toque
monta_la_presentacion:
	call monta_el_cartel		;42ca   ; el cartel de KONAMI
	call monta_la_letra		;42cd   ; y la letra
monta_la_fuente_en_0x3600:
	ld hl,03600h		;42d0   ; la fuente, a la VRAM en 0x3600
	ld de,059c4h		;42d3
	call descomprime		;42d6
	ld a,070h		;42d9   ; y su color, blanco sobre negro, en 0x1600
	ld hl,01600h		;42db
	ld bc,00180h		;42de
	call rellena_la_vram		;42e1
monta_el_fondo_de_la_presentacion:
	ld de,05bd6h		;42e4   ; el guion gordo de la presentacion
	call descomprime_desde_palabra		;42e7
	ld hl,04480h		;42ea
	ld bc,00380h		;42ed
	ld a,060h		;42f0
	jp rellena_la_vram		;42f2
prepara_la_partida:
	ld hl,0e049h		;42f5   ; la zona de trabajo, a cero
	ld bc,002b6h		;42f8
	call rellena_de_ceros		;42fb
	ld hl,0e207h		;42fe   ; (0xE207), el rival, y (0xE208)
	ld c,041h		;4301   ; (0xE208) sera 0x41...
	ld a,(0e002h)		;4303   ; el bit 4 de (0xE002) cambia el reparto
	bit 4,a		;4306
	jr z,L_431A		;4308
	inc c			;430a   ; ...o 0x42 con el bit 4 puesto
	cp 071h		;430b   ; con el 0x71 exacto...
	ld a,003h		;430d   ; ...el rival 1 y (0xE206) a cero
	ld b,010h		;430f   ; y si no, el 0x10 y un 3
	jr nz,L_4316		;4311
	ld b,001h		;4313
	xor a			;4315
L_4316:
	ld (hl),b			;4316
	ld (0e206h),a		;4317   ; (0xE206), lo duro que juega
L_431A:
	inc hl			;431a
	ld (hl),c			;431b   ; (0xE208), en su sitio
	ld hl,0432ch		;431c   ; los tres registros de cuatro, a 0xE100
	ld de,0e100h		;431f
	ld bc,0000ch		;4322
	ldir		;4325
	ld hl,0e051h		;4327   ; (0xE051), una partida mas
	inc (hl)			;432a
	ret			;432b

; ----------------------------------------------------------------------
; DATOS tres_registros_de_cuatro: Tres registros de cuatro bytes que 0x431C
;   copia con `ldir`; los dos primeros de cada uno son iguales (0xC058)
;   0x432c..0x4338  (12 bytes)
DATA_tres_registros_de_cuatro:
	defb 058h,0c0h,09ch,004h	; 432c
	defb 058h,0c0h,0a0h,001h	; 4330
	defb 058h,0c0h,0a4h,00ah	; 4334

; ======================================================================
; CODIGO 0x4338..0x4429  (241 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; EL BUCLE DE CADA CUADRO. Las escenas 2 y 5 acaban aqui, y esto es todo
; lo que el juego hace mientras se boxea: una llamada detras de otra.
; ----------------------------------------------------------------------
L_4338:
	call toca_la_campana		;4338   ; el reparto de los sprites
	call prepara_el_dibujo		;433b   ; los registros de dibujo
	call pinta_al_de_la_izquierda		;433e   ; el de la izquierda
	call pinta_la_marca_del_asalto		;4341   ; el marcador de arriba
	call pinta_las_figurillas		;4344   ; las figurillas del asalto
	call pinta_al_arbitro		;4347   ; los mandos
	call el_cuadro_del_de_la_derecha		;434a
	call el_cuadro_del_de_la_izquierda		;434d
	ld a,(0e22dh)		;4350   ; (0xE22D) marca que hay algo pendiente
	or a			;4353
	ret z			;4354   ; sin nada pendiente, se acaba aqui
	call mira_si_entra_el_golpe		;4355   ; los golpes que entran
	call aplica_los_golpes_encajados		;4358   ; el castigo
	call pinta_las_barras		;435b   ; las barras
	jp lleva_el_asalto		;435e
prepara_y_monta_el_combate:
	call prepara_la_partida		;4361
	ld hl,0e206h		;4364   ; (0xE206), lo duro que juega
	ld (hl),b			;4367   ; con lo que traiga B
	jp monta_el_combate		;4368   ; y a montar el cuadrilatero

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El telon: borra la pantalla de una columna por cuadro, de derecha a
; izquierda, y devuelve el signo puesto mientras siga bajando.
; ----------------------------------------------------------------------
baja_el_telon:
	ld hl,0e003h		;436b   ; los dos contadores, 0xE003 y 0xE004
	dec (hl)			;436e   ; el contador de cuadros
	inc hl			;436f
	dec (hl)			;4370
	ret m			;4371   ; con el segundo por debajo de cero, se acabo
	ld a,(hl)			;4372
	ld h,038h		;4373   ; la columna que toca, contada al reves
	xor 01fh		;4375
	ld l,a			;4377
	ld b,018h		;4378   ; las 24 filas
	xor a			;437a
L_437B:
	call escribe_una_casilla		;437b   ; casilla a cero
	ld de,00020h		;437e   ; la fila de abajo esta 0x20 mas alla
	add hl,de			;4381
	djnz L_437B		;4382

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
apaga_todos_los_sprites:
	ld hl,03b00h		;4384   ; los 0x80 bytes de la tabla de sprites...
	ld a,0cfh		;4387   ; ...a 0xCF, que es una Y fuera de la pantalla: los apaga todos
	ld bc,00080h		;4389
	call rellena_la_vram		;438c   ; a la vez, los 128 bytes
	xor a			;438f   ; y sale con Z
	ret			;4390
monta_la_presentacion_entera:
	call monta_el_fondo_de_la_presentacion		;4391   ; el fondo de la presentacion
	xor a			;4394   ; (0xE00A), la columna, a cero
	ld (0e00ah),a		;4395
L_4398:
	call monta_una_columna_del_fondo		;4398   ; y se monta a trozos hasta que deje de pedir mas
	jr c,L_4398		;439b
	ret			;439d

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Monta el fondo de la presentacion de DIECISEIS en dieciseis: cada
; llamada pone una columna de ocho casillas y devuelve acarreo mientras
; quede. (0xE00A) lleva la cuenta.
; ----------------------------------------------------------------------
monta_una_columna_del_fondo:
	ld bc,0e107h		;439e   ; R1 = 0xE2: pantalla encendida y sprites de 16x16
	call 00047h		;43a1   ; BIOS WRTVDP - Writes data in the VDP-register | y R1 con el bit 6: encendida
	ld hl,0e00ah		;43a4   ; por que columna vamos
	ld a,(hl)			;43a7   ; la columna
	inc (hl)			;43a8   ; y la siguiente para la proxima
	cp 010h		;43a9   ; pasadas dieciseis, el rotulo y a otra cosa
	jr nc,L_43D0		;43ab
	ld de,03808h		;43ad   ; la fila 0, columna 8
	ld c,a			;43b0   ; la columna, a C
	add a,e			;43b1   ; la columna, sumada
	ld e,a			;43b2
	ld b,c			;43b3   ; y a B
	inc b			;43b4
	xor a			;43b5
L_43B6:
	add a,007h		;43b6   ; siete por columna
	djnz L_43B6		;43b8
	add a,089h		;43ba   ; mas 0x89: de ahi sale el primer codigo de casilla
	ld c,a			;43bc   ; el codigo, a C
	ld b,008h		;43bd   ; ocho casillas hacia abajo
	xor a			;43bf   ; desde cero
L_43C0:
	ex de,hl			;43c0
	call escribe_una_casilla		;43c1   ; la casilla
	ex de,hl			;43c4
	ld a,020h		;43c5   ; la de abajo, 0x20 mas alla
	call suma_a_de		;43c7
	ld a,c			;43ca   ; el codigo de casilla
	inc c			;43cb   ; y la siguiente, una mas
	djnz L_43C0		;43cc
	scf			;43ce   ; acarreo: todavia queda
	ret			;43cf
L_43D0:
	ld de,05b29h		;43d0   ; al acabar, el rotulo de la presentacion
	call pinta_texto		;43d3   ; se pinta
	xor a			;43d6   ; y sale sin acarreo: no queda nada
	ret			;43d7
L_43D8:
	ld hl,0e004h		;43d8   ; el temporizador de la escena
	ld bc,05c5dh		;43db   ; las dos casillas del cursor
	bit 3,(hl)		;43de   ; su bit 3
	jr nz,pinta_el_cursor		;43e0
borra_el_cursor:
	ld bc,00000h		;43e2   ; y con el a cero, dos ceros: se borra
pinta_el_cursor:
	call donde_va_el_cursor		;43e5   ; dos casillas seguidas, la de 0xE042
	ld a,b			;43e8   ; la primera...
	call escribe_una_casilla		;43e9
	ld a,c			;43ec   ; ...y la segunda al lado
	inc hl			;43ed
	call escribe_una_casilla		;43ee
	ret			;43f1
donde_va_el_cursor:
	ld a,(0e042h)		;43f2   ; (0xE042) entre cuatro, mas cinco, en la fila 0x3A
	add a,014h		;43f5   ; mas veinte...
	rrca			;43f7   ; ...entre cuatro
	rrca			;43f8
	ld l,a			;43f9
	ld h,07ah		;43fa   ; fila 0x1A de la tabla de nombres
	ret			;43fc

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El arranque de verdad: calla el PSG, apaga la VRAM entera y pone los
; registros del VDP.
; ----------------------------------------------------------------------
arranca_el_psg_y_el_vdp:
	ld a,007h		;43fd   ; el registro 7 del PSG: el mezclador
	ld e,0b8h		;43ff
	call 00093h		;4401   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,0b8h		;4404
	call escribe_el_mezclador		;4406   ; y el motor de sonido se entera
	ld a,02bh		;4409   ; el sonido 0x2B, que es el silencio
	call pide_un_sonido		;440b
	ld de,00000h		;440e   ; los 16 KB de VRAM, a cero
	ld bc,04000h		;4411
	xor a			;4414
	call rellena_la_vram		;4415
pon_los_registros_del_vdp:		; Los ocho registros del VDP, de la tabla de 0x4429
	ld hl,04429h		;4418   ; los ocho registros salen de la tabla de 0x4429
	ld d,008h		;441b
	ld c,000h		;441d
L_441F:
	ld b,(hl)			;441f   ; uno por vuelta, R0 a R7
	call 00047h		;4420   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;4423
	inc c			;4424
	dec d			;4425
	jr nz,L_441F		;4426
	ret			;4428

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros que 0x4418 escribe en orden. R2
;   = 0x0E pone los nombres en 0x3800; R3 = 0x7F y R4 = 0x07 ponen los COLORES
;   en 0x0000 y los PATRONES en 0x2000, o sea la VRAM al reves de lo habitual
;   0x4429..0x4431  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e4h	; 4429  .....v..

; ======================================================================
; CODIGO 0x4431..0x4563  (306 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; EL VDP, LOS MANDOS Y LA VRAM
; ======================================================================
; El reparto de la VRAM va AL REVES de lo habitual, y sale de la tabla de
; 0x4429: colores en 0x0000, patrones en 0x2000, nombres en 0x3800,
; patrones de sprite en 0x1800 y atributos en 0x3B00.
; ----------------------------------------------------------------------
enciende_la_pantalla:
	ld bc,0e201h		;4431   ; R1 = 0xE2: pantalla encendida
L_4434:
	jp 00047h		;4434   ; BIOS WRTVDP - Writes data in the VDP-register
apaga_la_pantalla:
	ld bc,0a201h		;4437   ; R1 = 0xA2: pantalla APAGADA, para tocar la VRAM sin que se vea
	jr L_4434		;443a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Los mandos, por el PSG: el registro 15 elige la fila y el 14 la lee.
; El bit 7 de (0xE002) alterna entre los dos puertos, o sea entre los
; dos jugadores.
; Lee UN mando por el PSG. El bit 7 de (0xE002) alterna en cada llamada,
; y con el se elige el puerto: 0x8F es el 1 y 0xCF el 2. Como el gancho
; de interrupcion llama dos veces por cuadro, el bit vuelve solo a donde
; estaba. Devuelve arriba, abajo, izquierda, derecha y los dos botones
; en los bits 0 a 5.
; ----------------------------------------------------------------------
lee_el_mando:
	ld hl,0e002h		;443c   ; el bit 7 de (0xE002) dice a quien le toca
	ld a,(hl)			;443f   ; el byte de banderas de la partida
	xor 080h		;4440   ; cambia de puerto en cada llamada
	ld (hl),a			;4442   ; y se deja cambiado para la proxima
	bit 7,(hl)		;4443   ; puesto quiere decir puerto 2
	ld e,08fh		;4445   ; 0x8F para el puerto 1...
	jr z,lee_un_puerto_del_psg		;4447
	set 6,e		;4449   ; ...y con el bit 6 puesto, para el 2
lee_un_puerto_del_psg:
	ld a,00fh		;444b   ; registro 15: elegir
	call 00093h		;444d   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4450   ; registro 14: leer
	di			;4452
	call 00096h		;4453   ; BIOS RDPSG - Reads value from PSG-register
	ei			;4456   ; el PSG no se puede tocar con la interrupcion suelta
	cpl			;4457   ; los bits llegan al reves
	and 03fh		;4458   ; y solo interesan los seis de abajo
	ret			;445a   ; con un bit por direccion y dos botones

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Junta lo que dicen el mando y el teclado, y guarda lo pulsado ahora
; junto a lo que se acaba de pulsar en este cuadro.
; Junta el mando y el teclado en un solo byte y lo reparte en los tres
; que HL' trae detras: (HL'-2) la lectura del cuadro anterior, (HL'-1) lo
; que se acaba de pulsar y (HL') lo que sigue pulsado. El gancho de
; interrupcion lo llama con HL'=0xE300 y con HL'=0xE009, o sea una vez
; por boxeador.
; ----------------------------------------------------------------------
lee_los_mandos_de_uno:
	call lee_el_mando		;445b   ; el mando
	push af			;445e
	call lee_el_teclado		;445f   ; y el teclado
	exx			;4462   ; el bloque de los tres bytes viaja en HL'
	ld d,a			;4463
	pop af			;4464
	or d			;4465   ; los dos a la vez
	ld d,a			;4466
	and 020h		;4467   ; el segundo boton...
	rrca			;4469   ; ...se suma al primero, que es el bit 4
	or d			;446a
	and 01fh		;446b   ; cuatro direcciones y un boton
	ld b,a			;446d
	and 00ch		;446e   ; hay izquierda o derecha?
	ld a,b			;4470   ; la lectura, otra vez
	jr z,L_4475		;4471
	and 03ch		;4473   ; con una diagonal, se dejan las dos direcciones
L_4475:
	ld b,a			;4475
	ld a,l			;4476   ; el bloque de 0xE009 acaba en 9, el de 0xE300 en 0
	or a			;4477
	ld a,b			;4478   ; y de vuelta a la lectura
	jr z,L_4485		;4479   ; al primero no se le hace nada
	cp 014h		;447b   ; arriba+izquierda y arriba+derecha se corrigen
	jr z,L_4483		;447d
	cp 018h		;447f   ; ...o golpe+derecha
	jr nz,L_4485		;4481
L_4483:
	xor 00ch		;4483   ; ...se cambian el uno por el otro: el segundo boxeador mira al reves
L_4485:
	ld d,a			;4485
	dec hl			;4486   ; la lectura del cuadro anterior
	dec hl			;4487
	cp (hl)			;4488   ; lo de antes, para saber que es nuevo
	ld (hl),a			;4489   ; y se guarda la de ahora
	inc hl			;448a
	jr nz,L_44A4		;448b   ; si ha cambiado, todavia no vale: hace falta que repita
	inc hl			;448d
	ld d,a			;448e   ; lo ha repetido: esta vez si vale
	ld c,(hl)			;448f   ; lo que se dio por bueno la ultima vez
	ld (hl),a			;4490   ; y pasa a ser lo ultimo dado por bueno
	dec hl			;4491
	bit 4,c		;4492   ; llevaba el boton puesto?
	jr z,L_44A6		;4494
	ld a,c			;4496   ; si era el boton a secas...
	cp 010h		;4497
	jr z,L_44A0		;4499
	ld a,d			;449b   ; ...y ahora tambien, no es nuevo
	cp 010h		;449c
	jr z,L_44A4		;449e
L_44A0:
	ld a,d			;44a0   ; y si no ha cambiado nada, tampoco
	cp c			;44a1
	jr nz,L_44A6		;44a2
L_44A4:
	ld d,000h		;44a4   ; nada nuevo este cuadro
L_44A6:
	ld (hl),d			;44a6   ; lo nuevo va a (HL'-1)
	ret			;44a7

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El teclado, con el mismo reparto de bits que el mando. Cada boxeador
; tiene su juego de teclas, y los elige el mismo bit 7 de (0xE002).
; ----------------------------------------------------------------------
lee_el_teclado:
	ld hl,0e002h		;44a8   ; el mismo bit que eligio el puerto del mando
	bit 7,(hl)		;44ab
	jr nz,el_segundo_juego_de_teclas		;44ad   ; puesto: el segundo juego de teclas
	ld a,007h		;44af   ; fila 7 del teclado
	call lee_una_fila_del_teclado		;44b1
	rrca			;44b4   ; su bit 6 es SELECT...
	and 020h		;44b5   ; ...que hace de segundo boton
	ld e,a			;44b7
	ld a,008h		;44b8   ; fila 8: el cursor, y ESPACIO en el bit 0
	call lee_una_fila_del_teclado		;44ba
	rrca			;44bd   ; dos a la derecha, que las teclas no caen donde el mando
	rrca			;44be
	ld b,a			;44bf
	and 004h		;44c0   ; IZQUIERDA
	or e			;44c2
	ld c,a			;44c3
	ld a,b			;44c4
	rrca			;44c5
	rrca			;44c6
	ld b,a			;44c7
	and 018h		;44c8   ; DERECHA, y ESPACIO como boton
	or c			;44ca
	ld c,a			;44cb
	ld a,b			;44cc
	rrca			;44cd   ; y dos mas
	and 003h		;44ce   ; ARRIBA y ABAJO
	or c			;44d0   ; todo junto
	ret			;44d1
el_segundo_juego_de_teclas:
	ld a,005h		;44d2   ; fila 5: la S en el bit 0
	call lee_una_fila_del_teclado		;44d4
	and 001h		;44d7   ; solo la S
	rlca			;44d9   ; la S es IZQUIERDA
	rlca			;44da
	ld e,a			;44db
	ld a,006h		;44dc   ; fila 6: SHIFT en el bit 0
	call lee_una_fila_del_teclado		;44de
	rrca			;44e1   ; el bit 0 al acarreo
	jr nc,L_44E6		;44e2
	set 4,e		;44e4   ; SHIFT es el boton
L_44E6:
	ld a,003h		;44e6   ; fila 3: C, D, E y F en los bits 0 a 3
	call lee_una_fila_del_teclado		;44e8
	rrca			;44eb   ; el bit 0 al acarreo: la C
	jr nc,L_44F0		;44ec
	set 1,e		;44ee   ; la C es ABAJO
L_44F0:
	rrca			;44f0
	rrca			;44f1   ; la D queda en medio y no se usa
	jr nc,L_44F6		;44f2   ; la E es ARRIBA
	set 0,e		;44f4
L_44F6:
	rrca			;44f6   ; y una mas
	jr nc,L_44FB		;44f7   ; la F es DERECHA
	set 3,e		;44f9
L_44FB:
	ld a,e			;44fb   ; las cuatro son el rombo alrededor de la D
	ret			;44fc
lee_una_fila_del_teclado:
	call 00141h		;44fd   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4500   ; la matriz devuelve los bits al reves
	ret			;4501

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El menu. Aqui no se reparte por jugador: valen los dos mandos y el
; teclado a la vez, y el bloque de trabajo es (0xE040) y (0xE041).
; ----------------------------------------------------------------------
lee_el_menu:
	ld e,08fh		;4502   ; el puerto 1...
	call lee_un_puerto_del_psg		;4504
	ld d,a			;4507
	ld e,0cfh		;4508   ; ...y el puerto 2
	call lee_un_puerto_del_psg		;450a
	or d			;450d
	ld d,a			;450e
	call lee_el_teclado		;450f   ; y el teclado encima
	or d			;4512
	ld hl,0e040h		;4513   ; el bloque del menu, que no es de nadie en concreto
	ld c,(hl)			;4516   ; lo de antes
	ld (hl),a			;4517   ; y lo de ahora en su sitio
	inc hl			;4518
	ld (hl),c			;4519   ; lo anterior queda en 0xE041
	ld b,a			;451a
	xor c			;451b   ; lo que ha cambiado...
	and b			;451c   ; solo lo que se acaba de pulsar
	ret z			;451d   ; si no hay nada nuevo, no hay nada que hacer
	ld b,a			;451e
	xor a			;451f
	ld (0e004h),a		;4520   ; el temporizador de la escena, a cero
	inc a			;4523
	ld hl,0e000h		;4524   ; estamos en la escena 1, la del menu?
	cp (hl)			;4527
	jr nz,L_4543		;4528   ; si no, es la portada: entrar al menu
	ld a,b			;452a
	cp 010h		;452b   ; sin el boton, se mueve la eleccion
	jr c,mueve_la_eleccion		;452d
	ld hl,04563h		;452f   ; la tabla de 0x4563
	ld a,(0e042h)		;4532   ; la opcion elegida, de 0 a 3
	call suma_a_hl		;4535
	ld a,(hl)			;4538   ; el byte que le toca
	ld (0e002h),a		;4539   ; su byte de flags, que manda el resto de la partida
	ld hl,00003h		;453c   ; escena 3, paso 0
	ld (0e000h),hl		;453f
	ret			;4542
L_4543:
	ld (hl),a			;4543   ; a la escena 1
	call monta_la_fuente_en_0x3600		;4544   ; el marco del menu
	call monta_la_letra		;4547   ; los patrones del texto
	jp L_4293		;454a   ; y el cartel
mueve_la_eleccion:
	push bc			;454d
	call borra_el_cursor		;454e   ; borra el cursor de donde estaba
	pop af			;4551   ; lo que se acaba de pulsar
	ld hl,0e042h		;4552   ; la opcion
	ld b,(hl)			;4555
	rra			;4556   ; arriba
	jr nc,L_455A		;4557
	dec b			;4559
L_455A:
	rra			;455a   ; abajo
	jr nc,L_455E		;455b
	inc b			;455d
L_455E:
	ld a,b			;455e
	and 003h		;455f   ; cuatro opciones, y da la vuelta
	ld (hl),a			;4561
	ret			;4562

; ----------------------------------------------------------------------
; DATOS banderas_de_las_cuatro_opciones: El byte de banderas que deja cada
;   opcion del menu en (0xE002): 0x40, 0x50, 0x61, 0x71. El bit 0 dice que
;   juegan DOS y el bit 4 que se juega la variante dura
;   0x4563..0x4567  (4 bytes)
DATA_banderas_de_las_cuatro_opciones:
	defb 040h,050h,061h,071h	; 4563

; ======================================================================
; CODIGO 0x4567..0x465c  (245 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Lo que escribe en la VRAM. Todo pasa por prepara_la_escritura, que deja
; el puerto de datos del VDP en C', asi que el bucle no vuelve a tocar el
; puerto de direcciones.
; ----------------------------------------------------------------------
borra_la_pantalla:
	call apaga_todos_los_sprites		;4567   ; los sprites, fuera
	ld hl,07800h		;456a   ; la tabla de nombres, 0x3800 en 14 bits
	ld bc,00300h		;456d   ; las 768 casillas
	xor a			;4570   ; a cero
rellena_la_vram:		; Escribe A en BC posiciones de VRAM desde HL
	call prepara_la_escritura		;4571
L_4574:
	ex af,af'			;4574   ; se entra aqui con el byte ya en A'
L_4575:
	ex af,af'			;4575
	exx			;4576   ; el puerto de datos vive en C'
	out (c),a		;4577
	exx			;4579
	ex af,af'			;457a
	dec bc			;457b   ; una casilla menos
	ld a,b			;457c
	or c			;457d   ; hasta que no quede ninguna
	jr nz,L_4575		;457e
	ex af,af'			;4580
	ret			;4581
saca_el_siguiente_y_escribe:
	ld a,(de)			;4582   ; este si avanza en la tabla
	inc de			;4583
	jr L_4574		;4584
vuelca_en_la_vram:		; Copia BC bytes de (DE) a la VRAM desde HL
	call prepara_la_escritura		;4586
vuelca_en_la_vram_sin_fijar:
	ld a,(de)			;4589   ; byte de la tabla...
	exx			;458a   ; ...y al puerto de datos
	out (c),a		;458b
	exx			;458d
	inc de			;458e
	dec bc			;458f   ; uno menos
	ld a,b			;4590
	or c			;4591   ; hasta acabar
	jr nz,vuelca_en_la_vram_sin_fijar		;4592
	ret			;4594
monta_la_letra:
	call apaga_la_pantalla		;4595   ; con la pantalla apagada
	ld de,059c4h		;4598   ; el guion de los patrones de la letra
	ld hl,02180h		;459b   ; patrones, casilla 0x30
	call descomprime_en_tres_bancos		;459e
	ld a,0f0h		;45a1   ; blanco sobre transparente
	ld hl,00180h		;45a3   ; los colores de las mismas casillas
	ld bc,00180h		;45a6
rellena_los_tres_bancos:		; Lo mismo en los tres tercios de la pantalla, 0x800 en 0x800
	ld d,003h		;45a9   ; los tres tercios de la pantalla
L_45AB:
	push bc			;45ab   ; destino y cuenta, que el bucle se los come
	push de			;45ac
	call rellena_la_vram		;45ad
	ld de,00800h		;45b0   ; el siguiente tercio esta 0x800 mas alla
	add hl,de			;45b3
	pop de			;45b4
	pop bc			;45b5
	dec d			;45b6   ; tres veces
	jr nz,L_45AB		;45b7
	ret			;45b9
descomprime_en_tres_bancos:		; Un guion comprimido en los tres tercios
	ld b,003h		;45ba   ; los tres tercios
L_45BC:
	push bc			;45bc
	push de			;45bd
	call descomprime		;45be
	ld de,00800h		;45c1   ; igual, un tercio mas alla
	add hl,de			;45c4
	pop de			;45c5
	pop bc			;45c6
	djnz L_45BC		;45c7   ; tres veces
	ret			;45c9
vuelca_en_los_tres_bancos:
	exx			;45ca   ; el contador va en B', que aqui no se toca
	ld b,003h		;45cb
L_45CD:
	exx			;45cd
	push bc			;45ce
	push de			;45cf
	call vuelca_en_la_vram		;45d0   ; un tercio
	ld de,00800h		;45d3   ; y el siguiente 0x800 mas alla
	add hl,de			;45d6
	pop de			;45d7
	pop bc			;45d8
	exx			;45d9
	djnz L_45CD		;45da   ; tres veces
	ret			;45dc
descomprime_desde_palabra:		; Guion comprimido que empieza por la direccion de VRAM
	ex de,hl			;45dd   ; la palabra de delante es el destino
	ld e,(hl)			;45de
	inc hl			;45df
	ld d,(hl)			;45e0   ; a HL, que es donde va a escribir
	ex de,hl			;45e1
	inc de			;45e2   ; y el guion empieza detras
descomprime:		; Guion comprimido con la direccion de VRAM ya fijada en HL
	call prepara_la_escritura		;45e3
sigue_descomprimiendo:		; El cuerpo del bucle: se entra aqui para continuar donde lo dejo el anterior
	ld a,(de)			;45e6   ; el codigo: cuantos bytes
	and 07fh		;45e7   ; los siete de abajo son la cuenta
	ld c,a			;45e9
	ld a,(de)			;45ea   ; y el byte entero otra vez, que el bit 7 es el modo
	inc de			;45eb
	jr nz,L_45F2		;45ec   ; cuenta distinta de cero: guion normal
	cp c			;45ee   ; cuenta cero, o sea una marca: 0x00 o 0x80
	jr nz,descomprime_desde_palabra		;45ef   ; 0x80 cambia el destino en la VRAM
	ret			;45f1   ; y 0x00 acaba el guion
L_45F2:
	ld b,000h		;45f2   ; la cuenta cabe de sobra en C
	cp c			;45f4   ; con el bit 7 puesto son bytes seguidos...
	push af			;45f5
	call nz,vuelca_en_la_vram_sin_fijar		;45f6   ; ...y se copian tal cual
	pop af			;45f9
	call z,saca_el_siguiente_y_escribe		;45fa   ; y sin el, un solo byte repetido C veces
	jr sigue_descomprimiendo		;45fd   ; y a por el siguiente
prepara_la_escritura:		; SETWRT y el puerto de datos del VDP en C
	ex af,af'			;45ff   ; la que fija A no se pierde
	call 00053h		;4600   ; BIOS SETWRT - Enables VDP to write
	exx			;4603
	ld a,(00006h)		;4604   ; el puerto de datos del VDP, de la tabla de la BIOS
	ld c,a			;4607   ; y se queda en C'
	exx			;4608
	ex af,af'			;4609
	ret			;460a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El cartel de KONAMI que sube por la pantalla. Son 26 casillas en tres
; filas -3, 11 y 12-, y (0xE00E) lleva donde esta. Cada paso resta 0x20,
; o sea una fila, y borra la que deja debajo. Catorce pasos.
; ----------------------------------------------------------------------
monta_el_cartel:
	ld a,00eh		;460b   ; los catorce pasos que va a subir
	ld (0e00ah),a		;460d
	ld hl,03aaah		;4610   ; fila 21, columna 10
	ld (0e00eh),hl		;4613
	ld de,0465ch		;4616   ; el guion de 0x465C
	ld hl,06008h		;4619   ; patrones, casilla 1
	call descomprime_en_tres_bancos		;461c
	ld hl,00008h		;461f   ; los colores de las 26 casillas
	ld bc,000d0h		;4622   ; 26 casillas de ocho bytes
	ld a,0f0h		;4625   ; blanco sobre transparente
	jp rellena_los_tres_bancos		;4627
sube_el_cartel:
	ld hl,(0e00eh)		;462a   ; donde estaba
	ld de,0ffe0h		;462d   ; una fila mas arriba
	add hl,de			;4630
	ld (0e00eh),hl		;4631   ; y se apunta donde ha quedado
	ld a,001h		;4634   ; las casillas van del 1 al 26, seguidas
	ld b,003h		;4636   ; la primera fila, tres
	call escribe_una_fila_del_cartel		;4638
	ld bc,00b0ch		;463b   ; la segunda, once
	call escribe_una_fila_del_cartel		;463e
	ld b,c			;4641   ; la tercera, doce
	call escribe_una_fila_del_cartel		;4642
	xor a			;4645   ; y la de debajo se borra
	call rellena_la_vram		;4646
	ld hl,0e00ah		;4649   ; un paso menos
	dec (hl)			;464c
	ret			;464d
escribe_una_fila_del_cartel:
	push hl			;464e
L_464F:
	call escribe_una_casilla		;464f   ; casilla a casilla
	inc hl			;4652
	inc a			;4653   ; y son correlativas
	djnz L_464F		;4654
	pop de			;4656
	ld hl,00020h		;4657   ; al acabar, HL a la fila de abajo
	add hl,de			;465a
	ret			;465b

; ----------------------------------------------------------------------
; DATOS guion_del_cartel_de_konami: Guion comprimido: 216 bytes en los TRES
;   bancos desde 0x2008. Lo vuelca monta_el_cartel (0x4616)
;   0x465c..0x46f3  (151 bytes)
DATA_guion_del_cartel_de_konami:
	defb 00fh,000h,001h,001h,006h,000h,082h,0ffh,0feh,008h,00fh,084h,0c3h,0c7h,0cfh,0dfh	; 465c  ................
	defb 003h,0ffh,089h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,007h,007h,005h,000h,083h,003h	; 466c  ................
	defb 0cfh,0dfh,005h,000h,083h,0e1h,0f9h,07dh,005h,000h,083h,0efh,0ffh,0f7h,005h,000h	; 467c  .......}........
	defb 083h,007h,08fh,09eh,005h,000h,083h,0f0h,0f8h,078h,005h,000h,083h,0f7h,0ffh,0fbh	; 468c  .........x......
	defb 005h,000h,08bh,08fh,0dfh,0f7h,00ch,01eh,01eh,00ch,000h,01eh,09eh,09eh,008h,00fh	; 469c  ................
	defb 090h,0ffh,0ffh,0dfh,0cfh,0c7h,0c3h,0c1h,0c0h,007h,087h,0c7h,0efh,0ffh,0ffh,0ffh	; 46ac  ................
	defb 0fch,004h,0deh,084h,09eh,09fh,00fh,003h,005h,03dh,083h,07dh,0f9h,0e1h,008h,0e3h	; 46bc  .........=.}....
	defb 090h,0dch,0c0h,0c7h,0deh,0dch,0deh,0cfh,0c3h,03ch,07ch,0fch,03ch,03ch,07ch,0fch	; 46cc  .........<|.<<|.
	defb 0deh,008h,0f1h,008h,0e3h,008h,0deh,088h,038h,044h,0bah,0aah,0b2h,0aah,044h,038h	; 46dc  ........8D....D8
	defb 003h,000h,001h,0ffh,004h,000h,000h	; 46ec

; ======================================================================
; CODIGO 0x46f3..0x4c72  (1407 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; EL BOXEADOR: LO QUE HACE EN CADA CUADRO
; ======================================================================
; Los dos boxeadores tienen la misma zona de trabajo de once bytes. El
; truco es que solo hay UNA: 0x46F9 copia la del que toca a 0xE221, lo
; hace todo ahi y la devuelve. Asi el codigo no lleva indice de jugador.
; Los DOS bloques y su lado, medido y cruzado dos veces:
; - 0xE232 es el boxeador de la DERECHA. 0x46F3 lo trabaja primero, y
; (0xE22F) le toca el 1: ese es el D que se usa por todas partes.
; - 0xE255 es el de la IZQUIERDA, con D = 0.
; Lo confirman dos cosas independientes: al colocarlos (0x49FE) al de
; 0xE232 le toca la columna 22 y al de 0xE255 la 2; y al andar, el de
; 0xE255 se acerca sumando y el de 0xE232 restando.
; El byte 7 de cada bloque -0xE239 y 0xE25C- es LA ACCION, y cada uno
; entra con la del OTRO en A: es lo unico que sabe del rival.
; ----------------------------------------------------------------------
el_cuadro_del_de_la_derecha:
	ld a,(0e25ch)		;46f3   ; el bloque del rival esta en 0xE232
	ld hl,0e232h		;46f6
L_46F9:
	ld de,0e221h		;46f9   ; once bytes a la zona de trabajo
	ld bc,0000bh		;46fc
	push hl			;46ff   ; el bloque, para devolverlo luego
	push de			;4700
	push bc			;4701
	ldir		;4702   ; once bytes a la zona de trabajo de 0xE221
	call el_cuadro_de_un_boxeador		;4704   ; y ahi se hace el cuadro
	pop bc			;4707
	pop hl			;4708
	pop de			;4709
	ldir		;470a   ; de vuelta a su sitio
	ret			;470c
el_cuadro_del_de_la_izquierda:
	xor a			;470d   ; escribe en 0x4F84, que es ROM: no hace nada. Codigo que sobro
	ld (04f84h),a		;470e
	ld hl,0e282h		;4711   ; baja dos temporizadores mas
	call baja_un_temporizador		;4714
	ld l,051h		;4717   ; HL era 0xE282, asi que ahora es 0xE251
	call baja_un_temporizador		;4719
	ld a,(0e239h)		;471c   ; y el jugador, que esta en 0xE255
	ld l,055h		;471f   ; y este trabaja el bloque de 0xE255
	jr L_46F9		;4721
baja_un_temporizador:
	ld a,(hl)			;4723   ; baja uno si no esta ya a cero
	or a			;4724   ; ya esta a cero?
	jr z,L_4728		;4725
	dec (hl)			;4727   ; y no pasa de cero
L_4728:
	ret			;4728

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El reparto por accion: (0xE228) dice que esta haciendo el boxeador, y
; de 0x0D a 0x10 hay una rutina para cada una.
; (0xE228) es lo que esta haciendo, y de aqui sale todo. De 0x0D a 0x10
; cada accion tiene su rutina; de 0x09 a 0x0C las lleva 0x49BC; y por
; debajo de 0x09 se mira el mando.
; ----------------------------------------------------------------------
el_cuadro_de_un_boxeador:
	ld e,a			;4729   ; la accion del rival, que se guarda en E
	ld hl,0e22fh		;472a   ; (0xE22F) alterna entre 0 y 1 en cada cuadro
	ld a,(hl)			;472d   ; lo de antes
	xor 001h		;472e   ; 0 el de la izquierda, 1 el de la derecha
	ld (hl),a			;4730   ; y queda apuntado para el otro
	ld d,a			;4731   ; D es el lado, y no se vuelve a tocar
	ld l,028h		;4732   ; la accion, en (0xE228)
	ld a,(hl)			;4734   ; la accion
	cp 011h		;4735   ; de 0x11 en adelante no hay nada que hacer
	ret nc			;4737   ; de 0x11 en adelante no hay nada que hacer
	dec hl			;4738   ; HL a (0xE227)
	cp 009h		;4739   ; de 0x09 a 0x0C, el bloque de 0x49BC
	jr c,L_4742		;473b   ; por debajo de 9, al mando
	cp 00dh		;473d   ; de 9 a 0x0C, andar
	jp c,acaba_el_golpe		;473f
L_4742:
	cp 00eh		;4742   ; 0x0E
	jp z,encaja_el_golpe		;4744
	cp 00fh		;4747   ; 0x0F
	jp z,retrocede		;4749
	cp 010h		;474c   ; 0x10
	jp z,cae_al_suelo		;474e
	cp 00dh		;4751   ; 0x0D
	jp z,espera_a_levantarse		;4753
	call baja_un_temporizador		;4756   ; con el temporizador todavia corriendo, no se mueve
	ret nz			;4759
	dec hl			;475a   ; y el otro, en (0xE226)
	call baja_un_temporizador		;475b
	ld a,(0e270h)		;475e   ; (0xE270)
	or a			;4761   ; hay algo en (0xE270)?
	jr nz,L_4788		;4762   ; con (0xE270) puesto no se hace caso al mando
	ld a,(0e22dh)		;4764   ; (0xE22D), lo que quedo pendiente
	or a			;4767   ; hay algo pendiente?
	jr z,L_4780		;4768   ; sin nada pendiente, al mando
	ld a,e			;476a   ; la accion del rival
	cp 00dh		;476b   ; si esta en la 0x0D...
	jr z,L_4780		;476d
	cp 010h		;476f   ; ...o en la 0x10, tampoco
	jr z,L_4780		;4771
	ld a,(0e22ch)		;4773   ; (0xE22C)
	or a			;4776   ; hay algo en (0xE22C)?
	jp nz,L_4780		;4777   ; entonces no se mira el mando
	ld a,(0e211h)		;477a   ; (0xE211)
	or a			;477d   ; y si no, se mira el mando
	jr z,lee_lo_que_pide_el_mando		;477e
L_4780:
	ld a,d			;4780   ; el lado, mas uno...
	inc a			;4781   ; el 0 o el 1 de antes, por cuatro
	rlca			;4782   ; ...por cuatro: 4 el de la izquierda y 8 el de la derecha
	rlca			;4783
	ld b,a			;4784   ; y esa es la entrada de la tabla
L_4785:
	jp traduce_lo_pulsado		;4785
L_4788:
	ld a,d			;4788   ; el de la izquierda, no
	or a			;4789
	jr z,L_4797		;478a
	ld a,(0e23ah)		;478c   ; la columna del de la derecha
	cp 013h		;478f   ; la 19
	jr z,L_47A0		;4791
	ld b,004h		;4793   ; la entrada 4 de la tabla
	jr L_4785		;4795
L_4797:
	ld a,(0e25dh)		;4797   ; la columna del de la izquierda
	cp 005h		;479a   ; la 5
	ld b,008h		;479c   ; la 8
	jr nz,L_4785		;479e
L_47A0:
	jp no_hace_nada		;47a0

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El mando. Cada boxeador tiene su bloque de tres bytes: el de la
; izquierda en 0xE2FE-0xE300 y el de la derecha en 0xE007-0xE009. Se mira
; primero lo que se acaba de pulsar; si no hay nada, lo que sigue
; pulsado, y solo para dejar que golpe+direccion siga andando.
; ----------------------------------------------------------------------
lee_lo_que_pide_el_mando:
	ld a,d			;47a3   ; de que lado es
	or a			;47a4
	jr nz,lo_que_pide_el_de_la_derecha		;47a5   ; el de la derecha, por su lado
	ld a,(0e2ffh)		;47a7   ; lo que se acaba de pulsar
	ld b,a			;47aa
	or a			;47ab   ; si hay algo nuevo, con eso basta
	jr nz,L_47BC		;47ac
	ld a,(0e300h)		;47ae   ; y si no, lo que sigue pulsado
	cp 014h		;47b1   ; golpe+izquierda...
	jr z,L_47B9		;47b3
	cp 018h		;47b5   ; ...o golpe+derecha
	jr nz,L_47BC		;47b7
L_47B9:
	res 4,a		;47b9   ; se le quita el golpe y queda andar
	ld b,a			;47bb
L_47BC:
	ld a,(0e002h)		;47bc   ; el bit 0 de las banderas: con el puesto, juegan dos
	rrca			;47bf   ; el bit 0, al acarreo
	jp c,L_487B		;47c0   ; y entonces no hay nada que pensar
	push de			;47c3   ; la accion del rival, que L_4A6B no respeta
	call decide_la_maquina		;47c4   ; con un jugador solo, aqui decide la maquina
	ld a,(0e207h)		;47c7   ; (0xE207), que 0x42F5 deja en 0, 1 o 0x10 segun la opcion del menu
	cp 002h		;47ca   ; por debajo de 2...
	jr nc,L_47D9		;47cc
	ld a,(0e051h)		;47ce   ; ...y (0xE051), las veces que se ha empezado, por debajo de 3
	cp 003h		;47d1
	jr nc,L_47D9		;47d3
	ld a,010h		;47d5   ; y se le pone el golpe
	add a,b			;47d7
	ld b,a			;47d8
L_47D9:
	ld a,b			;47d9   ; el nibble alto...
	and 0f0h		;47da
	rrca			;47dc
	rrca			;47dd
	rrca			;47de
	rrca			;47df
	ld c,a			;47e0   ; ...que vale 1 con el golpe puesto
	ld a,b			;47e1
	and 00fh		;47e2   ; y el bajo es la direccion
	cp 009h		;47e4   ; de 9 para arriba, o sea con derecha
	jr c,L_47EE		;47e6
	ld a,c			;47e8
	ld hl,0e254h		;47e9
	add a,(hl)			;47ec
	ld (hl),a			;47ed   ; y se suma a (0xE254)
L_47EE:
	ld a,b			;47ee
	and 00fh		;47ef   ; solo el nibble bajo sigue
	ld b,a			;47f1
	cp 005h		;47f2   ; golpe con direccion, de 5 a 8
	jr c,L_480B		;47f4
	cp 009h		;47f6
	jr nc,L_480B		;47f8
	ld hl,0e26fh		;47fa   ; uno mas en la cuenta de 0xE26F
	inc (hl)			;47fd
	ld a,(hl)			;47fe
	cp 006h		;47ff   ; a los seis...
	jr c,L_480B		;4801
	xor a			;4803   ; ...vuelve a cero
	ld (hl),a			;4804
	ld (0e265h),a		;4805   ; y se borran (0xE265) y (0xE243)
	ld (0e243h),a		;4808
L_480B:
	pop de			;480b
	ld a,b			;480c   ; la accion pedida
	jr L_4887		;480d
lo_que_pide_el_de_la_derecha:
	ld a,(0e008h)		;480f   ; lo que se acaba de pulsar
	ld b,a			;4812
	or a			;4813   ; hay algo nuevo?
	jr nz,L_4826		;4814
	ld a,(0e009h)		;4816   ; y si no, lo mantenido
	cp 014h		;4819   ; golpe+izquierda...
	jr z,L_4821		;481b
	cp 018h		;481d   ; ...o golpe+derecha
	jr nz,L_4826		;481f
L_4821:
	res 4,a		;4821   ; se le quita el golpe...
	xor 00ch		;4823   ; ...y se deshace el cambio de lado que hizo 0x4483
	ld b,a			;4825
L_4826:
	ld a,(0e000h)		;4826   ; la escena 2
	cp 002h		;4829   ; la del combate contra la maquina
	jr nz,L_4843		;482b
	ld b,004h		;482d   ; entonces manda ella: la entrada 4
	ld a,(0e003h)		;482f   ; el contador de cuadros
	and 005h		;4832   ; uno de cada ocho, mas o menos
	jr nz,L_4843		;4834
	ld a,r		;4836   ; y lo que salga del registro de refresco
	and 01fh		;4838   ; cinco bits: las cuatro direcciones y el golpe
	set 4,a		;483a   ; con el golpe siempre puesto
	cp 014h		;483c   ; golpe+izquierda no, que ahi se anda
	jr nz,L_4842		;483e
	ld a,011h		;4840   ; golpe+abajo en su lugar
L_4842:
	ld b,a			;4842
L_4843:
	ld a,b			;4843   ; lo pedido
	cp 014h		;4844   ; 0x14, 0x01 y 0x03...
	jr z,L_4853		;4846
	dec a			;4848   ; la 1, agacharse...
	jr z,L_4853		;4849
	dec a			;484b   ; ...y la 3
	dec a			;484c
	jr z,L_4853		;484d
	xor a			;484f   ; ...y con cualquier otra cosa se borra (0xE247)
	ld (0e247h),a		;4850
L_4853:
	call mide_la_distancia		;4853   ; estan cerca?
	ld a,b			;4856
	jr nc,L_4861		;4857   ; lejos
	cp 008h		;4859   ; lejos y con el golpe a secas
	jr nz,L_4861		;485b
	ld hl,0e230h		;485d   ; se apunta en (0xE230)
	ld (hl),a			;4860
L_4861:
	cp 014h		;4861   ; golpe+izquierda, no
	jr z,traduce_lo_pulsado		;4863
	bit 4,a		;4865   ; y sin golpe tampoco
	jr z,traduce_lo_pulsado		;4867
	ld hl,0e200h		;4869   ; el ultimo golpe, en (0xE200)
	ld c,(hl)			;486c
	ld (hl),a			;486d   ; y lo de ahora
	inc hl			;486e
	inc (hl)			;486f   ; y (0xE201) cuenta uno mas
	cp c			;4870   ; si repite, se deja
	jr z,traduce_lo_pulsado		;4871
	ld a,(0e202h)		;4873   ; el tope de (0xE202)...
	cp (hl)			;4876   ; ...comparado con la cuenta de 0xE201
	jr z,traduce_lo_pulsado		;4877
	ld (hl),000h		;4879   ; y si no, la cuenta a cero
L_487B:
	jr traduce_lo_pulsado		;487b
no_hace_nada:
	ld b,000h		;487d   ; la entrada 0 de la tabla, que no es nada

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; La tabla de 0x4C72 traduce lo pulsado -cinco bits: arriba, abajo,
; izquierda, derecha y golpe- a una de las once acciones. Las utiles:
; arriba 3, abajo 1, izquierda 9, derecha 0x0A, golpe 8,
; golpe+arriba 5, golpe+abajo 6, golpe+izquierda 4, golpe+derecha 7.
; Las otras 21 combinaciones dan 0, o sea nada.
; ----------------------------------------------------------------------
traduce_lo_pulsado:
	ld a,b			;487f
	ld hl,04c72h		;4880   ; la tabla de 32 entradas
	call suma_a_hl		;4883
	ld a,(hl)			;4886   ; la accion que le toca
L_4887:
	or a			;4887   ; la accion 0, nada
	ld hl,0e228h		;4888   ; y (0xE228) es donde vive
	jp z,L_493C		;488b
	push af			;488e
	cp 004h		;488f   ; de la 4 a la 8, que son los golpes...
	jr c,L_48A0		;4891
	cp 009h		;4893   ; ...hasta la 8
	jr nc,L_48A0		;4895
	ld a,d			;4897   ; ...y solo las del de la derecha
	or a			;4898
	jr z,L_48A0		;4899
	ld a,004h		;489b   ; y se apunta un 4 en (0xE1FE)
	ld (0e1feh),a		;489d
L_48A0:
	pop af			;48a0
	cp 004h		;48a1   ; la 4
	jr z,entra_en_la_accion_4		;48a3
	cp 001h		;48a5   ; la 1...
	jr z,L_48AD		;48a7
	cp 003h		;48a9   ; ...y la 3
	jr nz,empieza_la_accion		;48ab
L_48AD:
	push hl			;48ad
	push af			;48ae
	ld hl,0e272h		;48af   ; (0xE272) el de la izquierda, (0xE273) el de la derecha
	ld a,d			;48b2
	add a,l			;48b3   ; uno u otro segun el lado
	ld l,a			;48b4
	pop af			;48b5
	and 002h		;48b6   ; agacharse deja el bit 1
	ld (hl),a			;48b8
	pop hl			;48b9
	or a			;48ba
	res 1,(hl)		;48bb   ; de pie...
	jr z,L_48C1		;48bd
	set 1,(hl)		;48bf   ; ...o agachado
L_48C1:
	ld a,(hl)			;48c1
	and 003h		;48c2   ; y (0xE228) se queda con los dos de abajo
	jp L_493B		;48c4
empieza_la_accion:
	ld b,a			;48c7
	cp 00ah		;48c8   ; la 0x0A...
	jr z,anda		;48ca
	cp 009h		;48cc   ; ...y la 9 son andar
	jr z,anda		;48ce
	ld (0e225h),a		;48d0   ; se apunta en (0xE225)...
	ld (0e221h),a		;48d3   ; ...y en (0xE221)
	add a,004h		;48d6   ; y a la accion se le suman cuatro: de la 9 a la 0x0C
	ld (hl),a			;48d8
	cp 00ch		;48d9   ; la 0x0C
	ld a,004h		;48db   ; cuatro cuadros...
	jr z,L_48E1		;48dd
	ld a,006h		;48df   ; ...y seis las demas
L_48E1:
	dec hl			;48e1
	ld (hl),a			;48e2   ; el temporizador, en (0xE227)
	ld a,(0e22fh)		;48e3   ; el de la izquierda, no
	or a			;48e6
	ret nz			;48e7
	ld a,(0e002h)		;48e8   ; con dos jugando, tampoco
	rrca			;48eb
	ret c			;48ec
	ld (hl),c			;48ed   ; y si no, lo que trajera C
	ret			;48ee
entra_en_la_accion_4:
	ld hl,0e228h		;48ef
	ld (hl),a			;48f2   ; la accion 4, tal cual
	ld a,d			;48f3   ; el de la derecha, siempre
	rrca			;48f4
	jr c,L_48FC		;48f5
	ld a,(0e002h)		;48f7   ; y el de la izquierda solo con dos jugando
	rrca			;48fa
	ret nc			;48fb
L_48FC:
	dec hl			;48fc
	ld (hl),00ah		;48fd   ; diez cuadros
	ret			;48ff
anda:
	ld hl,0e228h		;4900
	ld a,(hl)			;4903   ; lo que hace ahora
	cp 004h		;4904   ; de la 4 en adelante no se anda
	jp nc,L_493C		;4906
	ld l,026h		;4909   ; (0xE226)
	ld a,(hl)			;490b
	or a			;490c
	jr nz,L_493C		;490d   ; con el temporizador corriendo, tampoco
	call mide_la_distancia		;490f   ; estan cerca?
	cp 050h		;4912   ; lejos, tres cuadros por paso...
	ld (hl),003h		;4914
	jr c,L_491A		;4916
	ld (hl),008h		;4918   ; ...y cerca, ocho
L_491A:
	ld a,d			;491a   ; el de la izquierda
	or a			;491b
	ld a,b			;491c   ; la accion
	jr z,anda_el_de_la_izquierda		;491d
	ld bc,00108h		;491f   ; una columna a la derecha, ocho pixeles
	cp 00ah		;4922   ; la 0x0A es andar a la derecha
	jr z,L_492E		;4924
	call mide_la_distancia		;4926   ; estan cerca?
	ld bc,0fff8h		;4929   ; y la 9 a la izquierda
	jr c,L_493C		;492c   ; pero no si estan pegados
L_492E:
	ld hl,0e229h		;492e   ; la columna
	ld a,(hl)			;4931
	add a,b			;4932
	cp 017h		;4933   ; la 22 es el tope de la derecha
	jr nc,L_493C		;4935
L_4937:
	ld (hl),a			;4937   ; la columna nueva
	inc hl			;4938
	ld a,(hl)			;4939   ; y el pixel va detras
	add a,c			;493a
L_493B:
	ld (hl),a			;493b
L_493C:
	ld hl,0e22bh		;493c   ; el temporizador largo, en (0xE22B)
	ld a,(hl)			;493f
	sub 001h		;4940   ; uno menos
	ld (hl),a			;4942
	ret nc			;4943   ; mientras no de la vuelta, nada mas
	ld (hl),020h		;4944   ; al llegar a cero, 32 cuadros mas
	ld a,(0e22dh)		;4946   ; hay algo pendiente en (0xE22D)?
	or a			;4949
	jr z,L_4953		;494a   ; no
	ld a,r		;494c   ; y con (0xE22D) puesto, de 12 a 27 al azar
	and 00fh		;494e
	or 00ch		;4950
	ld (hl),a			;4952
L_4953:
	ld hl,0e272h		;4953   ; el bit que dejo 0x48AF
	ld a,d			;4956
	add a,l			;4957   ; el de su lado
	ld l,a			;4958
	ld a,(hl)			;4959
	ld l,028h		;495a   ; (0xE228)
	or a			;495c
	res 1,(hl)		;495d   ; de pie...
	jr z,L_4963		;495f
	set 1,(hl)		;4961   ; ...o agachado
L_4963:
	ld a,(hl)			;4963
	and 003h		;4964   ; y el bit 0 alterna en cada cuadro
	xor 001h		;4966   ; y el bit 0 cambia en cada vuelta
	ld (hl),a			;4968
	ret			;4969
anda_el_de_la_izquierda:
	ld bc,0fff8h		;496a   ; una columna a la izquierda
	cp 00ah		;496d   ; la 0x0A es a la derecha
	jr nz,L_4979		;496f
	call mide_la_distancia		;4971
	ld bc,00108h		;4974   ; y entonces suma
	jr c,L_493C		;4977   ; pero no si estan pegados
L_4979:
	ld hl,0e229h		;4979   ; la columna
	ld a,(hl)			;497c
	add a,b			;497d
	cp 002h		;497e   ; la 2 es el tope de la izquierda
	jr c,L_493C		;4980
	jr L_4937		;4982

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Las acciones que no salen del mando, una rutina cada una. (0xE228) las
; lleva: 0 quieto, de 1 a 3 de pie o agachado, 4 la guardia, de 9 a 0x0C
; los cuatro golpes -que son las acciones 5 a 8 con cuatro sumados-,
; 0x0D esperar, 0x0E encajar, 0x0F retroceder y 0x10 en el suelo.
; ----------------------------------------------------------------------
encaja_el_golpe:
	dec (hl)			;4984   ; el temporizador, en (0xE227)
	ret nz			;4985   ; mientras corra, quieto
	ld a,d			;4986   ; de que lado es
	or a			;4987
	ld a,(0e232h)		;4988   ; el byte 0 del de la derecha...
	jr z,L_4990		;498b
	ld a,(0e255h)		;498d   ; ...o el del de la izquierda: siempre el del OTRO
L_4990:
	ld b,00eh		;4990   ; catorce cuadros
	cp 008h		;4992   ; con un 8 ahi
	jr z,L_4998		;4994
	ld b,010h		;4996   ; y dieciseis con lo demas
L_4998:
	ld (hl),b			;4998   ; el temporizador, puesto
	inc hl			;4999   ; y luego la accion 0x0F
	ld (hl),00fh		;499a
	ret			;499c
retrocede:
	dec (hl)			;499d   ; mientras corra el temporizador, quieto
	ret nz			;499e
	ld a,d			;499f   ; de que lado es
	or a			;49a0
	ld b,009h		;49a1   ; el de la izquierda anda a la izquierda...
	ld a,(0e232h)		;49a3   ; el byte 0 del otro
	jr z,L_49AC		;49a6
	inc b			;49a8   ; ...y el de la derecha a la derecha: los dos se apartan
	ld a,(0e255h)		;49a9
L_49AC:
	inc hl			;49ac   ; HL a (0xE228)
	ld (hl),000h		;49ad   ; la accion 0, quieto
	cp 007h		;49af   ; y con un 7 en el byte 0 del otro...
	ret nz			;49b1
	dec hl			;49b2   ; ...ocho cuadros
	ld (hl),008h		;49b3
	dec hl			;49b5   ; (0xE226) a cero
	ld (hl),000h		;49b6
	ld a,b			;49b8   ; y se echa a andar
	jp empieza_la_accion		;49b9

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; PEGAR CANSA. Al acabarse el golpe se le suma a QUIEN LO DIO el numero
; que le toca en la tabla de 0x6854: 3 al golpe 5, 2 al 6 y 1 a los otros
; dos. Y (0xE24C) o (0xE24D) se cargan con 0xC0, que
; mira_si_entra_el_golpe va gastando con un `srl` por cuadro: los dos
; bits solo salen por el acarreo en los cuadros SEPTIMO y OCTAVO, que es
; la ventana en la que el golpe puede tocar.
; ----------------------------------------------------------------------
acaba_el_golpe:
	dec (hl)			;49bc   ; mientras corra el temporizador, quieto
	ret nz			;49bd
	ld b,00ch		;49be   ; doce cuadros...
	ld a,(0e206h)		;49c0   ; (0xE206), lo duro que juega
	cp 008h		;49c3   ; ...o catorce por debajo de 8
	jr nc,L_49C9		;49c5
	ld b,00eh		;49c7
L_49C9:
	ld (hl),b			;49c9   ; el temporizador, puesto
	dec hl			;49ca   ; (0xE225), la accion de antes
	dec hl			;49cb
	ld a,(hl)			;49cc
	push af			;49cd   ; guardada
	ld (0e228h),a		;49ce   ; y se vuelve a ella
	sub 005h		;49d1   ; del 5 al 8...
	ld hl,06854h		;49d3   ; ...la tabla de 0x6854: 3, 2, 1 y 1
	call suma_a_hl		;49d6
	ld b,(hl)			;49d9   ; lo que cansa
	ld a,d			;49da   ; de que lado es
	ld hl,0e218h		;49db   ; el castigo del de la derecha...
	or a			;49de
	jr nz,L_49E3		;49df
	ld l,01ah		;49e1   ; ...o el del de la izquierda, que es el suyo
L_49E3:
	ld a,(hl)			;49e3   ; su nivel
	cp 007h		;49e4   ; del 7 en adelante ya no sube mas
	call c,suma_castigo		;49e6
	pop af			;49e9   ; el golpe
	cp 008h		;49ea   ; el 8 suena distinto
	ld a,047h		;49ec
	jr z,L_49F2		;49ee
	ld a,049h		;49f0
L_49F2:
	call pide_un_sonido		;49f2   ; y suena
	ld hl,0e24ch		;49f5   ; (0xE24C) o (0xE24D)
	ld a,d			;49f8   ; la de su lado
	add a,l			;49f9
	ld l,a			;49fa
	ld (hl),0c0h		;49fb   ; 0xC0: la ventana en que el golpe toca
	ret			;49fd
cae_al_suelo:
	dec (hl)			;49fe   ; mientras corra el temporizador, quieto
	ret nz			;49ff
	ld (hl),00ah		;4a00   ; diez cuadros
	inc hl			;4a02
	ld (hl),00dh		;4a03   ; y luego la accion 0x0D, esperar
	ld a,d			;4a05   ; de que lado es
	ld bc,000e4h		;4a06   ; la casilla y el paso, para la cuenta
	ld de,001d7h		;4a09
	or a			;4a0c
	jr z,L_4A17		;4a0d
	ld hl,02802h		;4a0f   ; columna 2, pixel 40 al OTRO...
	ld (0e25dh),hl		;4a12
	jr coloca_la_cuenta		;4a15
L_4A17:
	ld hl,0c816h		;4a17   ; ...o columna 22, pixel 200: cada uno a su esquina
	ld (0e23ah),hl		;4a1a
	inc bc			;4a1d   ; y la otra pareja
	inc de			;4a1e
coloca_la_cuenta:
	ld hl,0e23bh		;4a1f   ; el pixel del de la derecha
	ld a,(0e22fh)		;4a22   ; de que lado es
	or a			;4a25
	ld a,090h		;4a26   ; 0x90...
	jr nz,L_4A2E		;4a28
	ld a,050h		;4a2a   ; ...o 0x50 y el pixel del de la izquierda
	ld l,05eh		;4a2c
L_4A2E:
	cp (hl)			;4a2e   ; con el pixel por encima...
	jr nc,L_4A33		;4a2f
	push de			;4a31   ; ...se cambia de pareja
	pop bc			;4a32
L_4A33:
	ld a,(hl)			;4a33   ; el pixel del caido
	srl a		;4a34   ; entre ocho: la columna
	srl a		;4a36
	srl a		;4a38
	add a,c			;4a3a   ; mas lo que traiga C
	ld l,06ch		;4a3b   ; y ahi va la cuenta, en (0xE26C)
	ld (hl),a			;4a3d
	inc hl			;4a3e
	ld (hl),b			;4a3f   ; el paso, en (0xE26D)
	inc hl			;4a40
	ld (hl),000h		;4a41   ; y (0xE26E) a cero
	ld a,(0e24fh)		;4a43   ; (0xE24F)
	or a			;4a46
	ld a,053h		;4a47   ; con el sonido 0x53, el de la cuenta
	jp pide_un_sonido		;4a49
espera_a_levantarse:
	inc hl			;4a4c   ; la accion, en (0xE228)
	ld a,(0e234h)		;4a4d   ; (0xE234)...
	or a			;4a50
	ret nz			;4a51
	ld a,(0e257h)		;4a52   ; ...(0xE257)...
	or a			;4a55
	ret nz			;4a56
	ld a,(0e224h)		;4a57   ; ...y (0xE224): mientras alguno tenga algo, se sigue esperando
	or a			;4a5a
	ret nz			;4a5b
	ld (hl),000h		;4a5c   ; y al quedar los tres a cero, a la accion 0
	ret			;4a5e

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; La distancia entre los dos, en pixeles: el byte 9 de cada bloque. Sale
; con acarreo cuando estan a menos de 0x41, que es "cerca".
; ----------------------------------------------------------------------
mide_la_distancia:
	push hl			;4a5f
	ld hl,0e25eh		;4a60   ; el pixel del de la izquierda
	ld a,(0e23bh)		;4a63   ; menos el del de la derecha
	sub (hl)			;4a66
	cp 041h		;4a67   ; 0x41 pixeles es la raya
	pop hl			;4a69
	ret			;4a6a

; ----------------------------------------------------------------------
; ======================================================================
; LA MAQUINA
; ======================================================================
; Quien juega a que, medido y cruzado tres veces:
; - con el bit 0 de las banderas puesto (opciones 3 y 4 del menu) no se
; entra aqui: los dos boxeadores leen su mando;
; - sin el, esto lleva al de la IZQUIERDA, y el humano es el de la
; DERECHA, que es el que va con el puerto 1 y el cursor;
; - y en la escena 2, la demostracion, al de la derecha lo mueve el
; registro R (0x4836), asi que juegan solos los dos.
; Lo confirma que aqui se acerque andando a la DERECHA (0x4A83) y se
; retire a la izquierda (0x4B39), que es lo que le toca al de ese lado.
; Devuelve en B la accion, con un numero de propina en el nibble alto:
; ese numero se suma a (0xE254) mientras anda, y (0xE254) es lo que luego
; elige el guion de golpes en 0x4C1C.
; ----------------------------------------------------------------------
decide_la_maquina:
	ld hl,0e26bh		;4a6b   ; (0xE26B), su temporizador corto
	call baja_un_temporizador		;4a6e
	ld a,(0e239h)		;4a71   ; lo que esta haciendo el humano
	ld c,a			;4a74
	ld l,06ah		;4a75   ; (0xE26A)
	ld a,(hl)			;4a77
	or a			;4a78   ; sin nada apuntado ahi, se decide de cero
	jr z,decide_de_cero		;4a79
	ld a,(0e212h)		;4a7b   ; (0xE212)
	cp 030h		;4a7e   ; con 0x30 exacto, a apartarse
	jp z,L_4B2C		;4a80
	ld b,09ah		;4a83   ; acercarse
	call mide_la_distancia		;4a85   ; la distancia
	cp 049h		;4a88   ; a mas de 0x49, andando
	ret nc			;4a8a
	ld b,000h		;4a8b   ; y si no, quieto
	inc hl			;4a8d   ; (0xE26B)
	ld a,(hl)			;4a8e
	or a			;4a8f   ; mientras corra, nada
	ret nz			;4a90
	dec hl			;4a91
	call baja_un_temporizador		;4a92   ; dos golpes a (0xE26A)
	call baja_un_temporizador		;4a95
	inc hl			;4a98   ; y vuelta a (0xE26B)
L_4A99:
	ld (hl),008h		;4a99   ; ocho cuadros de espera
	jp L_4B99		;4a9b
decide_de_cero:
	call mide_la_distancia		;4a9e   ; estan cerca?
	ld l,030h		;4aa1   ; (0xE230)
	jp nc,esta_lejos		;4aa3   ; lejos, a lo suyo
	ld (hl),000h		;4aa6   ; cerca: se borra
	call esta_contra_la_cuerda		;4aa8   ; esta contra su cuerda?
	jr c,le_pega_o_se_aparta		;4aab
	ld a,(0e25dh)		;4aad   ; o casi, por debajo de la columna 5
	cp 005h		;4ab0
L_4AB2:
	jr nc,le_pega_o_se_aparta		;4ab2
	ld b,000h		;4ab4   ; entonces quieto
	ld hl,0e26bh		;4ab6   ; (0xE26B)
	ld a,(hl)			;4ab9   ; su temporizador
	or a			;4aba
	jr z,L_4A99		;4abb   ; con el temporizador a cero, ocho cuadros
	ret			;4abd
le_pega_o_se_aparta:
	ld a,c			;4abe   ; lo que hace el humano
	cp 00dh		;4abf   ; de la 0x0D en adelante...
	jp nc,se_toma_su_tiempo		;4ac1
	cp 005h		;4ac4   ; ...o por debajo de la 5
	jp c,se_toma_su_tiempo		;4ac6
	call esta_contra_la_cuerda		;4ac9   ; contra la cuerda?
	jr nc,L_4AD3		;4acc
	call lleva_castigo		;4ace   ; y sin llevar castigo
	jr nc,L_4AF6		;4ad1
L_4AD3:
	ld a,(0e206h)		;4ad3   ; (0xE206), lo duro que juega
	ld hl,04dfdh		;4ad6   ; los cinco de 0x4DFD...
	cp 020h		;4ad9   ; por debajo de 0x20...
	jr nc,L_4AE3		;4adb
	ld hl,04ddeh		;4add   ; ...o la rampa de 0x4DDE, que baja de 0x4C a 0x0C
	call suma_a_hl		;4ae0
L_4AE3:
	ld b,(hl)			;4ae3   ; el numero que toca
	ld a,(0e003h)		;4ae4   ; el contador de cuadros
	and 07fh		;4ae7   ; siete bits, que da la vuelta cada dos segundos
	cp b			;4ae9   ; con el por debajo, se golpea; asi cuanto mas baja la rampa, mas
	jr nc,L_4AF6		;4aea   ; con el por encima, no
	ld hl,0e201h		;4aec   ; (0xE201), los golpes contados
	ld a,(hl)			;4aef
	inc hl			;4af0
	cp (hl)			;4af1   ; contra el tope de (0xE202)
	jp c,se_toma_su_tiempo		;4af2
	dec hl			;4af5
L_4AF6:
	ld b,001h		;4af6   ; agacharse
	ld a,c			;4af8   ; lo que hace el humano
	cp 00ah		;4af9   ; si anda a la derecha...
	ret z			;4afb
	cp 006h		;4afc   ; ...o pega bajo, agachado se queda
	ret z			;4afe
	ld hl,0e203h		;4aff   ; (0xE203), la marca de que ha decidido
	ld (hl),001h		;4b02
	inc hl			;4b04   ; (0xE204)
	ld a,(hl)			;4b05
	or a			;4b06   ; hay algo en (0xE204)?
	jr nz,espera_su_turno		;4b07   ; con algo apuntado, otra cosa
	ld b,004h		;4b09   ; la accion 4
	ld a,c			;4b0b   ; lo que hace el humano
	cp 009h		;4b0c   ; de la 9 en adelante
	jp nc,se_toma_su_tiempo		;4b0e
	ld a,(0e32fh)		;4b11   ; el sonido que suena ahora
	cp 003h		;4b14   ; si ya es el 3, no se repite
	ret z			;4b16
	ld a,003h		;4b17   ; y si no, el 3
	jp pide_un_sonido		;4b19
espera_su_turno:
	ld b,003h		;4b1c   ; la accion 3
	dec a			;4b1e   ; (0xE204) tiene que valer 1
	ret nz			;4b1f
	call esta_contra_la_cuerda		;4b20   ; contra la cuerda?
	ret c			;4b23   ; entonces no
	ld hl,0e26bh		;4b24   ; ocho cuadros...
	ld (hl),008h		;4b27
	dec hl			;4b29
	ld (hl),00ah		;4b2a   ; ...y un 0x0A en (0xE26A)
L_4B2C:
	call baja_un_temporizador		;4b2c   ; (0xE26B), otra vez
	ld b,003h		;4b2f   ; la accion 3
	ld a,(0e25dh)		;4b31   ; la columna del de la izquierda
	cp 005h		;4b34   ; de la 5 en adelante...
	jp c,L_4AB2		;4b36
	ld b,099h		;4b39   ; ...andar a la izquierda, que es apartarse
	ret			;4b3b
esta_lejos:
	ld a,(hl)			;4b3c   ; (0xE230), lo que apunto 0x485D
	or a			;4b3d   ; hay algo?
	jr z,mira_lo_apuntado		;4b3e   ; sin nada, se mira el castigo
	ld b,09ah		;4b40   ; acercarse
	ld l,018h		;4b42   ; (0xE218)
	ld a,(hl)			;4b44   ; lo de (0xE218)
	inc hl			;4b45
	inc hl			;4b46
	cp (hl)			;4b47   ; contra (0xE21A)
	ret c			;4b48   ; por debajo, se acerca
	ld b,000h		;4b49   ; y si no, quieto
	ld a,(0e003h)		;4b4b   ; el contador de cuadros
	and 03fh		;4b4e   ; uno de cada 64...
	ret nz			;4b50
	ld (0e230h),a		;4b51   ; ...borra (0xE230)
	ret			;4b54
mira_lo_apuntado:
	ld l,067h		;4b55   ; (0xE267)
	ld a,(hl)			;4b57
	or a			;4b58   ; hay algo?
	jr z,L_4B6D		;4b59
	ld (hl),000h		;4b5b   ; se gasta
	jr L_4B72		;4b5d   ; y se aparta
lleva_castigo:
	ld a,(0e243h)		;4b5f   ; (0xE243)
	ld b,099h		;4b62   ; acercarse
	cp 002h		;4b64   ; con dos o mas, ya no
	ret nc			;4b66
	ld a,(0e265h)		;4b67   ; y (0xE265), que cuenta hasta 3
	cp 003h		;4b6a
	ret			;4b6c
L_4B6D:
	call lleva_castigo		;4b6d   ; lleva castigo?
	jr nc,descansa		;4b70   ; sin castigo, otra cosa
L_4B72:
	ld b,000h		;4b72   ; quieto
	ld a,(0e282h)		;4b74   ; (0xE282), el temporizador que baja 0x4711
	or a			;4b77
	ret nz			;4b78   ; mientras corra, quieto
	ld b,09ah		;4b79   ; y si no, acercarse
	ret			;4b7b
descansa:
	ld a,(0e25dh)		;4b7c   ; la columna del de la izquierda
	cp 005h		;4b7f   ; de la 5 en adelante, nada
	ret nc			;4b81
	ld b,000h		;4b82   ; quieto
	ld a,(0e003h)		;4b84   ; el contador de cuadros
	and 07fh		;4b87   ; uno de cada 128...
	or a			;4b89
	ret nz			;4b8a
	ld (0e243h),a		;4b8b   ; ...borra (0xE243)...
	ld (0e265h),a		;4b8e   ; ...y (0xE265)
	ret			;4b91
se_toma_su_tiempo:
	ld a,(0e251h)		;4b92   ; (0xE251), la pausa que baja 0x4717
	or a			;4b95
	ld b,000h		;4b96   ; mientras corra, quieto
	ret nz			;4b98
L_4B99:
	ld a,r		;4b99   ; del registro de refresco
	and 00fh		;4b9b   ; de 0 a 15
	ld b,a			;4b9d
	ld a,(0e1feh)		;4b9e   ; (0xE1FE), que pone 0x489B cuando el de la derecha golpea
	or a			;4ba1
	ld a,(0e206h)		;4ba2   ; lo duro que juega
	jr nz,L_4BCA		;4ba5   ; con algo apuntado, se salta el ruido
	ld a,(0e215h)		;4ba7   ; (0xE215)
	cp 032h		;4baa   ; 0x32...
	jr z,L_4BB2		;4bac
	cp 036h		;4bae   ; ...o 0x36
	jr nz,L_4BC8		;4bb0
L_4BB2:
	ld a,(0e313h)		;4bb2   ; (0xE313)
	cp 056h		;4bb5   ; tres valores lo callan
	jr z,L_4BC8		;4bb7
	dec a			;4bb9   ; 0x55...
	jr z,L_4BC8		;4bba
	dec a			;4bbc   ; ...o 0x54
	jr z,L_4BC8		;4bbd
	ld a,r		;4bbf   ; y si no, el sonido 1 o el 2 al azar
	and 001h		;4bc1
	add a,001h		;4bc3   ; el 1 o el 2
	call pide_un_sonido		;4bc5
L_4BC8:
	ld a,010h		;4bc8   ; y se sigue con 0x10
L_4BCA:
	ld hl,04dfdh		;4bca   ; los cinco de 0x4DFD...
	cp 020h		;4bcd
	jr nc,L_4BD7		;4bcf
	ld hl,04ddeh		;4bd1   ; ...o la rampa de 0x4DDE
	call suma_a_hl		;4bd4
L_4BD7:
	ld a,(0e000h)		;4bd7   ; la escena 2, la demostracion
	cp 002h		;4bda
	jr nz,L_4BE0		;4bdc
	ld b,050h		;4bde   ; ahi la pausa es fija, 0x50 mas
L_4BE0:
	ld a,(hl)			;4be0   ; la de la tabla...
	add a,b			;4be1   ; ...mas lo del azar
	ld (0e251h),a		;4be2   ; y esa es la pausa
	ld hl,0e203h		;4be5   ; (0xE203), lo que dejo 0x4AFF
	ld a,(hl)			;4be8
	or a			;4be9   ; hay algo?
	jr z,L_4BF8		;4bea
	ld (hl),000h		;4bec   ; se gasta
	inc hl			;4bee
	ld a,(hl)			;4bef   ; y (0xE204) sube uno
	inc a			;4bf0
	ld (hl),a			;4bf1
	cp 004h		;4bf2   ; de cuatro en cuatro
	jr nz,L_4BF8		;4bf4
	ld (hl),000h		;4bf6
L_4BF8:
	ld b,056h		;4bf8   ; la accion 6, pegar bajo
	ld a,c			;4bfa   ; lo que hace el humano
	cp 002h		;4bfb   ; la 0, la 1...
	jr c,saca_el_golpe_del_guion		;4bfd
	cp 005h		;4bff   ; ...y de la 2 a la 4 se pega bajo y se acabo
	ret c			;4c01
saca_el_golpe_del_guion:
	ld l,050h		;4c02   ; (0xE250), los tres pasos del guion
	push hl			;4c04
	ld a,(hl)			;4c05   ; los pasos que quedan
	or a			;4c06
	jr nz,L_4C2A		;4c07   ; con el guion empezado, se sigue
	ld (hl),003h		;4c09   ; tres pasos
	ld hl,06858h		;4c0b   ; los guiones de 0x6858
	ld a,(0e207h)		;4c0e   ; (0xE207), que sale del menu
	and 003h		;4c11   ; cuatro juegos...
	add a,a			;4c13   ; por ocho...
	add a,a			;4c14
	add a,a			;4c15
	ld b,a			;4c16   ; ...y por tres
	add a,a			;4c17   ; ...de 24 bytes cada uno
	add a,b			;4c18
	call suma_a_hl		;4c19
	ld a,(0e254h)		;4c1c   ; (0xE254), lo que se acumulo andando
	and 007h		;4c1f   ; ocho guiones...
	ld b,a			;4c21
	rlca			;4c22   ; por dos...
	add a,b			;4c23   ; ...de tres bytes
	call suma_a_hl		;4c24
	ld (0e252h),hl		;4c27   ; y ahi queda el puntero
L_4C2A:
	pop hl			;4c2a
	dec (hl)			;4c2b   ; un paso menos
	ld a,(0e21ah)		;4c2c   ; (0xE21A)
	cp 004h		;4c2f   ; de 4 en adelante...
	jr c,L_4C40		;4c31
	ld hl,068a0h		;4c33   ; ...el golpe sale de los ocho de 0x68A0
	ld a,r		;4c36   ; al azar
	and 007h		;4c38
	call suma_a_hl		;4c3a
	ld b,(hl)			;4c3d
	jr L_4C5A		;4c3e
L_4C40:
	ld a,(hl)			;4c40   ; el paso en que va
	ld hl,(0e252h)		;4c41   ; el puntero del guion
	rrca			;4c44   ; en los pasos pares, el byte tal cual
	jr nc,L_4C55		;4c45
	ld a,r		;4c47   ; en los impares se echa a suertes
	rrca			;4c49
	jr nc,L_4C55		;4c4a
	ld a,(0e21bh)		;4c4c   ; y (0xE21B) decide si el de antes...
	rrca			;4c4f
	dec hl			;4c50   ; el de antes...
	jr nc,L_4C55		;4c51
	inc hl			;4c53   ; ...o el de despues
	inc hl			;4c54
L_4C55:
	ld b,(hl)			;4c55   ; el golpe
	inc hl			;4c56
	ld (0e252h),hl		;4c57   ; y el puntero avanza
L_4C5A:
	ld a,b			;4c5a   ; el nibble bajo es la accion
	and 00fh		;4c5b
	cp 009h		;4c5d   ; la 9, andar
	ret nz			;4c5f
	ld a,(0e25ch)		;4c60   ; la columna del de la derecha
	cp 005h		;4c63   ; de la 5 en adelante, nada
	ret nc			;4c65
	ld a,00fh		;4c66   ; y si no, 15 cuadros en (0xE282)
	ld (0e282h),a		;4c68
	ret			;4c6b
esta_contra_la_cuerda:
	ld a,(0e25dh)		;4c6c   ; la columna del de la izquierda
	cp 003h		;4c6f   ; el tope es la 2, asi que por debajo de 3 esta pegado
	ret			;4c71

; ----------------------------------------------------------------------
; DATOS acciones_por_mando: Las 32 combinaciones de los cinco bits del mando
;   traducidas a accion: arriba 3, abajo 1, izquierda 9, derecha 0x0A, golpe
;   8, golpe+arriba 5, golpe+abajo 6, golpe+izquierda 4 y golpe+derecha 7. Las
;   otras 23 dan cero
;   0x4c72..0x4c92  (32 bytes)
DATA_acciones_por_mando:
	defb 000h,003h,001h,000h,009h,000h,000h,000h	; 4c72  ........
	defb 00ah,000h,000h,000h,000h,000h,000h,000h	; 4c7a  ........
	defb 008h,005h,006h,000h,004h,000h,000h,000h	; 4c82  ........
	defb 007h,000h,000h,000h,000h,000h,000h,000h	; 4c8a  ........

; ======================================================================
; CODIGO 0x4c92..0x4dde  (332 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; EL GOLPE QUE ENTRA
; ======================================================================
; Aqui se resuelve si un golpe toca. Se mira una vez por boxeador, y el
; orden lo echa a suertes la paridad de (0xE23E)+(0xE261).
; Los dos punteros son el reparto: IY va al bloque del que PEGA -dos
; bytes por delante de su base- e IX a LA ACCION del que recibe. De ahi
; que (iy+5) sea la accion del que pega y (ix+0) la del que recibe, y que
; el golpe entre con `ld (ix+000h),00eh`: la accion 0x0E es encajarlo.
; Si el castigo pasa del tope, (ix+0) pasa a 0x10, que es caer.
; ----------------------------------------------------------------------
mira_si_entra_el_golpe:
	ld hl,0e241h		;4c92   ; (0xE241), dos temporizadores mas
	call baja_un_temporizador		;4c95
	ld l,064h		;4c98   ; y (0xE264)
	call baja_un_temporizador		;4c9a
	ld a,(0e234h)		;4c9d   ; con cualquiera de los cuatro puesto no se mira nada:
	or a			;4ca0
	ret nz			;4ca1
	ld a,(0e257h)		;4ca2   ; (0xE257)...
	or a			;4ca5
	ret nz			;4ca6
	ld a,(0e22ch)		;4ca7   ; ...(0xE22C)...
	or a			;4caa
	ret nz			;4cab
	ld a,(0e211h)		;4cac   ; ...y (0xE211)
	or a			;4caf
	ret nz			;4cb0
	ld a,(0e239h)		;4cb1   ; la accion del de la derecha, copiada a (0xE23F)
	ld (0e23fh),a		;4cb4
	ld a,(0e25ch)		;4cb7   ; y la del de la izquierda a (0xE262)
	ld (0e262h),a		;4cba
	ld a,(0e23eh)		;4cbd   ; (0xE23E)...
	ld hl,0e261h		;4cc0   ; ...mas (0xE261)
	add a,(hl)			;4cc3
	rrca			;4cc4   ; la paridad de la suma decide quien pega primero
	jr c,L_4CCC		;4cc5
	call pega_el_de_la_derecha		;4cc7   ; el de la derecha
	jr pega_el_de_la_izquierda		;4cca   ; y luego el de la izquierda
L_4CCC:
	call pega_el_de_la_izquierda		;4ccc   ; o al reves
pega_el_de_la_derecha:
	ld hl,0e24dh		;4ccf   ; (0xE24D), que se va gastando bit a bit
	srl (hl)		;4cd2
	ret nc			;4cd4   ; sin acarreo, este cuadro no le toca
	ld iy,0e234h		;4cd5   ; pega el de la derecha...
	ld ix,0e25ch		;4cd9   ; ...y recibe el de la izquierda
	ld bc,0e217h		;4cdd   ; donde se apunta el castigo
	ld l,01ah		;4ce0   ; y (0xE21A), lo que lleva encajado
	call mide_la_distancia		;4ce2   ; tienen que estar cerca
	ret nc			;4ce5
	jr el_golpe_toca		;4ce6
pega_el_de_la_izquierda:
	ld hl,0e24ch		;4ce8   ; (0xE24C)
	srl (hl)		;4ceb
	ret nc			;4ced   ; sin acarreo, este cuadro no le toca
	ld iy,0e257h		;4cee   ; pega el de la izquierda...
	ld ix,0e239h		;4cf2   ; ...y recibe el de la derecha
	ld bc,0e216h		;4cf6   ; donde se apunta el castigo
	ld l,018h		;4cf9   ; y (0xE218)
	call mide_la_distancia		;4cfb   ; tienen que estar cerca
	ret nc			;4cfe
el_golpe_toca:
	ld a,(iy+00bh)		;4cff   ; la accion del que pega
	cp 005h		;4d02   ; de la 5 a la 8 son los golpes
	ret c			;4d04
	cp 009h		;4d05   ; de la 9 en adelante, no
	ret nc			;4d07
	ld a,(ix+006h)		;4d08   ; y el que recibe no puede estar ya encajando
	cp 00dh		;4d0b
	ret nc			;4d0d
	ld a,(iy+00bh)		;4d0e   ; el golpe 6, que es el bajo
	cp 006h		;4d11
	ld a,(ix+006h)		;4d13   ; lo que hace el que recibe
	jr nz,L_4D1F		;4d16
	cp 002h		;4d18   ; agachado, el golpe bajo no le da
	jr nc,L_4D2C		;4d1a
L_4D1C:
	jp suena_el_bloqueo		;4d1c
L_4D1F:
	cp 002h		;4d1f   ; y contra los otros, agacharse...
	jr z,L_4D1C		;4d21
	cp 003h		;4d23   ; ...o estar de pie no vale
	jr z,L_4D1C		;4d25
	cp 004h		;4d27   ; la accion 4 es la guardia
	jp z,apunta_el_fallo		;4d29
L_4D2C:
	ld (ix+000h),00eh		;4d2c   ; EL GOLPE ENTRA: el que recibe pasa a encajarlo
	ld a,(iy-001h)		;4d30   ; y uno mas en su cuenta de 0xE233
	inc a			;4d33   ; si no se pasa
	jr z,L_4D39		;4d34
	ld (iy-001h),a		;4d36
L_4D39:
	push hl			;4d39   ; la tabla de 0x4DFE
	ld hl,04dfeh		;4d3a
	ld a,(iy+00bh)		;4d3d   ; el golpe...
	sub 005h		;4d40
	call suma_a_hl		;4d42   ; ...que elige el ruido
	ld a,(hl)			;4d45
	pop hl			;4d46
	call pide_un_sonido		;4d47   ; y suena
	inc (iy+00fh)		;4d4a   ; dos cuentas mas para el que pega
	inc (iy+010h)		;4d4d
	ld (ix-001h),004h		;4d50   ; cuatro cuadros al que recibe
	ld a,(iy+00bh)		;4d54   ; el golpe, otra vez
	sub 005h		;4d57
	ld de,06850h		;4d59   ; la tabla de 0x6850: 12, 10, 9 y 2
	call suma_a_de		;4d5c
	ld a,(de)			;4d5f   ; y ese es el castigo del golpe
	ld (bc),a			;4d60
	ld a,(hl)			;4d61   ; lo que lleva encajado
	cp 005h		;4d62   ; por debajo de 5 no pasa nada
	ret c			;4d64
	cp 008h		;4d65   ; de 8 en adelante el tope es 2
	ld a,002h		;4d67
	jr nc,L_4D74		;4d69
	ld a,(hl)			;4d6b   ; y entre medias sale de 0x5445
	sub 005h		;4d6c
	ld de,05445h		;4d6e
	call suma_a_de		;4d71
L_4D74:
	inc hl			;4d74   ; y el tope, en el byte de al lado
	ld a,(bc)			;4d75   ; el castigo del golpe...
	add a,(hl)			;4d76   ; ...mas lo que ya llevaba
	ld c,a			;4d77
	ld a,(de)			;4d78   ; contra el tope
	ld b,a			;4d79
	ld a,c			;4d7a
	cp b			;4d7b   ; por debajo, aguanta
	ret c			;4d7c
	ld a,(iy+005h)		;4d7d   ; la accion del que pega
	cp 010h		;4d80   ; y no pasa de 0x10
	ret nc			;4d82
	ld a,(iy+00bh)		;4d83   ; el golpe 8 nunca tumba
	cp 008h		;4d86
	ret z			;4d88
	ld a,c			;4d89   ; con 0x1C justo...
	cp 01ch		;4d8a
	jr z,L_4DA0		;4d8c   ; ...se tumba de todas formas
	dec hl			;4d8e   ; la cuenta de encajados
	ld de,00006h		;4d8f   ; seis
	ld a,r		;4d92   ; mas 0, 1 o 2 al azar
	and 003h		;4d94
	inc a			;4d96
	srl a		;4d97
	add a,e			;4d99
	ld e,a			;4d9a
	ld a,(hl)			;4d9b   ; lo que llevaba encajado
	cp 007h		;4d9c   ; por debajo de 7, ese
	jr c,L_4DA3		;4d9e
L_4DA0:
	ld de,0010ah		;4da0   ; y si no, 0x010A
L_4DA3:
	inc (ix+005h)		;4da3   ; una caida mas para el que recibe
	ld a,(ix+005h)		;4da6
	cp 003h		;4da9   ; a la tercera...
	jr c,L_4DB6		;4dab
	ld de,00100h		;4dad   ; ...se acaba: 0x0100
	ld hl,0e24eh		;4db0   ; y se apunta en (0xE24E) y (0xE24F)
	ld (hl),a			;4db3
	inc hl			;4db4
	ld (hl),a			;4db5
L_4DB6:
	push ix		;4db6   ; la accion del que recibe
	pop hl			;4db8
	ld (hl),010h		;4db9   ; la 0x10, que es caer
	dec hl			;4dbb
	ld (hl),010h		;4dbc   ; y su temporizador tambien
	dec hl			;4dbe
	dec hl			;4dbf
	ld (hl),000h		;4dc0   ; (ix-3) a cero
	dec hl			;4dc2
	ld (hl),e			;4dc3   ; y los dos bytes de DE quedan delante
	dec hl			;4dc4
	ld (hl),d			;4dc5
	ld a,001h		;4dc6   ; (0xE22C) avisa de que hay alguien en el suelo
	ld (0e22ch),a		;4dc8
	ret			;4dcb
suena_el_bloqueo:
	ld a,04bh		;4dcc   ; el ruido 0x4B
	call pide_un_sonido		;4dce
apunta_el_fallo:
	ld a,(0e247h)		;4dd1   ; (0xE247), que solo cuenta uno
	or a			;4dd4
	ret nz			;4dd5
	inc a			;4dd6   ; se pone a uno
	ld (0e247h),a		;4dd7
	inc (iy+00eh)		;4dda   ; y uno mas en la cuenta del que pega
	ret			;4ddd

; ----------------------------------------------------------------------
; DATOS rampa_de_treinta_y_uno: Treinta y un bytes que bajan de 0x4C a 0x0C y
;   se quedan planos al final; los cargan 0x4ADD y 0x4BD1
;   0x4dde..0x4dfd  (31 bytes)
DATA_rampa_de_treinta_y_uno:
	defb 04ch,037h,034h,030h,02eh,02ch,028h,025h,022h,01fh,01ch,018h,018h,017h,017h,016h	; 4dde  L740.,(%".......
	defb 015h,014h,013h,012h,011h,010h,00fh,00eh,00eh,00dh,00dh,00ch,00ch,00ch,00ch	; 4dee  ...............

; ----------------------------------------------------------------------
; DATOS el_tope_plano_y_los_cuatro_ruidos: El primero, 0x0C, es el tope que
;   0x4AD6 y 0x4BCA usan cuando (0xE206) llega a 0x20; los cuatro de detras
;   -0x51, 0x4F, 0x51 y 0x4D- son el ruido de cada uno de los cuatro golpes,
;   que 0x4D3A indexa
;   0x4dfd..0x4e02  (5 bytes)
DATA_el_tope_plano_y_los_cuatro_ruidos:
	defb 00ch,051h,04fh,051h,04dh	; 4dfd

; ======================================================================
; CODIGO 0x4e02..0x524b  (1097 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; EL MARCADOR Y LAS TARJETAS DE LOS JUECES
; ======================================================================
; Las casillas del texto son ASCII: el guion de 0x59C4 carga la letra en
; las casillas 0x30 a 0x5F, asi que 0x50 es la P y 0x4B 0x4F es "KO".
; Hay dos juegos de cifras: las de 0x30 y otras que empiezan en 0x90.
; La pantalla, contada sobre la tabla de nombres de 0x3800:
; fila 16 columna  7 -> (0xE21F), la tarjeta del de la IZQUIERDA
; fila 16 columna 23 -> (0xE21E), la del de la DERECHA
; fila 18 columna 28 -> (0xE051), el asalto
; fila 20 columna  9 y columna 26 -> las dos cifras grandes
; ----------------------------------------------------------------------
pinta_el_marcador:
	ld a,(0e210h)		;4e02   ; (0xE210)
	cp 003h		;4e05   ; con 3 exacto se mira otra cosa
	jr nz,L_4E15		;4e07
	ld a,(0e258h)		;4e09   ; (0xE258), el de la izquierda
	or a			;4e0c
	jr nz,L_4E1F		;4e0d
	ld a,(0e235h)		;4e0f   ; y (0xE235), el de la derecha
	or a			;4e12
	jr nz,L_4E1F		;4e13
L_4E15:
	ld a,(0e234h)		;4e15   ; con cualquiera de los dos tocado...
	or a			;4e18
	ret nz			;4e19
	ld a,(0e257h)		;4e1a   ; (0xE257), el de la izquierda
	or a			;4e1d
	ret nz			;4e1e   ; ...no se pinta nada
L_4E1F:
	ld a,(0e003h)		;4e1f   ; el contador de cuadros
	push af			;4e22
	and 01fh		;4e23   ; uno de cada 32...
	call z,repasa_las_tarjetas		;4e25   ; ...se repasan las tarjetas
	pop af			;4e28
	bit 4,a		;4e29   ; y el bit 4 las hace parpadear
	jr nz,borra_las_tarjetas		;4e2b
	ld a,(0e21fh)		;4e2d   ; la del de la izquierda...
	ld hl,07a07h		;4e30   ; ...en la fila 16, columna 7
	call pinta_dos_cifras		;4e33
	ld a,(0e21eh)		;4e36   ; y la del de la derecha...
	ld l,017h		;4e39   ; ...en la columna 23
	jp pinta_dos_cifras		;4e3b
repasa_las_tarjetas:
	ld hl,0e218h		;4e3e   ; el castigo del de la derecha
	ld b,0ffh		;4e41   ; 0xFF, que es lo que espera 0x53F9
	ld a,(0e235h)		;4e43   ; (0xE235)
	or a			;4e46
	jr z,L_4E4E		;4e47
	ld a,(hl)			;4e49   ; lo que lleva encajado
	cp 005h		;4e4a   ; con cinco o mas encajados, no
	jr nc,L_4E51		;4e4c
L_4E4E:
	call suma_castigo		;4e4e
L_4E51:
	inc hl			;4e51   ; y el castigo del de la izquierda
	inc hl			;4e52
	ld b,0ffh		;4e53
	ld a,(0e258h)		;4e55   ; (0xE258)
	or a			;4e58
	jr z,L_4E5F		;4e59
	ld a,(hl)			;4e5b
	cp 005h		;4e5c   ; igual con cinco
	ret nc			;4e5e
L_4E5F:
	jp suma_castigo		;4e5f
borra_las_tarjetas:
	ld hl,07a07h		;4e62   ; la columna 7...
	call borra_dos_casillas		;4e65
	ld l,017h		;4e68   ; ...y la 23
borra_dos_casillas:
	ld bc,00002h		;4e6a   ; dos casillas
	ld a,001h		;4e6d   ; en blanco
	jp rellena_la_vram		;4e6f
pinta_el_asalto:
	ld hl,07a5ch		;4e72   ; fila 18, columna 28
	ld a,(0e051h)		;4e75   ; las veces que se ha empezado
pinta_dos_cifras:
	ld b,030h		;4e78   ; las cifras de 0x30, que son las normales
	jr L_4E7E		;4e7a
pinta_dos_cifras_grandes:
	ld b,090h		;4e7c   ; y las de 0x90, que son las otras
L_4E7E:
	push af			;4e7e   ; el numero, en BCD
	and 0f0h		;4e7f   ; la cifra de las decenas
	rrca			;4e81
	rrca			;4e82
	rrca			;4e83
	rrca			;4e84
	or a			;4e85   ; si es cero...
	jr z,L_4E89		;4e86   ; cero, en blanco
	or b			;4e88   ; ...se deja en blanco, y si no va con su juego
L_4E89:
	call escribe_una_casilla		;4e89
	pop af			;4e8c
	inc hl			;4e8d
L_4E8E:
	and 00fh		;4e8e   ; y las unidades siempre
	or b			;4e90   ; con su juego de cifras
	jp escribe_una_casilla		;4e91

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Las tarjetas se llevan AL REVES: aqui se van sumando faltas, y al final
; la nota es 10 menos las faltas, subidas las dos hasta que una llega al
; 10. O sea el sistema de los diez puntos del boxeo de verdad.
; ----------------------------------------------------------------------
puntua_el_asalto:
	ld hl,0e218h		;4e94   ; el castigo del de la derecha
	ld a,(hl)			;4e97
	inc hl			;4e98   ; y el de la izquierda
	inc hl			;4e99
	ld b,(hl)			;4e9a
	ld l,01eh		;4e9b   ; las dos tarjetas, en (0xE21E) y (0xE21F)
	push hl			;4e9d
	cp b			;4e9e   ; quien lleva mas?
	jr nc,L_4EA5		;4e9f
	ld e,a			;4ea1   ; se ordenan: A el mayor, B el menor
	ld a,b			;4ea2
	ld b,e			;4ea3
	inc hl			;4ea4   ; y la tarjeta, la del que peor esta
L_4EA5:
	sub b			;4ea5   ; la diferencia
	cp 003h		;4ea6   ; con tres o mas...
	jr c,L_4EAD		;4ea8
	inc (hl)			;4eaa   ; ...una falta para el mas castigado
	jr L_4EBD		;4eab
L_4EAD:
	pop hl			;4ead   ; la tarjeta del mas castigado, otra vez
	push hl			;4eae
	ld a,(0e256h)		;4eaf   ; los golpes acertados por el de la izquierda
	ld b,a			;4eb2
	ld a,(0e233h)		;4eb3   ; y los del de la derecha
	cp b			;4eb6   ; iguales, nada
	jr z,L_4EBD		;4eb7
	jr c,L_4EBC		;4eb9   ; quien menos acerto...
	inc hl			;4ebb   ; y si no, la del otro
L_4EBC:
	inc (hl)			;4ebc   ; ...se lleva la falta
L_4EBD:
	pop hl			;4ebd   ; las dos tarjetas
	push hl			;4ebe
	ld a,(0e23eh)		;4ebf   ; (0xE23E), del de la derecha
	rlca			;4ec2   ; vale doble
	add a,(hl)			;4ec3   ; a su tarjeta
	ld (hl),a			;4ec4
	inc hl			;4ec5
	ld a,(0e261h)		;4ec6   ; y (0xE261), del de la izquierda
	rlca			;4ec9   ; tambien doble
	add a,(hl)			;4eca   ; a la suya
	ld (hl),a			;4ecb
	pop hl			;4ecc
	ld b,(hl)			;4ecd   ; las faltas de la derecha
	ld a,00ah		;4ece   ; diez menos las faltas
	sub b			;4ed0
	ld (hl),a			;4ed1
	push hl			;4ed2   ; la de la derecha, para luego
	inc hl			;4ed3
	ld b,(hl)			;4ed4   ; y lo mismo con la izquierda
	ld a,00ah		;4ed5
	sub b			;4ed7
	ld (hl),a			;4ed8
	cp 00ah		;4ed9   ; si una quedo en diez, ya esta
	jr z,L_4EED		;4edb
	dec hl			;4edd   ; la de la derecha
	ld a,00ah		;4ede
	cp (hl)			;4ee0   ; estaba a diez?
	jr z,L_4EED		;4ee1
L_4EE3:
	inc (hl)			;4ee3   ; y si no, suben las dos a la vez...
	inc hl			;4ee4
	inc (hl)			;4ee5
	cp (hl)			;4ee6   ; ...hasta que una llegue al diez
	jr z,L_4EED		;4ee7
	dec hl			;4ee9
	cp (hl)			;4eea   ; y hasta que la otra tambien llegue
	jr nz,L_4EE3		;4eeb
L_4EED:
	pop hl			;4eed   ; la de la derecha
	ld a,(hl)			;4eee   ; y las dos notas, a BCD
	add a,000h		;4eef
	daa			;4ef1
	ld (hl),a			;4ef2
	inc hl			;4ef3
	ld a,(hl)			;4ef4   ; y la de la izquierda
	add a,000h		;4ef5
	daa			;4ef7
	ld (hl),a			;4ef8
	ld hl,07a9ah		;4ef9   ; la columna 26...
	ld de,07a89h		;4efc   ; ...y la 9
	ld a,(0e234h)		;4eff   ; el de la derecha, tocado?
	or a			;4f02
	jr nz,pinta_el_ko		;4f03
	ld a,(0e257h)		;4f05   ; o el de la izquierda?
	or a			;4f08
	jr z,suma_las_tarjetas		;4f09   ; ninguno: al reparto normal
	ex de,hl			;4f0b   ; y entonces se cambian
pinta_el_ko:
	xor a			;4f0c   ; el tocado se queda en 00
	call pinta_dos_cifras_grandes		;4f0d
	ex de,hl			;4f10   ; y en la otra cifra...
	ld a,(0e24fh)		;4f11   ; (0xE24F)
	or a			;4f14
	jr z,L_4F1D		;4f15
	ld a,054h		;4f17   ; ...la T de TKO
	call escribe_una_casilla		;4f19
	inc hl			;4f1c
L_4F1D:
	ld a,04bh		;4f1d   ; la K...
	call escribe_una_casilla		;4f1f
	inc hl			;4f22
	ld a,04fh		;4f23   ; ...y la O
	jp escribe_una_casilla		;4f25
suma_las_tarjetas:
	ld hl,0e21ch		;4f28   ; (0xE21C), el acumulado del de la izquierda
	ld a,(0e21eh)		;4f2b   ; su nota de este asalto
	add a,(hl)			;4f2e
	daa			;4f2f   ; en BCD
	ld (hl),a			;4f30
	push af			;4f31
	inc hl			;4f32   ; y (0xE21D), el de la derecha
	ld a,(0e21fh)		;4f33
	add a,(hl)			;4f36
	daa			;4f37
	ld (hl),a			;4f38
	ld hl,07a89h		;4f39   ; la columna 9...
	call pinta_dos_cifras_grandes		;4f3c
	pop af			;4f3f
	ld l,09ah		;4f40   ; ...y la 26
	jp pinta_dos_cifras_grandes		;4f42

; ----------------------------------------------------------------------
; ======================================================================
; DIBUJAR A LOS BOXEADORES
; ======================================================================
; Los boxeadores se pintan de dos maneras a la vez: el cuerpo son
; CASILLAS de la pantalla, que 0x4F66 saca de los archivos de figuras, y
; los guantes y la cabeza son SPRITES, que monta 0x5178. La cabecera de
; una figura -17 + 5M, con M = N para el jugador y N+1 para el rival-
; esta medida arriba, en las notas de los archivos.
; ----------------------------------------------------------------------
prepara_el_dibujo:
	ld a,(0e003h)		;4f45   ; el contador de cuadros
	bit 1,a		;4f48   ; uno de cada dos
	ret z			;4f4a
	ld a,(0e23ah)		;4f4b   ; la columna del de la derecha
	ld (0e271h),a		;4f4e   ; apuntada en (0xE271)
	ld hl,0e248h		;4f51   ; los cuatro bytes de 0xE248...
	ld de,0e278h		;4f54   ; ...a 0xE278
	ld bc,00004h		;4f57
	push hl			;4f5a
	push de			;4f5b
	push bc			;4f5c
	ldir		;4f5d
	ld l,05ch		;4f5f   ; y luego 0xE25C a 0xE27C
	ld e,07ch		;4f61   ; y el destino, 0xE27C
	jp L_54D7		;4f63
pinta_una_figura:
	ld a,(0e003h)		;4f66   ; el contador de cuadros
	and 007h		;4f69   ; los tres de abajo
	rrca			;4f6b   ; y el bit 0 aparte
	jp c,pinta_los_sprites		;4f6c   ; en los impares, solo los sprites
	push af			;4f6f
	call mira_si_toca_otra_cosa		;4f70   ; el sonido de la campana y demas
	pop af			;4f73
	push af			;4f74
	rlca			;4f75   ; palabras
	ld hl,052bch		;4f76   ; las cuatro direcciones de VRAM de 0x52BC
	call suma_a_hl		;4f79
	call saca_la_palabra		;4f7c   ; la que toca
	ld e,l			;4f7f   ; a DE
	ld a,h			;4f80
	res 5,a		;4f81   ; sin el bit 13: la misma direccion en los patrones
	ld d,a			;4f83
	pop af			;4f84
	push de			;4f85
	push hl			;4f86
	ld hl,07086h		;4f87   ; la tabla del primer archivo de figuras
	rrca			;4f8a   ; el bit 0, al acarreo
	jr nc,L_4F9C		;4f8b   ; en los pares, la del boxeador
	ld hl,052c9h		;4f8d   ; y en los impares una de las cuatro de 0x52C9
	ld a,(0e207h)		;4f90   ; (0xE207)
	and 003h		;4f93   ; cuatro tablas
	rlca			;4f95
	call suma_a_hl		;4f96
	call saca_la_palabra		;4f99   ; y esa es la tabla
L_4F9C:
	ld a,(0e27ch)		;4f9c   ; (0xE27C), la accion copiada
	push hl			;4f9f
	push af			;4fa0
	cp 012h		;4fa1   ; la 0x12
	jr nz,L_4FB5		;4fa3
	ld a,(0e003h)		;4fa5   ; el contador de cuadros
	bit 1,a		;4fa8   ; uno de cada dos
	ld hl,0c816h		;4faa   ; columna 22, pixel 200...
	jr z,L_4FB2		;4fad
	ld hl,02802h		;4faf   ; ...o columna 2, pixel 40
L_4FB2:
	ld (0e27dh),hl		;4fb2   ; en (0xE27D)
L_4FB5:
	pop af			;4fb5
	pop hl			;4fb6
	rlca			;4fb7   ; palabras
	call suma_a_hl		;4fb8   ; la figura que toca
	ld e,(hl)			;4fbb   ; y su direccion
	inc hl			;4fbc
	ld d,(hl)			;4fbd
	pop hl			;4fbe
	push de			;4fbf   ; la direccion, para la siguiente
	ex de,hl			;4fc0   ; a HL, que es donde escribe
	call saca_la_palabra		;4fc1   ; el primer puntero de la figura
	ex de,hl			;4fc4
	call vuelca_un_guion_de_pieza_con_direccion		;4fc5   ; el fondo, en las casillas
	pop de			;4fc8
	inc de			;4fc9   ; el segundo puntero
	inc de			;4fca
	push de			;4fcb
	ex de,hl			;4fcc
	call saca_la_palabra		;4fcd   ; el puntero
	ex de,hl			;4fd0
	call vuelca_un_guion_de_pieza		;4fd1   ; y este en los colores, sin fijar direccion
	pop de			;4fd4
	inc de			;4fd5   ; el tercero
	inc de			;4fd6
	pop hl			;4fd7
	push de			;4fd8
	push hl			;4fd9
	ex de,hl			;4fda   ; a HL
	call saca_la_palabra		;4fdb   ; el puntero
	ex de,hl			;4fde
	pop hl			;4fdf
	call vuelca_un_guion_con_direccion		;4fe0   ; otra vez casillas
	pop de			;4fe3
	inc de			;4fe4   ; y el cuarto
	inc de			;4fe5
	push de			;4fe6
	ex de,hl			;4fe7
	call saca_la_palabra		;4fe8   ; el puntero
	ex de,hl			;4feb
	call vuelca_un_guion		;4fec   ; y colores
	pop de			;4fef
	inc de			;4ff0   ; detras de los cuatro punteros va la cuenta de piezas
	inc de			;4ff1
	ld hl,0e278h		;4ff2   ; donde se quedo, a (0xE278)...
	ld (hl),e			;4ff5
	inc hl			;4ff6
	ld (hl),d			;4ff7
	inc hl			;4ff8
	ld (hl),001h		;4ff9   ; ...con un 1 detras
	ex de,hl			;4ffb   ; a HL
	ld b,(hl)			;4ffc   ; N, las piezas moviles
	push bc			;4ffd
	ld a,(0e003h)		;4ffe   ; el contador de cuadros
	rrca			;5001   ; el bit 1, al acarreo
	rrca			;5002
	jr nc,L_5006		;5003   ; en el turno del rival -bit 1 puesto-...
	inc b			;5005   ; ...la figura lleva un registro mas: la pieza de la segunda vuelta
L_5006:
	inc hl			;5006   ; saltarse la cuenta
L_5007:
	inc hl			;5007   ; los registros son de tres bytes
	inc hl			;5008
	inc hl			;5009
	djnz L_5007		;500a
	ld a,008h		;500c   ; y detras hay ocho que no se leen aqui
	call suma_a_hl		;500e
	pop bc			;5011
	push hl			;5012   ; los punteros a las piezas
	ld a,(0e003h)		;5013   ; el contador de cuadros
	ld hl,05800h		;5016   ; la tabla de sprites, en 0x3800+0x2000
	bit 1,a		;5019   ; el bit 1 del contador de cuadros
	push af			;501b
	jr z,L_5021		;501c
	ld hl,05980h		;501e   ; o media pantalla mas alla
L_5021:
	bit 2,a		;5021   ; y el bit 2
	jr z,L_502A		;5023
	ld a,0c0h		;5025   ; y el bit 2 la sube otras 0xC0
	call suma_a_hl		;5027
L_502A:
	call 00053h		;502a   ; BIOS SETWRT - Enables VDP to write
	pop af			;502d
	pop hl			;502e
	ex af,af'			;502f   ; el desplazamiento de color, a A'
	xor a			;5030
	ex af,af'			;5031
	jr z,L_504A		;5032   ; el jugador: todas las piezas seguidas
	ld a,(0e207h)		;5034   ; el rival: (0xE207) decide que se hace con la primera pieza
	bit 4,a		;5037   ; el bit 4: la segunda vuelta
	jr z,L_5048		;5039
	bit 0,a		;503b   ; y el bit 0: CHINA KHAN
	jr nz,L_5045		;503d
	ex af,af'			;503f
	ld a,002h		;5040   ; SANCHESS y MOAI Jr.: tras la primera pieza se salta un puntero, la primera SUSTITUYE a la segunda
	ex af,af'			;5042
	jr L_504A		;5043
L_5045:
	inc b			;5045   ; CHINA KHAN las pinta todas: la primera es su coleta
	jr L_504A		;5046
L_5048:
	inc hl			;5048   ; y en la primera vuelta la primera pieza se salta
	inc hl			;5049
L_504A:
	push hl			;504a   ; pieza por pieza
	call saca_la_palabra		;504b   ; el puntero de la pieza
	call pinta_una_pieza		;504e   ; y se pinta
	pop hl			;5051
	inc hl			;5052   ; palabras
	inc hl			;5053
	ex af,af'			;5054
	call suma_a_hl		;5055   ; el desplazamiento, otra vez
	xor a			;5058   ; y se limpia para la siguiente
	ex af,af'			;5059
	djnz L_504A		;505a   ; pieza a pieza
	ret			;505c
vuelca_un_guion_con_direccion:
	call 00053h		;505d   ; BIOS SETWRT - Enables VDP to write | aqui se fija la direccion de VRAM
vuelca_un_guion:
	ld a,(00006h)		;5060   ; el puerto de datos del VDP
	ld c,a			;5063
L_5064:
	ld a,(de)			;5064   ; el codigo: cuantos bytes
	and 07fh		;5065   ; los siete de abajo
	ret z			;5067   ; cero, se acabo
	ld b,a			;5068
	ld a,(de)			;5069   ; y el bit 7 dice como
	cp b			;506a   ; compara el byte crudo con la cuenta
	jr z,L_5078		;506b   ; sin el, un byte repetido
L_506D:
	inc de			;506d   ; con el, bytes seguidos
	call saca_el_byte_con_el_color_cambiado		;506e   ; cada uno puede cambiar de color
	out (c),a		;5071
	djnz L_506D		;5073   ; byte a byte
	inc de			;5075
	jr L_5064		;5076
L_5078:
	inc de			;5078   ; el byte a repetir
	call saca_el_byte_con_el_color_cambiado		;5079
L_507C:
	nop			;507c   ; los dos `nop` dan tiempo al VDP entre escrituras
	nop			;507d
	out (c),a		;507e
	djnz L_507C		;5080
	inc de			;5082   ; y a por el siguiente codigo
	jr L_5064		;5083

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Los sprites. La tabla de atributos esta en 0x3B00, pero aqui se escribe
; como 0x7B00 porque SETWRT solo mira catorce bits. Cuatro bytes por
; sprite: fila, columna, patron y color. El contador de cuadros reparte
; el trabajo entre cuatro cuadros -bits 1 y 2-, asi que la tabla se
; rehace por trozos y no entera.
; ----------------------------------------------------------------------
pinta_los_sprites:
	ld hl,0e278h		;5085   ; (0xE278), donde se quedo pinta_una_figura
	ld e,(hl)			;5088   ; la palabra que dejo apuntada
	inc hl			;5089
	ld a,(hl)			;508a
	or a			;508b   ; sin nada apuntado, no hay sprites
	ret z			;508c
	ld d,a			;508d
	ex de,hl			;508e   ; a HL
	ld b,(hl)			;508f   ; la cuenta de piezas
	push hl			;5090
	ld hl,07b00h		;5091   ; la tabla de atributos
	ld a,(0e003h)		;5094   ; el contador de cuadros
	bit 1,a		;5097   ; el bit 1
	ld a,l			;5099   ; la parte baja
	jr z,L_50A0		;509a
	ld l,018h		;509c   ; el bit 1 mueve seis sprites mas alla
	ld a,030h		;509e
L_50A0:
	push hl			;50a0
	ld hl,0e003h		;50a1   ; el contador de cuadros
	bit 2,(hl)		;50a4   ; y el bit 2, otros seis
	jr z,L_50AA		;50a6
	add a,018h		;50a8
L_50AA:
	pop hl			;50aa
	ex af,af'			;50ab   ; el desplazamiento de color, a A'
	call 00053h		;50ac   ; BIOS SETWRT - Enables VDP to write
	ld de,0e27eh		;50af   ; la columna de donde se pinta
	pop hl			;50b2
	call monta_los_sprites_de_una_figura		;50b3   ; y ahi van los sprites
	push hl			;50b6
	call elige_el_bloque_de_registros		;50b7   ; (0xE274) o (0xE248)
	push hl			;50ba
	ld hl,07b00h		;50bb   ; la tabla de atributos, otra vez
	ld de,0e23bh		;50be   ; la columna del de la derecha
	ld a,(0e003h)		;50c1   ; el contador de cuadros
	bit 1,a		;50c4   ; el bit 1
	ld a,l			;50c6
	jr nz,L_50DC		;50c7
	ld l,018h		;50c9   ; en los pares se cambia de sitio...
	ld de,0e25eh		;50cb   ; ...y de boxeador: el de la izquierda
	ld a,030h		;50ce
	push hl			;50d0
	ld hl,0e003h		;50d1
	bit 2,(hl)		;50d4   ; y el bit 2
	jr nz,L_50E6		;50d6
	add a,018h		;50d8   ; seis sprites mas alla
	jr L_50E6		;50da
L_50DC:
	push hl			;50dc
	ld hl,0e003h		;50dd   ; el contador de cuadros
	bit 2,(hl)		;50e0   ; el bit 2
	jr z,L_50E6		;50e2
	add a,018h		;50e4   ; seis sprites mas alla
L_50E6:
	pop hl			;50e6
	ex af,af'			;50e7   ; el desplazamiento de color
	call 00053h		;50e8   ; BIOS SETWRT - Enables VDP to write | y ahi van los del otro
	pop hl			;50eb
	call saca_la_palabra		;50ec   ; el puntero de la figura
	ld a,h			;50ef   ; con la parte alta a cero no hay figura
	or a			;50f0
	jp z,no_habia_figura		;50f1
	ld b,(hl)			;50f4   ; la cuenta de piezas
	call monta_los_sprites_de_una_figura		;50f5   ; y sus sprites
	ld a,(0e22dh)		;50f8   ; (0xE22D)
	or a			;50fb
	jr nz,L_510B		;50fc   ; con algo apuntado, las nueve tiras de 0x5254
	ld hl,079d1h		;50fe   ; fila 14, columna 17
	ld bc,00002h		;5101   ; dos casillas
	ld a,001h		;5104   ; en blanco
	call rellena_la_vram		;5106
	jr L_512C		;5109
L_510B:
	ld hl,078e3h		;510b   ; fila 7, columna 3
	ld b,009h		;510e   ; nueve tiras
	ld de,05254h		;5110   ; las ternas de 0x5254
	ld a,(00006h)		;5113   ; el puerto de datos del VDP
	ld c,a			;5116
L_5117:
	push bc			;5117
	ld a,(de)			;5118   ; cuantas casillas
	ld b,a			;5119
	inc de			;511a
	call 00053h		;511b   ; BIOS SETWRT - Enables VDP to write | y donde
L_511E:
	ld a,(de)			;511e   ; la misma casilla, repetida
	out (c),a		;511f
	djnz L_511E		;5121
	inc de			;5123
	ld a,(de)			;5124   ; el tercer byte dice cuanto se baja
	call suma_a_hl		;5125
	inc de			;5128
	pop bc			;5129
	djnz L_5117		;512a
L_512C:
	call pinta_la_campana		;512c   ; la campana y el arbitro
	pop hl			;512f
	ex de,hl			;5130   ; a DE
	call prepara_la_cuenta		;5131   ; la cuenta del arbitro
	call elige_el_bloque_de_registros		;5134   ; (0xE274) o (0xE248)
	call saca_la_palabra		;5137   ; el puntero
	ld a,h			;513a   ; nada que pintar
	or a			;513b
	ret z			;513c
	ld b,(hl)			;513d   ; la cuenta de piezas
	ld a,(0e003h)		;513e   ; el contador de cuadros
	rrca			;5141   ; el bit 1, al acarreo
	rrca			;5142
	jr c,L_5146		;5143   ; en el turno del rival...
	inc b			;5145   ; ...un registro mas, el de la segunda vuelta
L_5146:
	inc hl			;5146
L_5147:
	inc hl			;5147   ; los registros son de tres bytes
	inc hl			;5148
	inc hl			;5149
	djnz L_5147		;514a
	ex de,hl			;514c   ; a DE
	ld a,(0e003h)		;514d   ; el contador de cuadros
	and 007h		;5150   ; de 0 a 7
	exx			;5152
	srl a		;5153   ; entre dos: de 0 a 3
	ld hl,052c4h		;5155   ; los cuatro de 0x52C4
	call suma_a_hl		;5158
	ld d,(hl)			;515b   ; y ese es el patron de partida
	exx			;515c
	ld a,(0e271h)		;515d   ; la columna apuntada en (0xE271)
	ld l,a			;5160
	jp L_5213		;5161
no_habia_figura:
	pop bc			;5164   ; la pila, en su sitio
	ret			;5165
mira_si_toca_otra_cosa:
	ld a,(0e22dh)		;5166   ; (0xE22D)
	or a			;5169
	ret nz			;516a   ; con algo apuntado, nada
	ld a,(0e210h)		;516b   ; (0xE210)
	or a			;516e
	ret z			;516f   ; a cero, nada
	ld a,(0e27fh)		;5170   ; y (0xE27F)
	or a			;5173
	jp z,anda_hacia_el_cuadrilatero		;5174   ; a cero, el sonido de la campana
	ret			;5177

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Los cuatro bytes de cada sprite, seguidos por el puerto de datos: a la
; fila se le suma 0x3F, a la columna la del boxeador, el patron va en A'
; y sube de cuatro en cuatro, y el color sale del tercer byte del
; registro. Los sprites que sobran se aparcan en la fila 0xCF.
; ----------------------------------------------------------------------
monta_los_sprites_de_una_figura:
	exx			;5178   ; al otro juego de registros
	ex af,af'			;5179   ; el desplazamiento de color
	ld l,a			;517a   ; el desplazamiento, a L
	and 0e0h		;517b   ; los tres de arriba
	or a			;517d
	ld a,l			;517e   ; y de vuelta a A
	ld l,000h		;517f   ; sin paso entre registros
	exx			;5181
	push af			;5182   ; el desplazamiento, de vuelta a A'
	ex af,af'			;5183
	pop af			;5184
	jr z,L_519E		;5185   ; el jugador: todos los registros seguidos
	ld a,(0e207h)		;5187   ; el rival: (0xE207) decide, igual que en 0x5034
	bit 4,a		;518a   ; el bit 4: la segunda vuelta
	jr z,L_519B		;518c
	bit 0,a		;518e   ; y el bit 0: CHINA KHAN
	jr nz,L_5198		;5190
	exx			;5192
	ld l,003h		;5193   ; SANCHESS y MOAI Jr.: tras el primer registro se salta el segundo
	exx			;5195
	jr L_519E		;5196
L_5198:
	inc b			;5198   ; CHINA KHAN: un sprite mas, la coleta
	jr L_519E		;5199
L_519B:
	inc hl			;519b   ; primera vuelta: el primer registro se salta
	inc hl			;519c
	inc hl			;519d
L_519E:
	ld a,006h		;519e   ; seis sprites en total...
	sub b			;51a0   ; ...menos los que se van a pintar
	push af			;51a1
	ld a,(00006h)		;51a2   ; el puerto de datos del VDP
	ld c,a			;51a5
L_51A6:
	inc hl			;51a6   ; la fila del registro
	ld a,03fh		;51a7   ; la fila, con 0x3F de margen
	add a,(hl)			;51a9
	out (c),a		;51aa   ; y al puerto
	inc hl			;51ac   ; el byte siguiente del registro
	ld a,(de)			;51ad   ; la columna del boxeador...
	add a,(hl)			;51ae   ; ...mas la del registro
	out (c),a		;51af
	ex af,af'			;51b1   ; el patron, que va en A'
	out (c),a		;51b2
	inc hl			;51b4
	add a,004h		;51b5   ; cada sprite se come cuatro patrones
	push af			;51b7
	ex af,af'			;51b8
	pop af			;51b9
	cp 030h		;51ba   ; por debajo del patron 0x30, el color tal cual
	jr c,L_51D0		;51bc
	ld a,(0e207h)		;51be   ; y de los del rival solo MOAI Jr.: bits 4 y 1 de (0xE207)
	bit 4,a		;51c1
	jr z,L_51D0		;51c3
	bit 1,a		;51c5
	jr z,L_51D0		;51c7
	ld a,(hl)			;51c9   ; su color 4, el azul del moai...
	cp 004h		;51ca
	ld a,00ch		;51cc   ; ...se cambia por el 0x0C, verde
	jr z,L_51D1		;51ce
L_51D0:
	ld a,(hl)			;51d0
L_51D1:
	out (c),a		;51d1   ; y ese es el color
	exx			;51d3   ; al otro juego
	ld a,l			;51d4   ; el paso entre registros
	ld l,000h		;51d5
	exx			;51d7
	call suma_a_hl		;51d8   ; al registro siguiente
	djnz L_51A6		;51db   ; sprite a sprite
	inc hl			;51dd   ; y uno mas al acabar
	pop af			;51de   ; los que sobran
	or a			;51df
	ret z			;51e0   ; ninguno, se acabo
	ld b,a			;51e1
	ld a,0cfh		;51e2   ; la fila 0xCF, que esta fuera de la pantalla
L_51E4:
	out (c),a		;51e4   ; cuatro bytes por sprite...
	nop			;51e6
	out (c),a		;51e7
	nop			;51e9
	out (c),a		;51ea
	nop			;51ec
	out (c),a		;51ed
	nop			;51ef
	djnz L_51E4		;51f0   ; ...y el resto, aparcados
	ret			;51f2
elige_el_bloque_de_registros:
	ld hl,0e274h		;51f3   ; (0xE274)
	ld a,(0e003h)		;51f6   ; el contador de cuadros
	rrca			;51f9
	rrca			;51fa
	ret c			;51fb   ; uno de cada cuatro se queda con ese...
	ld l,048h		;51fc   ; ...y los demas con (0xE248)
	ret			;51fe
prepara_la_cuenta:
	exx			;51ff   ; al otro juego de registros
	ld a,(0e003h)		;5200   ; el contador de cuadros
	and 007h		;5203   ; de 0 a 7
	srl a		;5205   ; entre dos
	ld hl,052c5h		;5207   ; los cuatro de 0x52C5
	call suma_a_hl		;520a
	ld d,(hl)			;520d   ; el patron de partida
	exx			;520e
	ld a,(0e27dh)		;520f   ; y la columna de (0xE27D)
	ld l,a			;5212
L_5213:
	ld h,079h		;5213   ; la tabla de nombres, fila 8
	ld a,(00006h)		;5215   ; el puerto de datos del VDP
	exx			;5218
	ld c,a			;5219
	exx			;521a
	ld b,008h		;521b   ; ocho filas
L_521D:
	push bc			;521d
	push hl			;521e
	ld a,(de)			;521f   ; el nibble alto: donde empieza
	and 0f0h		;5220
	rrca			;5222
	rrca			;5223
	rrca			;5224
	rrca			;5225
	cp 008h		;5226   ; de 8 en adelante, esa fila se salta
	jr nc,L_523C		;5228
	add a,l			;522a   ; la columna
	ld l,a			;522b
	call 00053h		;522c   ; BIOS SETWRT - Enables VDP to write
	ld a,(de)			;522f   ; el nibble bajo: cuantas casillas
	and 00fh		;5230
	exx			;5232
	ld b,a			;5233   ; esas van al patron
	ld a,d			;5234   ; el patron
L_5235:
	out (c),a		;5235   ; correlativas
	inc a			;5237
	djnz L_5235		;5238
	ld d,a			;523a   ; y sigue por donde iba
	exx			;523b
L_523C:
	inc de			;523c   ; la casilla siguiente
	pop hl			;523d
	ld a,020h		;523e   ; la fila de abajo
	add a,l			;5240
	ld l,a			;5241
	pop bc			;5242
	djnz L_521D		;5243   ; ocho veces
	ret			;5245
saca_la_palabra:
	ld a,(hl)			;5246   ; (HL) a HL, que es lo que hacen todas las tablas de punteros
	inc hl			;5247
	ld h,(hl)			;5248
	ld l,a			;5249
	ret			;524a

; ----------------------------------------------------------------------
; DATOS nueve_unos: Nueve bytes, los cinco primeros a uno
;   0x524b..0x5254  (9 bytes)
DATA_nueve_unos:
	defb 001h,001h,001h,001h,001h,026h,025h,024h,01dh	; 524b  .....&%$.

; ----------------------------------------------------------------------
; DATOS nueve_ternas: Veintisiete bytes que 0x5110 recorre de tres en tres
;   0x5254..0x526f  (27 bytes)
DATA_nueve_ternas:
	defb 01ah,01dh,020h	; 5254
	defb 01ah,024h,020h	; 5257
	defb 01ah,025h,020h	; 525a
	defb 01ah,026h,01fh	; 525d
	defb 01ch,001h,01fh	; 5260
	defb 01eh,001h,01fh	; 5263
	defb 020h,001h,01fh	; 5266
	defb 020h,001h,020h	; 5269
	defb 020h,001h,020h	; 526c

; ======================================================================
; CODIGO 0x526f..0x52bc  (77 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El cambio de color de MOAI Jr. En el turno del rival -bit 1 del
; contador-, con el bit 4 de (0xE207) puesto y (0xE207) & 3 == 2, el
; color 4 -el azul del moai- pasa a 0x0C, verde, tinta y fondo. Es lo
; unico que distingue el cuerpo de MOAI Jr. del de MOAI KING; la cara
; se la cambia 0x5034 con la pieza de la segunda vuelta.
; ----------------------------------------------------------------------
saca_el_byte_con_el_color_cambiado:
	ld a,(0e003h)		;526f   ; el contador de cuadros
	bit 1,a		;5272   ; el bit 1
	jr z,saca_el_byte_tal_cual		;5274
	ld a,(0e207h)		;5276   ; (0xE207)
	bit 4,a		;5279   ; el bit 4
	jr z,saca_el_byte_tal_cual		;527b
	and 003h		;527d   ; los dos de abajo
	cp 002h		;527f   ; solo con el 2: el archivo del moai, o sea MOAI Jr.
	jr nz,saca_el_byte_tal_cual		;5281
	ld a,(de)			;5283   ; el byte
	and 00fh		;5284   ; el fondo
	ld h,a			;5286
	cp 004h		;5287   ; el 4...
	jr nz,L_528D		;5289
	ld h,00ch		;528b   ; ...pasa a 0x0C
L_528D:
	ld a,(de)			;528d   ; y la tinta
	and 0f0h		;528e
	cp 040h		;5290   ; el 4...
	jr nz,L_5296		;5292
	ld a,0c0h		;5294   ; ...pasa a 0x0C
L_5296:
	or h			;5296   ; y se juntan
	ret			;5297
saca_el_byte_tal_cual:
	ld a,(de)			;5298   ; el byte, sin tocar
	ret			;5299
vuelca_un_guion_de_pieza_con_direccion:
	call 00053h		;529a   ; BIOS SETWRT - Enables VDP to write | aqui se fija la direccion de VRAM
vuelca_un_guion_de_pieza:
	ld a,(00006h)		;529d   ; el puerto de datos del VDP
	ld c,a			;52a0
L_52A1:
	ld a,(de)			;52a1   ; el codigo: cuantos bytes
	and 07fh		;52a2   ; los siete de abajo
	ret z			;52a4   ; cero, se acabo
	ld b,a			;52a5
	ld a,(de)			;52a6   ; y el bit 7 dice como
	inc de			;52a7
	rlca			;52a8   ; el bit 7, al acarreo
	jr c,L_52B3		;52a9   ; con el puesto, bytes seguidos
L_52AB:
	ld a,(de)			;52ab   ; sin el, la misma repetida
	out (c),a		;52ac
	djnz L_52AB		;52ae
	inc de			;52b0   ; el byte a repetir
	jr L_52A1		;52b1
L_52B3:
	ex de,hl			;52b3   ; `outi` va con HL, asi que se cambian
L_52B4:
	outi		;52b4   ; dos bytes por vuelta
	nop			;52b6
	jr nz,L_52B4		;52b7
	ex de,hl			;52b9   ; y se devuelven
	jr L_52A1		;52ba

; ----------------------------------------------------------------------
; DATOS cuatro_direcciones_de_vram: Cuatro palabras -0x6980, 0x6AC0, 0x6C00 y
;   0x6D40- que 0x4F76 indexa; con el bit 14 quitado son 0x2980, 0x2AC0,
;   0x2C00 y 0x2D40
;   0x52bc..0x52c4  (8 bytes)
DATA_cuatro_direcciones_de_vram:
	defw 06980h,06ac0h,06c00h,06d40h	; 52bc  -> L_6980 0x6ac0 0x6c00 0x6d40

; ----------------------------------------------------------------------
; DATOS patrones_de_partida_del_boxeador: Cinco bytes -0xA8, 0x30, 0x58, 0x80
;   y 0xA8- que 0x5155 lee desde el primero y 0x5207 desde el segundo, con el
;   mismo indice: la misma vuelta, corrida un puesto
;   0x52c4..0x52c9  (5 bytes)
DATA_patrones_de_partida_del_boxeador:
	defb 0a8h,030h,058h,080h,0a8h	; 52c4

; ----------------------------------------------------------------------
; DATOS tablas_de_los_archivos_del_rival: Las tres tablas de archivo que
;   0x4F8D indexa con (0xE207) & 3: 0x825C, 0x9670 y 0xABB4, o sea los
;   archivos de figuras 2, 3 y 4
;   0x52c9..0x52cf  (6 bytes)
DATA_tablas_de_los_archivos_del_rival:
	defw 0825ch,09670h,0abb4h	; 52c9  -> DATA_punteros_del_archivo_2 DATA_punteros_del_archivo_3 DATA_punteros_del_archivo_4

; ======================================================================
; CODIGO 0x52cf..0x53d5  (262 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; LA CAMPANA, EL ARBITRO Y LAS BARRAS DE CASTIGO
; ======================================================================
; ----------------------------------------------------------------------
toca_la_campana:
	ld hl,0e283h		;52cf   ; (0xE283), la marca de que ya sono
	ld a,(hl)			;52d2
	or a			;52d3   ; sin poner todavia?
	jr nz,ya_sono_la_campana		;52d4   ; con ella puesta, se sigue con lo de despues
	ld a,(0e210h)		;52d6   ; (0xE210)
	or a			;52d9
	jr z,L_52E1		;52da
	ld a,(0e27fh)		;52dc   ; y (0xE27F)
	or a			;52df
	ret z			;52e0   ; a cero, todavia no
L_52E1:
	ld a,(0e1ffh)		;52e1   ; (0xE1FF)
	or a			;52e4
	ret nz			;52e5   ; con algo, tampoco
	ld a,(0e313h)		;52e6   ; y con un sonido sonando...
	or a			;52e9
	ret nz			;52ea   ; ...se espera a que acabe
	inc a			;52eb   ; la marca, puesta
	ld (hl),a			;52ec
	ld a,03ch		;52ed   ; sesenta cuadros a los dos boxeadores
	ld (0e237h),a		;52ef
	ld (0e25ah),a		;52f2
	ld a,004h		;52f5   ; y un 4 en (0xE26D)
	ld (0e26dh),a		;52f7
	ld a,001h		;52fa   ; y un 1 en (0xE12B)
	ld (0e12bh),a		;52fc
	ret			;52ff
ya_sono_la_campana:
	ld a,(0e25ah)		;5300   ; (0xE25A), el temporizador del de la izquierda
	cp 010h		;5303   ; por debajo de 0x10...
	jr nc,L_530C		;5305
	ld hl,0e22dh		;5307   ; ...se apunta un 1 en (0xE22D)
	ld (hl),001h		;530a
L_530C:
	ld a,(0e22ch)		;530c   ; con alguien en el suelo, nada
	or a			;530f
	ret nz			;5310
	ld a,(0e003h)		;5311   ; el contador de cuadros
	and 00fh		;5314   ; uno de cada 16
	ret nz			;5316
	ld l,06dh		;5317   ; (0xE26D)
	ld a,(hl)			;5319
	cp 000h		;531a   ; a cero...
	jr nz,L_5321		;531c
	ld (hl),004h		;531e   ; ...se pone a 4
	ret			;5320
L_5321:
	cp 004h		;5321   ; y si vale 4...
	ret nz			;5323
	inc (hl)			;5324   ; ...sube a 5
	ret			;5325
pinta_al_arbitro:
	ld a,(0e003h)		;5326   ; el contador de cuadros
	and 01fh		;5329   ; uno de cada 32
	ret nz			;532b
	ld hl,0e140h		;532c   ; (0xE140), que alterna entre 0 y 1
	ld a,(hl)			;532f
	xor 001h		;5330   ; y cambia
	ld (hl),a			;5332
	ld a,(0e313h)		;5333   ; y solo con el sonido 0x53 sonando, que es el de la cuenta
	cp 053h		;5336
	ret nz			;5338
	ld a,(0e211h)		;5339   ; (0xE211)
	rrca			;533c   ; su bit 0
	jr nc,L_534C		;533d
	ld a,(0e003h)		;533f   ; el contador de cuadros
	bit 6,a		;5342   ; el bit 6 reparte los dos dibujos
	push af			;5344
	call z,pinta_al_arbitro_al_otro_lado		;5345   ; uno de cada dos, al otro lado
	pop af			;5348
	jr nz,L_5352		;5349
	ret			;534b
L_534C:
	ld a,(0e258h)		;534c   ; (0xE258), el de la izquierda
	or a			;534f
	jr z,mira_al_de_la_derecha		;5350   ; sin tocar, se mira el otro
L_5352:
	ld hl,07830h		;5352   ; fila 1, columna 16
	ld de,0680ch		;5355   ; el guion por filas de 0x680C
	call pinta_por_filas		;5358
	ld hl,0e140h		;535b   ; (0xE140) elige uno de los dos guiones cortos
	call elige_guion_corto		;535e
	ld hl,07892h		;5361   ; fila 4, columna 18
	call descomprime		;5364
	ld a,(0e140h)		;5367   ; y el otro va con el contrario
	xor 001h		;536a
	call elige_guion_corto_con_a		;536c
	ld hl,07879h		;536f   ; fila 3, columna 25
	jp descomprime		;5372
mira_al_de_la_derecha:
	ld a,(0e235h)		;5375   ; (0xE235)
	or a			;5378
	ret z			;5379   ; sin tocar, nada
pinta_al_arbitro_al_otro_lado:
	call el_arbitro_a_la_izquierda		;537a   ; el otro dibujo grande
	ld hl,0e140h		;537d   ; (0xE140), igual que arriba
	call elige_guion_corto		;5380
	ld hl,07889h		;5383   ; fila 4, columna 9
	call descomprime		;5386
	ld a,(0e140h)		;5389   ; y el contrario
	xor 001h		;538c
	call elige_guion_corto_con_a		;538e
	ld hl,07862h		;5391   ; fila 3, columna 2
	jp descomprime		;5394
el_arbitro_a_la_izquierda:
	ld hl,07820h		;5397   ; fila 1, columna 0
	ld de,067c8h		;539a   ; el guion por filas de 0x67C8
pinta_por_filas:		; Guion por filas: 0xFF baja una fila, 0x00 acaba, y B desplaza el codigo de casilla
	ld b,000h		;539d   ; sin desplazar
	ld a,(0e313h)		;539f   ; el sonido que suena
	cp 053h		;53a2   ; con el sonido de la cuenta...
	jr nz,L_53AF		;53a4
	ld a,(0e003h)		;53a6   ; el contador de cuadros
	bit 5,a		;53a9   ; y su bit 5
	jr z,L_53AF		;53ab
	ld b,02ah		;53ad   ; ...las casillas se desplazan 0x2A
L_53AF:
	ld a,(00006h)		;53af   ; el puerto de datos del VDP
	ld c,a			;53b2
L_53B3:
	ld a,020h		;53b3   ; una fila mas abajo
	call suma_a_hl		;53b5
	call prepara_la_escritura		;53b8
L_53BB:
	ld a,(de)			;53bb   ; la casilla
	or a			;53bc   ; 0x00 acaba
	ret z			;53bd
	inc de			;53be
	cp 0ffh		;53bf   ; 0xFF baja una fila
	jr z,L_53B3		;53c1
	add a,b			;53c3   ; y las demas van con su desplazamiento
	out (c),a		;53c4
	jr L_53BB		;53c6
elige_guion_corto:
	ld a,(hl)			;53c8   ; (0xE140)
elige_guion_corto_con_a:
	add a,a			;53c9   ; palabras
	ld hl,053d5h		;53ca   ; los dos punteros de 0x53D5
	call suma_a_hl		;53cd
	call saca_la_palabra		;53d0
	ex de,hl			;53d3   ; y el guion, a DE
	ret			;53d4

; ----------------------------------------------------------------------
; DATOS dos_guiones_por_filas: Dos punteros, 0x53D9 y 0x53DF, que 0x53CA
;   indexa
;   0x53d5..0x53d9  (4 bytes)
DATA_dos_guiones_por_filas:
	defw 053d9h,053dfh	; 53d5  -> DATA_guion_por_filas_1 DATA_guion_por_filas_2

; ----------------------------------------------------------------------
; DATOS guion_por_filas_1: Seis casillas en una fila: 0x84 y cuatro mas
;   0x53d9..0x53df  (6 bytes)
DATA_guion_por_filas_1:
	defb 084h,0b4h,0b5h,0b6h,0b7h,000h	; 53d9

; ----------------------------------------------------------------------
; DATOS guion_por_filas_2: Siete casillas en una fila
;   0x53df..0x53e6  (7 bytes)
DATA_guion_por_filas_2:
	defb 085h,0b8h,0b9h,0bah,0bbh,0bch,000h	; 53df

; ======================================================================
; CODIGO 0x53e6..0x5445  (95 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El castigo de cada boxeador son DOS bytes: el nivel, de 0 a 8, y lo que
; lleva acumulado dentro del nivel. Se sube de nivel al pasar el tope, y
; el tope sale de 0x5445: 0x10 por debajo del nivel 5, y 0x1A, 0x14 y
; 0x10 en los niveles 5, 6 y 7. Con B negativo -0xFF- se recupera.
; ----------------------------------------------------------------------
aplica_los_golpes_encajados:
	ld hl,0e216h		;53e6   ; (0xE216), lo que le entro al de la derecha
	ld b,(hl)			;53e9
	ld (hl),000h		;53ea   ; y se vacia
	ld l,018h		;53ec   ; su castigo esta en (0xE218)
	call suma_castigo		;53ee
	ld hl,0e217h		;53f1   ; (0xE217), lo del de la izquierda
	ld b,(hl)			;53f4
	ld (hl),000h		;53f5
	ld l,01ah		;53f7   ; y el suyo en (0xE21A)
suma_castigo:
	push de			;53f9   ; sin tocar DE ni HL
	push hl			;53fa
	call suma_castigo_de_verdad		;53fb
	pop hl			;53fe
	pop de			;53ff
	ret			;5400
suma_castigo_de_verdad:
	ld a,(hl)			;5401   ; el nivel
	cp 008h		;5402   ; el 8 es el tope, y no se pasa de ahi
	ret nc			;5404
	cp 005h		;5405   ; por debajo del 5...
	ld a,010h		;5407   ; ...el tope es 0x10
	jr c,L_5417		;5409
	ld a,(hl)			;540b   ; y del 5 al 7 sale de la tabla
	sub 005h		;540c
	push de			;540e
	ld de,05445h		;540f
	call suma_a_de		;5412
	ld a,(de)			;5415
	pop de			;5416
L_5417:
	ld c,a			;5417   ; el tope, a C
	inc hl			;5418   ; lo acumulado
	ld a,b			;5419   ; mas lo que entra
	add a,(hl)			;541a
	ld b,a			;541b
	jp p,L_543E		;541c   ; si no se ha ido por debajo de cero
	dec hl			;541f   ; el nivel
	ld a,(hl)			;5420
	or a			;5421   ; ya a cero, no baja mas
	ret z			;5422
	dec (hl)			;5423   ; y si no, un nivel menos
	ld c,010h		;5424   ; con su tope
	ld a,(hl)			;5426
	cp 005h		;5427   ; por debajo del 5, el 0x10 de siempre
	jr c,L_5435		;5429
	sub 005h		;542b
	ld de,05445h		;542d
	call suma_a_de		;5430
	ld a,(de)			;5433
	ld c,a			;5434
L_5435:
	inc hl			;5435   ; lo acumulado
	ld a,b			;5436   ; lo que sobraba, en negativo
	neg		;5437
	ld b,a			;5439
	ld a,c			;543a   ; y se cuenta desde el tope del nivel de abajo
	sub b			;543b
	ld (hl),a			;543c
	ret			;543d
L_543E:
	ld (hl),a			;543e   ; lo acumulado
	sub c			;543f   ; llega al tope?
	ret c			;5440   ; no, y ahi se queda
	ld (hl),a			;5441   ; si: se le quita el tope...
	dec hl			;5442
	inc (hl)			;5443   ; ...y sube un nivel
	ret			;5444

; ----------------------------------------------------------------------
; DATOS tres_topes: 0x1A, 0x14 y 0x10; los cargan 0x4D6E, 0x540F y 0x542D
;   0x5445..0x5448  (3 bytes)
DATA_tres_topes:
	defb 01ah,014h,010h	; 5445

; ======================================================================
; CODIGO 0x5448..0x54a1  (89 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Las dos barras de castigo son UNA sola tira de 22 casillas en la fila
; 22, columna 5: la del de la izquierda se come casillas desde el
; principio y la del de la derecha desde el final. La tira se monta en
; 0xE2B0 y se vuelca de una vez.
; ----------------------------------------------------------------------
pinta_las_barras:
	ld hl,054a1h		;5448   ; las 22 casillas de 0x54A1...
	ld de,0e2b0h		;544b   ; ...a 0xE2B0
	push de			;544e
	ld bc,00016h		;544f
	ldir		;5452
	ld hl,0e2b0h		;5454   ; desde el principio
	ld bc,06201h		;5457   ; casilla 0x62, de una en una
	ld a,(0e21ah)		;545a   ; el castigo del de la izquierda
	ld de,0e2b6h		;545d   ; y su parpadeo en 0xE2B6
	call come_casillas_de_la_barra		;5460
	ld l,0c5h		;5463   ; y ahora desde el final
	ld bc,063ffh		;5465   ; casilla 0x63, hacia atras
	ld a,(0e218h)		;5468   ; el castigo del de la derecha
	ld e,0beh		;546b   ; y el suyo en 0xE2BE
	call come_casillas_de_la_barra		;546d
	pop de			;5470
	ld hl,07ac5h		;5471   ; fila 22, columna 5
	ld bc,00016h		;5474   ; las 22
	jp vuelca_en_la_vram		;5477
come_casillas_de_la_barra:
	or a			;547a   ; sin castigo, entera
	ret z			;547b
	cp 008h		;547c   ; del nivel 8...
	jr c,L_5482		;547e
	ld a,007h		;5480   ; ...no se pasa
L_5482:
	push af			;5482
	cp 006h		;5483   ; por debajo del 6, sin parpadeo
	ld a,000h		;5485
	jr c,L_5497		;5487
	ld a,(0e003h)		;5489   ; el contador de cuadros
	bit 4,a		;548c   ; y su bit 4 lo hace parpadear
	jr z,L_5497		;548e
	inc b			;5490   ; dos casillas mas alla
	inc b			;5491
	ex de,hl			;5492
	ld (hl),b			;5493   ; las dos que avisan
	inc hl			;5494
	ld (hl),b			;5495
	ex de,hl			;5496
L_5497:
	pop af			;5497
	ld b,a			;5498   ; tantas casillas como el nivel
L_5499:
	ld (hl),000h		;5499   ; borradas
	ld a,c			;549b   ; y de una en una o hacia atras, segun C
	add a,l			;549c
	ld l,a			;549d
	djnz L_5499		;549e
	ret			;54a0

; ----------------------------------------------------------------------
; DATOS las_veintidos_casillas_de_la_barra: La tira de la barra de castigo,
;   que 0x5448 copia a 0xE2B0 para comersela por los dos extremos antes de
;   volcarla a la fila 22
;   0x54a1..0x54b7  (22 bytes)
DATA_las_veintidos_casillas_de_la_barra:
	defb 060h,060h,060h,060h,060h,062h,062h,062h	; 54a1  `````bbb
	defb 02ch,02bh,02dh,02eh,020h,021h,063h,063h	; 54a9  ,+-. !cc
	defb 063h,061h,061h,061h,061h,061h	; 54b1

; ======================================================================
; CODIGO 0x54b7..0x561f  (360 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; MONTAR LA PANTALLA DE COMBATE
; ======================================================================
; ----------------------------------------------------------------------
pinta_al_de_la_izquierda:
	ld a,(0e003h)		;54b7   ; el contador de cuadros
	bit 1,a		;54ba   ; uno de cada dos
	ret nz			;54bc
	ld a,(0e25dh)		;54bd   ; su columna...
	ld (0e271h),a		;54c0   ; ...a (0xE271)
	ld hl,0e274h		;54c3   ; los cuatro de 0xE274...
	ld de,0e278h		;54c6   ; ...a 0xE278
	ld bc,00004h		;54c9
	push hl			;54cc
	push de			;54cd
	push bc			;54ce
	ldir		;54cf
	ld hl,0e239h		;54d1   ; y su accion, columna y pixel
	ld de,0e27ch		;54d4
L_54D7:
	ld c,003h		;54d7   ; tres bytes
	push hl			;54d9
	push de			;54da
	push bc			;54db
	ldir		;54dc   ; a la zona de trabajo
	call pinta_una_figura		;54de   ; y ahi se pinta
	pop bc			;54e1
	pop hl			;54e2
	pop de			;54e3
	ldir		;54e4   ; lo de antes, de vuelta
	pop bc			;54e6
	pop hl			;54e7
	pop de			;54e8
	ldir		;54e9   ; y los otros cuatro tambien
	ret			;54eb
pinta_una_pieza_con_direccion:
	ex de,hl			;54ec   ; aqui se fija la direccion de VRAM
	call 00053h		;54ed   ; BIOS SETWRT - Enables VDP to write
	ex de,hl			;54f0
pinta_una_pieza:
	push bc			;54f1
	ld b,020h		;54f2   ; 32 bytes por pieza
	ld a,(00006h)		;54f4   ; el puerto de datos del VDP
	ld c,a			;54f7
L_54F8:
	ld a,(hl)			;54f8   ; el byte
	or a			;54f9   ; el cero es la marca de hueco
	jr z,L_5503		;54fa
	out (c),a		;54fc   ; y los demas van tal cual
L_54FE:
	inc hl			;54fe   ; byte a byte
	djnz L_54F8		;54ff
	pop bc			;5501
	ret			;5502
L_5503:
	inc b			;5503   ; el byte siguiente dice cuantos
	inc hl			;5504
	ld d,(hl)			;5505
L_5506:
	out (c),a		;5506   ; tantos ceros
	dec b			;5508   ; el hueco cuenta como bytes escritos
	dec d			;5509   ; hasta acabar el hueco
	jr nz,L_5506		;550a
	jr L_54FE		;550c
pinta_la_campana:
	ld hl,0e26eh		;550e   ; (0xE26E)
	ld a,(hl)			;5511
	or a			;5512   ; con algo, nada
	ret nz			;5513
	dec hl			;5514   ; (0xE26D)
	ld a,(hl)			;5515
	cp 005h		;5516   ; el 5...
	jr nz,L_551E		;5518
	inc hl			;551a
	set 0,(hl)		;551b   ; ...pone el bit 0 de (0xE26E)
	ret			;551d
L_551E:
	ld a,(hl)			;551e   ; palabras
	rlca			;551f
	ld de,068a8h		;5520   ; las parejas de 0x68A8
	call suma_a_de		;5523
	ld a,(de)			;5526   ; los dos bytes...
	ld b,a			;5527
	inc de			;5528
	ld a,(de)			;5529
	ld d,a			;552a   ; ...a DE
	ld e,b			;552b
	dec hl			;552c   ; (0xE26C) dice donde
	ld l,(hl)			;552d
	ld h,078h		;552e   ; fila 0 de la tabla de nombres
	ld a,(00006h)		;5530   ; el puerto de datos del VDP
	ld c,a			;5533
	ld b,007h		;5534   ; siete filas
L_5536:
	push bc			;5536
	call 00053h		;5537   ; BIOS SETWRT - Enables VDP to write
	ld b,006h		;553a   ; de seis casillas
L_553C:
	ld a,(de)			;553c
	out (c),a		;553d
	inc de			;553f
	djnz L_553C		;5540
	ld a,020h		;5542   ; y una fila mas abajo
	call suma_a_hl		;5544
	pop bc			;5547
	djnz L_5536		;5548
	ret			;554a

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El cuadrilatero entero, con la pantalla apagada. Los guiones se
; encadenan: unos siguen donde acabo el anterior con
; sigue_descomprimiendo, que es lo que hace que la cola se comparta.
; ----------------------------------------------------------------------
monta_el_combate:
	ld bc,0a201h		;554b   ; R1 sin el bit 6: la pantalla, apagada
	call 00047h		;554e   ; BIOS WRTVDP - Writes data in the VDP-register
	ld hl,07480h		;5551   ; patrones, casilla 0x30
	ld de,059c4h		;5554   ; la fuente
	call descomprime		;5557
	ld de,05af4h		;555a   ; el borde
	call descomprime_desde_palabra		;555d
	ld de,067c3h		;5560   ; y lo que sigue
	call descomprime_desde_palabra		;5563
	ld de,05d60h		;5566   ; el guion gordo del cuadrilatero
	call descomprime_desde_palabra		;5569
	call sigue_descomprimiendo		;556c   ; que sigue por donde acabo
	call descomprime_desde_palabra		;556f
	ld hl,06450h		;5572   ; patrones
	ld de,06632h		;5575   ; la cola de 0x6632
	call descomprime		;5578
	ld de,066dch		;557b   ; y lo que sigue
	call sigue_descomprimiendo		;557e
	ld a,(0e207h)		;5581   ; (0xE207), el rival
	bit 4,a		;5584   ; con el bit 4 puesto...
	jr z,L_558A		;5586
	add a,003h		;5588   ; ...tres mas
L_558A:
	and 00fh		;558a   ; de 0 a 15
	rlca			;558c   ; palabras
	ld hl,05661h		;558d   ; los seis punteros de 0x5661
	call suma_a_hl		;5590
	call saca_la_palabra		;5593   ; su nombre
	ex de,hl			;5596
	ld hl,07822h		;5597   ; fila 1, columna 2
	call descomprime		;559a
	ld hl,07837h		;559d   ; fila 1, columna 23
	ld de,056afh		;55a0   ; y "RYU", el del jugador
	call descomprime		;55a3
	ld de,06710h		;55a6   ; el guion de 0x6710
	ld hl,04450h		;55a9   ; fila 2, columna 16
	call descomprime_cambiando_el_color		;55ac
	call pinta_al_arbitro_en_medio		;55af   ; el reparto de colores
	ld a,(0e208h)		;55b2   ; (0xE208)
	ld hl,07a5ah		;55b5   ; fila 18, columna 26
	call escribe_una_casilla		;55b8
	call pinta_el_asalto		;55bb   ; y el asalto al lado
	ld a,(0e21ch)		;55be   ; (0xE21C), lo que lleva sumado el de la izquierda
	ld hl,07a9ah		;55c1   ; fila 20, columna 26
	call pinta_dos_cifras_grandes		;55c4
	ld a,(0e21dh)		;55c7   ; y (0xE21D), el de la derecha
	ld hl,07a89h		;55ca   ; fila 20, columna 9
	call pinta_dos_cifras_grandes		;55cd
	ld hl,0e202h		;55d0   ; (0xE202), el tope de golpes
	ld b,003h		;55d3   ; tres...
	ld a,(0e206h)		;55d5   ; (0xE206), lo duro que juega
	cp 007h		;55d8   ; por debajo de 7...
	jr c,L_55E2		;55da
	dec b			;55dc   ; ...dos, y por debajo de 0x0F...
	cp 00fh		;55dd
	jr c,L_55E2		;55df
	dec b			;55e1   ; ...uno
L_55E2:
	ld (hl),b			;55e2
borra_la_zona_de_trabajo:
	ld hl,0e21eh		;55e3   ; de 0xE21E a 0xE2EE
	ld bc,000cfh		;55e6
	call rellena_de_ceros		;55e9
	ld a,003h		;55ec   ; y un 3 en (0xE1FF)
	ld (0e1ffh),a		;55ee
	ld hl,02802h		;55f1   ; columna 2, pixel 40 para el de la izquierda
	ld (0e25dh),hl		;55f4
	ld hl,0c816h		;55f7   ; columna 22, pixel 200 para el de la derecha
	ld (0e23ah),hl		;55fa
	ld a,0edh		;55fd   ; fila 0 en (0xE26C), donde empieza la campana
	ld (0e26ch),a		;55ff
	ld a,(0e210h)		;5602   ; (0xE210), el asalto
	inc a			;5605   ; uno mas, en ASCII
	or 030h		;5606
	ld hl,07a4ah		;5608   ; fila 18, columna 10
	call escribe_una_casilla		;560b
	ld hl,0561fh		;560e   ; los cinco de 0x561F...
	ld de,0e211h		;5611   ; ...a 0xE211
	ld bc,00005h		;5614
	ldir		;5617
	ld bc,0e201h		;5619   ; y R1 otra vez con el bit 6: se enciende
	jp 00047h		;561c   ; BIOS WRTVDP - Writes data in the VDP-register

; ----------------------------------------------------------------------
; DATOS estado_y_reloj_de_arranque: Lo que 0x560E copia a 0xE211: el byte de
;   estado a cero y el reloj del asalto, "3", la casilla 0x1C que hace de dos
;   puntos, "0" y "1". La primera bajada lo deja en 3:00, o sea tres minutos
;   0x561f..0x5624  (5 bytes)
DATA_estado_y_reloj_de_arranque:
	defb 000h,033h,01ch,030h,031h	; 561f

; ======================================================================
; CODIGO 0x5624..0x5661  (61 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El mismo guion comprimido de siempre, pero pasando cada byte por un
; cambio de color: el 6 se convierte en 9, en la tinta y en el fondo.
; ----------------------------------------------------------------------
descomprime_cambiando_el_color:
	call prepara_la_escritura		;5624   ; aqui se fija la direccion
	ld a,(00006h)		;5627   ; el puerto de datos del VDP
	ld c,a			;562a
L_562B:
	ld a,(de)			;562b   ; el codigo
	and 07fh		;562c   ; los siete de abajo
	ret z			;562e   ; cero, se acabo
	ld b,a			;562f
	ld a,(de)			;5630   ; y el byte entero
	cp b			;5631   ; con el bit 7 puesto, bytes seguidos
	jr z,L_563F		;5632
L_5634:
	inc de			;5634   ; byte a byte
	call cambia_el_color_6_por_el_9		;5635   ; cada uno con su cambio de color
	out (c),a		;5638   ; y al puerto
	djnz L_5634		;563a
	inc de			;563c
	jr L_562B		;563d
L_563F:
	inc de			;563f   ; y si no, el mismo repetido
	call cambia_el_color_6_por_el_9		;5640
L_5643:
	nop			;5643   ; los dos `nop` dan tiempo al VDP
	nop			;5644
	out (c),a		;5645   ; y al puerto
	djnz L_5643		;5647
	inc de			;5649   ; y a por el siguiente codigo
	jr L_562B		;564a
cambia_el_color_6_por_el_9:
	ld a,(de)			;564c   ; el byte
	and 00fh		;564d   ; el fondo
	ld h,a			;564f
	cp 006h		;5650   ; el 6...
	jr nz,L_5656		;5652
	ld h,009h		;5654   ; ...pasa a 9
L_5656:
	ld a,(de)			;5656   ; y la tinta
	and 0f0h		;5657
	cp 060h		;5659   ; el 6...
	jr nz,L_565F		;565b
	ld a,090h		;565d   ; ...pasa a 9
L_565F:
	or h			;565f   ; y se juntan
	ret			;5660

; ----------------------------------------------------------------------
; DATOS punteros_de_los_nombres: Los seis rivales, en el orden en que los
;   indexa 0x558D con (0xE207) mas tres si lleva el bit 4
;   0x5661..0x566d  (12 bytes)
DATA_punteros_de_los_nombres:
	defw 0566dh,05678h,05683h,0568eh,05699h,056a5h	; 5661

; ----------------------------------------------------------------------
; DATOS nombre_red_wolf: "RED.WOLF" con una casilla de adorno delante (la
;   0x04, que no es de la fuente)
;   0x566d..0x5678  (11 bytes)
DATA_nombre_red_wolf:
	defb 089h,004h,052h,045h,044h,051h,057h,04fh,04ch,046h,000h	; 566d  ..REDQWOLF.

; ----------------------------------------------------------------------
; DATOS nombre_m_b_alli: "M.B.ALLI", con el punto medio de la casilla 0x51 y
;   el adorno 0x04 delante
;   0x5678..0x5683  (11 bytes)
DATA_nombre_m_b_alli:
	defb 089h,004h,04dh,051h,042h,051h,041h,04ch,04ch,049h,000h	; 5678  ..MQBQALLI.

; ----------------------------------------------------------------------
; DATOS nombre_moai_king: "MOAI.KING", con el punto medio de la casilla 0x51 y
;   sin adorno delante
;   0x5683..0x568e  (11 bytes)
DATA_nombre_moai_king:
	defb 089h,04dh,04fh,041h,049h,051h,04bh,049h,04eh,047h,000h	; 5683  .MOAIQKING.

; ----------------------------------------------------------------------
; DATOS nombre_sanchess: "SANCHESS", ocho letras con el adorno 0x04 delante
;   0x568e..0x5699  (11 bytes)
DATA_nombre_sanchess:
	defb 089h,004h,053h,041h,04eh,043h,048h,045h,053h,053h,000h	; 568e  ..SANCHESS.

; ----------------------------------------------------------------------
; DATOS nombre_china_khan: "CHINA.KHAN", el mas largo: diez casillas
;   0x5699..0x56a5  (12 bytes)
DATA_nombre_china_khan:
	defb 08ah,043h,048h,049h,04eh,041h,051h,04bh,048h,041h,04eh,000h	; 5699  .CHINAQKHAN.

; ----------------------------------------------------------------------
; DATOS nombre_moai_jr: "MOAI.Jr.": la casilla 0x58 no es la X del ASCII sino
;   un glifo con la "r" y el punto juntos, y dibujando la fuente se lee claro.
;   Es el hijo de MOAI KING, y comparte con el las figuras del archivo 4
;   0x56a5..0x56af  (10 bytes)
DATA_nombre_moai_jr:
	defb 088h,004h,04dh,04fh,041h,049h,051h,04ah,058h,000h	; 56a5  ..MOAIQJX.

; ----------------------------------------------------------------------
; DATOS nombre_del_jugador: "RYU". No sale de la tabla de los seis: lo pone
;   0x55A0 aparte, en 0x3837
;   0x56af..0x56b4  (5 bytes)
DATA_nombre_del_jugador:
	defb 083h,052h,059h,055h,000h	; 56af

; ======================================================================
; CODIGO 0x56b4..0x5950  (668 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; EL RELOJ, LA CUENTA Y EL FINAL DEL ASALTO
; ======================================================================
; El reloj del asalto son CUATRO casillas en ASCII, de (0xE212) a
; (0xE215), volcadas a la fila 1 columna 14. Baja de una en una por el
; final, y cuando las unidades pasan de '0' a '9' se lleva una de las
; decenas, que al pasar de '0' vuelven a '5': o sea segundos de verdad.
; ----------------------------------------------------------------------
apaga_la_campana:
	ld a,(0e22ch)		;56b4   ; con nadie en el suelo, nada
	or a			;56b7
	ret z			;56b8
	ld a,(0e003h)		;56b9   ; el contador de cuadros
	and 00fh		;56bc   ; uno de cada 16
	ret nz			;56be
	ld hl,0e26dh		;56bf   ; y se quita el bit 1 de (0xE26D)
	res 1,(hl)		;56c2
	ret			;56c4
lleva_el_asalto:
	call pinta_la_cuenta		;56c5   ; los sprites del jugador
	ld a,(0e211h)		;56c8   ; (0xE211)
	rrca			;56cb   ; su bit 0
	ld a,(0e1ffh)		;56cc   ; (0xE1FF), el paso en que va
	jp c,espera_al_sonido		;56cf   ; con el bit puesto, otra cosa
	or a			;56d2   ; y con el paso empezado, tampoco
	jr nz,apaga_la_campana		;56d3
	inc a			;56d5   ; el paso 1
	ld (0e1ffh),a		;56d6
	xor a			;56d9   ; y a mirar quien esta en el suelo
	ld hl,0e22ch		;56da   ; (0xE22C), el que cuenta la caida
	ld a,(hl)			;56dd
	or a			;56de   ; a cero, nadie en el suelo
	jr z,baja_los_temporizadores		;56df
	cp 004h		;56e1   ; el 4...
	jr nz,L_56F3		;56e3
	ld a,(0e23eh)		;56e5   ; ...y (0xE23E) o (0xE261) a 3
	cp 003h		;56e8
	jr z,L_56F7		;56ea
	ld a,(0e261h)		;56ec   ; o (0xE261)
	cp 003h		;56ef
	jr z,L_56F7		;56f1
L_56F3:
	cp 00bh		;56f3   ; de 0x0B en adelante...
	jr c,L_56FB		;56f5
L_56F7:
	ld (hl),00ch		;56f7   ; ...se salta al 0x0C, que acaba la cuenta
	jr baja_los_temporizadores		;56f9
L_56FB:
	ld a,(0e25ch)		;56fb   ; la accion del de la izquierda
	cp 010h		;56fe   ; la 0x10, caer
	jr z,L_5752		;5700
	cp 00dh		;5702   ; o la 0x0D
	jr z,L_571F		;5704
	ld a,(0e239h)		;5706   ; y la del de la derecha
	cp 010h		;5709
	jr z,L_5752		;570b
	cp 00dh		;570d
	jr z,L_571F		;570f
	ld a,005h		;5711   ; un 5 en (0xE26D)
	ld (0e26dh),a		;5713
	xor a			;5716   ; (0xE24B) a cero
	ld (0e24bh),a		;5717
	call suena_la_campana_y_pinta		;571a   ; y suena la campana
	jr baja_los_temporizadores		;571d
L_571F:
	ld a,(0e24fh)		;571f   ; (0xE24F)
	or a			;5722
	jr nz,baja_los_temporizadores		;5723   ; con algo, no se cuenta
	ld a,(hl)			;5725   ; el numero de la cuenta
	dec a			;5726
	ld de,05950h		;5727   ; los diez de 0x5950
	call suma_a_de		;572a
	ld a,(de)			;572d   ; el sonido que le toca
	call pide_un_sonido		;572e
	inc (hl)			;5731   ; y uno mas
	ld hl,0e26dh		;5732   ; con el bit 1 de (0xE26D) puesto
	set 1,(hl)		;5735
baja_los_temporizadores:
	xor a			;5737
	ld hl,0e258h		;5738   ; (0xE258), el del de la izquierda
	cp (hl)			;573b   ; ya a cero?
	jr z,L_5747		;573c
	dec (hl)			;573e   ; no: uno menos
	ld a,(0e211h)		;573f   ; (0xE211)
	bit 1,a		;5742   ; con su bit 1, nada mas
	ret nz			;5744
	jr L_574B		;5745
L_5747:
	dec hl			;5747   ; y entonces (0xE257)
	cp (hl)			;5748
	jr nz,acaba_el_asalto		;5749   ; con algo, se acaba aqui
L_574B:
	ld hl,0e235h		;574b   ; (0xE235), el del de la derecha
	cp (hl)			;574e   ; ya a cero?
	jr z,L_575A		;574f
	dec (hl)			;5751   ; uno menos
L_5752:
	ld a,(0e211h)		;5752   ; (0xE211)
	bit 1,a		;5755   ; con su bit 1, nada mas
	ret nz			;5757
	jr baja_el_reloj		;5758
L_575A:
	dec hl			;575a   ; y entonces (0xE234)
	cp (hl)			;575b
	jr nz,acaba_el_asalto		;575c   ; con algo, se acaba aqui
baja_el_reloj:
	call repasa_las_tarjetas		;575e   ; las tarjetas, al dia
	ld a,(0e211h)		;5761   ; (0xE211)
	bit 1,a		;5764   ; con su bit 1, el reloj no corre
	jr nz,acaba_el_asalto		;5766
	ld hl,0e215h		;5768   ; las unidades de segundo
	ld a,(hl)			;576b
	and 00fh		;576c   ; la cifra
	sub 001h		;576e   ; una menos...
	daa			;5770
L_5771:
	and 00fh		;5771   ; ...en BCD
	or 030h		;5773   ; y de vuelta a ASCII
	ld (hl),a			;5775
	cp 030h		;5776   ; si quedo en '0', puede que se acabe
	jr z,mira_si_se_acabo_el_tiempo		;5778
	cp 039h		;577a   ; y si dio la vuelta a '9'...
	jr nz,pinta_el_reloj		;577c
	dec hl			;577e   ; ...se lleva una de las decenas
	ld a,(hl)			;577f
	and 00fh		;5780
	sub 001h		;5782   ; una menos
	jr nc,L_5771		;5784   ; mientras no den la vuelta, se sigue
	ld a,005h		;5786   ; y al pasar de '0' vuelven a '5': sesenta segundos
	and 00fh		;5788
	or 030h		;578a
	ld b,a			;578c
	ld a,(0e212h)		;578d   ; (0xE212), los minutos
	cp 030h		;5790   ; a '0' no quedan mas
	jr z,acaba_el_asalto		;5792
	ld (hl),b			;5794   ; las decenas
	dec hl			;5795   ; y a los minutos
	dec hl			;5796
	dec (hl)			;5797   ; y un minuto menos
pinta_el_reloj:
	ld bc,00004h		;5798   ; las cuatro casillas...
	ld de,0e212h		;579b   ; ...de 0xE212...
	ld hl,0782eh		;579e   ; ...a la fila 1, columna 14
	jp vuelca_en_la_vram		;57a1
mira_si_se_acabo_el_tiempo:
	dec hl			;57a4   ; las decenas...
	cp (hl)			;57a5   ; ...tambien a '0'?
	jr nz,pinta_el_reloj		;57a6
	dec hl			;57a8   ; y los minutos
	dec hl			;57a9
	cp (hl)			;57aa   ; ...tambien?
	jr nz,pinta_el_reloj		;57ab
	call pinta_el_reloj		;57ad   ; se pinta el 0:00
acaba_el_asalto:
	ld hl,0e210h		;57b0   ; (0xE210), el asalto
	bit 1,(hl)		;57b3   ; su bit 1
	inc hl			;57b5
	jr nz,L_57C4		;57b6   ; ya estaba puesto
	set 1,(hl)		;57b8   ; se pone en (0xE211)
	ld a,(0e258h)		;57ba   ; (0xE258)...
	or a			;57bd
	ret nz			;57be
	ld a,(0e235h)		;57bf   ; ...y (0xE235) a cero
	or a			;57c2
	ret nz			;57c3
L_57C4:
	set 0,(hl)		;57c4   ; el bit 0 de (0xE211)
	dec hl			;57c6
	inc (hl)			;57c7   ; y un asalto mas
	call puntua_el_asalto		;57c8   ; se puntua
	ld a,008h		;57cb   ; el paso 8
	ld (0e1ffh),a		;57cd
	ld a,001h		;57d0   ; y un 1 en (0xE12B)
	ld (0e12bh),a		;57d2
	jp pon_la_cuenta_a_doce		;57d5
pon_la_accion_0x12:
	ld (hl),012h		;57d8   ; la accion 0x12 al que toque
suena_la_campana:
	ld (0e26dh),a		;57da   ; en (0xE26D)
	xor a			;57dd
	ld (0e26eh),a		;57de   ; y (0xE26E) a cero
	jr pon_el_sonido_final		;57e1
espera_al_sonido:
	ld a,(0e313h)		;57e3   ; el sonido que suena
	cp 01fh		;57e6   ; el 0x1F...
	jr nz,mira_quien_esta_en_el_suelo		;57e8
	ld a,(0e311h)		;57ea   ; ...con (0xE311) a 0x20
	cp 020h		;57ed
	jr nz,mira_quien_esta_en_el_suelo		;57ef
	ld hl,0e24eh		;57f1   ; (0xE24E)
	call baja_un_temporizador		;57f4
	jr z,mira_quien_esta_en_el_suelo		;57f7   ; mientras corra, nada
	ld a,001h		;57f9   ; y al acabar, un 1 en (0xE12B)
	ld (0e12bh),a		;57fb
mira_quien_esta_en_el_suelo:
	ld a,(0e239h)		;57fe   ; la accion del de la derecha
	cp 010h		;5801   ; la 0x10, caer
	ret z			;5803
	ld a,(0e25ch)		;5804   ; y la del de la izquierda
	cp 010h		;5807
	ret z			;5809
	ld hl,0e284h		;580a   ; (0xE284), que solo entra una vez
	bit 0,(hl)		;580d
	jr nz,pon_el_sonido_final		;580f
	inc (hl)			;5811   ; y se echa el cerrojo
	ld a,(0e257h)		;5812   ; (0xE257), el de la izquierda
	or a			;5815
	ld a,002h		;5816   ; tocado, el 2
	jr nz,suena_la_campana		;5818
	ld a,(0e234h)		;581a   ; (0xE234), el de la derecha
	or a			;581d
	ld a,003h		;581e   ; tocado, el 3
	jr nz,suena_la_campana		;5820
	ld a,(0e210h)		;5822   ; (0xE210), el asalto
	cp 003h		;5825   ; solo en el tercero
	jr nz,pon_el_sonido_final		;5827
	ld hl,0e26ch		;5829   ; la campana, a la fila 0
	ld (hl),0edh		;582c
	ld l,01ch		;582e   ; (0xE21C) contra (0xE21D)
	ld a,(hl)			;5830
	inc hl			;5831
	cp (hl)			;5832
	ld hl,04005h		;5833   ; columna 5, pixel 64
	ld (0e25dh),hl		;5836   ; para el de la izquierda
	ld hl,0e239h		;5839   ; y la accion del de la derecha
	ld a,003h		;583c   ; y la 3
	jr c,pon_la_accion_0x12		;583e   ; gana el de la derecha
	ld hl,0b013h		;5840   ; columna 19, pixel 176
	ld (0e23ah),hl		;5843   ; para el de la derecha
	ld hl,0e25ch		;5846   ; y la accion del de la izquierda
	ld a,002h		;5849
	jr nz,pon_la_accion_0x12		;584b   ; gana el de la izquierda
	dec a			;584d   ; empate
	jr suena_la_campana		;584e
pon_el_sonido_final:
	ld hl,0e280h		;5850   ; (0xE280), lo ultimo que sono
	ld a,(hl)			;5853
	cp 053h		;5854   ; el 0x53 ya esta puesto
	jr z,L_5868		;5856
	ld a,(0e313h)		;5858   ; con algo sonando, se espera
	or a			;585b
	ret nz			;585c
	ld a,(0e12bh)		;585d   ; y con (0xE12B) tambien
	or a			;5860
	ret nz			;5861
	ld a,053h		;5862   ; el 0x53, la cuenta
	ld (hl),a			;5864
	call pide_un_sonido		;5865
L_5868:
	ld a,(0e234h)		;5868   ; (0xE234)...
	or a			;586b
	jr nz,para_a_los_dos		;586c
	ld a,(0e257h)		;586e   ; ...o (0xE257)
	or a			;5871
	jr nz,para_a_los_dos		;5872
	ld a,(0e210h)		;5874   ; (0xE210), el asalto
	cp 003h		;5877   ; el tercero
	jr nz,elige_la_escena_siguiente		;5879
para_a_los_dos:
	ld (0e270h),a		;587b   ; en (0xE270)
	ld hl,0e239h		;587e   ; la accion del de la derecha
	ld a,(hl)			;5881
	cp 012h		;5882   ; la 0x12...
	jr z,L_588C		;5884
	cp 00dh		;5886   ; ...o la 0x0D se dejan
	jr z,L_588C		;5888
	ld (hl),011h		;588a   ; y a las demas, la 0x11
L_588C:
	ld hl,0e25ch		;588c   ; la del de la izquierda
	ld a,(hl)			;588f
	cp 012h		;5890
	jr z,elige_la_escena_siguiente		;5892
	cp 00dh		;5894
	jr z,elige_la_escena_siguiente		;5896
	ld (hl),011h		;5898   ; igual
elige_la_escena_siguiente:
	ld a,(0e1ffh)		;589a   ; (0xE1FF)
	or a			;589d
	jp nz,pinta_el_marcador		;589e   ; con algo, solo el marcador
	ld hl,0e22ch		;58a1   ; (0xE22C)
	call suena_la_campana_y_pinta		;58a4   ; la campana
	call borra_las_tarjetas		;58a7   ; y las tarjetas, en blanco
	ld a,(0e000h)		;58aa   ; la escena de ahora
	cp 002h		;58ad   ; la 2, la demostracion...
	ld b,007h		;58af   ; ...vuelve a la 7
	jr z,L_58E0		;58b1
	ld a,(0e234h)		;58b3   ; (0xE234), el de la derecha
	or a			;58b6
	ld b,006h		;58b7   ; tocado, la 6
	jr nz,L_58E0		;58b9
	ld a,(0e257h)		;58bb   ; (0xE257), el de la izquierda
	or a			;58be
	jr nz,L_58D8		;58bf
	ld a,(0e210h)		;58c1   ; (0xE210), el asalto
	cp 003h		;58c4   ; antes del tercero...
	ld b,00ah		;58c6   ; ...la 0x0A
	jr nz,L_58E0		;58c8
	xor a			;58ca   ; y en el tercero, a cero
	ld (0e210h),a		;58cb
	ld hl,0e21ch		;58ce   ; (0xE21C) contra (0xE21D)
	ld a,(hl)			;58d1
	inc hl			;58d2
	cp (hl)			;58d3
	ld b,006h		;58d4   ; el que menos puntos lleva, la 6
	jr c,L_58E0		;58d6
L_58D8:
	ld a,(0e002h)		;58d8   ; el bit 0 de las banderas: con dos jugando...
	rrca			;58db
	jr c,L_58E0		;58dc
	ld b,008h		;58de   ; ...la 8
L_58E0:
	ld a,b			;58e0   ; y esa es la escena
	ld (0e000h),a		;58e1
	cp 008h		;58e4   ; la 8
	jr nz,L_591A		;58e6
	ld a,(0e207h)		;58e8   ; (0xE207), el rival
	and 003h		;58eb   ; los dos de abajo
	cp 002h		;58ed   ; solo con el 2
	ret nz			;58ef
	ld a,(0e257h)		;58f0   ; (0xE257)
	or a			;58f3
	jr z,L_5916		;58f4
	call pinta_los_tres_sprites		;58f6   ; los tres sprites, al color 0x58
	ld hl,0e102h		;58f9   ; (0xE102), la fila del primero
	ld a,(hl)			;58fc
	cp 0b4h		;58fd   ; a 0xB4 no se baja mas
	jr z,L_5916		;58ff
	ld b,00ch		;5901   ; doce
	inc hl			;5903
	cp 09ch		;5904   ; a 0x9C...
	jr z,L_590A		;5906
	ld b,006h		;5908   ; ...seis
L_590A:
	ld (hl),b			;590a   ; en (0xE103)
	dec hl			;590b
L_590C:
	ld a,(hl)			;590c   ; la fila...
	add a,00ch		;590d   ; ...doce pixeles mas abajo
	ld (hl),a			;590f
	inc hl			;5910   ; y el registro siguiente
	inc hl			;5911
	inc hl			;5912
	inc hl			;5913
	djnz L_590C		;5914
L_5916:
	ld a,0a5h		;5916   ; el sonido 0xA5
	jr L_591F		;5918
L_591A:
	cp 006h		;591a   ; la escena 6...
	ret nz			;591c
	ld a,0a8h		;591d   ; ...suena el 0xA8
L_591F:
	jp pide_un_sonido		;591f
suena_la_campana_y_pinta:
	ld a,056h		;5922   ; el sonido 0x56
	call pide_un_sonido		;5924
pon_la_cuenta_a_doce:
	ld a,00ch		;5927   ; un 0x0C en (0xE22C)
	ld (0e22ch),a		;5929
pinta_al_arbitro_en_medio:
	ld hl,07830h		;592c   ; fila 1, columna 16
	ld de,0680ch		;592f   ; el guion por filas de 0x680C
	call pinta_por_filas		;5932
	jp el_arbitro_a_la_izquierda		;5935   ; y el otro a la izquierda
pinta_los_tres_sprites:
	ld c,058h		;5938   ; el color 0x58
pinta_los_tres_sprites_con_el_color_de_c:
	ld hl,0e100h		;593a   ; los tres registros de 0xE100
	push hl			;593d
	ld b,003h		;593e   ; tres
L_5940:
	ld (hl),c			;5940   ; el color, en su sitio
	ld a,004h		;5941   ; cuatro bytes por registro
	add a,l			;5943
	ld l,a			;5944
	djnz L_5940		;5945
	ld hl,07b30h		;5947   ; la tabla de sprites, sprite 12
	pop de			;594a
	ld c,00ch		;594b   ; doce bytes
	jp vuelca_en_la_vram		;594d

; ----------------------------------------------------------------------
; DATOS ruidos_de_la_cuenta: El ruido de cada numero de la cuenta del arbitro,
;   que 0x5727 indexa con (0xE22C) menos uno: 04 04 05 04 04 05 04 04 05 06
;   0x5950..0x595a  (10 bytes)
DATA_ruidos_de_la_cuenta:
	defb 004h,004h,005h,004h,004h,005h,004h,004h,005h,006h	; 5950  ..........

; ======================================================================
; CODIGO 0x595a..0x59c4  (106 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; La cuenta del arbitro: el numero grande son DOS sprites en 0x3B78, y
; la cifra va ademas en casillas. (0xE22C) lleva por donde va.
; ----------------------------------------------------------------------
pinta_la_cuenta:
	ld b,0cfh		;595a   ; la fila 0xCF, fuera de la pantalla
	ld hl,0e22ch		;595c   ; (0xE22C)
	ld a,(hl)			;595f
	cp 002h		;5960   ; por debajo de 2 no hay cuenta
	ret c			;5962
	cp 00ch		;5963   ; el 0x0C la acaba...
	jr nz,L_596B		;5965
	ld (hl),000h		;5967   ; ...y se borra
	jr L_598C		;5969
L_596B:
	ld e,a			;596b   ; el numero, a E
	ld a,(0e26eh)		;596c   ; (0xE26E)
	or a			;596f   ; con algo, nada
	ret nz			;5970
	ld a,(0e26ch)		;5971   ; (0xE26C), donde esta la campana
	sub 03ch		;5974   ; sesenta casillas mas arriba
	ld l,a			;5976
	ld d,a			;5977
	ld h,078h		;5978   ; la tabla de nombres
	ld a,e			;597a   ; el numero
	dec a			;597b   ; desde cero
	add a,000h		;597c   ; a BCD
	daa			;597e
	call pinta_la_cifra_de_la_cuenta		;597f   ; y se pinta
	ld a,d			;5982   ; la columna
	and 01fh		;5983   ; de 0 a 31
	rlca			;5985   ; por ocho: el pixel
	rlca			;5986
	rlca			;5987
	sub 008h		;5988   ; menos ocho
	ld b,025h		;598a   ; el patron 0x25
L_598C:
	ld hl,0e150h		;598c   ; los registros de sprite, en 0xE150
	push hl			;598f
	ld (hl),b			;5990   ; el patron
	inc hl			;5991
	ld (hl),a			;5992   ; la fila
	add a,008h		;5993   ; el segundo va ocho pixeles mas alla
	ld c,a			;5995
	inc hl			;5996
	ld (hl),0c0h		;5997   ; columna 0xC0
	inc hl			;5999
	ld (hl),001h		;599a   ; color 1
	inc hl			;599c
	ld (hl),b			;599d   ; el mismo patron
	inc hl			;599e
	ld a,(0e22ch)		;599f   ; (0xE22C)
	cp 00bh		;59a2   ; en el 0x0B...
	ld a,c			;59a4
	jr nz,L_59A9		;59a5
	add a,008h		;59a7   ; ...ocho pixeles mas
L_59A9:
	ld (hl),a			;59a9   ; la fila
	inc hl			;59aa
	ld (hl),0c4h		;59ab   ; columna 0xC4
	inc hl			;59ad
	ld (hl),001h		;59ae   ; color 1
	pop de			;59b0
	ld hl,07b78h		;59b1   ; la tabla de sprites, sprite 30
	ld bc,00008h		;59b4   ; ocho bytes
	jp vuelca_en_la_vram		;59b7
pinta_la_cifra_de_la_cuenta:
	cp 010h		;59ba   ; el 0x10 son dos cifras
	jp z,pinta_dos_cifras		;59bc
	ld b,030h		;59bf   ; y una sola con las casillas de 0x30
	jp L_4E8E		;59c1

; ----------------------------------------------------------------------
; DATOS guion_de_la_fuente: Guion comprimido: 368 bytes desde 0x2180, que son
;   CUARENTA Y SEIS casillas de ocho filas, los codigos 0x30 a 0x5D. Casi
;   ASCII, con tres cambios medidos dibujandola: 0x3A es un circulo, 0x40 un
;   guion, 0x51 un PUNTO MEDIO en vez de la Q y 0x5A (la Z) esta en blanco
;   0x59c4..0x5af4  (304 bytes)
DATA_guion_de_la_fuente:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0c9h,07eh	; 59c4  ..."ccc"...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 59d4  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 59e4  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 59f4  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 5a04  .>cc>cc>.>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,02ch,000h,001h,0ffh,004h,000h,0c1h,01ch	; 5a14  <B....B<,.......
	defb 036h,063h,063h,07fh,063h,063h,000h,07eh,063h,063h,07eh,063h,063h,07eh,000h,03eh	; 5a24  6cc.cc.~cc~cc~.>
	defb 063h,060h,060h,060h,063h,03eh,000h,07ch,066h,063h,063h,063h,066h,07ch,000h,07fh	; 5a34  c```c>.|fcccf|..
	defb 060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h,07eh,060h,060h,060h,000h,03eh	; 5a44  ``~``...``~```.>
	defb 063h,060h,067h,063h,063h,03fh,000h,063h,063h,063h,07fh,063h,063h,063h,000h,03ch	; 5a54  c`gcc?.ccc.ccc.<
	defb 005h,018h,083h,03ch,000h,01fh,004h,006h,08bh,066h,03ch,000h,063h,066h,06ch,078h	; 5a64  ...<.....f<.cflx
	defb 07ch,06eh,067h,000h,006h,060h,093h,07fh,000h,063h,077h,07fh,07fh,06bh,063h,063h	; 5a74  |ng..`...cw..kcc
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,03eh,005h,063h,089h,03eh,000h,07eh	; 5a84  .cs{.ogc.>.c.>.~
	defb 063h,063h,063h,07eh,060h,060h,004h,000h,096h,018h,018h,000h,000h,000h,07eh,063h	; 5a94  ccc~``........~c
	defb 063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh,000h,07eh,006h	; 5aa4  cb|fc.>c`>.c>.~.
	defb 018h,001h,000h,006h,063h,0a1h,03eh,000h,063h,063h,063h,063h,036h,01ch,008h,000h	; 5ab4  ....c.>.cccc6...
	defb 063h,063h,06bh,06bh,07fh,077h,022h,000h,000h,000h,050h,060h,040h,044h,000h,000h	; 5ac4  cckk.w"...P`@D..
	defb 066h,066h,07eh,03ch,018h,018h,018h,008h,000h,082h,001h,03dh,005h,018h,084h,03ch	; 5ad4  ff~<.......=...<
	defb 000h,00fh,01fh,004h,0ffh,089h,00fh,000h,000h,0feh,0e0h,0e0h,0c0h,0c0h,080h,000h	; 5ae4  ................

; ----------------------------------------------------------------------
; DATOS guion_del_borde: Guion comprimido de 40 bytes, volcado por
;   monta_el_combate (0x555A)
;   0x5af4..0x5b18  (36 bytes)
DATA_guion_del_borde:
	defb 0d0h,034h,08ah,000h,07eh,063h,063h,063h,07eh,060h,060h,000h,03eh,005h,063h,083h	; 5af4  .4..~ccc~``.>.c.
	defb 03eh,000h,03ch,005h,018h,08bh,03ch,000h,063h,073h,07bh,07fh,06fh,067h,063h,000h	; 5b04  >.<...<.cs{.ogc.
	defb 07eh,006h,018h,000h	; 5b14

; ----------------------------------------------------------------------
; DATOS rotulo_push_space_key: "PUSH SPACE KEY" en la fila 16, columna 9.
;   Parpadea: 0x42BF alterna pinta_texto y borra_texto con el bit 4 del
;   contador de cuadros
;   0x5b18..0x5b29  (17 bytes)
DATA_rotulo_push_space_key:
	defb 009h,03ah,050h,055h,053h,048h,000h,053h,050h,041h,043h,045h,000h,04bh,045h,059h,0ffh	; 5b18  .:PUSH.SPACE.KEY.

; ----------------------------------------------------------------------
; DATOS rotulo_de_la_presentacion: Guion de rotulos de 110 casillas en OCHO
;   tramos, el cartel de la presentacion
;   0x5b29..0x5baf  (134 bytes)
DATA_rotulo_de_la_presentacion:
	defb 0abh,039h,050h,04ch,041h,059h,000h,053h,045h,04ch,045h,043h,054h,0feh,048h,038h	; 5b29  .9PLAY.SELECT.H8
	defb 04bh,04fh,04eh,041h,04dh,05bh,053h,0feh,007h,03ah,0c1h,0e0h,0dch,0d1h,0e9h,0d5h	; 5b39  KONAM[S..:......
	defb 0e2h,000h,000h,000h,0d7h,0d1h,0ddh,0d5h,000h,000h,0d1h,0feh,047h,03ah,0c1h,0e0h	; 5b49  ............G:..
	defb 0dch,0d1h,0e9h,0d5h,0e2h,000h,000h,000h,0d7h,0d1h,0ddh,0d5h,000h,000h,0d2h,0feh	; 5b59  ................
	defb 087h,03ah,0c2h,0e0h,0dch,0d1h,0e9h,0d5h,0e2h,0e3h,000h,000h,0d7h,0d1h,0ddh,0d5h	; 5b69  .:..............
	defb 000h,000h,0d1h,0feh,0c7h,03ah,0c2h,0e0h,0dch,0d1h,0e9h,0d5h,0e2h,0e3h,000h,000h	; 5b79  .....:..........
	defb 0d7h,0d1h,0ddh,0d5h,000h,000h,0d2h,0feh,00ah,039h,000h,000h,000h,000h,000h,000h	; 5b89  .........9......
	defb 000h,000h,000h,000h,000h,000h,0feh,02ah,039h,03ah,04bh,04fh,04eh,041h,04dh,049h	; 5b99  .......*9:KONAMI
	defb 000h,031h,039h,038h,035h,0ffh	; 5ba9

; ----------------------------------------------------------------------
; DATOS rotulo_game_over: "GAME  OVER" en la fila 11, columna 11
;   0x5baf..0x5bbc  (13 bytes)
DATA_rotulo_game_over:
	defb 06bh,039h,047h,041h,04dh,045h,000h,000h,04fh,056h,045h,052h,0ffh	; 5baf  k9GAME..OVER.

; ----------------------------------------------------------------------
; DATOS rotulo_konami_software: Doce casillas del logotipo en la fila 10 y
;   "SOFTWARE" debajo, en la fila 11
;   0x5bbc..0x5bd6  (26 bytes)
DATA_rotulo_konami_software:
	defb 04ah,039h,040h,040h,040h,040h,040h,040h,040h,040h,040h,040h,040h	; 5bbc  J9@@@@@@@@@@@
	defb 040h,0feh,06ch,039h,053h,04fh,046h,054h,057h,041h,052h,045h,0ffh	; 5bc9  @.l9SOFTWARE.

; ----------------------------------------------------------------------
; DATOS guion_de_la_presentacion: Guion comprimido de 896 bytes. Lo vuelca
;   0x42E4
;   0x5bd6..0x5d59  (387 bytes)
DATA_guion_de_la_presentacion:
	defb 080h,064h,01ch,000h,00ah,001h,022h,000h,082h,01fh,03fh,009h,070h,083h,0f0h,0c0h	; 5bd6  .d...."...?.p...
	defb 0c0h,004h,0c3h,004h,0c0h,082h,0ffh,07fh,020h,000h,002h,0ffh,004h,000h,084h,0feh	; 5be6  ........ .......
	defb 0ffh,0ffh,0feh,004h,000h,084h,0f8h,0fch,0fch,0f8h,003h,000h,083h,003h,0ffh,0feh	; 5bf6  ................
	defb 020h,000h,098h,0c0h,0f0h,0f9h,03bh,01fh,01eh,00eh,00ch,00ch,008h,018h,018h,061h	; 5c06   .....;........a
	defb 061h,020h,030h,030h,038h,078h,07ch,0efh,0c7h,081h,000h,020h,000h,08ch,03fh,0ffh	; 5c16  a 008x|.... ..?.
	defb 0fch,0c0h,000h,000h,007h,01fh,03fh,03fh,07fh,07fh,004h,0ffh,082h,07fh,01eh,003h	; 5c26  ......??........
	defb 000h,083h,0c0h,0ffh,07fh,007h,000h,085h,001h,001h,003h,002h,004h,014h,000h,0a1h	; 5c36  ................
	defb 0e3h,0f7h,03eh,00eh,003h,001h,081h,0e0h,0f0h,0f0h,0f8h,0f8h,0e1h,0e1h,0c1h,0c3h	; 5c46  ..>.............
	defb 082h,006h,004h,00ch,038h,0f8h,0ffh,09fh,01fh,03fh,03eh,07ch,078h,0f0h,0e0h,0c0h	; 5c56  ....8....?>|x...
	defb 080h,017h,000h,099h,0f0h,0f8h,018h,01ch,00ch,00fh,087h,087h,0c3h,043h,060h,060h	; 5c66  .............C``
	defb 080h,080h,00ch,00ch,01eh,01eh,03fh,03fh,07bh,071h,0e1h,0c0h,080h,01ah,000h,09dh	; 5c76  ......??{q......
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,061h,0e1h,0c3h,0c3h,087h,087h,00fh,00fh,01fh	; 5c86  .....?.a........
	defb 01fh,07ch,07ch,03ch,03ch,01ch,01ch,00ch,00ch,084h,084h,0ffh,0ffh,014h,000h,08eh	; 5c96  .||<<...........
	defb 002h,004h,00ch,018h,038h,070h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,0ffh,0ffh,00ah,00ch	; 5ca6  ....8p..........
	defb 00ah,030h,002h,0ffh,020h,000h,098h,0fch,0feh,006h,007h,003h,003h,021h,021h,030h	; 5cb6  .0.. ........!!0
	defb 030h,038h,038h,0e1h,0e1h,0f0h,0f0h,0f8h,0d8h,0dch,0cch,0ceh,0c6h,0c7h,083h,020h	; 5cc6  088............ 
	defb 000h,082h,01fh,03fh,003h,030h,002h,0b0h,003h,0f0h,002h,070h,004h,0c3h,002h,043h	; 5cd6  ...?.0.....p...C
	defb 004h,003h,082h,0ffh,0feh,020h,000h,098h,080h,0c3h,0cfh,0deh,0d8h,0f0h,0f0h,0e3h	; 5ce6  ..... ..........
	defb 0e7h,0c7h,0cfh,0cfh,00fh,00fh,007h,087h,083h,0c0h,0c0h,0e0h,078h,03eh,00fh,003h	; 5cf6  ............x>..
	defb 020h,000h,086h,0ffh,0ffh,080h,000h,000h,03fh,006h,0ffh,083h,0c3h,0c0h,0fch,003h	; 5d06   .......?.......
	defb 0ffh,086h,03ch,000h,000h,000h,0ffh,0ffh,020h,000h,002h,0ffh,003h,000h,083h,0c0h	; 5d16  ..<..... .......
	defb 0f6h,0f9h,006h,0fbh,084h,07bh,0b9h,086h,07fh,004h,000h,002h,0ffh,020h,000h,098h	; 5d26  .....{....... ..
	defb 0ffh,0ffh,003h,007h,00fh,01eh,03ch,0d8h,0deh,0cfh,0c3h,0c1h,0c1h,0c0h,0c0h,0d0h	; 5d36  ......<.........
	defb 030h,0e1h,001h,003h,007h,01eh,0fch,0f0h,02ah,000h,002h,080h,006h,0c0h,002h,080h	; 5d46  0.......*.......
	defb 014h,000h,000h	; 5d56

; ----------------------------------------------------------------------
; DATOS guion_de_siete_bytes: Guion comprimido cortisimo: siete bytes que
;   escriben 160. Lo vuelca 0x414D
;   0x5d59..0x5d60  (7 bytes)
DATA_guion_de_siete_bytes:
	defb 0eah,038h,07fh,000h,021h,000h,000h	; 5d59

; ----------------------------------------------------------------------
; DATOS guion_del_cuadrilatero: El guion gordo: 4552 bytes en VEINTE tramos,
;   la pantalla de combate entera. La cola desde 0x6632 se vuelve a leer sola
;   para rehacer solo lo que cambia
;   0x5d60..0x66cb  (2411 bytes)
DATA_guion_del_cuadrilatero:
	defb 028h,060h,008h,0f8h,008h,01fh,008h,0c0h,008h,003h,081h,000h,007h,0ffh,004h,000h	; 5d60  (`..............
	defb 004h,0ffh,003h,000h,085h,0ffh,0ffh,0c3h,081h,000h,003h,000h,085h,0ffh,0ffh,0c3h	; 5d70  ................
	defb 081h,000h,004h,0ffh,094h,0fch,0f0h,0c3h,00fh,0ffh,0ffh,083h,001h,040h,030h,081h	; 5d80  .............@0.
	defb 0ffh,0ffh,0ffh,0c1h,080h,002h,00ch,081h,0ffh,004h,0ffh,08eh,03fh,00fh,0c3h,0f0h	; 5d90  ............?...
	defb 0ffh,09ch,099h,093h,087h,083h,091h,098h,0ffh,0c1h,005h,09ch,09bh,0c1h,0ffh,09ch	; 5da0  ................
	defb 08ch,084h,080h,090h,098h,09ch,0ffh,0e3h,0c9h,09ch,09ch,080h,09ch,09ch,0ffh,09ch	; 5db0  ................
	defb 088h,080h,080h,094h,09ch,09ch,0ffh,0c3h,005h,0e7h,08bh,0c3h,0ffh,0c1h,09ch,09fh	; 5dc0  ................
	defb 0c1h,0fch,09ch,0c1h,0ffh,081h,006h,0e7h,08ah,0ffh,083h,099h,09ch,09ch,09ch,099h	; 5dd0  ................
	defb 083h,0ffh,0c3h,005h,0e7h,082h,0c3h,0ffh,006h,09ch,088h,0c1h,000h,008h,008h,000h	; 5de0  ................
	defb 000h,008h,008h,009h,000h,080h,010h,061h,0c0h,0fch,0f8h,0f0h,0f0h,00fh,00fh,0f0h	; 5df0  .......a........
	defb 0f0h,03fh,01fh,01fh,01fh,0e0h,0f8h,007h,00fh,0fch,0f8h,0f8h,0f8h,007h,01fh,0e0h	; 5e00  .?..............
	defb 0f0h,03fh,01fh,00fh,00fh,0f0h,0f0h,00fh,00fh,070h,0c0h,080h,0dfh,087h,080h,080h	; 5e10  .?.......p......
	defb 000h,00eh,003h,001h,0fbh,0e1h,001h,001h,000h,070h,0c0h,080h,0dfh,087h,080h,080h	; 5e20  .........p......
	defb 0f9h,00eh,003h,001h,0fbh,0e1h,001h,001h,09fh,080h,010h,041h,081h,0eah,003h,0fah	; 5e30  ...........A....
	defb 002h,0a3h,002h,0fah,081h,0eah,003h,0fah,002h,0a3h,002h,0fah,081h,0eah,003h,0fah	; 5e40  ................
	defb 002h,0a3h,002h,0fah,081h,0eah,003h,0fah,002h,0a3h,002h,0fah,003h,0feh,005h,0ebh	; 5e50  ................
	defb 003h,0feh,005h,0ebh,003h,0feh,004h,0ebh,081h,0b1h,003h,0feh,004h,0ebh,081h,0b1h	; 5e60  ................
	defb 080h,068h,041h,008h,044h,080h,090h,06eh,090h,0e1h,0ceh,0fdh,0fdh,0ffh,0ffh,0f8h	; 5e70  .hA.D..n........
	defb 0c0h,087h,073h,0bfh,0bfh,0ffh,0ffh,01fh,003h,002h,0f0h,002h,00fh,004h,0f0h,090h	; 5e80  ..s.............
	defb 00fh,01fh,0e0h,0e0h,01fh,01fh,00fh,000h,0f0h,0f8h,007h,007h,0f8h,0f8h,0f0h,000h	; 5e90  ................
	defb 002h,00fh,002h,0f0h,004h,00fh,002h,007h,002h,0fch,081h,0feh,009h,0ffh,082h,03fh	; 5ea0  ...............?
	defb 00fh,006h,0ffh,082h,0fch,0f0h,002h,0e0h,002h,03fh,081h,07fh,003h,0ffh,008h,0fch	; 5eb0  .........?......
	defb 008h,03fh,0a0h,007h,00fh,0e0h,0c0h,0c0h,080h,07fh,07fh,0e0h,0f0h,007h,003h,003h	; 5ec0  .?..............
	defb 001h,0feh,0feh,007h,0e1h,0e0h,0e1h,0e3h,0e7h,0feh,0feh,0e0h,087h,007h,087h,0c7h	; 5ed0  ................
	defb 0e7h,07fh,07fh,002h,0ffh,002h,0feh,006h,0ffh,002h,07fh,006h,0ffh,002h,0feh,002h	; 5ee0  ................
	defb 0ffh,002h,07fh,002h,0ffh,002h,07fh,002h,0ffh,002h,0feh,002h,0fch,006h,0f8h,010h	; 5ef0  ................
	defb 000h,002h,03fh,006h,01fh,008h,0f0h,082h,000h,003h,004h,007h,002h,00fh,082h,000h	; 5f00  ..?.............
	defb 0c0h,004h,0e0h,002h,0f0h,008h,00fh,004h,0f8h,085h,0f0h,0e0h,0c0h,0c0h,00fh,004h	; 5f10  ................
	defb 007h,084h,0fch,0fch,000h,0f0h,004h,0e0h,083h,03fh,03fh,000h,004h,01fh,0a6h,00fh	; 5f20  .........??.....
	defb 007h,003h,003h,03fh,07fh,080h,0c0h,0e0h,0f8h,0f8h,0f8h,0fch,0feh,001h,003h,007h	; 5f30  ...?............
	defb 01fh,01fh,01fh,000h,080h,000h,080h,080h,000h,000h,000h,000h,001h,000h,001h,001h	; 5f40  ................
	defb 000h,000h,000h,080h,0ffh,005h,0feh,083h,0ffh,001h,0ffh,005h,07fh,0a9h,0ffh,0e6h	; 5f50  ................
	defb 0cdh,0fdh,0ffh,0feh,0feh,0feh,0c0h,067h,0b3h,0bfh,0ffh,07fh,07fh,07fh,003h,000h	; 5f60  .......g........
	defb 03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh,000h	; 5f70  >c..<p..>c...c>.
	defb 07eh,063h,063h,062h,07ch,066h,063h,080h,090h,04eh,007h,0b1h,081h,0fbh,007h,0b1h	; 5f80  ~ccb|fc..N......
	defb 003h,0fbh,002h,073h,004h,0f7h,002h,0fah,002h,073h,004h,0f7h,002h,0fah,002h,073h	; 5f90  ...s.....s.....s
	defb 004h,0f7h,002h,0fah,002h,073h,004h,0f7h,002h,073h,004h,0f7h,002h,031h,012h,073h	; 5fa0  .....s...s...1.s
	defb 004h,0f7h,002h,031h,005h,0f7h,003h,0e7h,005h,0f7h,003h,0e7h,002h,073h,004h,0f7h	; 5fb0  ...1.........s..
	defb 004h,073h,004h,0f7h,002h,073h,081h,0a7h,005h,071h,002h,075h,081h,0a7h,005h,071h	; 5fc0  .s...s...q.u...q
	defb 002h,075h,016h,075h,002h,071h,006h,075h,002h,071h,044h,0e1h,003h,0e6h,005h,0e1h	; 5fd0  .u.u.q.u.qD.....
	defb 081h,0e6h,003h,061h,004h,0e1h,081h,0e6h,003h,061h,004h,0e1h,003h,0e6h,081h,0e1h	; 5fe0  ...a.....a......
	defb 002h,0a7h,003h,0eah,003h,0e1h,002h,0a7h,003h,0eah,003h,0e1h,010h,0b1h,081h,0f7h	; 5ff0  ................
	defb 007h,071h,081h,0f7h,007h,071h,007h,0b1h,081h,0fbh,007h,0b1h,081h,0fbh,018h,018h	; 6000  .q...q..........
	defb 080h,0e0h,05ch,005h,000h,086h,01ch,00eh,02eh,077h,023h,00fh,00ah,000h,086h,038h	; 6010  ..\......w#....8
	defb 070h,074h,0eeh,0c4h,0f8h,008h,000h,08ah,007h,01bh,021h,060h,0c0h,080h,080h,0f0h	; 6020  pt........!`....
	defb 018h,007h,006h,000h,08ah,0e0h,0d8h,084h,006h,003h,001h,001h,007h,018h,0e0h,007h	; 6030  ................
	defb 000h,088h,004h,002h,011h,011h,008h,05ch,000h,007h,008h,000h,088h,020h,040h,088h	; 6040  .......\..... @.
	defb 088h,010h,03ah,000h,0e0h,008h,000h,088h,01ch,00eh,007h,076h,0f7h,00bh,00ch,007h	; 6050  ..:........v....
	defb 008h,000h,088h,038h,070h,0e0h,06eh,0efh,0d0h,030h,0e0h,005h,000h,086h,003h,007h	; 6060  ...8p.n..0......
	defb 018h,020h,040h,080h,003h,000h,083h,0f0h,018h,007h,004h,000h,086h,0c0h,0e0h,018h	; 6070  . @.............
	defb 004h,002h,001h,003h,000h,083h,00fh,018h,0e0h,006h,000h,088h,007h,003h,031h,078h	; 6080  ..............1x
	defb 089h,008h,0f4h,003h,008h,000h,088h,0e0h,0c0h,08ch,01eh,091h,010h,02fh,0c0h,009h	; 6090  ............./..
	defb 000h,089h,01ch,004h,026h,0afh,0b6h,0a7h,033h,001h,00fh,007h,000h,089h,038h,020h	; 60a0  ....&...3.....8 
	defb 064h,0f5h,06dh,0e5h,0cch,080h,0f0h,004h,000h,085h,003h,00fh,021h,040h,080h,005h	; 60b0  d.m.........!@..
	defb 000h,08bh,0c2h,020h,01fh,007h,000h,000h,0c0h,0f0h,084h,002h,001h,005h,000h,084h	; 60c0  ... ............
	defb 043h,004h,0fbh,0e0h,004h,000h,08ah,01eh,023h,07bh,0d9h,050h,049h,058h,0cch,03ch	; 60d0  C.......#{.PIX.<
	defb 010h,006h,000h,08ah,078h,0c4h,0deh,09bh,00ah,092h,01ah,033h,03ch,008h,003h,000h	; 60e0  ....x......3<...
	defb 080h,000h,05ch,087h,000h,000h,007h,00fh,01fh,01ch,01dh,004h,01fh,097h,03eh,07ch	; 60f0  ..\...........>|
	defb 01eh,03fh,0ffh,000h,000h,080h,0c0h,0e0h,0e0h,0f8h,0f8h,0f8h,0f0h,0a0h,010h,010h	; 6100  .?..............
	defb 01ch,038h,030h,0c0h,080h,005h,000h,084h,080h,040h,020h,030h,015h,000h,08ah,000h	; 6110  .80......@ 0....
	defb 000h,038h,010h,000h,060h,020h,000h,060h,020h,009h,000h,083h,008h,018h,018h,00ch	; 6120  .8..` .` .......
	defb 000h,084h,003h,007h,00eh,00eh,004h,00fh,098h,03fh,07eh,01ch,03fh,07eh,0fch,000h	; 6130  .........?~.?~..
	defb 000h,0c0h,0e0h,070h,0f0h,0fch,0fch,0fch,0f8h,020h,010h,010h,018h,038h,03ch,060h	; 6140  ...p..... ...8<`
	defb 040h,006h,000h,084h,0c0h,020h,040h,0f0h,014h,000h,094h,000h,004h,004h,007h,007h	; 6150  @.... @.........
	defb 043h,063h,063h,039h,07fh,03fh,01fh,00fh,00fh,03dh,060h,003h,0fbh,09fh,0ffh,008h	; 6160  Ccc9.?...=`.....
	defb 000h,003h,0ffh,085h,0c2h,006h,0fch,0ffh,0ffh,008h,000h,094h,0ffh,0ffh,0eeh,0c0h	; 6170  ................
	defb 000h,000h,0b0h,036h,064h,0cch,08ch,0b8h,0f8h,0fch,0e0h,0e6h,0e4h,070h,000h,040h	; 6180  ...6d........p.@
	defb 080h,000h,05eh,083h,001h,003h,007h,006h,00fh,083h,007h,003h,001h,004h,000h,002h	; 6190  ..^.............
	defb 0ffh,008h,000h,086h,0ffh,0ffh,03fh,01eh,01ch,038h,002h,0ffh,008h,000h,002h,0ffh	; 61a0  ......?..8......
	defb 004h,000h,083h,0c0h,0e0h,0f0h,006h,0f8h,083h,0f0h,0e0h,0c0h,004h,000h,080h,0a0h	; 61b0  ................
	defb 065h,0c8h,007h,00dh,00ch,03dh,07dh,0cdh,007h,000h,0ffh,0d6h,0d5h,055h,095h,0d6h	; 61c0  e....=}......U..
	defb 0ffh,000h,0ffh,030h,0d7h,0f0h,0d7h,030h,0ffh,000h,0f8h,04ch,0cch,0cch,0fch,04ch	; 61d0  ...0...0...L...L
	defb 0f8h,000h,007h,00eh,00dh,03dh,07dh,0ceh,007h,000h,0ffh,030h,0f7h,010h,0b4h,034h	; 61e0  .....=}....0...4
	defb 0ffh,000h,0ffh,0c1h,05fh,043h,0dfh,041h,0ffh,000h,0ffh,08ch,077h,007h,077h,077h	; 61f0  ...._C.A....w.ww
	defb 0ffh,000h,0feh,013h,073h,073h,07fh,073h,0feh,000h,080h,0a0h,045h,070h,0f6h,028h	; 6200  ....ss.s....Ep.(
	defb 0f6h,080h,010h,068h,0c0h,0fch,0f0h,0c3h,00fh,03fh,0ffh,0feh,0fch,0f1h,0c3h,08fh	; 6210  ...h.....?......
	defb 03fh,07fh,0feh,0f8h,0f1h,0c7h,08fh,03fh,07fh,0fch,0f8h,0f3h,0c7h,03fh,00fh,0c3h	; 6220  ?......?.....?..
	defb 0f0h,0fch,0ffh,07fh,03fh,08fh,0c3h,0f1h,0fch,0feh,07fh,01fh,08fh,0e3h,0f1h,0fch	; 6230  ....?...........
	defb 0feh,03fh,01fh,0cfh,0e3h,08fh,03fh,07fh,0ffh,0ffh,0feh,0fch,0f8h,0f1h,0fch,0feh	; 6240  .?....?.........
	defb 0ffh,0ffh,07fh,03fh,01fh,040h,000h,084h,0f0h,0e0h,0c0h,080h,004h,000h,084h,00fh	; 6250  ...?.@..........
	defb 01fh,03fh,07fh,004h,0ffh,088h,0f3h,0c7h,08fh,03fh,07fh,001h,003h,007h,010h,000h	; 6260  .?.......?......
	defb 084h,00fh,007h,003h,001h,004h,000h,084h,0f0h,0f8h,0fch,0feh,004h,0ffh,0c9h,0cfh	; 6270  ................
	defb 0e3h,0f1h,0fch,0feh,080h,0c0h,0e0h,03fh,0ffh,0fch,0f0h,0e3h,08fh,01fh,07fh,0fch	; 6280  .......?........
	defb 0f8h,0e3h,0c7h,01fh,03fh,0fch,0f8h,0fch,0ffh,03fh,00fh,0c7h,0f1h,0f8h,0feh,03fh	; 6290  ....?....?.....?
	defb 01fh,0c7h,0e3h,0f8h,0fch,03fh,01fh,083h,001h,040h,030h,081h,0ffh,083h,001h,040h	; 62a0  .....?...@0....@
	defb 030h,081h,0ffh,083h,001h,040h,030h,0c1h,080h,002h,00ch,081h,0ffh,0c1h,080h,002h	; 62b0  0....@0.........
	defb 00ch,081h,0ffh,0c1h,080h,002h,00ch,081h,004h,0ffh,003h,000h,081h,081h,004h,0ffh	; 62c0  ................
	defb 003h,000h,002h,0ffh,002h,000h,004h,0ffh,002h,000h,004h,0ffh,002h,000h,005h,0ffh	; 62d0  ................
	defb 003h,000h,080h,010h,070h,081h,0ffh,004h,000h,083h,0feh,0fch,0fch,081h,0ffh,005h	; 62e0  ....p...........
	defb 000h,002h,0ffh,008h,0fch,00fh,03fh,081h,07fh,007h,0fch,081h,0feh,008h,080h,00dh	; 62f0  ......?.........
	defb 001h,003h,0ffh,005h,080h,003h,0ffh,005h,000h,083h,00fh,01fh,01eh,008h,01ch,005h	; 6300  ................
	defb 000h,083h,0f0h,0f8h,078h,008h,038h,005h,000h,003h,0ffh,085h,01eh,01fh,00fh,000h	; 6310  ....x.8.........
	defb 000h,00bh,0ffh,085h,078h,0f8h,0f0h,000h,000h,004h,0ffh,004h,000h,083h,07fh,03fh	; 6320  ....x..........?
	defb 03fh,005h,000h,08bh,003h,00fh,01fh,000h,007h,00fh,00fh,00fh,0cfh,0f7h,0f8h,002h	; 6330  ?...............
	defb 000h,081h,080h,005h,0c0h,003h,000h,002h,001h,002h,003h,083h,007h,03fh,07fh,00eh	; 6340  .............?..
	defb 0ffh,082h,0fch,0feh,006h,0ffh,088h,060h,060h,020h,0b0h,090h,0d8h,0c8h,0e8h,002h	; 6350  .......`` ......
	defb 007h,006h,00fh,002h,0e8h,002h,0f8h,008h,0f0h,003h,0e0h,081h,0c0h,004h,0ffh,087h	; 6360  ................
	defb 0feh,0fch,0f8h,0f0h,0c0h,080h,080h,008h,000h,085h,01fh,0ffh,0ffh,00fh,078h,003h	; 6370  ..............x.
	defb 000h,087h,0f8h,0ffh,0ffh,0f8h,01fh,003h,001h,00ah,0ffh,084h,0feh,0fdh,0fah,0f8h	; 6380  ................
	defb 004h,0ffh,086h,080h,040h,0dfh,01fh,0fch,0feh,006h,0ffh,082h,03fh,07fh,006h,0ffh	; 6390  ....@.......?...
	defb 004h,00fh,003h,007h,081h,003h,005h,0ffh,08eh,01fh,003h,001h,01fh,003h,001h,0ffh	; 63a0  ................
	defb 07fh,03fh,01fh,00fh,003h,001h,001h,005h,000h,004h,0ffh,084h,07fh,01fh,000h,000h	; 63b0  .?..............
	defb 004h,0ffh,084h,0e3h,0cfh,01fh,03fh,081h,003h,007h,000h,080h,000h,073h,0b3h,01ch	; 63c0  ......?......s..
	defb 03eh,07eh,07dh,07fh,03eh,024h,03ch,038h,07ch,07eh,0beh,0feh,07ch,024h,03ch,01ch	; 63d0  >~}.>$<8|~..|$<.
	defb 03eh,07eh,07dh,07fh,03eh,024h,03ch,038h,07ch,07eh,0beh,0feh,07ch,024h,03ch,01ch	; 63e0  >~}.>$<8|~..|$<.
	defb 03eh,07eh,07dh,07fh,03eh,024h,03ch,038h,07ch,07eh,0beh,0feh,07ch,024h,03ch,0ffh	; 63f0  >~}.>$<8|~..|$<.
	defb 0ffh,01fh,005h,000h,083h,0ffh,0ffh,0f8h,005h,000h,081h,0c0h,00fh,000h,005h,000h	; 6400  ................
	defb 086h,0c0h,0f0h,0f8h,000h,01ch,03eh,003h,03fh,08eh,01fh,003h,003h,003h,002h,082h	; 6410  ......>.?.......
	defb 086h,0c6h,0c6h,0e6h,0e6h,0e4h,0fch,0f8h,004h,0f0h,080h,010h,040h,008h,077h,008h	; 6420  ............@.w.
	defb 044h,008h,044h,010h,04ch,010h,030h,008h,0feh,003h,094h,005h,019h,004h,094h,004h	; 6430  D.D.L.0.........
	defb 015h,004h,094h,004h,018h,008h,052h,081h,0eeh,007h,0f5h,081h,0eeh,007h,0f8h,008h	; 6440  ......R.........
	defb 082h,058h,071h,008h,0f0h,081h,0eeh,003h,0ffh,002h,033h,002h,0ffh,080h,008h,048h	; 6450  .Xq.......3....H
	defb 008h,0eeh,035h,0f2h,003h,0feh,005h,0f2h,04bh,0feh,008h,0e5h,005h,052h,003h,0e5h	; 6460  ..5.....K....R..
	defb 00dh,0f2h,00bh,0feh,008h,0e8h,005h,082h,003h,0e8h,010h,052h,010h,082h,010h,0f5h	; 6470  ...........R....
	defb 010h,0f8h,005h,0f5h,003h,0feh,005h,0f8h,003h,0feh,010h,0f3h,008h,0feh,080h,008h	; 6480  ................
	defb 050h,008h,0eeh,005h,0dbh,083h,0b4h,0b5h,0b7h,005h,0dbh,083h,074h,054h,070h,015h	; 6490  P...........tTp.
	defb 0b5h,083h,0b7h,0b5h,0b4h,005h,0b5h,083h,0b7h,0b5h,0b4h,016h,070h,082h,055h,040h	; 64a0  ............p.U@
	defb 006h,070h,082h,054h,040h,020h,0c0h,006h,030h,082h,0c0h,000h,005h,0c0h,08bh,070h	; 64b0  .p.T@ ..0......p
	defb 054h,040h,000h,0c5h,030h,000h,000h,070h,050h,040h,005h,0c0h,083h,070h,050h,040h	; 64c0  T@..0..pP@...pP@
	defb 005h,0dbh,083h,0b4h,0b5h,0b7h,06eh,0b0h,002h,0fbh,006h,0b0h,004h,0fbh,00ah,0b0h	; 64d0  ......n.........
	defb 004h,0bah,004h,0b0h,002h,0fbh,004h,0bah,006h,0b0h,002h,0bah,00ah,0b0h,004h,0a0h	; 64e0  ................
	defb 005h,0b0h,006h,0bah,00dh,0a0h,010h,0bah,005h,0a0h,083h,077h,055h,044h,080h,000h	; 64f0  ...........wUD..
	defb 053h,010h,050h,010h,090h,010h,0f0h,005h,0a0h,083h,077h,055h,044h,005h,0b0h,083h	; 6500  S.P.......wUD...
	defb 077h,055h,044h,005h,0b0h,083h,077h,055h,044h,005h,000h,083h,077h,055h,044h,020h	; 6510  wUD...wUD...wUD 
	defb 0b0h,080h,000h,078h,00ch,004h,088h,005h,007h,054h,049h,04dh,045h,008h,006h,018h	; 6520  ...x.....TIME...
	defb 004h,088h,005h,007h,033h,01ch,030h,030h,008h,006h,00ch,004h,00ch,060h,088h,061h	; 6530  ....3.00.....`.a
	defb 062h,063h,064h,079h,078h,077h,076h,00ch,075h,060h,000h,08dh,00ah,00bh,00ah,00ah	; 6540  bcdyxwv.u`......
	defb 00ah,00ah,002h,011h,012h,013h,014h,015h,016h,005h,002h,091h,017h,018h,014h,019h	; 6550  ................
	defb 01ah,01bh,015h,002h,00ah,00ah,00ah,00ah,00ch,00ah,009h,00dh,00eh,01ah,01dh,086h	; 6560  ................
	defb 00fh,010h,009h,002h,01ah,01eh,01ah,024h,086h,020h,01ch,005h,003h,01bh,01fh,01ah	; 6570  .......$. ......
	defb 025h,086h,021h,01dh,006h,004h,014h,022h,01ah,026h,085h,023h,019h,007h,008h,013h	; 6580  %.!....".&.#....
	defb 01ch,001h,083h,018h,009h,012h,01eh,001h,082h,017h,001h,07fh,001h,081h,002h,01eh	; 6590  ................
	defb 003h,089h,014h,004h,008h,000h,052h,04fh,055h,04eh,044h,006h,000h,08bh,015h,022h	; 65a0  ......ROUND...."
	defb 023h,016h,017h,000h,053h,054h,041h,047h,045h,005h,000h,084h,009h,005h,004h,008h	; 65b0  #...STAGE.......
	defb 00bh,000h,086h,018h,019h,01ah,024h,01bh,01ch,00bh,000h,082h,009h,005h,088h,004h	; 65c0  ......$.........
	defb 008h,000h,09ah,09bh,09ch,09dh,09eh,005h,000h,08ch,01dh,01ah,025h,026h,01ah,01eh	; 65d0  ............%&..
	defb 000h,09ah,09bh,09ch,09dh,09eh,005h,000h,087h,009h,005h,004h,008h,000h,000h,00ch	; 65e0  ................
	defb 008h,010h,086h,029h,02ah,027h,028h,01ah,01fh,008h,010h,08ah,00eh,000h,000h,009h	; 65f0  ...)*'(.........
	defb 005h,004h,008h,000h,000h,00dh,005h,060h,003h,062h,086h,02ch,02bh,02dh,02eh,020h	; 6600  .......`.b.,+-. 
	defb 021h,003h,063h,005h,061h,08ah,00fh,000h,000h,009h,005h,007h,00bh,069h,069h,011h	; 6610  !.c.a........ii.
	defb 009h,012h,084h,02fh,066h,067h,068h,009h,012h,085h,013h,069h,069h,00ah,006h,080h	; 6620  .../fgh....ii...
	defb 000h,063h,09ch,0f8h,0fch,0feh,000h,0ddh,066h,066h,0ffh,0c0h,07fh,000h,000h,0ddh	; 6630  .c......ff......
	defb 066h,066h,0ffh,000h,0ffh,000h,000h,0ddh,066h,066h,0ffh,000h,0ffh,000h,000h,004h	; 6640  ff......ff......
	defb 007h,084h,000h,0ffh,000h,000h,004h,0e0h,0c0h,000h,0ffh,000h,000h,0ddh,066h,066h	; 6650  ..............ff
	defb 0ffh,003h,0feh,000h,000h,0ddh,066h,066h,0ffh,01fh,03fh,07fh,000h,0ddh,066h,066h	; 6660  ......ff..?...ff
	defb 0ffh,0ffh,0ffh,0ffh,000h,0ddh,066h,066h,0ffh,0c7h,038h,0bah,0bah,07ch,0fch,0f8h	; 6670  ......ff..8..|..
	defb 007h,0c7h,038h,0bah,0bah,07ch,07fh,03eh,03eh,0c7h,038h,038h,0bah,07ch,03fh,00fh	; 6680  ..8..|.>>.88.|?.
	defb 0f0h,0c7h,038h,0bah,0bah,07ch,0e3h,0c1h,03eh,004h,00fh,004h,01fh,004h,0f0h,004h	; 6690  ..8..|..>.......
	defb 0f8h,0a0h,00dh,087h,096h,096h,00fh,0ffh,03fh,01fh,063h,0d1h,0d1h,090h,0e3h,0ffh	; 66a0  ........?.c.....
	defb 0fch,0f8h,058h,0f0h,0b0h,0e0h,0f8h,0ffh,03fh,01fh,06bh,0beh,0a2h,0ddh,07fh,0ffh	; 66b0  ..X.....?.k.....
	defb 0fch,0f8h,004h,03fh,004h,07fh,004h,0fch,004h,0feh,000h	; 66c0  ...?.......

; ----------------------------------------------------------------------
; DATOS guion_del_cuadrilatero_2: La continuacion, leida sin volver a fijar la
;   VRAM: 64 bytes mas. Su cola, desde 0x66DC, tambien se relee sola
;   0x66cb..0x670e  (67 bytes)
DATA_guion_del_cuadrilatero_2:
	defb 090h,067h,0edh,0efh,064h,076h,073h,07fh,03fh,0e6h,0b7h,0f7h,026h,06eh,0ceh,0feh	; 66cb  .g..dvs.?...&n..
	defb 0fch,0b0h,007h,00dh,00fh,006h,036h,033h,07fh,03fh,0e0h,0b0h,0f0h,060h,06ch,0cch	; 66db  ......63.?...`l.
	defb 0feh,0fch,067h,0edh,0efh,064h,076h,073h,07fh,03fh,0e6h,0b7h,0f7h,026h,06eh,0ceh	; 66eb  ..g..dvs.?...&n.
	defb 0feh,0fch,007h,00dh,00fh,006h,036h,033h,07fh,03fh,0e0h,0b0h,0f0h,060h,06ch,0cch	; 66fb  ......63.?...`l.
	defb 0feh,0fch,000h	; 670b

; ----------------------------------------------------------------------
; DATOS guion_de_los_marcadores: 216 bytes desde 0x0300
;   0x670e..0x67c3  (181 bytes)
DATA_guion_de_los_marcadores:
	defb 000h,043h,0c8h,072h,0f2h,0e2h,061h,061h,0a6h,0a6h,096h,0c0h,0fch,0fch,061h,061h	; 670e  .C.r..aa......aa
	defb 0a6h,0a6h,096h,0c0h,0fch,05ch,061h,061h,0a6h,0a6h,090h,0c0h,0fch,0fch,071h,016h	; 671e  .....\aa......q.
	defb 016h,016h,019h,0c0h,0fch,0fch,071h,016h,016h,016h,019h,0c0h,0fch,0fch,061h,061h	; 672e  ......q.......aa
	defb 0a6h,0a6h,096h,0c0h,0fch,0fch,061h,061h,0a6h,0a6h,096h,072h,0f2h,0e2h,061h,061h	; 673e  ......aa...r..aa
	defb 0a6h,0a6h,096h,077h,0ffh,0eeh,061h,061h,0a6h,0a6h,096h,0a0h,061h,0a6h,0a6h,0a6h	; 674e  ...w..aa....a...
	defb 076h,091h,061h,0b6h,061h,0a6h,0a6h,0a6h,076h,091h,061h,061h,061h,0a6h,0a6h,0a6h	; 675e  v.a.a...v.aaa...
	defb 0c6h,091h,061h,0b6h,061h,0a6h,0a6h,0a6h,076h,091h,061h,0b6h,005h,046h,081h,049h	; 676e  ..a.a...v.a..F.I
	defb 007h,046h,083h,049h,046h,046h,004h,0b6h,084h,076h,096h,091h,061h,004h,0b6h,084h	; 677e  .F.IFF...v..a...
	defb 076h,091h,091h,061h,004h,0b6h,084h,076h,096h,091h,061h,004h,0b6h,084h,0c6h,096h	; 678e  v..a...v..a.....
	defb 091h,061h,005h,046h,002h,049h,006h,046h,083h,049h,049h,046h,006h,0b6h,002h,076h	; 679e  .a.F.I.F.IIF...v
	defb 006h,0b6h,002h,076h,006h,0b6h,002h,0c6h,006h,0b6h,002h,0c6h,006h,0b6h,002h,0d6h	; 67ae  ...v............
	defb 006h,0b6h,002h,0d6h,000h	; 67be

; ----------------------------------------------------------------------
; DATOS guion_de_cinco_bytes: Cinco bytes que escriben 127
;   0x67c3..0x67c8  (5 bytes)
DATA_guion_de_cinco_bytes:
	defb 080h,054h,07fh,0a0h,000h	; 67c3

; ----------------------------------------------------------------------
; DATOS panel_izquierdo: Guion por filas: 64 casillas en CUATRO filas de
;   dieciseis, en la fila 1 columna 0
;   0x67c8..0x680c  (68 bytes)
DATA_panel_izquierdo:
	defb 068h,068h,068h,068h,068h,068h,068h,068h,068h,068h,068h,068h,060h,061h,062h,063h,0ffh	; 67c8  hhhhhhhhhhhh`abc.
	defb 069h,06ah,06bh,06ch,069h,06ah,06bh,06ch,069h,06ah,06bh,06ch,069h,06ah,06bh,06dh,0ffh	; 67d9  ijklijklijklijkm.
	defb 06fh,070h,071h,072h,06fh,070h,071h,072h,06fh,070h,071h,072h,06fh,070h,071h,073h,0ffh	; 67ea  opqropqropqropqs.
	defb 078h,075h,076h,077h,078h,075h,076h,077h,078h,075h,076h,077h,078h,079h,07ah,003h,000h	; 67fb  xuvwxuvwxuvwxyz..

; ----------------------------------------------------------------------
; DATOS panel_derecho: El otro, igual de medido: 64 casillas en cuatro filas
;   de dieciseis, en la fila 1 columna 16
;   0x680c..0x6850  (68 bytes)
DATA_panel_derecho:
	defb 064h,065h,066h,067h,068h,068h,068h,068h,068h,068h,068h,068h,068h,068h,068h,068h,0ffh	; 680c  defghhhhhhhhhhhh.
	defb 06eh,06ch,069h,06ah,06bh,06ch,069h,06ah,06bh,06ch,069h,06ah,06bh,06ch,069h,06ah,0ffh	; 681d  nlijklijklijklij.
	defb 074h,072h,06fh,070h,071h,072h,06fh,070h,071h,072h,06fh,070h,071h,072h,06fh,070h,0ffh	; 682e  tropqropqropqrop.
	defb 003h,075h,076h,077h,078h,079h,07ah,077h,078h,075h,076h,077h,078h,075h,076h,077h,000h	; 683f  .uvwxyzwxuvwxuvw.

; ----------------------------------------------------------------------
; DATOS el_castigo_de_cada_golpe: Lo que suma cada golpe al que lo recibe: 12
;   el 5, 10 el 6, 9 el 7 y 2 el 8
;   0x6850..0x6854  (4 bytes)
DATA_el_castigo_de_cada_golpe:
	defb 00ch,00ah,009h,002h	; 6850

; ----------------------------------------------------------------------
; DATOS lo_que_cansa_cada_golpe: Lo que se cobra el golpe a QUIEN LO DA,
;   sumado a su propio castigo al acabar: 3 el golpe 5, 2 el 6 y 1 los otros
;   dos
;   0x6854..0x6858  (4 bytes)
DATA_lo_que_cansa_cada_golpe:
	defb 003h,002h,001h,001h	; 6854

; ----------------------------------------------------------------------
; DATOS ternas_por_grupo: Cuatro grupos de ocho ternas. Del cuarto grupo
;   (0x68A0) solo hay ocho bytes, y 0x4C33 los lee aparte con `ld a,r` -o sea
;   AL AZAR- y `and 007h`
;   0x6858..0x68a8  (80 bytes)
DATA_ternas_por_grupo:
	defb 038h,0a7h,097h,058h,097h,057h,068h,087h	; 6858  8..X.Wh.
	defb 069h,048h,055h,095h,058h,0a5h,069h,049h	; 6860  iHU.X.iI
	defb 095h,085h,049h,059h,056h,049h,059h,086h	; 6868  ..IYVIY.
	defb 038h,048h,077h,068h,048h,075h,058h,076h	; 6870  8HwhHuXv
	defb 075h,068h,087h,056h,085h,086h,057h,076h	; 6878  uh.V..Wv
	defb 096h,085h,055h,079h,079h,069h,086h,079h	; 6880  ..Uyyi.y
	defb 038h,075h,057h,048h,066h,055h,048h,077h	; 6888  8uWHfUHw
	defb 056h,048h,067h,077h,077h,069h,066h,065h	; 6890  VHgwwife
	defb 068h,059h,059h,058h,076h,079h,048h,076h	; 6898  hYYXvyHv
	defb 067h,058h,068h,067h,095h,048h,085h,056h	; 68a0  gXhg.H.V

; ----------------------------------------------------------------------
; DATOS punteros_de_los_retratos: Cinco punteros que 0x5520 indexa. Los dos
;   primeros son el mismo, 0x68B2, y los otros tres van de 42 en 42
;   0x68a8..0x68b2  (10 bytes)
DATA_punteros_de_los_retratos:
	defw 068b2h,068b2h,068dch,06906h,06930h	; 68a8

; ----------------------------------------------------------------------
; DATOS retrato_1: Retrato de SEIS casillas de ancho por SIETE de alto: el
;   bucle de 0x5536 hace siete vueltas de seis bytes bajando 0x20 cada una. 6
;   x 7 = 42, que es justo lo que separa a un retrato del siguiente
;   0x68b2..0x68dc  (42 bytes)
DATA_retrato_1:
	defb 022h,023h,028h,029h,024h,025h	; 68b2
	defb 0d4h,0d5h,0f8h,0f9h,0d6h,0d7h	; 68b8
	defb 0d8h,0d9h,0e0h,0e1h,0dah,0dbh	; 68be
	defb 026h,0dch,0e2h,0e3h,0ddh,026h	; 68c4
	defb 001h,0e6h,0e7h,0e8h,0e9h,001h	; 68ca
	defb 001h,0eah,0ebh,0ech,0edh,001h	; 68d0
	defb 001h,0eeh,0efh,0f0h,0f1h,001h	; 68d6

; ----------------------------------------------------------------------
; DATOS retrato_2: El segundo, igual de medido: 42 bytes, 6 x 7
;   0x68dc..0x6906  (42 bytes)
DATA_retrato_2:
	defb 01dh,01dh,026h,027h,024h,025h	; 68dc
	defb 024h,024h,0d2h,0d3h,0d6h,0d7h	; 68e2
	defb 025h,0deh,0e0h,0e1h,0dah,0dbh	; 68e8
	defb 026h,0f6h,0e4h,0e3h,0ddh,026h	; 68ee
	defb 001h,0f2h,0f4h,0e8h,0e9h,001h	; 68f4
	defb 001h,0eah,0ebh,0ech,0edh,001h	; 68fa
	defb 001h,0eeh,0efh,0f0h,0f1h,001h	; 6900

; ----------------------------------------------------------------------
; DATOS retrato_3: El tercero de los cuatro, con el mismo formato que los
;   otros tres
;   0x6906..0x6930  (42 bytes)
DATA_retrato_3:
	defb 022h,023h,026h,027h,01dh,01dh	; 6906
	defb 0d4h,0d5h,0d2h,0d3h,024h,024h	; 690c
	defb 0d8h,0d9h,0e0h,0e1h,0dfh,025h	; 6912
	defb 026h,0dch,0e2h,0e5h,0f7h,026h	; 6918
	defb 001h,0e6h,0e7h,0f5h,0f3h,001h	; 691e
	defb 001h,0eah,0ebh,0ech,0edh,001h	; 6924
	defb 001h,0eeh,0efh,0f0h,0f1h,001h	; 692a

; ----------------------------------------------------------------------
; DATOS retrato_4: El cuarto, que cierra justo donde empieza el motor de
;   sonido
;   0x6930..0x695a  (42 bytes)
DATA_retrato_4:
	defb 01dh,01dh,026h,027h,01dh,01dh	; 6930
	defb 024h,024h,0d2h,0d3h,024h,024h	; 6936
	defb 025h,0deh,0e0h,0e1h,0dfh,025h	; 693c
	defb 026h,0f6h,0e4h,0e5h,0f7h,026h	; 6942
	defb 001h,0f2h,0f4h,0f5h,0f3h,001h	; 6948
	defb 001h,0eah,0ebh,0ech,0edh,001h	; 694e
	defb 001h,0eeh,0efh,0f0h,0f1h,001h	; 6954

; ======================================================================
; CODIGO 0x695a..0x6bb2  (600 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; EL MOTOR DE SONIDO
; ======================================================================
; Tres voces, cada una con su bloque de CATORCE bytes desde 0xE311:
; +0 el contador de la nota    +1 la duracion de base
; +2 el numero de sonido, que hace de estado y de prioridad
; +3 y +4 el puntero del guion +5 la octava    +6 el sostenido
; +7 el volumen de ahora       +8 el contador de la bajada
; +9 las vueltas dadas         +0x0A el paso del volumen
; +0x0B lo que queda de ataque +0x0C el desafine
; De ahi que (0xE313) sea el estado de la primera voz -lo que consulta
; la escena 6 para esperar a que se calle- y (0xE32F) el de la tercera.
; Cuantas voces se reparten depende del numero: por debajo del 7 solo la
; tercera, del 7 al 0x12 dos, y del 0x13 en adelante las tres.
; ----------------------------------------------------------------------
pide_un_sonido:
	di			;695a   ; mientras se monta, sin interrupciones
	push af			;695b
	ld a,(0e000h)		;695c   ; la escena
	cp 002h		;695f   ; en la 2, la demostracion, no suena nada
	jr nz,L_6966		;6961
	pop af			;6963
	ei			;6964
	ret			;6965
L_6966:
	pop af			;6966
pide_un_sonido_aunque_sea_la_demo:
	push hl			;6967
	push de			;6968
	push bc			;6969
	ld c,a			;696a   ; el numero de sonido
	ld b,002h		;696b   ; dos voces
	ld hl,0e313h		;696d   ; el estado de la primera voz
	and 03fh		;6970   ; seis bits
	cp 007h		;6972   ; por debajo del 7...
	jr c,L_6980		;6974
	cp 013h		;6976   ; del 7 al 0x12, dos voces
	jr c,L_6985		;6978
	jr nz,L_697D		;697a   ; y el 0x13 se apunta aparte
	ld d,a			;697c
L_697D:
	inc b			;697d   ; del 0x13 en adelante, tres
	jr L_6985		;697e
L_6980:
	dec b			;6980   ; ...una sola voz
	ld l,02fh		;6981   ; la tercera
	jr L_69A1		;6983
L_6985:
	ld a,(hl)			;6985   ; el estado de la primera
	and 03fh		;6986   ; seis bits
	ld e,a			;6988
	cp 016h		;6989   ; el 0x16 exacto...
	jr nz,L_699B		;698b
	ld a,d			;698d   ; ...con el 0x13 pedido se deja
	cp 013h		;698e
	jr z,L_69A1		;6990
	xor a			;6992   ; y si no, la tercera se calla
	ld (0e32fh),a		;6993
	ld a,c			;6996   ; y suena el pedido
	and 03fh		;6997
	jr L_69A1		;6999
L_699B:
	ld a,c			;699b   ; el pedido
	and 03fh		;699c
	cp e			;699e   ; contra el que suena
	jr c,L_69C7		;699f   ; con menos numero no se cuela: el numero es la prioridad
L_69A1:
	add a,a			;69a1   ; palabras
	ld de,06bbch		;69a2   ; la tabla de guiones de 0x6BBC
	call suma_a_de		;69a5
	dec hl			;69a8   ; al principio del bloque de la voz
	dec hl			;69a9
L_69AA:
	ld (hl),001h		;69aa   ; el contador, a uno
	inc hl			;69ac
	ld (hl),001h		;69ad   ; y la duracion tambien
	inc hl			;69af
	ld (hl),c			;69b0   ; el numero, que queda de estado
	inc hl			;69b1
	ld a,(de)			;69b2   ; el puntero del guion
	ld (hl),a			;69b3
	inc hl			;69b4
	inc de			;69b5
	ld a,(de)			;69b6
	ld (hl),a			;69b7
	ld a,005h		;69b8   ; cinco bytes mas alla
	call suma_a_hl		;69ba
	xor a			;69bd
	ld (hl),a			;69be   ; las vueltas del repetidor, a cero
	ld a,005h		;69bf
	call suma_a_hl		;69c1
	inc de			;69c4   ; las voces de un sonido van seguidas en la tabla
	djnz L_69AA		;69c5   ; una, dos o tres
L_69C7:
	pop bc			;69c7   ; lo que se guardo al entrar
	pop de			;69c8
	pop hl			;69c9
	ei			;69ca   ; y se sueltan las interrupciones
	ret			;69cb

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El 0xFE del guion: repetir un trozo.
; ----------------------------------------------------------------------
repite_un_trozo:
	inc hl			;69cc
	ld a,(ix+009h)		;69cd   ; cuantas vueltas lleva
	inc a			;69d0
	cp (hl)			;69d1   ; contra las que pide el guion
	jr z,L_69E7		;69d2   ; si ya estan hechas, se sigue de largo
	jp m,L_69D8		;69d4   ; el 0x00 quiere decir para siempre
	dec a			;69d7
L_69D8:
	ld (ix+009h),a		;69d8
	inc hl			;69db   ; y si no, se vuelve a la direccion que trae el guion
	ld a,(hl)			;69dc
	ld (ix+003h),a		;69dd
	inc hl			;69e0
	ld a,(hl)			;69e1
	ld (ix+004h),a		;69e2
	jr L_69F0		;69e5
L_69E7:
	inc hl			;69e7   ; dos bytes de la orden
	inc hl			;69e8
	xor a			;69e9
	ld (ix+009h),a		;69ea   ; la cuenta se reinicia
	call avanza_el_guion		;69ed
L_69F0:
	inc (ix+000h)		;69f0   ; una nota mas
	jr sigue_el_guion		;69f3

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; El mezclador. OJO: los bits que toca son el 3, el 4 y el 5, o sea los
; del RUIDO, no los del tono. El tono de las tres voces se deja abierto
; en el arranque (0x4401 escribe 0xB8 en el registro 7) y no se vuelve a
; tocar: para callar una voz se le baja el volumen, no se cierra aqui.
; Y el sentido de D es el contrario del que parece: el registro 7 del PSG
; va al reves, asi que con D=1 el bit se PONE y el ruido se APAGA.
; ----------------------------------------------------------------------
enciende_o_apaga_el_ruido:
	ld a,(0e310h)		;69f5   ; la copia del registro 7
	ld e,a			;69f8
	ld a,c			;69f9   ; c es 1, 3 o 5: la voz
	cp 001h		;69fa
	jr z,L_69FF		;69fc
	dec a			;69fe
L_69FF:
	rlca			;69ff   ; tres rotaciones dejan 0x08, 0x10 o 0x20, los bits de ruido
	rlca			;6a00
	rlca			;6a01
	dec d			;6a02   ; con D a uno...
	jr z,L_6A09		;6a03
	cpl			;6a05   ; el bit se quita y el ruido suena
	and e			;6a06
	jr escribe_el_mezclador		;6a07
L_6A09:
	or e			;6a09   ; ...el bit se pone y el ruido calla
escribe_el_mezclador:
	ld (0e310h),a		;6a0a
	ld e,a			;6a0d
	ld a,007h		;6a0e   ; el registro 7 del PSG es el mezclador
	jp 00093h		;6a10   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
suena_el_cuadro:
	ld a,(0e310h)		;6a13   ; primero el mezclador, tal como quedo
	call escribe_el_mezclador		;6a16
	ld c,001h		;6a19   ; la voz A, que en el PSG es el registro 1
	ld ix,0e311h		;6a1b   ; y su bloque de catorce bytes
	exx			;6a1f
	ld b,003h		;6a20   ; tres voces
	ld de,0000eh		;6a22   ; catorce bytes de una a otra
L_6A25:
	exx			;6a25
	ld a,(ix+002h)		;6a26   ; si la voz esta callada...
	or a			;6a29
	jr nz,L_6A31		;6a2a
	call calla_la_voz		;6a2c   ; ...se apaga
	jr L_6A34		;6a2f
L_6A31:
	call calla_el_ruido_si_lo_pide_el_estado		;6a31   ; y si no, suena
L_6A34:
	inc c			;6a34   ; c va 1, 3, 5: son los registros de periodo de las tres voces
	inc c			;6a35
	exx			;6a36
	add ix,de		;6a37   ; y ix salta al siguiente bloque
	djnz L_6A25		;6a39
	ret			;6a3b
calla_el_ruido_si_lo_pide_el_estado:
	bit 6,a		;6a3c   ; el bit 6 del estado
	ld d,001h		;6a3e   ; apagar
	call z,enciende_o_apaga_el_ruido		;6a40
sigue_el_guion:
	ld a,(ix+002h)		;6a43   ; el estado de la voz
	or a			;6a46
	jp m,envolvente		;6a47   ; con el bit 7 puesto, la envolvente
	cp 01fh		;6a4a   ; el 0x1F espera...
	jr nz,L_6A53		;6a4c
	ld a,(0e005h)		;6a4e   ; ...a que el cuadro anterior haya salido
	or a			;6a51
	ret nz			;6a52
L_6A53:
	dec (ix+000h)		;6a53   ; la nota sigue sonando: solo baja el contador
	ret nz			;6a56
paso_del_guion:
	ld l,(ix+003h)		;6a57   ; el puntero del guion
	ld h,(ix+004h)		;6a5a
	ld a,(hl)			;6a5d   ; el byte
	cp 0feh		;6a5e   ; 0xFE: repetir un trozo
	jp z,repite_un_trozo		;6a60
	jp nc,calla_la_voz		;6a63   ; 0xFF: se acabo la voz
	bit 7,(ix+002h)		;6a66   ; con el bit 7 puesto, lo que viene es una orden larga
	jp nz,orden_larga		;6a6a
	cp 020h		;6a6d   ; el 0x20 monta la envolvente del PSG
	jp nz,L_6A97		;6a6f
	ld (ix+00bh),001h		;6a72   ; un cuadro de ataque
	inc hl			;6a76
	ld a,(hl)			;6a77   ; el registro 12, la parte alta del periodo
	ld e,a			;6a78
	ld a,00ch		;6a79
	call 00093h		;6a7b   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;6a7e
	ld a,(hl)			;6a7f   ; el 11, la baja
	ld e,a			;6a80
	ld a,00bh		;6a81
	call 00093h		;6a83   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;6a86
	ld a,(hl)			;6a87   ; y el 13, la forma
	and 00fh		;6a88
	ld e,a			;6a8a
	ld a,00dh		;6a8b
	call 00093h		;6a8d   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;6a90
	ld a,(hl)			;6a91   ; y detras, la duracion
	ld (ix+000h),a		;6a92
	jr L_6AA3		;6a95
L_6A97:
	and 0f0h		;6a97   ; el nibble alto
	cp 020h		;6a99   ; el 0x2n cambia la duracion de base
	ld a,(hl)			;6a9b
	jr nz,L_6AA5		;6a9c
	and 00fh		;6a9e   ; la nueva duracion
	ld (ix+001h),a		;6aa0   ; en +1
L_6AA3:
	inc hl			;6aa3   ; y sigue el byte de despues
	ld a,(hl)			;6aa4
L_6AA5:
	ld b,a			;6aa5   ; el byte, guardado
	and 0f0h		;6aa6   ; el nibble alto
	cp 010h		;6aa8   ; 0x1n: el ruido
	jr nz,L_6ABD		;6aaa
	ld a,(hl)			;6aac   ; su periodo
	and 00fh		;6aad
	add a,a			;6aaf   ; por dos
	ld e,a			;6ab0
	ld a,006h		;6ab1   ; el registro 6 del PSG es el periodo del ruido
	call 00093h		;6ab3   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;6ab6   ; encender
	call enciende_o_apaga_el_ruido		;6ab8   ; y la voz entra en el mezclador
	inc hl			;6abb
	ld a,(hl)			;6abc   ; y sigue el byte de despues
L_6ABD:
	or a			;6abd   ; el cero es un silencio
	jr nz,L_6AC5		;6abe
	ld b,a			;6ac0   ; todo a cero
	ld d,a			;6ac1
	ld e,a			;6ac2
	jr L_6ACC		;6ac3
L_6AC5:
	and 0f0h		;6ac5   ; el nibble alto es el semitono
	ld b,a			;6ac7
	xor (hl)			;6ac8   ; lo que queda es el desplazamiento
	ld d,a			;6ac9
	inc hl			;6aca
	ld e,(hl)			;6acb   ; y detras va el segundo byte de la nota
L_6ACC:
	call avanza_el_guion		;6acc   ; el guion avanza
	ex de,hl			;6acf
	call pon_el_periodo		;6ad0   ; se escribe el periodo en el PSG
	ld a,b			;6ad3   ; el nibble alto de la nota
	rrca			;6ad4   ; el nibble bajo, bajado
	rrca			;6ad5
	rrca			;6ad6
	rrca			;6ad7
	dec (ix+00bh)		;6ad8   ; lo que queda de ataque
	jr nz,arranca_la_nota		;6adb
	add a,010h		;6add   ; al acabarlo, 0x10 mas de volumen
	ld h,a			;6adf
	jr escribe_el_volumen		;6ae0
arranca_la_nota:
	ld h,a			;6ae2   ; el volumen, sin mas
	ld a,(ix+001h)		;6ae3   ; la duracion de base
	ld (ix+000h),a		;6ae6
	add a,003h		;6ae9   ; y tres mas para la bajada
	ld (ix+008h),a		;6aeb
	jp escribe_el_volumen		;6aee
calla_la_voz:
	ld d,001h		;6af1   ; apagar el ruido
	call enciende_o_apaga_el_ruido		;6af3
	xor a			;6af6   ; y a cero todo
	ld (ix+002h),a		;6af7   ; el estado, a cero
	ld (ix+00bh),a		;6afa   ; y las dos cuentas tambien
	ld (ix+00ch),a		;6afd
	ld h,a			;6b00   ; volumen cero
	jr escribe_el_volumen		;6b01
envolvente:
	dec (ix+000h)		;6b03   ; la nota se acaba
	jp z,paso_del_guion		;6b06   ; al llegar a cero, el guion sigue
	dec (ix+008h)		;6b09   ; el volumen baja
	ld a,(ix+008h)		;6b0c
	cp (ix+000h)		;6b0f   ; hasta el sostenido
	jr nz,L_6B19		;6b12
	cp 003h		;6b14   ; por debajo de 3 ya no
	jr c,L_6B1C		;6b16
	ret			;6b18
L_6B19:
	dec (ix+008h)		;6b19   ; uno mas, que va al doble
L_6B1C:
	ld a,(ix+007h)		;6b1c   ; el volumen de ahora
	dec a			;6b1f   ; uno menos cada vez
	ret m			;6b20   ; y por debajo de cero, nada
	ld (ix+007h),a		;6b21
	ld h,a			;6b24
escribe_el_volumen:
	ld a,c			;6b25   ; c es 1, 3 o 5
	rrca			;6b26   ; una rotacion y sumar 0x88 los convierte en los registros 8, 9 y 10, que son los tres volumenes: un truco para no llevar tabla
	add a,088h		;6b27
	ld e,h			;6b29   ; el volumen, en E
	jp 00093h		;6b2a   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Las ordenes largas, todas con el bit 7 puesto y encadenables: 0xDn el
; paso del volumen, 0xFn el sostenido, 0xEn la octava o el desafine, y
; detras las veces que se suma el paso.
; ----------------------------------------------------------------------
orden_larga:
	ld a,(hl)			;6b2d   ; el byte
	and 0f0h		;6b2e   ; el nibble alto
	cp 0d0h		;6b30   ; 0xDn fija el paso del volumen
	ld a,(hl)			;6b32
	jr nz,L_6B3C		;6b33
	and 00fh		;6b35
	ld (ix+00ah),a		;6b37   ; en +0x0A
	inc hl			;6b3a
	ld a,(hl)			;6b3b   ; y sigue
L_6B3C:
	cp 0f0h		;6b3c   ; 0xFn, el sostenido
	jr c,L_6B47		;6b3e
	and 00fh		;6b40
	ld (ix+006h),a		;6b42   ; en +6
	inc hl			;6b45
	ld a,(hl)			;6b46
L_6B47:
	cp 0e0h		;6b47   ; 0xEn
	jr c,L_6B5C		;6b49
	and 00fh		;6b4b
	bit 3,a		;6b4d   ; con el bit 3, el desafine...
	jr z,L_6B57		;6b4f
	ld (ix+00ch),a		;6b51   ; ...en +0x0C, y se vuelve a mirar
	inc hl			;6b54
	jr orden_larga		;6b55
L_6B57:
	ld (ix+005h),a		;6b57   ; y sin el, la octava
	inc hl			;6b5a
	ld a,(hl)			;6b5b
L_6B5C:
	and 00fh		;6b5c   ; y lo que queda es cuantas veces se suma el paso del volumen
	ld b,a			;6b5e
	ld a,(ix+00ah)		;6b5f   ; el paso
	jr z,L_6B69		;6b62   ; ninguna vez, el paso tal cual
L_6B64:
	add a,(ix+00ah)		;6b64   ; de ahi sale el volumen de arranque
	djnz L_6B64		;6b67
L_6B69:
	ld (ix+001h),a		;6b69   ; en +1
	ld a,(hl)			;6b6c   ; y detras, ya, la nota
	call avanza_el_guion		;6b6d   ; el guion avanza
	and 0f0h		;6b70   ; el nibble alto: el semitono
	rrca			;6b72
	rrca			;6b73
	rrca			;6b74
	rrca			;6b75
	ld b,a			;6b76   ; guardado
	sub 00ch		;6b77   ; el semitono 0x0C deja el volumen a cero: es el silencio
	jr z,L_6B7E		;6b79
	ld a,(ix+006h)		;6b7b   ; y si no, el sostenido
L_6B7E:
	ld (ix+007h),a		;6b7e   ; el volumen de arranque
	call arranca_la_nota		;6b81   ; y a sonar
	ld a,b			;6b84   ; el semitono
	ld hl,06bb2h		;6b85   ; la tabla de periodos de 0x6BB2
	call suma_a_hl		;6b88
	ld l,(hl)			;6b8b   ; el periodo de esa nota, en la octava mas alta
	ld h,000h		;6b8c
	ld a,(ix+005h)		;6b8e   ; y la octava
	or a			;6b91
	jr z,pon_el_periodo		;6b92
	ld b,a			;6b94
L_6B95:
	add hl,hl			;6b95   ; doblar el periodo es bajar una octava exacta
	djnz L_6B95		;6b96
pon_el_periodo:
	ld a,(ix+00ch)		;6b98   ; el desafine
	or a			;6b9b
	jr z,escribe_las_dos_mitades_del_tono		;6b9c
	inc hl			;6b9e   ; con esto se le suma uno, para desafinar a proposito
escribe_las_dos_mitades_del_tono:
	ld a,c			;6b9f   ; c es el registro alto del periodo
	ld e,h			;6ba0
	call 00093h		;6ba1   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;6ba4   ; el mismo registro
	dec a			;6ba5   ; y c-1 el bajo
	ld e,l			;6ba6
	jp 00093h		;6ba7   ; BIOS WRTPSG - Writes data to PSG-register
avanza_el_guion:
	inc hl			;6baa   ; el guion avanza un byte
	ld (ix+003h),l		;6bab   ; y queda apuntado
	ld (ix+004h),h		;6bae
	ret			;6bb1

; ----------------------------------------------------------------------
; DATOS periodos_de_los_semitonos: Diez bytes que 0x6B85 indexa y 0x6B95
;   desplaza para subir de octava. Son semitonos consecutivos, y se comprueba
;   solo: 0x6B/0x40 = 1,672, que es 1,0595 elevado a NUEVE
;   0x6bb2..0x6bbc  (10 bytes)
DATA_periodos_de_los_semitonos:
	defb 06bh,065h,05fh,05ah,055h,050h,04ch,047h,043h,040h	; 6bb2  ke_ZUPLGC@

; ----------------------------------------------------------------------
; DATOS punteros_de_los_sonidos: Cuarenta y seis punteros, indexados por
;   0x69A2 con el numero de sonido por dos. La tabla la cierra su entrada mas
;   baja, 0x6C18, que es el primer guion. Ocho entradas apuntan al mismo
;   0x6F58, el guion de un solo byte
;   0x6bbc..0x6c18  (92 bytes)
DATA_punteros_de_los_sonidos:
	defw 0393ch,06c18h,06c2fh,06c49h,06c5fh,06c74h,06c8ah,06c9fh	; 6bbc
	defw 06f58h,06ca8h,06f58h,06cb1h,06f58h,06cbah,06cc2h,06ccbh	; 6bcc
	defw 06cceh,06cd7h,06cdfh,06ce8h,06d27h,06d56h,06d72h,06d9ah	; 6bdc
	defw 06dc2h,06dd7h,06f58h,06f58h,06de6h,06e00h,06f58h,06e28h	; 6bec
	defw 06e30h,06e38h,06e40h,06e55h,06e6eh,06e85h,06ea5h,06ec6h	; 6bfc
	defw 06efeh,06f19h,06f32h,06f58h,06f58h,06f58h	; 6c0c

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6C18: 23 bytes; lo nombran 1 entradas de la tabla
;   0x6c18..0x6c2f  (23 bytes)
DATA_guion_de_sonido_6C18:
	defb 0a2h,050h,0b1h,05ch,023h,0c1h,02ah,022h,000h,021h,0b1h,030h,0c1h,055h,0c1h,07ah	; 6c18  .P.\#.*".!.0.U.z
	defb 0b1h,0b0h,0feh,002h,018h,06ch,0ffh	; 6c28

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6C2F: 26 bytes; lo nombran 1 entradas de la tabla
;   0x6c2f..0x6c49  (26 bytes)
DATA_guion_de_sonido_6C2F:
	defb 091h,050h,0d1h,030h,0c1h,035h,027h,000h,021h,0a1h,040h,0e1h,050h,0c1h,070h,0b1h	; 6c2f  .P.0.5'.!.@.P.p.
	defb 090h,0b1h,0c0h,021h,000h,0feh,002h,02fh,06ch,0ffh	; 6c3f  ...!.../l.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6C49: 22 bytes; lo nombran 1 entradas de la tabla
;   0x6c49..0x6c5f  (22 bytes)
DATA_guion_de_sonido_6C49:
	defb 092h,070h,0b2h,000h,0c1h,0a0h,02ah,000h,021h,093h,000h,0b3h,020h,0a3h,050h,093h	; 6c49  .p....*.!... .P.
	defb 080h,093h,0c0h,023h,000h,0ffh	; 6c59

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6C5F: 21 bytes; lo nombran 1 entradas de la tabla
;   0x6c5f..0x6c74  (21 bytes)
DATA_guion_de_sonido_6C5F:
	defb 091h,0d0h,0d1h,050h,0c1h,055h,0c1h,056h,0b1h,060h,0b1h,070h,0b1h,080h,0b1h,090h	; 6c5f  ...P.U.V.`.p....
	defb 0b1h,0a0h,0a1h,0b0h,0ffh	; 6c6f

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6C74: 22 bytes; lo nombran 1 entradas de la tabla
;   0x6c74..0x6c8a  (22 bytes)
DATA_guion_de_sonido_6C74:
	defb 091h,0c0h,0c1h,0a0h,022h,000h,021h,0d1h,050h,0c1h,055h,0c1h,060h,0c1h,070h,0b1h	; 6c74  ....".!.P.U.`.p.
	defb 080h,0b1h,090h,0b1h,0a0h,0ffh	; 6c84

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6C8A: 21 bytes; lo nombran 1 entradas de la tabla
;   0x6c8a..0x6c9f  (21 bytes)
DATA_guion_de_sonido_6C8A:
	defb 0a1h,040h,0b1h,005h,0e1h,005h,0d1h,015h,0c1h,025h,0c1h,035h,0b1h,045h,0b1h,055h	; 6c8a  .@.......%.5.E.U
	defb 0a1h,070h,091h,090h,0ffh	; 6c9a

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6C9F: 9 bytes; lo nombran 1 entradas de la tabla
;   0x6c9f..0x6ca8  (9 bytes)
DATA_guion_de_sonido_6C9F:
	defb 020h,001h,035h,007h,003h,01ah,0f0h,005h,0ffh	; 6c9f   .5......

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CA8: 9 bytes; lo nombran 1 entradas de la tabla
;   0x6ca8..0x6cb1  (9 bytes)
DATA_guion_de_sonido_6CA8:
	defb 020h,001h,0bbh,007h,004h,014h,0f0h,005h,0ffh	; 6ca8   ........

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CB1: 9 bytes; lo nombran 1 entradas de la tabla
;   0x6cb1..0x6cba  (9 bytes)
DATA_guion_de_sonido_6CB1:
	defb 020h,001h,000h,009h,001h,012h,0d2h,080h,0ffh	; 6cb1   ........

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CBA: 8 bytes; lo nombran 1 entradas de la tabla
;   0x6cba..0x6cc2  (8 bytes)
DATA_guion_de_sonido_6CBA:
	defb 020h,001h,0eeh,009h,001h,0f2h,0e8h,0ffh	; 6cba   .......

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CC2: 9 bytes; lo nombran 1 entradas de la tabla
;   0x6cc2..0x6ccb  (9 bytes)
DATA_guion_de_sonido_6CC2:
	defb 020h,001h,0eeh,009h,001h,01fh,0f2h,055h,0ffh	; 6cc2   ......U.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CCB: 3 bytes; lo nombran 1 entradas de la tabla
;   0x6ccb..0x6cce  (3 bytes)
DATA_guion_de_sonido_6CCB:
	defb 0f2h,000h,0ffh	; 6ccb

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CCE: 9 bytes; lo nombran 1 entradas de la tabla
;   0x6cce..0x6cd7  (9 bytes)
DATA_guion_de_sonido_6CCE:
	defb 020h,004h,0b8h,009h,005h,01fh,0f4h,0eeh,0ffh	; 6cce   ........

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CD7: 8 bytes; lo nombran 1 entradas de la tabla
;   0x6cd7..0x6cdf  (8 bytes)
DATA_guion_de_sonido_6CD7:
	defb 01fh,0f2h,0e8h,0c2h,033h,0a1h,0e8h,0ffh	; 6cd7  ....3...

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CDF: 9 bytes; lo nombran 1 entradas de la tabla
;   0x6cdf..0x6ce8  (9 bytes)
DATA_guion_de_sonido_6CDF:
	defb 020h,002h,0ffh,009h,003h,01fh,0f2h,055h,0ffh	; 6cdf   ......U.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6CE8: 63 bytes; lo nombran 1 entradas de la tabla
;   0x6ce8..0x6d27  (63 bytes)
DATA_guion_de_sonido_6CE8:
	defb 022h,01fh,0a0h,02ah,0a0h,028h,0a0h,026h,0a0h,024h,0a0h,022h,0a0h,020h,0a0h,000h	; 6ce8  "..*.(.&.$.". ..
	defb 0a0h,020h,0a0h,022h,0a0h,024h,0a0h,026h,0a0h,029h,0a0h,02ch,0a0h,024h,0a0h,022h	; 6cf8  . .".$.&.).,.$."
	defb 0a0h,020h,0a0h,01eh,0a0h,01ch,0a0h,000h,0feh,002h,0f8h,06ch,0a0h,03dh,0a0h,03bh	; 6d08  . .........l.=.;
	defb 0a0h,039h,0a0h,037h,0a0h,035h,0a0h,033h,0a0h,031h,0feh,0ffh,0e8h,06ch,0ffh	; 6d18  .9.7.5.3.1...l.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6D27: 47 bytes; lo nombran 1 entradas de la tabla
;   0x6d27..0x6d56  (47 bytes)
DATA_guion_de_sonido_6D27:
	defb 022h,01fh,090h,05ah,090h,058h,090h,055h,090h,053h,02fh,090h,050h,090h,050h,090h	; 6d27  "..Z.X.U.S/.P.P.
	defb 050h,022h,090h,053h,090h,056h,090h,071h,090h,06dh,090h,06ah,02fh,090h,065h,090h	; 6d37  P".S.V.q.m.j/.e.
	defb 065h,090h,065h,022h,090h,069h,090h,06eh,090h,074h,0feh,0ffh,027h,06dh,0ffh	; 6d47  e.e".i.n.t..'m.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6D56: 28 bytes; lo nombran 1 entradas de la tabla
;   0x6d56..0x6d72  (28 bytes)
DATA_guion_de_sonido_6D56:
	defb 023h,01fh,080h,000h,02dh,0c0h,000h,0b0h,000h,023h,0a0h,000h,080h,000h,060h,000h	; 6d56  #...-....#....`.
	defb 0feh,003h,056h,06dh,02fh,000h,000h,0feh,0ffh,056h,06dh,0ffh	; 6d66  ..Vm/....Vm.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6D72: 40 bytes; lo nombran 1 entradas de la tabla
;   0x6d72..0x6d9a  (40 bytes)
DATA_guion_de_sonido_6D72:
	defb 02fh,01fh,090h,030h,021h,090h,031h,090h,032h,090h,033h,090h,034h,090h,035h,090h	; 6d72  /..0!.1.2.3.4.5.
	defb 036h,02fh,080h,054h,021h,080h,052h,080h,051h,080h,050h,070h,04fh,070h,04eh,070h	; 6d82  6/.T!.R.Q.PpOpNp
	defb 04dh,070h,04ch,060h,04bh,050h,04ah,0ffh	; 6d92  MpL`KPJ.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6D9A: 40 bytes; lo nombran 1 entradas de la tabla
;   0x6d9a..0x6dc2  (40 bytes)
DATA_guion_de_sonido_6D9A:
	defb 025h,01fh,0b0h,000h,022h,090h,020h,090h,022h,090h,024h,090h,025h,090h,026h,0feh	; 6d9a  %...". .".$.%.&.
	defb 002h,09ah,06dh,080h,020h,080h,022h,080h,024h,080h,025h,070h,026h,070h,020h,060h	; 6daa  ..m. .".$.%p&p `
	defb 022h,060h,024h,050h,025h,050h,026h,0ffh	; 6dba  "`$P%P&.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6DC2: 21 bytes; lo nombran 1 entradas de la tabla
;   0x6dc2..0x6dd7  (21 bytes)
DATA_guion_de_sonido_6DC2:
	defb 029h,000h,000h,000h,026h,01fh,080h,000h,090h,000h,080h,000h,070h,000h,060h,000h	; 6dc2  )...&.......p.`.
	defb 050h,000h,040h,000h,0ffh	; 6dd2

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6DD7: 15 bytes; lo nombran 1 entradas de la tabla
;   0x6dd7..0x6de6  (15 bytes)
DATA_guion_de_sonido_6DD7:
	defb 022h,0a0h,040h,02eh,000h,022h,0a0h,050h,02eh,000h,0feh,0ffh,0d7h,06dh,0ffh	; 6dd7  ".@..".P.....m.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6DE6: 26 bytes; lo nombran 1 entradas de la tabla
;   0x6de6..0x6e00  (26 bytes)
DATA_guion_de_sonido_6DE6:
	defb 021h,01fh,0b1h,050h,0a0h,0abh,0feh,007h,0e6h,06dh,0a1h,07ch,000h,0feh,007h,0f0h	; 6de6  !..P.....m.|....
	defb 06dh,0a1h,083h,0a1h,0a3h,091h,0c3h,081h,0f3h,0ffh	; 6df6  m.........

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E00: 40 bytes; lo nombran 1 entradas de la tabla
;   0x6e00..0x6e28  (40 bytes)
DATA_guion_de_sonido_6E00:
	defb 02fh,090h,0bbh,021h,0a1h,07ah,000h,0feh,005h,003h,06eh,0a1h,08ah,0a1h,0a0h,0a1h	; 6e00  /..!.z....n.....
	defb 0c0h,0a1h,0f0h,0a2h,000h,0a2h,010h,0a2h,020h,0a2h,030h,0a2h,055h,0a2h,045h,0a2h	; 6e10  ........ .0.U.E.
	defb 035h,0a2h,025h,0a2h,010h,0a1h,0f5h,0ffh	; 6e20  5.%.....

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E28: 8 bytes; lo nombran 1 entradas de la tabla
;   0x6e28..0x6e30  (8 bytes)
DATA_guion_de_sonido_6E28:
	defb 020h,013h,000h,009h,035h,0f0h,01dh,0ffh	; 6e28   ...5...

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E30: 8 bytes; lo nombran 1 entradas de la tabla
;   0x6e30..0x6e38  (8 bytes)
DATA_guion_de_sonido_6E30:
	defb 020h,018h,000h,009h,035h,0f0h,030h,0ffh	; 6e30   ...5.0.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E38: 8 bytes; lo nombran 1 entradas de la tabla
;   0x6e38..0x6e40  (8 bytes)
DATA_guion_de_sonido_6E38:
	defb 020h,01ah,000h,009h,035h,0f0h,050h,0ffh	; 6e38   ...5.P.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E40: 21 bytes; lo nombran 1 entradas de la tabla
;   0x6e40..0x6e55  (21 bytes)
DATA_guion_de_sonido_6E40:
	defb 0d7h,0fdh,0e2h,000h,0c0h,000h,052h,090h,070h,050h,0fch,0e1h,00fh,0c2h,0d8h,020h	; 6e40  ......R.pP..... 
	defb 0c0h,020h,047h,0c2h,0ffh	; 6e50

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E55: 25 bytes; lo nombran 1 entradas de la tabla
;   0x6e55..0x6e6e  (25 bytes)
DATA_guion_de_sonido_6E55:
	defb 0d7h,0fbh,0e3h,070h,0c0h,070h,0e2h,002h,050h,000h,000h,0fdh,052h,090h,070h,050h	; 6e55  ...p.p..P...R.pP
	defb 079h,0c2h,0d8h,090h,0c0h,090h,0b7h,0c2h,0ffh	; 6e65  y........

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E6E: 23 bytes; lo nombran 1 entradas de la tabla
;   0x6e6e..0x6e85  (23 bytes)
DATA_guion_de_sonido_6E6E:
	defb 0d7h,0fdh,0e3h,000h,0c0h,000h,002h,000h,000h,000h,00fh,0c2h,0d4h,0fch,091h,090h	; 6e6e  ................
	defb 090h,090h,0c0h,0d8h,087h,0c2h,0ffh	; 6e7e

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6E85: 32 bytes; lo nombran 1 entradas de la tabla
;   0x6e85..0x6ea5  (32 bytes)
DATA_guion_de_sonido_6E85:
	defb 0e8h,0d6h,0fch,0e1h,080h,040h,0e2h,0b0h,080h,0e1h,080h,040h,080h,040h,0e2h,0b0h	; 6e85  .....@.....@.@..
	defb 080h,0e1h,0b0h,080h,0feh,002h,089h,06eh,002h,000h,001h,021h,021h,021h,08ch,0ffh	; 6e95  .......n...!!!..

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6EA5: 33 bytes; lo nombran 1 entradas de la tabla
;   0x6ea5..0x6ec6  (33 bytes)
DATA_guion_de_sonido_6EA5:
	defb 0d6h,0fbh,0e1h,0c0h,080h,040h,0e2h,0b0h,080h,0e1h,080h,040h,080h,040h,0e2h,0b0h	; 6ea5  .....@.....@.@..
	defb 080h,0e1h,0b0h,080h,0feh,002h,0a9h,06eh,041h,040h,041h,061h,061h,061h,0e2h,0bch	; 6eb5  .......nA@Aaaa..
	defb 0ffh	; 6ec5

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6EC6: 56 bytes; lo nombran 1 entradas de la tabla
;   0x6ec6..0x6efe  (56 bytes)
DATA_guion_de_sonido_6EC6:
	defb 0d6h,0fch,0e2h,042h,040h,041h,0e3h,0b1h,0b1h,0b1h,082h,080h,081h,041h,043h,002h	; 6ec6  ...B@A.......AC.
	defb 000h,001h,021h,021h,021h,0d2h,0fbh,0e4h,040h,050h,060h,070h,080h,090h,0a0h,0b0h	; 6ed6  ..!!!...@P`p....
	defb 0d1h,0e3h,001h,010h,021h,030h,041h,0fah,050h,061h,070h,081h,090h,0a1h,0b0h,0e2h	; 6ee6  ....!0A.Pap.....
	defb 001h,010h,021h,030h,0d4h,0fch,048h,0ffh	; 6ef6  ..!0..H.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6EFE: 27 bytes; lo nombran 1 entradas de la tabla
;   0x6efe..0x6f19  (27 bytes)
DATA_guion_de_sonido_6EFE:
	defb 0d7h,0fch,0e2h,041h,051h,071h,0c0h,0e1h,000h,007h,0e2h,041h,051h,071h,0c0h,0e1h	; 6efe  ...AQq.....AQq..
	defb 000h,005h,000h,000h,0d5h,041h,021h,0d6h,001h,07ah,0ffh	; 6f0e  .....A!..z.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6F19: 25 bytes; lo nombran 1 entradas de la tabla
;   0x6f19..0x6f32  (25 bytes)
DATA_guion_de_sonido_6F19:
	defb 0d7h,0fbh,0e1h,041h,051h,041h,0c0h,070h,077h,041h,051h,0e2h,0a1h,0c0h,040h,045h	; 6f19  ...AQA.pwAQ...@E
	defb 000h,000h,0d5h,041h,021h,0d6h,001h,07ah,0ffh	; 6f29  ...A!..z.

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6F32: 38 bytes; lo nombran 1 entradas de la tabla
;   0x6f32..0x6f58  (38 bytes)
DATA_guion_de_sonido_6F32:
	defb 0d7h,0fch,0e3h,0c3h,001h,0e2h,001h,0e3h,001h,0e2h,001h,0e3h,001h,0e2h,001h,0e3h	; 6f32  ................
	defb 001h,0e2h,001h,0e4h,0a1h,0e3h,0a1h,0e4h,0a1h,0e3h,0a1h,0e4h,0a1h,0e3h,0a1h,0d8h	; 6f42  ................
	defb 0e4h,0a1h,0e3h,0a1h,007h,0ffh	; 6f52

; ----------------------------------------------------------------------
; DATOS guion_de_sonido_6F58: 1 bytes; lo nombran 9 entradas de la tabla
;   0x6f58..0x6f59  (1 bytes)
DATA_guion_de_sonido_6F58:
	defb 0ffh	; 6f58

; ======================================================================
; CODIGO 0x6f59..0x7011  (184 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ======================================================================
; LA ENTRADA AL CUADRILATERO
; ======================================================================
; (0xE112) es la columna, que sube de dos en dos, y (0xE110) las vueltas
; dadas. Los sprites se montan en 0xE114 y se vuelcan de golpe a 0x3B50,
; que es el sprite 20; los que no se usan se aparcan en la fila 0xCF.
; ----------------------------------------------------------------------
anda_hacia_el_cuadrilatero:
	ld hl,0e111h		;6f59   ; (0xE111), la espera
	ld a,(hl)			;6f5c
	or a			;6f5d   ; ya a cero?
	jr z,L_6F62		;6f5e
	dec (hl)			;6f60   ; mientras corra, quieto
	ret			;6f61
L_6F62:
	inc hl			;6f62   ; (0xE112), la columna
	inc (hl)			;6f63   ; dos pixeles...
	inc (hl)			;6f64
	ld a,(hl)			;6f65   ; la columna
	cp 072h		;6f66   ; ...hasta la 0x72
	jr nz,L_6F8B		;6f68
	dec hl			;6f6a   ; (0xE110), las vueltas
	dec hl			;6f6b
	inc (hl)			;6f6c   ; una mas
	ld a,(hl)			;6f6d
	cp 004h		;6f6e   ; a la cuarta ya no se para
	inc hl			;6f70
	inc hl			;6f71
	jr z,L_6F8B		;6f72
	dec (hl)			;6f74   ; y si no, se vuelve dos pixeles
	dec (hl)			;6f75
	ld c,000h		;6f76   ; el primer guion
	ld d,018h		;6f78   ; 24 cuadros de espera
	rrca			;6f7a   ; las vueltas impares...
	jr nc,L_6F86		;6f7b
	ld c,002h		;6f7d   ; ...van con el segundo guion
	ld d,030h		;6f7f   ; y 48 de espera
	ld a,05ch		;6f81   ; con el sonido 0x5C
	call pide_un_sonido		;6f83
L_6F86:
	ld a,c			;6f86   ; el guion que toca
	dec hl			;6f87   ; la espera
	ld (hl),d			;6f88
	jr L_6FB6		;6f89
L_6F8B:
	cp 0e0h		;6f8b   ; la columna 0xE0 es el final
	jr nz,L_6FA4		;6f8d
	ld (0e27fh),a		;6f8f   ; se apunta en (0xE27F)
	ld a,02bh		;6f92   ; el sonido 0x2B, el silencio
	call pide_un_sonido		;6f94
	xor a			;6f97   ; la columna...
	ld (hl),a			;6f98
	dec hl			;6f99
	dec hl			;6f9a
	ld (hl),a			;6f9b   ; ...y las vueltas, a cero
	inc a			;6f9c   ; y el paso 1 en (0xE1FF)
	ld (0e1ffh),a		;6f9d
	ld a,003h		;6fa0   ; el guion 3
	jr L_6FB6		;6fa2
L_6FA4:
	ld a,(0e313h)		;6fa4   ; el sonido que suena
	cp 019h		;6fa7   ; el 0x19 ya esta puesto
	jr z,L_6FB0		;6fa9
	ld a,019h		;6fab   ; y si no, se pide
	call pide_un_sonido		;6fad
L_6FB0:
	xor a			;6fb0   ; el guion 0...
	bit 4,(hl)		;6fb1   ; el bit 4 de la columna alterna los dos guiones del paso
	jr z,L_6FB6		;6fb3
	inc a			;6fb5
L_6FB6:
	ld hl,07013h		;6fb6   ; la tabla de guiones de 0x7013
	inc a			;6fb9   ; el que toca...
L_6FBA:
	inc hl			;6fba   ; ...contado de dos en dos
	inc hl			;6fbb
	dec a			;6fbc
	jr nz,L_6FBA		;6fbd
	call saca_la_palabra		;6fbf   ; y su direccion
	ld de,0e114h		;6fc2   ; los registros de sprite, en 0xE114
	push de			;6fc5
	push de			;6fc6
	ld b,016h		;6fc7   ; veintidos bytes
	ld a,0cfh		;6fc9   ; a la fila 0xCF, o sea aparcados
L_6FCB:
	ld (de),a			;6fcb
	inc de			;6fcc
	djnz L_6FCB		;6fcd
	pop de			;6fcf
	ld a,(0e112h)		;6fd0   ; la columna de ahora
	ld c,a			;6fd3
L_6FD4:
	ld a,(hl)			;6fd4   ; el guion
	inc a			;6fd5   ; el 0xFF acaba
	jr z,L_6FED		;6fd6
	dec a			;6fd8
	add a,078h		;6fd9   ; la fila, con 0x78 de margen
	ld (de),a			;6fdb
	inc de			;6fdc
	inc hl			;6fdd
	ld a,(hl)			;6fde   ; la columna del guion...
	add a,c			;6fdf   ; ...mas la de ahora
	ld (de),a			;6fe0
	inc hl			;6fe1
	inc de			;6fe2
	ld a,(hl)			;6fe3   ; el patron
	ld (de),a			;6fe4
	inc hl			;6fe5
	inc de			;6fe6
	ld a,(hl)			;6fe7   ; y el color
	ld (de),a			;6fe8
	inc hl			;6fe9
	inc de			;6fea
	jr L_6FD4		;6feb
L_6FED:
	pop de			;6fed   ; los registros montados
	ld hl,07b50h		;6fee   ; la tabla de sprites, sprite 20
	ld bc,00016h		;6ff1   ; veintidos bytes
L_6FF4:
	jp vuelca_en_la_vram		;6ff4
pinta_la_marca_del_asalto:
	ld a,(0e110h)		;6ff7   ; (0xE110)
	rrca			;6ffa   ; su bit 0
	ret nc			;6ffb
	ld a,(0e210h)		;6ffc   ; (0xE210), el asalto
	ld b,a			;6fff
	dec b			;7000   ; contado desde cero
	ld a,b			;7001
	add a,a			;7002   ; palabras
	ld de,07011h		;7003   ; las dos parejas de 0x7011
	call suma_a_de		;7006
	ld bc,00002h		;7009   ; dos casillas
	ld hl,079d1h		;700c   ; fila 14, columna 17
	jr L_6FF4		;700f

; ----------------------------------------------------------------------
; DATOS casillas_de_la_marca_del_asalto: Las dos casillas que 0x6FF7 pone en
;   la fila 14 columna 17, una pareja por asalto menos uno, y 0x7066 vuelca en
;   0x39D1
;   0x7011..0x7015  (4 bytes)
DATA_casillas_de_la_marca_del_asalto:
	defb 0fah,0fch	; 7011
	defb 0fbh,0fch	; 7013

; ----------------------------------------------------------------------
; DATOS punteros_de_los_guiones_de_entrada: Cuatro punteros: 0x701D, 0x702A,
;   0x7037 y 0x704B. 0x6FB6 los indexa partiendo de 0x7013, o sea que la
;   entrada 0 es la de 0x7015
;   0x7015..0x701d  (8 bytes)
DATA_punteros_de_los_guiones_de_entrada:
	defw 0701dh,0702ah,07037h,0704bh	; 7015  -> DATA_guion_de_piezas_1 DATA_guion_de_piezas_2 DATA_guion_de_piezas_3 DATA_guion_de_piezas_vacio

; ----------------------------------------------------------------------
; DATOS guion_de_piezas_1: Trece bytes de ternas que 0x6FD4 pasa a 0xE114,
;   sumando 0x78 a la primera y (0xE112) a la segunda; el 0xFF acaba
;   0x701d..0x702a  (13 bytes)
DATA_guion_de_piezas_1:
	defb 000h,000h,080h,004h,005h,006h,084h,001h,000h,000h,088h,008h,0ffh	; 701d  .............

; ----------------------------------------------------------------------
; DATOS guion_de_piezas_2: Otros trece bytes con el mismo formato: fila,
;   columna, patron y color por sprite, y 0xFF al final
;   0x702a..0x7037  (13 bytes)
DATA_guion_de_piezas_2:
	defb 000h,000h,08ch,004h,004h,006h,090h,001h,000h,001h,088h,008h,0ffh	; 702a  .............

; ----------------------------------------------------------------------
; DATOS guion_de_piezas_3: Veinte bytes, o sea cinco sprites: el guion mas
;   largo de los cuatro
;   0x7037..0x704b  (20 bytes)
DATA_guion_de_piezas_3:
	defb 000h,000h,08ch,004h,004h,006h,090h,001h,000h,001h,088h,008h,0f3h	; 7037  .............
	defb 010h,094h,008h,0f3h,020h,098h,008h	; 7044

; ----------------------------------------------------------------------
; DATOS guion_de_piezas_vacio: Un solo 0xFF: ninguna pieza
;   0x704b..0x704c  (1 bytes)
DATA_guion_de_piezas_vacio:
	defb 0ffh	; 704b

; ======================================================================
; CODIGO 0x704c..0x707e  (50 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ----------------------------------------------------------------------
; Las figurillas de cuatro casillas que marcan el asalto, en tres sitios
; de la fila 18 en adelante. (0xE12B) es el paso.
; ----------------------------------------------------------------------
pinta_las_figurillas:
	ld de,07082h		;704c   ; las cuatro casillas de 0x7082
	ld hl,0e12bh		;704f   ; (0xE12B), el paso
	ld a,(hl)			;7052
	or a			;7053   ; ya a cero?
	ret z			;7054   ; a cero, nada
	inc (hl)			;7055   ; uno mas
	dec a			;7056   ; en el 1 se pintan
	jr z,L_7066		;7057
	cp 004h		;7059   ; y en el 4...
	ret nz			;705b
	ld (hl),000h		;705c   ; ...se acaba
	ld a,01fh		;705e   ; con el sonido 0x1F
	call pide_un_sonido_aunque_sea_la_demo		;7060
	ld de,0707eh		;7063   ; y las otras cuatro casillas
L_7066:
	ld hl,07a51h		;7066   ; fila 18, columna 17
	ld bc,00001h		;7069   ; dos casillas
	xor a			;706c   ; la primera
	call pinta_cuatro_casillas		;706d
	ld a,021h		;7070   ; 0x21 mas alla
	call pinta_cuatro_casillas		;7072
	ld a,020h		;7075   ; y 0x20 mas
pinta_cuatro_casillas:
	call suma_a_hl		;7077   ; donde toca
	inc bc			;707a   ; una casilla mas
	jp vuelca_en_la_vram		;707b

; ----------------------------------------------------------------------
; DATOS dos_figurillas_de_cuatro_casillas: Dos blobs de cuatro casillas que
;   0x7066 pone en 0x3A51 (dos), 0x3A72 (una) y 0x3A92 (una): 0x707E y 0x7082
;   0x707e..0x7086  (8 bytes)
DATA_dos_figurillas_de_cuatro_casillas:
	defb 016h,017h,01ch,01eh	; 707e
	defb 06ah,06bh,06ch,06dh	; 7082

; ----------------------------------------------------------------------
; DATOS punteros_del_archivo_1: Las 19 figuras del archivo 1. La tabla la
;   cierra su entrada mas baja, y los cuatro archivos dan 19 clavadas
;   0x7086..0x70ac  (38 bytes)
DATA_punteros_del_archivo_1:
	defw 0721eh,07382h,070ach,0717ch,074bbh,075a7h,0773fh,07803h	; 7086
	defw 079a8h,07b1bh,07bf2h,07cd1h,07382h,07d81h,0721eh,07ebbh	; 7096
	defw 07ebbh,08078h,08244h	; 70a6  -> DATA_cabecera_de_la_figura_7EBB DATA_guiones_8078 DATA_cabecera_de_la_figura_8244

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_70AC: Archivo 1: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0x70ac..0x70cc  (32 bytes)
DATA_cabecera_de_la_figura_70AC:
	defb 0cch,070h,099h,072h,01bh,071h,014h,073h	; 70ac  .p.r.q.s
	defb 003h,002h,0ebh,001h,009h,0e8h,008h,028h	; 70b4  .......(
	defb 0f0h,00dh,002h,003h,013h,013h,013h,004h	; 70bc  ........
	defb 004h,004h,046h,071h,062h,071h,070h,073h	; 70c4  ..Fqbqps

; ----------------------------------------------------------------------
; DATOS guiones_70CC: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x70cc..0x711b  (79 bytes)
DATA_guiones_70CC:
	defb 088h,0ffh,0ffh,003h,007h,0f0h,0f0h,0e0h,0e0h,083h,0ffh,0ffh,0feh,005h,0ffh,098h	; 70cc  ................
	defb 001h,003h,0f8h,0f9h,0ffh,0ffh,000h,001h,011h,013h,011h,080h,080h,0ffh,0ffh,0f7h	; 70dc  ................
	defb 000h,000h,0ffh,0ffh,07fh,03fh,0e0h,0f8h,082h,0efh,0cfh,005h,0f0h,083h,090h,001h	; 70ec  .....?..........
	defb 03fh,008h,0ffh,083h,07fh,03fh,03fh,003h,01fh,090h,008h,000h,000h,080h,0c0h,0e0h	; 70fc  ?....??.........
	defb 0f8h,0feh,0fbh,0f7h,0efh,0dfh,0bfh,07fh,07fh,0ffh,007h,01fh,081h,03fh,000h	; 710c  .............?.

; ----------------------------------------------------------------------
; DATOS guiones_711B: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x711b..0x7146  (43 bytes)
DATA_guiones_711B:
	defb 002h,0f1h,002h,0b3h,004h,0fbh,002h,0f1h,008h,0b3h,004h,0fbh,002h,0b3h,005h,0fbh	; 711b  ................
	defb 003h,0b8h,002h,0b3h,004h,0fbh,002h,0b3h,002h,0b8h,003h,0fbh,003h,0ebh,081h,0fbh	; 712b  ................
	defb 007h,0b8h,005h,0fbh,00bh,0ebh,008h,0b8h,008h,0ebh,000h	; 713b  ...........

; ----------------------------------------------------------------------
; DATOS guiones_7146: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7146..0x7162  (28 bytes)
DATA_guiones_7146:
	defb 01fh,03fh,07fh,07fh,0fdh,0f9h,0f0h,060h,000h,001h,008h,00ch,000h,005h,0f0h,0f8h	; 7146  .?.....`........
	defb 0fch,0feh,0ceh,08fh,08fh,09fh,08fh,007h,003h,001h,000h,004h	; 7156  ............

; ----------------------------------------------------------------------
; DATOS guiones_7162: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7162..0x717c  (26 bytes)
DATA_guiones_7162:
	defb 000h,003h,03eh,07fh,0ffh,0feh,0bdh,0bdh,0bfh,0dfh,0ffh,07fh,03fh,00fh,00fh,000h	; 7162  ..>.........?...
	defb 007h,080h,080h,081h,081h,002h,082h,0c4h,084h,008h	; 7172  ..........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_717C: Archivo 1: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0x717c..0x719c  (32 bytes)
DATA_cabecera_de_la_figura_717C:
	defb 09ch,071h,0f5h,073h,0edh,071h,07dh,074h	; 717c  .q.s.q}t
	defb 003h,001h,0ebh,001h,008h,0e8h,008h,020h	; 7184  ....... 
	defb 0f2h,00dh,002h,003h,013h,013h,013h,004h	; 718c  ........
	defb 004h,004h,046h,071h,062h,071h,0a4h,074h	; 7194  ..Fqbq.t

; ----------------------------------------------------------------------
; DATOS guiones_719C: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x719c..0x71ed  (81 bytes)
DATA_guiones_719C:
	defb 002h,0ffh,002h,000h,003h,0ffh,089h,0feh,0ffh,0ffh,000h,000h,0ffh,0b9h,031h,011h	; 719c  ..............1.
	defb 098h,003h,007h,0f8h,0feh,0ffh,0ffh,000h,000h,0ech,0eeh,080h,000h,000h,000h,0f7h	; 71ac  ................
	defb 0efh,000h,000h,0ffh,07fh,03fh,01fh,0f8h,0feh,081h,0cfh,005h,0f0h,083h,090h,000h	; 71bc  .....?..........
	defb 03fh,006h,0ffh,085h,0fbh,0ffh,07fh,03fh,03fh,004h,01fh,090h,000h,000h,080h,0c0h	; 71cc  ?......??.......
	defb 0e0h,0f8h,0feh,0feh,0f7h,0efh,0dfh,0bfh,07fh,07fh,0ffh,0ffh,006h,01fh,002h,03fh	; 71dc  ...............?
	defb 000h	; 71ec

; ----------------------------------------------------------------------
; DATOS guiones_71ED: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x71ed..0x721e  (49 bytes)
DATA_guiones_71ED:
	defb 004h,0f3h,004h,0fbh,004h,0f3h,004h,0fbh,002h,0b3h,004h,0fbh,002h,073h,002h,0b3h	; 71ed  .............s..
	defb 004h,0fbh,002h,0b8h,003h,0f3h,003h,0fbh,002h,0b3h,081h,0b8h,004h,0fbh,003h,0ebh	; 71fd  ................
	defb 008h,0b8h,005h,0fbh,00ah,0ebh,081h,0edh,007h,0b8h,081h,0dbh,007h,0ebh,081h,0edh	; 720d  ................
	defb 000h	; 721d

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_721E: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x721e..0x7243  (37 bytes)
DATA_cabecera_de_la_figura_721E:
	defb 043h,072h,0edh,072h,0eeh,072h,034h,073h	; 721e  Cr.r.r4s
	defb 004h,001h,0efh,001h,001h,0efh,00fh,011h	; 7226  ........
	defb 0e8h,008h,028h,0f0h,00dh,003h,003h,013h	; 722e  ..(.....
	defb 013h,013h,004h,004h,004h,035h,073h,051h	; 7236  .....5sQ
	defb 073h,056h,073h,070h,073h	; 723e

; ----------------------------------------------------------------------
; DATOS guiones_7243: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7243..0x72ee  (171 bytes)
DATA_guiones_7243:
	defb 002h,0ffh,002h,000h,004h,0ffh,090h,0ffh,0ffh,000h,000h,0ffh,0fdh,0e1h,080h,0ffh	; 7243  ................
	defb 0ffh,000h,000h,0ffh,0ffh,0ffh,0e7h,002h,000h,004h,0ffh,002h,000h,093h,07fh,03fh	; 7253  ...............?
	defb 080h,080h,0c0h,0f0h,03fh,03fh,038h,0b8h,04fh,04fh,007h,007h,0fch,0fch,0f8h,0fch	; 7263  ....??8.OO......
	defb 0fch,005h,0f8h,086h,001h,0ffh,0e7h,0dfh,0bfh,07fh,004h,0ffh,082h,07fh,03fh,004h	; 7273  ..............?.
	defb 01fh,085h,0f8h,0f8h,0f0h,0f0h,0f8h,003h,0feh,088h,0ffh,0ffh,0fbh,0f7h,0efh,0dfh	; 7283  ................
	defb 03fh,0ffh,007h,01fh,081h,03fh,083h,0feh,0feh,001h,005h,003h,002h,000h,006h,0f3h	; 7293  ?....?..........
	defb 082h,03fh,03fh,006h,0e0h,008h,0ffh,003h,0fch,005h,0f8h,081h,00fh,005h,000h,083h	; 72a3  .??.............
	defb 001h,003h,0e0h,002h,03fh,002h,07fh,003h,0ffh,008h,0ffh,004h,0f8h,084h,0fch,0feh	; 72b3  ....?...........
	defb 0feh,0ffh,003h,0fch,08ah,0f9h,0f9h,007h,007h,0e3h,018h,000h,000h,040h,040h,003h	; 72c3  .............@@.
	defb 0e0h,008h,0ffh,004h,0ffh,094h,0feh,0f8h,0e0h,0e0h,003h,0e3h,083h,083h,001h,001h	; 72d3  ................
	defb 001h,001h,0e1h,0c1h,0c3h,087h,08fh,0ffh,001h,000h,000h	; 72e3  ...........

; ----------------------------------------------------------------------
; DATOS guiones_72EE: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x72ee..0x7335  (71 bytes)
DATA_guiones_72EE:
	defb 008h,0f3h,004h,0f3h,004h,0fbh,004h,0f3h,004h,0fbh,008h,0f3h,002h,0b3h,004h,0fbh	; 72ee  ................
	defb 004h,0b3h,004h,0fbh,002h,0b3h,005h,0fbh,003h,0ebh,081h,0fbh,007h,0b8h,005h,0fbh	; 72fe  ................
	defb 00bh,0ebh,008h,0b8h,008h,0ebh,002h,0edh,006h,0feh,008h,0fdh,002h,0edh,006h,0feh	; 730e  ................
	defb 008h,0eeh,008h,0ebh,006h,0fbh,002h,0ebh,081h,0feh,014h,0ebh,003h,0e5h,005h,0b5h	; 731e  ................
	defb 013h,0e5h,016h,0e5h,002h,0e1h,000h	; 732e

; ----------------------------------------------------------------------
; DATOS guiones_7335: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7335..0x7351  (28 bytes)
DATA_guiones_7335:
	defb 01fh,03fh,07fh,0ffh,0feh,070h,000h,001h,008h,008h,000h,007h,0f8h,0fch,0feh,0ffh	; 7335  .?...p..........
	defb 0ffh,0ffh,073h,063h,023h,027h,027h,003h,003h,001h,000h,002h	; 7345  ..sc#''.....

; ----------------------------------------------------------------------
; DATOS guiones_7351: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7351..0x7356  (5 bytes)
DATA_guiones_7351:
	defb 000h,007h,004h,000h,018h	; 7351

; ----------------------------------------------------------------------
; DATOS guiones_7356: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7356..0x7370  (26 bytes)
DATA_guiones_7356:
	defb 00fh,01fh,037h,02fh,02fh,03fh,03fh,03fh,01fh,00fh,000h,007h,080h,060h,0e0h,0e0h	; 7356  ..7//???.....`..
	defb 0e1h,0feh,0fah,0f8h,0f0h,0f0h,070h,001h,000h,003h	; 7366  ......p...

; ----------------------------------------------------------------------
; DATOS guiones_7370: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7370..0x7382  (18 bytes)
DATA_guiones_7370:
	defb 000h,002h,001h,001h,001h,001h,002h,002h,002h,002h,002h,001h,000h,004h,08ch,080h	; 7370  ................
	defb 000h,00eh	; 7380

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_7382: Archivo 1: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0x7382..0x73a2  (32 bytes)
DATA_cabecera_de_la_figura_7382:
	defb 0a2h,073h,052h,074h,053h,074h,0a3h,074h	; 7382  .sRtSt.t
	defb 003h,000h,0efh,001h,010h,0e8h,008h,020h	; 738a  ....... 
	defb 0f2h,00dh,003h,003h,013h,013h,013h,004h	; 7392  ........
	defb 004h,004h,035h,073h,056h,073h,0a4h,074h	; 739a  ..5sVs.t

; ----------------------------------------------------------------------
; DATOS guiones_73A2: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x73a2..0x7453  (177 bytes)
DATA_guiones_73A2:
	defb 002h,0ffh,002h,000h,004h,0ffh,090h,0ffh,0ffh,000h,000h,0fdh,0e1h,080h,088h,0ffh	; 73a2  ................
	defb 0ffh,000h,000h,0ffh,0ffh,0e7h,0c7h,002h,000h,004h,0ffh,002h,000h,090h,03fh,07fh	; 73b2  ..............?.
	defb 080h,0c0h,0f0h,0c0h,03fh,007h,0b8h,0b0h,04fh,007h,007h,003h,0fch,0feh,002h,0fch	; 73c2  ....?...O.......
	defb 006h,0f8h,085h,0ffh,0e7h,0dfh,0bfh,07fh,004h,0ffh,082h,07fh,03fh,005h,01fh,084h	; 73d2  ............?...
	defb 0f8h,0f0h,0f0h,0f8h,004h,0feh,088h,0ffh,0fbh,0f7h,0efh,0dfh,03fh,0ffh,000h,006h	; 73e2  ............?...
	defb 01fh,002h,03fh,088h,001h,003h,003h,007h,007h,00fh,00fh,0e0h,007h,0ffh,081h,07fh	; 73f2  ..?.............
	defb 002h,0c0h,006h,0e0h,003h,0ffh,081h,0feh,004h,0fch,082h,0c0h,080h,004h,000h,082h	; 7402  ................
	defb 001h,007h,006h,000h,002h,080h,004h,03fh,004h,07fh,081h,0feh,007h,0ffh,090h,003h	; 7412  .......?........
	defb 001h,0e1h,0c1h,0f1h,0e0h,0e0h,0c0h,080h,080h,0c0h,0c0h,0c0h,0e0h,0e0h,07ch,003h	; 7422  ..............|.
	defb 0ffh,005h,07fh,098h,0ffh,0feh,0f8h,0f8h,0ffh,0ffh,0fch,0f8h,080h,000h,003h,00fh	; 7432  ................
	defb 0fch,0c0h,001h,000h,070h,07ch,0f0h,0f0h,0c0h,0ffh,0ffh,000h,003h,03fh,005h,01fh	; 7442  ....p|.......?..
	defb 000h	; 7452

; ----------------------------------------------------------------------
; DATOS guiones_7453: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7453..0x74a4  (81 bytes)
DATA_guiones_7453:
	defb 008h,0f3h,004h,0f3h,004h,0fbh,004h,0f3h,004h,0fbh,008h,0f3h,002h,0b3h,004h,0fbh	; 7453  ................
	defb 004h,0b3h,004h,0fbh,002h,0b3h,005h,0fbh,003h,0ebh,008h,0b8h,005h,0fbh,00ah,0ebh	; 7463  ................
	defb 081h,0edh,007h,0b8h,081h,0edh,007h,0ebh,081h,0edh,007h,0feh,081h,0ebh,007h,0f1h	; 7473  ................
	defb 081h,0fbh,008h,0feh,029h,0ebh,007h,0e5h,005h,0ebh,003h,0e5h,005h,0ebh,007h,0e5h	; 7483  ....)...........
	defb 004h,0e1h,004h,0e5h,002h,0e1h,002h,051h,005h,0e5h,003h,051h,007h,0e5h,081h,0e1h	; 7493  .......Q...Q....
	defb 000h	; 74a3

; ----------------------------------------------------------------------
; DATOS guiones_74A4: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x74a4..0x74bb  (23 bytes)
DATA_guiones_74A4:
	defb 007h,000h,005h,004h,002h,002h,002h,002h,002h,002h,002h,000h,002h,0ffh,030h,030h	; 74a4  ..............00
	defb 030h,030h,030h,030h,030h,000h,008h	; 74b4

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_74BB: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x74bb..0x74e0  (37 bytes)
DATA_cabecera_de_la_figura_74BB:
	defb 0e0h,074h,023h,07ah,02eh,075h,0afh,07ah	; 74bb  .t#z.u.z
	defb 004h,000h,0f9h,001h,010h,0ech,006h,010h	; 74c3  ........
	defb 0f4h,008h,020h,0f1h,00dh,022h,023h,014h	; 74cb  .. .."#.
	defb 014h,003h,003h,004h,004h,05bh,075h,07ch	; 74d3  .....[u|
	defb 075h,08fh,075h,006h,07bh	; 74db

; ----------------------------------------------------------------------
; DATOS guiones_74E0: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x74e0..0x752e  (78 bytes)
DATA_guiones_74E0:
	defb 08bh,0f8h,0e0h,03fh,07fh,080h,080h,0c0h,0c0h,003h,001h,0feh,004h,0ffh,091h,0c0h	; 74e0  ...?............
	defb 01fh,03fh,0c0h,0c7h,0c0h,0e3h,00fh,0e7h,080h,000h,000h,083h,007h,007h,0f0h,0e0h	; 74f0  .?..............
	defb 002h,080h,004h,0ffh,002h,000h,004h,0fch,002h,0f8h,002h,0f0h,008h,0ffh,082h,00fh	; 7500  ................
	defb 001h,005h,000h,089h,0f7h,0ffh,0ffh,0ffh,07fh,03fh,03fh,01fh,00fh,008h,0e0h,008h	; 7510  .........??.....
	defb 0ffh,083h,0f7h,0fbh,0f3h,004h,0ffh,081h,040h,007h,00fh,081h,01fh,000h	; 7520  ........@.....

; ----------------------------------------------------------------------
; DATOS guiones_752E: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x752e..0x755b  (45 bytes)
DATA_guiones_752E:
	defb 002h,0fbh,002h,0b3h,006h,0fbh,005h,0b3h,081h,0fbh,002h,0b3h,004h,0fbh,002h,0b3h	; 752e  ................
	defb 006h,0fbh,004h,0b3h,006h,0f3h,005h,0fbh,003h,0ebh,008h,0b0h,007h,0fbh,081h,0b6h	; 753e  ................
	defb 005h,0fbh,00bh,0ebh,008h,0b0h,003h,0b6h,004h,0b1h,009h,0ebh,000h	; 754e  .............

; ----------------------------------------------------------------------
; DATOS guiones_755B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x755b..0x757c  (33 bytes)
DATA_guiones_755B:
	defb 00fh,03fh,07fh,0ffh,0dfh,0cfh,000h,001h,011h,009h,000h,003h,007h,000h,003h,0f8h	; 755b  .?..............
	defb 0fch,0fch,0feh,0deh,01fh,01fh,009h,009h,009h,000h,001h,006h,00ch,008h,010h,000h	; 756b  ................
	defb 001h	; 757b

; ----------------------------------------------------------------------
; DATOS guiones_757C: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x757c..0x758f  (19 bytes)
DATA_guiones_757C:
	defb 000h,005h,003h,007h,00fh,00eh,00eh,00eh,00eh,006h,000h,004h,010h,020h,000h,002h	; 757c  ............. ..
	defb 080h,000h,00ah	; 758c

; ----------------------------------------------------------------------
; DATOS guiones_758F: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x758f..0x75a7  (24 bytes)
DATA_guiones_758F:
	defb 000h,005h,001h,003h,007h,007h,006h,006h,007h,003h,001h,000h,007h,0f0h,0ech,0fch	; 758f  ................
	defb 0fch,0fch,0feh,07fh,0bfh,0feh,00eh,002h	; 759f  ........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_75A7: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x75a7..0x75cc  (37 bytes)
DATA_cabecera_de_la_figura_75A7:
	defb 0cch,075h,07dh,076h,07eh,076h,0cdh,076h	; 75a7  .u}v~v.v
	defb 004h,000h,0ech,001h,006h,0d8h,008h,010h	; 75af  ........
	defb 0e4h,00bh,030h,000h,005h,011h,003h,004h	; 75b7  ..0.....
	defb 013h,013h,004h,004h,005h,0cdh,076h,0e9h	; 75bf  ......v.
	defb 076h,002h,077h,01fh,077h	; 75c7

; ----------------------------------------------------------------------
; DATOS guiones_75CC: 4 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x75cc..0x767e  (178 bytes)
DATA_guiones_75CC:
	defb 0a0h,0ffh,0ffh,000h,000h,0ffh,0ffh,0efh,000h,003h,003h,0feh,0fch,0fch,0feh,001h	; 75cc  ................
	defb 001h,007h,0c6h,082h,002h,002h,040h,080h,000h,0c0h,0c0h,03fh,07fh,07fh,03fh,0c0h	; 75dc  ......@....?..?.
	defb 0e0h,085h,0ffh,0ffh,0f8h,0f1h,0f3h,003h,0ffh,081h,001h,007h,0f0h,083h,007h,003h	; 75ec  ................
	defb 001h,005h,000h,005h,0ffh,08bh,07fh,07fh,03fh,0fdh,0f3h,0cfh,02fh,0f7h,0fbh,0f2h	; 75fc  ........?.../...
	defb 0f6h,008h,000h,003h,03fh,005h,01fh,003h,001h,004h,003h,081h,0e0h,002h,0ffh,081h	; 760c  ....?...........
	defb 006h,005h,003h,002h,0c0h,006h,0e0h,083h,0ffh,0feh,0f8h,004h,0f0h,082h,0f8h,080h	; 761c  ................
	defb 005h,000h,083h,003h,01fh,0bch,004h,0bfh,081h,0dfh,003h,0e0h,005h,03fh,002h,01fh	; 762c  .............?..
	defb 002h,0f8h,003h,0fch,08bh,0ffh,0feh,0ffh,01fh,00fh,00fh,007h,007h,0c7h,007h,087h	; 763c  ................
	defb 002h,0e0h,003h,0f0h,083h,0fch,0ffh,0ffh,002h,01fh,004h,00fh,082h,08fh,0ffh,090h	; 764c  ................
	defb 0ffh,0fch,0f0h,0c0h,0c0h,080h,0c0h,0ffh,007h,003h,003h,0fch,0fch,000h,000h,0ffh	; 765c  ................
	defb 003h,0ffh,004h,000h,081h,0e0h,004h,0ffh,004h,000h,004h,0ffh,084h,003h,003h,007h	; 766c  ................
	defb 00fh,000h	; 767c

; ----------------------------------------------------------------------
; DATOS guiones_767E: 5 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x767e..0x76e9  (107 bytes)
DATA_guiones_767E:
	defb 004h,0f3h,004h,0fbh,002h,0b3h,004h,0fbh,082h,0f3h,0b3h,008h,0fbh,002h,0b3h,004h	; 767e  ................
	defb 0fbh,002h,0b3h,005h,0f6h,003h,0e6h,081h,0b6h,004h,0fbh,003h,0ebh,00dh,0fbh,003h	; 768e  ................
	defb 0ebh,006h,0b6h,012h,0ebh,002h,0deh,005h,0feh,081h,0ebh,008h,0dfh,002h,0deh,006h	; 769e  ................
	defb 0feh,010h,0ebh,081h,0fdh,005h,0bdh,002h,0ebh,081h,0feh,00ah,0ebh,005h,0e5h,003h	; 76ae  ................
	defb 0ebh,005h,0e5h,010h,0ebh,005h,0e5h,003h,0e1h,003h,0e5h,002h,051h,01bh,0e1h,000h	; 76be  ............Q...
	defb 002h,01fh,03fh,07fh,0ffh,0feh,070h,000h,001h,008h,008h,000h,007h,0f8h,0fch,0feh	; 76ce  ..?...p.........
	defb 0ffh,0ffh,0ffh,073h,063h,023h,027h,027h,003h,003h,001h	; 76de  ...sc#''...

; ----------------------------------------------------------------------
; DATOS guiones_76E9: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x76e9..0x7702  (25 bytes)
DATA_guiones_76E9:
	defb 000h,004h,001h,003h,007h,006h,006h,006h,007h,003h,001h,000h,007h,0f0h,0f8h,078h	; 76e9  ...............x
	defb 0f6h,0feh,0feh,0ffh,0ffh,0ffh,0feh,01ch,018h	; 76f9  .........

; ----------------------------------------------------------------------
; DATOS guiones_7702: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7702..0x771f  (29 bytes)
DATA_guiones_7702:
	defb 000h,003h,030h,07ch,0ffh,0ffh,07fh,03fh,01fh,007h,001h,000h,004h,01eh,003h,00fh	; 7702  ..0|...?........
	defb 01fh,03fh,0ffh,0ffh,0ffh,0ffh,0ffh,0fch,0f2h,06fh,00fh,003h,001h	; 7712  .?.......o...

; ----------------------------------------------------------------------
; DATOS guiones_771F: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x771f..0x773f  (32 bytes)
DATA_guiones_771F:
	defb 000h,001h,00eh,00fh,00fh,00fh,00dh,00bh,002h,001h,001h,001h,001h,003h,007h,00fh	; 771f  ................
	defb 00fh,000h,003h,080h,0c0h,0e0h,07ch,0fch,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,0c0h	; 772f  ......|.........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_773F: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x773f..0x7764  (37 bytes)
DATA_cabecera_de_la_figura_773F:
	defb 064h,077h,013h,076h,0a7h,077h,0a3h,076h	; 773f  dw.v.w.v
	defb 004h,000h,0e8h,001h,012h,0d8h,008h,012h	; 7747  ........
	defb 0d8h,00bh,030h,000h,005h,080h,002h,004h	; 774f  ..0.....
	defb 004h,004h,004h,004h,005h,0c5h,077h,0e1h	; 7757  ......w.
	defb 077h,0fbh,077h,01fh,077h	; 775f

; ----------------------------------------------------------------------
; DATOS guiones_7764: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7764..0x77a7  (67 bytes)
DATA_guiones_7764:
	defb 094h,002h,007h,0f0h,0e0h,0c0h,0c4h,01fh,01fh,000h,018h,0c7h,047h,04fh,047h,003h	; 7764  ............GOG.
	defb 001h,0e0h,0f2h,0fch,0f8h,004h,0ffh,003h,000h,089h,080h,0c0h,080h,000h,000h,0e1h	; 7774  ................
	defb 000h,0fdh,0feh,006h,0ffh,004h,07fh,002h,03fh,085h,0feh,0fch,0f8h,0f0h,0e0h,007h	; 7784  ........?.......
	defb 000h,084h,0fch,00ch,03ch,07eh,008h,000h,003h,01fh,005h,00fh,083h,001h,007h,00fh	; 7794  ....<~..........
	defb 005h,0ffh,000h	; 77a4

; ----------------------------------------------------------------------
; DATOS guiones_77A7: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x77a7..0x77e1  (58 bytes)
DATA_guiones_77A7:
	defb 002h,0b3h,004h,0fbh,004h,0b3h,00bh,0fbh,003h,0ebh,005h,0fbh,003h,0ebh,002h,0fbh	; 77a7  ................
	defb 006h,0b6h,004h,0fbh,081h,0f6h,00fh,0ebh,081h,0b6h,013h,0ebh,008h,0ebh,000h,004h	; 77b7  ................
	defb 01fh,03fh,07fh,07fh,0fdh,0f8h,0f0h,060h,000h,001h,008h,00ch,000h,005h,0f0h,0f8h	; 77c7  .?.....`........
	defb 0fch,0feh,0feh,0e7h,0c7h,047h,04fh,047h,003h,001h	; 77d7  .....GOG..

; ----------------------------------------------------------------------
; DATOS guiones_77E1: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x77e1..0x77fb  (26 bytes)
DATA_guiones_77E1:
	defb 000h,005h,03dh,07dh,0ffh,0ffh,0dfh,0dfh,0efh,0ffh,07fh,00fh,000h,006h,080h,0c0h	; 77e1  ..=}............
	defb 0c0h,0c0h,0f8h,0f8h,0f8h,0f8h,0f8h,038h,000h,001h	; 77f1  .......8..

; ----------------------------------------------------------------------
; DATOS guiones_77FB: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x77fb..0x7803  (8 bytes)
DATA_guiones_77FB:
	defb 000h,01ah,007h,007h,007h,007h,007h,003h	; 77fb  ........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_7803: Archivo 1: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0x7803..0x7832  (47 bytes)
DATA_cabecera_de_la_figura_7803:
	defb 032h,078h,0f2h,078h,0f3h,078h,044h,079h	; 7803  2x.x.xDy
	defb 006h,000h,0eeh,001h,008h,0dah,008h,010h	; 780b  ........
	defb 0f8h,006h,020h,0fch,00fh,020h,0fch,00dh	; 7813  .. .. ..
	defb 030h,008h,005h,012h,003h,005h,014h,023h	; 781b  0......#
	defb 014h,014h,005h,035h,073h,045h,079h,05bh	; 7823  ...5sEy[
	defb 079h,068h,079h,07dh,079h,08bh,079h	; 782b

; ----------------------------------------------------------------------
; DATOS guiones_7832: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7832..0x78f3  (193 bytes)
DATA_guiones_7832:
	defb 0abh,0ffh,0ffh,000h,000h,0fbh,0c1h,001h,0efh,0ffh,0ffh,000h,000h,0ffh,0ffh,0cfh	; 7832  ................
	defb 08fh,000h,000h,0ffh,00fh,001h,000h,0ffh,0ffh,07fh,0ffh,0ffh,090h,0e0h,0c7h,0f8h	; 7842  ................
	defb 0ffh,0f0h,0e0h,01fh,00fh,00fh,007h,0fch,01fh,080h,0f0h,0fch,005h,0ffh,004h,000h	; 7852  ................
	defb 081h,0e0h,003h,0f8h,081h,0efh,007h,0ffh,084h,03fh,01fh,00fh,003h,004h,000h,005h	; 7862  .........?......
	defb 0ffh,086h,07fh,03fh,03fh,0fch,0fch,0feh,005h,0ffh,004h,000h,08fh,080h,0c0h,0c0h	; 7872  ...??...........
	defb 0e0h,0fbh,0fdh,0fdh,0ffh,0ffh,0ffh,038h,0ffh,03fh,03fh,07fh,005h,0ffh,005h,0f0h	; 7882  .......8.??.....
	defb 083h,0e0h,0c0h,080h,008h,000h,002h,000h,005h,080h,091h,000h,0ffh,0feh,0fch,0f8h	; 7892  ................
	defb 0f0h,0f0h,0f0h,0f8h,003h,0fdh,0fdh,0feh,003h,00fh,01fh,01fh,005h,000h,003h,080h	; 78a2  ................
	defb 002h,0ffh,005h,07fh,089h,0ffh,0f8h,0f8h,0f0h,0f0h,0feh,0e0h,0f8h,0e0h,003h,00fh	; 78b2  ................
	defb 08ah,01fh,03fh,07fh,07fh,0ffh,0c0h,0c0h,0e0h,0e0h,0fch,003h,0ffh,083h,00fh,03fh	; 78c2  ..?............?
	defb 07fh,008h,0ffh,087h,0fch,0f0h,0f8h,0feh,0ffh,0c0h,080h,005h,000h,002h,0ffh,002h	; 78d2  ................
	defb 07fh,002h,080h,002h,000h,005h,0ffh,084h,007h,000h,000h,0c0h,005h,0ffh,003h,000h	; 78e2  ................
	defb 000h	; 78f2

; ----------------------------------------------------------------------
; DATOS guiones_78F3: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x78f3..0x7945  (82 bytes)
DATA_guiones_78F3:
	defb 004h,0f3h,003h,0fbh,081h,0bfh,004h,0f3h,004h,0fbh,002h,0b3h,004h,0fbh,005h,0b3h	; 78f3  ................
	defb 002h,0fbh,003h,0b6h,002h,0b3h,004h,0fbh,082h,0b3h,0b6h,005h,0fbh,003h,0e1h,005h	; 7903  ................
	defb 0fbh,083h,0e6h,0ebh,0ebh,008h,0b6h,00dh,0fbh,013h,0ebh,006h,0b6h,002h,0dbh,018h	; 7913  ................
	defb 0ebh,008h,0feh,008h,0ebh,081h,0fbh,003h,0b6h,016h,0ebh,006h,0e5h,002h,0ebh,006h	; 7923  ................
	defb 0e5h,010h,0ebh,005h,0e5h,003h,0e1h,005h,0e5h,003h,0e1h,003h,0e5h,002h,051h,013h	; 7933  ..............Q.
	defb 0e1h,000h	; 7943

; ----------------------------------------------------------------------
; DATOS guiones_7945: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7945..0x795b  (22 bytes)
DATA_guiones_7945:
	defb 03fh,07fh,0cfh,0dfh,0dfh,0ffh,0feh,07dh,03dh,000h,007h,0c0h,0f0h,0fch,0fch,0fch	; 7945  ?......}=.......
	defb 0fch,07ch,0ech,080h,000h,007h	; 7955

; ----------------------------------------------------------------------
; DATOS guiones_795B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x795b..0x7968  (13 bytes)
DATA_guiones_795B:
	defb 000h,013h,020h,010h,008h,008h,004h,004h,002h,002h,001h,000h,004h	; 795b  .. ..........

; ----------------------------------------------------------------------
; DATOS guiones_7968: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7968..0x797d  (21 bytes)
DATA_guiones_7968:
	defb 003h,007h,0e7h,0e7h,067h,073h,079h,039h,038h,000h,007h,080h,0f0h,0f8h,0f8h,0f8h	; 7968  ....gsy98.......
	defb 0f8h,0f8h,0c0h,000h,008h	; 7978

; ----------------------------------------------------------------------
; DATOS guiones_797D: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x797d..0x798b  (14 bytes)
DATA_guiones_797D:
	defb 0fch,0f8h,018h,018h,018h,00ch,006h,006h,004h,000h,007h,070h,000h,00fh	; 797d  ...........p..

; ----------------------------------------------------------------------
; DATOS guiones_798B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x798b..0x79a8  (29 bytes)
DATA_guiones_798B:
	defb 000h,001h,038h,07ch,0feh,0deh,03fh,02fh,00fh,007h,007h,007h,00fh,01fh,03fh,07fh	; 798b  ..8|..?/......?.
	defb 0feh,000h,006h,0e0h,0e0h,0e0h,0e0h,0c0h,0c0h,0c0h,080h,000h,002h	; 799b  .............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_79A8: Archivo 1: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x79a8..0x79d2  (42 bytes)
DATA_cabecera_de_la_figura_79A8:
	defb 0d2h,079h,087h,07ah,088h,07ah,0ddh,07ah	; 79a8  .y.z.z.z
	defb 005h,000h,0f0h,001h,005h,0d9h,008h,010h	; 79b0  ........
	defb 0e0h,00bh,01ah,0f0h,006h,020h,0f9h,00dh	; 79b8  ..... ..
	defb 012h,013h,013h,022h,013h,013h,014h,014h	; 79c0  ..."....
	defb 035h,073h,0ddh,07ah,0f2h,07ah,0feh,07ah	; 79c8  5s.z.z.z
	defb 006h,07bh	; 79d0

; ----------------------------------------------------------------------
; DATOS guiones_79D2: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x79d2..0x7a88  (182 bytes)
DATA_guiones_79D2:
	defb 0a0h,0ffh,0ffh,000h,000h,0feh,0f0h,0c0h,0cch,0ffh,0ffh,000h,000h,0ffh,0ffh,073h	; 79d2  ...............s
	defb 063h,01fh,03fh,0c0h,0e0h,0f8h,0e0h,01fh,003h,023h,027h,027h,003h,003h,0dfh,0bdh	; 79e2  c.?......#''....
	defb 07bh,002h,000h,004h,0ffh,09ah,0e0h,0f0h,080h,018h,020h,000h,000h,020h,090h,0f0h	; 79f2  {......... .. ..
	defb 0ffh,07fh,03fh,03fh,00fh,00fh,00fh,01fh,007h,003h,001h,001h,0ffh,0f7h,0f7h,0f7h	; 7a02  ..??............
	defb 085h,01fh,03fh,03fh,080h,0c0h,003h,0e0h,088h,0f7h,0f7h,0efh,0efh,0dfh,0dfh,03fh	; 7a12  ..??...........?
	defb 0ffh,007h,0ffh,081h,0feh,088h,01fh,01fh,03fh,03fh,07fh,0ffh,03fh,00fh,008h,0ffh	; 7a22  ........??..?...
	defb 085h,0feh,0fch,0fch,0f8h,0f8h,003h,0f0h,089h,000h,000h,001h,003h,007h,00fh,01fh	; 7a32  ................
	defb 01fh,0ffh,003h,000h,004h,080h,002h,0fch,002h,0feh,004h,0ffh,093h,00fh,007h,003h	; 7a42  ................
	defb 003h,0e1h,001h,0e1h,0c0h,080h,080h,0c0h,0c0h,0f0h,0f8h,0fch,0ffh,0ffh,07fh,01fh	; 7a52  ................
	defb 004h,00fh,081h,087h,0a0h,0ffh,0ffh,0feh,0fch,0f8h,0fch,0ffh,0ffh,080h,000h,000h	; 7a62  ................
	defb 0feh,0f0h,000h,0ffh,0ffh,07eh,03fh,03fh,01fh,001h,003h,007h,0f0h,007h,0c7h,083h	; 7a72  .....~??........
	defb 083h,001h,000h,000h,000h,000h	; 7a82

; ----------------------------------------------------------------------
; DATOS guiones_7A88: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x7a88..0x7af2  (106 bytes)
DATA_guiones_7A88:
	defb 004h,0f3h,004h,0fbh,004h,0f3h,004h,0fbh,002h,0b3h,004h,0fbh,082h,0b3h,063h,005h	; 7a88  ..............c.
	defb 0fbh,003h,0b6h,006h,0f3h,002h,0b3h,005h,0f8h,003h,0b8h,008h,0b8h,004h,0fbh,004h	; 7a98  ................
	defb 0b6h,003h,0b8h,005h,0ebh,008h,0b6h,008h,0ebh,006h,0feh,00ah,0fbh,010h,0ebh,081h	; 7aa8  ................
	defb 0feh,009h,0ebh,006h,0e5h,002h,0ebh,006h,0e5h,005h,0ebh,003h,0e5h,004h,0ebh,009h	; 7ab8  ................
	defb 0e5h,003h,0e1h,003h,0e5h,002h,051h,003h,0e1h,003h,0e5h,081h,0e1h,003h,051h,081h	; 7ac8  ......Q.......Q.
	defb 0e1h,007h,0e5h,081h,051h,000h,007h,007h,00ch,01bh,01fh,01fh,01fh,01fh,00fh,000h	; 7ad8  ....Q...........
	defb 008h,0f0h,0f8h,0feh,0ffh,0ffh,0ffh,0ffh,07eh,0eeh	; 7ae8  ........~.

; ----------------------------------------------------------------------
; DATOS guiones_7AF2: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7af2..0x7afe  (12 bytes)
DATA_guiones_7AF2:
	defb 000h,010h,07ch,07eh,07fh,0ffh,0ffh,07fh,01fh,003h,000h,008h	; 7af2  ..|~........

; ----------------------------------------------------------------------
; DATOS guiones_7AFE: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7afe..0x7b06  (8 bytes)
DATA_guiones_7AFE:
	defb 000h,010h,020h,010h,008h,007h,000h,00ch	; 7afe  .. .....

; ----------------------------------------------------------------------
; DATOS guiones_7B06: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7b06..0x7b1b  (21 bytes)
DATA_guiones_7B06:
	defb 03fh,03fh,000h,004h,006h,002h,01eh,002h,000h,006h,0feh,0feh,006h,003h,003h,003h	; 7b06  ??..............
	defb 003h,003h,003h,000h,007h	; 7b16

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_7B1B: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x7b1b..0x7b40  (37 bytes)
DATA_cabecera_de_la_figura_7B1B:
	defb 040h,07bh,023h,076h,0a3h,07bh,0afh,076h	; 7b1b  @{#v.{.v
	defb 004h,000h,0f4h,001h,010h,0eeh,006h,018h	; 7b23  ........
	defb 0fdh,008h,030h,008h,005h,021h,013h,014h	; 7b2b  ..0..!..
	defb 023h,023h,014h,014h,015h,0cdh,076h,0cch	; 7b33  ##....v.
	defb 07bh,0d9h,07bh,01fh,077h	; 7b3b

; ----------------------------------------------------------------------
; DATOS guiones_7B40: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7b40..0x7ba3  (99 bytes)
DATA_guiones_7B40:
	defb 0a1h,0ffh,0ffh,000h,000h,0ffh,0ffh,0efh,000h,003h,003h,0feh,0fch,0fch,0feh,001h	; 7b40  ................
	defb 001h,007h,0c6h,082h,002h,002h,040h,080h,000h,0c0h,0c0h,03fh,07fh,07fh,03fh,0c0h	; 7b50  ......@....?..?.
	defb 0e0h,0feh,007h,0ffh,083h,000h,0c0h,0e0h,005h,0f0h,082h,003h,001h,006h,000h,003h	; 7b60  ................
	defb 0ffh,085h,03fh,01fh,00fh,003h,001h,084h,0f0h,0f0h,0f8h,0fdh,004h,0ffh,085h,002h	; 7b70  ..?.............
	defb 000h,000h,0f0h,0ebh,003h,0ffh,088h,000h,0c0h,060h,0c0h,080h,0c1h,0c3h,0c7h,083h	; 7b80  .........`......
	defb 001h,000h,002h,004h,003h,084h,0e0h,0ffh,0c0h,002h,005h,0ffh,083h,0cfh,0dfh,060h	; 7b90  ...............`
	defb 005h,0e0h,000h	; 7ba0

; ----------------------------------------------------------------------
; DATOS guiones_7BA3: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x7ba3..0x7bd9  (54 bytes)
DATA_guiones_7BA3:
	defb 004h,0f3h,004h,0fbh,002h,0b3h,004h,0fbh,082h,0f3h,0b3h,008h,0fbh,002h,0b3h,004h	; 7ba3  ................
	defb 0fbh,002h,0b3h,005h,0fbh,003h,0e1h,005h,0fbh,003h,0ebh,00dh,0fbh,01bh,0ebh,007h	; 7bb3  ................
	defb 0feh,002h,0ebh,007h,0feh,002h,0ebh,006h,0feh,000h,016h,01ch,03ch,074h,06ch,06eh	; 7bc3  ............<tln
	defb 07fh,07fh,07eh,03eh,000h,001h	; 7bd3

; ----------------------------------------------------------------------
; DATOS guiones_7BD9: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7bd9..0x7bf2  (25 bytes)
DATA_guiones_7BD9:
	defb 000h,003h,03eh,07dh,0ffh,0ffh,0ffh,0dfh,067h,03fh,000h,005h,040h,038h,00ch,018h	; 7bd9  ..>}....g?..@8..
	defb 070h,0f8h,0f8h,0f8h,0f8h,0f8h,0b0h,000h,005h	; 7be9  p........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_7BF2: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x7bf2..0x7c17  (37 bytes)
DATA_cabecera_de_la_figura_7BF2:
	defb 017h,07ch,023h,076h,077h,07ch,0afh,076h	; 7bf2  .|#vw|.v
	defb 004h,000h,0f0h,001h,010h,0efh,006h,016h	; 7bfa  ........
	defb 0ffh,008h,030h,008h,005h,080h,013h,014h	; 7c02  ..0.....
	defb 023h,023h,014h,014h,015h,0c5h,077h,0a6h	; 7c0a  ##....w.
	defb 07ch,0b2h,07ch,01fh,077h	; 7c12

; ----------------------------------------------------------------------
; DATOS guiones_7C17: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7c17..0x7c77  (96 bytes)
DATA_guiones_7C17:
	defb 090h,002h,007h,0f0h,0e0h,0c0h,0c4h,01fh,01fh,000h,018h,0c7h,047h,04fh,047h,003h	; 7c17  ............GOG.
	defb 001h,007h,0ffh,085h,03ch,0e0h,0f2h,0fch,0f8h,007h,0ffh,082h,080h,0c0h,003h,0e0h	; 7c27  ....<...........
	defb 081h,080h,005h,000h,08ah,008h,006h,0ffh,07fh,01fh,00fh,007h,003h,001h,000h,003h	; 7c37  ................
	defb 0f0h,085h,0f8h,0fch,0feh,0feh,0ffh,003h,001h,085h,007h,007h,03fh,05fh,0ffh,088h	; 7c47  ............?_..
	defb 080h,001h,001h,003h,087h,0cfh,0dfh,0efh,003h,0feh,003h,0ffh,092h,0f8h,0e0h,000h	; 7c57  ................
	defb 000h,020h,018h,081h,0c3h,0ffh,07fh,0cfh,00fh,01fh,0e0h,0f0h,070h,070h,070h,000h	; 7c67  . ..........ppp.

; ----------------------------------------------------------------------
; DATOS guiones_7C77: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x7c77..0x7cb2  (59 bytes)
DATA_guiones_7C77:
	defb 002h,0b3h,004h,0fbh,004h,0b3h,006h,0fbh,002h,031h,004h,0f1h,082h,031h,0b3h,005h	; 7c77  .........1...1..
	defb 0fbh,003h,0e1h,003h,0b1h,002h,0fbh,003h,0ebh,00dh,0fbh,006h,0ebh,002h,0fbh,013h	; 7c87  ................
	defb 0ebh,006h,0e1h,002h,0ebh,007h,0feh,081h,0fbh,081h,0ebh,002h,0edh,005h,0feh,000h	; 7c97  ................
	defb 017h,030h,078h,0f8h,0f8h,0dch,0eeh,07fh,03eh,000h,001h	; 7ca7  .0x.....>..

; ----------------------------------------------------------------------
; DATOS guiones_7CB2: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7cb2..0x7cd1  (31 bytes)
DATA_guiones_7CB2:
	defb 004h,003h,000h,003h,003h,003h,01fh,02fh,0ffh,0ffh,0ffh,0efh,073h,03fh,01eh,000h	; 7cb2  ......./....s?..
	defb 002h,0c0h,080h,080h,080h,0c0h,0e0h,0e8h,0f0h,0e0h,080h,080h,080h,000h,002h	; 7cc2  ...............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_7CD1: Archivo 1: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0x7cd1..0x7cf1  (32 bytes)
DATA_cabecera_de_la_figura_7CD1:
	defb 0f1h,07ch,023h,07ah,044h,07dh,0afh,07ah	; 7cd1  .|#zD}.z
	defb 003h,000h,0f8h,001h,010h,0fah,006h,020h	; 7cd9  ....... 
	defb 001h,00dh,022h,023h,024h,032h,023h,023h	; 7ce1  .."#$2##
	defb 024h,024h,035h,073h,070h,07dh,006h,07bh	; 7ce9  $$5sp}.{

; ----------------------------------------------------------------------
; DATOS guiones_7CF1: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7cf1..0x7d44  (83 bytes)
DATA_guiones_7CF1:
	defb 0a8h,0ffh,0ffh,000h,000h,0feh,0f0h,0c0h,0cch,0ffh,0ffh,000h,000h,0ffh,0ffh,073h	; 7cf1  ...............s
	defb 063h,01fh,03fh,0c0h,0e0h,0f8h,0e0h,01fh,003h,023h,027h,027h,003h,003h,0dfh,0bdh	; 7d01  c.?......#''....
	defb 07bh,000h,000h,0ffh,0ffh,0ffh,087h,0fch,0ffh,002h,0ffh,004h,0feh,002h,0ffh,092h	; 7d11  {...............
	defb 081h,030h,040h,000h,000h,000h,006h,082h,0ffh,0f1h,00fh,00fh,00fh,007h,007h,047h	; 7d21  .0@............G
	defb 03fh,01fh,004h,00fh,082h,01fh,07fh,083h,080h,080h,0c0h,005h,0e0h,082h,0f8h,0feh	; 7d31  ?...............
	defb 006h,0ffh,000h	; 7d41

; ----------------------------------------------------------------------
; DATOS guiones_7D44: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x7d44..0x7d81  (61 bytes)
DATA_guiones_7D44:
	defb 004h,0f3h,004h,0fbh,004h,0f3h,004h,0fbh,002h,0b3h,004h,0fbh,002h,0b3h,005h,0fbh	; 7d44  ................
	defb 003h,0b6h,005h,0f3h,083h,0fbh,0b3h,0b3h,005h,0f8h,003h,0e8h,081h,0b8h,005h,0f8h	; 7d54  ................
	defb 002h,0b8h,002h,0b6h,006h,0b8h,005h,0fbh,00bh,0ebh,008h,0b6h,000h,006h,03ch,07ch	; 7d64  ..............<|
	defb 0deh,0beh,0bfh,0ffh,07dh,03dh,000h,00dh,080h,080h,080h,000h,002h	; 7d74  ....}=.......

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_7D81: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x7d81..0x7da6  (37 bytes)
DATA_cabecera_de_la_figura_7D81:
	defb 0a6h,07dh,045h,07eh,046h,07eh,07dh,07eh	; 7d81  .}E~F~}~
	defb 004h,020h,00ch,006h,020h,010h,001h,030h	; 7d89  . .. ..0
	defb 0f0h,005h,030h,0f0h,006h,080h,080h,080h	; 7d91  ..0.....
	defb 080h,052h,016h,008h,008h,07dh,07eh,08bh	; 7d99  .R...}~.
	defb 07eh,0a8h,07eh,0b5h,07eh	; 7da1

; ----------------------------------------------------------------------
; DATOS guiones_7DA6: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7da6..0x7e46  (160 bytes)
DATA_guiones_7DA6:
	defb 004h,0ffh,084h,0f7h,0e3h,0e3h,0c1h,006h,0ffh,082h,0fbh,0e3h,005h,0ffh,083h,0fch	; 7da6  ................
	defb 0f8h,0f0h,005h,0ffh,083h,01fh,00fh,003h,009h,0ffh,097h,0f9h,0f0h,0f3h,0f4h,0f8h	; 7db6  ................
	defb 0e0h,0e0h,040h,040h,080h,080h,080h,040h,020h,010h,0c3h,003h,007h,027h,00fh,007h	; 7dc6  ..@@...@ ....'..
	defb 001h,000h,005h,0ffh,084h,03fh,01fh,01fh,0f0h,003h,0e0h,084h,0feh,0ffh,0ffh,0f8h	; 7dd6  .....?..........
	defb 004h,000h,086h,040h,0e0h,0feh,003h,000h,0f0h,004h,0fch,084h,0beh,03eh,0c0h,080h	; 7de6  ...@.........>..
	defb 004h,0ffh,083h,080h,080h,0f0h,007h,0ffh,081h,07fh,003h,0ffh,081h,0bfh,003h,0dfh	; 7df6  ................
	defb 005h,07fh,083h,03fh,03fh,01fh,090h,00fh,005h,081h,080h,080h,080h,0c0h,03eh,0f8h	; 7e06  ...??.........>.
	defb 03fh,01fh,01fh,00fh,00fh,0f0h,000h,005h,0ffh,083h,07fh,03fh,007h,008h,07fh,081h	; 7e16  ?..........?....
	defb 080h,004h,0c0h,09bh,0c1h,0c7h,000h,0c0h,080h,018h,020h,0ffh,0ffh,0fch,07eh,047h	; 7e26  .......... ...~G
	defb 03fh,00fh,007h,007h,003h,003h,033h,01fh,01fh,00fh,00fh,00fh,01fh,03fh,00fh,000h	; 7e36  ?.....3......?..

; ----------------------------------------------------------------------
; DATOS guiones_7E46: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x7e46..0x7e8b  (69 bytes)
DATA_guiones_7E46:
	defb 040h,0ebh,008h,0e5h,008h,0ebh,004h,0fbh,004h,0ebh,002h,0feh,006h,0fdh,002h,0ebh	; 7e46  @...............
	defb 004h,0b1h,002h,0dbh,008h,0b6h,008h,0b8h,008h,0ebh,007h,0e5h,082h,051h,0ebh,005h	; 7e56  .............Q..
	defb 0b5h,002h,051h,008h,0b1h,006h,0fbh,009h,0dbh,081h,0e1h,002h,0b8h,002h,0f8h,004h	; 7e66  ..Q.............
	defb 081h,008h,0b8h,007h,0ebh,081h,0e1h,000h,009h,010h,008h,038h,048h,084h,002h,001h	; 7e76  ...........8H...
	defb 000h,00dh,061h,072h,004h	; 7e86

; ----------------------------------------------------------------------
; DATOS guiones_7E8B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7e8b..0x7ea8  (29 bytes)
DATA_guiones_7E8B:
	defb 00fh,03fh,07fh,07fh,0ffh,0ffh,0f7h,0e7h,041h,040h,00ch,002h,000h,004h,0c0h,0f0h	; 7e8b  .?......A@......
	defb 0f8h,0fch,0feh,0feh,0feh,0f6h,0c6h,004h,004h,040h,040h,000h,003h	; 7e9b  .........@@..

; ----------------------------------------------------------------------
; DATOS guiones_7EA8: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7ea8..0x7eb5  (13 bytes)
DATA_guiones_7EA8:
	defb 000h,004h,03eh,007h,03fh,008h,038h,000h,00ch,080h,080h,000h,009h	; 7ea8  ..>.?.8......

; ----------------------------------------------------------------------
; DATOS guiones_7EB5: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7eb5..0x7ebb  (6 bytes)
DATA_guiones_7EB5:
	defb 000h,016h,00eh,003h,000h,008h	; 7eb5

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_7EBB: Archivo 1: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x7ebb..0x7ee0  (37 bytes)
DATA_cabecera_de_la_figura_7EBB:
	defb 0e0h,07eh,0b6h,07fh,0b7h,07fh,017h,080h	; 7ebb  .~......
	defb 004h,000h,008h,001h,018h,018h,008h,010h	; 7ec3  ........
	defb 0f6h,008h,020h,0feh,00dh,042h,033h,025h	; 7ecb  .. ..B3%
	defb 025h,014h,013h,004h,004h,018h,080h,034h	; 7ed3  %......4
	defb 080h,04ch,080h,064h,080h	; 7edb

; ----------------------------------------------------------------------
; DATOS guiones_7EE0: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7ee0..0x7fb7  (215 bytes)
DATA_guiones_7EE0:
	defb 090h,0ffh,0ffh,000h,000h,0feh,0ceh,0c4h,0c4h,0ffh,0ffh,000h,0c0h,00fh,003h,033h	; 7ee0  ...............3
	defb 037h,002h,000h,004h,0ffh,092h,000h,007h,01bh,01fh,0c0h,0c0h,000h,080h,07fh,0ffh	; 7ef0  7...............
	defb 0fch,0fch,007h,01fh,01fh,007h,0f8h,0c0h,004h,0ffh,004h,0feh,088h,0e0h,0c0h,080h	; 7f00  ................
	defb 0efh,0dfh,0bfh,0bfh,07fh,008h,0ffh,084h,07fh,007h,003h,001h,004h,000h,004h,0ffh	; 7f10  ................
	defb 084h,07fh,03fh,01fh,00fh,002h,0feh,002h,0ffh,003h,0feh,081h,0fch,002h,07fh,005h	; 7f20  ..?.............
	defb 0ffh,081h,080h,003h,000h,088h,001h,003h,007h,00fh,00fh,08fh,078h,0fch,005h,0ffh	; 7f30  ............x...
	defb 085h,007h,003h,0f9h,0ffh,00ch,003h,002h,005h,0ffh,08ch,0feh,0fch,0f8h,003h,00fh	; 7f40  ................
	defb 03fh,03fh,01fh,00fh,007h,003h,0fch,007h,0ffh,081h,01fh,007h,0e0h,098h,0e0h,0c0h	; 7f50  ??..............
	defb 080h,080h,080h,000h,01fh,001h,001h,002h,004h,018h,030h,0e0h,0e0h,0c0h,0ffh,00fh	; 7f60  ..........0.....
	defb 000h,001h,003h,007h,00fh,01fh,08bh,0ffh,0feh,0ffh,0feh,0fch,0fch,0f0h,0e0h,0e3h	; 7f70  ................
	defb 003h,087h,004h,00fh,081h,01fh,003h,0c0h,08dh,0e0h,0e0h,0f0h,0f8h,0ffh,03fh,07fh	; 7f80  ..............?.
	defb 07fh,01fh,00fh,00fh,00fh,087h,085h,0c0h,0ffh,0ffh,0fch,000h,003h,0ffh,087h,01fh	; 7f90  ................
	defb 01fh,003h,000h,000h,080h,0f8h,004h,0ffh,08dh,01fh,001h,003h,00fh,00fh,007h,0c1h	; 7fa0  ................
	defb 080h,080h,001h,001h,0f8h,0f8h,000h	; 7fb0

; ----------------------------------------------------------------------
; DATOS guiones_7FB7: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x7fb7..0x8018  (97 bytes)
DATA_guiones_7FB7:
	defb 004h,0f3h,004h,0fbh,003h,0f3h,081h,0b3h,004h,0fbh,007h,0f3h,003h,0b3h,004h,0fbh	; 7fb7  ................
	defb 004h,0b3h,004h,0fbh,002h,0b3h,005h,0fbh,003h,0ebh,003h,0fbh,005h,0b6h,008h,0b0h	; 7fc7  ................
	defb 00dh,0fbh,00ah,0ebh,081h,0edh,007h,0b6h,081h,0dbh,008h,0ebh,081h,0b6h,00bh,0ebh	; 7fd7  ................
	defb 004h,0feh,008h,0ebh,004h,0feh,00ch,0fbh,081h,0ebh,007h,0feh,006h,0ebh,083h,0b5h	; 7fe7  ................
	defb 0e5h,0fbh,007h,0ebh,002h,0fbh,006h,0ebh,010h,0e5h,005h,0ebh,003h,0e5h,004h,0ebh	; 7ff7  ................
	defb 005h,0e5h,004h,051h,003h,0e1h,002h,0e5h,00ah,0e1h,004h,051h,006h,0e5h,002h,051h	; 8007  ...Q.......Q...Q
	defb 000h	; 8017

; ----------------------------------------------------------------------
; DATOS guiones_8018: 2 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8018..0x804c  (52 bytes)
DATA_guiones_8018:
	defb 01fh,03fh,07fh,0ffh,0feh,0ceh,0c4h,0c4h,0e4h,0e0h,0c0h,0c0h,081h,080h,000h,002h	; 8018  .?..............
	defb 0fch,0feh,0ffh,03fh,00eh,000h,002h,010h,000h,005h,080h,060h,000h,001h,01eh,03fh	; 8028  ...?.......`...?
	defb 07bh,0fdh,0feh,0feh,0feh,0ffh,0ffh,07fh,03eh,000h,007h,080h,080h,080h,080h,080h	; 8038  {.......>.......
	defb 080h,080h,000h,006h	; 8048

; ----------------------------------------------------------------------
; DATOS guiones_804C: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x804c..0x8064  (24 bytes)
DATA_guiones_804C:
	defb 000h,003h,001h,003h,003h,003h,003h,001h,001h,001h,000h,007h,0f8h,0feh,0f3h,0fdh	; 804c  ................
	defb 0fdh,0fdh,0ffh,0ffh,0feh,0fch,000h,004h	; 805c  ........

; ----------------------------------------------------------------------
; DATOS guiones_8064: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8064..0x8078  (20 bytes)
DATA_guiones_8064:
	defb 0ffh,03fh,000h,003h,00ch,050h,060h,000h,009h,0f8h,0f8h,018h,018h,018h,018h,018h	; 8064  .?...P`.........
	defb 038h,030h,000h,006h	; 8074

; ----------------------------------------------------------------------
; DATOS guiones_8078: 2 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8078..0x808e  (22 bytes)
DATA_guiones_8078:
	defb 08eh,080h,09eh,081h,09fh,081h,02dh,082h,001h,000h,0f8h,001h,006h,006h,006h,022h	; 8078  ......-........"
	defb 014h,014h,014h,006h,02eh,082h	; 8088

; ----------------------------------------------------------------------
; DATOS guiones_808E: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x808e..0x819f  (273 bytes)
DATA_guiones_808E:
	defb 08ch,0e1h,0c0h,07fh,000h,020h,020h,010h,000h,0ffh,0ffh,080h,0c0h,004h,03fh,094h	; 808e  .....  .......?.
	defb 0ffh,0ffh,000h,010h,0e7h,0c3h,0c0h,086h,0ffh,0ffh,000h,008h,0e7h,0c3h,003h,021h	; 809e  ...............!
	defb 0ffh,0ffh,001h,003h,004h,0fch,088h,087h,003h,0feh,000h,004h,004h,008h,000h,0b0h	; 80ae  ................
	defb 0cfh,0f0h,080h,0c0h,0c0h,0c0h,01fh,01fh,080h,0ffh,0ffh,07fh,07fh,07fh,001h,0bfh	; 80be  ................
	defb 05dh,07fh,0c0h,0c7h,0c7h,0e3h,0dfh,0cfh,0aah,0feh,003h,0e3h,0e3h,0c7h,0fbh,0f3h	; 80ce  ]...............
	defb 001h,0ffh,0ffh,0feh,0feh,0feh,080h,0fdh,0f3h,00fh,001h,003h,003h,003h,0f8h,0f8h	; 80de  ................
	defb 003h,0e0h,085h,0f0h,0f0h,0f8h,0fch,0ffh,002h,0bfh,004h,0ffh,002h,0feh,081h,0f7h	; 80ee  ................
	defb 007h,0ffh,081h,0efh,007h,0ffh,002h,0fdh,004h,0ffh,002h,07fh,003h,007h,095h,00fh	; 80fe  ................
	defb 00fh,01fh,03fh,0ffh,0ffh,07fh,00fh,0fdh,0fbh,0f7h,0f7h,080h,0ffh,0feh,0f0h,0bfh	; 810e  ..?.............
	defb 0dfh,0efh,0efh,001h,005h,0ffh,003h,0feh,002h,080h,004h,07fh,082h,0fbh,0fdh,002h	; 811e  ................
	defb 001h,004h,0feh,082h,0dfh,0bfh,005h,0ffh,003h,07fh,002h,0feh,002h,0fch,002h,0f8h	; 812e  ................
	defb 002h,0f0h,0a0h,0feh,001h,001h,003h,003h,007h,007h,00fh,07fh,080h,080h,0c0h,0c0h	; 813e  ................
	defb 0e0h,0e0h,0f0h,07fh,07fh,03fh,03fh,01fh,01fh,00fh,00fh,0f0h,0f0h,0e0h,0e0h,0efh	; 814e  .....??.........
	defb 0e0h,0eeh,0c0h,005h,01fh,083h,03fh,03fh,07fh,005h,0f8h,08bh,0fch,0fch,0feh,00fh	; 815e  ......??........
	defb 00fh,007h,007h,0f7h,007h,077h,003h,004h,0ffh,08ch,0feh,0f8h,0e0h,0c0h,0c0h,0c0h	; 816e  .....w..........
	defb 081h,081h,001h,0feh,0feh,000h,004h,0ffh,081h,0c0h,007h,0ffh,081h,003h,003h,000h	; 817e  ................
	defb 088h,003h,003h,081h,081h,080h,07fh,07fh,000h,004h,0ffh,084h,07fh,01fh,007h,003h	; 818e  ................
	defb 000h	; 819e

; ----------------------------------------------------------------------
; DATOS guiones_819F: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x819f..0x822e  (143 bytes)
DATA_guiones_819F:
	defb 002h,0f8h,081h,083h,007h,0f8h,002h,083h,006h,0f8h,002h,0b3h,006h,0fbh,002h,0b3h	; 819f  ................
	defb 006h,0fbh,002h,083h,006h,0f8h,081h,083h,005h,0f8h,002h,081h,004h,0f8h,002h,0b3h	; 81af  ................
	defb 082h,083h,031h,004h,0f8h,004h,0b3h,004h,0fbh,004h,0b3h,004h,0fbh,002h,0b3h,082h	; 81bf  ..1.............
	defb 083h,031h,004h,0f8h,002h,0b3h,002h,081h,004h,0f8h,002h,0b3h,005h,0fbh,003h,0ebh	; 81cf  .1..............
	defb 006h,0b6h,002h,0e6h,018h,0b6h,005h,0fbh,003h,0ebh,007h,0b6h,081h,0ebh,007h,0b6h	; 81df  ................
	defb 081h,0ebh,00ah,0edh,006h,0fdh,002h,0edh,006h,0fdh,009h,0edh,007h,0ebh,081h,0fdh	; 81ef  ................
	defb 007h,0ebh,081h,0fdh,007h,0ebh,081h,0edh,009h,0ebh,006h,0e5h,002h,0ebh,006h,0e5h	; 81ff  ................
	defb 002h,0ebh,006h,0e5h,002h,0ebh,00dh,0e5h,081h,0e1h,005h,0e5h,003h,051h,005h,0e1h	; 820f  .............Q..
	defb 003h,010h,008h,0e1h,005h,0e5h,003h,051h,004h,0e1h,003h,0e5h,081h,0e1h,000h	; 821f  .......Q.......

; ----------------------------------------------------------------------
; DATOS guiones_822E: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x822e..0x8244  (22 bytes)
DATA_guiones_822E:
	defb 01fh,03fh,07fh,06fh,067h,043h,040h,002h,022h,000h,007h,0f8h,0fch,0feh,0f6h,0e6h	; 822e  .?.ogC@.".......
	defb 0c2h,002h,020h,054h,000h,007h	; 823e

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8244: Archivo 1: cuatro punteros de fondo, 1
;   piezas de tres bytes y sus 1 punteros; mide 17 + 5*1 = 22
;   0x8244..0x825a  (22 bytes)
DATA_cabecera_de_la_figura_8244:
	defb 05ah,082h,05ah,082h,05ah,082h,05ah,082h	; 8244  Z.Z.Z.Z.
	defb 001h,08fh,000h,000h,080h,080h,080h,080h	; 824c  ........
	defb 080h,080h,080h,080h,05ah,082h	; 8254

; ----------------------------------------------------------------------
; DATOS guiones_825A: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x825a..0x825c  (2 bytes)
DATA_guiones_825A:
	defb 000h,020h	; 825a

; ----------------------------------------------------------------------
; DATOS punteros_del_archivo_2: Las 19 figuras del archivo 2. La tabla la
;   cierra su entrada mas baja, y los cuatro archivos dan 19 clavadas
;   0x825c..0x8282  (38 bytes)
DATA_punteros_del_archivo_2:
	defw 084d3h,085aah,08282h,083d0h,0864eh,08801h,0897ch,08ae3h	; 825c
	defw 08c82h,08d56h,08e29h,08eebh,085aah,090a1h,085aah,09257h	; 826c
	defw 09257h,09362h,09653h	; 827c  -> DATA_cabecera_de_la_figura_9257 DATA_cabecera_de_la_figura_9362 DATA_cabecera_de_la_figura_9653

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8282: Archivo 2: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x8282..0x82a7  (37 bytes)
DATA_cabecera_de_la_figura_8282:
	defb 0a7h,082h,037h,083h,038h,083h,08ah,083h	; 8282  ..7.8...
	defb 003h,001h,012h,006h,001h,011h,006h,008h	; 828a  ........
	defb 01ch,005h,028h,00bh,006h,052h,052h,043h	; 8292  ..(..RRC
	defb 043h,043h,043h,043h,043h,03dh,095h,08bh	; 829a  CCCCC=..
	defb 083h,0a4h,083h,0bfh,083h	; 82a2

; ----------------------------------------------------------------------
; DATOS guiones_82A7: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x82a7..0x8338  (145 bytes)
DATA_guiones_82A7:
	defb 006h,0ffh,082h,0fch,0f8h,088h,0ffh,0ffh,000h,000h,0ffh,000h,000h,00ch,089h,007h	; 82a7  ................
	defb 007h,0f8h,0f8h,0e0h,080h,000h,0f3h,01dh,007h,000h,003h,0fch,005h,0f8h,082h,0fdh	; 82b7  ................
	defb 0feh,005h,0ffh,089h,09fh,00ah,0ffh,07fh,06fh,05fh,0bfh,0ffh,001h,007h,0f8h,085h	; 82c7  ........o_......
	defb 0fch,0e7h,0fbh,0fdh,0feh,004h,0fbh,084h,003h,007h,00fh,01fh,004h,03fh,003h,0fch	; 82d7  .............?..
	defb 005h,0f8h,002h,0ffh,006h,050h,002h,03fh,006h,01fh,08ah,0f8h,0f8h,0fch,0feh,0feh	; 82e7  .....P.?........
	defb 0ffh,0ffh,030h,051h,001h,004h,0ffh,085h,080h,0c0h,01fh,01fh,09fh,003h,08fh,002h	; 82f7  ..0Q............
	defb 04fh,003h,000h,082h,004h,002h,003h,007h,003h,03fh,085h,01fh,01fh,0f0h,0f0h,0e3h	; 8307  O........?......
	defb 003h,02fh,09dh,04fh,09fh,03fh,03fh,0ffh,087h,083h,0c3h,0e1h,0f1h,0ffh,080h,000h	; 8317  ./.O.??.........
	defb 0e0h,0e3h,0e0h,0e0h,0c0h,0c0h,03fh,000h,07fh,0ffh,0ffh,0ffh,03fh,00fh,003h,001h	; 8327  ......?.....?...
	defb 000h	; 8337

; ----------------------------------------------------------------------
; DATOS guiones_8338: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8338..0x838b  (83 bytes)
DATA_guiones_8338:
	defb 002h,0f1h,002h,031h,002h,0f1h,004h,0fbh,003h,0f3h,003h,0fbh,002h,0b3h,005h,0fbh	; 8338  ...1............
	defb 081h,0b6h,008h,0fbh,005h,0fbh,003h,0ebh,008h,0b6h,081h,0fbh,006h,0b6h,009h,0ebh	; 8348  ................
	defb 008h,0b6h,004h,0ebh,084h,0e6h,0ebh,0e6h,0ebh,002h,0edh,006h,0e2h,008h,0d2h,002h	; 8358  ................
	defb 0edh,008h,0e2h,003h,0ebh,003h,0e9h,082h,0d2h,0dbh,004h,0b1h,00ah,0ebh,008h,0e9h	; 8368  ................
	defb 005h,0b9h,003h,0e9h,005h,0ebh,008h,0e9h,003h,0e1h,006h,0e9h,002h,091h,007h,0e9h	; 8378  ................
	defb 081h,0e1h,000h	; 8388

; ----------------------------------------------------------------------
; DATOS guiones_838B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x838b..0x83a4  (25 bytes)
DATA_guiones_838B:
	defb 007h,00fh,01fh,03fh,03fh,039h,031h,031h,031h,018h,000h,006h,0f8h,0fch,0feh,0ffh	; 838b  ...??9111.......
	defb 0f7h,0e3h,088h,088h,000h,005h,040h,020h,010h	; 839b  ......@ .

; ----------------------------------------------------------------------
; DATOS guiones_83A4: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x83a4..0x83bf  (27 bytes)
DATA_guiones_83A4:
	defb 000h,001h,00fh,01fh,01fh,03eh,03fh,03fh,03fh,05fh,0ffh,0ffh,0feh,07ch,03ch,000h	; 83a4  .....>???_...|<.
	defb 004h,080h,0c0h,0c0h,040h,040h,0c0h,0c0h,080h,000h,006h	; 83b4  ....@@.....

; ----------------------------------------------------------------------
; DATOS guiones_83BF: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x83bf..0x83d0  (17 bytes)
DATA_guiones_83BF:
	defb 000h,010h,008h,008h,004h,004h,004h,004h,002h,002h,001h,001h,001h,002h,004h,000h	; 83bf  ................
	defb 003h	; 83cf

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_83D0: Archivo 2: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0x83d0..0x83f0  (32 bytes)
DATA_cabecera_de_la_figura_83D0:
	defb 0f0h,083h,078h,084h,079h,084h,0d2h,084h	; 83d0  ..x.y...
	defb 002h,000h,012h,006h,000h,011h,006h,007h	; 83d8  ........
	defb 01ch,005h,052h,043h,043h,043h,043h,043h	; 83e0  ..RCCCCC
	defb 043h,043h,03dh,095h,08bh,083h,0a4h,083h	; 83e8  CC=.....

; ----------------------------------------------------------------------
; DATOS guiones_83F0: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x83f0..0x8479  (137 bytes)
DATA_guiones_83F0:
	defb 005h,0ffh,083h,0fch,0f8h,0f8h,004h,0ffh,084h,000h,000h,008h,019h,006h,0ffh,082h	; 83f0  ................
	defb 001h,003h,088h,007h,007h,0f8h,0e0h,080h,0ffh,0f3h,0fdh,007h,0ffh,081h,0fdh,002h	; 8400  ................
	defb 0fch,006h,0f8h,081h,0feh,005h,0ffh,08ah,09fh,0e7h,0ffh,07fh,06fh,05fh,0bfh,0ffh	; 8410  ............o_..
	defb 001h,003h,006h,0f8h,002h,0fch,083h,0fbh,0fdh,0feh,004h,0fbh,084h,0ffh,007h,00fh	; 8420  ................
	defb 01fh,005h,03fh,002h,0fch,006h,0f8h,081h,0ffh,006h,050h,082h,051h,03fh,007h,01fh	; 8430  ..?.......P.Q?..
	defb 004h,0fch,00ch,0feh,084h,00fh,007h,003h,001h,004h,000h,004h,0ffh,002h,0feh,002h	; 8440  ................
	defb 0fch,093h,0feh,0fdh,0fdh,0fch,0fch,0fbh,0fbh,038h,080h,001h,023h,01fh,04fh,03fh	; 8450  .........8..#.O?
	defb 03fh,01fh,0fch,0f8h,0f0h,005h,0e0h,090h,008h,038h,01eh,01fh,0f8h,0feh,0ffh,000h	; 8460  ?........8......
	defb 01fh,007h,001h,001h,0ffh,0ffh,001h,000h,000h	; 8470  .........

; ----------------------------------------------------------------------
; DATOS guiones_8479: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8479..0x84d3  (90 bytes)
DATA_guiones_8479:
	defb 002h,0f1h,002h,031h,004h,0fbh,002h,0f1h,002h,031h,004h,0fbh,002h,031h,004h,0f1h	; 8479  ...1.....1...1..
	defb 004h,0b3h,003h,0fbh,003h,0b6h,008h,0b3h,005h,0fbh,003h,0ebh,00eh,0b6h,009h,0ebh	; 8489  ................
	defb 081h,0edh,007h,0b6h,081h,0dbh,003h,0ebh,085h,0e6h,0ebh,0e6h,0ebh,0edh,081h,0edh	; 8499  ................
	defb 007h,0e2h,008h,0d2h,081h,0edh,006h,0e2h,009h,0ebh,008h,0b6h,008h,0ebh,004h,0e1h	; 84a9  ................
	defb 002h,0ebh,002h,0e9h,003h,0b6h,086h,0b9h,0b9h,096h,096h,0e9h,0ebh,00dh,0e9h,002h	; 84b9  ................
	defb 0e1h,004h,0e9h,004h,091h,004h,0e9h,004h,0e1h,000h	; 84c9  ..........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_84D3: Archivo 2: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x84d3..0x84fd  (42 bytes)
DATA_cabecera_de_la_figura_84D3:
	defb 0fdh,084h,0e5h,082h,043h,085h,061h,083h	; 84d3  ....C.a.
	defb 004h,000h,012h,006h,000h,011h,006h,009h	; 84db  ........
	defb 018h,005h,011h,018h,006h,028h,00bh,006h	; 84e3  .....(..
	defb 052h,043h,043h,043h,043h,043h,043h,043h	; 84eb  RCCCCCCC
	defb 058h,095h,06eh,085h,08ah,085h,0a1h,085h	; 84f3  X.n.....
	defb 0bfh,083h	; 84fb

; ----------------------------------------------------------------------
; DATOS guiones_84FD: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x84fd..0x8543  (70 bytes)
DATA_guiones_84FD:
	defb 006h,0ffh,082h,0fch,0f8h,005h,0ffh,083h,000h,000h,008h,006h,0ffh,002h,001h,090h	; 84fd  ................
	defb 007h,007h,0f8h,0f8h,0c0h,0ffh,0ffh,0fbh,019h,000h,000h,002h,00bh,007h,0fch,0ech	; 850d  ................
	defb 003h,0fch,005h,0f8h,082h,0fdh,0feh,005h,0ffh,083h,0bfh,01fh,00fh,003h,08fh,083h	; 851d  ................
	defb 09fh,063h,001h,007h,0f8h,08dh,0fch,0dfh,0e7h,0fbh,0fch,0ffh,0fbh,0fbh,0fbh,000h	; 852d  .c..............
	defb 000h,003h,00fh,004h,03fh,000h	; 853d

; ----------------------------------------------------------------------
; DATOS guiones_8543: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x8543..0x858a  (71 bytes)
DATA_guiones_8543:
	defb 002h,0f1h,002h,031h,006h,0fbh,002h,031h,004h,0fbh,002h,031h,004h,0f1h,004h,0b3h	; 8543  ...1...1...1....
	defb 003h,0fbh,003h,0b6h,006h,0fbh,002h,0b3h,005h,0fbh,003h,0ebh,008h,0b6h,008h,0fbh	; 8553  ................
	defb 008h,0ebh,008h,0b6h,004h,0ebh,084h,0e6h,0ebh,0e6h,0ebh,000h,001h,007h,00fh,01fh	; 8563  ................
	defb 03fh,03fh,039h,031h,031h,031h,018h,000h,006h,0f8h,0fch,0feh,0ffh,0f7h,0e3h,088h	; 8573  ??9111..........
	defb 088h,000h,003h,010h,008h,0c0h,020h	; 8583

; ----------------------------------------------------------------------
; DATOS guiones_858A: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x858a..0x85a1  (23 bytes)
DATA_guiones_858A:
	defb 000h,007h,001h,001h,001h,001h,003h,007h,003h,001h,000h,006h,038h,0deh,0ffh,0ffh	; 858a  ............8...
	defb 0ffh,0fbh,0fbh,0f7h,0feh,0fch,080h	; 859a

; ----------------------------------------------------------------------
; DATOS guiones_85A1: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x85a1..0x85aa  (9 bytes)
DATA_guiones_85A1:
	defb 000h,001h,080h,080h,080h,098h,060h,000h,01ah	; 85a1  ......`..

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_85AA: Archivo 2: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x85aa..0x85cf  (37 bytes)
DATA_cabecera_de_la_figura_85AA:
	defb 0cfh,085h,033h,084h,019h,086h,0a7h,084h	; 85aa  ..3.....
	defb 003h,0ffh,012h,006h,0ffh,011h,006h,008h	; 85b2  ........
	defb 018h,005h,010h,018h,006h,052h,043h,043h	; 85ba  .....RCC
	defb 043h,043h,043h,043h,043h,058h,095h,06eh	; 85c2  CCCCCX.n
	defb 085h,08ah,085h,0a1h,085h	; 85ca

; ----------------------------------------------------------------------
; DATOS guiones_85CF: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x85cf..0x8619  (74 bytes)
DATA_guiones_85CF:
	defb 005h,0ffh,083h,0fch,0f8h,0f8h,004h,0ffh,084h,000h,000h,008h,019h,005h,0ffh,083h	; 85cf  ................
	defb 0feh,001h,003h,090h,007h,007h,0f8h,0c0h,0ffh,0ffh,0fbh,0fdh,0ffh,0ffh,002h,00bh	; 85df  ................
	defb 007h,003h,0fch,0e0h,002h,0fch,006h,0f8h,081h,0feh,005h,0ffh,083h,0bfh,0dfh,00fh	; 85ef  ................
	defb 003h,08fh,084h,09fh,063h,001h,000h,006h,0f8h,002h,0fch,08bh,0e7h,0fbh,0fch,0ffh	; 85ff  ....c...........
	defb 0fbh,0fbh,0fbh,000h,000h,003h,00fh,005h,03fh,000h	; 860f  ........?.

; ----------------------------------------------------------------------
; DATOS guiones_8619: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8619..0x864e  (53 bytes)
DATA_guiones_8619:
	defb 002h,0f1h,002h,031h,006h,0fbh,002h,031h,004h,0fbh,002h,031h,003h,0f1h,081h,0fbh	; 8619  ...1...1...1....
	defb 004h,0b3h,002h,0fbh,004h,0b6h,002h,0b3h,004h,0fbh,002h,0b3h,005h,0fbh,003h,0ebh	; 8629  ................
	defb 008h,0b6h,005h,0fbh,00ah,0ebh,081h,0edh,007h,0b6h,081h,0bdh,003h,0ebh,085h,0e6h	; 8639  ................
	defb 0ebh,0e6h,0ebh,0edh,000h	; 8649

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_864E: Archivo 2: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0x864e..0x867d  (47 bytes)
DATA_cabecera_de_la_figura_864E:
	defb 07dh,086h,036h,087h,037h,087h,07fh,087h	; 864e  }.6.7...
	defb 005h,000h,008h,006h,000h,008h,006h,010h	; 8656  ........
	defb 000h,005h,00fh,012h,005h,020h,00dh,002h	; 865e  ..... ..
	defb 030h,001h,009h,051h,033h,034h,034h,043h	; 8666  0..Q344C
	defb 044h,053h,035h,078h,095h,07fh,087h,0a3h	; 866e  DS5x....
	defb 087h,0beh,087h,0d4h,087h,0e8h,087h	; 8676

; ----------------------------------------------------------------------
; DATOS guiones_867D: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x867d..0x8737  (186 bytes)
DATA_guiones_867D:
	defb 005h,0ffh,003h,007h,006h,0ffh,0a6h,001h,003h,03fh,083h,087h,080h,0c0h,0e1h,0ceh	; 867d  .........?......
	defb 0f7h,0f8h,037h,03fh,007h,007h,007h,008h,0f8h,0f8h,0f0h,0f0h,0e1h,0e1h,0c1h,081h	; 868d  ..7?............
	defb 0f0h,07eh,0feh,0ffh,0ffh,0ffh,000h,000h,0feh,0f6h,00bh,0fdh,0eeh,003h,0f6h,084h	; 869d  .~..............
	defb 0feh,0ffh,07fh,03fh,004h,07fh,081h,03fh,09dh,003h,003h,001h,001h,000h,001h,083h	; 86ad  ...?...?........
	defb 0ffh,0feh,0fch,0fch,0f8h,0f0h,0f8h,0fch,0fch,0ffh,0ech,0ceh,09eh,0beh,0bfh,0ffh	; 86bd  ................
	defb 0ffh,03fh,03fh,01fh,003h,007h,003h,07fh,081h,0fch,007h,0feh,081h,000h,006h,0bfh	; 86cd  .??.............
	defb 082h,0beh,03fh,003h,0ffh,084h,0f7h,0e3h,0c1h,080h,004h,0fch,002h,0feh,002h,0ffh	; 86dd  ..?.............
	defb 081h,0fdh,003h,0feh,002h,001h,006h,000h,088h,080h,0e0h,0f0h,0f8h,07fh,03fh,01fh	; 86ed  ..............?.
	defb 00fh,004h,007h,098h,080h,000h,000h,000h,001h,087h,09fh,0ffh,0f0h,0f0h,0f0h,0e0h	; 86fd  ................
	defb 0e0h,0c1h,0c0h,081h,00fh,00fh,01fh,0ffh,03fh,0ffh,07fh,0ffh,006h,0ffh,082h,0fch	; 870d  ........?.......
	defb 0feh,00ah,0ffh,082h,0fch,0e0h,003h,000h,08eh,00fh,0ffh,0ffh,07fh,03fh,00fh,001h	; 871d  .............?..
	defb 0e0h,0fch,0ffh,07fh,03fh,01fh,00fh,003h,007h,000h	; 872d  ....?.....

; ----------------------------------------------------------------------
; DATOS guiones_8737: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x8737..0x87a3  (108 bytes)
DATA_guiones_8737:
	defb 002h,0f1h,002h,031h,004h,0fbh,002h,031h,004h,0f1h,003h,0b3h,005h,0fbh,002h,0b6h	; 8737  ...1...1........
	defb 081h,0b3h,005h,0fbh,002h,0b3h,005h,0fbh,085h,0ebh,0ebh,0b6h,0fbh,0f6h,005h,0feh	; 8747  ................
	defb 081h,0ebh,008h,0b6h,005h,0fbh,012h,0ebh,081h,0edh,007h,0b6h,081h,0dbh,005h,0ebh	; 8757  ................
	defb 083h,0e6h,0ebh,0edh,014h,0edh,00ch,0ebh,004h,0b6h,01ch,0ebh,010h,0e9h,018h,0e1h	; 8767  ................
	defb 006h,091h,002h,0e1h,007h,0e9h,081h,0e1h,000h,001h,01fh,03fh,07fh,07fh,0ffh,0ffh	; 8777  ...........?....
	defb 0ffh,0d8h,099h,091h,090h,040h,001h,001h,000h,002h,0e0h,0fch,0feh,0feh,0f6h,0f6h	; 8787  .....@..........
	defb 084h,000h,001h,010h,010h,020h,010h,000h,001h,0f0h,000h,001h	; 8797  ..... ......

; ----------------------------------------------------------------------
; DATOS guiones_87A3: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x87a3..0x87be  (27 bytes)
DATA_guiones_87A3:
	defb 000h,003h,001h,001h,001h,001h,001h,003h,003h,001h,001h,000h,004h,07ch,0feh,0f7h	; 87a3  .............|..
	defb 0fbh,0fbh,0fbh,0fbh,0feh,0feh,0fch,0fch,0f8h,000h,004h	; 87b3  ...........

; ----------------------------------------------------------------------
; DATOS guiones_87BE: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x87be..0x87d4  (22 bytes)
DATA_guiones_87BE:
	defb 000h,004h,001h,001h,001h,001h,000h,008h,03ch,07eh,0fbh,0fdh,0fdh,0fdh,0ffh,0ffh	; 87be  ........<~......
	defb 0ffh,0ffh,0feh,07ch,000h,004h	; 87ce

; ----------------------------------------------------------------------
; DATOS guiones_87D4: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x87d4..0x87e8  (20 bytes)
DATA_guiones_87D4:
	defb 000h,001h,0d7h,0d7h,0d7h,0d7h,0d7h,0d7h,0d7h,000h,009h,0fch,0feh,0feh,0feh,0fch	; 87d4  ................
	defb 0f8h,0d0h,000h,008h	; 87e4

; ----------------------------------------------------------------------
; DATOS guiones_87E8: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x87e8..0x8801  (25 bytes)
DATA_guiones_87E8:
	defb 000h,006h,001h,003h,007h,007h,007h,003h,003h,000h,005h,00eh,01eh,03eh,07bh,0fdh	; 87e8  .............>{.
	defb 0f5h,0f8h,0f0h,0f0h,0f8h,0f8h,0feh,0ffh,07fh	; 87f8  .........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8801: Archivo 2: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0x8801..0x8830  (47 bytes)
DATA_cabecera_de_la_figura_8801:
	defb 030h,088h,0c3h,088h,0c4h,088h,018h,089h	; 8801  0.......
	defb 005h,000h,01ah,006h,000h,019h,006h,00dh	; 8809  ........
	defb 028h,005h,010h,028h,00bh,030h,01bh,009h	; 8811  (..(.0..
	defb 030h,005h,00eh,071h,062h,053h,053h,053h	; 8819  0..qbSSS
	defb 053h,044h,044h,0b3h,095h,018h,089h,032h	; 8821  SDD....2
	defb 089h,04ch,089h,059h,089h,075h,089h	; 8829

; ----------------------------------------------------------------------
; DATOS guiones_8830: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8830..0x88c4  (148 bytes)
DATA_guiones_8830:
	defb 007h,0ffh,083h,000h,003h,007h,004h,0f8h,08fh,00fh,03fh,000h,008h,019h,000h,000h	; 8830  ..........?.....
	defb 002h,0f4h,0f8h,0ffh,0feh,0fch,0f8h,0f8h,004h,0f0h,006h,0ffh,089h,0fbh,023h,073h	; 8840  ..............#s
	defb 03fh,01fh,0f0h,0f8h,0fch,0feh,008h,0e0h,091h,0fdh,0feh,0ffh,0ffh,0ffh,0fbh,0f6h	; 8850  ?...............
	defb 0efh,0ffh,0ffh,03fh,0dfh,070h,078h,07fh,0ffh,0e0h,004h,0f0h,003h,0e0h,084h,0ech	; 8860  ...?.px.........
	defb 0efh,0ffh,0ffh,004h,0a0h,004h,0ffh,004h,07fh,003h,0e0h,003h,0f0h,002h,0f8h,003h	; 8870  ................
	defb 0a0h,005h,0f7h,088h,07fh,07fh,03fh,00fh,007h,003h,001h,001h,003h,0ffh,082h,0fch	; 8880  ......?.........
	defb 0f0h,003h,000h,088h,0f8h,0fch,00fh,00fh,00fh,027h,0a7h,0a7h,006h,007h,084h,00fh	; 8890  .........'......
	defb 01fh,001h,001h,006h,0ffh,088h,000h,081h,081h,0c1h,0c1h,01fh,00fh,0c0h,004h,0ffh	; 88a0  ................
	defb 08ch,0f0h,000h,000h,003h,0e0h,0e0h,0f0h,001h,000h,000h,00fh,0ffh,005h,0ffh,083h	; 88b0  ................
	defb 000h,0ffh,0ffh,000h	; 88c0

; ----------------------------------------------------------------------
; DATOS guiones_88C4: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x88c4..0x8932  (110 bytes)
DATA_guiones_88C4:
	defb 002h,0f1h,002h,031h,004h,0fbh,002h,0b3h,004h,0fbh,002h,0b3h,006h,0fbh,002h,0b3h	; 88c4  ...1............
	defb 005h,0fbh,003h,0ebh,008h,0b6h,004h,0fbh,004h,0b5h,008h,0ebh,00ch,0b6h,002h,0ebh	; 88d4  ................
	defb 002h,0e6h,002h,0ebh,002h,0edh,004h,0e2h,002h,0b6h,006h,0d2h,004h,0e1h,081h,0e3h	; 88e4  ................
	defb 003h,0e2h,003h,0e2h,005h,0ebh,003h,0d2h,005h,0b6h,002h,0e2h,006h,0ebh,003h,0e1h	; 88f4  ................
	defb 005h,0e9h,002h,0ebh,006h,0b9h,010h,0ebh,005h,0e9h,002h,091h,009h,0e1h,003h,0ebh	; 8904  ................
	defb 081h,0b1h,00ch,0e1h,000h,003h,007h,00fh,01fh,03fh,03fh,039h,031h,031h,031h,018h	; 8914  .........??9111.
	defb 000h,006h,0f8h,0fch,0feh,0ffh,0f7h,0e3h,088h,088h,000h,003h,010h,008h	; 8924  ..............

; ----------------------------------------------------------------------
; DATOS guiones_8932: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8932..0x894c  (26 bytes)
DATA_guiones_8932:
	defb 000h,001h,001h,002h,003h,002h,007h,01fh,01fh,08fh,087h,003h,000h,005h,0fch,0feh	; 8932  ................
	defb 0feh,0fah,0fah,0fah,0f6h,0fch,0f8h,0c0h,000h,006h	; 8942  ..........

; ----------------------------------------------------------------------
; DATOS guiones_894C: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x894c..0x8959  (13 bytes)
DATA_guiones_894C:
	defb 000h,005h,010h,078h,0fch,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,012h	; 894c  ...x.........

; ----------------------------------------------------------------------
; DATOS guiones_8959: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8959..0x8975  (28 bytes)
DATA_guiones_8959:
	defb 000h,002h,01fh,01fh,03ch,03fh,07ch,0ffh,0ffh,0ffh,07fh,00fh,007h,000h,005h,0e0h	; 8959  ....<?|.........
	defb 0c0h,000h,001h,080h,000h,003h,080h,0e0h,0f0h,0f0h,000h,003h	; 8969  ............

; ----------------------------------------------------------------------
; DATOS guiones_8975: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8975..0x897c  (7 bytes)
DATA_guiones_8975:
	defb 000h,015h,001h,005h,005h,000h,008h	; 8975

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_897C: Archivo 2: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x897c..0x89a6  (42 bytes)
DATA_cabecera_de_la_figura_897C:
	defb 0a6h,089h,052h,08ah,053h,08ah,0ach,08ah	; 897c  ..R.S...
	defb 004h,003h,01ah,006h,003h,019h,006h,010h	; 8984  ........
	defb 028h,005h,018h,028h,00bh,020h,00fh,002h	; 898c  (..(. ..
	defb 080h,062h,053h,044h,044h,053h,035h,035h	; 8994  .bSDDS55
	defb 0b3h,095h,018h,089h,0ach,08ah,0c5h,08ah	; 899c  ........
	defb 0cfh,08ah	; 89a4

; ----------------------------------------------------------------------
; DATOS guiones_89A6: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x89a6..0x8a53  (173 bytes)
DATA_guiones_89A6:
	defb 003h,0ffh,083h,0fch,0f8h,0f8h,002h,007h,004h,000h,08dh,008h,019h,0ffh,0ffh,0ffh	; 89a6  ................
	defb 0fch,0f8h,0f0h,0e0h,0c0h,0c0h,080h,080h,007h,000h,088h,002h,00bh,003h,023h,073h	; 89b6  ..............#s
	defb 0c3h,089h,080h,003h,0ffh,005h,0feh,081h,080h,006h,000h,081h,0feh,08ch,0ffh,0ffh	; 89c6  ................
	defb 09fh,0efh,0f7h,0fbh,0fdh,006h,0c0h,0e0h,0f0h,0f8h,004h,0ffh,003h,0feh,005h,0ffh	; 89d6  ................
	defb 004h,0fdh,002h,000h,002h,0afh,005h,01fh,085h,00fh,0ffh,0ffh,080h,0c1h,006h,0ffh	; 89e6  ................
	defb 003h,0afh,002h,0d7h,005h,0ffh,082h,0fbh,0e1h,004h,07fh,005h,0ffh,083h,07fh,03fh	; 89f6  ...............?
	defb 01fh,004h,0ffh,081h,0fch,003h,0f8h,098h,0ffh,0ffh,0e0h,080h,000h,000h,001h,005h	; 8a06  ................
	defb 000h,000h,080h,000h,000h,07fh,03fh,03eh,080h,0c0h,0f0h,0e0h,0c0h,083h,000h,007h	; 8a16  ......?>........
	defb 003h,01fh,082h,03fh,07fh,003h,0ffh,003h,0fch,004h,0feh,082h,0ffh,002h,003h,00fh	; 8a26  ...?............
	defb 089h,007h,0fch,0ffh,000h,08ch,0feh,0feh,0fch,0e0h,003h,000h,08bh,003h,0ffh,0ffh	; 8a36  ................
	defb 07fh,01fh,000h,01fh,0ffh,0ffh,0ffh,03fh,003h,01fh,002h,0ffh,000h	; 8a46  .......?.....

; ----------------------------------------------------------------------
; DATOS guiones_8A53: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x8a53..0x8ac5  (114 bytes)
DATA_guiones_8A53:
	defb 002h,031h,004h,0fbh,004h,0b3h,004h,0fbh,002h,0b3h,005h,0fbh,003h,0ebh,00dh,0fbh	; 8a53  .1..............
	defb 083h,0e5h,0e5h,0b5h,00fh,0ebh,008h,0b6h,081h,0ebh,003h,0b5h,005h,0b6h,008h,0ebh	; 8a63  ................
	defb 004h,0b6h,004h,0edh,084h,0e6h,0ebh,0e6h,0ebh,004h,0edh,008h,0ebh,005h,0edh,003h	; 8a73  ................
	defb 0b6h,004h,0ebh,004h,0b6h,008h,0ebh,010h,0e9h,005h,0ebh,003h,0b9h,003h,0ebh,005h	; 8a83  ................
	defb 0e9h,003h,0ebh,00bh,0e9h,002h,0e1h,005h,0e9h,003h,091h,003h,0e9h,005h,0e1h,081h	; 8a93  ................
	defb 0e9h,004h,091h,005h,0e1h,003h,0e9h,003h,0e1h,000h,006h,001h,003h,003h,003h,01fh	; 8aa3  ................
	defb 00fh,00fh,007h,007h,003h,000h,005h,078h,0bch,0feh,0ffh,0fdh,0fdh,0fbh,0f6h,0fch	; 8ab3  .......x........
	defb 0f8h,080h	; 8ac3

; ----------------------------------------------------------------------
; DATOS guiones_8AC5: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8ac5..0x8acf  (10 bytes)
DATA_guiones_8AC5:
	defb 000h,003h,0f0h,0f0h,0f8h,0f8h,0fch,0e0h,000h,017h	; 8ac5  ..........

; ----------------------------------------------------------------------
; DATOS guiones_8ACF: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8acf..0x8ae3  (20 bytes)
DATA_guiones_8ACF:
	defb 000h,006h,0d7h,0d7h,0d7h,0d7h,0d7h,0ebh,0ebh,000h,009h,0f8h,0fch,0feh,0feh,0fch	; 8acf  ................
	defb 0f0h,080h,000h,003h	; 8adf

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8AE3: Archivo 2: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x8ae3..0x8b0d  (42 bytes)
DATA_cabecera_de_la_figura_8AE3:
	defb 00dh,08bh,0cch,08bh,0cdh,08bh,035h,08ch	; 8ae3  ......5.
	defb 004h,0fch,016h,006h,0fch,016h,006h,008h	; 8aeb  ........
	defb 02bh,005h,00ch,028h,00bh,020h,00bh,002h	; 8af3  +..(. ..
	defb 062h,053h,035h,034h,043h,044h,035h,035h	; 8afb  bS54CD55
	defb 09ah,095h,036h,08ch,04eh,08ch,064h,08ch	; 8b03  ..6.N.d.
	defb 06ch,08ch	; 8b0b

; ----------------------------------------------------------------------
; DATOS guiones_8B0D: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8b0d..0x8bcd  (192 bytes)
DATA_guiones_8B0D:
	defb 006h,0ffh,002h,000h,005h,0ffh,083h,00fh,00fh,08fh,003h,0ffh,086h,0feh,0f8h,0e0h	; 8b0d  ................
	defb 07fh,0ffh,001h,004h,0ffh,088h,0f0h,00fh,0ffh,09fh,0f0h,00fh,02fh,0f8h,003h,0ffh	; 8b1d  ............/...
	defb 005h,0ffh,08bh,000h,0feh,0feh,0fah,0f4h,0ech,0c8h,098h,010h,030h,020h,00dh,0ffh	; 8b2d  ............0 ..
	defb 087h,0f3h,007h,00fh,0ffh,0ffh,00fh,03fh,004h,0ffh,081h,0feh,007h,0ffh,083h,020h	; 8b3d  .......?....... 
	defb 020h,0a0h,003h,0e0h,002h,0f0h,004h,0ffh,088h,0fch,0ffh,0fch,0ffh,01fh,03fh,07fh	; 8b4d   .............?.
	defb 07fh,004h,0ffh,002h,0f0h,006h,0f5h,002h,000h,005h,0ffh,081h,0fbh,006h,0ffh,082h	; 8b5d  ................
	defb 0cfh,003h,002h,0f5h,006h,0f0h,002h,008h,083h,0f7h,0f7h,00eh,003h,00fh,005h,000h	; 8b6d  ................
	defb 085h,080h,0e0h,0e0h,0ffh,07fh,006h,03fh,003h,0ffh,088h,0fch,0f0h,080h,000h,000h	; 8b7d  .......?........
	defb 0f0h,0f8h,0f8h,004h,01fh,004h,00fh,003h,01fh,002h,03fh,089h,0c0h,080h,080h,08fh	; 8b8d  ..........?.....
	defb 081h,00fh,003h,007h,07fh,007h,0ffh,09ah,001h,001h,003h,083h,081h,080h,03fh,01fh	; 8b9d  ..............?.
	defb 04fh,04fh,0ffh,0ffh,0f0h,000h,080h,0c0h,0feh,0feh,0fch,0fch,003h,000h,000h,007h	; 8bad  OO..............
	defb 007h,001h,004h,000h,081h,003h,003h,0ffh,086h,07fh,01fh,01fh,03fh,0ffh,0ffh,000h	; 8bbd  ............?...

; ----------------------------------------------------------------------
; DATOS guiones_8BCD: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8bcd..0x8c36  (105 bytes)
DATA_guiones_8BCD:
	defb 002h,0f1h,002h,031h,006h,0fbh,002h,031h,004h,0fbh,002h,031h,004h,0fbh,002h,0b3h	; 8bcd  ...1...1...1....
	defb 081h,0fbh,007h,0b6h,082h,0fbh,0b3h,003h,0fbh,003h,0b1h,006h,0feh,002h,0ebh,008h	; 8bdd  ................
	defb 0fbh,00eh,0b6h,002h,0ebh,002h,0b1h,003h,0fbh,003h,0e1h,008h,0ebh,002h,0fbh,006h	; 8bed  ................
	defb 0ebh,008h,0b6h,008h,0ebh,010h,0edh,008h,0ebh,002h,0edh,006h,0ebh,002h,0dbh,002h	; 8bfd  ................
	defb 0b6h,014h,0ebh,008h,0e9h,003h,0ebh,005h,0b9h,00ah,0ebh,006h,0e9h,008h,0ebh,006h	; 8c0d  ................
	defb 0e9h,084h,091h,091h,0b9h,0e9h,004h,0e1h,002h,091h,004h,0e9h,002h,091h,002h,0e1h	; 8c1d  ................
	defb 005h,0e9h,003h,0e1h,005h,0e9h,003h,0e1h,000h	; 8c2d  .........

; ----------------------------------------------------------------------
; DATOS guiones_8C36: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8c36..0x8c4e  (24 bytes)
DATA_guiones_8C36:
	defb 000h,005h,007h,00fh,01fh,03fh,03fh,039h,031h,031h,031h,018h,000h,006h,0f8h,0fch	; 8c36  .....??9111.....
	defb 0feh,0ffh,0f7h,0f3h,088h,088h,000h,003h	; 8c46  ........

; ----------------------------------------------------------------------
; DATOS guiones_8C4E: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8c4e..0x8c64  (22 bytes)
DATA_guiones_8C4E:
	defb 001h,003h,01fh,03fh,01fh,01fh,01fh,00fh,00dh,000h,007h,0fch,0feh,0fbh,0fdh,0fdh	; 8c4e  ...?............
	defb 0fdh,09fh,0deh,0bch,000h,007h	; 8c5e

; ----------------------------------------------------------------------
; DATOS guiones_8C64: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8c64..0x8c6c  (8 bytes)
DATA_guiones_8C64:
	defb 0fch,0fch,0fch,0feh,0f8h,0c0h,000h,01ah	; 8c64  ........

; ----------------------------------------------------------------------
; DATOS guiones_8C6C: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8c6c..0x8c82  (22 bytes)
DATA_guiones_8C6C:
	defb 000h,002h,0afh,0afh,0afh,0afh,0afh,0afh,0afh,0afh,000h,008h,0f8h,0fch,0fch,0feh	; 8c6c  ................
	defb 0feh,0d8h,0b0h,080h,000h,006h	; 8c7c

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8C82: Archivo 2: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0x8c82..0x8cb1  (47 bytes)
DATA_cabecera_de_la_figura_8C82:
	defb 0b1h,08ch,07ch,08fh,0ffh,08ch,00ch,090h	; 8c82  ..|.....
	defb 005h,0ffh,018h,006h,0ffh,017h,006h,00ch	; 8c8a  ........
	defb 02ah,005h,010h,028h,00bh,020h,010h,00dh	; 8c92  *..(. ..
	defb 030h,018h,009h,062h,053h,053h,053h,053h	; 8c9a  0..bSSSS
	defb 053h,044h,044h,058h,095h,06eh,085h,034h	; 8ca2  SDDX.n.4
	defb 08dh,04ch,08dh,077h,090h,086h,090h	; 8caa

; ----------------------------------------------------------------------
; DATOS guiones_8CB1: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8cb1..0x8cff  (78 bytes)
DATA_guiones_8CB1:
	defb 005h,0ffh,083h,0f3h,0e3h,0e3h,004h,0ffh,084h,003h,003h,023h,067h,004h,0ffh,094h	; 8cb1  ...........#g...
	defb 0feh,0fch,007h,00fh,01fh,01fh,0e0h,0e0h,010h,0ffh,0ffh,0ffh,0fch,0fch,00bh,02fh	; 8cc1  .............../
	defb 01fh,00fh,00fh,0c0h,099h,0f0h,0e0h,0c0h,080h,000h,000h,000h,080h,0ffh,0feh,0fch	; 8cd1  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f8h,001h,00ch,002h,000h,000h,004h,009h,08fh,0c0h,006h,0e0h	; 8ce1  ................
	defb 08ah,0f0h,0f8h,000h,008h,013h,010h,013h,010h,0ffh,07fh,007h,0ffh,000h	; 8cf1  ..............

; ----------------------------------------------------------------------
; DATOS guiones_8CFF: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8cff..0x8d34  (53 bytes)
DATA_guiones_8CFF:
	defb 002h,0f1h,002h,031h,006h,0fbh,002h,031h,004h,0fbh,002h,031h,004h,0fbh,004h,0b3h	; 8cff  ...1...1...1....
	defb 003h,0fbh,005h,0b3h,005h,0fbh,081h,0b3h,004h,0fbh,004h,0ebh,003h,0b5h,081h,065h	; 8d0f  ...............e
	defb 004h,0b5h,005h,0f5h,003h,0b5h,082h,0ebh,0e6h,005h,0ebh,082h,0ebh,065h,006h,06bh	; 8d1f  .............e.k
	defb 081h,0bbh,008h,0ebh,000h	; 8d2f

; ----------------------------------------------------------------------
; DATOS guiones_8D34: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8d34..0x8d4c  (24 bytes)
DATA_guiones_8D34:
	defb 000h,001h,001h,003h,00fh,00fh,00fh,007h,007h,003h,002h,000h,006h,0fch,0feh,0fbh	; 8d34  ................
	defb 0fdh,0fdh,0ffh,0deh,0eeh,070h,000h,007h	; 8d44  .....p..

; ----------------------------------------------------------------------
; DATOS guiones_8D4C: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8d4c..0x8d56  (10 bytes)
DATA_guiones_8D4C:
	defb 03ch,0fch,0feh,0feh,0ffh,0fch,0f0h,0c0h,000h,018h	; 8d4c  <.........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8D56: Archivo 2: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0x8d56..0x8d85  (47 bytes)
DATA_cabecera_de_la_figura_8D56:
	defb 085h,08dh,079h,088h,0d2h,08dh,0f6h,088h	; 8d56  ..y.....
	defb 005h,000h,012h,006h,000h,011h,006h,012h	; 8d5e  ........
	defb 013h,005h,012h,00bh,006h,030h,013h,009h	; 8d66  .....0..
	defb 030h,0fdh,00eh,061h,052h,043h,043h,043h	; 8d6e  0..aRCCC
	defb 043h,034h,034h,0b3h,095h,018h,089h,0f6h	; 8d76  C44.....
	defb 08dh,012h,08eh,059h,089h,075h,089h	; 8d7e

; ----------------------------------------------------------------------
; DATOS guiones_8D85: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8d85..0x8dd2  (77 bytes)
DATA_guiones_8D85:
	defb 007h,0ffh,083h,000h,003h,007h,004h,0f8h,08ah,00fh,03fh,0ffh,008h,019h,000h,000h	; 8d85  ..........?.....
	defb 002h,0f4h,0f8h,088h,0ffh,0feh,0fch,0f9h,0fah,0f4h,0f8h,0f0h,008h,000h,083h,023h	; 8d95  ...............#
	defb 033h,03fh,005h,01fh,093h,0e0h,0e0h,0c0h,0c0h,080h,080h,080h,0e0h,008h,010h,020h	; 8da5  3?............. 
	defb 0fdh,00fh,00fh,01fh,01fh,01fh,03fh,07fh,005h,0ffh,082h,0fch,0f3h,003h,0f0h,003h	; 8db5  ......?.........
	defb 0e0h,084h,03fh,0c1h,0ffh,0ffh,004h,0a0h,004h,0ffh,004h,07fh,000h	; 8dc5  ..?..........

; ----------------------------------------------------------------------
; DATOS guiones_8DD2: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x8dd2..0x8e12  (64 bytes)
DATA_guiones_8DD2:
	defb 002h,0f1h,002h,031h,004h,0fbh,002h,0b3h,004h,0fbh,003h,0b3h,005h,0fbh,002h,0b3h	; 8dd2  ...1............
	defb 005h,0fbh,00bh,0ebh,005h,0fbh,01dh,0ebh,002h,0edh,004h,0e2h,002h,0ebh,006h,0d2h	; 8de2  ................
	defb 005h,0e3h,003h,0e2h,000h,007h,001h,003h,06dh,07fh,07fh,0ffh,0ffh,0feh,00fh,000h	; 8df2  ........m.......
	defb 001h,038h,07ch,0f6h,0fah,0fah,0feh,0fch,0f0h,0f8h,0f8h,0f8h,0d8h,0b8h,070h,0e0h	; 8e02  .8|...........p.

; ----------------------------------------------------------------------
; DATOS guiones_8E12: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8e12..0x8e29  (23 bytes)
DATA_guiones_8E12:
	defb 000h,001h,008h,010h,020h,040h,000h,003h,001h,007h,000h,004h,0e1h,01eh,000h,006h	; 8e12  .... @..........
	defb 040h,080h,000h,001h,080h,000h,006h	; 8e22

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8E29: Archivo 2: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x8e29..0x8e53  (42 bytes)
DATA_cabecera_de_la_figura_8E29:
	defb 053h,08eh,0f6h,089h,0abh,08eh,080h,08ah	; 8e29  S.......
	defb 004h,003h,012h,006h,003h,011h,006h,018h	; 8e31  ........
	defb 009h,005h,010h,019h,004h,020h,007h,002h	; 8e39  ..... ..
	defb 080h,052h,043h,034h,033h,043h,025h,025h	; 8e41  .RC43C%%
	defb 0b3h,095h,018h,089h,0c9h,08eh,0deh,08eh	; 8e49  ........
	defb 0cfh,08ah	; 8e51

; ----------------------------------------------------------------------
; DATOS guiones_8E53: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8e53..0x8eab  (88 bytes)
DATA_guiones_8E53:
	defb 003h,0ffh,085h,0fch,0f8h,0f8h,007h,003h,004h,000h,082h,008h,019h,002h,000h,08ah	; 8e53  ................
	defb 0feh,0fch,0f8h,0f0h,0f0h,0c0h,080h,000h,01ch,008h,006h,000h,085h,002h,00bh,007h	; 8e63  ................
	defb 023h,033h,003h,03fh,091h,0feh,0fch,0f8h,0f8h,0f8h,0fch,0feh,0feh,0ffh,0feh,0fdh	; 8e73  #3.?............
	defb 0f3h,0fbh,0fch,0feh,0fch,07fh,004h,0ffh,083h,042h,001h,000h,005h,07fh,083h,03fh	; 8e83  .........B.....?
	defb 07fh,0ffh,003h,0feh,005h,0ffh,090h,03ch,0c8h,0f0h,0feh,000h,000h,0afh,0afh,0ffh	; 8e93  .......<........
	defb 000h,000h,0ffh,03fh,00fh,0ffh,0ffh,000h	; 8ea3  ...?....

; ----------------------------------------------------------------------
; DATOS guiones_8EAB: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x8eab..0x8ede  (51 bytes)
DATA_guiones_8EAB:
	defb 002h,031h,004h,0fbh,004h,0b3h,006h,0fbh,005h,0fbh,003h,0ebh,00dh,0fbh,00ah,0ebh	; 8eab  .1..............
	defb 081h,0e6h,010h,0b6h,002h,0ebh,003h,0e6h,00bh,0ebh,004h,0b6h,00ch,0edh,000h,005h	; 8ebb  ................
	defb 001h,001h,003h,003h,007h,007h,001h,000h,009h,0bch,0feh,0ffh,0ffh,0fbh,0e7h,0feh	; 8ecb  ................
	defb 03ch,000h,003h	; 8edb

; ----------------------------------------------------------------------
; DATOS guiones_8EDE: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8ede..0x8eeb  (13 bytes)
DATA_guiones_8EDE:
	defb 000h,006h,03ch,07eh,0fbh,0fdh,0fdh,0fdh,0ffh,07fh,03eh,000h,011h	; 8ede  ..<~......>..

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_8EEB: Archivo 2: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0x8eeb..0x8f1a  (47 bytes)
DATA_cabecera_de_la_figura_8EEB:
	defb 01ah,08fh,0d3h,08fh,0d4h,08fh,032h,090h	; 8eeb  ......2.
	defb 005h,000h,010h,006h,000h,010h,006h,010h	; 8ef3  ........
	defb 018h,005h,010h,008h,006h,020h,008h,00dh	; 8efb  ..... ..
	defb 030h,010h,009h,043h,025h,034h,043h,043h	; 8f03  0..C%4CC
	defb 043h,034h,034h,0d0h,095h,033h,090h,053h	; 8f0b  C44..3.S
	defb 090h,060h,090h,077h,090h,086h,090h	; 8f13

; ----------------------------------------------------------------------
; DATOS guiones_8F1A: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8f1a..0x8fd4  (186 bytes)
DATA_guiones_8F1A:
	defb 002h,0ffh,002h,000h,003h,0ffh,091h,0f0h,0ffh,0ffh,000h,000h,0ffh,0e7h,0c6h,039h	; 8f1a  ...............9
	defb 0ffh,0ffh,000h,000h,00fh,00fh,047h,0cfh,005h,0ffh,087h,0feh,001h,001h,000h,003h	; 8f2a  ......G.........
	defb 0e0h,080h,003h,000h,083h,0fch,0dfh,001h,004h,000h,084h,023h,0f2h,03fh,01fh,003h	; 8f3a  ...........#.?..
	defb 09fh,08eh,01fh,01fh,03fh,0f8h,0f8h,017h,05fh,03fh,01fh,060h,080h,000h,080h,0e0h	; 8f4a  ....?..._?.`....
	defb 005h,0ffh,003h,0ffh,081h,0cfh,004h,0c0h,008h,0ffh,002h,03fh,081h,07fh,005h,0ffh	; 8f5a  ...........?....
	defb 004h,0c0h,003h,0e0h,083h,0f0h,0ffh,0ffh,006h,001h,085h,0ffh,0ffh,073h,007h,08fh	; 8f6a  .............s..
	defb 003h,0ffh,002h,0f0h,002h,0e5h,004h,0cah,002h,001h,006h,000h,004h,0ffh,002h,07fh	; 8f7a  ................
	defb 002h,03fh,002h,0cah,005h,0e0h,08ch,0f0h,001h,007h,0efh,0efh,0efh,01ch,01eh,01eh	; 8f8a  .?..............
	defb 01fh,00fh,007h,005h,003h,007h,0ffh,092h,0feh,0f0h,0f0h,0e0h,0c0h,080h,000h,007h	; 8f9a  ................
	defb 001h,01ch,01fh,01fh,01fh,03fh,07fh,0ffh,0ffh,007h,007h,0ffh,002h,0feh,002h,0fch	; 8faa  .....?..........
	defb 002h,0f8h,002h,0f0h,088h,00fh,007h,01fh,01fh,0f0h,0fch,0feh,000h,003h,0ffh,003h	; 8fba  ................
	defb 000h,081h,00fh,005h,0ffh,081h,000h,003h,0ffh,000h	; 8fca  ..........

; ----------------------------------------------------------------------
; DATOS guiones_8FD4: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x8fd4..0x9033  (95 bytes)
DATA_guiones_8FD4:
	defb 004h,0f3h,004h,0f5h,004h,0f3h,003h,0fbh,081h,0b5h,004h,0f3h,004h,0fbh,002h,031h	; 8fd4  ...............1
	defb 004h,0fbh,004h,0b3h,005h,0fbh,081h,0b6h,081h,053h,00fh,0b5h,002h,0b3h,004h,0fbh	; 8fe4  .........S......
	defb 002h,0b3h,005h,0fbh,003h,0ebh,004h,0b6h,081h,0fbh,003h,0ebh,008h,0b0h,005h,0fbh	; 8ff4  ................
	defb 003h,0e1h,008h,0ebh,002h,0b1h,00eh,0ebh,002h,0edh,006h,0e2h,002h,0edh,010h,0e2h	; 9004  ................
	defb 006h,0ebh,002h,0b2h,003h,0b6h,00bh,0ebh,008h,0e9h,005h,0ebh,003h,0e9h,005h,0ebh	; 9014  ................
	defb 003h,0e9h,008h,0ebh,007h,0e9h,081h,0e1h,004h,0e9h,004h,091h,010h,0e1h,000h	; 9024  ...............

; ----------------------------------------------------------------------
; DATOS guiones_9033: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9033..0x9053  (32 bytes)
DATA_guiones_9033:
	defb 01fh,03fh,07fh,0ffh,0ffh,0e7h,0c6h,046h,004h,000h,003h,002h,001h,000h,002h,0e0h	; 9033  .?.....F........
	defb 0f0h,0f8h,0fch,0dch,08ch,020h,020h,000h,003h,040h,020h,000h,001h,080h,000h,001h	; 9043  .....  ..@ .....

; ----------------------------------------------------------------------
; DATOS guiones_9053: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9053..0x9060  (13 bytes)
DATA_guiones_9053:
	defb 000h,002h,078h,0fch,0feh,0f6h,0fah,0fah,0feh,0fch,078h,000h,015h	; 9053  ..x.......x..

; ----------------------------------------------------------------------
; DATOS guiones_9060: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9060..0x9077  (23 bytes)
DATA_guiones_9060:
	defb 000h,003h,030h,008h,004h,004h,003h,000h,00ah,002h,002h,002h,002h,002h,0c2h,000h	; 9060  ..0.............
	defb 002h,001h,021h,040h,080h,080h,080h	; 9070

; ----------------------------------------------------------------------
; DATOS guiones_9077: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9077..0x9086  (15 bytes)
DATA_guiones_9077:
	defb 000h,002h,005h,005h,00ah,00ah,00ah,00ah,00ah,00ah,000h,00fh,010h,000h,006h	; 9077  ...............

; ----------------------------------------------------------------------
; DATOS guiones_9086: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9086..0x90a1  (27 bytes)
DATA_guiones_9086:
	defb 000h,001h,003h,003h,003h,003h,007h,007h,00fh,00fh,00fh,00fh,000h,006h,0f8h,0c0h	; 9086  ................
	defb 0f0h,0c0h,0e0h,0e0h,0f0h,0fch,0feh,0ffh,0ffh,000h,004h	; 9096  ...........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_90A1: Archivo 2: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x90a1..0x90cb  (42 bytes)
DATA_cabecera_de_la_figura_90A1:
	defb 0cbh,090h,085h,091h,086h,091h,0f0h,091h	; 90a1  ........
	defb 004h,017h,0ffh,006h,017h,0ffh,006h,017h	; 90a9  ........
	defb 0ffh,00fh,030h,008h,002h,030h,018h,009h	; 90b1  ..0..0..
	defb 080h,080h,080h,032h,015h,017h,008h,007h	; 90b9  ...2....
	defb 0f0h,095h,0f1h,091h,012h,092h,01eh,092h	; 90c1  ........
	defb 034h,092h	; 90c9

; ----------------------------------------------------------------------
; DATOS guiones_90CB: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x90cb..0x9186  (187 bytes)
DATA_guiones_90CB:
	defb 00dh,0ffh,083h,0efh,00fh,06bh,006h,0ffh,002h,0feh,084h,0c1h,0c0h,080h,080h,004h	; 90cb  .....k..........
	defb 000h,007h,0ffh,089h,0fch,001h,0ffh,0ffh,0fch,0feh,0ffh,0ffh,01fh,006h,0ffh,002h	; 90db  ................
	defb 07fh,002h,0feh,003h,0fch,003h,0f8h,0a1h,0ffh,0fch,002h,007h,00fh,00fh,01fh,01fh	; 90eb  ................
	defb 07fh,03fh,0dfh,0e3h,0ffh,080h,0c0h,0e0h,0ffh,0ffh,002h,021h,040h,040h,044h,043h	; 90fb  .?.........!@@DC
	defb 03fh,03fh,03eh,01ch,018h,060h,0e0h,0c0h,080h,005h,0ffh,083h,0dfh,0bfh,080h,007h	; 910b  ??>..`..........
	defb 0c0h,005h,0ffh,083h,0fch,0f8h,0f1h,003h,0f0h,002h,0e0h,003h,000h,006h,03fh,002h	; 911b  ..............?.
	defb 07fh,090h,0f8h,0fch,0fch,0feh,0fch,0f0h,0e0h,0c0h,04fh,03fh,0ffh,03fh,0ffh,01fh	; 912b  ..........O?.?..
	defb 00fh,007h,004h,0c0h,088h,0e0h,0e1h,0ffh,0ffh,0bfh,03fh,03fh,07fh,004h,0ffh,081h	; 913b  ..........??....
	defb 03fh,007h,0ffh,085h,0f2h,0f2h,0f8h,0f8h,0fch,003h,0ffh,085h,000h,000h,00ch,010h	; 914b  ?...............
	defb 000h,003h,0ffh,003h,080h,085h,078h,0fch,0feh,0ffh,0ffh,08ch,080h,07fh,07fh,07fh	; 915b  ......x.........
	defb 03fh,01fh,080h,0ffh,001h,0c0h,080h,010h,003h,014h,083h,0ffh,0ffh,0c0h,005h,0ffh	; 916b  ?...............
	defb 089h,000h,0ffh,0ffh,07fh,03fh,03fh,03fh,080h,000h,000h	; 917b  .....???...

; ----------------------------------------------------------------------
; DATOS guiones_9186: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9186..0x91f1  (107 bytes)
DATA_guiones_9186:
	defb 005h,0ebh,003h,0b1h,018h,0ebh,008h,0b6h,081h,0ebh,007h,0b6h,007h,0ebh,081h,0e6h	; 9186  ................
	defb 008h,0ebh,002h,0b6h,006h,0ebh,005h,0b6h,003h,0ebh,002h,0b6h,006h,0dbh,005h,0ebh	; 9196  ................
	defb 003h,0dbh,081h,0ebh,007h,0b6h,008h,0beh,008h,0e5h,003h,0ebh,005h,0e5h,003h,0ebh	; 91a6  ................
	defb 005h,0e5h,003h,0ebh,002h,0edh,003h,0ebh,003h,0dbh,082h,0edh,0e1h,003h,0ebh,008h	; 91b6  ................
	defb 0ebh,081h,0b6h,00fh,0ebh,004h,0e5h,004h,0e1h,004h,0e5h,004h,0e1h,003h,051h,005h	; 91c6  ..............Q.
	defb 0e1h,081h,0ebh,005h,0b1h,002h,0e1h,081h,0e9h,002h,0b9h,005h,0e9h,082h,0e1h,0e9h	; 91d6  ................
	defb 005h,098h,081h,091h,002h,0e1h,004h,0e9h,002h,091h,000h	; 91e6  ...........

; ----------------------------------------------------------------------
; DATOS guiones_91F1: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x91f1..0x9212  (33 bytes)
DATA_guiones_91F1:
	defb 00fh,03fh,03fh,07fh,07fh,07fh,05eh,018h,012h,002h,000h,001h,040h,008h,008h,005h	; 91f1  .??...^.....@...
	defb 002h,0f8h,0fch,0feh,0ffh,0ffh,0ffh,0f6h,006h,024h,024h,044h,024h,004h,0ech,0e8h	; 9201  .........$$D$...
	defb 008h	; 9211

; ----------------------------------------------------------------------
; DATOS guiones_9212: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9212..0x921e  (12 bytes)
DATA_guiones_9212:
	defb 000h,008h,001h,001h,003h,000h,00dh,010h,010h,030h,000h,005h	; 9212  .........0..

; ----------------------------------------------------------------------
; DATOS guiones_921E: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x921e..0x9234  (22 bytes)
DATA_guiones_921E:
	defb 001h,003h,007h,03fh,0ffh,01fh,00fh,007h,001h,000h,007h,0c0h,0c0h,0c0h,0c0h,0e0h	; 921e  ...?............
	defb 0e0h,0fch,0f8h,0c0h,000h,007h	; 922e

; ----------------------------------------------------------------------
; DATOS guiones_9234: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9234..0x9257  (35 bytes)
DATA_guiones_9234:
	defb 000h,001h,03fh,03fh,038h,03fh,03ch,01fh,01fh,01fh,01fh,01fh,03fh,03fh,03fh,03fh	; 9234  ..??8?<.....????
	defb 03fh,000h,001h,0c0h,0c0h,000h,001h,0c0h,040h,0c0h,0c0h,0c0h,0c0h,0e0h,0f0h,0f8h	; 9244  ?.......@.......
	defb 0feh,0ffh,0ffh	; 9254

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9257: Archivo 2: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0x9257..0x9286  (47 bytes)
DATA_cabecera_de_la_figura_9257:
	defb 086h,092h,0d5h,086h,0dch,092h,06bh,087h	; 9257  ......k.
	defb 005h,000h,004h,006h,000h,004h,006h,010h	; 925f  ........
	defb 018h,004h,010h,004h,005h,020h,00dh,002h	; 9267  ..... ..
	defb 030h,001h,009h,041h,034h,034h,034h,043h	; 926f  0..A444C
	defb 044h,053h,035h,010h,096h,013h,093h,037h	; 9277  DS5....7
	defb 093h,04dh,093h,0d4h,087h,0e8h,087h	; 927f

; ----------------------------------------------------------------------
; DATOS guiones_9286: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9286..0x92dc  (86 bytes)
DATA_guiones_9286:
	defb 006h,0ffh,082h,09fh,007h,096h,001h,080h,0feh,0feh,0feh,0efh,044h,000h,070h,070h	; 9286  ............D.pp
	defb 070h,000h,080h,0e0h,01fh,0d7h,080h,0c0h,03fh,03fh,07fh,011h,004h,000h,004h,0ffh	; 9296  p.......??......
	defb 08ch,000h,080h,0ffh,0f8h,0f0h,0f0h,0e0h,0e0h,0e0h,0c3h,0efh,01fh,004h,0ffh,08ah	; 92a6  ................
	defb 0e0h,0f0h,0ffh,0ffh,0efh,0f7h,0f7h,0f7h,0f6h,01fh,006h,03fh,002h,07fh,081h,0c7h	; 92b6  ...........?....
	defb 005h,08fh,082h,0cfh,0ffh,004h,0f8h,004h,0fch,083h,0ffh,0ffh,0edh,004h,0deh,083h	; 92c6  ................
	defb 0ffh,07fh,07fh,006h,03fh,000h	; 92d6

; ----------------------------------------------------------------------
; DATOS guiones_92DC: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x92dc..0x9337  (91 bytes)
DATA_guiones_92DC:
	defb 002h,0f1h,002h,031h,004h,0fbh,088h,0b3h,063h,0fbh,0fbh,0fbh,0f6h,063h,063h,006h	; 92dc  ...1....c....cc.
	defb 0fbh,004h,0b3h,006h,0fbh,007h,0f3h,081h,0b3h,005h,0fbh,003h,0ebh,006h,0b6h,002h	; 92ec  ................
	defb 0ebh,008h,0b6h,005h,0fbh,002h,0e6h,009h,0ebh,081h,0e6h,006h,0ebh,081h,0edh,007h	; 92fc  ................
	defb 0b6h,081h,0dbh,007h,0ebh,081h,0edh,000h,001h,007h,01fh,03fh,07fh,07fh,079h,030h	; 930c  ...........?..y0
	defb 004h,004h,000h,001h,080h,000h,001h,006h,006h,002h,000h,001h,0c0h,0f0h,0f8h,0fch	; 931c  ................
	defb 0fch,0feh,07eh,066h,062h,022h,022h,004h,000h,002h,080h	; 932c  ..~fb""....

; ----------------------------------------------------------------------
; DATOS guiones_9337: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9337..0x934d  (22 bytes)
DATA_guiones_9337:
	defb 000h,003h,01eh,03fh,03dh,07eh,07eh,07eh,07fh,03fh,01fh,00eh,000h,008h,080h,080h	; 9337  ...?=~~~.?......
	defb 080h,080h,080h,080h,000h,005h	; 9347

; ----------------------------------------------------------------------
; DATOS guiones_934D: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x934d..0x9362  (21 bytes)
DATA_guiones_934D:
	defb 000h,006h,00eh,03fh,07dh,0feh,0feh,0ffh,0ffh,0ffh,0feh,0e0h,000h,008h,080h,080h	; 934d  ...?}...........
	defb 080h,080h,080h,000h,003h	; 935d

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9362: Archivo 2: cuatro punteros de fondo, 2
;   piezas de tres bytes y sus 2 punteros; mide 17 + 5*2 = 27
;   0x9362..0x937d  (27 bytes)
DATA_cabecera_de_la_figura_9362:
	defb 07dh,093h,08dh,094h,08eh,094h,01ch,095h	; 9362  }.......
	defb 001h,000h,008h,006h,000h,008h,006h,026h	; 936a  .......&
	defb 026h,026h,042h,034h,034h,034h,026h,033h	; 9372  &&B444&3
	defb 096h,01dh,095h	; 937a

; ----------------------------------------------------------------------
; DATOS guiones_937D: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x937d..0x948e  (273 bytes)
DATA_guiones_937D:
	defb 08ch,0e1h,0c0h,07fh,0ffh,040h,040h,020h,002h,0ffh,0ffh,080h,0c0h,004h,03fh,006h	; 937d  .....@@ ......?.
	defb 0ffh,082h,0f7h,007h,005h,0ffh,087h,0f7h,0e7h,085h,0ffh,0ffh,001h,003h,004h,0fch	; 938d  ................
	defb 0b8h,087h,003h,0feh,0ffh,002h,002h,004h,040h,0fdh,0feh,080h,0c0h,0c0h,0c0h,01fh	; 939d  ........@.......
	defb 01fh,080h,000h,0ffh,07fh,07fh,07fh,001h,0bfh,07fh,08ch,086h,0e2h,0e0h,0e4h,0e8h	; 93ad  ................
	defb 0e6h,0feh,0ceh,061h,047h,007h,027h,017h,067h,0feh,0ffh,0ffh,0feh,0feh,0feh,080h	; 93bd  ...aG.'.g.......
	defb 0fdh,0bfh,07fh,001h,003h,003h,003h,0f8h,0f8h,003h,0e0h,087h,0f0h,0f0h,0f8h,0fch	; 93cd  ................
	defb 0ffh,0bfh,0bfh,004h,0ffh,085h,0feh,0feh,0f3h,0f8h,0ffh,004h,0feh,084h,07eh,0cfh	; 93dd  ..............~.
	defb 01fh,0ffh,004h,07fh,083h,07eh,0fdh,0fdh,004h,0ffh,002h,07fh,003h,007h,095h,00fh	; 93ed  .....~..........
	defb 00fh,01fh,03fh,0ffh,07eh,07fh,01fh,0f9h,0f3h,0e7h,0cfh,07fh,07eh,0feh,0f8h,09fh	; 93fd  ..?.~.......~...
	defb 0cfh,0e7h,0f3h,0feh,005h,0ffh,003h,0feh,005h,080h,083h,000h,004h,002h,005h,001h	; 940d  ................
	defb 083h,000h,020h,040h,005h,0ffh,003h,07fh,002h,0feh,002h,0fch,002h,0f8h,002h,0f0h	; 941d  .. @............
	defb 003h,001h,085h,003h,003h,007h,007h,00fh,003h,080h,085h,0c0h,0c0h,0e0h,0e0h,0f0h	; 942d  ................
	defb 002h,07fh,002h,03fh,002h,01fh,002h,00fh,088h,0f0h,0f0h,0e0h,0e0h,0feh,0e0h,0f8h	; 943d  ...?............
	defb 0c0h,005h,01fh,083h,03fh,03fh,07fh,005h,0f8h,08bh,0fch,0fch,0feh,00fh,00fh,007h	; 944d  ....??..........
	defb 007h,07fh,007h,01fh,003h,004h,0ffh,08ch,0feh,0f8h,0e0h,0c0h,0c0h,0c0h,081h,081h	; 945d  ................
	defb 001h,0feh,0feh,000h,004h,0ffh,081h,0e0h,003h,000h,004h,0ffh,081h,007h,003h,000h	; 946d  ................
	defb 088h,003h,003h,081h,081h,080h,07fh,07fh,000h,004h,0ffh,084h,07fh,01fh,007h,007h	; 947d  ................
	defb 000h	; 948d

; ----------------------------------------------------------------------
; DATOS guiones_948E: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x948e..0x951d  (143 bytes)
DATA_guiones_948E:
	defb 002h,0f5h,002h,053h,006h,0f5h,002h,053h,006h,0f5h,002h,031h,002h,0f1h,004h,0fbh	; 948e  ...S...S...1....
	defb 002h,031h,006h,0fbh,002h,053h,006h,0f5h,002h,053h,004h,0f5h,002h,053h,004h,0f5h	; 949e  .1...S...S...S..
	defb 002h,0b3h,002h,053h,004h,0f5h,003h,0b3h,005h,0fbh,004h,0b3h,004h,0fbh,002h,0b3h	; 94ae  ...S............
	defb 002h,035h,004h,0f5h,002h,0b3h,002h,053h,004h,0f5h,002h,0b3h,005h,0fbh,003h,0ebh	; 94be  .5.....S........
	defb 006h,0b6h,002h,0e6h,016h,0b6h,002h,0e6h,005h,0fbh,003h,0ebh,007h,0b6h,081h,0beh	; 94ce  ................
	defb 007h,0b6h,081h,0beh,00ah,0edh,006h,0d2h,002h,0edh,006h,0d2h,009h,0edh,007h,0ebh	; 94de  ................
	defb 081h,0d2h,007h,0ebh,081h,0d2h,007h,0ebh,081h,0edh,009h,0ebh,006h,0e9h,002h,0ebh	; 94ee  ................
	defb 006h,0e9h,002h,0ebh,006h,0e9h,002h,0ebh,006h,0e9h,004h,0e1h,003h,0e9h,081h,0e1h	; 94fe  ................
	defb 005h,0e9h,002h,091h,011h,0e1h,005h,0e9h,003h,091h,007h,0e9h,081h,0e1h,000h	; 950e  ...............

; ----------------------------------------------------------------------
; DATOS guiones_951D: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x951d..0x953d  (32 bytes)
DATA_guiones_951D:
	defb 00fh,01fh,03fh,07fh,07fh,0ffh,0f7h,0a7h,080h,082h,082h,0e0h,060h,004h,017h,019h	; 951d  ..?.........`...
	defb 0f8h,0fch,0feh,0feh,0ffh,0f7h,0e7h,085h,001h,031h,061h,047h,006h,020h,0e8h,098h	; 952d  .........1aG. ..

; ----------------------------------------------------------------------
; DATOS guiones_953D: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x953d..0x9558  (27 bytes)
DATA_guiones_953D:
	defb 00fh,01fh,03fh,03fh,07fh,07fh,07fh,07fh,07eh,07eh,07fh,07bh,029h,000h,003h,0f0h	; 953d  ..??....~~.{)...
	defb 0fch,0ffh,0ffh,0ffh,0c6h,010h,010h,000h,006h,040h,020h	; 954d  .........@ 

; ----------------------------------------------------------------------
; DATOS guiones_9558: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9558..0x9578  (32 bytes)
DATA_guiones_9558:
	defb 000h,001h,00fh,01fh,03fh,03fh,07fh,07fh,07fh,07fh,07eh,07eh,07fh,07bh,029h,000h	; 9558  ....??....~~.{).
	defb 003h,0f0h,0fch,0ffh,0ffh,0ffh,0c6h,010h,010h,000h,003h,020h,010h,000h,001h,040h	; 9568  ........... ...@

; ----------------------------------------------------------------------
; DATOS guiones_9578: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9578..0x959a  (34 bytes)
DATA_guiones_9578:
	defb 000h,001h,00fh,01fh,03fh,07fh,0ffh,0ffh,0ffh,0dch,099h,091h,098h,0c8h,061h,001h	; 9578  ....?.........a.
	defb 000h,002h,0e0h,0feh,0ffh,0ffh,0f7h,0f7h,086h,004h,014h,01eh,026h,016h,003h,0f0h	; 9588  ............&...
	defb 000h,001h	; 9598

; ----------------------------------------------------------------------
; DATOS guiones_959A: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x959a..0x95b3  (25 bytes)
DATA_guiones_959A:
	defb 000h,005h,00fh,01fh,03fh,03fh,07fh,07fh,07fh,0ffh,0feh,0feh,0ach,000h,005h,0f0h	; 959a  ....??..........
	defb 0fch,0ffh,0ffh,0ffh,0c6h,010h,010h,000h,003h	; 95aa  .........

; ----------------------------------------------------------------------
; DATOS guiones_95B3: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x95b3..0x95d0  (29 bytes)
DATA_guiones_95B3:
	defb 000h,003h,00fh,01fh,03fh,03fh,07fh,07fh,07fh,07fh,07eh,07eh,07fh,07bh,029h,000h	; 95b3  ....??....~~.{).
	defb 003h,0f0h,0fch,0ffh,0ffh,0ffh,0c6h,010h,010h,000h,003h,020h,010h	; 95c3  ........... .

; ----------------------------------------------------------------------
; DATOS guiones_95D0: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x95d0..0x95f0  (32 bytes)
DATA_guiones_95D0:
	defb 01fh,03fh,07fh,07fh,0ffh,0ffh,0feh,07eh,03ch,01ch,01eh,016h,012h,000h,003h,0e0h	; 95d0  .?.....~<.......
	defb 0f8h,0feh,0feh,0feh,08ch,020h,020h,000h,003h,040h,020h,000h,001h,080h,000h,001h	; 95e0  .....  ..@ .....

; ----------------------------------------------------------------------
; DATOS guiones_95F0: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x95f0..0x9610  (32 bytes)
DATA_guiones_95F0:
	defb 00fh,03fh,03fh,07fh,07fh,07fh,07eh,0f8h,0fah,0fah,0f0h,0f8h,07ch,07ch,02dh,00ah	; 95f0  .??...~.....||-.
	defb 0f8h,0fch,0feh,0ffh,0ffh,0ffh,0f7h,007h,026h,026h,046h,024h,004h,0ech,0e8h,008h	; 9600  ........&&F$....

; ----------------------------------------------------------------------
; DATOS guiones_9610: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9610..0x9633  (35 bytes)
DATA_guiones_9610:
	defb 000h,001h,003h,00fh,03fh,07fh,07fh,07fh,031h,004h,004h,020h,0e0h,000h,001h,006h	; 9610  ....?...1.. ....
	defb 006h,002h,000h,001h,0f0h,0fch,0feh,0ffh,0ffh,0ffh,0ffh,07fh,07fh,03fh,07fh,0deh	; 9620  .............?..
	defb 00ch,018h,080h	; 9630

; ----------------------------------------------------------------------
; DATOS guiones_9633: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9633..0x9653  (32 bytes)
DATA_guiones_9633:
	defb 00fh,01fh,03fh,07fh,07fh,0ffh,0ffh,0f7h,0e0h,0e2h,0e2h,0e0h,0e0h,0e4h,0b7h,039h	; 9633  ..?............9
	defb 0f0h,0f8h,0fch,0feh,0feh,0ffh,0efh,0a7h,007h,037h,067h,047h,007h,027h,0edh,09ch	; 9643  .........7gG.'..

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9653: La figura 18 de los archivos 2, 3 y 4, la
;   vacia: cuatro punteros de fondo a 0x966E, 1 pieza declarada pero 2
;   registros -el de mas que el rival lleva siempre-, los ocho de disposicion
;   y sus 2 punteros, los dos a 0x966E; mide 17 + 5*2 = 27
;   0x9653..0x966e  (27 bytes)
DATA_cabecera_de_la_figura_9653:
	defb 06eh,096h,06eh,096h,06eh,096h,06eh,096h	; 9653  n.n.n.n.
	defb 001h,0a0h,000h,000h,0a0h,000h,000h,080h	; 965b  ........
	defb 080h,080h,080h,080h,080h,080h,080h,06eh	; 9663  .......n
	defb 096h,06eh,096h	; 966b

; ----------------------------------------------------------------------
; DATOS pieza_vacia_del_archivo_3: `00 20`: leido como guion de figura es un
;   0x00, se acabo, y leido como pieza son treinta y dos ceros, un sprite en
;   blanco. Los cuatro guiones de fondo y las dos piezas de 0x9653 apuntan
;   aqui
;   0x966e..0x9670  (2 bytes)
DATA_pieza_vacia_del_archivo_3:
	defb 000h,020h	; 966e

; ----------------------------------------------------------------------
; DATOS punteros_del_archivo_3: Las 19 figuras del archivo 3. La tabla la
;   cierra su entrada mas baja, y los cuatro archivos dan 19 clavadas
;   0x9670..0x9696  (38 bytes)
DATA_punteros_del_archivo_3:
	defw 09957h,09a40h,09696h,09825h,09aedh,09cdah,09e68h,09f5ch	; 9670
	defw 0a0e0h,0a1e1h,0a378h,0a510h,09a40h,0a66dh,09a40h,0a7d2h	; 9680
	defw 0a7d2h,0a93ch,09653h	; 9690  -> DATA_cabecera_de_la_figura_A7D2 DATA_cabecera_de_la_figura_A93C DATA_cabecera_de_la_figura_9653

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9696: Archivo 3: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x9696..0x96bb  (37 bytes)
DATA_cabecera_de_la_figura_9696:
	defb 0bbh,096h,06eh,097h,06fh,097h,0d1h,097h	; 9696  ..n.o...
	defb 003h,0f8h,011h,001h,002h,018h,001h,008h	; 969e  ........
	defb 020h,004h,020h,00ch,007h,053h,044h,044h	; 96a6   . ..SDD
	defb 044h,043h,044h,034h,034h,020h,0abh,0d1h	; 96ae  DCD44 ..
	defb 097h,0eeh,097h,03dh,099h	; 96b6

; ----------------------------------------------------------------------
; DATOS guiones_96BB: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x96bb..0x976f  (180 bytes)
DATA_guiones_96BB:
	defb 006h,0ffh,092h,0feh,0fch,0ffh,0e0h,03fh,07fh,080h,001h,078h,058h,0ffh,01fh,0f8h	; 96bb  .......?...xX...
	defb 0fch,0e1h,0f1h,009h,077h,003h,0ffh,088h,0feh,0fch,0fch,007h,007h,00fh,03fh,080h	; 96cb  ....w.........?.
	defb 003h,000h,092h,001h,000h,0b3h,0b3h,07ch,03ch,01eh,01eh,0cfh,02fh,0fch,0feh,00fh	; 96db  .......|<.../...
	defb 01fh,03fh,03fh,03fh,000h,002h,0f0h,006h,0e0h,008h,000h,088h,017h,013h,008h,006h	; 96eb  .???............
	defb 004h,008h,000h,000h,005h,0ffh,083h,07fh,03fh,00fh,007h,0e0h,085h,0f0h,000h,000h	; 96fb  ........?.......
	defb 006h,001h,008h,000h,089h,080h,0f0h,009h,00fh,00fh,01fh,01fh,03fh,07fh,003h,0ffh	; 970b  ............?...
	defb 083h,0f0h,007h,007h,005h,000h,003h,0ffh,005h,030h,083h,00fh,0f0h,0f0h,005h,0ffh	; 971b  .........0......
	defb 005h,0ffh,003h,0f8h,005h,030h,005h,0ffh,083h,0efh,0c7h,0c7h,003h,047h,008h,0ffh	; 972b  .....0.......G..
	defb 081h,0ffh,007h,0f8h,002h,0fch,003h,007h,083h,003h,003h,009h,008h,000h,003h,047h	; 973b  ...............G
	defb 003h,04fh,082h,0cfh,01fh,005h,0f8h,09bh,0f9h,0fbh,0f8h,024h,014h,07fh,07fh,0ffh	; 974b  .O.........$....
	defb 0ffh,0c0h,000h,0feh,0fch,0c1h,080h,080h,080h,07fh,000h,0ffh,03fh,0ffh,07fh,03fh	; 975b  ............?..?
	defb 00fh,003h,001h,000h	; 976b

; ----------------------------------------------------------------------
; DATOS guiones_976F: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x976f..0x97ee  (127 bytes)
DATA_guiones_976F:
	defb 002h,0f1h,002h,031h,006h,0f6h,002h,063h,006h,0f6h,002h,063h,004h,0f6h,002h,031h	; 976f  ...1...c...c...1
	defb 004h,0f6h,004h,063h,004h,0f6h,002h,0e6h,002h,063h,004h,0f6h,002h,0e6h,002h,063h	; 977f  ...c.....c.....c
	defb 005h,0f6h,081h,063h,005h,0f6h,013h,0e6h,005h,0f1h,003h,0e6h,020h,0e6h,081h,0e6h	; 978f  ...c........ ...
	defb 007h,0feh,081h,061h,002h,0f1h,005h,0feh,081h,0e6h,002h,0feh,005h,0e1h,008h,0e6h	; 979f  ...a............
	defb 005h,0feh,003h,061h,008h,0e6h,008h,0eeh,008h,0e2h,002h,0e6h,006h,062h,00fh,0e6h	; 97af  ...a.........b..
	defb 008h,0e2h,081h,0e1h,004h,0e2h,004h,0e1h,002h,062h,004h,0e2h,002h,021h,007h,0e2h	; 97bf  .........b...!..
	defb 081h,0e1h,000h,003h,001h,078h,058h,04ch,04ch,07ch,03ch,01eh,01eh,00fh,00fh,007h	; 97cf  .....xXLL|<.....
	defb 003h,000h,002h,0e0h,0f0h,008h,014h,000h,005h,040h,000h,001h,0f0h,0c0h,0c0h	; 97df  .........@.....

; ----------------------------------------------------------------------
; DATOS guiones_97EE: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x97ee..0x980b  (29 bytes)
DATA_guiones_97EE:
	defb 000h,002h,00fh,01eh,03fh,02fh,02fh,00fh,03fh,03fh,07fh,0ffh,0feh,07eh,03ch,00ch	; 97ee  ....?//.??...~<.
	defb 000h,002h,080h,0c0h,060h,060h,0e0h,0e0h,0e0h,0c0h,080h,000h,005h	; 97fe  ....``.......

; ----------------------------------------------------------------------
; DATOS guiones_980B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x980b..0x9825  (26 bytes)
DATA_guiones_980B:
	defb 000h,002h,079h,079h,0f9h,0f9h,0f9h,0f9h,0f9h,0f9h,0f9h,0f9h,000h,006h,0ffh,0ffh	; 980b  ..yy............
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0feh,000h,004h	; 981b  ..........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9825: Archivo 3: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x9825..0x984a  (37 bytes)
DATA_cabecera_de_la_figura_9825:
	defb 04ah,098h,0fch,098h,0fdh,098h,03dh,099h	; 9825  J.....=.
	defb 003h,0f7h,011h,001h,001h,018h,001h,007h	; 982d  ........
	defb 020h,004h,020h,00ch,007h,053h,044h,044h	; 9835   . ..SDD
	defb 044h,043h,044h,034h,034h,02eh,0abh,0d1h	; 983d  DCD44...
	defb 097h,0eeh,097h,00bh,098h	; 9845

; ----------------------------------------------------------------------
; DATOS guiones_984A: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x984a..0x98fd  (179 bytes)
DATA_guiones_984A:
	defb 005h,0ffh,0a1h,0feh,0fch,0f0h,0e0h,0c0h,07fh,07fh,001h,078h,058h,04ch,01fh,007h	; 984a  ...........xXL..
	defb 0fch,01eh,0f1h,009h,077h,003h,0ffh,0ffh,0feh,0fch,0fch,0f8h,007h,00fh,03fh,07fh	; 985a  ....w.........?.
	defb 0ffh,0ffh,0ffh,001h,007h,000h,08ch,0c0h,020h,010h,0feh,0f0h,01fh,03fh,07fh,03fh	; 986a  ........ ....?.?
	defb 0ffh,0ffh,0f0h,007h,0e0h,008h,000h,085h,010h,008h,006h,004h,008h,003h,000h,004h	; 987a  ................
	defb 0ffh,084h,07fh,03fh,00fh,00fh,006h,0e0h,085h,0f0h,0f0h,000h,006h,001h,008h,000h	; 988a  ...?............
	defb 089h,080h,0f0h,009h,00fh,00fh,01fh,01fh,03fh,07fh,004h,0ffh,002h,007h,006h,000h	; 989a  ........?.......
	defb 002h,0ffh,006h,060h,002h,0f0h,006h,000h,004h,0ffh,002h,0f0h,002h,0f8h,004h,060h	; 98aa  ...`...........`
	defb 004h,000h,084h,0f7h,0f3h,0e1h,0e0h,004h,040h,004h,0ffh,081h,07fh,003h,03fh,008h	; 98ba  ........@.....?.
	defb 0ffh,098h,0f8h,0f8h,0fch,0f0h,0e0h,0e0h,0c0h,080h,0ffh,0ffh,0feh,0feh,0fch,0fch	; 98ca  ................
	defb 004h,008h,080h,080h,001h,00fh,003h,00fh,007h,001h,008h,0ffh,003h,080h,08dh,0c0h	; 98da  ................
	defb 0c0h,080h,080h,000h,0f8h,018h,0ffh,03fh,00fh,0f8h,0fch,000h,005h,0ffh,083h,01fh	; 98ea  .......?........
	defb 003h,000h,000h	; 98fa

; ----------------------------------------------------------------------
; DATOS guiones_98FD: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x98fd..0x9957  (90 bytes)
DATA_guiones_98FD:
	defb 002h,0f1h,002h,031h,006h,0f6h,002h,063h,006h,0f6h,002h,063h,004h,0f6h,002h,031h	; 98fd  ...1...c...c...1
	defb 004h,0f6h,007h,063h,00bh,0e6h,002h,063h,004h,0f6h,002h,031h,005h,0f6h,013h,0e6h	; 990d  ...c...c...1....
	defb 004h,0f1h,081h,0f6h,023h,0e6h,018h,0feh,008h,0e6h,004h,0feh,022h,0e6h,002h,0e2h	; 991d  ....#......."...
	defb 006h,062h,002h,0e2h,002h,0e6h,015h,0e2h,081h,0e1h,005h,0e2h,005h,021h,006h,0e1h	; 992d  .b...........!..
	defb 000h,003h,07ch,07ch,0fch,0fch,0fch,0fch,0fch,0fch,0fch,0fch,000h,006h,0ffh,0ffh	; 993d  ..||............
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0fch,0f8h,000h,003h	; 994d  ..........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9957: Archivo 3: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x9957..0x997c  (37 bytes)
DATA_cabecera_de_la_figura_9957:
	defb 07ch,099h,01bh,097h,0dch,099h,09dh,097h	; 9957  |.......
	defb 003h,0f8h,011h,001h,002h,018h,001h,010h	; 995f  ........
	defb 020h,004h,020h,00ch,007h,053h,044h,044h	; 9967   . ..SDD
	defb 044h,043h,044h,034h,034h,020h,0abh,005h	; 996f  DCD44 ..
	defb 09ah,024h,09ah,03dh,099h	; 9977

; ----------------------------------------------------------------------
; DATOS guiones_997C: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x997c..0x99dc  (96 bytes)
DATA_guiones_997C:
	defb 006h,0ffh,092h,0feh,0fch,0ffh,0e0h,03fh,07fh,080h,001h,070h,058h,0ffh,01fh,0f8h	; 997c  .......?...pX...
	defb 0fch,0e1h,0f1h,009h,077h,003h,0ffh,088h,0feh,0fch,0fch,007h,007h,00fh,03fh,080h	; 998c  ....w.........?.
	defb 005h,000h,090h,0b7h,0b3h,07ch,03ch,03ch,021h,080h,0e0h,0fch,0feh,000h,01fh,03fh	; 999c  .....|<<!......?
	defb 073h,0fch,0ffh,002h,0f0h,006h,0e0h,008h,000h,090h,01fh,017h,010h,030h,008h,009h	; 99ac  s............0..
	defb 006h,000h,0ffh,0ffh,03fh,07fh,0ffh,0ffh,01fh,01fh,007h,0e0h,085h,0f0h,008h,004h	; 99bc  ....?...........
	defb 002h,001h,008h,000h,084h,080h,060h,011h,00fh,005h,01fh,083h,03fh,0ffh,0ffh,000h	; 99cc  ......`.....?...

; ----------------------------------------------------------------------
; DATOS guiones_99DC: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x99dc..0x9a24  (72 bytes)
DATA_guiones_99DC:
	defb 002h,0f1h,002h,031h,006h,0f6h,002h,063h,006h,0f6h,002h,063h,004h,0f6h,002h,031h	; 99dc  ...1...c...c...1
	defb 004h,0f6h,004h,063h,006h,0f6h,002h,063h,003h,0f6h,005h,06eh,004h,0f6h,082h,063h	; 99ec  ...c...c...n...c
	defb 031h,005h,0f6h,013h,0e6h,005h,0f6h,023h,0e6h,000h,003h,001h,070h,058h,048h,04ch	; 99fc  1......#....pXHL
	defb 07ch,03ch,03ch,01eh,01fh,00fh,00fh,007h,000h,002h,0e0h,0f0h,008h,014h,000h,003h	; 9a0c  |<<.............
	defb 01eh,03eh,070h,000h,001h,0feh,0feh,0fch	; 9a1c  .>p.....

; ----------------------------------------------------------------------
; DATOS guiones_9A24: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9a24..0x9a40  (28 bytes)
DATA_guiones_9A24:
	defb 000h,002h,039h,07dh,0f6h,0e7h,01fh,01fh,01fh,01fh,01fh,01fh,01ch,000h,004h,0f8h	; 9a24  ..9}............
	defb 0ech,0f4h,0f6h,0feh,0feh,0feh,0feh,0fch,0f8h,0c0h,000h,004h	; 9a34  ............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9A40: Archivo 3: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0x9a40..0x9a65  (37 bytes)
DATA_cabecera_de_la_figura_9A40:
	defb 065h,09ah,0a6h,098h,0c6h,09ah,023h,099h	; 9a40  e.....#.
	defb 003h,0f7h,011h,001h,001h,018h,001h,00fh	; 9a48  ........
	defb 020h,004h,020h,00ch,007h,053h,044h,044h	; 9a50   . ..SDD
	defb 044h,043h,044h,034h,034h,02eh,0abh,005h	; 9a58  DCD44...
	defb 09ah,024h,09ah,00bh,098h	; 9a60

; ----------------------------------------------------------------------
; DATOS guiones_9A65: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9a65..0x9ac6  (97 bytes)
DATA_guiones_9A65:
	defb 005h,0ffh,093h,0feh,0fch,0f0h,0e0h,0c0h,07fh,07fh,001h,070h,058h,048h,01fh,007h	; 9a65  ...........pXH..
	defb 0fch,01eh,0f1h,009h,077h,003h,08ah,0ffh,0ffh,0feh,0fch,0fch,0f8h,007h,00fh,03fh	; 9a75  ....w..........?
	defb 07fh,006h,0ffh,091h,0b3h,083h,03ch,03ch,0deh,07fh,01fh,01fh,0feh,0ffh,01fh,03fh	; 9a85  ......<<.......?
	defb 073h,003h,0ffh,0ffh,0f0h,007h,0e0h,007h,000h,08eh,008h,017h,010h,030h,008h,009h	; 9a95  s............0..
	defb 006h,000h,000h,0ffh,03fh,07fh,0ffh,0ffh,003h,01fh,006h,0e0h,002h,0f0h,083h,004h	; 9aa5  ....?...........
	defb 002h,001h,008h,000h,085h,080h,060h,011h,00fh,00fh,004h,01fh,081h,03fh,003h,0ffh	; 9ab5  ......`......?..
	defb 000h	; 9ac5

; ----------------------------------------------------------------------
; DATOS guiones_9AC6: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9ac6..0x9aed  (39 bytes)
DATA_guiones_9AC6:
	defb 002h,0f1h,002h,031h,006h,0f6h,002h,063h,006h,0f6h,002h,063h,004h,0f6h,002h,031h	; 9ac6  ...1...c...c...1
	defb 004h,0f6h,00ch,063h,002h,0f6h,004h,0e6h,002h,063h,004h,0f6h,002h,031h,005h,0f6h	; 9ad6  ...c.....c...1..
	defb 013h,0e6h,005h,0f6h,023h,0e6h,000h	; 9ae6

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9AED: Archivo 3: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x9aed..0x9b17  (42 bytes)
DATA_cabecera_de_la_figura_9AED:
	defb 017h,09bh,001h,09ch,002h,09ch,065h,09ch	; 9aed  ......e.
	defb 004h,000h,004h,001h,000h,002h,001h,01ah	; 9af5  ........
	defb 00dh,00fh,030h,005h,002h,030h,018h,002h	; 9afd  ..0..0..
	defb 033h,034h,026h,026h,035h,044h,044h,035h	; 9b05  34&&5DD5
	defb 041h,0abh,065h,09ch,081h,09ch,0a2h,09ch	; 9b0d  A.e.....
	defb 0beh,09ch	; 9b15

; ----------------------------------------------------------------------
; DATOS guiones_9B17: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9b17..0x9c02  (235 bytes)
DATA_guiones_9B17:
	defb 090h,0fch,0f0h,01fh,03fh,0c0h,0c0h,0dch,0ffh,01fh,03bh,0cch,0ceh,03ch,03ch,000h	; 9b17  ....?.....;..<<.
	defb 000h,006h,0ffh,0a2h,07fh,041h,0f7h,087h,000h,038h,09ch,0feh,000h,00ch,0f0h,01ch	; 9b27  .....A...8......
	defb 038h,031h,023h,027h,0ffh,001h,0bfh,0bfh,0c0h,0c0h,080h,080h,000h,000h,080h,0c0h	; 9b37  81#'............
	defb 01fh,05fh,03fh,01fh,0e0h,0f0h,002h,0ffh,002h,0feh,004h,0fch,081h,0c0h,006h,000h	; 9b47  ._?.............
	defb 081h,006h,005h,000h,09bh,0feh,0fch,0fch,000h,040h,020h,010h,008h,00fh,007h,003h	; 9b57  .........@ .....
	defb 00fh,0e0h,0f0h,0f8h,0f8h,0f8h,0fch,0fch,0ffh,0ffh,03fh,09fh,05fh,05fh,05fh,01fh	; 9b67  ..........?.___.
	defb 002h,0fch,002h,0feh,004h,0ffh,003h,001h,005h,000h,090h,0f3h,0f0h,0f0h,0c0h,0c0h	; 9b77  ................
	defb 0e0h,0f0h,0f0h,001h,001h,009h,009h,013h,007h,00fh,03fh,004h,0fch,088h,01fh,0f3h	; 9b87  ..........?.....
	defb 0f3h,001h,01fh,01fh,03fh,07fh,004h,0ffh,083h,080h,0c0h,0e1h,005h,0ffh,082h,0f0h	; 9b97  ....?...........
	defb 01fh,006h,0feh,00eh,000h,08ah,0fch,0f8h,0ffh,07fh,03fh,01fh,01fh,01fh,00fh,007h	; 9ba7  ..........?.....
	defb 002h,0feh,005h,0f8h,081h,0fch,008h,0ffh,002h,0e0h,003h,020h,085h,030h,038h,030h	; 9bb7  ........... .080
	defb 003h,001h,003h,000h,08bh,001h,001h,003h,0fch,0feh,0feh,0f8h,0fch,0fch,0ffh,0ffh	; 9bc7  ................
	defb 005h,000h,085h,001h,003h,0ffh,060h,07fh,006h,0ffh,082h,007h,00fh,00dh,0ffh,081h	; 9bd7  ......`.........
	defb 0fch,007h,0ffh,081h,000h,08eh,0ffh,0ffh,0fch,000h,000h,0c0h,0e0h,00fh,0ffh,0ffh	; 9be7  ................
	defb 01fh,000h,007h,03fh,005h,0ffh,081h,007h,004h,0ffh,000h	; 9bf7  ...?.......

; ----------------------------------------------------------------------
; DATOS guiones_9C02: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x9c02..0x9c81  (127 bytes)
DATA_guiones_9C02:
	defb 002h,0f6h,002h,063h,006h,0f6h,002h,063h,006h,0f6h,002h,031h,00ah,0f6h,003h,063h	; 9c02  ...c...c...1...c
	defb 006h,0f6h,003h,063h,006h,0f6h,002h,063h,004h,0f6h,002h,063h,005h,0f6h,003h,0e6h	; 9c12  ...c...c...c....
	defb 007h,0f6h,006h,0e6h,003h,064h,005h,0e6h,003h,064h,081h,0f6h,007h,064h,005h,0f4h	; 9c22  .....d...d...d..
	defb 003h,0e4h,010h,0e6h,003h,064h,081h,0e4h,00ah,064h,002h,0e4h,004h,064h,081h,0e6h	; 9c32  .....d...d...d..
	defb 003h,0e7h,008h,0e4h,008h,0e6h,082h,064h,0e6h,014h,0e7h,002h,076h,005h,0e7h,003h	; 9c42  .......d....v...
	defb 0e6h,002h,0e7h,006h,0e6h,002h,071h,006h,061h,002h,076h,01dh,0e6h,081h,0e1h,010h	; 9c52  ......q.a.v.....
	defb 0e6h,028h,0e1h,000h,006h,070h,0fch,0c4h,000h,002h,0e0h,070h,038h,03fh,00fh,060h	; 9c62  .(...p.....p8?.`
	defb 0e0h,0c0h,0c0h,090h,080h,000h,002h,03dh,061h,0c3h,087h,08eh,09eh,0fch,0f8h	; 9c72  .......=a......

; ----------------------------------------------------------------------
; DATOS guiones_9C81: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9c81..0x9ca2  (33 bytes)
DATA_guiones_9C81:
	defb 001h,001h,002h,000h,001h,001h,007h,000h,001h,060h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h	; 9c81  .........`......
	defb 0c0h,0c0h,000h,002h,003h,01eh,0feh,0e0h,000h,003h,001h,001h,002h,002h,002h,000h	; 9c91  ................
	defb 002h	; 9ca1

; ----------------------------------------------------------------------
; DATOS guiones_9CA2: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9ca2..0x9cbe  (28 bytes)
DATA_guiones_9CA2:
	defb 000h,004h,003h,007h,00fh,00fh,01fh,01fh,03fh,03fh,07fh,07fh,07fh,000h,005h,080h	; 9ca2  ........??......
	defb 080h,0e0h,0feh,080h,0f0h,080h,0c0h,0e0h,0f8h,0fch,000h,001h	; 9cb2  ............

; ----------------------------------------------------------------------
; DATOS guiones_9CBE: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9cbe..0x9cda  (28 bytes)
DATA_guiones_9CBE:
	defb 000h,001h,01eh,03fh,03fh,07fh,07eh,07fh,0feh,0ffh,0ffh,0ffh,000h,007h,0f0h,000h	; 9cbe  ...??.~.........
	defb 001h,0c0h,000h,001h,080h,000h,001h,080h,0e0h,0f8h,000h,005h	; 9cce  ............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9CDA: Archivo 3: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x9cda..0x9d04  (42 bytes)
DATA_cabecera_de_la_figura_9CDA:
	defb 004h,09dh,0b5h,09dh,0b6h,09dh,00ch,09eh	; 9cda  ........
	defb 004h,0f6h,011h,001h,000h,018h,001h,00ch	; 9ce2  ........
	defb 02ah,004h,010h,028h,006h,030h,018h,002h	; 9cea  *..(.0..
	defb 062h,053h,044h,044h,043h,044h,035h,035h	; 9cf2  bSDDCD55
	defb 04ah,0abh,00ch,09eh,025h,09eh,041h,09eh	; 9cfa  J...%.A.
	defb 04eh,09eh	; 9d02

; ----------------------------------------------------------------------
; DATOS guiones_9D04: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9d04..0x9db6  (178 bytes)
DATA_guiones_9D04:
	defb 0a8h,0ffh,0ffh,00fh,01fh,0c0h,0c0h,081h,078h,0ffh,0ffh,0e0h,0f8h,003h,0e1h,0f1h	; 9d04  ........x.......
	defb 009h,000h,001h,0fch,0fch,0f8h,0f0h,01fh,03fh,0a7h,0b3h,04ch,07ch,03ch,03eh,0e1h	; 9d14  ........?..L|<>.
	defb 0e0h,077h,0fch,001h,000h,01fh,03fh,08ch,0fch,004h,0ffh,004h,0feh,002h,080h,00fh	; 9d24  .w....?.........
	defb 000h,084h,0c0h,01fh,00fh,003h,003h,000h,004h,0feh,004h,0ffh,00ah,000h,086h,018h	; 9d34  ................
	defb 006h,001h,000h,000h,003h,004h,000h,084h,080h,07fh,0ffh,0ffh,003h,0ffh,005h,0feh	; 9d44  ................
	defb 003h,0ffh,005h,018h,084h,003h,0fch,0fch,003h,004h,001h,006h,0feh,002h,0ffh,005h	; 9d54  ................
	defb 018h,003h,0ffh,085h,001h,0f6h,0ech,0e8h,0e0h,003h,010h,088h,0ffh,0ffh,03fh,00fh	; 9d64  ..............?.
	defb 003h,001h,000h,000h,004h,0ffh,081h,0f0h,003h,0c0h,083h,0ffh,0ffh,0c0h,004h,000h	; 9d74  ................
	defb 083h,004h,000h,080h,006h,000h,08ch,010h,01ch,018h,030h,03fh,03fh,07fh,07fh,000h	; 9d84  ..........0??...
	defb 000h,001h,003h,004h,0ffh,004h,0c0h,002h,0e0h,002h,00fh,08ah,014h,014h,0ffh,07fh	; 9d94  ................
	defb 07fh,0c0h,0e0h,0f0h,000h,001h,00ah,0ffh,002h,03fh,002h,000h,006h,0ffh,082h,000h	; 9da4  .........?......
	defb 00fh,000h	; 9db4

; ----------------------------------------------------------------------
; DATOS guiones_9DB6: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x9db6..0x9e25  (111 bytes)
DATA_guiones_9DB6:
	defb 002h,0f1h,002h,063h,006h,0f6h,002h,063h,004h,0f6h,002h,063h,004h,0f6h,004h,063h	; 9db6  ...c...c...c...c
	defb 004h,0f6h,002h,063h,082h,0f6h,063h,004h,0f6h,002h,063h,005h,0f6h,003h,0e6h,010h	; 9dc6  ...c..c...c.....
	defb 0f6h,082h,0e1h,061h,003h,0f6h,023h,0e6h,008h,0e7h,081h,061h,007h,0f7h,083h,0e6h	; 9dd6  ...a..#....a....
	defb 0feh,0feh,005h,0e7h,005h,0e7h,003h,0e6h,005h,0f7h,003h,061h,081h,0e7h,004h,076h	; 9de6  ...........a...v
	defb 00bh,0e6h,010h,0e2h,018h,0e6h,006h,0e2h,002h,021h,005h,0e2h,003h,021h,004h,0e6h	; 9df6  .........!...!..
	defb 004h,010h,004h,0e2h,00ch,0e1h,000h,006h,001h,078h,058h,04ch,04ch,07ch,03ch,03eh	; 9e06  .........xXLL|<>
	defb 01eh,01fh,000h,005h,0e0h,0f0h,008h,014h,000h,003h,01eh,03eh,070h,000h,001h	; 9e16  ...........>p..

; ----------------------------------------------------------------------
; DATOS guiones_9E25: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9e25..0x9e41  (28 bytes)
DATA_guiones_9E25:
	defb 001h,001h,006h,007h,007h,01fh,01fh,00fh,00fh,007h,007h,003h,000h,004h,0f8h,0fch	; 9e25  ................
	defb 0feh,0ffh,0fbh,0fbh,0f6h,0feh,0fch,0f8h,0f0h,0c0h,000h,004h	; 9e35  ............

; ----------------------------------------------------------------------
; DATOS guiones_9E41: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9e41..0x9e4e  (13 bytes)
DATA_guiones_9E41:
	defb 000h,003h,01ch,0fch,0feh,0feh,0ffh,0feh,0fch,0f0h,0c0h,000h,014h	; 9e41  .............

; ----------------------------------------------------------------------
; DATOS guiones_9E4E: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9e4e..0x9e68  (26 bytes)
DATA_guiones_9E4E:
	defb 000h,004h,00fh,00fh,01fh,01fh,01fh,01fh,03fh,03fh,03fh,03fh,000h,006h,0fch,0c0h	; 9e4e  ........????....
	defb 0f8h,0c0h,0f0h,0e0h,0e0h,0f0h,0fch,0ffh,000h,002h	; 9e5e  ..........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9E68: Archivo 3: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x9e68..0x9e92  (42 bytes)
DATA_cabecera_de_la_figura_9E68:
	defb 092h,09eh,05fh,09dh,0e8h,09eh,0eah,09dh	; 9e68  .._.....
	defb 004h,0fbh,011h,001h,008h,018h,001h,018h	; 9e70  ........
	defb 02ah,004h,020h,028h,006h,030h,018h,002h	; 9e78  *. (.0..
	defb 062h,053h,053h,044h,053h,044h,035h,035h	; 9e80  bSSDSD55
	defb 04ah,0abh,018h,09fh,035h,09fh,053h,09fh	; 9e88  J...5.S.
	defb 04eh,09eh	; 9e90

; ----------------------------------------------------------------------
; DATOS guiones_9E92: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9e92..0x9ee8  (86 bytes)
DATA_guiones_9E92:
	defb 007h,0ffh,081h,0f0h,007h,0ffh,081h,01fh,006h,0ffh,0abh,001h,003h,01fh,03fh,0c0h	; 9e92  ..............?.
	defb 081h,078h,058h,0b3h,0b3h,0f8h,0fch,0e1h,0f1h,009h,077h,0fch,0feh,0fch,0f8h,0f0h	; 9ea2  .xX.......w.....
	defb 0e0h,0c0h,080h,080h,000h,07ch,03ch,03eh,01eh,01fh,001h,000h,000h,000h,01fh,03fh	; 9eb2  .....|<>.......?
	defb 073h,003h,0ffh,03fh,01fh,0ffh,007h,0feh,010h,000h,088h,01fh,00fh,00fh,007h,007h	; 9ec2  s..?............
	defb 007h,003h,000h,005h,0ffh,003h,018h,085h,004h,002h,002h,0fch,0fch,003h,001h,005h	; 9ed2  ................
	defb 000h,083h,080h,0e0h,0f8h,000h	; 9ee2

; ----------------------------------------------------------------------
; DATOS guiones_9EE8: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0x9ee8..0x9f35  (77 bytes)
DATA_guiones_9EE8:
	defb 002h,0f1h,002h,031h,006h,0f6h,002h,031h,004h,0f6h,002h,031h,004h,0f1h,004h,063h	; 9ee8  ...1...1...1...c
	defb 004h,0f6h,004h,063h,004h,0f6h,002h,063h,005h,0f6h,003h,0e6h,005h,0f6h,003h,0e6h	; 9ef8  ...c...c........
	defb 005h,0f6h,023h,0e6h,003h,061h,005h,0f7h,003h,0e6h,002h,0feh,003h,0e7h,008h,0e6h	; 9f08  ..#..a..........
	defb 000h,003h,001h,078h,058h,04ch,04ch,07ch,03ch,03eh,01eh,01fh,001h,000h,004h,0e0h	; 9f18  ...xXLL|<>......
	defb 0f0h,008h,014h,000h,003h,01eh,03eh,070h,000h,001h,0feh,03eh,01ch	; 9f28  ......>p...>.

; ----------------------------------------------------------------------
; DATOS guiones_9F35: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9f35..0x9f53  (30 bytes)
DATA_guiones_9F35:
	defb 000h,001h,001h,001h,001h,006h,007h,007h,00fh,00fh,007h,003h,003h,003h,000h,003h	; 9f35  ................
	defb 0fch,0feh,0f7h,0fbh,0fbh,0fbh,0ffh,0feh,0fch,0f8h,0f0h,0c0h,000h,004h	; 9f45  ..............

; ----------------------------------------------------------------------
; DATOS guiones_9F53: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9f53..0x9f5c  (9 bytes)
DATA_guiones_9F53:
	defb 0fch,0feh,0ffh,0ffh,0ffh,0f8h,0e0h,000h,019h	; 9f53  .........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_9F5C: Archivo 3: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0x9f5c..0x9f86  (42 bytes)
DATA_cabecera_de_la_figura_9F5C:
	defb 086h,09fh,03ah,0a0h,03bh,0a0h,094h,0a0h	; 9f5c  ..:.;...
	defb 004h,0f2h,010h,001h,0f8h,018h,001h,008h	; 9f64  ........
	defb 02bh,004h,008h,028h,006h,030h,0f8h,002h	; 9f6c  +..(.0..
	defb 053h,044h,035h,033h,033h,034h,034h,025h	; 9f74  SD53344%
	defb 058h,0abh,094h,0a0h,0a0h,0a0h,0b6h,0a0h	; 9f7c  X.......
	defb 0c1h,0a0h	; 9f84

; ----------------------------------------------------------------------
; DATOS guiones_9F86: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0x9f86..0xa03b  (181 bytes)
DATA_guiones_9F86:
	defb 004h,0ffh,09ah,0feh,0fch,0f8h,0c0h,0e0h,0c0h,07fh,0feh,003h,0ffh,00fh,04fh,03fh	; 9f86  ..............O?
	defb 01fh,0f8h,03ch,0e3h,013h,0efh,007h,0ffh,003h,0f0h,0e0h,0c0h,080h,005h,000h,082h	; 9f96  ..<.............
	defb 007h,008h,003h,000h,002h,098h,006h,0ffh,083h,0fch,03fh,0c0h,005h,000h,088h,0fah	; 9fa6  ..........?.....
	defb 0f2h,0e2h,0c2h,0c2h,0c2h,0c4h,0e4h,013h,0ffh,087h,00fh,07fh,0bfh,03fh,07fh,000h	; 9fb6  .............?..
	defb 00fh,006h,0ffh,082h,0e4h,0f4h,003h,0fch,003h,0feh,00ah,000h,086h,001h,001h,007h	; 9fc6  ................
	defb 003h,007h,003h,002h,001h,003h,0feh,003h,0fch,002h,0ffh,006h,018h,002h,0fch,002h	; 9fd6  ................
	defb 003h,004h,001h,008h,0fch,081h,018h,003h,030h,004h,0ffh,085h,001h,0f8h,0f0h,0e0h	; 9fe6  ........0.......
	defb 020h,003h,040h,004h,0ffh,084h,07fh,07fh,03fh,01fh,084h,0feh,0f8h,0fch,0fch,003h	; 9ff6   .@.....?.......
	defb 0feh,081h,0ffh,003h,000h,085h,001h,001h,003h,00fh,03fh,004h,080h,084h,0c0h,080h	; a006  ..........?.....
	defb 083h,080h,003h,01fh,003h,03fh,082h,0ffh,07fh,006h,0ffh,082h,0e0h,080h,006h,0ffh	; a016  .....?..........
	defb 002h,000h,005h,0ffh,003h,000h,081h,083h,006h,000h,089h,00fh,0ffh,0ffh,03fh,00fh	; a026  ..............?.
	defb 007h,007h,07fh,0ffh,000h	; a036

; ----------------------------------------------------------------------
; DATOS guiones_A03B: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xa03b..0xa0a0  (101 bytes)
DATA_guiones_A03B:
	defb 002h,0f1h,002h,031h,006h,0f6h,002h,063h,081h,0f6h,003h,061h,002h,0f6h,002h,063h	; a03b  ...1...c...a...c
	defb 004h,0f6h,082h,031h,063h,006h,0f6h,008h,0e6h,083h,016h,016h,0e1h,005h,060h,081h	; a04b  ...1c.........`.
	defb 063h,007h,0e6h,005h,0f6h,003h,0e6h,013h,061h,002h,0f6h,003h,0e6h,005h,0f6h,003h	; a05b  c.......a.......
	defb 0e1h,018h,0e6h,002h,0feh,006h,0e7h,008h,0f7h,002h,0feh,00ah,0e7h,004h,0e6h,004h	; a06b  ................
	defb 0f7h,004h,061h,081h,0e7h,003h,076h,021h,0e6h,003h,0e2h,005h,0e6h,003h,0e2h,018h	; a07b  ..a...v!........
	defb 0e1h,005h,0e2h,003h,0e1h,005h,0e2h,003h,0e1h,000h,00bh,001h,003h,000h,00eh,0c0h	; a08b  ................
	defb 0e0h,010h,028h,000h,001h	; a09b

; ----------------------------------------------------------------------
; DATOS guiones_A0A0: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa0a0..0xa0b6  (22 bytes)
DATA_guiones_A0A0:
	defb 007h,03fh,03fh,03fh,03fh,03fh,03fh,03eh,006h,000h,007h,0fch,0feh,0f7h,0fbh,0fbh	; a0a0  .??????>........
	defb 0fbh,07fh,0feh,0f8h,000h,007h	; a0b0

; ----------------------------------------------------------------------
; DATOS guiones_A0B6: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa0b6..0xa0c1  (11 bytes)
DATA_guiones_A0B6:
	defb 000h,001h,0f8h,0f8h,0f8h,0f8h,0f8h,0f8h,0f8h,000h,018h	; a0b6  ...........

; ----------------------------------------------------------------------
; DATOS guiones_A0C1: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa0c1..0xa0e0  (31 bytes)
DATA_guiones_A0C1:
	defb 000h,004h,001h,00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,007h,007h,007h,000h,001h	; a0c1  ................
	defb 018h,03ch,07ch,0feh,0feh,0f6h,0fbh,0ebh,0ech,0f0h,080h,080h,080h,0e0h,0e0h	; a0d1  .<|............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_A0E0: Archivo 3: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0xa0e0..0xa10a  (42 bytes)
DATA_cabecera_de_la_figura_A0E0:
	defb 00ah,0a1h,0d9h,09fh,077h,0a1h,06eh,0a0h	; a0e0  ....w.n.
	defb 004h,0f2h,010h,001h,0f8h,018h,001h,00bh	; a0e8  ........
	defb 030h,004h,00dh,028h,006h,030h,000h,002h	; a0f0  0..(.0..
	defb 053h,044h,044h,044h,043h,044h,044h,035h	; a0f8  SDDDCDD5
	defb 058h,0abh,0adh,0a1h,0bbh,0a1h,0d5h,0a1h	; a100  X.......
	defb 0c1h,0a0h	; a108

; ----------------------------------------------------------------------
; DATOS guiones_A10A: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa10a..0xa177  (109 bytes)
DATA_guiones_A10A:
	defb 0a2h,0ffh,0ffh,000h,000h,0ffh,0feh,0fch,0f0h,0e0h,0c0h,07fh,07fh,0ffh,078h,058h	; a10a  ..............xX
	defb 04ch,01fh,007h,0fch,0feh,001h,001h,063h,003h,0ffh,0ffh,0feh,0fch,0fch,0f8h,00fh	; a11a  L......c........
	defb 00fh,03fh,07fh,005h,000h,092h,010h,04ch,07ch,03ch,03eh,01eh,01fh,00fh,00fh,0feh	; a12a  .?.....L|<>.....
	defb 0ffh,0f0h,0e0h,0c7h,001h,0ffh,0ffh,0f0h,007h,0e0h,082h,004h,002h,005h,001h,08bh	; a13a  ................
	defb 000h,0fch,0f8h,0f0h,0f0h,0e0h,0e0h,0c0h,0c0h,00fh,007h,005h,003h,081h,007h,002h	; a14a  ................
	defb 0e0h,003h,0f0h,096h,0f8h,0f8h,003h,001h,000h,000h,040h,030h,008h,008h,0fch,0c0h	; a15a  ..........@0....
	defb 0f0h,0f8h,0fch,003h,007h,007h,00fh,007h,01fh,07fh,005h,0ffh,000h	; a16a  .............

; ----------------------------------------------------------------------
; DATOS guiones_A177: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xa177..0xa1bb  (68 bytes)
DATA_guiones_A177:
	defb 004h,0f3h,006h,0f6h,003h,063h,005h,0f6h,002h,063h,004h,0f6h,002h,031h,004h,0f6h	; a177  .....c...c...1..
	defb 004h,063h,006h,0e6h,008h,016h,002h,063h,003h,061h,003h,016h,005h,0f6h,00bh,0e6h	; a187  .c.....c.a......
	defb 007h,064h,081h,0e4h,007h,064h,081h,0e4h,007h,0e6h,081h,06eh,007h,0e6h,081h,066h	; a197  .d...d.....n...f
	defb 004h,064h,004h,0e6h,008h,0e4h,000h,00ch,001h,078h,058h,04ch,000h,00bh,0e0h,0f0h	; a1a7  .d.......xXL....
	defb 008h,014h,000h,001h	; a1b7

; ----------------------------------------------------------------------
; DATOS guiones_A1BB: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa1bb..0xa1d5  (26 bytes)
DATA_guiones_A1BB:
	defb 007h,01fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0fch,01dh,00dh,000h,005h,0e0h,0f0h,0f8h	; a1bb  ................
	defb 0f8h,0f8h,0e8h,0e8h,0d8h,0f8h,0f0h,0e0h,000h,005h	; a1cb  ..........

; ----------------------------------------------------------------------
; DATOS guiones_A1D5: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa1d5..0xa1e1  (12 bytes)
DATA_guiones_A1D5:
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0f0h,0c0h,000h,016h	; a1d5  ............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_A1E1: Archivo 3: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0xa1e1..0xa206  (37 bytes)
DATA_cabecera_de_la_figura_A1E1:
	defb 006h,0a2h,0e0h,0a2h,0e1h,0a2h,04ch,0a3h	; a1e1  ......L.
	defb 003h,008h,006h,001h,00eh,00ch,001h,024h	; a1e9  .......$
	defb 00ah,00fh,030h,018h,002h,080h,043h,034h	; a1f1  ..0...C4
	defb 035h,035h,035h,035h,035h,064h,0abh,005h	; a1f9  55555d..
	defb 09ah,04ch,0a3h,063h,0a3h	; a201

; ----------------------------------------------------------------------
; DATOS guiones_A206: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa206..0xa2e1  (219 bytes)
DATA_guiones_A206:
	defb 006h,0ffh,082h,001h,003h,005h,0ffh,081h,001h,004h,000h,004h,0ffh,082h,080h,0c0h	; a206  ................
	defb 006h,0ffh,09bh,0fch,0f0h,0fch,0f8h,0f7h,0e5h,0c4h,084h,007h,003h,00eh,01fh,000h	; a216  ................
	defb 087h,080h,0c0h,0c0h,0c1h,01fh,01fh,09fh,03fh,007h,013h,00bh,0f3h,0e0h,003h,0c0h	; a226  ........?.......
	defb 004h,080h,083h,000h,001h,001h,005h,000h,08dh,0c3h,0e7h,0f0h,0ffh,0ffh,07fh,000h	; a236  ................
	defb 004h,0e3h,023h,023h,0f0h,0e0h,003h,0c0h,004h,0ffh,084h,07fh,03fh,03fh,0bfh,006h	; a246  ..##........??..
	defb 0ffh,08ah,0e1h,080h,000h,040h,040h,0a0h,0a0h,090h,08ch,080h,005h,004h,08fh,018h	; a256  .....@@.........
	defb 030h,000h,0c0h,0c0h,0c0h,0e0h,0e0h,01fh,0ffh,09fh,0bfh,03fh,03fh,07fh,004h,0ffh	; a266  0..........??...
	defb 081h,080h,003h,000h,004h,080h,089h,00fh,03fh,09fh,05fh,05fh,05fh,09fh,01fh,00fh	; a276  ........?.___...
	defb 006h,0ffh,089h,0f1h,00fh,007h,003h,001h,0fch,0f0h,0e0h,0c0h,004h,0ffh,087h,07fh	; a286  ................
	defb 01fh,007h,003h,080h,0c0h,0e1h,004h,0ffh,092h,0f8h,03fh,07fh,080h,080h,0c0h,0e0h	; a296  ..........?.....
	defb 01fh,03fh,0feh,0ffh,0ffh,001h,001h,001h,003h,003h,080h,004h,000h,083h,080h,0f8h	; a2a6  .?..............
	defb 0f0h,004h,003h,085h,007h,007h,03fh,0ffh,0f0h,004h,0e0h,093h,0f0h,007h,0c0h,03fh	; a2b6  ......?........?
	defb 03fh,03fh,01fh,00fh,007h,0fch,0feh,007h,007h,00fh,01fh,03fh,0feh,000h,000h,005h	; a2c6  ??.........?....
	defb 0ffh,083h,01fh,000h,000h,006h,0ffh,082h,000h,00fh,000h	; a2d6  ...........

; ----------------------------------------------------------------------
; DATOS guiones_A2E1: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xa2e1..0xa363  (130 bytes)
DATA_guiones_A2E1:
	defb 002h,031h,004h,0f1h,002h,063h,002h,031h,006h,0f6h,006h,0f3h,002h,063h,005h,0f1h	; a2e1  .1...c.1.....c..
	defb 003h,0e6h,005h,0f6h,003h,0e6h,005h,0f6h,003h,0e6h,005h,0f6h,01eh,0e6h,085h,064h	; a2f1  ...............d
	defb 0e4h,0e4h,064h,064h,008h,0e4h,008h,064h,010h,0e6h,003h,064h,085h,0e4h,064h,0e6h	; a301  ..dd...d...d..d.
	defb 0e6h,0e7h,008h,0e4h,004h,064h,004h,0e4h,081h,064h,007h,074h,006h,076h,002h,074h	; a311  .....d...d.t.v.t
	defb 004h,0e7h,004h,076h,008h,0e6h,007h,0e4h,081h,0e2h,002h,074h,002h,0e7h,002h,0e6h	; a321  ...v.......t....
	defb 002h,062h,003h,074h,081h,0e7h,004h,0e6h,005h,076h,00bh,0e6h,006h,0e2h,082h,021h	; a331  .b.t.....v.....!
	defb 0e1h,005h,062h,083h,0e2h,021h,021h,005h,0e6h,013h,0e1h,000h,004h,0c0h,07fh,03fh	; a341  ..b..!!........?
	defb 018h,018h,018h,018h,018h,018h,018h,018h,018h,000h,002h,003h,006h,03ch,0f0h,080h	; a351  .............<..
	defb 000h,009h	; a361

; ----------------------------------------------------------------------
; DATOS guiones_A363: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa363..0xa378  (21 bytes)
DATA_guiones_A363:
	defb 000h,007h,001h,00fh,00fh,00fh,00fh,01fh,01fh,000h,008h,038h,0e0h,0d8h,0e0h,0d0h	; a363  ...........8....
	defb 0fch,0feh,0ffh,000h,002h	; a373

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_A378: Archivo 3: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0xa378..0xa39d  (37 bytes)
DATA_cabecera_de_la_figura_A378:
	defb 09dh,0a3h,07dh,0a4h,07eh,0a4h,0ech,0a4h	; a378  ..}.~...
	defb 003h,004h,006h,001h,00ah,00ch,001h,018h	; a380  ........
	defb 00eh,004h,022h,008h,00fh,080h,043h,034h	; a388  .."...C4
	defb 025h,025h,034h,026h,026h,064h,0abh,005h	; a390  %%4&&d..
	defb 09ah,0ech,0a4h,0f8h,0a4h	; a398

; ----------------------------------------------------------------------
; DATOS guiones_A39D: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa39d..0xa47e  (225 bytes)
DATA_guiones_A39D:
	defb 0b8h,0ffh,0ffh,0feh,0fch,0fch,0f8h,008h,01ah,000h,0feh,0ffh,0ffh,00eh,01fh,000h	; a39d  ................
	defb 087h,0ffh,0ffh,07fh,03fh,01fh,01fh,060h,080h,0ffh,0ffh,0fch,0f0h,0e0h,0c0h,0c0h	; a3ad  ....?..`........
	defb 080h,0c4h,084h,007h,003h,003h,001h,001h,000h,080h,0c0h,0c0h,0c1h,0c3h,0e7h,0f0h	; a3bd  ................
	defb 0ffh,03fh,01fh,00fh,0ffh,0efh,02fh,027h,0e7h,003h,0ffh,081h,0feh,004h,0fch,081h	; a3cd  .?..../'........
	defb 080h,004h,000h,083h,001h,001h,002h,003h,000h,088h,040h,020h,020h,010h,010h,0ffh	; a3dd  ..........@  ...
	defb 07fh,000h,005h,002h,082h,0e7h,0d7h,006h,01fh,002h,0fch,002h,0feh,004h,0ffh,08ch	; a3ed  ................
	defb 001h,001h,0e0h,0c0h,080h,000h,000h,080h,00ch,007h,03fh,01fh,004h,00fh,083h,004h	; a3fd  ..........?.....
	defb 0c0h,000h,005h,001h,082h,03fh,07fh,006h,0ffh,085h,080h,0c0h,0e0h,0e0h,0f0h,003h	; a40d  .....?..........
	defb 0fch,084h,00fh,01fh,03fh,07fh,004h,0ffh,081h,001h,005h,0ffh,082h,0feh,0ech,003h	; a41d  ....?...........
	defb 0ffh,085h,07fh,03fh,01fh,007h,003h,005h,0ffh,005h,0fch,083h,0feh,0ffh,0c0h,00bh	; a42d  ...?............
	defb 000h,088h,0d8h,0d0h,020h,030h,038h,03eh,03fh,07fh,006h,0ffh,084h,0f0h,007h,0ffh	; a43d  .... 08>?.......
	defb 07fh,004h,03fh,082h,07fh,0ffh,004h,0fch,09fh,0feh,0f0h,0f8h,0fch,002h,005h,007h	; a44d  ..?.............
	defb 001h,0ffh,0ffh,07fh,03fh,07fh,07fh,0c0h,0ffh,0ffh,080h,0e0h,0e0h,07fh,07fh,0ffh	; a45d  ....?...........
	defb 0feh,001h,001h,000h,000h,000h,007h,001h,008h,0ffh,085h,07fh,01fh,007h,003h,03fh	; a46d  ...............?
	defb 000h	; a47d

; ----------------------------------------------------------------------
; DATOS guiones_A47E: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xa47e..0xa4f8  (122 bytes)
DATA_guiones_A47E:
	defb 002h,031h,004h,0f6h,006h,063h,004h,0f6h,002h,031h,004h,0f6h,002h,063h,005h,0f6h	; a47e  .1...c...1...c..
	defb 003h,0e6h,002h,0f6h,00eh,0e6h,005h,0f6h,02bh,0e6h,00ah,0e6h,005h,064h,081h,0e4h	; a48e  ........+....d..
	defb 002h,0e6h,004h,064h,002h,0f4h,007h,0e6h,081h,0e7h,008h,0e6h,005h,0e4h,003h,0e7h	; a49e  ...d............
	defb 008h,074h,081h,0e7h,007h,076h,005h,0e7h,003h,0e6h,008h,0e2h,083h,0e7h,0e7h,0e6h	; a4ae  .t...v..........
	defb 005h,0e2h,002h,0f7h,008h,076h,006h,0e6h,007h,062h,081h,0e2h,008h,0e6h,005h,0e2h	; a4be  .....v...b......
	defb 003h,0e1h,004h,0e2h,004h,021h,002h,062h,003h,0e6h,003h,021h,002h,0e6h,002h,0e2h	; a4ce  .....!.b...!....
	defb 004h,021h,083h,062h,0e2h,0e2h,003h,021h,002h,010h,006h,0e2h,002h,0e1h,000h,012h	; a4de  .!.b...!........
	defb 006h,007h,005h,005h,007h,00eh,00eh,01ch,000h,006h	; a4ee  ..........

; ----------------------------------------------------------------------
; DATOS guiones_A4F8: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa4f8..0xa510  (24 bytes)
DATA_guiones_A4F8:
	defb 000h,001h,080h,040h,020h,02fh,04fh,000h,002h,020h,060h,060h,060h,060h,060h,060h	; a4f8  ...@ /O.. ``````
	defb 060h,000h,003h,00eh,0feh,0f0h,000h,00ah	; a508  `.......

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_A510: Archivo 3: cuatro punteros de fondo, 2
;   piezas de tres bytes y sus 2 punteros; mide 17 + 5*2 = 27
;   0xa510..0xa52b  (27 bytes)
DATA_cabecera_de_la_figura_A510:
	defb 02bh,0a5h,0f0h,0a5h,0f1h,0a5h,04eh,0a6h	; a510  +.....N.
	defb 001h,0f9h,001h,001h,002h,008h,001h,042h	; a518  .......B
	defb 024h,024h,033h,033h,033h,025h,024h,075h	; a520  $$333%$u
	defb 0abh,04eh,0a6h	; a528

; ----------------------------------------------------------------------
; DATOS guiones_A52B: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa52b..0xa5f1  (198 bytes)
DATA_guiones_A52B:
	defb 090h,0ffh,0f0h,01fh,03fh,0c0h,080h,000h,000h,0ffh,01fh,0f8h,0fch,0e1h,0f1h,009h	; a52b  ....?...........
	defb 077h,003h,0ffh,089h,0feh,0f8h,0f0h,03fh,07fh,000h,01fh,0c6h,001h,004h,000h,090h	; a53b  w......?........
	defb 080h,07fh,03fh,03fh,01fh,01fh,00fh,00fh,0fch,0feh,0ffh,01fh,03fh,073h,0fch,0feh	; a54b  ..??........?s..
	defb 005h,000h,08dh,080h,0c0h,0f8h,000h,040h,0f0h,080h,000h,000h,00ch,003h,01fh,03fh	; a55b  .......@.......?
	defb 007h,000h,087h,002h,002h,042h,022h,022h,024h,024h,002h,0e0h,005h,0c0h,092h,07fh	; a56b  .....B""$$......
	defb 080h,07ch,000h,008h,010h,010h,010h,0ffh,0f8h,0f8h,0f0h,0e0h,0e0h,0c0h,080h,0c1h	; a57b  .|..............
	defb 07fh,007h,006h,006h,0ffh,08ah,0ffh,0feh,0ffh,07fh,07fh,03fh,01fh,00fh,003h,001h	; a58b  ...........?....
	defb 003h,006h,08dh,080h,080h,0c0h,0c0h,0e0h,0fch,0f8h,0f8h,004h,004h,006h,006h,007h	; a59b  ................
	defb 004h,0ffh,084h,0feh,0f8h,0e0h,000h,004h,0ffh,084h,0f8h,0c0h,000h,000h,004h,0c0h	; a5ab  ................
	defb 004h,03fh,003h,007h,003h,00fh,082h,01fh,03fh,003h,000h,08ah,080h,080h,081h,087h	; a5bb  .?......?.......
	defb 0ffh,0ffh,001h,007h,01fh,07fh,003h,0ffh,090h,002h,001h,001h,081h,080h,0c0h,03fh	; a5cb  ...............?
	defb 01fh,01fh,04fh,0ffh,0ffh,0ffh,080h,0e0h,0e0h,005h,0ffh,082h,003h,01fh,004h,0ffh	; a5db  ..O.............
	defb 082h,000h,0c3h,003h,0ffh,000h	; a5eb

; ----------------------------------------------------------------------
; DATOS guiones_A5F1: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xa5f1..0xa66d  (124 bytes)
DATA_guiones_A5F1:
	defb 002h,0f6h,002h,063h,006h,0f6h,002h,063h,004h,0f6h,002h,03fh,004h,0f6h,002h,063h	; a5f1  ...c...c...?...c
	defb 083h,043h,043h,0f4h,005h,0e4h,081h,0e6h,007h,064h,003h,063h,003h,0f6h,082h,063h	; a601  .CC......d.c...c
	defb 0e3h,008h,0e6h,003h,064h,005h,0e6h,002h,064h,015h,0e6h,081h,0feh,007h,0e6h,081h	; a611  ....d...d.......
	defb 0f1h,007h,064h,081h,0e4h,081h,0feh,008h,0f7h,007h,076h,006h,0e7h,002h,0e6h,003h	; a621  ..d.......v.....
	defb 0f7h,005h,0e6h,003h,076h,005h,0e6h,008h,062h,008h,0e2h,004h,0e6h,004h,062h,008h	; a631  ....v...b.....b.
	defb 0e6h,016h,0e2h,002h,021h,081h,062h,004h,0e2h,003h,021h,010h,0e1h,000h,003h,001h	; a641  ....!.b...!.....
	defb 078h,058h,04ch,04ch,03ch,01ch,01eh,00eh,00fh,00fh,007h,003h,000h,002h,0e0h,0f0h	; a651  xXLL<...........
	defb 008h,014h,000h,003h,01eh,03eh,070h,000h,001h,0feh,0feh,0fch	; a661  .....>p.....

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_A66D: Archivo 3: cuatro punteros de fondo, 2
;   piezas de tres bytes y sus 2 punteros; mide 17 + 5*2 = 27
;   0xa66d..0xa688  (27 bytes)
DATA_cabecera_de_la_figura_A66D:
	defb 088h,0a6h,06bh,0a7h,06ch,0a7h,0b1h,0a7h	; a66d  ..k.l...
	defb 001h,018h,0efh,001h,023h,0f1h,001h,080h	; a675  ....#...
	defb 080h,080h,080h,007h,008h,008h,008h,084h	; a67d  ........
	defb 0abh,0b1h,0a7h	; a685

; ----------------------------------------------------------------------
; DATOS guiones_A688: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa688..0xa76c  (228 bytes)
DATA_guiones_A688:
	defb 006h,0ffh,002h,0feh,084h,0f8h,0e0h,0c0h,080h,004h,000h,08bh,03fh,00fh,004h,064h	; a688  ............?..d
	defb 0f4h,0c2h,0dah,071h,0ffh,003h,001h,005h,000h,003h,0ffh,085h,0ffh,03fh,00fh,006h	; a698  ...q.........?..
	defb 001h,003h,0ffh,085h,0e0h,0c0h,080h,000h,000h,003h,0ffh,085h,03fh,01fh,00fh,007h	; a6a8  ............?...
	defb 003h,09bh,0feh,0feh,0f9h,0f1h,0e1h,0c0h,0c0h,080h,000h,006h,01ch,033h,036h,04ch	; a6b8  .............36L
	defb 060h,030h,061h,001h,01fh,03dh,07dh,079h,0f3h,0c7h,000h,080h,080h,004h,081h,099h	; a6c8  `0a..=}y........
	defb 001h,000h,000h,080h,000h,000h,000h,080h,060h,080h,040h,020h,010h,018h,008h,009h	; a6d8  ........`.@ ....
	defb 00bh,003h,001h,001h,0f8h,0e0h,080h,000h,080h,005h,0ffh,0c4h,07fh,07fh,03fh,080h	; a6e8  ..............?.
	defb 080h,080h,0c0h,0c0h,080h,080h,007h,008h,007h,003h,0e0h,030h,0f2h,0e1h,0e0h,08eh	; a6f8  ...........0....
	defb 0f8h,0f0h,002h,001h,01fh,00fh,007h,001h,003h,002h,002h,004h,0feh,0fch,0c0h,040h	; a708  ...............@
	defb 040h,040h,080h,03fh,00fh,003h,001h,00bh,00fh,01fh,03fh,07fh,087h,0fch,0feh,080h	; a718  @@.?......?.....
	defb 080h,0c0h,0e0h,0f0h,0f8h,018h,008h,03fh,01fh,01fh,00fh,007h,003h,001h,000h,018h	; a728  .......?........
	defb 005h,0ffh,082h,07fh,01fh,004h,080h,003h,0ffh,081h,0e7h,004h,006h,086h,0f9h,0f9h	; a738  ................
	defb 0f1h,0e0h,000h,030h,003h,040h,003h,000h,082h,001h,003h,004h,007h,082h,01fh,0c0h	; a748  ...0.@..........
	defb 006h,0ffh,08eh,0f8h,000h,0f8h,0fch,0fch,0fch,007h,00fh,007h,07fh,000h,003h,00fh	; a758  ................
	defb 03fh,004h,0ffh,000h	; a768

; ----------------------------------------------------------------------
; DATOS guiones_A76C: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xa76c..0xa7d2  (102 bytes)
DATA_guiones_A76C:
	defb 016h,0e6h,002h,0f6h,02bh,0e6h,003h,0f6h,002h,0e6h,082h,0f6h,0e6h,005h,0f6h,01ch	; a76c  ....+...........
	defb 0e6h,003h,062h,00ah,0e2h,00dh,0e6h,003h,064h,005h,0e6h,003h,064h,005h,0e6h,003h	; a77c  ..b.....d...d...
	defb 064h,004h,0e6h,004h,064h,006h,0e6h,002h,062h,010h,0e2h,081h,0e6h,007h,061h,004h	; a78c  d...d...b.....a.
	defb 064h,004h,041h,004h,064h,004h,041h,008h,0e4h,007h,064h,081h,041h,008h,061h,004h	; a79c  d.A.d.A...d.A.a.
	defb 021h,002h,0e2h,00ah,0e1h,000h,001h,001h,001h,001h,000h,002h,00ch,038h,062h,060h	; a7ac  !............8b`
	defb 080h,0c1h,061h,011h,00fh,007h,0c8h,0e8h,084h,094h,082h,082h,003h,03fh,07bh,0e3h	; a7bc  ..a..........?{.
	defb 0c3h,087h,08eh,01ch,0f8h,0e0h	; a7cc

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_A7D2: Archivo 3: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0xa7d2..0xa7fc  (42 bytes)
DATA_cabecera_de_la_figura_A7D2:
	defb 0fch,0a7h,0b7h,09bh,0aah,0a8h,053h,09ch	; a7d2  ......S.
	defb 004h,000h,008h,001h,000h,0f8h,001h,01ah	; a7da  ........
	defb 005h,00fh,030h,0fdh,002h,030h,010h,002h	; a7e2  ..0..0..
	defb 023h,025h,016h,016h,025h,034h,034h,025h	; a7ea  #%..%44%
	defb 097h,0abh,014h,0a9h,02eh,0a9h,0a2h,09ch	; a7f2  ........
	defb 0beh,09ch	; a7fa

; ----------------------------------------------------------------------
; DATOS guiones_A7FC: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa7fc..0xa8aa  (174 bytes)
DATA_guiones_A7FC:
	defb 0c0h,0ffh,07fh,000h,043h,0b0h,078h,0dch,0feh,073h,0c1h,0f7h,0f3h,0f0h,0e0h,000h	; a7fc  ....C.x..s......
	defb 000h,07fh,01fh,0e0h,0f0h,007h,007h,003h,03fh,030h,018h,0f7h,0f0h,0f8h,0feh,0ffh	; a80c  ........?0......
	defb 0ffh,0fch,0f9h,084h,084h,00fh,01fh,003h,007h,01fh,0dfh,09fh,0bfh,07fh,0ffh,0ffh	; a81c  ................
	defb 0ffh,0f8h,0fch,003h,001h,0fch,0f8h,0f0h,0e0h,0ffh,0ffh,0ffh,0ffh,01fh,0cfh,0f8h	; a82c  ................
	defb 0fch,005h,0ffh,08ch,0feh,0fch,0fch,0fch,0f8h,0f0h,0f0h,007h,003h,001h,004h,00fh	; a83c  ................
	defb 007h,0ffh,083h,004h,002h,002h,003h,001h,002h,000h,003h,0e0h,085h,0f0h,0f8h,091h	; a84c  ................
	defb 00dh,002h,003h,003h,005h,007h,004h,0fch,003h,0feh,081h,0ffh,003h,002h,0a7h,004h	; a85c  ................
	defb 000h,001h,083h,0ffh,018h,004h,003h,008h,018h,038h,07ch,07ch,002h,00ch,031h,0c2h	; a86c  .........8||..1.
	defb 002h,004h,004h,0ffh,01ah,005h,003h,001h,001h,007h,01fh,0f0h,007h,00fh,01fh,03fh	; a87c  ...............?
	defb 080h,080h,07fh,03fh,080h,0c3h,008h,0ffh,006h,0feh,008h,0ffh,090h,0f0h,000h,000h	; a88c  ...?............
	defb 000h,0fbh,0f7h,0ech,0e8h,03fh,03fh,01fh,01fh,01fh,00fh,00fh,007h,000h	; a89c  .....??.......

; ----------------------------------------------------------------------
; DATOS guiones_A8AA: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xa8aa..0xa92e  (132 bytes)
DATA_guiones_A8AA:
	defb 002h,0f6h,002h,063h,004h,0f6h,002h,063h,008h,0f6h,002h,063h,003h,0f6h,081h,061h	; a8aa  ...c...c...c...a
	defb 002h,063h,004h,0f6h,002h,031h,002h,063h,004h,0f6h,002h,063h,008h,061h,002h,063h	; a8ba  .c...1.c...c.a.c
	defb 002h,0f6h,004h,064h,002h,031h,002h,0f6h,002h,0f4h,002h,043h,005h,0f1h,003h,0e4h	; a8ca  ...d.1.....C....
	defb 004h,0f6h,003h,064h,081h,0f4h,008h,061h,008h,0e6h,005h,064h,003h,0e6h,005h,0f4h	; a8da  ...d...a...d....
	defb 003h,0e6h,005h,0e4h,003h,0e6h,004h,0f4h,004h,064h,00fh,0e6h,081h,0f6h,005h,0e6h	; a8ea  .........d......
	defb 083h,0f6h,0f6h,0f7h,004h,0e6h,002h,0feh,002h,0e7h,008h,0e6h,008h,0e7h,081h,0f1h	; a8fa  ................
	defb 007h,071h,004h,0f7h,004h,076h,006h,0e7h,002h,0e6h,000h,006h,004h,00eh,00fh,063h	; a90a  .q...v.........c
	defb 0f1h,0f0h,078h,03eh,01fh,007h,00ch,03eh,0c7h,0c3h,000h,004h,003h,006h,084h,084h	; a91a  ..x>...>........
	defb 00fh,01fh,0fch,0f8h	; a92a

; ----------------------------------------------------------------------
; DATOS guiones_A92E: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa92e..0xa93c  (14 bytes)
DATA_guiones_A92E:
	defb 000h,006h,060h,0e0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,000h,010h	; a92e  ..`...........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_A93C: Archivo 3: cuatro punteros de fondo, 2
;   piezas de tres bytes y sus 2 punteros; mide 17 + 5*2 = 27
;   0xa93c..0xa957  (27 bytes)
DATA_cabecera_de_la_figura_A93C:
	defb 057h,0a9h,066h,0aah,067h,0aah,000h,0abh	; a93c  W.f.g...
	defb 001h,000h,008h,001h,003h,008h,001h,026h	; a944  .......&
	defb 026h,026h,026h,034h,034h,034h,034h,0aah	; a94c  &&&4444.
	defb 0abh,000h,0abh	; a954

; ----------------------------------------------------------------------
; DATOS guiones_A957: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xa957..0xaa67  (272 bytes)
DATA_guiones_A957:
	defb 006h,0ffh,082h,0c1h,080h,00ah,0ffh,08eh,007h,00fh,0e0h,0fch,0feh,0c6h,0ffh,0ffh	; a957  ................
	defb 0e0h,0f0h,007h,03fh,07fh,063h,00eh,0ffh,0b2h,083h,001h,020h,040h,040h,0ffh,0cfh	; a967  ...?.c..... @@..
	defb 0f0h,080h,000h,080h,0c0h,03fh,03fh,07fh,03fh,0c0h,080h,021h,06dh,040h,046h,04fh	; a977  .....??.?..!m@FO
	defb 05fh,067h,0cfh,084h,0b6h,002h,062h,0f2h,0fah,0e6h,0f3h,001h,003h,0fch,0fch,0feh	; a987  _g....b.........
	defb 0fch,003h,001h,004h,002h,002h,0ffh,0f3h,00fh,001h,0ffh,002h,000h,006h,080h,084h	; a997  ................
	defb 0e0h,0c0h,080h,080h,004h,040h,083h,03fh,03fh,01fh,005h,000h,083h,0fch,0fch,0f8h	; a9a7  .....@.??.......
	defb 005h,000h,084h,007h,003h,001h,001h,004h,002h,002h,000h,006h,001h,003h,080h,0adh	; a9b7  ................
	defb 0c0h,0c0h,0e0h,0f0h,0f8h,004h,002h,002h,001h,000h,00eh,03eh,0feh,000h,000h,000h	; a9c7  ...........>....
	defb 0c0h,004h,008h,010h,010h,000h,000h,000h,003h,020h,010h,008h,008h,020h,040h,040h	; a9d7  ......... ... @@
	defb 080h,000h,070h,07ch,07fh,001h,001h,001h,003h,003h,007h,00fh,01fh,002h,0feh,002h	; a9e7  ..p|............
	defb 001h,004h,0fch,081h,020h,007h,0ffh,081h,004h,007h,0ffh,002h,07fh,002h,080h,004h	; a9f7  .... ...........
	defb 03fh,003h,0f8h,002h,0f0h,003h,0e0h,090h,0ffh,0ffh,0e7h,0f3h,0fch,0feh,001h,001h	; aa07  ?...............
	defb 0ffh,0ffh,0e7h,0cfh,03fh,07fh,080h,080h,003h,01fh,002h,00fh,003h,007h,0c0h,0e0h	; aa17  ....?...........
	defb 0c0h,0c0h,080h,080h,080h,0c0h,0efh,003h,003h,007h,007h,00fh,007h,007h,003h,0c0h	; aa27  ................
	defb 0c0h,0e0h,0e0h,0f0h,0e0h,0e0h,0c0h,007h,003h,003h,001h,001h,001h,003h,0f7h,0e0h	; aa37  ................
	defb 0f7h,0f8h,0fch,0f0h,0c0h,0ffh,000h,003h,003h,003h,001h,001h,0feh,0feh,0ffh,0c0h	; aa47  ................
	defb 0c0h,0c0h,080h,080h,07fh,07fh,000h,007h,0efh,01fh,03fh,00fh,003h,0ffh,000h,000h	; aa57  ..........?.....

; ----------------------------------------------------------------------
; DATOS guiones_AA67: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xaa67..0xab20  (185 bytes)
DATA_guiones_AA67:
	defb 002h,0f1h,002h,031h,006h,0f4h,002h,031h,006h,0f4h,002h,063h,006h,0f6h,002h,063h	; aa67  ...1...1...c...c
	defb 006h,0f6h,002h,031h,006h,0f4h,002h,031h,007h,0f4h,003h,041h,002h,0f4h,088h,043h	; aa77  ...1...1...A...C
	defb 043h,0f4h,0f4h,0f1h,0f4h,043h,043h,002h,063h,005h,0f6h,003h,063h,005h,0f6h,081h	; aa87  C....CC.c...c...
	defb 063h,088h,043h,043h,0f4h,0f4h,0f1h,0f4h,043h,043h,003h,0f4h,003h,041h,082h,0f4h	; aa97  c.CC....CC...A..
	defb 040h,002h,064h,003h,0f6h,003h,0e6h,003h,0f6h,005h,0e6h,013h,0f6h,005h,0e6h,002h	; aaa7  @.d.............
	defb 064h,003h,0f6h,035h,0e6h,002h,0feh,004h,0e7h,082h,0e6h,061h,002h,0f1h,004h,071h	; aab7  d..5.......a...q
	defb 084h,0e6h,061h,0f1h,0f1h,004h,071h,002h,0e6h,002h,0feh,00ah,0e7h,002h,0e6h,006h	; aac7  ..a...q.........
	defb 074h,002h,0e6h,006h,074h,002h,0e6h,006h,0e7h,008h,0e6h,002h,0e2h,006h,0e6h,002h	; aad7  t...t...........
	defb 0e2h,006h,0e6h,002h,0e2h,006h,0e6h,008h,0e2h,002h,021h,005h,0e2h,083h,021h,021h	; aae7  ..........!...!!
	defb 010h,005h,0e2h,003h,021h,006h,0e2h,002h,021h,000h,002h,03ch,07eh,006h,01eh,012h	; aaf7  ....!...!..<~...
	defb 040h,046h,04fh,05ch,060h,030h,03fh,03fh,01fh,000h,002h,03ch,07eh,060h,078h,048h	; ab07  @FO\`0??...<~`xH
	defb 002h,062h,0f2h,03ah,006h,00ch,0fch,0fch,0f8h	; ab17  .b.:.....

; ----------------------------------------------------------------------
; DATOS guiones_AB20: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab20..0xab2e  (14 bytes)
DATA_guiones_AB20:
	defb 000h,006h,0c0h,0c0h,0c1h,082h,044h,038h,000h,00bh,0e0h,03eh,000h,007h	; ab20  ......D8...>..

; ----------------------------------------------------------------------
; DATOS guiones_AB2E: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab2e..0xab41  (19 bytes)
DATA_guiones_AB2E:
	defb 000h,006h,007h,018h,020h,040h,040h,080h,080h,0c0h,0c0h,0c0h,000h,006h,0e0h,030h	; ab2e  .... @@........0
	defb 03eh,000h,007h	; ab3e

; ----------------------------------------------------------------------
; DATOS guiones_AB41: 2 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab41..0xab58  (23 bytes)
DATA_guiones_AB41:
	defb 0c0h,000h,00fh,003h,003h,001h,002h,002h,00ch,000h,00ah,0c0h,0c0h,080h,041h,066h	; ab41  ..............Af
	defb 018h,000h,00bh,03fh,0e0h,000h,003h	; ab51

; ----------------------------------------------------------------------
; DATOS guiones_AB58: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab58..0xab64  (12 bytes)
DATA_guiones_AB58:
	defb 000h,00ch,0c0h,0c0h,031h,01fh,000h,00dh,03fh,0e0h,000h,001h	; ab58  ....1...?...

; ----------------------------------------------------------------------
; DATOS guiones_AB64: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab64..0xab75  (17 bytes)
DATA_guiones_AB64:
	defb 000h,004h,001h,006h,008h,010h,020h,040h,040h,080h,0c0h,0c0h,000h,006h,0ffh,000h	; ab64  ...... @@.......
	defb 00bh	; ab74

; ----------------------------------------------------------------------
; DATOS guiones_AB75: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab75..0xab84  (15 bytes)
DATA_guiones_AB75:
	defb 000h,00ah,003h,00ch,030h,040h,0c0h,0c0h,000h,007h,01fh,060h,0c0h,000h,006h	; ab75  ....0@.....`...

; ----------------------------------------------------------------------
; DATOS guiones_AB84: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab84..0xab97  (19 bytes)
DATA_guiones_AB84:
	defb 000h,003h,007h,018h,020h,020h,040h,04ch,070h,060h,040h,080h,080h,000h,004h,038h	; ab84  ....  @Lp`@....8
	defb 0f0h,000h,00ch	; ab94

; ----------------------------------------------------------------------
; DATOS guiones_AB97: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xab97..0xabaa  (19 bytes)
DATA_guiones_AB97:
	defb 05ch,033h,010h,000h,004h,0c0h,0e0h,020h,060h,040h,080h,000h,005h,0e0h,030h,00eh	; ab97  \3..... `@....0.
	defb 006h,000h,00ah	; aba7

; ----------------------------------------------------------------------
; DATOS guiones_ABAA: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xabaa..0xabb4  (10 bytes)
DATA_guiones_ABAA:
	defb 00fh,011h,020h,0c0h,0c0h,000h,00ch,080h,000h,00eh	; abaa  .. .......

; ----------------------------------------------------------------------
; DATOS punteros_del_archivo_4: Las 19 figuras del archivo 4. La tabla la
;   cierra su entrada mas baja, y los cuatro archivos dan 19 clavadas
;   0xabb4..0xabda  (38 bytes)
DATA_punteros_del_archivo_4:
	defw 0ae84h,0af6dh,0abdah,0ad41h,0b053h,0b1edh,0b30ch,0b4a1h	; abb4
	defw 0b611h,0b7c4h,0b7c4h,0b966h,0af6dh,0bb09h,0af6dh,0bc6ah	; abc4
	defw 0bc6ah,0bdabh,09653h	; abd4  -> DATA_cabecera_de_la_figura_BC6A DATA_cabecera_de_la_figura_BDAB DATA_cabecera_de_la_figura_9653

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_ABDA: Archivo 4: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0xabda..0xabff  (37 bytes)
DATA_cabecera_de_la_figura_ABDA:
	defb 0ffh,0abh,0b8h,0ach,0b9h,0ach,019h,0adh	; abda  ........
	defb 003h,003h,00ch,001h,0f0h,000h,000h,00ch	; abe2  ........
	defb 01bh,008h,018h,020h,001h,043h,044h,044h	; abea  ... .CDD
	defb 044h,044h,053h,053h,053h,07dh,0bfh,07bh	; abf2  DDSSS}.{
	defb 0bfh,019h,0adh,037h,0adh	; abfa

; ----------------------------------------------------------------------
; DATOS guiones_ABFF: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xabff..0xacb9  (186 bytes)
DATA_guiones_ABFF:
	defb 082h,0ffh,0ffh,002h,001h,004h,0feh,081h,0ffh,007h,000h,088h,0ffh,03fh,0e0h,0f0h	; abff  .............?..
	defb 00fh,007h,003h,001h,002h,001h,004h,0feh,002h,001h,003h,0ffh,082h,0cfh,0d3h,003h	; ac0f  ................
	defb 0dfh,081h,0feh,003h,0ffh,08ch,0c0h,0f0h,0f8h,0fch,000h,000h,0ffh,07fh,07fh,0ffh	; ac1f  ................
	defb 080h,0c0h,008h,0feh,003h,0dfh,085h,0c7h,0f0h,0f8h,0fch,0fch,007h,0ffh,089h,07fh	; ac2f  ................
	defb 01fh,01fh,07fh,07fh,03fh,03fh,03fh,01fh,081h,0feh,003h,0ffh,004h,0feh,004h,0fch	; ac3f  ....???.........
	defb 081h,0fdh,003h,0ffh,090h,03fh,01fh,00fh,070h,0f8h,0feh,0ffh,0ffh,00fh,01fh,0d0h	; ac4f  .....?..p.......
	defb 03fh,001h,003h,003h,007h,004h,0feh,004h,0ffh,006h,000h,082h,080h,0c0h,004h,0ffh	; ac5f  ?...............
	defb 08ch,0fch,0f9h,0ffh,0ffh,00fh,00bh,039h,061h,0c0h,000h,000h,000h,003h,0c0h,002h	; ac6f  .......9a.......
	defb 03fh,003h,0c0h,005h,0ffh,003h,0c0h,003h,000h,085h,0ffh,0ffh,000h,001h,001h,005h	; ac7f  ?...............
	defb 0c0h,083h,0e0h,0f0h,0e0h,005h,0c0h,003h,000h,088h,003h,003h,087h,0cfh,04fh,04fh	; ac8f  ..............OO
	defb 04fh,0cfh,002h,0e0h,004h,0c0h,092h,0e0h,000h,000h,001h,001h,000h,000h,000h,07fh	; ac9f  O...............
	defb 000h,08fh,00fh,00fh,08fh,087h,083h,001h,000h,000h	; acaf  ..........

; ----------------------------------------------------------------------
; DATOS guiones_ACB9: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xacb9..0xad37  (126 bytes)
DATA_guiones_ACB9:
	defb 002h,0f4h,002h,043h,00eh,0f4h,002h,043h,004h,0f4h,002h,043h,004h,0f4h,002h,043h	; acb9  ...C...C...C...C
	defb 008h,041h,081h,043h,007h,041h,002h,073h,002h,0f4h,002h,0f1h,002h,043h,005h,0f4h	; acc9  .A.C.A.s.....C..
	defb 003h,0e4h,010h,041h,087h,0f4h,0f1h,0f4h,0f4h,0f1h,0e4h,0e1h,009h,0e4h,010h,041h	; acd9  ...A...........A
	defb 002h,0e4h,002h,041h,014h,0e4h,008h,041h,008h,0e4h,003h,0e4h,002h,0feh,003h,0edh	; ace9  ...A...A........
	defb 003h,041h,005h,0fdh,005h,0f4h,008h,0edh,003h,0e4h,005h,0fdh,003h,0e4h,005h,0edh	; acf9  .A..............
	defb 003h,0e4h,005h,0ech,003h,0e1h,005h,0ech,003h,0c1h,002h,0e4h,005h,0ech,081h,0e1h	; ad09  ................
	defb 000h,002h,001h,003h,003h,003h,003h,002h,001h,001h,001h,000h,004h,001h,07ch,0feh	; ad19  ..............|.
	defb 0feh,0ffh,0ffh,0fbh,0fbh,07bh,0b7h,0ffh,0feh,0feh,07eh,0fch,0fch,0f8h	; ad29  .....{....~...

; ----------------------------------------------------------------------
; DATOS guiones_AD37: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xad37..0xad41  (10 bytes)
DATA_guiones_AD37:
	defb 000h,007h,004h,00ch,008h,038h,060h,0c0h,000h,013h	; ad37  .....8`...

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_AD41: Archivo 4: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0xad41..0xad6b  (42 bytes)
DATA_cabecera_de_la_figura_AD41:
	defb 06bh,0adh,018h,0aeh,019h,0aeh,07bh,0aeh	; ad41  k.....{.
	defb 004h,002h,00ch,001h,0f0h,000h,000h,00bh	; ad49  ........
	defb 01bh,008h,017h,020h,001h,028h,020h,00dh	; ad51  ... .( .
	defb 043h,044h,044h,044h,044h,053h,053h,053h	; ad59  CDDDDSSS
	defb 07dh,0bfh,07bh,0bfh,019h,0adh,037h,0adh	; ad61  }.{...7.
	defb 07bh,0aeh	; ad69

; ----------------------------------------------------------------------
; DATOS guiones_AD6B: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xad6b..0xae19  (174 bytes)
DATA_guiones_AD6B:
	defb 082h,0ffh,0feh,002h,001h,004h,0feh,008h,000h,088h,03fh,01fh,0f0h,0f0h,007h,003h	; ad6b  ..........?.....
	defb 001h,001h,002h,001h,004h,0feh,002h,001h,084h,0ffh,0ffh,0cfh,0d3h,004h,0dfh,003h	; ad7b  ................
	defb 0ffh,08dh,0c0h,0f0h,0f8h,0fch,0ffh,000h,000h,07fh,07fh,0ffh,07fh,080h,080h,008h	; ad8b  ................
	defb 0feh,085h,0dfh,0dfh,0c7h,0f0h,0f8h,003h,0fch,006h,0ffh,082h,07fh,03fh,003h,07fh	; ad9b  .............?..
	defb 003h,03fh,082h,01fh,00fh,003h,0ffh,005h,0feh,003h,0fch,081h,0feh,004h,0ffh,085h	; adab  .?..............
	defb 01fh,00fh,070h,0f8h,0feh,003h,0ffh,088h,01fh,0d0h,03fh,001h,003h,003h,007h,00fh	; adbb  ..p.......?.....
	defb 003h,0feh,005h,0ffh,005h,000h,083h,080h,0c0h,0c0h,004h,0ffh,088h,0fch,0f9h,0ffh	; adcb  ................
	defb 0ffh,00bh,039h,061h,0c0h,004h,000h,002h,0c0h,002h,03fh,004h,0c0h,004h,0ffh,004h	; addb  ..9a......?.....
	defb 0c0h,002h,000h,002h,0ffh,004h,000h,004h,0c0h,004h,0e0h,004h,0c0h,004h,000h,088h	; adeb  ................
	defb 0ffh,0ffh,0e1h,0e0h,040h,040h,0c1h,083h,002h,0e0h,006h,0c0h,090h,000h,001h,003h	; adfb  ....@@..........
	defb 002h,003h,0feh,0ffh,000h,087h,007h,001h,000h,0ffh,00fh,001h,000h,000h	; ae0b  ..............

; ----------------------------------------------------------------------
; DATOS guiones_AE19: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xae19..0xae84  (107 bytes)
DATA_guiones_AE19:
	defb 002h,0f4h,002h,043h,00eh,0f4h,002h,043h,004h,0f4h,002h,043h,004h,0f4h,002h,043h	; ae19  ...C...C...C...C
	defb 010h,041h,088h,073h,073h,0f4h,0f1h,0f4h,0f4h,043h,043h,005h,0f4h,003h,0e4h,010h	; ae29  .A.ss....CC.....
	defb 041h,086h,0f1h,0f4h,0f4h,0f1h,0f4h,0e1h,00ah,0e4h,010h,041h,083h,0e4h,041h,041h	; ae39  A..........A..AA
	defb 015h,0e4h,008h,041h,008h,0e4h,002h,0e4h,002h,0feh,004h,0edh,002h,041h,006h,0fdh	; ae49  ...A.........A..
	defb 002h,0e4h,002h,0feh,008h,0edh,004h,0e4h,004h,0fdh,004h,0e4h,002h,0edh,005h,0e4h	; ae59  ................
	defb 081h,0ech,002h,0e4h,005h,0ech,081h,0e1h,002h,0e4h,003h,0ech,003h,0c1h,004h,0ech	; ae69  ................
	defb 004h,0e1h,000h,008h,0feh,0e6h,0c2h,080h,080h,000h,013h	; ae79  ...........

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_AE84: Archivo 4: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0xae84..0xaea4  (32 bytes)
DATA_cabecera_de_la_figura_AE84:
	defb 0a4h,0aeh,07ch,0ach,01eh,0afh,0f3h,0ach	; ae84  ..|.....
	defb 002h,003h,00ch,001h,0f0h,000h,000h,018h	; ae8c  ........
	defb 018h,004h,043h,044h,044h,044h,044h,053h	; ae94  ..CDDDDS
	defb 053h,053h,07dh,0bfh,07bh,0bfh,063h,0afh	; ae9c  SS}.{.c.

; ----------------------------------------------------------------------
; DATOS guiones_AEA4: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xaea4..0xaf1e  (122 bytes)
DATA_guiones_AEA4:
	defb 082h,0ffh,0ffh,002h,001h,004h,0feh,009h,0ffh,087h,03fh,0e0h,0f0h,00fh,007h,003h	; aea4  ..........?.....
	defb 001h,002h,001h,004h,0feh,002h,001h,003h,0ffh,082h,0cfh,0d3h,003h,0dfh,090h,0feh	; aeb4  ................
	defb 0ffh,0ffh,0ffh,0c0h,0f0h,0f8h,0fch,000h,000h,0ffh,07fh,07fh,0ffh,080h,0c0h,008h	; aec4  ................
	defb 0feh,003h,0dfh,085h,0c7h,0f0h,0f8h,0fch,0fch,004h,0ffh,084h,0feh,0ffh,0ffh,07fh	; aed4  ................
	defb 002h,01fh,006h,03fh,003h,0feh,085h,0ffh,0ffh,0feh,0fch,0fch,004h,0fch,084h,0ffh	; aee4  ...?............
	defb 0ffh,0f3h,0fbh,090h,03fh,01fh,00fh,000h,000h,01fh,03fh,03fh,01fh,00fh,00fh,03fh	; aef4  ....?.....??...?
	defb 03fh,00fh,0c7h,027h,005h,0f8h,084h,0fch,0fch,0feh,0f8h,006h,0ffh,081h,0c0h,007h	; af04  ?..'............
	defb 0ffh,081h,003h,005h,007h,083h,00fh,01fh,03fh,000h	; af14  ........?.

; ----------------------------------------------------------------------
; DATOS guiones_AF1E: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xaf1e..0xaf6d  (79 bytes)
DATA_guiones_AF1E:
	defb 002h,0f4h,002h,043h,005h,0f4h,007h,041h,002h,0f4h,002h,043h,004h,0f4h,002h,043h	; af1e  ...C...A...C...C
	defb 004h,0f4h,002h,043h,008h,041h,081h,043h,007h,041h,002h,073h,002h,0f4h,002h,0f1h	; af2e  ...C.A.C.A.s....
	defb 002h,043h,005h,0f4h,003h,0e4h,010h,041h,087h,0f4h,0f1h,0f4h,0f4h,0f1h,0e4h,0e1h	; af3e  .C.....A........
	defb 009h,0e4h,00ch,041h,004h,084h,003h,0e4h,082h,0e1h,0e4h,003h,0e8h,008h,0e4h,008h	; af4e  ...A............
	defb 041h,008h,084h,008h,0e8h,000h,018h,004h,004h,006h,006h,007h,00fh,01fh,03fh	; af5e  A.............?

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_AF6D: Archivo 4: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0xaf6d..0xaf92  (37 bytes)
DATA_cabecera_de_la_figura_AF6D:
	defb 092h,0afh,0e2h,0adh,011h,0b0h,04fh,0aeh	; af6d  ......O.
	defb 003h,002h,00ch,001h,0f0h,000h,000h,017h	; af75  ........
	defb 018h,004h,028h,020h,00dh,043h,044h,044h	; af7d  ..( .CDD
	defb 044h,044h,053h,053h,053h,07dh,0bfh,07bh	; af85  DDSSS}.{
	defb 0bfh,063h,0afh,07bh,0aeh	; af8d

; ----------------------------------------------------------------------
; DATOS guiones_AF92: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xaf92..0xb011  (127 bytes)
DATA_guiones_AF92:
	defb 082h,0ffh,0feh,002h,001h,004h,0feh,008h,000h,088h,03fh,01fh,0f0h,0f0h,007h,003h	; af92  ..........?.....
	defb 001h,001h,002h,001h,004h,0feh,002h,001h,084h,0ffh,0ffh,0cfh,0d3h,004h,0dfh,003h	; afa2  ................
	defb 0ffh,08dh,0c0h,0f0h,0f8h,0fch,0ffh,000h,000h,07fh,07fh,0ffh,07fh,0c0h,0e0h,008h	; afb2  ................
	defb 0feh,085h,0dfh,0dfh,0c7h,0f0h,0f8h,003h,0fch,003h,0ffh,086h,0feh,0ffh,0ffh,07fh	; afc2  ................
	defb 03fh,01fh,006h,03fh,081h,01fh,0a0h,0feh,0feh,0ffh,0ffh,0feh,0fch,0fch,0f8h,0fch	; afd2  ?..?............
	defb 0fch,0fch,0ffh,0ffh,0f3h,0fbh,0f8h,01fh,00fh,000h,000h,01fh,03fh,03fh,0ffh,00fh	; afe2  ............??..
	defb 00fh,03fh,03fh,01fh,0cfh,027h,007h,004h,0f8h,084h,0fch,0fch,0feh,0ffh,006h,0ffh	; aff2  .??..'..........
	defb 002h,0c0h,006h,0ffh,082h,003h,000h,004h,007h,084h,00fh,01fh,03fh,000h,000h	; b002  ............?..

; ----------------------------------------------------------------------
; DATOS guiones_B011: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb011..0xb053  (66 bytes)
DATA_guiones_B011:
	defb 002h,0f4h,002h,043h,00eh,0f4h,002h,043h,004h,0f4h,002h,043h,004h,0f4h,002h,043h	; b011  ...C...C...C...C
	defb 010h,041h,088h,073h,073h,0f4h,0f1h,0f4h,0f4h,043h,043h,005h,0f4h,003h,0e4h,010h	; b021  .A.ss....CC.....
	defb 041h,086h,0f1h,0f4h,0f4h,0f1h,0f4h,0e1h,00ah,0e4h,00bh,041h,005h,084h,084h,0e4h	; b031  A..........A....
	defb 0e4h,0e1h,0e4h,004h,0e8h,008h,0e4h,007h,041h,081h,0e4h,008h,084h,007h,0e8h,081h	; b041  ........A.......
	defb 0e4h,000h	; b051

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_B053: Archivo 4: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0xb053..0xb073  (32 bytes)
DATA_cabecera_de_la_figura_B053:
	defb 073h,0b0h,05bh,0b1h,05ch,0b1h,0d1h,0b1h	; b053  s.[.\...
	defb 002h,006h,0f4h,001h,0f0h,000h,000h,018h	; b05b  ........
	defb 0f9h,008h,023h,023h,024h,025h,025h,025h	; b063  ..##$%%%
	defb 035h,035h,084h,0bfh,07bh,0bfh,0d1h,0b1h	; b06b  55..{...

; ----------------------------------------------------------------------
; DATOS guiones_B073: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb073..0xb15c  (233 bytes)
DATA_guiones_B073:
	defb 084h,0ffh,0ffh,000h,001h,004h,0feh,002h,0ffh,006h,000h,088h,0ffh,0ffh,0c0h,0e0h	; b073  ................
	defb 00fh,007h,007h,003h,002h,001h,004h,0feh,002h,003h,005h,0ffh,08bh,07fh,0e0h,0f0h	; b083  ................
	defb 0fch,0feh,001h,0ffh,0ffh,0ffh,060h,0e1h,098h,0fch,0fch,0feh,0feh,0ffh,0ffh,0ffh	; b093  ......`.........
	defb 0feh,0f8h,0ffh,0ffh,0ffh,03eh,0bfh,0beh,0dfh,0f3h,0ffh,0c7h,0efh,0ffh,00eh,00eh	; b0a3  .....>..........
	defb 0fdh,006h,0ffh,082h,01fh,00fh,0bah,0fch,0f0h,0e0h,0c0h,0c0h,0c0h,080h,080h,00fh	; b0b3  ................
	defb 0c7h,0e1h,0c0h,080h,004h,002h,002h,08dh,0fbh,0fbh,0fbh,007h,07dh,07ch,07eh,00fh	; b0c3  ............}|~.
	defb 00fh,00fh,007h,007h,003h,001h,000h,07fh,03fh,01fh,09fh,05fh,05fh,01fh,03fh,0fbh	; b0d3  ........?..__.?.
	defb 0f3h,0fch,0feh,0feh,0ffh,0ffh,080h,000h,000h,000h,001h,003h,007h,00fh,0bfh,07eh	; b0e3  ...............~
	defb 07fh,00dh,0ffh,081h,0f8h,003h,07fh,002h,03fh,003h,01fh,081h,0c1h,007h,0ffh,08ch	; b0f3  ........?.......
	defb 0c0h,0e0h,0e0h,0f0h,00fh,00fh,0f0h,0f0h,000h,003h,03fh,0fch,004h,0c0h,083h,07fh	; b103  ..........?.....
	defb 0f8h,0c0h,005h,000h,088h,0e0h,01fh,00fh,00fh,00fh,007h,003h,001h,006h,0f0h,082h	; b113  ................
	defb 0fch,0ffh,006h,0c0h,002h,000h,003h,0ffh,087h,0f6h,0f4h,0f0h,0f7h,0fbh,0e0h,080h	; b123  ................
	defb 005h,000h,084h,007h,0ffh,0ffh,07fh,005h,03fh,003h,0ffh,005h,0feh,081h,080h,006h	; b133  ........?.......
	defb 0ffh,089h,000h,007h,00fh,00fh,0e0h,0e0h,0f0h,0f8h,000h,004h,0ffh,086h,000h,000h	; b143  ................
	defb 00fh,0ffh,01fh,00fh,003h,007h,003h,0ffh,000h	; b153  .........

; ----------------------------------------------------------------------
; DATOS guiones_B15C: 4 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xb15c..0xb1ed  (145 bytes)
DATA_guiones_B15C:
	defb 002h,0f1h,002h,043h,00eh,0f4h,002h,043h,004h,0f4h,002h,043h,003h,0f4h,083h,0f1h	; b15c  ...C...C...C....
	defb 043h,043h,008h,041h,002h,043h,081h,0f4h,005h,041h,005h,0f4h,003h,0e4h,010h,041h	; b16c  CC.A.C...A.....A
	defb 005h,0f1h,00bh,0e4h,005h,041h,003h,0f1h,008h,041h,008h,084h,008h,0e8h,007h,041h	; b17c  .....A...A.....A
	defb 081h,0e4h,010h,041h,008h,04fh,007h,0e4h,081h,0efh,008h,0e4h,004h,0e4h,002h,0feh	; b18c  ...A.O..........
	defb 002h,0edh,003h,0f4h,005h,0fdh,081h,0f4h,007h,0fdh,081h,0feh,00dh,0edh,002h,0e4h	; b19c  ................
	defb 006h,0fdh,008h,0d4h,002h,041h,002h,0d4h,006h,0c4h,007h,0e4h,081h,0ech,004h,0e4h	; b1ac  .....A..........
	defb 003h,0ech,082h,0e1h,0e4h,003h,041h,004h,0c1h,003h,0e4h,081h,041h,008h,0c1h,004h	; b1bc  ......A.....A...
	defb 0e1h,004h,0ech,004h,0e1h,000h,005h,001h,001h,001h,001h,001h,007h,003h,003h,001h	; b1cc  ................
	defb 001h,000h,003h,03ch,07eh,0feh,0f7h,0fbh,0fbh,0ffh,0ffh,0feh,0fch,0f8h,0f0h,0e0h	; b1dc  ...<~...........
	defb 080h	; b1ec

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_B1ED: Archivo 4: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0xb1ed..0xb212  (37 bytes)
DATA_cabecera_de_la_figura_B1ED:
	defb 012h,0b2h,0a3h,0b3h,07eh,0b2h,026h,0b4h	; b1ed  ....~.&.
	defb 003h,008h,017h,001h,008h,017h,001h,00ch	; b1f5  ........
	defb 02ah,008h,018h,028h,004h,053h,053h,053h	; b1fd  *..(.SSS
	defb 044h,044h,043h,035h,035h,08ch,0bfh,0b8h	; b205  DDC55...
	defb 0b2h,0d4h,0b2h,0f5h,0b2h	; b20d

; ----------------------------------------------------------------------
; DATOS guiones_B212: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb212..0xb27e  (108 bytes)
DATA_guiones_B212:
	defb 084h,0ffh,0ffh,007h,00fh,004h,0f0h,083h,0ffh,0ffh,0feh,009h,0ffh,084h,07fh,07fh	; b212  ................
	defb 03fh,01fh,002h,00fh,002h,0f0h,002h,0f1h,002h,00eh,004h,000h,08ch,080h,061h,000h	; b222  ?.............a.
	defb 000h,0f0h,0f0h,007h,007h,003h,0ffh,080h,0c4h,006h,0f1h,082h,0f0h,0e0h,005h,000h	; b232  ................
	defb 08bh,0c0h,070h,038h,019h,000h,007h,003h,001h,00fh,001h,007h,088h,0ffh,0feh,0f8h	; b242  ..p8............
	defb 0f0h,0f0h,0e0h,0c0h,0c0h,008h,0ffh,082h,0c3h,0e0h,006h,0ffh,082h,001h,0feh,006h	; b252  ................
	defb 0ffh,081h,0c0h,007h,080h,013h,000h,085h,01fh,03fh,03fh,07fh,07fh,003h,080h,085h	; b262  .........??.....
	defb 07fh,07fh,000h,000h,000h,005h,0ffh,003h,030h,008h,0ffh,000h	; b272  ........0...

; ----------------------------------------------------------------------
; DATOS guiones_B27E: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xb27e..0xb2f5  (119 bytes)
DATA_guiones_B27E:
	defb 002h,0f1h,002h,043h,006h,0f4h,006h,043h,002h,0f1h,002h,031h,004h,0f4h,002h,043h	; b27e  ...C...C...1...C
	defb 004h,0f4h,002h,043h,008h,0f4h,002h,043h,004h,0f4h,002h,043h,005h,0f4h,00bh,0e4h	; b28e  ...C...C...C....
	defb 005h,0f4h,00bh,0e4h,010h,041h,081h,0e1h,007h,041h,023h,0e4h,002h,0feh,003h,0fdh	; b29e  .....A...A#.....
	defb 003h,041h,005h,0fdh,003h,041h,002h,0f1h,003h,0d1h,000h,004h,0c0h,0b0h,080h,080h	; b2ae  .A...A..........
	defb 080h,080h,080h,080h,080h,0e0h,038h,01ch,000h,005h,0feh,03ch,01ch,00ch,000h,001h	; b2be  ......8....<....
	defb 003h,001h,000h,001h,007h,000h,001h,003h,003h,003h,000h,001h,007h,007h,007h,003h	; b2ce  ................
	defb 003h,007h,007h,001h,000h,003h,0fch,0feh,0ffh,0ffh,07fh,0bfh,0bfh,0ffh,0ffh,0feh	; b2de  ................
	defb 0feh,0fch,0fch,0f8h,070h,000h,001h	; b2ee

; ----------------------------------------------------------------------
; DATOS guiones_B2F5: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb2f5..0xb30c  (23 bytes)
DATA_guiones_B2F5:
	defb 007h,01fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0f8h,000h,005h,080h,0c0h,0e0h	; b2f5  ................
	defb 0f0h,0f0h,0e0h,0c0h,080h,000h,008h	; b305

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_B30C: Archivo 4: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0xb30c..0xb336  (42 bytes)
DATA_cabecera_de_la_figura_B30C:
	defb 036h,0b3h,0ebh,0b3h,0ech,0b3h,050h,0b4h	; b30c  6.....P.
	defb 004h,007h,011h,001h,0f0h,000h,000h,00fh	; b314  ........
	defb 017h,001h,018h,02dh,008h,020h,028h,004h	; b31c  ...-. (.
	defb 052h,053h,053h,044h,044h,044h,035h,035h	; b324  RSSDDD55
	defb 07dh,0bfh,07bh,0bfh,051h,0b4h,075h,0b4h	; b32c  }.{.Q.u.
	defb 094h,0b4h	; b334

; ----------------------------------------------------------------------
; DATOS guiones_B336: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb336..0xb3ec  (182 bytes)
DATA_guiones_B336:
	defb 005h,0ffh,083h,0f8h,0f0h,0f0h,005h,0ffh,083h,001h,0ffh,0ffh,002h,00fh,004h,0f0h	; b336  ................
	defb 002h,00fh,007h,0ffh,089h,080h,080h,0c0h,01fh,00fh,00fh,007h,0f8h,0fch,008h,0f1h	; b346  ................
	defb 081h,061h,007h,000h,088h,0ffh,07bh,039h,019h,0ffh,0f8h,003h,001h,08ah,0ffh,0ffh	; b356  .a....{9........
	defb 0feh,0fch,0f8h,0f0h,0f0h,0e0h,0e1h,080h,006h,000h,091h,0c0h,078h,018h,0f3h,0f1h	; b366  ............x...
	defb 0f8h,0fbh,0ffh,00fh,001h,007h,001h,000h,0e0h,01fh,007h,0e0h,004h,0c0h,003h,080h	; b376  ................
	defb 010h,000h,083h,003h,003h,001h,005h,000h,005h,080h,083h,07fh,07fh,0ffh,007h,0ffh	; b386  ................
	defb 083h,030h,0feh,0feh,007h,0ffh,084h,07fh,040h,078h,07fh,003h,0ffh,003h,0ffh,003h	; b396  .0......@x......
	defb 0feh,002h,080h,005h,000h,09bh,001h,001h,0c0h,060h,060h,0c0h,0c0h,0c0h,080h,080h	; b3a6  .........``.....
	defb 0feh,0ffh,0ffh,0feh,0fch,0f8h,0f0h,080h,000h,0ffh,0ffh,0ffh,07fh,03fh,03fh,03fh	; b3b6  .............???
	defb 07fh,003h,080h,085h,0c0h,0c0h,0e0h,01fh,00fh,005h,0c0h,08bh,000h,080h,0c0h,0feh	; b3c6  ................
	defb 001h,003h,007h,007h,000h,000h,001h,005h,0ffh,08bh,000h,000h,0ffh,0ffh,0ffh,07fh	; b3d6  ................
	defb 03fh,03fh,01fh,03fh,0ffh,000h	; b3e6

; ----------------------------------------------------------------------
; DATOS guiones_B3EC: 3 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb3ec..0xb451  (101 bytes)
DATA_guiones_B3EC:
	defb 002h,0f1h,002h,031h,006h,0f4h,002h,031h,002h,0f4h,002h,041h,002h,043h,004h,0f4h	; b3ec  ...1...1...A.C..
	defb 009h,043h,081h,0f4h,002h,043h,004h,0f4h,002h,043h,005h,0f4h,003h,0e4h,00ch,0f4h	; b3fc  .C...C...C......
	defb 002h,041h,015h,0e4h,005h,041h,02dh,0e4h,083h,0feh,0feh,0d1h,005h,041h,003h,0fdh	; b40c  .A...A-......A..
	defb 005h,041h,083h,0f1h,0f1h,0d1h,002h,041h,006h,0e4h,006h,0edh,002h,0ech,007h,0fdh	; b41c  .A.....A........
	defb 081h,0c4h,007h,0fdh,081h,041h,008h,0d4h,008h,0e4h,006h,0ech,002h,0c1h,005h,0c4h	; b42c  .....A..........
	defb 003h,0c1h,081h,041h,003h,0c4h,081h,0c1h,003h,0e1h,081h,041h,004h,0c1h,003h,0e1h	; b43c  ...A.......A....
	defb 005h,0ech,003h,0e1h,000h	; b44c

; ----------------------------------------------------------------------
; DATOS guiones_B451: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb451..0xb475  (36 bytes)
DATA_guiones_B451:
	defb 0c0h,0b0h,080h,080h,080h,080h,080h,080h,080h,0e0h,03ch,00ch,004h,006h,003h,002h	; b451  ..........<.....
	defb 000h,001h,0feh,03ch,01ch,00ch,000h,001h,003h,001h,000h,001h,007h,000h,001h,003h	; b461  ...<............
	defb 000h,002h,0f0h,008h	; b471

; ----------------------------------------------------------------------
; DATOS guiones_B475: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb475..0xb494  (31 bytes)
DATA_guiones_B475:
	defb 007h,00fh,00fh,00fh,037h,03bh,03bh,03fh,03fh,0ffh,0ffh,07fh,03fh,01ch,018h,000h	; b475  ....7;;??...?...
	defb 001h,0e0h,0f0h,030h,0d8h,0f8h,0f8h,0f8h,0f8h,0f0h,0f0h,0e0h,0c0h,000h,004h	; b485  ...0...........

; ----------------------------------------------------------------------
; DATOS guiones_B494: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb494..0xb4a1  (13 bytes)
DATA_guiones_B494:
	defb 000h,003h,0fch,0feh,0ffh,0ffh,0ffh,0feh,0f8h,0f0h,0c0h,000h,014h	; b494  .............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_B4A1: Archivo 4: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0xb4a1..0xb4cb  (42 bytes)
DATA_cabecera_de_la_figura_B4A1:
	defb 0cbh,0b4h,07dh,0b5h,07eh,0b5h,0d9h,0b5h	; b4a1  ..}.~...
	defb 004h,0f0h,000h,000h,0f0h,000h,000h,002h	; b4a9  ........
	defb 030h,008h,00dh,028h,004h,018h,000h,001h	; b4b1  0..(....
	defb 053h,053h,053h,044h,044h,044h,035h,035h	; b4b9  SSSDDD55
	defb 07bh,0bfh,07bh,0bfh,0d9h,0b5h,0f1h,0b5h	; b4c1  {.{.....
	defb 002h,0b6h	; b4c9

; ----------------------------------------------------------------------
; DATOS guiones_B4CB: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb4cb..0xb57e  (179 bytes)
DATA_guiones_B4CB:
	defb 084h,0feh,0fch,003h,003h,004h,0fch,008h,000h,088h,07fh,03fh,0e0h,0e0h,00fh,007h	; b4cb  ...........?....
	defb 003h,003h,002h,003h,004h,0fch,002h,003h,084h,0ffh,0ffh,09fh,0a7h,004h,0bfh,088h	; b4db  ................
	defb 0feh,0feh,0ffh,080h,0e0h,0f1h,0f9h,00fh,003h,0fch,085h,0f0h,0e0h,0c0h,0c0h,080h	; b4eb  ................
	defb 082h,08ch,0f3h,00eh,0ffh,088h,0ffh,0fdh,0f1h,0e2h,0c2h,084h,084h,004h,010h,000h	; b4fb  ................
	defb 088h,001h,007h,00fh,01fh,01fh,01fh,00fh,00fh,084h,008h,008h,088h,0c8h,004h,0f0h	; b50b  ................
	defb 010h,000h,081h,00fh,006h,007h,081h,00fh,090h,0f0h,00fh,00fh,0f0h,0e0h,0c0h,0c0h	; b51b  ................
	defb 080h,0ffh,0ffh,0ffh,006h,006h,00ch,018h,030h,008h,0ffh,083h,00fh,0e0h,0e0h,005h	; b52b  ........0.......
	defb 01fh,003h,0ffh,005h,0fch,003h,080h,081h,07fh,004h,0f8h,002h,030h,002h,060h,005h	; b53b  ............0.`.
	defb 0ffh,08fh,0fch,0f8h,0e0h,0dfh,0dfh,0dfh,0bfh,01fh,01fh,00fh,007h,007h,007h,00fh	; b54b  ................
	defb 01fh,005h,0fch,083h,0feh,0feh,0f8h,004h,0f8h,089h,01fh,0e0h,0f0h,0f8h,000h,001h	; b55b  ................
	defb 007h,03fh,0e0h,003h,000h,002h,080h,006h,000h,088h,03fh,01fh,00fh,007h,003h,001h	; b56b  .?........?.....
	defb 01fh,0ffh,000h	; b57b

; ----------------------------------------------------------------------
; DATOS guiones_B57E: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xb57e..0xb5f1  (115 bytes)
DATA_guiones_B57E:
	defb 002h,0f4h,002h,043h,00eh,0f4h,002h,043h,004h,0f4h,002h,043h,004h,0f4h,002h,043h	; b57e  ...C...C...C...C
	defb 008h,041h,003h,043h,005h,041h,005h,0f4h,003h,0e4h,010h,041h,041h,0e4h,082h,0feh	; b58e  .A.C.A.....AA...
	defb 0feh,005h,0edh,081h,041h,007h,0fdh,083h,041h,0f1h,0f1h,005h,0d1h,083h,0e4h,0feh	; b59e  ....A...A.......
	defb 0feh,005h,0edh,008h,0ech,003h,0edh,081h,0dch,004h,0c4h,004h,0fdh,004h,041h,004h	; b5ae  ..............A.
	defb 0d4h,004h,041h,008h,0e4h,007h,0ech,081h,0e1h,004h,0c4h,081h,0ech,003h,0c1h,004h	; b5be  ..A.............
	defb 0e4h,004h,0e1h,005h,0ech,003h,0e1h,005h,0ech,003h,0e1h,000h,006h,007h,00fh,01fh	; b5ce  ................
	defb 03fh,0ffh,0ffh,0ffh,0f9h,0feh,07eh,000h,006h,0c0h,0f0h,0d8h,0e8h,0e8h,0e8h,0f8h	; b5de  ?.....~.........
	defb 0f8h,0f0h,0e0h	; b5ee

; ----------------------------------------------------------------------
; DATOS guiones_B5F1: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb5f1..0xb602  (17 bytes)
DATA_guiones_B5F1:
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0fch,0f0h,0c0h,080h,000h,009h,080h,080h,000h	; b5f1  ................
	defb 00ah	; b601

; ----------------------------------------------------------------------
; DATOS guiones_B602: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb602..0xb611  (15 bytes)
DATA_guiones_B602:
	defb 000h,011h,001h,001h,002h,002h,004h,004h,004h,008h,008h,008h,008h,000h,004h	; b602  ...............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_B611: Archivo 4: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0xb611..0xb63b  (42 bytes)
DATA_cabecera_de_la_figura_B611:
	defb 03bh,0b6h,000h,0b7h,001h,0b7h,06fh,0b7h	; b611  ;.....o.
	defb 004h,001h,015h,001h,001h,015h,001h,006h	; b619  ........
	defb 02fh,008h,011h,020h,004h,030h,004h,00ch	; b621  /.. .0..
	defb 053h,053h,053h,044h,044h,044h,044h,044h	; b629  SSSDDDDD
	defb 0aah,0bfh,06fh,0b7h,082h,0b7h,09bh,0b7h	; b631  ..o.....
	defb 0b1h,0b7h	; b639

; ----------------------------------------------------------------------
; DATOS guiones_B63B: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb63b..0xb701  (198 bytes)
DATA_guiones_B63B:
	defb 084h,0f0h,0e0h,01fh,01fh,004h,0e0h,082h,003h,001h,006h,000h,004h,0ffh,086h,07fh	; b63b  ................
	defb 03fh,01fh,01fh,01fh,01ch,004h,0e2h,086h,01dh,01dh,0ffh,0ffh,0c0h,003h,004h,0ffh	; b64b  ?...............
	defb 088h,0f0h,0f0h,007h,0ffh,0ffh,077h,0cch,0feh,005h,0e0h,093h,0c0h,0ffh,0ffh,07fh	; b65b  ......w.........
	defb 03fh,03fh,00fh,08fh,08fh,0c7h,0c7h,0f0h,003h,0fdh,0e1h,0fdh,0f1h,0fdh,0fdh,085h	; b66b  ??..............
	defb 0fch,0fch,0f8h,0f0h,0f0h,003h,0e0h,004h,0ffh,094h,0e3h,0f9h,0fch,0feh,0f1h,0b0h	; b67b  ................
	defb 0c0h,003h,007h,00fh,01fh,01fh,0feh,0feh,000h,00fh,007h,013h,00bh,00bh,005h,0e0h	; b68b  ................
	defb 085h,0f0h,0f8h,0f8h,0feh,0feh,005h,0ffh,082h,0dfh,01fh,004h,07fh,08bh,038h,010h	; b69b  ..............8.
	defb 0efh,0fch,0fch,0b8h,0b0h,000h,000h,000h,001h,002h,0fch,002h,003h,004h,0fch,084h	; b6ab  ................
	defb 0c7h,0f0h,0ffh,0ffh,004h,00ch,082h,01fh,07fh,006h,0ffh,002h,003h,002h,0f8h,002h	; b6bb  ................
	defb 007h,002h,00fh,004h,0fch,004h,0ffh,004h,00ch,002h,000h,002h,080h,089h,0ffh,0ffh	; b6cb  ................
	defb 0f8h,0f3h,0f7h,0e7h,0efh,0efh,01fh,007h,03fh,006h,0ffh,086h,080h,0f0h,0c0h,0c0h	; b6db  ........?.......
	defb 0e0h,0e1h,004h,000h,090h,0dfh,040h,0c0h,080h,07fh,07fh,000h,000h,07fh,07fh,03fh	; b6eb  ......@........?
	defb 01fh,00fh,007h,003h,0ffh,000h	; b6fb

; ----------------------------------------------------------------------
; DATOS guiones_B701: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xb701..0xb782  (129 bytes)
DATA_guiones_B701:
	defb 002h,0f4h,002h,043h,00eh,0f4h,002h,031h,004h,0f4h,002h,043h,004h,0f4h,004h,043h	; b701  ...C...1...C...C
	defb 002h,0f4h,006h,043h,004h,0f4h,002h,043h,005h,0f4h,081h,0e4h,00bh,041h,081h,0e4h	; b711  ...C...C.....A..
	defb 006h,041h,008h,0e4h,00bh,041h,005h,084h,003h,041h,005h,0e8h,008h,0e4h,008h,041h	; b721  .A...A...A.....A
	defb 082h,084h,081h,005h,084h,081h,041h,007h,084h,003h,0e4h,002h,0feh,004h,0edh,002h	; b731  ......A.........
	defb 041h,006h,0fdh,002h,041h,002h,0f1h,004h,0d1h,002h,0e4h,002h,0feh,00ch,0edh,004h	; b741  A...A...........
	defb 0fdh,004h,0e4h,004h,0d1h,004h,041h,004h,0edh,004h,0e4h,008h,0e1h,004h,0e4h,004h	; b751  ......A.........
	defb 0e1h,084h,041h,0e4h,0ech,0ech,004h,0c1h,002h,0e4h,004h,0ech,002h,0e1h,000h,008h	; b761  ..A.............
	defb 060h,058h,040h,040h,040h,040h,040h,070h,000h,00ah,07fh,01eh,00eh,006h,000h,001h	; b771  `X@@@@@p........
	defb 001h	; b781

; ----------------------------------------------------------------------
; DATOS guiones_B782: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb782..0xb79b  (25 bytes)
DATA_guiones_B782:
	defb 000h,006h,007h,01fh,03fh,07fh,0ffh,0ffh,0ffh,0fch,07fh,05fh,000h,006h,0e0h,030h	; b782  ....?......_...0
	defb 0f8h,0f8h,0f8h,0f8h,0f8h,0f0h,070h,000h,001h	; b792  ......p..

; ----------------------------------------------------------------------
; DATOS guiones_B79B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb79b..0xb7b1  (22 bytes)
DATA_guiones_B79B:
	defb 000h,00ah,00fh,006h,002h,003h,003h,000h,001h,03eh,0feh,0feh,0ffh,0ffh,0fch,0f8h	; b79b  .........>......
	defb 0f0h,0e0h,0c0h,080h,000h,005h	; b7ab

; ----------------------------------------------------------------------
; DATOS guiones_B7B1: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb7b1..0xb7c4  (19 bytes)
DATA_guiones_B7B1:
	defb 000h,007h,003h,003h,001h,001h,000h,00ah,030h,0f8h,0f8h,0fch,0fch,0feh,0feh,0ffh	; b7b1  ........0.......
	defb 078h,07ch,03eh	; b7c1

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_B7C4: Archivo 4: cuatro punteros de fondo, 6
;   piezas de tres bytes y sus 6 punteros; mide 17 + 5*6 = 47
;   0xb7c4..0xb7f3  (47 bytes)
DATA_cabecera_de_la_figura_B7C4:
	defb 0f3h,0b7h,0bbh,0b8h,0bch,0b8h,016h,0b9h	; b7c4  ........
	defb 005h,009h,00bh,001h,0f0h,000h,000h,010h	; b7cc  ........
	defb 013h,001h,01ah,020h,008h,028h,0fch,008h	; b7d4  ... .(..
	defb 038h,007h,00ch,051h,043h,044h,035h,035h	; b7dc  8..QCD55
	defb 035h,044h,035h,07dh,0bfh,07bh,0bfh,016h	; b7e4  5D5}.{..
	defb 0b9h,02ah,0b9h,038h,0b9h,054h,0b9h	; b7ec

; ----------------------------------------------------------------------
; DATOS guiones_B7F3: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb7f3..0xb8bc  (201 bytes)
DATA_guiones_B7F3:
	defb 007h,0ffh,081h,000h,082h,001h,003h,004h,0fch,002h,003h,008h,0ffh,088h,0c0h,0e0h	; b7f3  ................
	defb 01fh,00fh,007h,003h,0fch,0feh,008h,0fch,083h,0ffh,09fh,0a7h,005h,0bfh,088h,0ffh	; b803  ................
	defb 0ffh,07fh,01fh,00eh,006h,0ffh,0feh,005h,0ffh,088h,07fh,03fh,0ffh,0ffh,0ffh,0feh	; b813  ...........?....
	defb 0fch,0fch,003h,0f8h,081h,0f0h,007h,0ffh,09dh,0bfh,0bfh,08fh,0e1h,0e1h,0f1h,0c0h	; b823  ................
	defb 0f8h,0ffh,0ffh,0fch,0ffh,0feh,0ffh,0ffh,07fh,0ffh,05fh,0cfh,04fh,0cfh,04fh,02fh	; b833  .........._.O.O/
	defb 02fh,0f0h,0e0h,0e0h,0c0h,0c0h,003h,080h,004h,0ffh,084h,0f7h,0e7h,0efh,0dfh,008h	; b843  /...............
	defb 0ffh,081h,000h,007h,0ffh,083h,03fh,07fh,07fh,005h,0ffh,081h,09ch,003h,0bfh,004h	; b853  ......?.........
	defb 0ffh,082h,0dfh,05fh,003h,01fh,003h,00fh,007h,0ffh,081h,001h,005h,000h,088h,001h	; b863  ..._............
	defb 00fh,0f8h,0ffh,07fh,03fh,07fh,080h,003h,03fh,081h,00fh,003h,0e1h,004h,0e0h,081h	; b873  ....?...?.......
	defb 0ffh,003h,080h,004h,0c0h,08bh,080h,0ffh,0ffh,0feh,0fch,0f8h,0c0h,0c0h,07fh,03fh	; b883  ...............?
	defb 01fh,005h,00fh,006h,0ffh,0a2h,0f8h,0feh,0f8h,0fch,0feh,0ffh,0ffh,0feh,000h,000h	; b893  ................
	defb 0ffh,0ffh,0ffh,0feh,07ch,000h,000h,000h,0c0h,0c0h,03fh,000h,000h,000h,00fh,0ffh	; b8a3  ....|.....?.....
	defb 00fh,003h,001h,000h,007h,07fh,0ffh,0ffh,000h	; b8b3  .........

; ----------------------------------------------------------------------
; DATOS guiones_B8BC: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xb8bc..0xb92a  (110 bytes)
DATA_guiones_B8BC:
	defb 002h,0f1h,002h,031h,004h,0f4h,002h,043h,004h,0f4h,00ch,043h,004h,0f4h,002h,043h	; b8bc  ...1...C...C...C
	defb 005h,0f4h,003h,0e4h,00ah,041h,004h,0f4h,002h,041h,005h,0f1h,00ch,0e4h,017h,041h	; b8cc  .....A...A.....A
	defb 010h,0e4h,018h,041h,008h,0e1h,008h,0e4h,00fh,041h,008h,0f4h,081h,0fdh,004h,0e4h	; b8dc  ...A.....A......
	defb 081h,0feh,003h,0edh,081h,0f1h,003h,0fdh,004h,0edh,009h,0fdh,006h,0d4h,083h,0dch	; b8ec  ................
	defb 0edh,0edh,005h,0e4h,081h,0ech,008h,0e1h,003h,0e4h,005h,0e1h,005h,041h,003h,0e1h	; b8fc  .............A..
	defb 083h,0ech,0ech,0c1h,005h,0e1h,003h,0ech,005h,0e1h,000h,002h,003h,000h,00fh,0f8h	; b90c  ................
	defb 0f0h,070h,030h,000h,001h,00eh,004h,002h,006h,002h,006h,002h,001h,001h	; b91c  .p0...........

; ----------------------------------------------------------------------
; DATOS guiones_B92A: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb92a..0xb938  (14 bytes)
DATA_guiones_B92A:
	defb 000h,006h,038h,07ch,066h,0fah,0fah,0fah,0feh,0feh,0fch,078h,000h,010h	; b92a  ..8|f......x..

; ----------------------------------------------------------------------
; DATOS guiones_B938: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb938..0xb954  (28 bytes)
DATA_guiones_B938:
	defb 001h,003h,003h,003h,003h,003h,003h,003h,001h,001h,001h,000h,005h,0c0h,0f8h,0fch	; b938  ................
	defb 0feh,0feh,0fbh,0fdh,0fdh,0fdh,0feh,0beh,0ceh,07ch,000h,003h	; b948  .........|..

; ----------------------------------------------------------------------
; DATOS guiones_B954: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb954..0xb966  (18 bytes)
DATA_guiones_B954:
	defb 01ch,07eh,0ffh,0ffh,0ffh,0ffh,07fh,01fh,000h,00bh,080h,0c0h,000h,001h,080h,0c0h	; b954  .~..............
	defb 000h,008h	; b964

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_B966: Archivo 4: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0xb966..0xb986  (32 bytes)
DATA_cabecera_de_la_figura_B966:
	defb 086h,0b9h,06eh,0bah,06fh,0bah,0ech,0bah	; b966  ..n.o...
	defb 002h,003h,00ch,001h,0f0h,000h,000h,008h	; b96e  ........
	defb 006h,008h,043h,044h,035h,035h,044h,044h	; b976  ..CD55DD
	defb 035h,035h,07dh,0bfh,07bh,0bfh,0ech,0bah	; b97e  55}.{...

; ----------------------------------------------------------------------
; DATOS guiones_B986: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xb986..0xba6f  (233 bytes)
DATA_guiones_B986:
	defb 002h,0ffh,002h,001h,004h,0feh,081h,0ffh,007h,000h,088h,0ffh,03fh,0e0h,0f0h,00fh	; b986  ............?...
	defb 007h,003h,001h,002h,001h,008h,0ffh,083h,03fh,00fh,003h,003h,007h,090h,0feh,0ffh	; b996  ........?.......
	defb 0ffh,0ffh,0c0h,0f0h,0f8h,0fch,000h,000h,0ffh,07fh,07fh,0ffh,080h,0c0h,084h,0f9h	; b9a6  ................
	defb 0e1h,0c1h,0c0h,004h,080h,088h,0ffh,0ffh,0f9h,0feh,0ddh,080h,0ffh,0ffh,004h,007h	; b9b6  ................
	defb 084h,011h,0f1h,0f8h,0f8h,004h,0ffh,084h,0feh,0ffh,0ffh,03fh,002h,01fh,006h,03fh	; b9c6  ...........?...?
	defb 085h,080h,0c0h,0c0h,0e0h,0fch,003h,0ffh,006h,000h,085h,0e0h,0f0h,0e4h,0f0h,0fch	; b9d6  ................
	defb 005h,0ffh,083h,01fh,00fh,000h,005h,0ffh,090h,03fh,01fh,01fh,07fh,07fh,03fh,03fh	; b9e6  .........?....??
	defb 01fh,0f0h,0f0h,0e0h,0e0h,0e0h,0c0h,0c0h,080h,010h,000h,002h,01fh,006h,00fh,085h	; b9f6  ................
	defb 080h,080h,07fh,07fh,080h,003h,0ffh,004h,0ffh,004h,060h,007h,0ffh,089h,0feh,01fh	; ba06  ..........`.....
	defb 03fh,0c0h,0c0h,03fh,03fh,01fh,00fh,0d0h,0ffh,0feh,0feh,0feh,0feh,0ffh,0ffh,0feh	; ba16  ?..??...........
	defb 000h,000h,001h,001h,003h,000h,0c0h,0f0h,0c0h,0c0h,080h,080h,000h,000h,000h,001h	; ba26  ................
	defb 0fch,0f8h,0f0h,0e0h,080h,07fh,0ffh,0ffh,00fh,00fh,01fh,03fh,07fh,07fh,07fh,03fh	; ba36  ...........?...?
	defb 0fch,0f8h,0f0h,0f0h,0f0h,0fch,0e0h,0f8h,0f8h,0fch,0feh,003h,001h,0ffh,0ffh,03fh	; ba46  ...............?
	defb 001h,00fh,0ffh,0ffh,0feh,0ffh,0c0h,0f0h,0ffh,0ffh,0ffh,0ffh,000h,080h,000h,000h	; ba56  ................
	defb 00fh,003h,0ffh,0ffh,00fh,003h,003h,0ffh,000h	; ba66  .........

; ----------------------------------------------------------------------
; DATOS guiones_BA6F: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xba6f..0xbb09  (154 bytes)
DATA_guiones_BA6F:
	defb 002h,0f1h,002h,043h,00eh,0f4h,002h,043h,004h,0f4h,002h,043h,004h,0f1h,002h,031h	; ba6f  ...C...C...C...1
	defb 008h,041h,004h,043h,004h,041h,003h,0f3h,085h,0f4h,0f1h,0f1h,043h,043h,005h,0f4h	; ba7f  .A.C.A......CC..
	defb 003h,0e4h,004h,0f1h,082h,0f4h,0e4h,012h,041h,087h,0f4h,0f1h,0f4h,0f4h,0f1h,0e4h	; ba8f  ........A.......
	defb 0e1h,010h,0e4h,081h,0e1h,010h,041h,083h,0e4h,0e4h,0e1h,027h,0e4h,083h,0feh,0feh	; ba9f  ......A....'....
	defb 0edh,003h,0d1h,002h,041h,006h,0fdh,002h,041h,002h,0f1h,004h,0d4h,002h,0e4h,002h	; baaf  ....A...A.......
	defb 0feh,002h,0edh,002h,0e4h,005h,0edh,003h,0ech,005h,0fdh,003h,0c4h,005h,0fdh,003h	; babf  ................
	defb 0e4h,005h,0d4h,003h,0c4h,005h,0e4h,009h,0ech,002h,0e1h,003h,0c4h,002h,0ech,003h	; bacf  ................
	defb 0c1h,002h,0e4h,004h,0e1h,004h,0c1h,006h,0e1h,002h,0ech,006h,0e1h,000h,002h,003h	; badf  ................
	defb 007h,00fh,01eh,03fh,07fh,07fh,07fh,07eh,03fh,037h,020h,000h,004h,0f0h,0f8h,03ch	; baef  ...?...~?7 ....<
	defb 0feh,0feh,0feh,0feh,0feh,07eh,0bch,078h,000h,003h	; baff  .....~.x..

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_BB09: Archivo 4: cuatro punteros de fondo, 5
;   piezas de tres bytes y sus 5 punteros; mide 17 + 5*5 = 42
;   0xbb09..0xbb33  (42 bytes)
DATA_cabecera_de_la_figura_BB09:
	defb 033h,0bbh,0d9h,0bbh,0dah,0bbh,01fh,0bch	; bb09  3.......
	defb 004h,011h,0ffh,001h,0f0h,000h,000h,018h	; bb11  ........
	defb 009h,001h,030h,000h,00dh,030h,018h,00ah	; bb19  ..0..0..
	defb 080h,042h,043h,043h,043h,035h,035h,035h	; bb21  .BCCC555
	defb 0bch,0bfh,07bh,0bfh,01fh,0bch,040h,0bch	; bb29  ..{...@.
	defb 04ch,0bch	; bb31

; ----------------------------------------------------------------------
; DATOS guiones_BB33: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbb33..0xbbda  (167 bytes)
DATA_guiones_BB33:
	defb 006h,0ffh,082h,03fh,07fh,006h,0ffh,082h,0f0h,0f8h,008h,080h,083h,003h,001h,001h	; bb33  ...?............
	defb 005h,000h,005h,0ffh,083h,07fh,07fh,03fh,090h,080h,080h,007h,003h,001h,000h,080h	; bb43  .......?........
	defb 080h,000h,000h,0e7h,0c7h,0c3h,000h,00eh,004h,003h,03fh,002h,07fh,003h,03fh,098h	; bb53  ..........?...?.
	defb 0f0h,0f0h,0f0h,0f8h,0fch,08ch,006h,001h,000h,00ch,00ch,000h,00ch,001h,001h,001h	; bb63  ................
	defb 03fh,07fh,07fh,09fh,08fh,007h,003h,001h,002h,0fch,002h,0f8h,003h,0f0h,082h,0e0h	; bb73  ?...............
	defb 0feh,007h,0ffh,081h,001h,007h,0ffh,085h,0fdh,0feh,07fh,0bfh,0dfh,006h,0ffh,085h	; bb83  ................
	defb 07fh,03fh,03fh,01fh,00fh,008h,0e0h,0aah,0ffh,0ffh,0f7h,0f7h,0f7h,00fh,01fh,010h	; bb93  .??.............
	defb 0ffh,0ffh,0ffh,001h,07fh,0e0h,080h,000h,000h,007h,00fh,0e0h,0e0h,0e0h,0f0h,0f0h	; bba3  ................
	defb 00fh,007h,00fh,01fh,0e0h,0e0h,0f0h,0f0h,0f0h,080h,038h,040h,0fch,0fdh,0fch,000h	; bbb3  ..........8@....
	defb 0e0h,0c0h,004h,0f0h,004h,000h,005h,001h,081h,000h,005h,0e0h,083h,0f0h,0f0h,038h	; bbc3  ...............8
	defb 005h,0e0h,083h,0f0h,0f0h,038h,000h	; bbd3

; ----------------------------------------------------------------------
; DATOS guiones_BBDA: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xbbda..0xbc40  (102 bytes)
DATA_guiones_BBDA:
	defb 002h,031h,004h,0f1h,002h,043h,002h,031h,004h,0f1h,002h,043h,005h,0f4h,003h,0e4h	; bbda  .1...C.1...C....
	defb 00dh,0f4h,015h,0e4h,002h,0e1h,024h,0e4h,018h,041h,010h,0e4h,005h,041h,003h,0f4h	; bbea  ......$..A...A..
	defb 003h,041h,005h,0f4h,003h,0c4h,08dh,0fch,0fch,0dch,0c1h,0c1h,0e4h,0c4h,0c4h,0c4h	; bbfa  .A..............
	defb 0fch,0fch,0c1h,0c1h,084h,0e4h,0e8h,0f8h,0f8h,004h,081h,081h,041h,004h,084h,003h	; bc0a  ............A...
	defb 081h,007h,0c4h,011h,0c1h,000h,002h,00fh,007h,003h,000h,003h,0e0h,0e0h,0e0h,070h	; bc1a  ...............p
	defb 078h,018h,00ch,002h,000h,002h,0cfh,08fh,086h,000h,001h,01ch,008h,000h,001h,018h	; bc2a  x...............
	defb 018h,001h,019h,002h,002h,002h	; bc3a

; ----------------------------------------------------------------------
; DATOS guiones_BC40: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbc40..0xbc4c  (12 bytes)
DATA_guiones_BC40:
	defb 000h,017h,00fh,01fh,03eh,00eh,00eh,00eh,00fh,007h,000h,001h	; bc40  ....>.......

; ----------------------------------------------------------------------
; DATOS guiones_BC4C: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbc4c..0xbc6a  (30 bytes)
DATA_guiones_BC4C:
	defb 000h,003h,006h,00fh,00fh,00fh,00fh,01fh,01fh,01fh,01fh,01fh,00fh,00fh,006h,000h	; bc4c  ................
	defb 003h,006h,00fh,00fh,00fh,00fh,01fh,01fh,01fh,01fh,01fh,00fh,00fh,006h	; bc5c  ..............

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_BC6A: Archivo 4: cuatro punteros de fondo, 3
;   piezas de tres bytes y sus 3 punteros; mide 17 + 5*3 = 32
;   0xbc6a..0xbc8a  (32 bytes)
DATA_cabecera_de_la_figura_BC6A:
	defb 08ah,0bch,002h,0b1h,03bh,0bdh,098h,0b1h	; bc6a  ....;...
	defb 002h,003h,000h,001h,003h,000h,001h,008h	; bc72  ........
	defb 0f0h,001h,023h,025h,016h,016h,025h,025h	; bc7a  ..#%..%%
	defb 035h,035h,0c3h,0bfh,097h,0bdh,09dh,0bdh	; bc82  55......

; ----------------------------------------------------------------------
; DATOS guiones_BC8A: 1 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbc8a..0xbd3b  (177 bytes)
DATA_guiones_BC8A:
	defb 005h,0ffh,087h,0feh,0fch,0f8h,0f3h,0e0h,03fh,07fh,006h,0ffh,083h,0c0h,0e0h,00fh	; bc8a  ........?.......
	defb 003h,007h,087h,00fh,01fh,0fch,0f6h,0efh,0cfh,086h,006h,0ffh,083h,07fh,03fh,0feh	; bc9a  ..............?.
	defb 002h,0f8h,004h,007h,082h,0f8h,078h,004h,0ffh,084h,0fch,0f8h,007h,00fh,004h,0ffh	; bcaa  ......x.........
	defb 094h,00fh,007h,0f8h,0fch,0dbh,0ffh,0fah,0f7h,0ffh,0feh,0f8h,0f8h,0c0h,0e0h,0c0h	; bcba  ................
	defb 0c0h,060h,020h,020h,0ffh,006h,0ffh,09ah,0f2h,0e0h,077h,017h,032h,0dfh,09fh,03fh	; bcca  .`  ......w.2..?
	defb 07fh,0ffh,0f0h,0f0h,00fh,007h,007h,003h,0ffh,0ffh,013h,00bh,00bh,00bh,003h,003h	; bcda  ................
	defb 007h,003h,082h,0fch,0feh,008h,0ffh,0a6h,0e0h,080h,0f0h,0e0h,0c0h,080h,0c0h,080h	; bcea  ................
	defb 000h,0f3h,0cfh,0bfh,0ffh,0ffh,0bfh,07fh,07fh,0dfh,0e7h,0e7h,0f7h,0f7h,0efh,0f7h	; bcfa  ................
	defb 0fbh,0fdh,0fch,0ffh,0ffh,0ffh,003h,003h,007h,00fh,0ffh,0ffh,0ffh,07fh,084h,03ch	; bd0a  ...............<
	defb 07eh,000h,004h,003h,002h,005h,000h,004h,080h,081h,0fdh,007h,0ffh,007h,000h,081h	; bd1a  ~...............
	defb 007h,002h,07fh,003h,03fh,088h,01fh,01fh,0e0h,0ffh,0ffh,07eh,03ch,081h,003h,0ffh	; bd2a  ....?......~<...
	defb 000h	; bd3a

; ----------------------------------------------------------------------
; DATOS guiones_BD3B: 2 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xbd3b..0xbd9d  (98 bytes)
DATA_guiones_BD3B:
	defb 002h,0f1h,002h,031h,006h,0f4h,006h,043h,002h,0f1h,002h,043h,004h,0f4h,002h,043h	; bd3b  ...1...C...C...C
	defb 005h,0f4h,006h,043h,003h,041h,002h,043h,004h,0f4h,002h,043h,002h,031h,004h,0f8h	; bd4b  ...C.A.C...C.1..
	defb 002h,083h,002h,031h,004h,0f8h,002h,083h,005h,0f8h,003h,0e4h,007h,0f4h,009h,041h	; bd5b  ...1...........A
	defb 003h,0f4h,005h,041h,002h,0f8h,004h,084h,002h,041h,005h,0f8h,002h,0e8h,009h,0e4h	; bd6b  ...A.....A......
	defb 003h,041h,081h,0e1h,004h,0e4h,018h,041h,008h,0e4h,002h,084h,006h,0f8h,008h,084h	; bd7b  .A.....A........
	defb 008h,041h,008h,0f4h,007h,0e4h,081h,0feh,004h,084h,004h,0e4h,000h,01ch,080h,070h	; bd8b  .A.............p
	defb 010h,030h	; bd9b

; ----------------------------------------------------------------------
; DATOS guiones_BD9D: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbd9d..0xbdab  (14 bytes)
DATA_guiones_BD9D:
	defb 000h,012h,00ch,002h,005h,000h,001h,001h,000h,001h,040h,020h,000h,006h	; bd9d  ..........@ ..

; ----------------------------------------------------------------------
; DATOS cabecera_de_la_figura_BDAB: Archivo 4: cuatro punteros de fondo, 4
;   piezas de tres bytes y sus 4 punteros; mide 17 + 5*4 = 37
;   0xbdab..0xbdd0  (37 bytes)
DATA_cabecera_de_la_figura_BDAB:
	defb 0d0h,0bdh,0cch,0beh,0cdh,0beh,055h,0bfh	; bdab  ......U.
	defb 003h,008h,008h,001h,0f0h,000h,000h,008h	; bdb3  ........
	defb 0f8h,004h,008h,018h,004h,026h,026h,026h	; bdbb  .....&&&
	defb 026h,034h,034h,034h,034h,0d0h,0bfh,07bh	; bdc3  &4444..{
	defb 0bfh,055h,0bfh,068h,0bfh	; bdcb

; ----------------------------------------------------------------------
; DATOS guiones_BDD0: 2 guiones de figura encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbdd0..0xbecd  (253 bytes)
DATA_guiones_BDD0:
	defb 006h,0ffh,082h,0c1h,080h,008h,0ffh,085h,0c0h,0c0h,07fh,07fh,080h,003h,000h,085h	; bdd0  ................
	defb 003h,003h,0feh,0feh,001h,003h,000h,00eh,0ffh,08ah,083h,001h,000h,010h,020h,020h	; bde0  ..............  
	defb 0ffh,0f7h,0f8h,0ffh,002h,080h,004h,03fh,082h,040h,080h,004h,0ffh,084h,081h,000h	; bdf0  .......?.@......
	defb 003h,0cfh,004h,0ffh,084h,081h,000h,080h,099h,002h,001h,004h,0fch,08ah,002h,001h	; be00  ................
	defb 000h,008h,004h,004h,0ffh,0efh,01fh,0ffh,003h,000h,002h,080h,003h,000h,002h,07fh	; be10  ................
	defb 004h,0ffh,081h,0feh,003h,0ffh,08eh,0fbh,0fch,0ffh,0f0h,0f0h,078h,0bfh,0bfh,09fh	; be20  ............x...
	defb 03fh,0ffh,00fh,00fh,01eh,002h,0feh,004h,0ffh,082h,07fh,0ffh,003h,000h,002h,001h	; be30  ?...............
	defb 003h,000h,088h,000h,000h,080h,0c0h,0c0h,0e0h,0f0h,0feh,003h,0ffh,081h,0fch,004h	; be40  ................
	defb 0ffh,090h,0bfh,09ch,00fh,007h,0f8h,0ffh,0ffh,0ffh,0fdh,039h,0f0h,0e0h,01fh,0ffh	; be50  ...........9....
	defb 0ffh,0ffh,003h,0ffh,081h,03fh,006h,0ffh,088h,001h,003h,003h,007h,00fh,07fh,000h	; be60  .....?..........
	defb 0c0h,004h,0e0h,002h,0c0h,008h,0ffh,004h,07fh,005h,0ffh,081h,003h,004h,007h,002h	; be70  ................
	defb 003h,004h,0c0h,084h,03fh,03fh,0c0h,080h,010h,0ffh,004h,003h,084h,0fch,0fch,003h	; be80  ....??..........
	defb 001h,002h,080h,004h,000h,002h,080h,003h,0ffh,082h,0fbh,0fch,003h,001h,003h,0ffh	; be90  ................
	defb 082h,0dfh,03fh,003h,080h,002h,001h,004h,000h,002h,001h,0a0h,080h,080h,0c0h,0e0h	; bea0  ..?.............
	defb 0c0h,080h,0ffh,000h,001h,003h,003h,003h,0fch,0fch,0feh,000h,080h,0c0h,0c0h,0c0h	; beb0  ................
	defb 03fh,03fh,07fh,000h,001h,001h,003h,007h,003h,001h,0ffh,000h,000h	; bec0  ??...........

; ----------------------------------------------------------------------
; DATOS guiones_BECD: 3 guiones de figura y piezas de sprite encajados: los
;   que comparten cola empiezan dentro del anterior
;   0xbecd..0xbf68  (155 bytes)
DATA_guiones_BECD:
	defb 002h,0f1h,002h,031h,006h,0f8h,002h,031h,006h,0f4h,002h,043h,006h,0f4h,002h,043h	; becd  ...1...1...C...C
	defb 006h,0f4h,002h,031h,006h,0f1h,002h,031h,008h,0f8h,004h,081h,002h,083h,004h,0f8h	; bedd  ...1...1........
	defb 002h,083h,010h,041h,002h,083h,004h,0f8h,002h,083h,004h,0f8h,004h,081h,004h,0f8h	; beed  ...A............
	defb 004h,0f4h,005h,0f8h,003h,0e1h,010h,041h,005h,0f8h,003h,0e1h,004h,0f8h,004h,0f4h	; befd  .......A........
	defb 008h,0e4h,022h,041h,00eh,0e4h,011h,041h,00bh,0e4h,002h,0feh,002h,0edh,004h,041h	; bf0d  .."A...A.......A
	defb 002h,0f1h,002h,0d1h,004h,041h,002h,0f1h,002h,0d1h,004h,0e4h,002h,0feh,008h,0edh	; bf1d  .....A..........
	defb 002h,0e4h,005h,0d1h,083h,0edh,0e4h,0e4h,005h,0d1h,083h,0edh,0e4h,0e4h,006h,0edh	; bf2d  ................
	defb 005h,0e4h,003h,0ech,002h,0c1h,003h,0e4h,081h,0ech,004h,0c1h,003h,0e4h,081h,0ech	; bf3d  ................
	defb 004h,0c1h,003h,0e4h,003h,0ech,002h,0c1h,000h,010h,001h,001h,001h,001h,001h,001h	; bf4d  ................
	defb 000h,001h,001h,001h,001h,001h,001h,001h,001h,080h,0bfh	; bf5d  ...........

; ----------------------------------------------------------------------
; DATOS guiones_BF68: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbf68..0xbf7b  (19 bytes)
DATA_guiones_BF68:
	defb 080h,080h,080h,080h,080h,080h,000h,001h,080h,080h,080h,080h,080h,080h,080h,001h	; bf68  ................
	defb 0fdh,000h,010h	; bf78

; ----------------------------------------------------------------------
; DATOS guiones_BF7B: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbf7b..0xbf7d  (2 bytes)
DATA_guiones_BF7B:
	defb 000h,020h	; bf7b

; ----------------------------------------------------------------------
; DATOS guiones_BF7D: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbf7d..0xbf84  (7 bytes)
DATA_guiones_BF7D:
	defb 000h,01bh,010h,00ah,004h,00ah,001h	; bf7d

; ----------------------------------------------------------------------
; DATOS guiones_BF84: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbf84..0xbf8c  (8 bytes)
DATA_guiones_BF84:
	defb 000h,01ah,004h,005h,006h,002h,003h,001h	; bf84  ........

; ----------------------------------------------------------------------
; DATOS guiones_BF8C: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbf8c..0xbfaa  (30 bytes)
DATA_guiones_BF8C:
	defb 000h,004h,0c0h,0b0h,080h,084h,082h,081h,082h,080h,080h,0e0h,038h,01ch,000h,005h	; bf8c  ............8...
	defb 0feh,03ch,01ch,08ch,000h,001h,083h,041h,000h,001h,007h,000h,001h,003h	; bf9c  .<.....A......

; ----------------------------------------------------------------------
; DATOS guiones_BFAA: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbfaa..0xbfbc  (18 bytes)
DATA_guiones_BFAA:
	defb 000h,008h,060h,058h,040h,040h,042h,041h,040h,071h,000h,00ah,07fh,01eh,00eh,046h	; bfaa  ..`X@@BA@q.....F
	defb 080h,041h	; bfba

; ----------------------------------------------------------------------
; DATOS guiones_BFBC: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbfbc..0xbfc3  (7 bytes)
DATA_guiones_BFBC:
	defb 000h,01bh,008h,00eh,004h,00eh,009h	; bfbc

; ----------------------------------------------------------------------
; DATOS guiones_BFC3: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbfc3..0xbfd0  (13 bytes)
DATA_guiones_BFC3:
	defb 000h,003h,004h,017h,01ch,074h,010h,000h,014h,080h,070h,010h,030h	; bfc3  .....t....p.0

; ----------------------------------------------------------------------
; DATOS guiones_BFD0: 1 piezas de sprite encajados: los que comparten cola
;   empiezan dentro del anterior
;   0xbfd0..0xbfde  (14 bytes)
DATA_guiones_BFD0:
	defb 000h,009h,080h,000h,001h,080h,040h,000h,004h,002h,001h,002h,000h,00ch	; bfd0  ......@.......

; ----------------------------------------------------------------------
; DATOS relleno_antes_de_la_marca: Dieciocho bytes de 0xFF: lo que queda entre
;   el ultimo archivo y la marca oculta de Konami
;   0xbfde..0xbff0  (18 bytes)
DATA_relleno_antes_de_la_marca:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfde  ................
	defb 0ffh,0ffh	; bfee

; ----------------------------------------------------------------------
; DATOS marca_oculta_de_konami: el numero de catalogo y el titulo en katakana,
;   escondidos detras del relleno 0xFF
;   0xbff0..0xc000  (16 bytes)
DATA_marca_oculta_de_konami:
	defb 0b7h,087h,0ach,08bh,087h,0b7h,09dh,000h,098h,000h,09fh,094h,089h,00dh,036h,0aah	; bff0  ..............6.
