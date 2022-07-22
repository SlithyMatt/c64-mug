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

SCREEN_RAM  = $0400
SPRITE_PTRS = SCREEN_RAM | $03F8

SPRITE1_PTRS = bitmap_colors1 | $03F8
SPRITE2_PTRS = bitmap_colors1_title | $03F8

COLOR_RAM   = $D800

INTRO_DELAY = 180
TITLE_DELAY = 120

tove_sprite_colors:
.byte 8,7,8,7,5,8,5

tove_sprite_xy:
.byte 118,75
.byte 98,95
.byte 82,107
.byte 96,135
.byte 118,121
.byte 104,131
.byte 100,131

title_str:
.byte LOWER_CASE,GREEN_CHAR,"slithy",RETURN
.res LEFT_MARGIN,SPACE
.byte BLACK_CHAR,"GAMES",RETURN,RETURN
.res LEFT_MARGIN,SPACE
.byte RED_CHAR,"PRESENTS",RETURN,RETURN,0

target_clock:
.res 3

kernal_irq:
.res 2

start_mug:
.byte 0

show_title:
.byte 0

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
   lda #$7F
   sta VIC_SPR_MCOLOR
   sta VIC_SPR_EXP_Y
   sta VIC_SPR_ENA
   lda #15 ; light gray
   sta VIC_SPR_MCOLOR0
   lda #9  ; brown
   sta VIC_SPR_MCOLOR1
   ldx #0
   stx VIC_SPR_HI_X
   stx VIC_SPR_EXP_X
@sprite_loop:
   txa
   ora #>((tove_sprite0 & $3E00) << 2)
   sta SPRITE_PTRS,x
   lda tove_sprite_colors,x
   sta VIC_SPR0_COLOR,x
   lda tove_sprite_xy,x
   sta VIC_SPR0_X,x
   inx
   cpx #7
   bne @sprite_loop
@coord_loop:
   lda tove_sprite_xy,x
   sta VIC_SPR0_X,x
   inx
   cpx #14
   bne @coord_loop

   ; wait for INTRO_DELAY jiffies
   clc
   lda TIME+2
   adc #INTRO_DELAY
   sta target_clock+2
   lda TIME+1
   adc #0
   sta target_clock+1
   lda TIME
   adc #0
   sta target_clock

   ; backup RAM vector for kernal IRQ routine
   lda IRQVec
   sta kernal_irq
   lda IRQVec+1
   sta kernal_irq+1

   ; overwrite IRQ vector
   sei
   lda #<custom_irq
   sta IRQVec
   lda #>custom_irq
   sta IRQVec+1
   cli

   ; wait for start_mug flag to be set
@wait_mug:
   lda start_mug
   beq @wait_mug

   ; load mug screen
   lda #0
   sta VIC_BORDERCOLOR
   sta VIC_BG_COLOR0
   sta VIC_SPR_ENA
   sta VIC_SPR_EXP_Y
   lda CIA2_PRA
   and #$FE ; VIC Bank 1
   sta CIA2_PRA
   lda #$80 ; Bitmap at $4000, Colors at $6000
   sta VIC_VIDEO_ADR
   lda VIC_CTRL1
   ora #$20 ; enable bitmap mode
   sta VIC_CTRL1
   lda VIC_CTRL2
   ora #$10 ; enable multi-color mode
   sta VIC_CTRL2

   ldy #0
   sty ZP_PTR_1
   lda #>bitmap_colors2
   sta ZP_PTR_1+1
   sty ZP_PTR_2
   lda #>COLOR_RAM
   sta ZP_PTR_2+1
@color_loop:
   lda (ZP_PTR_1),y
   sta (ZP_PTR_2),y
   iny
   bne @color_loop
   inc ZP_PTR_1+1
   inc ZP_PTR_2+1
   lda ZP_PTR_2+1
   cmp #>CIA1
   bne @color_loop

   clc
   lda TIME+2
   adc #TITLE_DELAY
   sta target_clock+2
   lda TIME+1
   adc #0
   sta target_clock+1
   lda TIME
   adc #0
   sta target_clock 

   lda #0 ; black
   sta VIC_SPR_MCOLOR0
   lda #3  ; cyan
   sta VIC_SPR_MCOLOR1

   lda #2 ; red
   sta VIC_SPR0_COLOR   ; spr0 = mug
   lda #8 ; orange
   sta VIC_SPR1_COLOR   ; spr1 = beer
   lda #9 ; brown
   sta VIC_SPR2_COLOR   ; spr2 = tap handle

   ldx #>((mug_sprite & $3FC0) << 2) ; spr0 address
   stx SPRITE1_PTRS
   inx
   stx SPRITE1_PTRS+1
   inx
   stx SPRITE1_PTRS+2

   ; mug @ 54,154
   lda #54
   sta VIC_SPR0_X
   lda #154
   sta VIC_SPR0_Y

   ; beer @ 273,153
   lda #17
   sta VIC_SPR1_X
   lda VIC_SPR_HI_X
   ora #$02
   sta VIC_SPR_HI_X
   lda #153
   sta VIC_SPR1_Y

   ; orig: handle @ 257,79
   ; handle @ 270,131
   lda #14
   sta VIC_SPR2_X
   lda VIC_SPR_HI_X
   ora #$04
   sta VIC_SPR_HI_X
   lda #131
   sta VIC_SPR2_Y

   ; enable sprites
   lda #$07
   sta VIC_SPR_ENA

