; Convertidor de número Base10 a Base64 en NASM
; Para Linux x86_64

section .data
    ; Tabla de caracteres Base64
    base64_charset db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/", 0
    
    ; Datos de prueba
    test_data db "14142416", 0    ; Número decimal a convertir
    
    ; Buffers
    converted_data times 64 db 0  ; Buffer para el resultado en base64
    temp_buffer times 64 db 0     ; Buffer temporal
    
    ; Mensajes
    msg_input db "Número decimal: ", 0
    msg_output db "Número en Base64: ", 0
    newline db 10, 0

section .text
global _start

_start:
    ; Mostrar número original
    mov rsi, msg_input
    call print_string
    
    mov rsi, test_data
    call print_string
    call print_newline
    
    ; Convertir string decimal a número
    mov rsi, test_data
    call str_to_uint64    ; RAX = número en decimal
    
    ; Convertir a Base64
    mov rdi, converted_data   ; RDI = buffer de salida
    call decimal_to_base64
    
    ; Mostrar resultado
    mov rsi, msg_output
    call print_string
    
    mov rsi, converted_data
    call print_string
    call print_newline
    
    ; Salir
    mov rax, 60    ; syscall: exit
    xor rdi, rdi   ; status: 0
    syscall

;===============================================
; Función para convertir decimal a Base64
; Entrada: RAX = número decimal
;          RDI = puntero al buffer de salida
; Salida: La representación base64 se almacena en el buffer
;===============================================
decimal_to_base64:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    
    mov r8, rdi        ; r8 = buffer de salida
    mov r9, rax        ; r9 = número a convertir
    
    ; Verificación especial para 0
    test r9, r9
    jnz .conversion
    
    ; Si el número es 0, directamente poner un '0'
    mov byte [r8], '0'
    mov byte [r8+1], 0
    jmp .end
    
.conversion:
    ; Usar buffer temporal para almacenar los dígitos en orden inverso
    mov rsi, temp_buffer
    xor rcx, rcx        ; rcx = contador de dígitos
    
.divide_loop:
    ; Dividir r9 por 64
    mov rax, r9
    mov rbx, 64
    xor rdx, rdx        ; limpiar rdx para la división
    div rbx             ; rax = cociente, rdx = resto
    
    ; Guardar el resto como índice para el caracter base64
    mov bl, byte [base64_charset + rdx]
    mov byte [rsi + rcx], bl
    inc rcx
    
    ; Actualizar r9 con el cociente
    mov r9, rax
    
    ; Continuar si el cociente no es 0
    test rax, rax
    jnz .divide_loop
    
    ; Copiar los dígitos al buffer de salida en orden inverso
    xor rbx, rbx    ; rbx = índice en buffer de salida
    
.reverse_loop:
    dec rcx
    mov al, byte [rsi + rcx]
    mov byte [r8 + rbx], al
    inc rbx
    
    ; Continuar si quedan dígitos
    test rcx, rcx
    jnz .reverse_loop
    
    ; Añadir el terminador NULL
    mov byte [r8 + rbx], 0
    
.end:
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

;===============================================
; Función para convertir string a uint64
; Entrada: RSI = puntero a la cadena
; Salida: RAX = valor numérico
;===============================================
str_to_uint64:
    push rbx
    push rcx
    push rdx
    push rsi
    
    xor rax, rax    ; inicializar resultado
    xor rcx, rcx    ; inicializar índice
    
.next_digit:
    movzx rbx, byte [rsi + rcx]  ; obtener siguiente dígito
    test rbx, rbx
    jz .done                    ; terminar si es NULL
    
    sub rbx, '0'               ; convertir ASCII a valor numérico
    jl .error                  ; error si < '0'
    cmp rbx, 9
    jg .error                  ; error si > '9'
    
    ; rax = rax * 10 + rbx
    mov rdx, 10
    mul rdx
    add rax, rbx
    
    inc rcx
    jmp .next_digit
    
.error:
    ; En caso de error, devolver 0
    xor rax, rax
    
.done:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

;===============================================
; Función para calcular longitud de cadena
; Entrada: RSI = puntero a cadena terminada en NULL
; Salida: RAX = longitud (sin contar NULL)
;===============================================
strlen:
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rbx, rsi    ; Guardar dirección inicial
    
    xor rcx, rcx
    not rcx         ; rcx = máximo valor posible
    xor al, al      ; buscar byte NULL (0)
    mov rdi, rsi    ; Dirección de la cadena
    cld             ; dirección: de menor a mayor
    repne scasb     ; buscar mientras no sea igual a AL
    
    not rcx         ; Invertir para obtener la longitud + 1
    dec rcx         ; Restar 1 para no contar el NULL
    mov rax, rcx    ; Devolver resultado en RAX
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
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
    
    ; Calcular longitud
    mov rdi, rsi
    call strlen
    mov rdx, rax    ; rdx = longitud
    
    ; Imprimir
    mov rax, 1      ; syscall: write
    mov rdi, 1      ; descriptor: stdout
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

;===============================================
; Función para imprimir una nueva línea
;===============================================
print_newline:
    push rax
    push rdi
    push rsi
    push rdx
    
    mov rsi, newline
    mov rdx, 1
    mov rax, 1      ; syscall: write
    mov rdi, 1      ; descriptor: stdout
    syscall
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret