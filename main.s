.globl main
.extern MMAP
.extern AC
.extern PC
.extern MQ

.data

p_linha:				.asciz "%03X %02X %03X %02X %03X\n"
p_teste:				.asciz "TESTE || PC: %03X\n"

p_sim_comeca: 			.asciz "\nIASIM: A simulacao esta comecando.\n\n"
p_sim_termina: 			.asciz "\nIASIM: A simulacao terminou.\n\n"
p_inicial:				.asciz "@ Estado inicial:\n"
p_estado:				.asciz "+ AC:  0x%010llX     MQ: 0x%010llX     PC: 0x%010llX\n--------------------------------------------------------------\n"
p_execucao:				.asciz "@ Executando instrucao no endereco %010X "
p_execucao_esquerda:	.asciz "(instrucao a esquerda)\n"
p_execucao_direita:		.asciz "(instrucao a direita)\n"
p_salto_realizado: 		.asciz "@ Salto realizado\n"
p_erro_opcode: 			.asciz "IASIM: Erro! Instrucao invalida com opcode %02X.\n"
p_erro_endereco: 		.asciz "IASIM: Erro! Endereco invalido de numero %04X.\n"
p_erro_divisao: 		.asciz "IASIM: Erro! Divisao por zero.\n"
p_load: 				.asciz "@ LOAD M(X), X = 0x%04X\n"
p_loadmmq: 				.asciz "@ LOAD MQ,M(X), X = 0x%04X\n"
p_loadmq: 				.asciz "@ LOAD MQ, X = 0x%04X\n"
p_loadabs: 				.asciz "@ LOAD |(M(X)|, X = 0x%04X\n"
p_loadn: 				.asciz "@ LOAD -(M(X)), X = 0x%04X\n"
p_stor: 				.asciz "@ STOR M(X), X = 0x%04X\n"
p_storl: 				.asciz "@ STOR M(X,8:19), X =0x%04X\n" 
p_storr: 				.asciz "@ STOR M(X,28:39), X =0x%04X\n"
p_add: 					.asciz "@ ADD M(X), X = 0x%04X\n"
p_addabs: 				.asciz "@ ADD |M(X)|, X = 0x%04X\n"
p_sub: 					.asciz "@ SUB M(X), X = 0x%04X\n"
p_subabs: 				.asciz "@ SUB |M(X)|, X = 0x%04X\n"
p_mul: 					.asciz "@ MUL M(X), X = 0x%04X\n"
p_div: 					.asciz "@ DIV M(X), X = 0x%04X\n"
p_rsh: 					.asciz "@ RSH, X = 0x%04X\n"			
p_lsh: 					.asciz "@ LSH, X = 0x%04X\n"			
p_jumpl: 				.asciz "@ JUMP M(X,0:19), X = 0x%04X\n",
p_jumpr:				.asciz "@ JUMP M(X,20:39), X = 0x%04X\n"
p_jumppl: 				.asciz "@ JUMP+ M(X,0:19), X = 0x%04X\n"
p_jumppr: 				.asciz "@ JUMP+ M(X,20:39), X = 0x%04X\n"

mask2: 		.word 0xFF
mask3: 		.word 0xFFF
a_direita: 	.word 0x0

tab_switch:
	.word case_default
	.word case_LOAD 	@ opcode = 0x01			
	.word case_LOADN 	@ opcode = 0x02	
	.word case_LOADABS 	@ opcode = 0x03
	.word case_default		
	.word case_ADD 		@ opcode = 0x05		
	.word case_SUB 		@ opcode = 0x06			
	.word case_ADDABS 	@ opcode = 0x07			
	.word case_SUBABS 	@ opcode = 0x08
	.word case_LOADMQM 	@ opcode = 0x09		
	.word case_LOADMQ 	@ opcode = 0x0A		
	.word case_MUL 		@ opcode = 0x0B			
	.word case_DIV 		@ opcode = 0x0C			
	.word case_JUMPL 	@ opcode = 0x0D		
	.word case_JUMPR 	@ opcode = 0x0E		
	.word case_JUMPPL 	@ opcode = 0x0F		
	.word case_JUMPPR 	@ opcode = 0x10
	.word case_default			
	.word case_STORL 	@ opcode = 0x12		
	.word case_STORR 	@ opcode = 0x13			
	.word case_LSH 		@ opcode = 0x14			
	.word case_RSH 		@ opcode = 0x15
	.word case_default
	.word case_default
	.word case_default
	.word case_default
	.word case_default	
	.word case_default
	.word case_default
	.word case_default
	.word case_default
	.word case_default
	.word case_default		
	.word case_STOR 	@ opcode = 0x21

.text
.align 4

main:
	push {ip, lr}

	bl inicializacao
@ TODO: verificar todos os endereços!
	bl simulacao
	ldr r0, =p_sim_termina
	bl printf
	bl exit

simulacao:
	push {ip, lr}

	ldr r6, =PC
	ldr r1, [r6]
	bl leitura_linha
	loop_mmap:
		ldr r0, =a_direita
		ldr r0, [r0] 			@ recupera a_direita
		cmp r0, #0				@ verifica se estamos na instrucao da esquerda ou da direita e le em consequencia
		beq pegar_esquerda		@ if instrucao da esquerda
		b pegar_direita			@ else
		pegar_direita: 			@ instrucao a direita
			mov r2, r4			@ r2 <- opcode direita
			mov r3, r5			@ r3 <- endereco direita	
			add r1, r1, #1 		@ incrementa PC
			ldr r6, =PC
			str r1, [r6]
			b saida_if

		pegar_esquerda: 		@ instrucao a esquerda
			b saida_if

		saida_if:
			cmp r2, #0			@ verifica se os opcode1 é 0, indica o final do programma
			beq exit	
			bl impressao_execucao
			ldr r6, =a_direita
			ldr r0, [r6]
			eor r0, r0, #1 		@ toggle a_direita
			str r0, [r6]
			bl switch 			@ chama switch para tratar a instrucao atual
			
			ldr r6, =PC			
			ldr r1, [r6] 		@ recupera PC
			bl leitura_linha
			b loop_mmap
	
switch:
	push {r1-r5, ip, lr}
	@ r1 - linha atual
	@ r2 - opcode
	@ r3 - endereco
	
	mov r2, #0x01
	mov r0, r2
	cmp r0, #0x01       	@ menor que menor entrada na tabela?
	blt case_default    	@ sim, desvia
	cmpge r0, #0x21     	@ compara com maior valor
	bgt case_default    	@ val é maior que a maior entrada na tabela 
							@ r0 será o índice na tabela
	ldr r4, =tab_switch		@ carrega endereço da tabela de desvios
	ldr pc,[r4,r0,lsl #2]

	case_LOAD:
		bl load
		b break				
	case_LOADN:
		b break		
	case_LOADABS:
		b break 			
	case_ADD:
		b break 				
	case_SUB:
		b break 					
	case_ADDABS:
		b break 				
	case_SUBABS:
		b break	
	case_LOADMQM:
		b break 			
	case_LOADMQ:
		b break 			
	case_MUL:
		b break 					
	case_DIV :
		b break					
	case_JUMPL:
		b break 			
	case_JUMPR :
		b break			
	case_JUMPPL:
		b break 			
	case_JUMPPR:
		b break 				
	case_STORL:
		b break			
	case_STORR:
		b break 				
	case_LSH:
		b break					
	case_RSH:
		b break					
	case_STOR:
		b break	
	case_default:
		b break


	break:
		bl impressao_estado
		pop {r1-r5, ip, pc}

load:
	push {r1-r5, ip, lr}

	mov r1, r3				@ carrega endereco para print
	bl recupera_dado
	mov r3, r0				@ recupera o retorno de recupera_dado
	ldr r4, =AC				@ Carrega AC em r4
	str r3, [r4]			@ Salva conteudo de M(X) em AC
	
	ldr r0, =p_load
	bl printf

	pop {r1-r5, ip, pc}
		
loadmmq:
	push {ip, lr}

	pop {ip, pc}

loadmq:
	push {ip, lr}

	pop {ip, pc}

loadabs:
	push {ip, lr}

	pop {ip, pc}

loadn:
	push {ip, lr}

	pop {ip, pc}

stor:
	push {ip, lr}

	pop {ip, pc}

storl:
	push {ip, lr}

	pop {ip, pc}

storr:
	push {ip, lr}

	pop {ip, pc}

add:
	push {ip, lr}

	pop {ip, pc}

addabs:
	push {ip, lr}

	pop {ip, pc}

sub:
	push {ip, lr}

	pop {ip, pc}

subabs:
	push {ip, lr}

	pop {ip, pc}

mul:
	push {ip, lr}

	pop {ip, pc}

div:
	push {ip, lr}

	pop {ip, pc}

rsh:
	push {ip, lr}

	pop {ip, pc}

lsh:
	push {ip, lr}

	pop {ip, pc}

jumpl:
	push {ip, lr}

	pop {ip, pc}

jumpr:
	push {ip, lr}

	pop {ip, pc}

jumppl:
	push {ip, lr}

	pop {ip, pc}

jumppr:
	push {ip, lr}

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

recupera_dado:
	push {r1-r4, ip, lr}

	@ r1 - endereco
	@ r2 - byte mais significativo
	@ r3 - bytes menos significativos
	@ r0 - retorno

	ldr r7, =MMAP
	lsl r5, r1, #2
	add r5, r5, r1 @ r1*5 para ajustar o endereço com o numero de bytes
	add r7, r7, r5 

	ldrb r2, [r7], #1 @ byte mais significativo
	
	ldrb r3, [r7], #1 @ bytes menos significativos
	ldrb r4, [r7], #1
	ldrb r5, [r7], #1
	ldrb r6, [r7], #1
	lsl r3, r3, #24
	lsl r4, r4, #16
	lsl r5, r5, #8
	add r3, r3, r4
	add r3, r3, r5
	add r3, r3, r6
	mov r0, r3

	pop {r1-r4, ip, pc}


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
	ldr r1, =a_direita
	str r0, [r1]

	@ impressao inicial
	ldr r0, =p_sim_comeca
	bl printf
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
	push {r1-r3}
	bl printf
	pop {r1-r3}

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