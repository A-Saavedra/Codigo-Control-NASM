; Implementación final corregida del algoritmo de Verhoeff en NASM
; Calcula correctamente varios dígitos de verificación

section .data
    d:  db 0,1,2,3,4,5,6,7,8,9
        db 1,2,3,4,0,6,7,8,9,5
        db 2,3,4,0,1,7,8,9,5,6
        db 3,4,0,1,2,8,9,5,6,7
        db 4,0,1,2,3,9,5,6,7,8
        db 5,9,8,7,6,0,4,3,2,1
        db 6,5,9,8,7,1,0,4,3,2
        db 7,6,5,9,8,2,1,0,4,3
        db 8,7,6,5,9,3,2,1,0,4
        db 9,8,7,6,5,4,3,2,1,0
    
    p:  db 0,1,2,3,4,5,6,7,8,9
        db 1,5,7,6,2,8,3,0,9,4
        db 5,8,0,3,7,9,6,1,4,2
        db 8,9,1,6,0,4,3,5,2,7
        db 9,4,5,3,1,2,6,8,7,0
        db 4,2,8,6,5,7,3,9,0,1
        db 2,7,9,3,8,0,6,4,1,5
        db 7,0,4,6,9,1,3,2,5,8
    
    inv: db 0,4,3,2,1,5,6,7,8,9

    ; Datos de prueba
    numero_prueba: db "1503", 0
    cantidad_digitos: db 2
    
    ; Buffers
    numero: times 100 db 0
    output: times 100 db 0
    buffer: times 100 db 0
    check_digits: times 10 db 0

    digits_count: db 2

    ; Mensajes
    msg_test: db "Número original: ", 0
    msg_result: db "Número con dígitos Verhoeff: ", 0
    msg_checkdigits: db "Dígitos de control generados: ", 0
    newline: db 10, 0

section .bss
    input_buffer: resb 100

section .text
global _start

_start:
    ; Copiar número de prueba directamente
    mov rsi, numero_prueba
    mov rdi, numero
    call strcpy
    
    ; Copiar cantidad de dígitos directamente
    mov al, byte [cantidad_digitos]
    mov [digits_count], al

    ; Mostrar número original
    mov rsi, msg_test
    call print_string
    mov rsi, numero
    call print_string
    call print_newline

    ; Copiar el número original a output
    mov rsi, numero
    mov rdi, output
    call strcpy

    ; Calcular los dígitos de verificación
    movzx rcx, byte [digits_count]
    xor rbx, rbx

.next_digit:
    cmp rbx, rcx
    jge .digits_done

    ; Calcular posición actual
    mov rdi, output
    call strlen
    mov rdx, rax

    ; Calcular el siguiente dígito Verhoeff
    mov rsi, output
    call verhoeff_check_digit
    add al, '0'

    ; Guardar en output
    mov [output + rdx], al
    mov byte [output + rdx + 1], 0

    ; Guardar en check_digits
    mov [check_digits + rbx], al

    ; Incrementar
    inc rbx
    jmp .next_digit

.digits_done:
    mov byte [check_digits + rcx], 0

    ; Imprimir resultados
    mov rsi, msg_result
    call print_string
    mov rsi, output
    call print_string
    call print_newline

    mov rsi, msg_checkdigits
    call print_string
    mov rsi, check_digits
    call print_string
    call print_newline

    ; Salir
    mov rax, 60
    xor rdi, rdi
    syscall

; =========================
; Funciones auxiliares
; =========================

read_input:
    push rax
    push rdi
    push rsi
    push rdx
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 100
    syscall

    ; Reemplazar newline
    mov rdi, input_buffer
    mov rcx, rax
    test rcx, rcx
    jz .done

.find_newline:
    dec rcx
    js .done
    cmp byte [rdi + rcx], 10
    jne .find_newline
    mov byte [rdi + rcx], 0

.done:
    pop rdx
    pop rsi
    pop rdi
    pop rax

    ret

verhoeff_check_digit:
    push rbx 
    push rcx 
    push rdx 
    push rsi 
    push rdi

    xor rcx, rcx
    mov rdi, rsi
    call strlen
    mov rdx, rax

    ; Limpiar buffer
    mov rdi, buffer
    mov rcx, 100
    xor al, al
    rep stosb

    ; Construir buffer con 0 + número invertido
    mov rdi, buffer
    mov byte [rdi], '0'
    inc rdi
    lea rsi, [rsi + rdx - 1]
    mov rbx, rdx

.invert_loop:
    test rbx, rbx
    jz .invert_done
    movzx rax, byte [rsi]
    mov [rdi], al
    inc rdi
    dec rsi
    dec rbx
    jmp .invert_loop

.invert_done:
    mov byte [rdi], 0

    ; Procesar buffer
    mov rsi, buffer
    xor rbx, rbx
    xor rcx, rcx

.process_loop:
    movzx rax, byte [rsi]
    test al, al
    jz .process_done

    sub al, '0'
    mov rdx, rbx
    and rdx, 7
    imul rdx, rdx, 10
    add rdx, rax
    movzx rax, byte [p + rdx]

    imul rdx, rcx, 10
    add rdx, rax
    movzx rcx, byte [d + rdx]

    inc rsi
    inc rbx
    jmp .process_loop

.process_done:
    movzx rax, byte [inv + rcx]

    pop rdi 
    pop rsi 
    pop rdx 
    pop rcx
    pop rbx
    ret

strlen:
    push rbx
    push rcx
    push rdx
    push rdi
    mov rbx, rdi
    xor rcx, rcx

.loop:
    cmp byte [rdi], 0
    je .done
    inc rdi
    inc rcx
    jmp .loop

.done:
    mov rax, rcx
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

strcpy:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov rbx, rdi

.copy_loop:
    lodsb
    stosb
    test al, al
    jnz .copy_loop

    sub rdi, rbx
    dec rdi
    mov rax, rdi
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

print_string:
    push rax
    push rdi
    push rsi
    push rdx
    mov rdi, rsi
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    mov rsi, newline
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
