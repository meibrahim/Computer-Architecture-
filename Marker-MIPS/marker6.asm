# Mazen Ibrahim
# 295924

.eqv SYSCALL_PRINT_INT 	1
.eqv SYSCALL_PRINT_STR 	4
.eqv SYSCALL_EXIT 	10
.eqv SYSCALL_FOPEN 	13
.eqv SYSCALL_FREAD 	14
.eqv SYSCALL_FCLOSE 	16
.eqv BMP_HEAD_W 	18
.eqv BMP_HEAD_H 	22
.eqv BMP_HEAD_S 	34
.eqv FALSE 		0
.eqv TRUE 		1
.eqv CLR_BLACK		0x000000

.data
str_pattern_a: .asciiz	"Found the pattern at: ["
str_pattern_b: .asciiz	", "
str_pattern_c: .asciiz	"]\n"
err_fopen: .asciiz	"Couldn't open the source.bmp file\n"
err_fread: .asciiz	"Couldn't read from the source.bmp file\n"

filename: .asciiz 	"source.bmp"

.align 4
aligning: .space 2
header:	.space 		54
pixels: .space 		230400

# reserved registers
.eqv 			STACK		$sp
.eqv 			RADDR		$ra
.eqv 			TEMP		$t7
.eqv 			RESULT		$v0
#

.text
main:
	jal		read_bmp
	jal 		find_markers
	j		main_exit
main_error:
	li		$v0, SYSCALL_PRINT_STR
	syscall
main_exit:
	li		$v0, SYSCALL_EXIT
	syscall
	

# read_bmp(void) : void	
read_bmp:
	li		$v0, SYSCALL_FOPEN
	la		$a0, filename
	li		$a1, 0 
	li		$a2, 0 
	syscall
	move		$s6, $v0
	bgt		$v0, -1, read_bmp_hread
	la		$a0, err_fopen
	j		main_error
	
read_bmp_hread:
	li		$v0, SYSCALL_FREAD
	move		$a0, $s6
	la		$a1, header
	li		$a2, 54
	syscall
	beq		$v0, 54, read_bmp_pread
	
	la		$a0, err_fread
	j		read_bmp_error
	
read_bmp_pread:
	lw		$t0, header + BMP_HEAD_H
	lw		$t1, header + BMP_HEAD_W
	
	mul		$t2, $t0, $t1
	mul		$t2, $t2, 3	
	
	rem		$t3, $t1, 4
	mul		$t3, $t3, $t0
	
	li		$v0, SYSCALL_FREAD
	move		$a0, $s6
	la		$a1, pixels
	add		$a2, $t2, $t3
	syscall
	
	beq		$v0, $a2, read_bmp_return
	la		$a0, err_fread
	j		read_bmp_error
read_bmp_return:	
	jr		RADDR	
read_bmp_error:
	li		$v0, SYSCALL_FCLOSE
	syscall
	j		main_error
#
	
	
# get_pixel(int x, int y) : int
get_pixel:
	li		$v0, -1	
	#
	bltz		$a0, get_pixel_return
	bltz		$a1, get_pixel_return
	# $t0: height
	# $t1: width	
	lw		$t0, header + BMP_HEAD_H
	lw		$t1, header + BMP_HEAD_W
	bge		$a1, $t0, get_pixel_return	
	bge		$a0, $t1, get_pixel_return	
	# $t2: index
	mul		$t2, $a0, 3
	mul		$t3, $a1, $t1
	mul		$t3, $t3, 3
	add		$t2, $t2, $t3
	# $t3: r
	# $t4: g
	# $t5: b
	lbu		$t3, pixels+2($t2)
	lbu		$t4, pixels+1($t2)
	lbu		$t5, pixels($t2)	
	sll		$t5, $t5, 16
	sll		$t4, $t4, 8	
	or		$v0, $t3, $t4
	or		$v0, $v0, $t5
	#
get_pixel_return:
	jr		RADDR
#
	
	
# find_black(int x, int y) : int
find_black:
	addi		STACK, STACK, -4
	sw		RADDR, (STACK)
	#
find_black_loop:
	addi		STACK, STACK, -4
	sw		$a0, (STACK)
	addi		STACK, STACK, -4
	sw		$a1, (STACK)
	jal		get_pixel
	lw		$a1, (STACK)
	addi		STACK, STACK, 4
	lw		$a0, (STACK)
	addi		STACK, STACK, 4	
	move		TEMP, RESULT
	move		RESULT, $a0
	beq		TEMP, CLR_BLACK, find_black_break
	sub		$a0, $a0, 1
	blt		$a0, 0, find_black_error
	j		find_black_loop
find_black_error:
	li		RESULT, -1
find_black_break:
	#
	lw		RADDR, (STACK)
	addi		STACK, STACK, 4
	jr		RADDR
#
	
	
# find_color(int x, int y) : int
find_color:
	addi		STACK, STACK, -4
	sw		RADDR, (STACK)
	#
find_color_loop:
	addi		STACK, STACK, -4
	sw		$a0, (STACK)
	addi		STACK, STACK, -4
	sw		$a1, (STACK)
	jal		get_pixel
	lw		$a1, (STACK)
	addi		STACK, STACK, 4
	lw		$a0, (STACK)
	addi		STACK, STACK, 4	
	move		TEMP, RESULT
	move		RESULT, $a0
	bne		TEMP, CLR_BLACK, find_color_break
	sub		$a0, $a0, 1
	blt		$a0, 0, find_color_error
	j		find_color_loop
find_color_error:
	li		RESULT, -1
find_color_break:
	#
	lw		RADDR, (STACK)
	addi		STACK, STACK, 4
	jr		RADDR
#


# get_width(int x, int y) : int
get_width:
	addi		STACK, STACK, -4
	sw		RADDR, (STACK)
	#
	addi		STACK, STACK, -4
	sw		$a0, (STACK)
	addi		STACK, STACK, -4
	sw		$a1, (STACK)
	jal		find_color
	lw		$a1, (STACK)
	addi		STACK, STACK, 4
	lw		$a0, (STACK)
	addi		STACK, STACK, 4	
	move		TEMP, RESULT
	move		RESULT, $a0
	beq		TEMP, -1, get_width_return
	sub		RESULT, RESULT, TEMP
get_width_return:
	#
	lw		RADDR, (STACK)
	addi		STACK, STACK, 4
	jr		RADDR
	
	
# pattern_match(int x, int y) : int
pattern_match:
	addi		STACK, STACK, -4
	sw		RADDR, (STACK)
	#
	
	.eqv		X $s0
	.eqv		Y $s1
	.eqv		minX $s2
	.eqv		maxX $s3
	.eqv		minY $s4
	.eqv		maxY $s5
	.eqv		wthicc $s6
	.eqv		hthicc $s7
	
	move		X, $a0
	move		Y, $a1
	li		minX, -1
	move		maxX, $a0
	move		minY, $a1
	li		maxY, -1
	li		wthicc, -1
	li		hthicc, -1
	
	# check if we are at the bottom-right pixel of the alledged shape
	move		$a0, X
	move		$a1, Y
	jal		get_pixel
	bne		RESULT, CLR_BLACK, pattern_match_failure
	
	add		$a0, X, 1
	move		$a1, Y
	jal		get_pixel
	beq		RESULT, CLR_BLACK, pattern_match_failure
	
	move		$a0, X
	sub		$a1, Y, 1
	jal		get_pixel
	beq		RESULT, CLR_BLACK, pattern_match_failure
	
	add		$a0, X, 1
	sub		$a1, Y, 1
	jal		get_pixel
	beq		RESULT, CLR_BLACK, pattern_match_failure
	#
	
	# first, we get the bottom line width
	move		$a0, X
	move		$a1, Y
	jal		get_width
	move		wthicc, RESULT
	#
	
pattern_match_lower:
	# if there's a black pixel in the envelope, we aren't okay
	add		$a0, X, 1
	move		$a1, Y
	jal		get_pixel
	beq		RESULT, CLR_BLACK, pattern_match_failure
	#
	
	# we get the black line length
	add		Y, Y, 1
	move		$a0, X
	move		$a1, Y
	jal		get_width
	#
	
	# if we've encountered an equivalent black line, we continue
	beq		RESULT, wthicc, pattern_match_lower_loop
	#
	
	# if we've encountered a shorter black line, we aren't okay
	blt		RESULT, wthicc, pattern_match_failure
	#
	
	# if we've encountered a longer black line, we're okay to stop
	sub		minX, X, RESULT
	add		minX, minX, 1
	move		hthicc, Y
	j		pattern_match_lower_break
	#
pattern_match_lower_loop:
	# while (y < get_h());
	lw		TEMP, header + BMP_HEAD_H
	blt		Y, TEMP, pattern_match_lower
	#
