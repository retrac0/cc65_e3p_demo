
; store 
.macro  set16   value, dest
        lda     #<value
        sta     dest
        lda     #>value
        sta     dest+1
.endmacro

; swap in page 0 - 3 (F000, F400, F800, FC00) with bank 0-63
.macro  bankRom page, bank
        lda     #(page << 6) | bank
        sta     $3f
.endmacro

; generic delay macro
; should be assumed to trash NZC, A
.macro delay val 
        .if     val = 2
                nop
                
        .elseif val = 3
                bit $ff

        .elseif val = 4
                nop
                nop

        .elseif val = 5
                bit $ff
                nop

        .elseif val = 6
                bit $ff
                bit $ff
        
        .elseif val = 7
                bit $ff
                nop
                nop
        .else
; from 6502 wiki http://6502org.wikidot.com/software-delay
; delay A + 15 cycles, (17 with lda#) (up to 255 + 15 -> 270 cycles ?)
        .local DLY1, DLY2, DLY3
                        ;    Cycles        Accumulator     Carry flag
                        ; 0  1  2  3  4       (hex)        0 1 2 3 4
                lda #(val - 17)
                SEC        ; 2  2  2  2  2   00 01 02 03 04   1 1 1 1 1
        DLY1:   SBC #5     ; 2  2  2  2  2   FB FC FD FE FF   0 0 0 0 0
                BCS DLY1   ; 2  2  2  2  2   FB FC FD FE FF   0 0 0 0 0
                LSR        ; 2  2  2  2  2   7D 7E 7E 7F 7F   1 0 1 0 1
                BCC DLY2   ; 2  3  2  3  2   7D 7E 7E 7F 7F   1 0 1 0 1
        DLY2:   SBC #$7E   ; 2  2  2  2  2   FF FF 00 00 01   0 0 1 1 1
                BCC DLY3   ; 3  3  2  2  2   FF FF 00 00 01   0 0 1 1 1
                BEQ DLY3   ;       3  3  2         00 00 01       1 1 1
                BNE DLY3   ;             3               01           1
        DLY3:
        .endif
.endmacro