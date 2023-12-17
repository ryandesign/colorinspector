; SPDX-FileCopyrightText: © 1983 Don Lancaster and Synergetics <https://www.tinaja.com>
; SPDX-License-Identifier: LicenseRef-Vaporlock

.export VAPORLK

.include "samepage.inc"

;.align 256

;               ORG     $8AFF   ; FOR HIGH HRCG CHARACTER SET

;   *****************************************
;   *                                       *
;   *           - < VAPORLOCK > -           *
;   *                                       *
;   *      (FAST AND EXACT FIELD SYNC)      *
;   *                                       *
;   *       VERSION 1.0 ($8AFF-$8BC7)       *
;   *    for the APPLE II+ and APPLE IIe    *
;   *                                       *
;   *               10-12-83                *
;   *.......................................*
;   *                                       *
;   *          COPYRIGHT C 1983 BY          *
;   *                                       *
;   *     DON LANCASTER AND SYNERGETICS     *
;   *     BOX 1300, THATCHER AZ., 85552     *
;   *            (602) 428-4073             *
;   *                                       *
;   *     ALL COMMERCIAL RIGHTS RESERVED    *
;   *****************************************


;             *** WHAT IT DOES ***

;   This subroutine gives you a fast and exact field
;   sync that locks to the video screen in as few as
;   nine scan lines.  No hardware mods are needed.
;
;   The same code works on the Apple II+ or IIe.
;
;   The vaporlock, with suitable support software,
;   lets you mix and match HIRES, LORES, and text
;   anywhere on the screen, provides for glitchless
;   animation, simplifies light pens, allows grey
;   scale, text-over-color, professional video wipes,
;   and offers many other new visual display tricks
;   that seem "impossible" to do on a stock Apple.
;
;   Typical displays are totally free from any
;   glitches or jitter.


;             *** HOW TO USE IT ***

;   To lock to the video timing, do a JSR VAPORLK at
;   $8B00 or CALL 35840.
;
;   The vaporlock exits exactly and precisely on the
;   start of a new video field.


;             *** GOTCHAS ***

;   This code only runs on "real" Apples.
;
;   Franklins, clones, and look-alikes may have
;   different timing that requires special code.
;
;   Certain oddball plug-in cards might interfere
;   with operation on the II+.  Such interference
;   is unlikely on the IIe.
;
;   Parts of the code have very critical timing
;   and must not cross a page boundary.  If you
;   relocate the code, put it all on one page.


;             *** ENHANCEMENTS ***

;   You can make a "phasing" adjustment by adding
;   or removing NOPs and branches in the PHASE code.
;   Note that a NOP or a branch not taken uses two
;   clock cycles, while a branch taken needs three.
;
;   You can preset the soft switches at the top of
;   the screen with suitable pokes to SHOW.
;
;   VAPORLK object code is relocatable, if you put
;   it all on one page of memory.  Be sure to protect
;   memory and link to your first or second address.


;             *** RANDOM COMMENTS ***

;   The accumulator and all flags are saved to the
;   stack.  No use is made of the X or Y registers.
;
;   The vaporlock exact field sync may be used in
;   your commercial programs provided fair credit
;   is prominently given.
;
;   VAPORLK may be loaded as the highest HRCG
;   character set.
;
;   Program length is $C8 (200) bytes.


;             *** HOOKS ***

FULL        =   $C052   ; FULL SCREEN SOFT SWITCH
GR          =   $C050   ; GRAPHICS SOFT SWITCH
HIRES       =   $C057   ; HIRES SOFT SWITCH
IDBYTE      =   $06     ; ID VALUE FOR APPLE IIe
PAGE1       =   $C054   ; PAGE ONE SOFT SWITCH
SNIFF       =   GR      ; FLOATING DATA BUS READ ADDRESS
TEXT        =   $C051   ; TEXT SOFT SWITCH
VBLANK      =   $C019   ; JITTERY V BLANKING (IIe ONLY!)
VERSION     =   $FBB3   ; SYSTEM ID BYTE LOCATION
WAIT        =   $FCA8   ; MONITOR DELAY SUBROUTINE


;             *** CONSTANTS ***

ID0         =   $DB     ; ID BYTES FOR SYNC PATCH
ID1         =   $24     ;  (ALL SHOULD BE RARELY USED)
ID2         =   $B6     ;
ID3         =   $49     ;
ID4         =   $88     ;
ID5         =   $F3     ; THIS BYTE MUST BE ODD VALUE!


;          *** VAPORLOCK SUBROUTINE ****

;   There are three parts to the Vaporlock
;   subroutine.  These are SETUP, LOCK, and STALL.
;
;   SETUP works by writing a magic "id patch"
;   to invisible locations on the text screen.
;   These magic locations tap the unique 3FFX
;   to 2BFX transitions that happen only on
;   the invisible advance from line 255 to 256.
;
;   SETUP also forces the full HIRES1 mode
;   during the locking process.  A IIe-only
;   blanking search minimizes any entry glitches.
;
;   LOCK searches for the magic combinations
;   of invisible ID bytes, starting on line
;   255.  Four lines are needed for complete
;   and exact locking.  One half of the
;   possible jitter is eliminated on each of
;   the second, third, and fourth lines,
;   ending with an exact lock at the end of
;   blank screen line 258.
;
;   LOCK uses the "floating data bus" read
;   technique pioneered by Bob Bishop.  If
;   an Apple location is read addressed in
;   which there is no read hardware, a
;   floating data bus results.  This floating
;   data bus acts as a "sample and hold" that
;   saves the last video screen access.  The
;   "fumes" that remain from the previous
;   video screen access can be read as data.
;
;   STALL delays until the exact start of
;   the field.  It is presently set up
;   to exit exactly on the start of the live
;   screen at the top of the field.  You
;   can adjust this for phasing, or to gain
;   pre-screen time for setup or actions.
;   The exit is exact and jitter-free.
;
;   The FIX2+ routine provides one extra
;   delay cycle to adjust for screen switching
;   differences between the IIe and II+.
;   For II+ exotic (non-screen) field switching,
;   you might want to defeat this adjustment.