wait_title:
   lda show_title
   beq wait_title

   lda #$A0 ; Bitmap at $4000, Colors at $6800
   sta VIC_VIDEO_ADR

   ldx #>((mug_sprite & $3FC0) << 2) ; spr0 address
   stx SPRITE2_PTRS
   inx
   stx SPRITE2_PTRS+1
   inx
   stx SPRITE2_PTRS+2

   ldy #0
   sty ZP_PTR_1
   lda #>bitmap_colors2_title
   sta ZP_PTR_1+1
   sty ZP_PTR_2
   lda #>COLOR_RAM
   sta ZP_PTR_2+1
@color_loop:
   lda (ZP_PTR_1),y
   sta (ZP_PTR_2),y
   iny
   bne @color_loop
   inc ZP_PTR_1+1
   inc ZP_PTR_2+1
   lda ZP_PTR_2+1
   cmp #>CIA1
   bne @color_loop
   
   

forever:
   nop
   jmp forever

   

custom_irq:

   lda start_mug
   bne @animation
   lda TIME
   cmp target_clock
   bne @done
   lda TIME+1
   cmp target_clock+1
   bne @done
   lda TIME+2
   cmp target_clock+2
   bne @done
   lda #1
   sta start_mug
   jmp @done
@animation:
   lda TIME
   cmp target_clock
   bne @do_tick
   lda TIME+1
   cmp target_clock+1
   bne @do_tick
   lda TIME+2
   cmp target_clock+2
   bne @do_tick
   lda #1
   sta show_title
   jmp @done
@do_tick:
   jsr mug_tick
@done:
   jmp (kernal_irq)
   ; end

mug_tick:
   inc VIC_SPR0_X
   rts
   

.res $2000-*
; Sprites
tove_sprite0:
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

tove_sprite1:
.byte %00000000,%00000000,%00000010
.byte %00000000,%00000000,%00001010
.byte %00000000,%00000000,%00101000
.byte %00000000,%00000001,%10100000
.byte %00000000,%00000110,%10100000
.byte %00000000,%01101101,%10010000
.byte %00000100,%01110110,%01000000
.byte %00011111,%11101011,%00000000
.byte %00011111,%10101001,%00000000
.byte %01111101,%10101000,%00000000
.byte %01111110,%10100100,%00000000
.byte %01111010,%10110000,%00000000
.byte %00001010,%10110100,%00000000
.byte %10101010,%11111100,%00000000
.byte %00000000,%11111101,%00000000
.byte %00000000,%11111101,%00000000
.byte %11110000,%11111111,%01000000
.byte %00001111,%11111111,%01010000
.byte %00000011,%11111111,%01010000
.byte %10101111,%11111111,%01000000
.byte %10111111,%11111111,%01000000

.byte 0 ; spacer

tove_sprite2:
.byte %00000000,%00000000,%00000110
.byte %00000000,%00000000,%00011111
.byte %00000000,%00000000,%00011111
.byte %00000000,%00000000,%01111101
.byte %00000000,%00000000,%01111100
.byte %00000000,%00000000,%01110000
.byte %00000000,%00000000,%10100000
.byte %00000000,%00000001,%00000000
.byte %00000000,%00000111,%10101010
.byte %00000000,%00011110,%10101010
.byte %00000000,%01111110,%11111010
.byte %00000001,%11111111,%10101111
.byte %00000111,%11111101,%10101011
.byte %00011111,%11111110,%00001111
.byte %01111101,%01010100,%00111111
.byte %01110100,%00000100,%10111111
.byte %00010100,%00000000,%10111111
.byte %00000000,%00000000,%00111111
.byte %00000000,%00000010,%00100101
.byte %00000000,%00000001,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer

tove_sprite3:
.byte %10101111,%11111111,%11010000
.byte %10001111,%11010001,%11110000
.byte %10001111,%11101001,%11110100
.byte %10101111,%11101000,%01110100
.byte %00100001,%01101010,%11111101
.byte %01101010,%10101000,%00111111
.byte %00101010,%10000000,%00000011
.byte %00001010,%00000000,%00000000
.byte %00000110,%00000000,%00000000
.byte %00000000,%10000000,%00000000
.byte %00000000,%00010101,%01010000
.byte %00000000,%00000000,%00010000
.byte %00000000,%00000000,%00000111
.byte %00000000,%00000000,%00000100
.byte %00000000,%00000000,%00000001
.byte %00000000,%00000000,%00001000
.byte %00000000,%00000100,%00000010
.byte %00000000,%00010100,%01000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer

