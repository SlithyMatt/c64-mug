.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

.include "c64.inc"
.include "cbm_kernal.inc"

; PETSCII Codes
RETURN      = $0D
LOWER_CASE  = $0E
RED_CHAR    = $1C
GREEN_CHAR  = $1E
SPACE       = $20
BLACK_CHAR  = $90
CLR_CHAR    = $93

LEFT_MARGIN = 17

ZP_PTR_1    = $FB
ZP_PTR_2    = $FD


title_str:
.byte LOWER_CASE,GREEN_CHAR,"slithy",RETURN
.res LEFT_MARGIN,SPACE
.byte BLACK_CHAR,"GAMES",RETURN,RETURN
.res LEFT_MARGIN,SPACE
.byte RED_CHAR,"PRESENTS",0

start:
   lda #1
   sta VIC_BORDERCOLOR
   sta VIC_BG_COLOR0
   lda #CLR_CHAR
   jsr CHROUT
   ldy #LEFT_MARGIN
   ldx #10
   clc
   jsr PLOT
   ldx #0
@title_loop:
   lda title_str,x
   beq @done_text
   jsr CHROUT
   inx
   jmp @title_loop
@done_text:


   rts



.org $3E00
; Sprites
sprite0: ; position = 118,75; color = orange(8)
.byte %00000000,%00000000,%00000001
.byte %00000000,%00000000,%00000001
.byte %00000000,%00000000,%00000101
.byte %00000000,%00000000,%01010100
.byte %00000000,%00000101,%01000000
.byte %00000000,%00000101,%00000000
.byte %00000000,%00011100,%00000000
.byte %00000101,%10010100,%00000000
.byte %00001101,%01010000,%00000000
.byte %00101100,%00000000,%00000000
.byte %00001000,%00000000,%00000000
.byte %00000100,%00000000,%00000000
.byte %00100000,%00000000,%00000000
.byte %11000000,%00000000,%00000000
.byte %01000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer

sprite1:

