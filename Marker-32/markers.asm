; Mazen Ibrahim 295924
bits 32

extern _print_debug

extern _get_int32	
extern _get_int24	
extern _get_int16	

extern _find_black
extern _find_color	
extern _get_bmp_s
extern _get_pixel_offset
extern _print_marker

%define header_size 54

%define get_int32 _get_int32
%define get_int24 _get_int24
%define get_int16 _get_int16

%define is_black _is_black
%define get_width _get_width
%define get_bmp_h _get_bmp_h
%define get_bmp_w _get_bmp_w
%define get_pixel _get_pixel
%define get_pixel_offset _get_pixel_offset
%define find_black _find_black
%define find_color _find_color
%define next_marker _next_marker

global _get_bmp_w
global _get_bmp_h
global _get_pixel

global _is_black
global _next_marker
global _find_markers

SECTION .text
	align 4

; int32_t find_markers(uint8_t* bitmap, uint32_t* x_pos, uint32_t* y_pos)
; args
%define arg_bitmap ebp+8
%define arg_x_pos ebp+12
%define arg_y_pos ebp+16
; locals
%define local_x ebp-4
%define local_y ebp-8
%define local_width ebp-12
%define local_result ebp-16
;
_find_markers:
	push 	ebp
	mov 	ebp, esp
	
	; setup globals
	mov		eax, DWORD [arg_bitmap]
	mov		DWORD [bmp_header], eax
	add		eax, header_size
	mov		DWORD [bmp_pixels], eax
	;
	
	; setup locals
	sub		esp, 16
	mov		DWORD [local_result], 0
	mov		DWORD [local_y], 0
	;

find_markers_y:
	; y < get_bmp_h()
	call 	get_bmp_h
	mov		ecx, DWORD[local_y]
	cmp		ecx, eax
	jge		find_markers_y_break
	;
	; int x = get_bmp_w() - 1
	call	get_bmp_w
	dec		eax
	mov		DWORD[local_x], eax
	;
find_markers_x:
	; x > 0
	mov		eax, DWORD[local_x]
	cmp		eax, 0
	jle		find_markers_x_break
	;
	
	; int32_t width = next_marker(x, y);
	push	DWORD [local_y]
	push	DWORD [local_x]
	call	next_marker
	add		esp, 8
	mov		DWORD [local_width], eax 
	;
	
	; if (width != -1)
	cmp		eax, 0
	jl		find_markers_else
find_markers_if:
	
	; x_pos[result] = x;
	mov		eax, DWORD [local_result]
	mov		ecx, DWORD [arg_x_pos]
	shl		eax, 2
	add		eax, ecx
	mov		ecx, DWORD [local_x]
	mov		DWORD [eax], ecx
	;
	
	; y_pos[result] = width / 2 + y - 1;
	mov		eax, DWORD [local_result]
	mov		ecx, DWORD [arg_y_pos]
	shl		eax, 2
	add		eax, ecx
	mov		ecx, DWORD [local_y]
	dec		ecx
	mov		edx, DWORD [local_width]
	shr		edx, 1
	add		ecx, edx
	mov		DWORD [eax], ecx
	;
	
	; result = result + 1;
	mov		eax, DWORD [local_result]
	inc		eax
	mov		DWORD [local_result], eax
	;
	
	; x = x - width;
	mov		eax, DWORD [local_x]
	mov		ecx, DWORD [local_width]
	sub		eax, ecx
	mov		DWORD [local_x], eax
	;

find_markers_else:
	; --x
	mov 	eax, DWORD[local_x]
	dec		eax
	mov		DWORD[local_x], eax
	;
	jmp		find_markers_x
find_markers_x_break:
	; ++y
	mov 	eax, DWORD[local_y]
	inc		eax
	mov		DWORD[local_y], eax
	;
	jmp		find_markers_y
find_markers_y_break:
	
find_markers_return:
	mov 	eax, DWORD[local_result]
	add		esp, 16
	leave
	ret
; returns: number of patterns found
	
	
	
; int32_t next_marker(int32_t x, int32_t y)
; args
%define arg_x ebp+8
%define arg_y ebp+12
; locals
%define local_minX ebp-4
%define local_maxX ebp-8
%define local_minY ebp-12
%define local_maxY ebp-16
%define local_wthicc ebp-20
%define local_hthicc ebp-24
%define local_envelope ebp-28
%define local_line ebp-32
;
_next_marker:
	push 	ebp
	mov 	ebp, esp
	sub		esp, 32
	;

	; if (!is_black(x, y))
	push 	DWORD [arg_y]
	push 	DWORD [arg_x]
	call 	is_black
	add 	esp, 8
	cmp     eax, 0
	je		next_marker_error		; return false
	;
	
	; if (is_black(x + 1, y))
	push 	DWORD [arg_y]
	mov		eax, DWORD [arg_x]
	inc		eax
	push 	eax
	call 	is_black
	add 	esp, 8
	cmp     eax, 1
	je		next_marker_error		; return false
	;
	
	; if (is_black(x, y - 1))
	mov		eax, DWORD [arg_y]
	dec		eax
	push 	eax
	push 	DWORD [arg_x]
	call 	is_black
	add 	esp, 8
	cmp     eax, 1
	je		next_marker_error		; return false
	;
	
	; if (is_black(x + 1, y - 1))
	mov		eax, DWORD [arg_y]
	dec		eax
	push 	eax
	mov		eax, DWORD [arg_x]
	inc		eax
	push 	eax
	call 	is_black
	add 	esp, 8
	cmp     eax, 1
	je		next_marker_error		; return false
	;
		
	; setup locals
	mov		DWORD [local_minX], -1		; minX = -1
	mov		DWORD [local_minY], -1		; minY = -1
	mov		DWORD [local_hthicc], -1	; hthicc = -1
	mov		DWORD [local_envelope], -1	; envelope = -1
	
	mov		eax, DWORD [arg_x]
	mov		DWORD [local_maxX], eax		; maxX = x
	
	mov		eax, DWORD [arg_y]
	mov		DWORD [local_minY], eax		; minY = y
	
	mov		eax, DWORD [arg_y]
	push	eax
	mov		eax, DWORD [arg_x]
	push	eax
	call	get_width
	add		esp, 8
	mov		DWORD [local_wthicc], eax	; wthicc = get_width(x, y);
	;
		
; do
next_marker_loop_a:
	; if (is_black(x + 1, y))
	mov		eax, DWORD [arg_y]
	push	eax
	mov		eax, DWORD [arg_x]
	inc		eax
	push 	eax
	call	is_black
	add		esp, 8
	cmp		eax, 1
	je		next_marker_error			; return -1;
	;	

	; int line = get_width(x, ++y);
	mov		eax, DWORD [arg_y]
	inc		eax
	push	eax
	mov		DWORD [arg_y], eax
	mov		eax, DWORD [arg_x]
	push	eax
	call	get_width
	add		esp, 8
	mov		DWORD [local_line], eax
	;
	
	; if (line == wthicc)
	mov		ecx, DWORD [local_wthicc]
	cmp		eax, ecx
	je		next_marker_loop_a_logic	; continue;
	;
	
	; if (line < wthicc) 
	jl		next_marker_error			; return false;
	;
	
	; if (line > wthicc) 
	mov		ecx, DWORD [arg_x]
	sub		ecx, eax
	inc		ecx
	mov		DWORD [local_minX], ecx
	mov		eax, DWORD [arg_y]
	mov		DWORD [local_hthicc], eax
	jmp		next_marker_loop_a_break
	;
	
next_marker_loop_a_logic:
	; while (y < get_bmp_h());
	call	get_bmp_h
	mov		ecx, DWORD [arg_y]
	cmp		eax, ecx
	jg		next_marker_loop_a
	;
