
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


.macro _lit value
        .addr dolit
        .word value
.endmacro

.macro _plus
        .addr plus
.endmacro

.macro _halt

        .addr halt
.endmacro

.macro _dup
        .addr dup
.endmacro 

.macro _oneplus
        .addr oneplus
.endmacro

code:

        _lit $1111
        .addr double
         _halt

double:
        .addr docol
        _dup
        _plus
        .addr exit


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

.macro defcode name, previous, flags
.ident (.concat (name, "_header")):
    .word previous
    
    ;link .set (.word (.ident (.concat (name, "_header"))))

    ;link .set (.word name)

    
    .byte flags + .strlen (name)
    .byte name

.align 2
.ident (name):   .word (.ident (name)) + 2

.endmacro

.macro defword name, previous, flags
.ident (.concat(name, "_header")):
    .word previous
    .byte flags + .strlen (name)
    .byte name

.align 2
.ident (name):  .word(.ident (name)) + 2
.endmacro

    defcode "exit", 0, 0
        pla
        sta     fip
        pla
        sta     fip+1
        jmp     next

    defcode "dup", exit, 0
        lda     dstkbase_lo,x
        sta     dstkbase_lo-1,x
        lda     dstkbase_hi,x
        sta     dstkbase_hi-1,x
        dex
        jmp     next

        
    defcode "halt", dup, 0

        jmp *

    defcode "plus", halt, 0
        clc
        lda     dstkbase_lo,   x
        adc     dstkbase_lo+1, x
        sta     dstkbase_lo+1, x
        lda     dstkbase_hi,   x
        adc     dstkbase_hi +1, x
        sta     dstkbase_hi +1, x
        inx
        jmp     next

    defcode "dolit", plus, 0
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
        
    defcode "oneplus", dolit, 0
        inc     dstkbase_lo,x
        bne     @1
        inc     dstkbase_hi,x
    @1: jmp     next

    defcode "drop", oneplus, 0
        inx
        jmp     next

    defcode "twodrop", drop, 0
        inx
        inx
        jmp     next

    