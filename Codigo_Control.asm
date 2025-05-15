section .data
    ; Tablas del algoritmo de Verhoeff
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

    ; Datos de entrada
    numero_autorizacion: db "29040011007",0
    numero_factura: db "1503",0
    nit_cliente: db "4189179011",0
    fecha_transaccion: db "20070702",0
    monto_transaccion: db "2500",0
    llave_dosificacion: db "9rCB7Sv4X29d)5k7N%3ab89p-3(5[A",0
    
    ; Buffers para resultados
    factura_ver: times 20 db 0
    nit_ver: times 20 db 0
    fecha_ver: times 20 db 0
    monto_ver: times 20 db 0
    suma_str: times 20 db 0
    cinco_digitos_ver: times 10 db 0
    
    ; Buffers para el paso 2
    auth_concat: times 50 db 0
    factura_concat: times 50 db 0
    nit_concat: times 50 db 0
    fecha_concat: times 50 db 0
    monto_concat: times 50 db 0
    
    ; Buffers para el paso 3
    all_concat: times 500 db 0      ; Buffer para la concatenación de todos los datos
    rc4_key: times 300 db 0         ; Buffer para la llave de cifrado
    rc4_result: times 500 db 0      ; Buffer para el resultado del cifrado
    hex_output: times 1000 db 0     ; Buffer para la salida en hexadecimal

    ; Añadir variables para el paso 4
    suma_total: dq 0             ; Sumatoria total valores ASCII
    suma_parcial1: dq 0          ; Sumatoria posiciones 1,6,11,16,...
    suma_parcial2: dq 0          ; Sumatoria posiciones 2,7,12,17,...
    suma_parcial3: dq 0          ; Sumatoria posiciones 3,8,13,18,...
    suma_parcial4: dq 0          ; Sumatoria posiciones 4,9,14,19,...
    suma_parcial5: dq 0          ; Sumatoria posiciones 5,10,15,20,...

    ; Resultados del paso 5
    result_mult1: dq 0
    result_mult2: dq 0
    result_mult3: dq 0
    result_mult4: dq 0
    result_mult5: dq 0
    suma_final: dq 0
    base64_result: times 20 db 0

    ; Diccionario Base64
    base64_dict: db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/",0

    ; Corrección para los dígitos hexadecimales
    hex_digits: db "0123456789ABCDEF",0

    ; Cadena predefinida para el paso 3 (solución)
    ;predefined_str: db "290400110079rCB7Sv4150312X24189179011589d)5k7N2007070201%3a250031b8",0

    
    ; Mensajes de salida
    header: db "Paso 1 - Datos con 2 digitos Verhoeff:",10,0
    msg_factura: db "Numero de Factura: ",0
    msg_nit: db "NIT/CI Cliente: ",0
    msg_fecha: db "Fecha Transaccion: ",0
    msg_monto: db "Monto Transaccion: ",0
    msg_suma: db 10,"Suma total: ",0
    msg_verhoeff: db "5 digitos Verhoeff: ",0
    newline: db 10,0
    
    ; Mensajes para el paso 2
    msg_step2_header: db 10,"Paso 2 - Concatenaciones con substrings:",10,0
    msg_auth_concat: db "Autorizacion + Substring 1: ",0
    msg_factura_concat: db "Factura + Substring 2: ",0
    msg_nit_concat: db "NIT + Substring 3: ",0
    msg_fecha_concat: db "Fecha + Substring 4: ",0
    msg_monto_concat: db "Monto + Substring 5: ",0
    
    ; Mensajes para el paso 3
    msg_step3_header: db 10,"Paso 3 - Cifrado con AllegedRC4:",10,0
    msg_concat_all: db "Cadena concatenada: ",0
    msg_llave_cifrado: db "Llave para cifrado: ",0
    msg_rc4_result: db "Resultado RC4 (hex): ",0

    ; Mensajes para el paso 4
    msg_step4_header: db 10,"Paso 4 - Sumatorias de valores ASCII:",10,0
    msg_suma_total: db "Sumatoria Total: ",0
    msg_suma_parcial1: db "Sumatoria Parcial 1 (1,6,11,16,...): ",0
    msg_suma_parcial2: db "Sumatoria Parcial 2 (2,7,12,17,...): ",0
    msg_suma_parcial3: db "Sumatoria Parcial 3 (3,8,13,18,...): ",0
    msg_suma_parcial4: db "Sumatoria Parcial 4 (4,9,14,19,...): ",0
    msg_suma_parcial5: db "Sumatoria Parcial 5 (5,10,15,20,...): ",0

    ; Mensajes para el paso 5
    msg_step5_header: db 10,"Paso 5 - Cálculos finales y Base64:",10,0
    msg_mult_1: db "ST * SP1 / (DV1+1) = ",0
    msg_mult_2: db "ST * SP2 / (DV2+1) = ",0
    msg_mult_3: db "ST * SP3 / (DV3+1) = ",0
    msg_mult_4: db "ST * SP4 / (DV4+1) = ",0
    msg_mult_5: db "ST * SP5 / (DV5+1) = ",0
    msg_suma_final: db "Sumatoria final: ",0
    msg_base64: db "Base64: ",0

    ; Añadir variables para el paso 6
    msg_step6_header: db 10,"Paso 6 - AllegedRC4 para obtener Código de Control:",10,0
    msg_input_base64: db "Entrada Base64: ",0
    msg_codigo_control: db "Código de Control: ",0
    base64_cifrado: times 100 db 0
    codigo_control: times 50 db 0

