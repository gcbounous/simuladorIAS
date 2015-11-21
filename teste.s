.data
scanf_format: .asciz "%d"
printf_format: .asciz "É negativo %d\n"
entrada1: .word 0
entrada2: .word 0

.text
.align 4

.globl main
.extern scanf
.extern printf

main:
    push {ip, lr}

loop:
    ldr r0, =scanf_format
    ldr r1, =entrada1
    bl scanf

    ldr r0, =scanf_format
    ldr r1, =entrada2
    bl scanf

    ldr r1, =entrada1
    ldr r2, =entrada2
    ldr r1, [r1]
    ldr r2, [r2]
    subs r1, r1, r2
    @se negativo imprimir "hegativo"
    bmi negativo
    b exit

negativo:
    ldr r0, =printf_format
    ldr r1, =entrada1
    bl printf
    
exit:
    pop {ip, pc}

    @loadkeys fr
    @scp -P 31415 exemplo.s debian@localhost:~/