;                        ** SETUP **

.proc VAPORLK
;               NOP             ; EQUALIZE TO PAGE BOUNDARY
                PHP             ; SAVE FLAGS
                PHA             ; SAVE ACCUMULATOR

                LDA     #ID0    ; WRITE ID PATCH
                STA     $3FF8   ;  TO LINE #255
                STA     $3FF9   ;
                STA     $3FFA   ;
                STA     $3FFB   ;
                STA     $3FFC   ;
                STA     $3FFD   ;
                STA     $3FFE   ;

                LDA     #ID1    ;  TO LINE #256
                STA     $2BF8   ;
                STA     $2BF9   ;
                STA     $2BFA   ;
                STA     $2BFB   ;
                LDA     #ID2    ;
                STA     $2BFC   ;
                STA     $2BFD   ;
                STA     $2BFE   ;

                LDA     #ID3    ;  TO LINE 257
                STA     $2FF8   ;
                STA     $2FF9   ;
                LDA     #ID4    ;
                STA     $2FFA   ;
                STA     $2FFB   ;

                LDA     #ID5    ; AND FINALLY TO LINE 258
                STA     $33F8   ;
                LDA     #ID5-1  ;
                STA     $33F9   ;

;               LDA     #IDBYTE ; CHECK FOR A IIe
;               CMP     VERSION ;
;               BNE     MORE0   ;
;VBFIND:        BIT     VBLANK  ; WAIT TILL IIe BLANKING START
;               BMI     VBFIND  ;

MORE0:          BIT     GR      ; FORCE FULL HIRES PAGE ONE
                BIT     HIRES   ;
                BIT     FULL    ;
                BIT     PAGE1   ; THEN FALL THROUGH TO LOCK


;                        ** LOCK **

LOCK:           LDA     #ID0    ; LOOK FOR FIRST PATCH ID VALUE
RETRY1:         CMP     SNIFF   ;
       samepage BNE,    RETRY1  ;
                LDA     #$02    ; DELAY FOR EXACTLY 57 CYCLES
                JSR     WAIT    ; (HLINE-BNE-LDA#-LDA)
                PHA             ;
                PLA             ;
                LDA     SNIFF   ; GET SECOND PATCH ID VALUE
                CMP     #ID2    ; JITTER 4,5,OR 6?
       samepage BEQ,    MORE1   ;
                CMP     #ID1    ; JITTER 0,1,2, OR 3?
       samepage BEQ,    MORE1   ; OK TO CONTINUE
       samepage BNE,    LOCK    ; MISSED, TRY AGAIN

MORE1:          LDA     #$02    ; DELAY FOR EXACTLY 50 CYCLES
                JSR     WAIT    ;  (HLINE-4-CMP#-BEQ-LDA#-LDA)
                LDA     SNIFF   ; GET THIRD PATCH ID VALUE
                CMP     #ID4    ; JITTER 2 OR 3?
       samepage BEQ,    MORE2   ; YES
                CMP     #ID3    ; JITTER 0 OR 1
       samepage BEQ,    MORE3   ; ONLY WANT 2 CLOCK CORRECTION

MORE2: samepage BNE,    LOCK    ; CURSES! FOILED AGAIN!
MORE3:          LDA     #$02    ; DELAY FOR EXACTLY 50 CYCLES
                JSR     WAIT    ;  (HLINE-2-CMP#-BEQ-BNE-LDA#-LDA)
                LDA     SNIFF   ; GET FOURTH PATCH ID VALUE
                LSR             ; SHIFT INTO CARRY
       samepage BCS,    MORE4   ; TO EQUALIZE ONE COUNT

MORE4:          CMP     #ID5/2  ; FINAL VALIDITY CHECK
       samepage BNE,    LOCK    ; BACK TO SQUARE ONE
                NOP             ; HAVE LOCK AT THIS POINT


;                        ** STALL **

STALL:          LDA     #$05    ; DELAY FOR EXACTLY 193 CYCLES
                JSR     WAIT    ;
                LDA     #$02    ;
                JSR     WAIT    ;

FIX2PLUS:       LDA     #IDBYTE ; ADD ONE EXTRA CYCLE ONLY ON
                CMP     VERSION ;  THE II+ TO EQUALIZE ON-SCREEN
       samepage BNE,    SHOW    ;  DISPLAY MODE SWITCHING

SHOW:           BIT     SNIFF   ; OPTIONAL MODE CHANGES GO HERE
                BIT     SNIFF   ;
                BIT     SNIFF   ;
;               BIT     SNIFF   ;

PHASE:          SEC             ; PHASING CHANGES GO HERE
       samepage BCS,    MORE5   ;
MORE5:
;               NOP             ; EACH BRANCH TAKEN = 3
;               NOP             ; EACH BRANCH NOT TAKEN = 2
;               NOP             ; EACH NOP = 2 CYCLES
;               NOP             ;

                PLA             ; RESTORE ACCUMULATOR AND FLAGS
                PLP             ;
                RTS             ; AND EXIT
.endproc