section .bss
    temp_buffer: resb 20
    substring: resb 20   ; Buffer para extraer substrings
    rc4_state: resb 256             ; Estado interno del RC4
    rc4_temp: resb 1                ; Temporal para intercambio en RC4

section .text
global _start

_start:
    ; Paso 1: Añadir 2 dígitos Verhoeff a cada campo
    mov rsi, numero_factura
    mov rdi, factura_ver
    call strcpy
    mov rsi, factura_ver
    mov rcx, 2
    call add_verhoeff_digits
    
    mov rsi, nit_cliente
    mov rdi, nit_ver
    call strcpy
    mov rsi, nit_ver
    mov rcx, 2
    call add_verhoeff_digits
    
    mov rsi, fecha_transaccion
    mov rdi, fecha_ver
    call strcpy
    mov rsi, fecha_ver
    mov rcx, 2
    call add_verhoeff_digits
    
    mov rsi, monto_transaccion
    mov rdi, monto_ver
    call strcpy
    mov rsi, monto_ver
    mov rcx, 2
    call add_verhoeff_digits
    
    ; Mostrar resultados del paso 1
    mov rsi, header
    call print_string
    
    mov rsi, msg_factura
    call print_string
    mov rsi, factura_ver
    call print_string
    call print_newline
    
    mov rsi, msg_nit
    call print_string
    mov rsi, nit_ver
    call print_string
    call print_newline
    
    mov rsi, msg_fecha
    call print_string
    mov rsi, fecha_ver
    call print_string
    call print_newline
    
    mov rsi, msg_monto
    call print_string
    mov rsi, monto_ver
    call print_string
    call print_newline
    
    ; Calcular suma y 5 dígitos Verhoeff
    ; Convertir a enteros y sumar
    mov rsi, factura_ver
    call str_to_int
    mov rbx, rax
    
    mov rsi, nit_ver
    call str_to_int
    add rbx, rax
    
    mov rsi, fecha_ver
    call str_to_int
    add rbx, rax
    
    mov rsi, monto_ver
    call str_to_int
    add rbx, rax
    
    ; Convertir suma a string
    mov rax, rbx
    mov rdi, suma_str
    call int_to_str
    
    ; Mostrar suma
    mov rsi, msg_suma
    call print_string
    mov rsi, suma_str
    call print_string
    call print_newline
    
    ; Generar 5 dígitos Verhoeff para la suma
    mov rsi, suma_str
    mov rdi, cinco_digitos_ver
    call strcpy
    mov rsi, cinco_digitos_ver
    mov rcx, 5
    call add_verhoeff_digits
    
    ; Extraer solo los últimos 5 dígitos (los Verhoeff)
    mov rsi, cinco_digitos_ver
    call strlen
    lea rsi, [cinco_digitos_ver + rax - 5]
    mov rdi, temp_buffer
    call strcpy
    
    ; Mostrar 5 dígitos Verhoeff
    mov rsi, msg_verhoeff
    call print_string
    mov rsi, temp_buffer
    call print_string
    call print_newline
    
    
    ; Después de calcular los 5 dígitos Verhoeff y mostrarlos
; Guardar los dígitos en registros para usarlos más tarde
movzx r8, byte [temp_buffer]      ; Primer dígito Verhoeff
movzx r9, byte [temp_buffer+1]    ; Segundo dígito Verhoeff
movzx r10, byte [temp_buffer+2]   ; Tercer dígito Verhoeff
movzx r11, byte [temp_buffer+3]   ; Cuarto dígito Verhoeff
movzx r12, byte [temp_buffer+4]   ; Quinto dígito Verhoeff

; Convertir de ASCII a número
sub r8, '0'
sub r9, '0'
sub r10, '0'
sub r11, '0'
sub r12, '0'
    
    ; Paso 2: Extraer substrings basados en los 5 dígitos Verhoeff
    mov rsi, msg_step2_header
    call print_string
    
    ; Variable para rastrear la posición actual en la llave de dosificación
    mov r8, 0  ; Inicializar en 0
    
    ; --- Substring 1 ---
    movzx rcx, byte [temp_buffer]    ; Primer dígito Verhoeff
    sub rcx, '0'                     ; Convertir a número
    inc rcx                          ; Añadir 1
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8                      ; Ajustar posición de inicio
    call extract_substring
    add r8, rcx                      ; Actualizar posición
    
    ; Concatenar con autorización
    mov rdi, auth_concat
    mov rsi, numero_autorizacion
    call strcpy
    mov rdi, auth_concat
    call strlen
    add rdi, rax
    mov rsi, substring
    call strcpy
    
    ; Mostrar resultado
    mov rsi, msg_auth_concat
    call print_string
    mov rsi, auth_concat
    call print_string
    call print_newline
    
    ; --- Substring 2 ---
    movzx rcx, byte [temp_buffer+1]  ; Segundo dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8                      ; Usar posición actualizada
    call extract_substring
    add r8, rcx                      ; Actualizar posición
    
    ; Concatenar con factura
    mov rdi, factura_concat
    mov rsi, factura_ver
    call strcpy
    mov rdi, factura_concat
    call strlen
    add rdi, rax
    mov rsi, substring
    call strcpy
    
    ; Mostrar resultado
    mov rsi, msg_factura_concat
    call print_string
    mov rsi, factura_concat
    call print_string
    call print_newline
    
    ; --- Substring 3 ---
    movzx rcx, byte [temp_buffer+2]  ; Tercer dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8                      ; Usar posición actualizada
    call extract_substring
    add r8, rcx                      ; Actualizar posición
    
    ; Concatenar con NIT
    mov rdi, nit_concat
    mov rsi, nit_ver
    call strcpy
    mov rdi, nit_concat
    call strlen
    add rdi, rax
    mov rsi, substring
    call strcpy
    
    ; Mostrar resultado
    mov rsi, msg_nit_concat
    call print_string
    mov rsi, nit_concat
    call print_string
    call print_newline
    
    ; --- Substring 4 ---
    movzx rcx, byte [temp_buffer+3]  ; Cuarto dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8                      ; Usar posición actualizada
    call extract_substring
    add r8, rcx                      ; Actualizar posición
    
    ; Concatenar con fecha
    mov rdi, fecha_concat
    mov rsi, fecha_ver
    call strcpy
    mov rdi, fecha_concat
    call strlen
    add rdi, rax
    mov rsi, substring
    call strcpy
    
    ; Mostrar resultado
    mov rsi, msg_fecha_concat
    call print_string
    mov rsi, fecha_concat
    call print_string
    call print_newline
    
    ; --- Substring 5 ---
    movzx rcx, byte [temp_buffer+4]  ; Quinto dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8                      ; Usar posición actualizada
    call extract_substring
    add r8, rcx                      ; Actualizar posición
    
    ; Concatenar con monto
    mov rdi, monto_concat
    mov rsi, monto_ver
    call strcpy
    mov rdi, monto_concat
    call strlen
    add rdi, rax
    mov rsi, substring
    call strcpy
    
    ; Mostrar resultado
    mov rsi, msg_monto_concat
    call print_string
    mov rsi, monto_concat
    call print_string
    call print_newline
    
    ; Salir
    ;mov rax, 60
    ;xor rdi, rdi
    ;syscall
 
 ;=======   
    ;============= Paso 3 - Concatenación de cadenas para AllegedRC4
; Solución para el paso 3
    mov rsi, msg_step3_header
    call print_string
    

; Limpiar completamente el buffer
mov rdi, all_concat
xor al, al
mov rcx, 500
rep stosb

; Construir la cadena manualmente, subcadena por subcadena
mov rdi, all_concat  ; Destino inicial

; Copiar auth_concat (primera subcadena)
mov rsi, auth_concat
.loop1:
    lodsb
    test al, al
    jz .done1
    stosb
    jmp .loop1
.done1:

; Copiar factura_concat (segunda subcadena)
mov rsi, factura_concat
.loop2:
    lodsb
    test al, al
    jz .done2
    stosb
    jmp .loop2
.done2:

; Copiar nit_concat (tercera subcadena)
mov rsi, nit_concat
.loop3:
    lodsb
    test al, al
    jz .done3
    stosb
    jmp .loop3
.done3:

; Copiar fecha_concat (cuarta subcadena)
mov rsi, fecha_concat
.loop4:
    lodsb
    test al, al
    jz .done4
    stosb
    jmp .loop4
.done4:

; Copiar monto_concat (quinta subcadena)
mov rsi, monto_concat
.loop5:
    lodsb
    test al, al
    jz .done5
    stosb
    jmp .loop5
.done5:

; Asegurar que la cadena termine con un nulo
mov byte [rdi], 0

    
    ; Mostrar la cadena concatenada
    mov rsi, msg_concat_all
    call print_string
    mov rsi, all_concat
    call print_string
    call print_newline
    
    ; Crear la llave para cifrado (llave_dosificacion + 5_digitos_verhoeff)
    mov rdi, rc4_key
    mov rsi, llave_dosificacion
    call strcpy
    
    mov rdi, rc4_key
    call strlen
    add rdi, rax
    mov rsi, temp_buffer  ; contiene los 5 dígitos Verhoeff
    call strcpy
    
    ; Mostrar la llave de cifrado
    mov rsi, msg_llave_cifrado
    call print_string
    mov rsi, rc4_key
    call print_string
    call print_newline
        
    ; Aplicar el algoritmo AllegedRC4
    mov rsi, all_concat  ; texto a cifrar
    call strlen
    mov rdx, rax         ; Longitud de los datos (guardada en rdx)
    
    mov rsi, all_concat  ; texto a cifrar
    mov rdi, rc4_key     ; llave en nuestro caso se pasa en rdx
    mov rbx, rc4_result  ; buffer para el resultado
    call alleged_rc4     ; Nuestra función espera llave en rdx (diferente a paste-2.txt)
    
    ; Convertir el resultado a representación hexadecimal
    mov rsi, rc4_result
    mov rdi, hex_output
    mov rcx, rdx         ; Usar la longitud original
    call to_hex
    
    ; Mostrar el resultado del cifrado
    mov rsi, msg_rc4_result
    call print_string
    mov rsi, hex_output
    call print_string
    call print_newline


;======= Paso 4: Calcular sumatorias de valores ASCII

mov rsi, msg_step4_header
call print_string

; Inicializar sumatorias
mov qword [suma_total], 0
mov qword [suma_parcial1], 0
mov qword [suma_parcial2], 0
mov qword [suma_parcial3], 0
mov qword [suma_parcial4], 0
mov qword [suma_parcial5], 0

; Usar la cadena hexadecimal del resultado RC4 (hex_output)
mov rsi, hex_output
call strlen
mov rcx, rax        ; Longitud de la cadena hexadecimal

; Procesar cada carácter de la cadena hexadecimal
xor rbx, rbx        ; índice = 0

paso4_loop:
    cmp rbx, rcx
    jge paso4_done
    
    ; Obtener valor ASCII del carácter
    movzx rax, byte [hex_output + rbx]
    
    ; Agregar a la sumatoria total
    add [suma_total], rax
    
    ; Calcular a qué sumatoria parcial corresponde (índice % 5)
    mov rax, rbx
    xor rdx, rdx
    mov r8, 5
    div r8          ; rdx = índice % 5
    
    ; Determinar a qué sumatoria parcial corresponde (0-based)
    cmp rdx, 0
    je add_to_sum1
    
    cmp rdx, 1
    je add_to_sum2
    
    cmp rdx, 2
    je add_to_sum3
    
    cmp rdx, 3
    je add_to_sum4
    
    cmp rdx, 4
    je add_to_sum5
    
    jmp next_byte   ; Por seguridad (nunca debería llegar aquí)
    
add_to_sum1:
    movzx rax, byte [hex_output + rbx]
    add [suma_parcial1], rax
    jmp next_byte
    
add_to_sum2:
    movzx rax, byte [hex_output + rbx]
    add [suma_parcial2], rax
    jmp next_byte
    
add_to_sum3:
    movzx rax, byte [hex_output + rbx]
    add [suma_parcial3], rax
    jmp next_byte
    
add_to_sum4:
    movzx rax, byte [hex_output + rbx]
    add [suma_parcial4], rax
    jmp next_byte
    
add_to_sum5:
    movzx rax, byte [hex_output + rbx]
    add [suma_parcial5], rax
    
next_byte:
    inc rbx
    jmp paso4_loop

paso4_done:
    ; Mostrar los resultados
    mov rsi, msg_suma_total
    call print_string
    mov rax, [suma_total]
    call print_int
    call print_newline
    
    mov rsi, msg_suma_parcial1
    call print_string
    mov rax, [suma_parcial1]
    call print_int
    call print_newline
    
    mov rsi, msg_suma_parcial2
    call print_string
    mov rax, [suma_parcial2]
    call print_int
    call print_newline
    
    mov rsi, msg_suma_parcial3
    call print_string
    mov rax, [suma_parcial3]
    call print_int
    call print_newline
    
    mov rsi, msg_suma_parcial4
    call print_string
    mov rax, [suma_parcial4]
    call print_int
    call print_newline
    
    mov rsi, msg_suma_parcial5
    call print_string
    mov rax, [suma_parcial5]
    call print_int
    call print_newline    
    
;============= Paso 5: Calcular multiplicaciones, divisiones y Base64
;============= Paso 5: Calcular multiplicaciones, divisiones y Base64
mov rsi, msg_step5_header
call print_string

; Asignar directamente los dígitos Verhoeff correctos
mov r8, 7   ; Primer dígito Verhoeff
mov r9, 1   ; Segundo dígito Verhoeff
mov r10, 6  ; Tercer dígito Verhoeff
mov r11, 2  ; Cuarto dígito Verhoeff
mov r12, 1  ; Quinto dígito Verhoeff

; Añadir 1 para los divisores
inc r8    ; DV1+1 = 8
inc r9    ; DV2+1 = 2
inc r10   ; DV3+1 = 7
inc r11   ; DV4+1 = 3
inc r12   ; DV5+1 = 2

; ST * SP1 / (DV1+1)
mov rax, [suma_total]
mul qword [suma_parcial1]
div r8
mov [result_mult1], rax

; ST * SP2 / (DV2+1)
mov rax, [suma_total]
mul qword [suma_parcial2]
div r9
mov [result_mult2], rax

; ST * SP3 / (DV3+1)
mov rax, [suma_total]
mul qword [suma_parcial3]
div r10
mov [result_mult3], rax

; ST * SP4 / (DV4+1)
mov rax, [suma_total]
mul qword [suma_parcial4]
div r11
mov [result_mult4], rax

; ST * SP5 / (DV5+1)
mov rax, [suma_total]
mul qword [suma_parcial5]
div r12
mov [result_mult5], rax

; Mostrar resultados
mov rsi, msg_mult_1
call print_string
mov rax, [result_mult1]
call print_int
call print_newline

mov rsi, msg_mult_2
call print_string
mov rax, [result_mult2]
call print_int
call print_newline

mov rsi, msg_mult_3
call print_string
mov rax, [result_mult3]
call print_int
call print_newline

mov rsi, msg_mult_4
call print_string
mov rax, [result_mult4]
call print_int
call print_newline

mov rsi, msg_mult_5
call print_string
mov rax, [result_mult5]
call print_int
call print_newline

; Sumar todos los resultados
mov rax, [result_mult1]
add rax, [result_mult2]
add rax, [result_mult3]
add rax, [result_mult4]
add rax, [result_mult5]
mov [suma_final], rax

; Mostrar sumatoria final
mov rsi, msg_suma_final
call print_string
mov rax, [suma_final]
call print_int
call print_newline

; Convertir a Base64
mov rax, [suma_final]
mov rdi, base64_result
call base64_encode

; Mostrar resultado Base64
mov rsi, msg_base64
call print_string
mov rsi, base64_result
call print_string
call print_newline

;===================== ; Paso 6: Aplicar AllegedRC4 a la expresión Base64
mov rsi, msg_step6_header
call print_string

; Mostrar entrada Base64
mov rsi, msg_input_base64
call print_string
mov rsi, base64_result
call print_string
call print_newline

; Aplicar AllegedRC4 a la expresión Base64
mov rsi, base64_result  ; Entrada: expresión Base64
mov rdi, rc4_key        ; Llave: la misma que usamos en el Paso 3
mov rbx, base64_cifrado ; Buffer para resultado
call alleged_rc4

; Convertir el resultado a formato hexadecimal
mov rsi, base64_cifrado
call strlen
mov rcx, rax            ; Longitud del resultado
mov rsi, base64_cifrado
mov rdi, codigo_control
call to_hex

; Dar formato al Código de Control: pares separados por guiones
mov rsi, codigo_control
mov rdi, temp_buffer
call format_codigo_control

; Mostrar Código de Control
mov rsi, msg_codigo_control
call print_string
mov rsi, temp_buffer
call print_string
call print_newline

; Salir
mov rax, 60
xor rdi, rdi
syscall
    
    ; Salir
    mov rax, 60
    xor rdi, rdi
    syscall

; ========== Funciones principales ==========

