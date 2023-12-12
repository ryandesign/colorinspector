; SPDX-FileCopyrightText: © 2017 Michael T. Barry
; SPDX-FileCopyrightText: © 2017 John Brooks
; SPDX-FileCopyrightText: © 2017 Peter Ferrie
; SPDX-License-Identifier: LicenseRef-DecPrintU16

;-------------------------------
; DecPrint - 6502 print 16 bits
;
; by Michael T. Barry 2017.07.07. Free to
; copy, use and modify, but without warranty
;
; Optimized by J.Brooks & qkumba 7/8/2017
;-------------------------------

;https://groups.google.com/g/comp.sys.apple2/c/_y27d_TxDHA

;ryandesign changes:
;get input number from A3L/A3H not A/X
;save and restore A/X/Y
;right align width 4

.export DecPrintU16

CH          =         $24       ;cursor horizontal position
ZpDecWord   =         $40       ;U16 being printed

PRHEX       =       $FDE3       ;print low nibble of A as hex
COUT        =       $FDF0       ;output character A
RESTORE     =       $FF3F       ;$45->A, $46->X, $47->Y
SAVE        =       $FF4A       ;A->$45, X->$46, Y->$47

;-------------------------------
; Print U16 as decimal via COUT
; IN: A3H=hi, A3L=lo
;-------------------------------
.proc DecPrintU16
            jsr SAVE
            ldy #3
@DoDigit:   lda #0              ;Remainder=0
            clv                 ;V=0 means div result = 0
            ldx #16             ;16-bit divide
@Div10:     cmp #10/2           ;Calc ZpDecWord/10
            bcc @Under10
            sbc #10/2+$80       ;Remove digit & set V=1 to show div result > 0
            sec                 ;Shift 1 into div result
@Under10:   rol ZpDecWord       ;Shift /10 result into ZpDecWord
            rol ZpDecWord+1
            rol                 ;Shift bits of input into acc (input mod 10)
            dex
            bne @Div10          ;Continue 16-bit divide
            pha                 ;Push low digit 0-9 to print
            lda #>(PRHEX-2)
            pha                 ;Push address of one opcode before PRHEX
            lda #<(PRHEX-2)     ;which is PLA
            pha
            dey
            bvs @DoDigit        ;If V=1, result of /10 was > 0 & do next digit
@align:     inc CH
            dey
            bpl @align
            jmp RESTORE
.endproc
