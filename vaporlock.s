; SPDX-FileCopyrightText: © 1983 Don Lancaster and Synergetics <https://www.tinaja.com>
; SPDX-License-Identifier: LicenseRef-Vaporlock

.export VAPORLK

.include "samepage.inc"

.align 256

FULL        =   $C052
GR          =   $C050
LORES       =   $C056
HIRES       =   $C057
IDBYTE      =   $06
PAGE1       =   $C054
SNIFF       =   GR
TEXT        =   $C051
VBLANK      =   $C019
VERSION     =   $FBB3
WAIT        =   $FCA8

ID0         =   $DB
ID1         =   $24
ID2         =   $B6
ID3         =   $49
ID4         =   $88
ID5         =   $F3

.proc VAPORLK
                PHP
                PHA

                LDA     #ID0
                STA     $3FF8
                STA     $3FF9
                STA     $3FFA
                STA     $3FFB
                STA     $3FFC
                STA     $3FFD
                STA     $3FFE

                LDA     #ID1
                STA     $2BF8
                STA     $2BF9
                STA     $2BFA
                STA     $2BFB
                LDA     #ID2
                STA     $2BFC
                STA     $2BFD
                STA     $2BFE

                LDA     #ID3
                STA     $2FF8
                STA     $2FF9
                LDA     #ID4
                STA     $2FFA
                STA     $2FFB

                LDA     #ID5
                STA     $33F8
                LDA     #ID5-1
                STA     $33F9

;                LDA     #IDBYTE
;                CMP     VERSION
;                BNE     MORE0
;VBFIND:         BIT     VBLANK
;                BMI     VBFIND

MORE0:          BIT     GR
                BIT     HIRES
                BIT     FULL
                BIT     PAGE1

LOCK:           LDA     #ID0
RETRY1:         CMP     SNIFF
       samepage BNE,    RETRY1
                LDA     #$02
                JSR     WAIT
                PHA
                PLA
                LDA     SNIFF
                CMP     #ID2
       samepage BEQ,    MORE1
                CMP     #ID1
       samepage BEQ,    MORE1
       samepage BNE,    LOCK

MORE1:          LDA     #$02
                JSR     WAIT
                LDA     SNIFF
                CMP     #ID4
       samepage BEQ,    MORE2
                CMP     #ID3
       samepage BEQ,    MORE3

MORE2: samepage BNE,    LOCK
MORE3:          LDA     #$02
                JSR     WAIT
                LDA     SNIFF
                LSR
       samepage BCS,    MORE4

MORE4:          CMP     #ID5/2
       samepage BNE,    LOCK
                NOP

STALL:          LDA     #$05
                JSR     WAIT
                LDA     #$02
                JSR     WAIT

FIX2PLUS:       LDA     #IDBYTE
                CMP     VERSION
       samepage BNE,    SHOW

SHOW:           BIT     SNIFF
                BIT     SNIFF
                BIT     SNIFF
                BIT     LORES

PHASE:          CLC
       samepage BCS,    MORE5
MORE5:          ;NOP
                ;NOP
                ;NOP
                ;NOP

                PLA
                PLP
                RTS
.endproc