tove_sprite4:
.byte %00000000,%00000000,%00000001
.byte %00000000,%00000000,%00000100
.byte %00000000,%00000000,%00000100
.byte %00000000,%00000000,%00000101
.byte %00000000,%00000000,%00000101
.byte %00000000,%00000110,%11110100
.byte %00000000,%00011001,%00000000
.byte %00000000,%00011100,%00000000
.byte %00000000,%00001101,%00000000
.byte %00000000,%00000101,%00000000
.byte %00000000,%00000011,%01000000
.byte %00000000,%00000011,%11000000
.byte %00010100,%00000111,%11000000
.byte %00111101,%01111111,%01000000
.byte %10111111,%11111101,%00000000
.byte %10101011,%11110100,%00000000
.byte %10101001,%01000000,%00000000
.byte %10101101,%01000000,%00000000
.byte %10111111,%01000000,%00000000
.byte %00010001,%01000000,%00000000
.byte %10110011,%01000000,%00000000
.byte 0 ; spacer

tove_sprite5:
.byte %11111111,%11010100,%00000000
.byte %11111111,%11010000,%00000000
.byte %11111111,%11010000,%00000000
.byte %11011001,%11110000,%00000000
.byte %11000001,%11110100,%00000000
.byte %11000010,%01110100,%00000000
.byte %01000000,%11111101,%00000000
.byte %00000000,%00111111,%01010000
.byte %00101000,%00000011,%11110101
.byte %10101000,%00000000,%11111111
.byte %10101000,%00000000,%00001111
.byte %00101000,%00000000,%00000101
.byte %00010101,%01010000,%00110101
.byte %00000000,%00010000,%11111101
.byte %00000000,%00000111,%01000101
.byte %00000000,%00000100,%11101101
.byte %00000000,%00000001,%00000100
.byte %00000010,%10100010,%00000000
.byte %00000100,%00000000,%01000000
.byte %00010110,%01101000,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer

tove_sprite6:
.byte %00000000,%00000000,%00000000
.byte %00110000,%00000000,%00000000
.byte %11110000,%00000000,%00000000
.byte %11110000,%00000000,%00000000
.byte %11110000,%00000000,%00000000
.byte %11110000,%00000000,%00000000
.byte %00010000,%00000000,%00000000
.byte %00000000,%00101000,%00000000
.byte %00000000,%00101010,%10000000
.byte %00000000,%00101010,%10000000
.byte %01000000,%00101010,%10000000
.byte %00000000,%00101010,%10000000
.byte %00000000,%00000000,%10000000
.byte %00000000,%00000000,%10000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00001010
.byte %00000000,%00000000,%00001000
.byte %00000000,%00010101,%01000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer

.res $4000-*
.include "bitmap.asm"

.res $7000-*
mug_sprite:
.byte %00000000,%00001111,%11110000
.byte %00000000,%00110000,%00001100
.byte %00000000,%11000000,%00000011
.byte %00000000,%11110000,%00001111
.byte %00000000,%11111111,%11110011
.byte %00001111,%11111100,%00000011
.byte %00001101,%11110000,%00000011
.byte %00001100,%11100000,%00001011
.byte %00001100,%11101000,%00101011
.byte %00001100,%01101010,%10101001
.byte %00001100,%01101010,%10101001
.byte %00001100,%01101000,%00101001
.byte %00001111,%01100000,%00001001
.byte %00000001,%01000000,%00000001
.byte %00000000,%01000100,%00010001
.byte %00000000,%01000100,%00010001
.byte %00000000,%01000000,%00000001
.byte %00000000,%00010000,%00000100
.byte %00000000,%00000101,%01010000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer

beer_sprite:
.res 63,0
.byte 0 ; spacer

handle_off_sprite:
.byte %00000000,%00000000,%00101000
.byte %00000000,%00000000,%10101010
.byte %00000000,%00000000,%10101010
.byte %00000000,%00000000,%10101010
.byte %00000000,%00000000,%10101010
.byte %00000000,%00000000,%10101010
.byte %00000000,%00000000,%10101010
.byte %00000000,%00000000,%10101010
.byte %00000000,%00000000,%01101001
.byte %00000000,%00000000,%00101000
.byte %00000000,%00000000,%00101000
.byte %00000000,%00000000,%00101000
.byte %00000000,%00000000,%00101000
.byte %00000000,%00000000,%00101000
.byte %00000000,%00000000,%00111100
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer

handle_on_sprite:
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %10101000,%00000000,%00000000
.byte %10101010,%00000000,%00000000
.byte %10101010,%10000000,%00000000
.byte %00101010,%10100000,%00000000
.byte %00001010,%10100100,%00000000
.byte %00000010,%10101000,%00000000
.byte %00000000,%01101010,%00000000
.byte %00000000,%00001010,%10000000
.byte %00000000,%00000010,%10100000
.byte %00000000,%00000000,%10101100
.byte %00000000,%00000000,%00110000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000,%00000000,%00000000
.byte 0 ; spacer
