; Implementación del algoritmo AllegedRC4 en NASM
; Este algoritmo es una variante del cifrado RC4 utilizado en el
; cálculo del Código de Control

section .data
; Datos de prueba - Actualizado con los datos del problema
test_data: db "290400110079rCB7Sv4150312X24189179011589d)5k7N2007070201%3a250031b8", 0
test_key: db "9rCB7Sv4X29d)5k7N%3ab89p-3(5[A71621", 0

; Estado de la clave (Tabla S)
state: times 256 db 0

; Buffers para resultados
output_hex: times 512 db 0
output_buffer: times 256 db 0

; Mensajes
msg_input: db "Texto de entrada: ", 0
msg_key: db "Llave: ", 0
msg_output: db "Resultado (hex): ", 0
hex_digits: db "0123456789ABCDEF", 0
newline: db 10, 0

section .bss
; Variables temporales
temp_byte: resb 1
i_index: resb 1
j_index: resb 1

section .text
global _start

_start:
    ; Mostrar los datos de entrada
    mov rsi, msg_input
    call print_string

    mov rsi, test_data
    call print_string
    call print_newline

    mov rsi, msg_key
    call print_string

    mov rsi, test_key
    call print_string
    call print_newline

    ; Ejecutar AllegedRC4
    mov rsi, test_data     ; Datos a cifrar
    call strlen
    mov rdx, rax           ; Longitud de los datos

    mov rsi, test_data     ; Datos a cifrar
    mov rdi, test_key      ; Llave
    mov rbx, output_buffer ; Buffer para el resultado
    call alleged_rc4

    ; Convertir resultado a hexadecimal
    mov rsi, output_buffer
    mov rdi, output_hex
    mov rcx, rdx           ; Longitud de los datos cifrados
    call bytes_to_hex

    ; Mostrar el resultado
    mov rsi, msg_output
    call print_string

    mov rsi, output_hex
    call print_string
    call print_newline

    ; Salir
    mov rax, 60            ; syscall: exit
    xor rdi, rdi           ; status: 0
    syscall

;===============================================
; Función para cifrar datos con AllegedRC4
; Entrada: RSI = puntero a los datos a cifrar
;          RDI = puntero a la llave
;          RBX = puntero al buffer de salida
; Salida:  Los datos cifrados se almacenan en el buffer apuntado por RBX
;          RDX = longitud de los datos cifrados (igual a la longitud de entrada)
;===============================================
alleged_rc4:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    ; Guardar punteros
    mov r12, rsi           ; r12 = datos a cifrar
    mov r13, rdi           ; r13 = llave
    mov r14, rbx           ; r14 = buffer de salida
    
    ; Calcular longitudes
    mov rsi, r12
    call strlen
    mov r15, rax           ; r15 = longitud de datos
    
    mov rsi, r13
    call strlen
    mov r11, rax           ; r11 = longitud de llave
    
    ; Inicializar la tabla S (0 a 255)
    xor rcx, rcx
init_state_loop:
    mov byte [state + rcx], cl
    inc rcx
    cmp rcx, 256
    jl init_state_loop
    
    ; KSA – Key Scheduling Algorithm
    xor rcx, rcx           ; j = 0
    xor rsi, rsi           ; i = 0
    
key_schedule_loop:
    ; j = (j + S[i] + key[i % len(key)]) % 256
    movzx rax, byte [state + rsi]
    add rcx, rax
    
    ; Calcular i % len(key)
    mov rax, rsi
    xor rdx, rdx
    div r11                ; rdx = i % len(key)
    
    ; Obtener key[i % len(key)]
    movzx rax, byte [r13 + rdx]
    add rcx, rax
    and rcx, 0xFF          ; j = j % 256
    
    ; Intercambiar S[i] y S[j]
    mov al, byte [state + rsi]
    mov dl, byte [state + rcx]
    mov byte [state + rsi], dl
    mov byte [state + rcx], al
    
    inc rsi
    cmp rsi, 256
    jl key_schedule_loop
    
    ; PRGA – Pseudo-Random Generation Algorithm
    xor rsi, rsi           ; i = 0
    xor rcx, rcx           ; j = 0
    xor rbx, rbx           ; contador de caracteres procesados
    