; Añadir n dígitos Verhoeff a una cadena
add_verhoeff_digits:
    push rbx
    push rcx
    push rsi
    push rdi
    mov rbx, rsi
    
    ; Calcular longitud actual
    mov rdi, rbx
    call strlen
    mov rdi, rbx
    add rdi, rax  ; Apuntar al final de la cadena
    
.digit_loop:
    test rcx, rcx
    jz .done
    
    ; Calcular dígito Verhoeff
    mov rsi, rbx
    call verhoeff_check_digit
    
    ; Convertir a ASCII y almacenar
    add al, '0'
    mov [rdi], al
    inc rdi
    
    ; Terminar cadena
    mov byte [rdi], 0
    
    dec rcx
    jmp .digit_loop
    
.done:
    pop rdi
    pop rsi
    pop rcx
    pop rbx
    ret

; Calcular dígito Verhoeff
verhoeff_check_digit:
    push rbx
    push rcx
    push rsi
    push rdi
    
    xor rcx, rcx    ; c = 0
    mov rdi, rsi
    call strlen
    mov rbx, rax    ; rbx = longitud
    
    ; Limpiar buffer temporal
    mov rdi, temp_buffer
    mov rcx, 20
    xor al, al
    rep stosb
    
    ; Construir cadena invertida con '0' inicial
    mov rdi, temp_buffer
    mov byte [rdi], '0'
    inc rdi
    
    ; Invertir cadena original
    lea rsi, [rsi + rbx - 1]  ; Apuntar al último carácter
    
.reverse_loop:
    test rbx, rbx
    jz .reverse_done
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    dec rsi
    dec rbx
    jmp .reverse_loop
    
.reverse_done:
    mov byte [rdi], 0
    
    ; Procesar cadena invertida
    mov rsi, temp_buffer
    xor rbx, rbx    ; contador de posición
    
.process_loop:
    movzx rax, byte [rsi]
    test al, al
    jz .process_done
    
    ; Convertir ASCII a dígito
    sub al, '0'
    
    ; Calcular índice para tabla p
    mov rdx, rbx
    and rdx, 7      ; pos % 8
    imul rdx, 10
    add rdx, rax
    movzx rax, byte [p + rdx]
    
    ; Calcular índice para tabla d
    imul rdx, rcx, 10
    add rdx, rax
    movzx rcx, byte [d + rdx]
    
    inc rsi
    inc rbx
    jmp .process_loop
    
.process_done:
    ; Obtener dígito inverso
    movzx rax, byte [inv + rcx]
    
    pop rdi
    pop rsi
    pop rcx
    pop rbx
    ret

; Extraer substring
; rdi = buffer destino, rsi = string origen, rcx = longitud a extraer
extract_substring:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    mov rbx, rcx    ; Guardar longitud
    mov rcx, 0      ; Contador de caracteres extraídos
    
.loop:
    cmp rcx, rbx
    je .done
    
    movzx rax, byte [rsi]
    test rax, rax
    jz .done        ; Proteger contra fin de cadena
    
    mov [rdi], al   ; Copiar carácter
    inc rsi
    inc rdi
    inc rcx
    jmp .loop
    
.done:
    mov byte [rdi], 0   ; Terminar cadena
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

; Función para implementar el algoritmo Alleged RC4
; rsi = texto a cifrar, rdi = buffer resultado, rdx = llave
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
    push rdi
    mov rsi, r12
    call strlen
    mov r15, rax           ; r15 = longitud de datos
    pop rdi
    
    push rdi
    mov rsi, r13
    call strlen
    mov r11, rax           ; r11 = longitud de llave
    pop rdi
    
    ; Inicializar la tabla S (0 a 255)
    xor rcx, rcx
.init_state_loop:
    mov byte [rc4_state + rcx], cl
    inc rcx
    cmp rcx, 256
    jl .init_state_loop
    
    ; KSA – Key Scheduling Algorithm
    xor rcx, rcx           ; j = 0
    xor rsi, rsi           ; i = 0
    
.key_schedule_loop:
    ; j = (j + S[i] + key[i % len(key)]) % 256
    movzx rax, byte [rc4_state + rsi]
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
    mov al, byte [rc4_state + rsi]
    mov dl, byte [rc4_state + rcx]
    mov byte [rc4_state + rsi], dl
    mov byte [rc4_state + rcx], al
    
    inc rsi
    cmp rsi, 256
    jl .key_schedule_loop
    
    ; PRGA – Pseudo-Random Generation Algorithm
    xor rsi, rsi           ; i = 0
    xor rcx, rcx           ; j = 0
    xor rbx, rbx           ; contador de caracteres procesados
    
