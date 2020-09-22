
DSTKSIZE=16
dstkbase_lo = dstklo + DSTKSIZE
dstkbase_hi = dstkhi + DSTKSIZE


.export init

.macro loaday val
        lda     #<val 
        ldy     #>val
.endmacro

.macro pushay 
        dex
        sta     dstkbase_lo, x
        sty     dstkbase_hi, x
.endmacro

.macro popay
        lda     dstkbase_lo, x
        ldy     dstkbase_hi, x
        inx
.endmacro

.macro const    val
        loaday  val
        pushay
.endmacro

.segment "ZEROPAGE"

dstklo: .res    DSTKSIZE
dstkhi: .res    DSTKSIZE
fip:    .res    2
zp_trampoline:     .res    3
rstkptr:.res    1


.segment "CODE"

init:
        lda     #$ff
        sta     rstkptr
        lda     #$6c     ;opcode for (JMP)
        sta     zp_trampoline

        loaday  code
        sta     fip
        sty     fip+1

        ldx     #0

        jmp     next

docol:
        lda     fip+1
        pha
        lda     fip
        pha
        clc
        lda     zp_trampoline+1
        adc     #2
        sta     fip
        lda     zp_trampoline+2
        adc     #0
        sta     fip+1
        jmp     next

next:

        ldy     #1                  ; 2 (0)
        lda     (fip),y             ; 5 (2)
        sta     zp_trampoline+2     ; 3 (7)
        dey                         ; 2 (10)
        lda     (fip),y             ; 5 (12)
        sta     zp_trampoline+1     ; 3 (17)
        clc                         ; 2 (19)
        lda     fip                 ; 3 (22)
        adc     #2                  ; 2 (24)
        sta     fip                 ; 3 (27)
        bcc     @1                  ; 2 (29)
        inc     fip+1               ; 5 (34)
    @1: jmp     zp_trampoline       ; 5 + 6 (45)

.macro defcode name, previous, flags, label
.ident (.concat (.string (label), "_header")):
    .word previous 
    .byte flags + .strlen (name)
    .byte name

.align 2
.ident (.string(label)):   .word (.ident (.string(label))) + 2
.endmacro

.macro defword name, previous, flags
.ident (.concat(name, "_header")):
    .word previous
    .byte flags + .strlen (name)
    .byte name

.align 2
.ident (name):  .word docol
.endmacro

    defcode "exit", 0, 0, exit
    .define _exit .addr exit
        pla
        sta     fip
        pla
        sta     fip+1
        jmp     next

    defcode "dup", exit, 0, dup
    .define _dup .addr dup
        lda     dstkbase_lo,x
        sta     dstkbase_lo-1,x
        lda     dstkbase_hi,x
        sta     dstkbase_hi-1,x
        dex
        jmp     next

    defcode "halt", dup_header, 0, halt
    .define _halt .addr halt 
        jmp *

    defcode "+", halt_header, 0, plus
    .define _plus .addr plus
        clc
        lda     dstkbase_lo,   x
        adc     dstkbase_lo+1, x
        sta     dstkbase_lo+1, x
        lda     dstkbase_hi,   x
        adc     dstkbase_hi +1, x
        sta     dstkbase_hi +1, x
        inx
        jmp     next

    defcode "lit", plus_header, 0, lit
    .define _lit .addr lit
        dex
        ldy     #1
        lda     (fip),y
        sta     dstkbase_lo,x
        dey
        lda     (fip),y
        sta     dstkbase_hi,x
        clc
        lda     fip
        adc     #2
        sta     fip
        bcc     @1
        inc     fip+1
    @1: jmp     next
        
    defcode "1+", lit_header, 0, oneplus
    .define _oneplus .addr oneplus
        inc     dstkbase_lo,x
        bne     @1
        inc     dstkbase_hi,x
    @1: jmp     next

    defcode "drop", oneplus_header, 0, drop
    .define _drop .addr drop 
        inx
        jmp     next

    defcode "2drop", drop_header, 0, twodrop
    .define _twodrop .addr twodrop 
        inx
        inx
        jmp     next

    defcode "?dup", twodrop_header, 0, qdup
    .define _qdup .addr qdup
        lda     dstkbase_lo,x
        ora     dstkbase_hi,x
        beq     @1
        lda     dstkbase_lo,x
        sta     dstkbase_lo-1,x
        lda     dstkbase_hi,x
        sta     dstkbase_hi-1,x
        dex
    @1: jmp     next

    defcode "=", qdup_header, 0, equal
    .define _equal .addr equal
        lda     dstkbase_lo,x
        cmp     dstkbase_lo+1,x
        bne     @1
        lda     dstkbase_hi,x
        cmp     dstkbase_hi+1,x
        bne     @1
        inx
        lda     #$ff
        sta     dstkbase_lo,x
        sta     dstkbase_hi,x
        jmp     next

    @1: inx
        lda     #$0
        sta     dstkbase_lo,x
        sta     dstkbase_hi,x
        jmp     next

    defcode "invert", equal_header, 0, invert
    .define _invert .addr invert

        lda     dstkbase_lo,x
        eor     #$ff
        sta     dstkbase_lo,x
        lda     dstkbase_hi,x
        eor     #$ff
        sta     dstkbase_hi,x
        jmp     next

    defword "double", twodrop_header, 0
    .define _double .addr double 
        _dup
        _plus
        _exit

code:

        _lit 
        .word $1111
        _invert
        _lit
        .word $1112
        _dup
 
        _equal


        _halt
