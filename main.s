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
p_loadmqm: 				.asciz "@ LOAD MQ,M(X), X = 0x%04X\n"
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

mask2: 			.word 0xFF
mask3: 			.word 0xFFF
endereco_max:	.word 0x3FF @ (1023)
a_direita: 		.word 0x0
erro:			.word 0x0

tab_switch:
	.word case_default			@ (0x0)        
	.word load	 				@ opcode = 0x01
	.word loadn					@ opcode = 0x02
	.word loadabs				@ opcode = 0x03
	.word case_default			@ (0x4)        
	.word add					@ opcode = 0x05
	.word sub					@ opcode = 0x06
	.word addabs				@ opcode = 0x07
	.word subabs				@ opcode = 0x08
	.word loadmqm				@ opcode = 0x09
	.word loadmq				@ opcode = 0x0A
	.word mul					@ opcode = 0x0B
	.word div					@ opcode = 0x0C
	.word jumpl					@ opcode = 0x0D
	.word jumpr					@ opcode = 0x0E
	.word jumppl				@ opcode = 0x0F
	.word jumppr				@ opcode = 0x10
	.word case_default			@ (0x11)       
	.word storl					@ opcode = 0x12
	.word storr					@ opcode = 0x13
	.word lsh					@ opcode = 0x14
	.word rsh					@ opcode = 0x15
	.word case_default			@ (0x16)       
	.word case_default			@ (0x17)       
	.word case_default			@ (0x18)       
	.word case_default			@ (0x19)       
	.word case_default			@ (0x1A)       
	.word case_default			@ (0x1B)       
	.word case_default			@ (0x1C)       
	.word case_default			@ (0x1D)       
	.word case_default			@ (0x1E)       
	.word case_default			@ (0x1F)       
	.word case_default			@ (0x20)       
	.word stor					@ opcode = 0x21

.text
.align 4

main:
	push {ip, lr}

	bl inicializacao
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
			ldr r4, =erro
			ldr r4, [r4]		@ recupera valor da variavel erro
			cmp r4, #1
			beq exit			@ se teve um erro sai do programa sem imprimir o estado
			bl impressao_estado
			ldr r6, =PC			
			ldr r1, [r6] 		@ recupera PC
			bl leitura_linha	@ le a palavra apontada por PC
			b loop_mmap
	
