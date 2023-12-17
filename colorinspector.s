; SPDX-FileCopyrightText: © 2023 Ryan Carsten Schmidt <https://github.com/ryandesign>
; SPDX-License-Identifier: MIT

.import VAPORLK
.import DecPrintU16

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
IOADR       =       $C000       ;I/O addresses
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

SWITCHES    =        $300       ;table of switch address low bytes
SCRNWIDTH   =          40       ;screen width in characters
NUMCOL      =           1       ;column for color number
BARCOL      =          15       ;start column for color bar
BARLEN      =          11       ;length of color bar
HEADERSCOL  =          26       ;start column for headers

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
defstr "headers",       "Phase Amp Lum"
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

;http://mrob.com/pub/xapple2/colors.html

            ;  phase amp lum
pal:        .byte  0,  0,  0
            .byte 18, 12,  5
            .byte  0, 12,  5
            .byte  9, 20, 10
            .byte 54, 12,  5
            .byte  0,  0, 10
            .byte 63, 20, 10
            .byte  0, 12, 15
            .byte 36, 12,  5
            .byte 27, 20, 10
            .byte  0,  0, 10
            .byte 18, 12, 15
            .byte 45, 20, 10
            .byte 36, 12, 15
            .byte 54, 12, 15
            .byte  0,  0, 20

.code

.proc main
                                ;initialization copied from ROM RESET routine:
            jsr SETNORM         ;use normal (not inverse) text
            jsr INIT            ;text mode, page 1, lores, standard text window
            jsr SETVID          ;use standard character output routine
            jsr SETKBD          ;use standard keyboard input routine
            jsr HOME            ;clear screen and move cursor to top left
            lda AN0OFF          ;annunciators to standard
            lda AN1OFF
            lda AN2ON
            lda AN3ON

            jsr clearhires      ;clear hires page 1 to black

            lda #(SCRNWIDTH - colorinsplen + 1) / 2
            sta CH              ;position cursor for title
            ldy #colorinsplen   ;load length of title into Y
            jsr underline       ;draw underline for title on hires screen
            coutstr colorinsp   ;print title

            lda #2              ;load headers row number into A
            jsr TABV            ;vertical tab to there
            lda #HEADERSCOL     ;load headers column number into A
            sta CH              ;position cursor for headers
            coutstr headers     ;print headers

            lda #23             ;load "press any key" row number into A
            jsr TABV            ;vertical tab to there
            lda #(SCRNWIDTH - anykeylen + 1) / 2
            sta CH              ;position cursor for "press any key"
            coutstr anykey      ;print "press any key"

            ldx #15             ;load last color number into X
@nextcolor: txa                 ;copy color number to A
            adc #4              ;add 4 to A (row number)
            jsr TABV            ;vertical tab to there

            lda #NUMCOL         ;load column for color number into A
            sta CH              ;position cursor there
            txa                 ;copy color number to A
            jsr PRHEX           ;print it in hexadecimal

            inc CH              ;move one space to the right
            lda colorslo,x      ;load color name string
            sta A3L
            lda colorshi,x
            sta A3H
            jsr couta3          ;print color name string

            lda #HEADERSCOL + 1
            sta CH              ;position cursor for phase column
            txa                 ;copy color number to A
            sta A2L             ;store A in A2L
            asl                 ;shift A left (multiply by two)
            adc A2L             ;add A2L to A (now color multiplied by three)
            tay                 ;copy A to Y (value table start offset)
            adc #3              ;add 3 to A
            sta A2L             ;store A in A2L (value table end offset)
@nextcol:   lda #0              ;load 0 into A
            sta A3H             ;store A in A3H
            lda pal,y           ;load next value for this color into A
            sta A3L             ;store A in A3L
            asl                 ;shift A left (multiply by two)
            asl                 ;shift A left (multiply by two)
            adc A3L             ;add A3L to A (now value multiplied by five)
            sta A3L             ;store A in A3L
            rol A3H             ;rotate carry, if any, into A3H
            jsr DecPrintU16     ;print value in decimal
            iny                 ;increment Y
            cpy A2L             ;have we printed all values for this color yet?
            bcc @nextcol        ;if not, loop to print the next one

            lda BASL            ;load low byte of row base address into A
            adc #BARCOL - 2     ;add color bar start column address to A
            sta BASL            ;store A in BASL
            txa                 ;copy color number to A
            sta A3L             ;store A in A3L
            asl                 ;shift it into the high nibble
            asl
            asl
            asl
            adc A3L             ;add color number to A (now in both nibbles)
            ldy #BARLEN         ;load color bar length into Y
