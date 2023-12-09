; SPDX-FileCopyrightText: © 2023 Ryan Carsten Schmidt <https://github.com/ryandesign>
; SPDX-License-Identifier: MIT

.import VAPORLK

.include "samepage.inc"

CH          =         $24       ;cursor horizontal position
BASL        =         $28       ;low byte of text row base address
YSAV        =         $34       ;place to save Y register
A1L         =         $3C       ;general purpose A1 register low byte
A1H         =         $3D       ;general purpose A1 register high byte
A2L         =         $3E       ;general purpose A2 register low byte
A2H         =         $3F       ;general purpose A2 register high byte
A3L         =         $40       ;general purpose A3 register low byte
A3H         =         $41       ;general purpose A3 register high byte
A4L         =         $42       ;general purpose A4 register low byte
A4H         =         $43       ;general purpose A4 register high byte
HGR1SCRN    =       $2000       ;hires page 1 base address
KBD         =       $C000       ;keyboard value
KBDSTRB     =       $C010       ;keyboard strobe
TXTCLR      =       $C050       ;graphics
TXTSET      =       $C051       ;text
MIXCLR      =       $C052       ;no split
MIXSET      =       $C053       ;split
LORES       =       $C056       ;lores
HIRES       =       $C057       ;hires
AN0OFF      =       $C058       ;annunciator 0 off
AN0ON       =       $C059       ;annunciator 0 on
AN1OFF      =       $C05A       ;annunciator 1 off
AN1ON       =       $C05B       ;annunciator 1 on
AN2OFF      =       $C05C       ;annunciator 2 off
AN2ON       =       $C05D       ;annunciator 2 on
AN3OFF      =       $C05E       ;annunciator 3 off
AN3ON       =       $C05F       ;annunciator 3 on
BUTN0       =       $C061       ;pushbutton 0
BUTN1       =       $C062       ;pushbutton 1
PREAD       =       $FB1E       ;machine identification byte
INIT        =       $FB2F       ;set text mode, page 1, lores, standard text window
TABV        =       $FB5B       ;set cursor vertical position
VERSION     =       $FBB3       ;machine identification byte
HOME        =       $FC58       ;clear text screen 1 and move cursor to top left
CROUT       =       $FD8E       ;print carriage return
PRHEX       =       $FDE3       ;print low nibble of A as hex
COUT        =       $FDF0       ;output character A
IDROUTINE   =       $FE1F       ;identify if machine is iigs
SETNORM     =       $FE84       ;set normal text
SETKBD      =       $FE89       ;set KSW to KEYIN
SETVID      =       $FE93       ;set CSW to COUT1
RESET       =       $FFFC       ;reset vector

SCRNWIDTH   =          40       ;screen width in characters

;define a string in which every char except the last one has the high bit set
.macro defstr name, str
    .ident(.concat(name, "len")) = .strlen(str)
    .ident(name):
    .repeat .strlen(str) - 1, i
        .byte .strat(str, i) | %10000000
    .endrepeat
    .byte .strat(str, .strlen(str) - 1) & $7F
.endmacro

;load the given memory address into A3
.macro la3 addr
            lda #<addr
            sta A3L
            lda #>addr
            sta A3H
.endmacro

;output the string at the given memory address
.macro coutstr addr
            la3 addr
            jsr couta3
.endmacro

.rodata

defstr "colorinsp",     "COLOR INSPEC][R"
defstr "anykey",        "Press any key to exit"
defstr "black",         "Black"
defstr "magenta",       "Magenta"
defstr "darkblue",      "Dark blue"
defstr "purple",        "Purple"
defstr "darkgreen",     "Dark green"
defstr "gray",          "Gray"
defstr "mediumblue",    "Medium blue"
defstr "lightblue",     "Light blue"
defstr "brown",         "Brown"
defstr "orange",        "Orange"
defstr "pink",          "Pink"
defstr "green",         "Green"
defstr "yellow",        "Yellow"
defstr "aqua",          "Aqua"
defstr "white",         "White"

.define colors black, magenta, darkblue, purple, darkgreen, gray, mediumblue, lightblue, brown, orange, gray, pink, green, yellow, aqua, white
colorslo: .lobytes colors
colorshi: .hibytes colors

.code

.proc main
            jsr SETNORM
            jsr INIT
            jsr SETVID
            jsr SETKBD
            jsr HOME
            lda AN0OFF
            lda AN1OFF
            lda AN2ON
            lda AN3ON
            jsr clearhires

            lda #(SCRNWIDTH - colorinsplen + 1) / 2
            sta CH
            ldy #colorinsplen
            jsr underline
            coutstr colorinsp

            lda #23
            jsr TABV
            lda #(SCRNWIDTH - anykeylen + 1) / 2
            sta CH
            coutstr anykey

            ldx #23
@nextline:  txa
            jsr TABV
            lda #0
            tay
            sta (BASL),y
            ldy #39
            sta (BASL),y
            dex
            bpl @nextline

            ldx #15
