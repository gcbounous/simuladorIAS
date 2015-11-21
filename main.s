.globl main
.extern MMAP
.extern AC
.extern PC
.extern MQ

.data

p_linha:		.asciz "%03X %02X %03X %02X %03X\n"
p_inicial:		.asciz "@ Estado inicial:\n"
p_estado:		.asciz "+ AC:  0x%010llX     MQ: 0x%010llX        PC: 0x%0010llX\n--------------------------------------------------------------\n"
p_execucao:		.asciz "@ Executando instrucao no endereco %010X "
p_execucao_esquerda:	.asciz "(instrucao a esquerda)\n"
p_execucao_direita:		.asciz "(instrucao a direita)\n"
mask2: .word 0xFF
mask3: .word 0xFFF
a_direita: .word 0x0

.text
.align 4

main:
	push {ip, lr}

	bl inicializacao
	@ TODO: verificar todos os endereços!
	bl simulacao
	bl exit

simulacao:
	push {ip, lr}
	mov r1, #0
	loop_mmap:
		ldr r0, =a_direita
		ldr r0, [r0]
		cmp r0, #0
		beq pegar_esquerda
		b pegar_direita
		pegar_direita: @ instrucao a direita
			mov r2, r4	@ r2 <- opcode
			mov r3, r5	@ r3 <- end
			b saida_if

		pegar_esquerda: @instrucao a esquerda
			add r1, r1, #1 @proxima linha
			bl leitura_linha
			b saida_if

		saida_if:
			cmp r2, #0	@ verifica se os opcode1 é 0, indica o final do programma
			beq exit
			bl impressao_execucao
			bl impressao_estado
			@ TODO: aqui fazer switch!!
			bl impressao_linha
			ldr r6, =a_direita
			ldr r0, [r6]
			eor r0, r0, #1 @ toggle a_direita
			str r0, [r6]
			b loop_mmap
	
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
	bl impressao_estado

	pop {ip, pc}

impressao_estado:
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
	pop {r4, r5}

	pop {r1-r5, ip, pc}

impressao_execucao:
	push {r1-r5, ip, lr}

	ldr r0, =p_execucao	
	bl printf
	ldr r6, =a_direita
	ldr r6, [r6]
	cmp r6, #0
	beq impressao_esquerda
	cmp r6, #1
	beq impressao_direita
	b sair_impressao_execucao

	impressao_esquerda:
		ldr r0, =p_execucao_esquerda	
		bl printf
		b sair_impressao_execucao

	impressao_direita:
		ldr r0, =p_execucao_direita	
		bl printf
		b sair_impressao_execucao

	sair_impressao_execucao:
		pop {r1-r5, ip, pc}


exit:
	pop { ip, pc}