@drawbar:   sta (BASL),y        ;plot two (stacked) pixels on the lores screen
            dey                 ;decrement Y
            bne @drawbar        ;if not done, loop to the next pixels
            dex                 ;decrement X
            bpl @nextcolor      ;if not done, loop to the next color

                                ;build a table of screen switches that will be
                                ;accessed on color bar scanlines because it's
                                ;quicker to access a table than compute this on
                                ;the fly. for each color the first and last
                                ;lines come from the hires screen (black) and
                                ;the middle six are from the lores screen (the
                                ;color bar). adjust one pixel lower on the ii
                                ;and ii+ to match its character generator.
            inx                 ;load 0 into X
            lda VERSION         ;load computer ID byte into A
            cmp #6              ;check if it's a iie or later
            beq @iie            ;if yes, no adjustment needed
            inx                 ;increment X
@iie:       stx A3L             ;store X in A3L
            ldx #128            ;load number of bar scanlines into X
@nextswitch:txa                 ;copy X to A
            clc                 ;clear carry
            adc A3L             ;add A3L to A
            and #%00000110      ;is this a middle-six line?
            beq @add            ;if no, A is 0
            lda #$FF            ;if yes, A is $FF
@add:       adc #<HIRES         ;A is now low byte of HIRES or LORES
            sta SWITCHES,x      ;store it in the table
            dex                 ;decrement X
            bne @nextswitch     ;if not done, loop to next switch

            stx A3L             ;store 0 in A3L
@nextframe: jsr VAPORLK         ;find start of next video frame
            ldx #8              ;load number of scanlines into X
            jsr textscanlines   ;show that many mostly-text scanlines
            ldx #8              ;load number of scanlines into X
            jsr hiresscanlines  ;show that many hires scanlines
            ldx #16             ;load number of scanlines into X
            jsr textscanlines   ;show that many mostly-text scanlines
            ldx #128            ;load number of scanlines into X
            jsr barscanlines    ;show that many text-and-color-bar scanlines
            ldx #32             ;load number of scanlines into X
            jsr textscanlines   ;show that many mostly-text scanlines

                                ;exit if there was a keypress, including apple
                                ;keys, but wait until apple keys are up before
                                ;exiting because we exit via reset which would
                                ;start the self-test if apple keys were down
            lda A3L             ;load A3L into A
            tay                 ;copy A to Y
            bit KBD             ;check if key was pressed
            bpl @checkbtn0      ;if no, check buttons
            lda #$FF            ;load #FF into A
@checkbtn0: bit BUTN0           ;check if button 0 is down
            bmi @pressed        ;if yes, update registers
@checkbtn1: bit BUTN1           ;check if button 1 is down
            bpl @after          ;if no, don't update registers
@pressed:   iny                 ;increment Y
            lda #$FF            ;load $FF into A
@after:     sta A3L             ;store A in A3L
            iny                 ;increment Y
            bne @nextframe      ;if no user input, loop for next frame

            bit KBDSTRB         ;indicate keypress was handled
            sta TXTSET          ;text mode
            jsr HOME            ;clear the screen
            jmp (RESET)         ;exit by resetting to BASIC or monitor
.endproc

;clear hires page 1 to black
.proc clearhires
            lda #$0             ;load 0 (black) into A
            ldx #$20            ;load hires page 1 start high byte into X
            ldy #$3F            ;load hires page 1 end high byte into Y
            ;fall through to clearscreen
.endproc

;clear any screen to any value
;
;input: A = value to set each byte to; X = high byte start; Y = high byte end
.proc clearscreen
            stx @cpy + 1        ;modify the cpy instruction below
@outerloop: sty @sta1 + 2       ;modify the sta instructions below
            sty @sta2 + 2
            ldx #119            ;load last offset into X
@innerloop:
@sta1:      sta $780,x          ;store byte in screen (address modified above!)
@sta2:      sta $700,x          ;store byte in screen (address modified above!)
            dex                 ;decrement X
            bpl @innerloop      ;if not done, loop
            dey                 ;decrement Y
@cpy:       cpy #$4             ;check if done (value modified above!)
            bcs @outerloop      ;if not done, loop
            rts                 ;return
.endproc

;underline line 1
;
;input: A = horizontal character position, Y = length (min 2)
.proc underline
            clc                 ;clear carry
            adc #$80            ;add $80 to A (moving down 8 scanlines)
            sta A1L             ;store A in A1L
            lda #>HGR1SCRN      ;load hires page 1 high byte into A
            ldx VERSION         ;load computer ID byte into X
            cpx #6              ;check if it's a iie or later
            beq @iie            ;if yes, no adjustment needed
            lda #>HGR1SCRN + 4  ;move down by one more scanline