prga_loop:
    cmp rbx, r15
    jge prga_done
    
    ; i = (i + 1) % 256
    inc rsi
    and rsi, 0xFF
    
    ; j = (j + S[i]) % 256
    movzx rax, byte [state + rsi]
    add rcx, rax
    and rcx, 0xFF
    
    ; Intercambiar S[i] y S[j]
    mov al, byte [state + rsi]
    mov dl, byte [state + rcx]
    mov byte [state + rsi], dl
    mov byte [state + rcx], al
    
    ; K = S[(S[i] + S[j]) % 256]
    movzx rax, byte [state + rsi]
    movzx rdx, byte [state + rcx]
    add rax, rdx
    and rax, 0xFF
    movzx rax, byte [state + rax]
    
    ; output[k] = input[k] XOR K
    xor al, byte [r12 + rbx]
    mov byte [r14 + rbx], al
    
    inc rbx
    jmp prga_loop
    
prga_done:
    mov rdx, r15           ; Devolver longitud cifrada
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;===============================================
; Función para calcular la longitud de una cadena
; Entrada: RSI = puntero a la cadena
; Salida:  RAX = longitud de la cadena
;===============================================
strlen:
    push rcx
    push rdi
    
    xor rcx, rcx
    dec rcx
    xor rax, rax
    
    mov rdi, rsi
    repnz scasb
    
    not rcx
    dec rcx
    mov rax, rcx
    
    pop rdi
    pop rcx
    ret

;===============================================
; Función para convertir bytes a representación hexadecimal
; Entrada: RSI = puntero a los bytes
;          RDI = puntero al buffer de salida
;          RCX = cantidad de bytes a convertir
;===============================================
bytes_to_hex:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    xor rbx, rbx
    
bytes_to_hex_loop:
    cmp rbx, rcx
    jge bytes_to_hex_done
    
    ; Obtener el byte actual
    movzx rax, byte [rsi + rbx]
    
    ; Convertir el nibble alto a hex
    mov rdx, rax
    shr rdx, 4
    and rdx, 0x0F
    mov dl, byte [hex_digits + rdx]
    mov byte [rdi], dl
    inc rdi
    
    ; Convertir el nibble bajo a hex
    mov rdx, rax
    and rdx, 0x0F
    mov dl, byte [hex_digits + rdx]
    mov byte [rdi], dl
    inc rdi
    
    inc rbx
    jmp bytes_to_hex_loop
    
bytes_to_hex_done:
    ; Terminar la cadena con un nulo
    mov byte [rdi], 0
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;===============================================
; Función para imprimir una cadena
; Entrada: RSI = puntero a la cadena
;===============================================
print_string:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Calcular longitud de la cadena
    call strlen_for_print
    mov rdx, rax
    
    ; Imprimir la cadena
    mov rax, 1            ; syscall: write
    mov rdi, 1            ; file descriptor: stdout
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

;===============================================
; Función para calcular longitud para imprimir
; Entrada: RSI = puntero a la cadena
; Salida:  RAX = longitud de la cadena
;===============================================
strlen_for_print:
    push rdi
    push rcx
    
    mov rdi, rsi
    xor rcx, rcx
    xor rax, rax
    not rcx
    
    repnz scasb
    
    not rcx
    dec rcx
    mov rax, rcx
    
    pop rcx 
    pop rdi
    ret

;===============================================
; Función para imprimir un salto de línea
;===============================================
print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rax, 1            ; syscall: write
    mov rdi, 1            ; file descriptor: stdout
    mov rsi, newline
    mov rdx, 1
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret