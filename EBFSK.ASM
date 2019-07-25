;**************************************
;******  PLACA DE AUTOSELECCION  ******
;******                          ******
;****** ASSEMBLER 68705/C8       ******
;**************************************
;*
;*


;* DEFINICION DE LOS PORTS

PORTA EQU 00
PORTB EQU 01
PORTC EQU 02
PORTD EQU 03
PCA   EQU 04
PCB   EQU 05
PCC   EQU 06
PCD   EQU 07

;* POSICION DE LOS BUFERS


RESET   EQU 100H          ;*RESET.
WADOG   EQU 010H          ;*REGISTRO WATCH DOG

        ORG RAM

SAVA            rmb 1
SAVX            rmb 1
OPER            rmb 1
BPRA            rmb 1
CntByte         rmb 1
carr            rmb 1
result          rmb 6
PntResta        rmb 1
resultRes       rmb 6
string          rmb 10
temp            rmb 1

          ORG ROM

;*****************ÝINICIALIZACION DE LOS PORTS Ý****************

        sei

        ldx #RAM
bc:
        clra
        sta ,x
        incx
        cpx #$ff
        bne bc

        clr  DDRA         ;*PORT A BIT 0 SALIDAS RESTO ENTRADAS

        CLR PORTB
        lda #$ff
        STA DDRB

        bclr 3,DDRB
        bclr 0,DDRB

        lda PORTB
        and #$01
        sta result+4
        lda PORTA
        sta result+5

        clc
        lda result+5
        inca
        sta result+5
        lda result+4
        adc #$0
        sta result+4
        jsr Hex2Asc

        bset 4,PORTB            ;*Activa el PTT
        jsr bucle
        jsr bucle
        jsr bucle
        jsr bucle
        jsr bucle
        jsr bucle
        jsr bucle
        jsr bucle



        bset 1,PORTB              ;*desactiva el microfono
        brclr 3,PORTB,salton      ;*mira si hay test
        jmp test

salton:
        lda #$30
        sta oper                ;*beep
        jsr uno

cabeza:
        ldx #$4                 ;*saca 4 bytes
cabe:
        lda tono                ;*primer byte del buffer del tono
        jsr out
        decx
        bne cabe

        ldx #$1
cabe2:
        lda tono,x
        cmp #$ff
        beq FinCabe
        jsr out                 ;*transmite cabecera
        incx
        bra cabe2

FinCabe:                ;*Transmite indicativo

        lda string+7
        jsr out
        lda string+8
        jsr out
        lda string+9
        jsr out


        bclr 4,PORTB            ;*DESACTIVA PTT
        bclr 1,PORTB            ;*ACTIVA EL MICROFONO
        stop
;*-------------- Convierte un n£mero binario a ascii decimal -----------------
;* Convierte un n£mero binario a una cadena de car cteres ascii
;* El n£mero ha de estar en result
;* La cadena la pone en string


hex2asc:
        clr sava
        clr savx
        clr PntResta
BucHex
        jsr resta
        bcs HayC

        lda ResultRes
        sta Result
        lda ResultRes+1
        sta Result+1
        lda ResultRes+2
        sta Result+2
        lda ResultRes+3
        sta Result+3
        lda ResultRes+4
        sta Result+4
        lda ResultRes+5
        sta Result+5
        inc sava

BucH:
        lda PntResta
        cmp #$32
        bne BucHex
        rts


HayC:

        ldx savx
        lda sava
;        add #'0'
        sta string,x
        inc savx
        clr sava
        lda PntResta
        add #$5
        sta PntResta
        bra BucH
;*----------------------------------- RESTA -----------------------------------
resta:

        clr carr
        lda #$5
        sta CntByte
        lda PntResta
        add #$4
        sta PntResta
        tax

restB:
        ldx PntResta
        dec PntResta
        lda const,x
        add carr
        sta temp
        clr carr

        ldx CntByte
        lda result,x
        sub temp
        bcc NoCarry

        inc carr

NoCarry:
        ldx CntByte
        sta ResultRes,x
        dec CntByte
        lda CntByte
        bne restB
        inc PntResta
        clc
        lda carr
        beq FinRes
        sec
FinRes:
        rts

;*------------------------------------------------------------------------------
test:

        jsr unos
        jsr ceros
        bra test

;*---------------------------------- SUBRUTINAS --------------------------------



out:                    ;*saca los tonos
        stx savx
        ldx #$5         ;*bytes de 5 bits
        jsr ceros       ;*start

out1:
        rora
        bcs alto
        jsr ceros

salou:
        decx
        bne out1
        jsr unos        ;*1 bit de stop
        ldx savx
        rts

alto:
        jsr unos
        bra salou


ceros:
        sta sava
        lda #$4
        sta oper
cero:
        bset 2,PORTB
        jsr c2400
        bclr 2,PORTB
        jsr c2400
        dec oper
        bne cero
        lda sava
        rts

unos:
        sta sava
        lda #$2         ;*dos ciclos de 1200 para 1
        sta oper
uno:
        bset 2,PORTB
        jsr c1200
        bclr 2,PORTB
        jsr c1200
        dec oper
        bne uno
        lda sava
        rts


c1200:
        lda #$6e        ;*tiempos para el cristal de 4.43 mhz
                        ;*8a = cpu / 6a = emulador
c1201:
        deca
        bne c1201
        nop
        nop
c1202:
        lda #$19
c1203:
        deca
        bne c1203
        nop
        nop
        rts

c2400:
        lda #$40        ;*40 emulador y cpu
c2402:
        deca
        bne c2402
        nop
        nop
        nop
        nop
        nop
        nop
        rts


tep:
        ldx #$18

tmp1:
        lda #$2
        sta oper
tmp:
        jsr c1200
        jsr c1200
        dec oper
        bne tmp
        decx
        bne tmp1

        lda bpra
        beq fitemp
        dec bpra
        jmp tep

fitemp:
        rts

;*------------------------------------------------------------------------------


bucle:
        ldx #$3f
bu0     lda #$ff
bu1     nop
        nop
        nop
        deca
        bne bu1
        decx
        bne bu0
        rts

;*----------------------------- ROM DATA -----------------------------------

const:

         fcb 0,3bh,9ah,0cah,0
         fcb 0,5h,0f5h,0e1h,0
         fcb 0,0,98h,96h,80h
         fcb 0,0,0fh,42h,40h
         fcb 0,0,1,86h,0a0h
         fcb 0,0,00h,27h,10h
         fcb 0,0,00h,3h,0e8h
         fcb 0,0,00h,00h,64h
         fcb 0,0,00h,00h,0ah
         fcb 0,0,00h,00h,01h

        ;*para miramar cabecera         = 1ch,1bh,1ah
        ;*para bajo llobregat cabecera  = 1ch,17h
        ;*para radio movil cabecera     = 1ch,1bh
        ;*para servi taxi               = 1ch,1ch

        ;*xx = indicativo

tono:
       fcb 1ch,1bh,1ah,0ffh

;*------------------------------------------------------------------------------


;*=========================== OTRAS INTERRUPCIONES =============================

SPI:
SCI:
TIMER:
SWI:
IRQ:
        RTI
;*==============================================================================

;*------------------- INICIALIZACION DE LOS VECTORES ----------------------
        org $7f1
        db $28           ;*MOR set for PORT A ints and LEVEL ints

        org $7f8
        dw TIMER
        dw IRQ
        dw ROM
        dw ROM
;*-----------------------------------------------------------------------------

        END