@nextcolor: txa
            adc #4
            jsr TABV
            lda #1
            sta CH
            txa
            jsr PRHEX
            inc CH
            lda colorslo,x
            sta A3L
            lda colorshi,x
            sta A3H
            jsr couta3
            lda BASL
            adc #15
            sta BASL
            txa
            ;sta A3L
            asl
            asl
            asl
            asl
            ;adc A3L
            ldy #10
@drawbar:   sta (BASL),y
            dey
            bpl @drawbar
            dex
            bpl @nextcolor

@nextframe: jsr VAPORLK
            ldx #8
            jsr textscanlines
            ldx #8
            jsr hiresscanlines
            ldx #16
            jsr textscanlines
            ldx #128
            jsr colorbarscanlines
            ldx #32
            jsr textscanlines

            lda BUTN0
            bmi @waitkeyup
            lda BUTN1
            bmi @waitkeyup
            lda KBD
            bpl @nextframe
            bit KBDSTRB
@waitkeyup: sta TXTSET
            jsr HOME
            lda BUTN0
            bmi @waitkeyup
            lda BUTN1
            bmi @waitkeyup
            jmp (RESET)
.endproc

.proc clearhires
            lda #$0
            ldx #$20
            ldy #$3F
            ;fall through to clearscreen
.endproc

;input: A = value to set each byte to; X = high byte start; Y = high byte end
.proc clearscreen
            stx @cpy + 1
@outerloop: sty @sta1 + 2
            sty @sta2 + 2
            ldx #119
@innerloop:
@sta1:      sta $780,x          ;self-modifying!
@sta2:      sta $700,x          ;self-modifying!
            dex
            bpl @innerloop
            dey
@cpy:       cpy #$4             ;self-modifying!
            bcs @outerloop
            rts
.endproc

;underline line 1
;input: A = horizontal character position, Y = length (min 2)
.proc underline
            clc
            adc #$80
            sta A1L
            lda #>HGR1SCRN
            ldx VERSION
            cpx #6
            beq @iie
            lda #>HGR1SCRN + 4
@iie:       sta A1H
            dey
            lda #%00111111
            sta (A1L),Y
            dey
            lda #%01111111
@loop:      sta (A1L),Y
            dey
            bne @loop
            lda #%01111110
            sta (A1L),Y
            rts
.endproc

;output a string
;input: A3 = string
.proc couta3
            tya
            pha
            ldy #$0             ;start at 1st character
            beq @load           ;always
@loop:      jsr machinecout     ;output character
            iny                 ;move to next character
@load:      lda (A3L),Y         ;load character
            bmi @loop           ;loop if high bit is set
            ora #%10000000      ;set high bit
            jsr machinecout     ;output character
            pla
            tay
            rts
.endproc

;output a character appropriate for this machine, converting lowercase to
;uppercase if not iie or newer
;input: A = character
.proc machinecout
            sty YSAV
            ldy VERSION
            cpy #$6
            beq @cout           ;don't convert if iie or newer
            cmp #'a' | %10000000
            bcc @cout           ;don't convert if not lowercase
            cmp #('z' + 1) | %10000000
            bcs @cout           ;don't convert if not lowercase
            and #%11011111      ;lowercase to uppercase
@cout:      ldy YSAV
            jmp COUT            ;output character
.endproc

;wait 31 cycles (including jsr and rts)
.proc wait31                    ;6
            jsr wait12          ;12
            php                 ;3
            plp                 ;4
            ;fall through to wait12
.endproc

;wait 12 cycles (including jsr and rts)
.proc wait12                    ;6
            rts                 ;6
.endproc

.proc textscanlines
@scanline:  sta TXTSET          ;4
            jsr wait31          ;31
            php                 ;3
            sta TXTCLR          ;4
            plp                 ;4
            dex                 ;2
  samepage  beq,@end            ;2+1
            jsr wait12          ;12
  samepage  bne,@scanline       ;3 always
@end:       rts                 ;6
.endproc

.proc hiresscanlines
@scanline:  sta HIRES           ;4
            jsr wait31          ;31
            php                 ;3
            sta LORES           ;4
            plp                 ;4
            dex                 ;2
  samepage  beq,@end            ;2+1
            jsr wait12          ;12
  samepage  bne,@scanline       ;3 always
@end:       rts                 ;6
.endproc

.proc colorbarscanlines
@scanline:  sta TXTSET          ;4
            php                 ;3
            plp                 ;4
            php                 ;3
            sta TXTCLR          ;4
            plp                 ;4
            php                 ;3
            sta TXTSET          ;4
            plp                 ;4
            php                 ;3
            nop                 ;2
            sta TXTCLR          ;4
            plp                 ;4
            dex                 ;2
  samepage  beq,@end            ;2+1
            jsr wait12          ;12
  samepage  bne,@scanline       ;3 always
@end:       rts                 ;6
.endproc