switch:
	push {r1-r5, ip, lr}
								@ r1 - linha atual
								@ r2 - opcode
								@ r3 - endereco	
	mov r2, #0x4
	mov r3, #-2
	mov r0, r2
	cmp r0, #0x01       		@ menor que menor entrada na tabela?
	blt case_default    		@ sim, desvia
	cmpge r0, #0x21     		@ compara com maior valor
	bgt case_default    		@ val é maior que a maior entrada na tabela 
								@ r0 será o índice na tabela
	ldr r4, =tab_switch			@ carrega endereço da tabela de desvios
	ldr pc,[r4,r0,lsl #2]

@-- Instrucoes

	@ LOAD M(X)	 - 0x01
	load:
								@ r3 - endereco
		mov r1, r3				@ carrega endereco para print
		ldr r0, =p_load
		push {r3}
		bl printf
		pop {r3}
		mov r0, r3				@ carrega endereco para verificacao
		bl verifica_endereco
		cmp r0, #1				@ verifica o retorno da rotina verifica_endereco
		beq break				@ caso tenha erro sai
		bl recupera_dado
		mov r3, r0				@ recupera o retorno de recupera_dado
		ldr r4, =AC				@ Carrega AC em r4
		str r3, [r4]			@ Salva conteudo de M(X) em AC	

		b break

	@ LOAD -M(x) - 0x02
	loadn:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		ldr r4, =AC				@ Carrega AC em r4
		mov r5, #-1				@ Move (-1) para r5
		mul r6, r3, r5			@ r6 = M(X) * (-1)
		str r6, [r4]			@ Salva -M(X) em AC

		ldr r0, =p_loadn
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ LOAD |M(X)|- 0x03
	loadabs:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		ldr r4, =AC				@ Carrega AC em r4
		cmp r3, #0				@ Compara M(X) com 0
		strge r3, [r4]			@ Se M(X) >= 0, AC = M(X)
		movlt r5, #-1			@ Se M(X) < 0, carrega -1 em r5,
		mullt r6, r3, r5		@ r6 = M(X) * (-1)
		strlt r6, [r4]			@ e AC = -M(X)
								@ Salva |M(X)| em AC

		ldr r0, =p_loadabs
		bl printf

		pop {r1-r5, ip, pc}
		b break
 
	@ ADD M(X)   - 0x05
	add:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		ldr r4, =AC				@ Carrega &AC em r4
		ldr r5, [r4]			@ Carrega conteudo de AC em r5
		add r5, r5, r3			@ r2 = AC + M(X)
		str r5, [r4]			@ Salva a soma em AC

		ldr r0, =p_add
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ SUB M(X)   - 0x06
	sub:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		ldr r4, =AC				@ Carrega &AC em r4
		ldr r5, [r4]			@ Carrega conteudo de AC em r5
		sub r5, r5, r3			@ r5 = AC - M(X)
		str r5, [r4]			@ Salva a subtracao em AC

		ldr r0, =p_sub
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ ADD |M(X)| - 0x07
	addabs:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		cmp r3, #0				@ Compara M(X) com 0
		movlt r4, #-1			@ Se M(X) <  0, carrega -1 em r4
		mullt r5, r3, r4		@ e r5 = M(X)*(-1)
		movge r5, r3			@ Se M(X) >= 0, r5 = M(X)
		ldr r4, =AC				@ Carrega AC em r4
		ldr r6, [r4]			@ Carrega conteudo de AC em r6
		add r6, r6, r5			@ r6 = AC + |M(X)|
		str r6, [r4]			@ Salva a soma em AC

		ldr r0, =p_addabs
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ SUB |M(X)| - 0x08
	subabs:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		cmp r3, #0				@ Compara M(X) com 0
		movlt r4, #-1			@ Se M(X) <  0, carrega -1 em r4
		mullt r5, r3, r4		@ e r5 = -M(X)
		movge r5, r3			@ Se M(X) >= 0, r5 = M(X)
		ldr r4, =AC				@ Carrega AC em r4
		ldr r5, [r4]			@ Carrega conteudo de AC em r5
		sub r5, r5, r3			@ r2 = AC - M(X)
		str r5, [r4]			@ Salva a subtracao em AC

		ldr r0, =p_subabs
		bl printf

		pop {r1-r5, ip, pc}
		b break
		
	@ LOAD MQ,M(x) - 0x09
	loadmqm:
		push {ip, lr}

		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ retorna em r0 a funcao recupera_dado
		mov r3, r0				@ carrega M(X) em r3

		ldr r4, =MQ				@ Carrega MQ em r4
		str r3, [r4]			@ Salva M(X) em MQ
		
		ldr r0, =p_loadmqm
		bl printf
		
		pop {ip, pc}
		b break					@ break

	@ LOAD MQ    - 0x0A
	loadmq:
		push {r1-r5, ip, lr}

		ldr r4, =MQ				@ Carrega &MQ em r4
		ldr r4, [r4]			@ Carrega conteudo de MQ
		ldr r5, =AC				@ Carrega &AC em r5
		str r4, [r5]			@ Salva conteudo de MQ em AC

		ldr r0, =p_loadmq
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ MUL M(X)   - 0x0B
	mul:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		ldr r4, =MQ				@ Carrega &MQ em r4
		ldr r5, [r4]			@ r5 = MQ
		mul r6, r5, r3			@ r6 = MQ * M(X)
		str r6, [r4]			@ Salva em MQ = MQ * M(X)
								@ (bits menos significativos)
		mov r5, #0				@ Zera o r5
		ldr r6, =AC				@ Carrega &AC em r6
		str r5, [r6]			@ Salva os zeros no AC
								@ (bits mais significativos)

		ldr r0, =p_mul
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ DIV M(X)   - 0x0C	
	div:
		push {r1-r5, ip, lr}
		
		mov r1, r3				@ carrega endereco para funcao recupera_dado
		bl recupera_dado		@ chama a funcao recupera_dado em r0
		mov r3, r0				@ Carrega M(X) em r3

		ldr r4, =AC				@ Carrega AC em r4
		ldr r4, [r4]			@ Carrega conteudo de AC em r4
		mov r5, #0				@ r5 = contador (quociente)
			Loop_Div:
				cmp r4, r3		@ Compara AC com M(X)
				blt Fim_Div		@ Se AC < M(X) salta para Fim_Div
				add r5, r5, #1	@ Se nao, incrementa r5
				sub r4, r4, r3	@ r4 = AC - M(X) (resto)
				b Loop_Div		@ Salta para o loop da divisao
			Fim_Div:
				ldr r6, =AC		@ Carrega AC em r6
				str r4, [r6]	@ Salva o resto da divisao em AC
				ldr r6, =MQ		@ Carrega MQ em r6
				str r5, [r6]	@ Salva quociente em MQ

		ldr r0, =p_mul
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ JUMP M(X,0:19) - 0x0D
	jumpl:
		push {r1-r5, ip, lr}

		@ -- r3 contem o endereco do opcode
		ldr r4, =PC				@ Carrega &PC em r4
		str r3, [r4]			@ Salva endereco em PC
		ldr r5, =a_direita		@ Carrega a_direita em r5
		mov r6, #0				@ r6 = 0
		str r6, [r5]			@ Instrucao a esquerda

		ldr r0, =p_jumpl
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ JUMP M(X,20:39)- 0x0E
	jumpr:
		push {r1-r5, ip, lr}

		@ -- r3 contem o endereco do opcode
		ldr r4, =PC				@ Carrega &PC em r4
		str r3, [r4]			@ Salva endereco em PC
		ldr r5, =a_direita		@ Carrega a_direita em r5
		mov r6, #1				@ r6 = 1
		str r6, [r5]			@ Instrucao a direita

		ldr r0, =p_jumpr
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ JUMP+M(X,0:19) - 0x0F
	jumppl:
		push {r1-r5, ip, lr}

		@ -- r3 contem o endereco do opcode

		ldr r4, =AC				@ Carrega &AC em r4
		ldr r4, [r4]			@ Carrega conteudo de AC em r4
		cmp r4, #0				@ Compara AC com zero
		blt break				@ Se AC for negativo: break
		ldr r4, =PC				@ Se nao, carrega &PC em r4
		str r3, [r4]			@ Salva endereco em PC
		ldr r5, =a_direita		@ Carrega a_direita em r5
		mov r6, #0				@ r6 = 0
		str r6, [r5]			@ Instrucao a esquerda

		ldr r0, =p_jumppl
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ JUMP+M(X,20:39)- 0x10
	jumppr:
		push {r1-r5, ip, lr}

		@ -- r3 contem o endereco do opcode

		ldr r4, =AC				@ Carrega &AC em r4
		ldr r4, [r4]			@ Carrega conteudo de AC em r4
		cmp r4, #0				@ Compara AC com zero
		blt break				@ Se AC for negativo: break
		ldr r4, =PC				@ Se nao, carrega &PC em r4
		str r3, [r4]			@ Salva endereco em PC
		ldr r5, =a_direita		@ Carrega a_direita em r5
		mov r6, #1				@ r6 = 1
		str r6, [r5]			@ Instrucao a direita

		ldr r0, =p_jumppr
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ STOR M(X,8:19) -0x12
	storl:
		push {ip, lr}

		pop {ip, pc}

	@ STOR M(X,28:39)- 0x13
	storr:
		push {ip, lr}

		pop {ip, pc}

	@ LSH - 0x14
	lsh:
		push {r1-r5, ip, lr}

		ldr r4, =AC				@ Carrega AC em r4
		ldr r4, [r4]			@ Carrega conteudo de AC em r4
		lsl r5, r4, #1			@ Desloca AC para a esquerda
		str r5, [r4]			@ Salva AC deslocado em AC

		ldr r0, =p_lsh
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ RSH - 0x15
	rsh:
		push {r1-r5, ip, lr}

		ldr r4, =AC				@ Carrega AC em r4
		ldr r4, [r4]			@ Carrega conteudo de AC em r4
		lsr r5, r4, #1			@ Desloca AC para a direitra
		str r5, [r4]			@ Salva AC deslocado em AC

		ldr r0, =p_rsh
		bl printf

		pop {r1-r5, ip, pc}
		b break

	@ STOR - 0x21
	stor:
		push {ip, lr}

		pop {ip, pc}

	@ OpCode falso
	case_default:
		bl confirma_erro
		ldr r0, =p_erro_opcode
		mov r1, r2
		bl printf

	break:
		pop {r1-r5, ip, pc}
		

verifica_endereco:	
	push {r1-r5, ip, lr}
									@ r0 - endereco a ser verificado
									@ retorna em r0 1 ou 0 caso tenha erro ou nao
	cmp r0, #0
	blt confirma_erro_endereco		@ verifica se endereco menos que 0
	ldr r1, =endereco_max			
	ldr r1, [r1]					@recupera o maior endereco possivel
	cmp r0, r1
	bgt confirma_erro_endereco		@ verifica se endereco maior que 1023
	mov r0, #0
	mov r0, r1						@ nao ha erro
	b sair_veri_end

	confirma_erro_endereco:			
		bl confirma_erro 			@ ativa a variavel erro
		mov r1, r0					
		ldr r0, =p_erro_endereco	@ imprime erro de endereco
		bl printf
		mov r1, #1
		mov r0, r1					@ ha erro

	sair_veri_end:
		pop {r1-r5, ip, pc}

confirma_erro:
	push {r1-r3, ip, lr}
	ldr r1, =erro 
	mov r2, #1
	str r2, [r1]	@ mudamos a variavel erro para verdadeira
	pop {r1-r3, ip, pc}

leitura_linha:	
	push {ip, lr}
							@ r1 - endereço atual
							@ r2 - AA (opcode esquerda)
							@ r3 - BBB (endereco esquerda)
							@ r4 - CC (opcode direita)
							@ r5 - DDD (endereco direita)
	ldr r7, =MMAP
	lsl r5, r1, #2
	add r5, r5, r1 			@ r1*5 para ajustar o endereço com o numero de bytes
	add r7, r7, r5 

	ldrb r2, [r7], #1 		@ AA
	
	ldrb r3, [r7], #1 		@ BBB
	ldrb r4, [r7], #1
	lsl r3, r3, #4
	lsr r5, r4, #4
	add r3, r3, r5

	lsl r4, r4, #4 			@ CC
	ldrb r5, [r7], #1
	lsr r6, r5, #4
	add r4, r4, r6
	ldr r6, =mask2
	ldr r6, [r6]
	and r4, r4, r6 			@ mask que guarda so os dois bytes menos significativos
	
	lsl r5, r5, #8 			@ DDD
	ldrb r6, [r7], #1
	add r5, r5, r6
	ldr r6, =mask3
	ldr r6, [r6]
	and r5, r5, r6 			@ mask que guarda so os tres bytes menos significativos

	pop {ip, pc}

recupera_dado:
	push {r1-r4, ip, lr}
							@ r1 - endereco
							@ r2 - byte mais significativo
							@ r3 - bytes menos significativos
							@ r0 - retorno
	ldr r7, =MMAP
	lsl r5, r1, #2
	add r5, r5, r1 			@ r1*5 para ajustar o endereço com o numero de bytes
	add r7, r7, r5 

	ldrb r2, [r7], #1 		@ byte mais significativo
	
	ldrb r3, [r7], #1 		@ bytes menos significativos
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