	.globl main
	.extern MMAP
	.extern AC
	.extern PC
	.extern MQ

	.data
p_linha:	 .asciz "%03X %02X %03X %02X %03X\n"
p_inicial:	 .asciz "@ Estado inicial:\n"
p_estado:	 .asciz "+ AC:  0x%03X     MQ: 0x%03X        PC: 0x%03X\n"
mask2: .word 0xFF
mask3: .word 0xFFF

	.text
	.align 4

main:
	push {ip, lr}

	@ Linha do mapa de memoria a ser impressa
	bl inicializacao
	bl simulacao
	@bl leitura_linha
	bl exit

simulacao:
	push {ip, lr}
	mov r1, #0
	loop_mmap:
		bl leitura_linha
		cmp r2, #0	@ verifica se os opcode1 é 0
		beq exit
		cmp r4, #0 @ erifica se os opcode2 é 0
		beq exit
		@TODO: aqui fazer switch!!
		bl impressao_linha
		add r1, r1, #1
		b loop_mmap

	pop {ip, pc}
	
leitura_linha:	
	push {ip, lr}

	@ r1 - endereço atual
	@ r2 - AA (opcode esquerda)
	@ r3 - BBB (endereco esquerda)
	@ r4 - CC (opcode direita)
	@ r5 - DDD (endereco direita)

	ldr r7, =MMAP
	lsl r5, r1, #2
	add r5, r5, r1 @ r1*5 para ajustar o endereço com o numero de bytes
	add r7, r7, r5 

	ldrb r2, [r7], #1 @ AA
	
	ldrb r3, [r7], #1 @ BBB
	ldrb r4, [r7], #1
	lsl r3, r3, #4
	lsr r5, r4, #4
	add r3, r3, r5

	lsl r4, r4, #4 @ CC
	ldrb r5, [r7], #1
	lsr r6, r5, #4
	add r4, r4, r6
	ldr r6, =mask2
	ldr r6, [r6]
	and r4, r4, r6 @ mask que guarda so os dois bytes menos significativos
	
	lsl r5, r5, #8 @ DDD
	ldrb r6, [r7], #1
	add r5, r5, r6
	ldr r6, =mask3
	ldr r6, [r6]
	and r5, r5, r6 @ mask que guarda so os tres bytes menos significativos

	pop {ip, pc}


inicializacao:
	push {ip, lr}

	@ zerar todos os valores
	mov r0, #0
	ldr r1, =AC
	str r0, [r1]
	ldr r1, =MQ
	str r0, [r1]
	ldr r1, =PC
	str r0, [r1]

	@ impressao inicial
	ldr r0, =p_inicial
	bl printf
	bl impressao_variaveis

	pop {ip, pc}

impressao_variaveis:
	push {r1-r5, ip, lr}

	ldr r0, =p_estado
	ldr r1, =AC
	ldr r1, [r1]
	ldr r2, =MQ
	ldr r2, [r2]
	ldr r3, =PC
	ldr r3, [r3]
	bl printf

	pop {r1-r5, ip, pc}

impressao_linha:
	push {r1-r5, ip, lr}

	@impressao da linha lida
	ldr r0, =p_linha	
	push {r4, r5}
	bl printf
	pop {r14, r5}

	pop {r1-r5, ip, pc}

exit:
	pop { ip, pc}