@iie:       sta A1H             ;store A in A1H
            dey                 ;decrement Y
            lda #%00111111      ;load 6 white pixels and 1 black pixel into A
            sta (A1L),Y         ;store byte in screen
            dey                 ;decrement Y
            lda #%01111111      ;load 7 white pixels into A
@loop:      sta (A1L),Y         ;store byte in screen
            dey                 ;decrement Y
            bne @loop           ;loop to next pixels
            lda #%01111110      ;load 1 black pixel and 6 white pixels into A
            sta (A1L),Y         ;store byte in screen
            rts                 ;return
.endproc

;output a string
;
;input: A3 = string
.proc couta3
            tya                 ;copy Y to A
            pha                 ;push A
            ldy #$0             ;start at zeroth character
            beq @load           ;always
@loop:      jsr machinecout     ;output character
            iny                 ;move to next character
@load:      lda (A3L),Y         ;load character
            bmi @loop           ;loop while high bit is set
            ora #%10000000      ;set high bit
            jsr machinecout     ;output character
            pla                 ;pull A
            tay                 ;copy A to Y
            rts                 ;return
.endproc

;output a character appropriate for this machine, converting lowercase to
;uppercase if not iie or later
;
;input: A = character
.proc machinecout
            sty YSAV            ;store Y in YSAV
            ldy VERSION         ;load computer ID byte into Y
            cpy #$6             ;check if it's a iie or later
            beq @cout           ;don't convert if iie or later
            cmp #'a' | %10000000
            bcc @cout           ;don't convert if not lowercase
            cmp #('z' + 1) | %10000000
            bcs @cout           ;don't convert if not lowercase
            and #%11011111      ;convert lowercase to uppercase
@cout:      ldy YSAV            ;load YSAV into Y
            jmp COUT            ;output character
.endproc

;wait 46 cycles (including jsr and rts)
.proc wait46                    ;6
            jsr wait12          ;12
            cmp A3L             ;3
            ;fall through to wait31
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

;wait 65 * X cycles (including ldx, jsr, and rts) for mostly-text scanlines
;
;on entry, graphics mode is on. leave graphics mode on for the first and last
;columns, switching to text mode in between. the mode during horizontal blanking
;-- text or graphics -- determines whether the color burst will be produced, and
;monitors want all scanlines either to have or not to have the color burst.
;
;input: X = number of scanlines
.proc textscanlines             ;6
@scanline:  sta TXTSET          ;4  text mode
            jsr wait31          ;31
            php                 ;3
            sta TXTCLR          ;4  graphics mode
            plp                 ;4
            dex                 ;2
  samepage  beq,@end            ;2+1
            jsr wait12          ;12
  samepage  bne,@scanline       ;3  always
@end:       rts                 ;6
.endproc

;wait 65 * X cycles (including ldx, jsr, and rts) for hires scanlines
;
;on entry, graphics and hires modes are already on so this routine only needs
;to delay by the right amount.
;
;input: X = number of scanlines
.proc hiresscanlines            ;6
@scanline:  jsr wait46          ;46
            dex                 ;2
  samepage  beq,@end            ;2+1
            jsr wait12          ;12
  samepage  bne,@scanline       ;3  always
@end:       rts                 ;6
.endproc

;wait 65 * X cycles (including ldx, jsr, and rts) for color bar scanlines
;
;on entry, graphics and hires modes are on. switch to text mode after the first
;column to show the color number and name. preset which graphics mode we'll use
;by loading from the lookup table. switch to that graphics mode to show either
;the color bar from the lores screen or the black gaps between the bars from the
;hires screen. back to text mode for the phase/amp/lum values. finally, back to
;hires graphics mode on the last column before horizontal blanking.
;
;input: X = number of scanlines
.proc barscanlines              ;6
@scanline:  sta TXTSET          ;4  text mode for color number and name
            ldy SWITCHES,x      ;4  load low byte of switch into Y
            lda IOADR,y         ;4  access the switch (lores or hires)
            nop                 ;2
            sta TXTCLR          ;4  graphics mode for color bar
            php                 ;3
            plp                 ;4
            sta TXTSET          ;4  text mode for phase/amp/lum values
            sta HIRES           ;4  hires mode
            nop                 ;2
            php                 ;3
            sta TXTCLR          ;4  back to graphics mode at end of line
            plp                 ;4
            dex                 ;2
  samepage  beq,@end            ;2+1
            jsr wait12          ;12
  samepage  bne,@scanline       ;3  always
@end:       rts                 ;6
.endproc