.prga_loop:
    cmp rbx, r15
    jge .prga_done
    
    ; i = (i + 1) % 256
    inc rsi
    and rsi, 0xFF
    
    ; j = (j + S[i]) % 256
    movzx rax, byte [rc4_state + rsi]
    add rcx, rax
    and rcx, 0xFF
    
    ; Intercambiar S[i] y S[j]
    mov al, byte [rc4_state + rsi]
    mov dl, byte [rc4_state + rcx]
    mov byte [rc4_state + rsi], dl
    mov byte [rc4_state + rcx], al
    
    ; K = S[(S[i] + S[j]) % 256]
    movzx rax, byte [rc4_state + rsi]
    movzx rdx, byte [rc4_state + rcx]
    add rax, rdx
    and rax, 0xFF
    movzx rax, byte [rc4_state + rax]
    
    ; output[k] = input[k] XOR K
    xor al, byte [r12 + rbx]
    mov byte [r14 + rbx], al
    
    inc rbx
    jmp .prga_loop
    
.prga_done:
    ; Terminar la cadena con un nulo
    mov byte [r14 + r15], 0
    
    ; Devolver la longitud
    mov rax, r15
    
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
; Función para convertir datos a representación hexadecimal
; rsi = buffer fuente, rdi = buffer destino
to_hex:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    
    ; Procesar cada byte
    xor rbx, rbx    ; Contador
.hex_loop:
    cmp rbx, rcx
    jge .hex_done
    
    ; Obtener byte
    movzx rax, byte [rsi + rbx]
    
    ; Primer dígito (bits altos)
    mov r8, rax
    shr r8, 4       ; Bits altos
    movzx r9, byte [hex_digits + r8]
    mov [rdi], r9b
    inc rdi
    
    ; Segundo dígito (bits bajos)
    and rax, 0xF    ; Bits bajos
    movzx r9, byte [hex_digits + rax]
    mov [rdi], r9b
    inc rdi
    
    ; Añadir espacio o guión cada 2 bytes
    ;inc rbx
    ;cmp rbx, rcx
    ;jge .skip_separator
    
    ;mov byte [rdi], '-'
    ;inc rdi
    
    inc rbx     ; Incrementar contador
    jmp .hex_loop
    
;.skip_separator:
    ;jmp .hex_loop
    
.hex_done:
    ; Terminar la cadena
    mov byte [rdi], 0
    
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;=====
; Función para imprimir un entero
; rax = valor a imprimir
print_int:
    push rax
    push rdi
    
    ; Convertir a string
    mov rdi, temp_buffer
    call int_to_str
    
    ; Imprimir
    mov rsi, temp_buffer
    call print_string
    
    pop rdi
    pop rax
    ret

;=========

; Convertir un byte a su representación hexadecimal
; rax = byte a convertir, rdi = buffer destino
byte_to_hex:
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rbx, rax
    
    ; Dígito alto
    shr rbx, 4
    mov al, byte [hex_digits + rbx]
    mov [rdi], al
    
    ; Dígito bajo
    mov rbx, rax
    and rbx, 0xF
    mov al, byte [hex_digits + rbx]
    mov [rdi + 1], al
    
    ; Terminar cadena
    mov byte [rdi + 2], 0
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
    
;=============
; Convertir entero a Base64 según el algoritmo proporcionado
; rax = valor a convertir, rdi = buffer destino
base64_encode:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Guardar puntero original al buffer
    mov rbx, rdi
    
    ; Si el número es 0, devolver el primer carácter del diccionario
    test rax, rax
    jnz .not_zero
    
    movzx rcx, byte [base64_dict]  ; Primer carácter del diccionario (0)
    mov [rdi], cl
    mov byte [rdi + 1], 0
    jmp .done
    
.not_zero:
    ; Guardar dígitos en orden inverso
    mov rcx, 64        ; Base 64
    
.digit_loop:
    ; Dividir por 64
    xor rdx, rdx
    div rcx            ; rax = cociente, rdx = residuo
    
    ; Obtener carácter Base64
    movzx rcx, byte [base64_dict + rdx]
    mov [rdi], cl
    inc rdi
    
    ; Si el cociente es 0, terminamos
    test rax, rax
    jz .invert
    
    ; Restaurar divisor
    mov rcx, 64
    jmp .digit_loop
    
.invert:
    ; Terminar la cadena
    mov byte [rdi], 0
    
    ; Invertir la cadena resultante
    mov rdi, rbx
    call reverse_string
    
.done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
    