next_marker_loop_a_break:
;
	
; do
next_marker_loop_b:
	; if (is_black(x + 1, y))
	mov		eax, DWORD [arg_y]
	push	eax
	mov		eax, DWORD [arg_x]
	inc		eax
	push 	eax
	call	is_black
	add		esp, 8
	cmp		eax, 1
	je		next_marker_error			; return -1;
	;	
	
	; int line = get_width(x, ++y);
	mov		eax, DWORD [arg_y]
	inc		eax
	push	eax
	mov		DWORD [arg_y], eax
	mov		eax, DWORD [arg_x]
	push	eax
	call	get_width
	add		esp, 8
	mov		DWORD [local_line], eax
	;
	
	; if (line == 0)
next_marker_loop_b_if:
	cmp		eax, 0
	jne		next_marker_loop_b_else	
	; hthicc = y - hthicc;
	mov		eax, DWORD [arg_y]
	mov		ecx, DWORD [local_hthicc]	
	sub		eax, ecx
	mov		DWORD [local_hthicc], eax
	; maxY = y - 1;
	mov		eax, DWORD [arg_y]
	dec		eax
	mov		DWORD [local_maxY], eax
	; break;
	jmp		next_marker_loop_b_break
next_marker_loop_b_else:

	; if (line != (maxX - minX + 1)) 
	mov		eax, DWORD [local_line]	
	mov		ecx, DWORD [local_maxX]
	mov		edx, DWORD [local_minX]
	sub		ecx, edx
	inc		ecx
	cmp 	eax, ecx
	jne		next_marker_error

next_marker_loop_b_logic:
	; while (y < get_bmp_h());
	call	get_bmp_h
	mov		ecx, DWORD [arg_y]
	cmp		eax, ecx
	jg		next_marker_loop_b
	;	
next_marker_loop_b_break:

	; // our logical condition
	; if ((maxX - minX + 1) / 2 != (maxY - minY + 1))
	mov		eax, DWORD [local_maxX]
	mov		ecx, DWORD [local_minX]
	sub		eax, ecx
	inc		eax
	shr		eax, 1		
	mov		ecx, DWORD [local_maxY]
	mov		edx, DWORD [local_minY]
	sub		ecx, edx
	inc		ecx
	cmp		eax, ecx
	jne		next_marker_error			; return -1
	; if (hthicc != wthicc)
	mov		eax, DWORD [local_wthicc]
	mov		ecx, DWORD [local_hthicc]
	cmp		eax, ecx
	jne		next_marker_error			; return -1
	;;
	
	; // check the lowest envelope
	; envelope = find_black(maxX - 1, minY - 1);
	mov		eax, DWORD [local_minY]
	dec		eax
	push	eax	
	mov		eax, DWORD [local_maxX]
	dec		eax
	push	eax
	call	find_black
	add		esp, 8
	mov		DWORD [local_envelope], eax	
	; if (maxX - envelope <= wthicc)
	mov		eax, DWORD [local_maxX]
	mov		ecx, DWORD [local_envelope]
	sub		eax, ecx
	mov		ecx, DWORD [local_wthicc]
	cmp		eax, ecx
	jle		next_marker_error			; return -1
	;;
	
	
	; // check the middle envelope
	; envelope = find_black(maxX - wthicc, maxY - hthicc);
	mov		eax, DWORD [local_maxY]
	mov		ecx, DWORD [local_hthicc]
	sub		eax, ecx
	push	eax		
	mov		eax, DWORD [local_maxX]
	mov		ecx, DWORD [local_wthicc]
	sub		eax, ecx
	push	eax	
	call	find_black
	add		esp, 8
	mov		DWORD [local_envelope], eax	
	; if (maxX - envelope <= (maxX - minX + 1))
	mov		eax, DWORD [local_maxX]
	mov		ecx, DWORD [local_envelope]
	sub		eax, ecx
	mov		ecx, DWORD [local_maxX]
	mov		edx, DWORD [local_minX]
	sub		ecx, edx
	inc		ecx
	mov		edx, DWORD [local_wthicc]
	sub		ecx, edx	
	cmp		eax, ecx
	jle		next_marker_error			; return false
	;;
	
	; // check the upper envelope
	; envelope = find_black(maxX - 1, minY - 1);
	mov		eax, DWORD [local_maxY]
	inc		eax
	push	eax	
	mov		eax, DWORD [local_maxX]
	push	eax
	call	find_black
	add		esp, 8
	mov		DWORD [local_envelope], eax	
	; if (maxX - envelope <= (maxX - minX + 1))
	mov		eax, DWORD [local_maxX]
	mov		ecx, DWORD [local_envelope]
	sub		eax, ecx
	mov		ecx, DWORD [local_maxX]
	mov		edx, DWORD [local_minX]
	sub		ecx, edx
	inc		ecx
	cmp		eax, ecx
	jle		next_marker_error			; return false
	;;
	
	jmp		next_marker_return
