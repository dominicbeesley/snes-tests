.p816
.i16
.a8

OSVECS_START = $BFE0
OSVECS_LEN   = $0020

OSVEC_EMU_NMI	:=	$BFE0
OSVEC_EMU_IRQ	:=	$BFE2
OSVEC_EMU_COP	:=	$BFE4
OSVEC_EMU_BRK	:=	$BFE6
OSVEC_EMU_ABORT	:=	$BFE8

OSVEC_NAT_NMI	:=	$BFF0
OSVEC_NAT_IRQ	:=	$BFF2
OSVEC_NAT_COP	:=	$BFF4
OSVEC_NAT_BRK	:=	$BFF6
OSVEC_NAT_ABORT	:=	$BFF8

native_brk_handler = $1000
native_cop_handler = $1004
emulation_brk_handler = $1008
emulation_cop_handler = $100C


HW_PORTA		:=	$C000		; control port
HW_UART_DAT		:=	$D000		; UART DATA
HW_UART_STAT	:=	$D001		; UART STATUS
HW_DEBUG		:=	$E000		; 2xLED 7 segment display

	.export success:far
	.export fail:far
	.export save_results:far
	.export init_test:far
	.exportzp test_num
	.exportzp result_a
	.exportzp result_x
	.exportzp result_y
	.exportzp result_p
	.exportzp result_s
	.exportzp result_d
	.exportzp result_dbr
	.exportzp retaddr



	.import tests_table
	.import start_tests


.segment "ZEROPAGE"
.res $10
test_num: .word 0
result_a: .word 0
result_x: .word 0
result_y: .word 0
result_p: .word 0
result_s: .word 0
result_d: .word 0
result_dbr: .byte 0
retaddr: .word 0  ; return address from bankN_save_results
vblank_counter: .byte 0  ; wait for vblank when it reaches 0

.segment "CODE"


main:
	clc
	xce
	sei
	rep #$18  ; 16 bit X/Y
	sep #$20  ; 8 bit A
	ldx #$01EF
	txs

	ldx #native_brk_handler
	stx OSVEC_NAT_BRK
	ldx #native_cop_handler
	stx OSVEC_NAT_COP

	ldx #emulation_brk_handler
	stx OSVEC_EMU_BRK
	ldx #emulation_cop_handler
	stx OSVEC_EMU_COP

	jsr init

	ldx #$ffff
	stx test_num
	jmp start_tests

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:

	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 0:x = text (null-terminated).  y = vmem word address
write_text:
@loop:
	lda $00,x
	beq @end
	jsr serial_outch
	inx
	bra @loop
@end:
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; a = val.  y = vmem word address
write_hex8:
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	jsr @write_digit
	pla
	and #$0F
@write_digit:  ; write hex digit in A
	cmp #$0A
	bcc @num
	clc
	adc #'A'-$0A-'0'
@num:
	clc
	adc #'0'
	jsr serial_outch
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; 0:x = address. y = vmem word address
write_hex16:
	lda $01,x
	jsr write_hex8
	lda $00,x
	iny
	iny
	jsr write_hex8
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; x = new test num
init_test:
	; Check that we haven't skipped a test
	dex
	cpx test_num
	beq @ok

	; ** Invalid test order - possibly an errant jump **
	clc
	xce
	sei
	rep #$18  ; 16 bit X/Y
	sep #$20  ; 8 bit A
	ldx #$01EF
	txs

	jsr update_test_num
	ldx #txt_fail
	ldy #$32
	jsr write_text
	ldx #txt_skipped
	ldy #$A1
	jsr write_text
@end:
	jmp @end
	
@ok:
	inx
	stx test_num

	jsr update_test_num
	rtl

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Save the register values, and reset state (D, DBR, etc.)
save_results:
	; p register was already saved, and emulation mode was cleared.
	sei
	rep #$38
	.a16
	.i16
	phd
	pha
	lda #$0000
	tcd
	pla
	sta result_a
	stx result_x
	sty result_y
	plx  ; d register
	stx result_d
	tsc  ; original S value minus 3 (due to jsl).
	inc a
	inc a
	inc a
	sta result_s

	sep #$20
	.a8
	phb
	pla
	sta result_dbr
	lda #$00
	pha
	plb
	rtl

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

success:
	jsr update_test_num
	
	ldx #txt_success
	ldy #$32
	jsr write_text

@end:	jmp @end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_test_num:
	ldx #test_num
	ldy #$6E
	jsr write_hex16
	jmp write_newline

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fail:
	ldx #$1ef
	txs  ; in case s is invalid
	jsr update_test_num

	ldx #txt_fail
	ldy #$32
	jsr write_text
	jsr write_newline

	ldx #txt_a
	ldy #$A1
	jsr write_text
	ldx #result_a
	ldy #$A5
	jsr write_hex16
	jsr write_newline

	ldx #txt_x
	ldy #$C1
	jsr write_text
	ldx #result_x
	ldy #$C5
	jsr write_hex16
	jsr write_newline

	ldx #txt_y
	ldy #$E1
	jsr write_text
	ldx #result_y
	ldy #$E5
	jsr write_hex16
	jsr write_newline

	ldx #txt_p
	ldy #$101
	jsr write_text

	lda result_p
	ldy #$105
	jsr write_hex8
	jsr write_newline

	ldx #txt_s
	ldy #$121
	jsr write_text
	ldx #result_s
	ldy #$125
	jsr write_hex16
	jsr write_newline

	jsr wait_for_key
	jsr init

	; jump to next test

	rep #$20
	.a16
	lda test_num
	inc a
	asl a  ; A = (test_num+1) * 2
	sec
	adc test_num  ; A = (test_num+1) * 3
	tax
	sep #$20
	.a8
	ldy tests_table,x   ; y = test offset
	lda tests_table+2,x ; a = test bank
	pha
	dey  ; the return address should be 1 less than the target
	phy
	rtl  ; actually a jump to the next test

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serial_outch:
@lp:	bit	HW_UART_STAT		;CHECK TX STATUS        		
	bmi     @lp			;READY ?
        	sta     HW_UART_DAT	   	;TRANSMIT CHAR.


	rts

write_newline:
	lda #10
	jsr serial_outch
	lda #13
	jmp serial_outch	

wait_for_key:
	ldx #txt_press
	ldy #$341
	jsr write_text
@l1:	bit	HW_UART_STAT
	bvc	@l1
	lda	HW_UART_DAT

	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



.segment "RODATA"
txt_running: .byte "Running tests...", 0
txt_success: .byte "Success", 0
txt_fail: .byte "Failed", 0
txt_skipped: .byte "Invalid test order", 0
txt_testnum: .byte "Test number:", 0
txt_press: .byte "Press A for next tests...", 0
txt_a: .byte "A = ", 0
txt_x: .byte "X = ", 0
txt_y: .byte "Y = ", 0
txt_p: .byte "P = ", 0
txt_s: .byte "S = ", 0
zero:
	.byte 0, 0


.segment "TEST_DATA"  ; At address FFA0. Used by some tests
test_addr:    ; $FFA0
	.word $1212
test_target:  ; $FFA2
	.word $8000
test_target24:  ; $FFA4
	.word $8000
	.byte $7E