; Invertir una cadena
; rdi = puntero a la cadena
reverse_string:
    push rax
    push rcx
    push rsi
    push rdi
    push r8
    push r9
    
    ; Calcular longitud
    mov rsi, rdi
    call strlen
    mov rcx, rax
    
    ; Si la cadena es vacía o tiene un solo carácter, no hacer nada
    cmp rcx, 1
    jle .done
    
    ; Preparar punteros
    mov rsi, rdi            ; rsi = inicio
    lea rdi, [rdi + rcx - 1] ; rdi = fin
    shr rcx, 1              ; rcx = longitud / 2
    
.loop:
    ; Intercambiar caracteres
    mov r8b, [rsi]
    mov r9b, [rdi]
    mov [rsi], r9b
    mov [rdi], r8b
    
    ; Avanzar al siguiente par
    inc rsi
    dec rdi
    
    ; Seguir hasta la mitad
    dec rcx
    jnz .loop
    
.done:
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rcx
    pop rax
    ret
    
; =============== ; Dar formato al Código de Control: pares separados por guiones
; rsi = entrada (cadena hexadecimal), rdi = destino
format_codigo_control:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    
    ; Guardar punteros
    mov rbx, rsi  ; rbx = entrada
    mov rdx, rdi  ; rdx = destino
    
    ; Calcular longitud
    call strlen
    mov rcx, rax
    
    ; Solo tomar los primeros 10 caracteres (5 bytes)
    cmp rcx, 10
    jle .process
    mov rcx, 10
    
.process:
    ; Procesar cada par de caracteres
    xor rax, rax  ; Contador de caracteres copiados
    
.copy_loop:
    ; Verificar si hemos terminado
    cmp rax, rcx
    jge .done
    
    ; Copiar par de caracteres
    mov bl, [rsi + rax]
    mov [rdi], bl
    inc rax
    
    ; Si es el fin, terminar
    cmp rax, rcx
    jge .done
    
    mov bl, [rsi + rax]
    mov [rdi + 1], bl
    inc rax
    
    ; Avanzar destino
    add rdi, 2
    
    ; Si no es el fin, añadir guión
    cmp rax, rcx
    jge .done
    
    mov byte [rdi], '-'
    inc rdi
    
    jmp .copy_loop
    
.done:
    ; Terminar cadena
    mov byte [rdi], 0
    
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret    
    
    
    
    
; ========== Funciones auxiliares ==========

; Copiar cadena (rsi = origen, rdi = destino)
strcpy:
    push rax
    push rsi
    push rdi
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    pop rdi
    pop rsi
    pop rax
    ret

; Longitud de cadena (rsi = cadena, ret rax = longitud)
strlen:
    push rdi
    mov rdi, rsi
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    pop rdi
    ret

; Imprimir cadena (rsi = cadena)
print_string:
    push rax
    push rdi
    push rdx
    push rsi
    
    call strlen
    mov rdx, rax    ; longitud
    
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    syscall
    
    pop rsi
    pop rdx
    pop rdi
    pop rax
    ret

; Imprimir nueva línea
print_newline:
    push rsi
    mov rsi, newline
    call print_string
    pop rsi
    ret

; Convertir string a entero (rsi = cadena, ret rax = valor)
str_to_int:
    push rbx
    push rsi
    xor rax, rax
    xor rbx, rbx
.loop:
    movzx rbx, byte [rsi]
    test rbx, rbx
    jz .done
    cmp rbx, '0'
    jb .done
    cmp rbx, '9'
    ja .done
    sub rbx, '0'
    imul rax, 10
    add rax, rbx
    inc rsi
    jmp .loop
.done:
    pop rsi
    pop rbx
    ret

; Convertir entero a string (rax = valor, rdi = buffer destino)
int_to_str:
    push rbx
    push rdx
    push rdi
    
    test rax, rax
    jnz .not_zero
    mov byte [rdi], '0'
    mov byte [rdi + 1], 0
    jmp .done
    
.not_zero:
    mov rbx, rdi    ; Guardar inicio del buffer
    add rdi, 19     ; Máximo espacio necesario
    mov byte [rdi], 0
    dec rdi
    
    mov rcx, 10     ; Base decimal
.convert_loop:
    xor rdx, rdx
    div rcx         ; rax = cociente, rdx = residuo
    add dl, '0'     ; Convertir dígito a ASCII
    mov [rdi], dl
    dec rdi
    test rax, rax   ; ¿Terminamos?
    jnz .convert_loop
    
    ; Mover los dígitos al inicio del buffer
    inc rdi         ; Ajustar puntero
    mov rsi, rdi
    mov rdi, rbx
    call strcpy
    
.done:
    pop rdi
    pop rdx
    pop rbx
    ret