next_marker_error:
	mov		eax, -1
	jmp		next_marker_leave
next_marker_return:
	mov		eax, DWORD [local_maxX]
	mov		ecx, DWORD [local_minX]
	sub		eax, ecx
	inc		eax
next_marker_leave:
	add		esp, 32
	leave
	ret
	
	
; int32_t get_pixel(int32_t x, int32_t y)
; args:
%define arg_x ebp+8
%define arg_y ebp+12
; locals:
_get_pixel:
	push 	ebp
	mov 	ebp, esp
	;
	push	DWORD [arg_y]
	push	DWORD [arg_x]
	call	get_pixel_offset
	add		esp, 8
	cmp		eax, -1
	je		get_pixel_error
	
	push	eax
	push	DWORD [bmp_pixels]
	call	get_int24
	add		esp, 8
	
	jmp		get_pixel_leave
get_pixel_error:
	mov		eax, -1
get_pixel_leave:
	;
	leave
	ret
	

; boolean is_black(int32_t x, int32_t y)
; args:
%define arg_x ebp+8
%define arg_y ebp+12
;
_is_black:
	push 	ebp
	mov 	ebp, esp
	;
	push 	DWORD [arg_y]
	push 	DWORD [arg_x]
	call 	get_pixel
	add 	esp, 8
	cmp 	eax, 0
	jne		is_black_false
is_black_true:
	mov		eax, 1
	jmp		is_black_leave
is_black_false:
	mov		eax, 0
is_black_leave:
	leave
	ret
;

; int32_t get_width(int32_t x, int32_t y)
; args:
%define arg_x ebp+8
%define arg_y ebp+12
_get_width:
	push 	ebp
	mov 	ebp, esp
	;
	push	DWORD [arg_y]
	push	DWORD [arg_x]
	call 	find_color
	add		esp, 8
	mov		ecx, eax
	cmp		eax, -1
	je		get_width_return_a	
get_width_return_b:
	mov		eax, DWORD [arg_x]
	sub		eax, ecx	
	jmp		get_width_leave
get_width_return_a:
	mov		eax, DWORD [arg_x]
get_width_leave:
	leave
	ret
;

; int32_t get_bmp_w()
_get_bmp_w:
	push 	ebp
	mov 	ebp, esp
	;
	mov		ecx, DWORD[bmp_header]
	add		ecx, 12h
	mov		eax, DWORD[ecx] 
	;
	pop		ebp
	ret
;

; int32_t get_bmp_h()
_get_bmp_h:
	push 	ebp
	mov 	ebp, esp
	
	mov		ecx, DWORD[bmp_header]
	add		ecx, 16h
	mov		eax, DWORD[ecx] 
	
	leave
	ret
;

SECTION .data
	align 4
	bmp_header dd 00000000H
	bmp_pixels dd 00000000H
	
SECTION .bss
	align 4