pattern_match_lower_break:

	
pattern_match_upper:
	# if there's a black pixel in the envelope, we aren't okay
	add		$a0, X, 1
	move		$a1, Y
	jal		get_pixel
	beq		RESULT, CLR_BLACK, pattern_match_failure
	#
	
	# we get the black line length
	add		Y, Y, 1
	move		$a0, X
	move		$a1, Y
	jal		get_width
	#
	
	# if we've encountered a whitespace, we're okay
	bne		RESULT, 0, pattern_match_upper_if2
	sub		hthicc, Y, hthicc
	sub		maxY, Y, 1
	j		pattern_match_upper_break
	#
	
pattern_match_upper_if2:
	# if we've encountered a shorter/longer line, we aren't okay
	sub		TEMP, maxX, minX
	add		TEMP, TEMP, 1
	bne		RESULT, TEMP, pattern_match_failure
	#
	
pattern_match_upper_loop:
	# while (y < get_h());
	lw		TEMP, header + BMP_HEAD_H
	blt		Y, TEMP, pattern_match_upper
	#
pattern_match_upper_break:
	
	# verify the logical condition: [width / 2 == height]
	sub		$t0, maxX, minX
	sub		$t1, maxY, minY
	add		$t0, $t0, 1
	add		$t1, $t1, 1
	div		$t0, $t0, 2
	bne		$t0, $t1, pattern_match_failure
	#

	# verify the logical condition: [wthicc == hthicc]
	bne		wthicc, hthicc, pattern_match_failure
	#
	
	# check the lowest envelope
	sub		$a0, maxX, 1
	sub		$a1, minY, 1
	jal		find_black
	sub 		$t0, maxX, RESULT
	ble		$t0, wthicc, pattern_match_failure	
	#
	
	# check the middle envelope
	sub		$a0, maxX, wthicc
	sub		$a1, maxY, hthicc
	jal		find_black
	sub 		$t0, maxX, RESULT
	sub		$t1, maxX, minX
	add 		$t1, $t1, 1
	sub		$t1, $t1, wthicc	
	ble		$t0, $t1, pattern_match_failure	
	#
	
	# check the upper envelope
	move		$a0, maxX
	add		$a1, maxY, 1
	jal		find_black
	sub 		$t0, maxX, RESULT
	sub		$t1, maxX, minX
	add 		$t1, $t1, 1
	ble		$t0, $t1, pattern_match_failure	
	#
	
	# return maxX - minX + 1, aka width
	sub		RESULT, maxX, minX
	add		RESULT, RESULT, 1
	j		pattern_match_return
pattern_match_failure:
	li		RESULT, -1
pattern_match_return:
	#
	lw		RADDR, (STACK)
	addi		STACK, STACK, 4
	jr		RADDR
#
	
	
# find_markets(void) : void
find_markers:
	addi		STACK, STACK, -4
	sw		RADDR, (STACK)
	#
	
	# $t0 : x
	# $t1 : y
	# $t2 : w
	li		$t0, 0
	li		$t1, 0 
	li		$t2, 0
	
find_markers_loop_y:	
	lw		$t0, header + BMP_HEAD_W
	sub		$t0, $t0, 1	
find_markers_loop_x:
	addi		STACK, STACK, -4
	sw		$t0, (STACK)
	addi		STACK, STACK, -4
	sw		$t1, (STACK)
	
	move		$a0, $t0
	move		$a1, $t1
	jal		pattern_match
	
	lw		$t1, (STACK)
	addi		STACK, STACK, 4
	lw		$t0, (STACK)
	addi		STACK, STACK, 4
	
	move		$t2, RESULT
	beq		$t2, -1, find_markers_nomatch
	
	# print
	li		$v0, SYSCALL_PRINT_STR
	la		$a0, str_pattern_a
	syscall
	
	li		$v0, SYSCALL_PRINT_INT
	move		$a0, $t0
	syscall	
	
	li		$v0, SYSCALL_PRINT_STR
	la		$a0, str_pattern_b
	syscall
	
	li		$v0, SYSCALL_PRINT_INT
	div		$a0, $t2, 2
	add		$a0, $a0, $t1
	sub		$a0, $a0, 1
	syscall	
	
	li		$v0, SYSCALL_PRINT_STR
	la		$a0, str_pattern_c
	syscall
	# !print

	sub		$t0, $t0, $t2
			
	#
find_markers_nomatch:
	# loop x
	sub		$t0, $t0, 1
	bgt		$t0, 0, find_markers_loop_x
	# loop y	
	add		$t1, $t1, 1
	lw		TEMP, header + BMP_HEAD_H
	blt		$t1, TEMP, find_markers_loop_y
	
	#
	lw		RADDR, (STACK)
	addi		STACK, STACK, 4
	jr		RADDR