.setcpu "6502x"

.include "vcs.inc"
.include "zeropage.inc"
.include "lib.inc"
.include "bitmap.s"

COLOUR = $c8

.segment "ZERO_PAGE": zeropage
LineCounter:    .res    1
Temp:           .res    1
FrameCounter:   .res    1
BTable:         .res    12
Colour:         .res    1

.segment "CODE"
Reset:  
        lax     #0                      ; reset TIA and RAM by 
  @1:   dex                             ; clearing 00 to ff
        txs
        pha
        bne     @1
        plp                             ; clear processor status
        pha                             ; and put SP back to FF


        set16   bitmap0, BTable         ; bitmap kernel display addresses
        set16   bitmap1, BTable+2       ; of bitmap to display
        set16   bitmap2, BTable+4
        set16   bitmap3, BTable+6
        set16   bitmap4, BTable+8
        set16   bitmap5, BTable+10

        lda     #COLOUR
        sta     Colour

        jmp     Main

Main:
        jsr     vBlankStart             ; setup vblank timer
        ; do stuff
        jsr     vBlankDone              ; catch vblank timer
        jsr     bitmapKernel            
        jsr     overScan                ; setup overscan timer
        ; do stuff
        jsr     overScanDone            ; catch overscan timer
        jmp     Main                    

; send VSYNC and draw vblank period
vBlankStart:
        lda     #TIA_VSYNC_ON           ; vsync on
        sta     VSYNC   
        sta     WSYNC                   ; 3 lines of VSYNC
        sta     WSYNC   
        sta     WSYNC   
        lda     #0      
        sta     VSYNC                   ; vsync off
        lda     #41                     ; wait (35 * 76) / 64 cycles
        sta     TIM64T	                ; check in VBlankFinished
        rts                             ; this timer MUST be      

vBlankDone:     
        lda     INTIM                   ; timer set up in vBlankStart
        bne     vBlankDone              ; done?
        lda     #0      
        sta     VBLANK                  ; 
        rts

overScan:   
        ldy     #36                     ; 30 lines of OS (1 in kernel)
        sty     TIM64T
        rts

overScanDone:
        lda     INTIM
        bne     overScanDone
        rts
;
; This kernel displays a 96 x 192 bitmap on alternating frames of 48x192.
;
; Based on the 6-digit score trick as documented in TIA_HW_Notes.txt and
; in BIGMOVE.ASM and https://www.masswerk.at/rc2018/04/10.html
;
; Pointers to the bitmaps are stored in ZP addresses bitmap0..5
; bitmaps are stored upside down in memory (last line at offset 0) to take
; advantage of the 6502's decrement loops.
;
; Banks 1 and 2 are used to store the left frame, 2 and 3 to store the right.
;
; The display kernel has cycle-exact code. Align to prevent page crossing.
.align $100

; Both left and right frames share a common entry with some setup. 
; We should be 2 lines from the end of vertical blank now.
bitmapKernel:
        lda     #%00000011              ; 3 copies of P0 and P1 
        sta     NUSIZ0                  ; with close spacing
        sta     NUSIZ1                  ;
        sta     VDELP0                  ; D0 = enable vertical delay regs
        sta     VDELP1                  ; 
        lda     #$00                    ; set background colour
        sta     COLUBK                  ; 
        lda     #%10010000              ; set P0 HMOVE horizontal -6
        sta     HMP0                    ; 
        lda     #%10100000              ; and P1 HMOVE horizontal -7
        sta     HMP1                    ;  

        ldy     #192                    ; drawing 192 lines
                                        ; 
        sty     LineCounter             ; keep in Y, used later in bmLoop

        inc     FrameCounter            ; we increment FrameCounter every 
        lda     FrameCounter            ; frame, and branch left when even
        and     #1                      ; and branch right when odd
        beq     bmLeft                  
        jmp     bmRight
; left frame
bmLeft: bankRom 0, 1                    ; use the same addresses for both 
        bankRom 1, 2                    ; frames, just bankswitch the address
        sta     WSYNC                   ; cycle-exact timing begins!

        delay   25                      ;   0 (25) 
        sta     RESP0                   ;  25 (3)
        sta     RESP1                   ;  28 (3)
        delay   42                      ;  31 (42)
        sta     HMOVE                   ;  73 (3)
        delay   40                      ;   0 (40)
        lda     Colour                  ;  40 (3)      set up colours for
        sta     COLUP0                  ;  43 (3)       P0 and P1
        sta     COLUP1                  ;  46 (3)
        jmp     bmLoop                  ;  49 (3)

bmRight:
        bankRom 0, 3                    
        bankRom 1, 4
        sta     WSYNC                   ; cycle-exact timing begins!

        delay   41                      ;   0 (41)
        sta     RESP0                   ;  41 (3)
        sta     RESP1                   ;  44 (3)
        delay   26                      ;  47 (26)
        sta     HMOVE                   ;  73 (3)
        delay   57                      ;   0 (57)
        lda     Colour                  ;  57 (3)       set up colours 
        sta     COLUP0                  ;  60 (3)       for P0 and P1
        sta     COLUP1                  ;  63 (3)
        jmp     bmLoop                  ;  66 (3)

bmLoop:  
        delay   6                       ;   0 (6)       begins on cycle 52 / 69
        ldy     LineCounter             ;   6 (3)       
        lda     (BTable+0), y           ;   9 (5)       Y should be line number
        sta     GRP0                    ;  14 (3)
        lda     (BTable+2), y           ;  17 (5) 
        sta     GRP1                    ;  22 (3)
        lda     (BTable+4), y           ;  25 (5)
        sta     GRP0                    ;  30 (3)
        lda     (BTable+8), y           ;  33 (5)
        sta     Temp                    ;  36 (3)
        lax     (BTable+10), y          ;  41 (5)
        lda     (BTable+6), y           ;  46 (5)
        ldy     Temp                    ;  51 (3)
        nop                             ;  54 (2)
        sta     GRP1                    ;  56 (3)       
        sty     GRP0                    ;  59 (3)
        stx     GRP1                    ;  62 (3)
        sty     GRP0                    ;  65 (3) 
        dec     LineCounter             ;  68 (5)
        bne     bmLoop                  ;  73 (2,3)
        sta     WSYNC                   ; done
        lda     #%01000010              ; blank screen
        sta     VBLANK
        lda     #0
        sta     COLUP0
        sta     COLUP1              
        rts                             ; return to main loop

.segment "VECTORS"
.org $fffa
        .addr   Reset                   ; NMI: should never occur
        .addr   Reset                   ; RESET
        .addr   Reset                   ; IRQ: will only occur with brk

