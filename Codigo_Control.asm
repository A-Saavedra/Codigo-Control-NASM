;=============================================================================
; GENERADOR DE CÓDIGO DE CONTROL PARA FACTURACIÓN ELECTRÓNICA BOLIVIANA
;
; Implementa el algoritmo oficial del Servicio de Impuestos Nacionales (SIN)
; para generar el Código de Control de facturas digitales.
;
; Compilación: nasm -f elf64 codigo_control.asm -o codigo_control.o
; Enlazado:    ld codigo_control.o -o codigo_control
;
; Autores: 
;   Alex Saavedra
;   Andy Montaño
;
; Comentarios e indentado: Claude 3.7 Sonnet
;=============================================================================

section .data
    ;-------------------------------------------------------------------------
    ; TABLAS PARA EL ALGORITMO DE VERHOEFF
    ;-------------------------------------------------------------------------
    ; Tabla de multiplicación d
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
    
    ; Tabla de permutación p
    p:  db 0,1,2,3,4,5,6,7,8,9
        db 1,5,7,6,2,8,3,0,9,4
        db 5,8,0,3,7,9,6,1,4,2
        db 8,9,1,6,0,4,3,5,2,7
        db 9,4,5,3,1,2,6,8,7,0
        db 4,2,8,6,5,7,3,9,0,1
        db 2,7,9,3,8,0,6,4,1,5
        db 7,0,4,6,9,1,3,2,5,8
    
    ; Tabla de inversión inv
    inv: db 0,4,3,2,1,5,6,7,8,9

    ;-------------------------------------------------------------------------
    ; DICCIONARIOS
    ;-------------------------------------------------------------------------
    ; Diccionario para Base64
    base64_dict: db "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/",0

    ; Dígitos hexadecimales
    hex_digits: db "0123456789ABCDEF",0
    
    ;-------------------------------------------------------------------------
    ; MENSAJES DE INTERFAZ
    ;-------------------------------------------------------------------------
    ; Mensaje principal de solicitud de datos
    msg_input_data: db "Recibiendo Datos de Insumo:",10,0
    
    ; Mensajes para el Paso 1
    header: db "Paso 1 - Datos con 2 digitos Verhoeff:",10,0
    msg_factura: db "Numero de Factura: ",0
    msg_nit: db "NIT/CI Cliente: ",0
    msg_fecha: db "Fecha Transaccion: ",0
    msg_monto: db "Monto Transaccion: ",0
    msg_suma: db 10,"Suma total: ",0
    msg_verhoeff: db "5 digitos Verhoeff: ",0
    newline: db 10,0
    
    ; Mensajes para el Paso 2
    msg_step2_header: db 10,"Paso 2 - Concatenaciones con substrings:",10,0
    msg_auth_concat: db "Autorizacion + Substring 1: ",0
    msg_factura_concat: db "Factura + Substring 2: ",0
    msg_nit_concat: db "NIT + Substring 3: ",0
    msg_fecha_concat: db "Fecha + Substring 4: ",0
    msg_monto_concat: db "Monto + Substring 5: ",0
    
    ; Mensajes para el Paso 3
    msg_step3_header: db 10,"Paso 3 - Cifrado con AllegedRC4:",10,0
    msg_concat_all: db "Cadena concatenada: ",0
    msg_llave_cifrado: db "Llave para cifrado: ",0
    msg_rc4_result: db "Resultado RC4 (hex): ",0

    ; Mensajes para el Paso 4
    msg_step4_header: db 10,"Paso 4 - Sumatorias de valores ASCII:",10,0
    msg_suma_total: db "Sumatoria Total: ",0
    msg_suma_parcial1: db "Sumatoria Parcial 1 (1,6,11,16,...): ",0
    msg_suma_parcial2: db "Sumatoria Parcial 2 (2,7,12,17,...): ",0
    msg_suma_parcial3: db "Sumatoria Parcial 3 (3,8,13,18,...): ",0
    msg_suma_parcial4: db "Sumatoria Parcial 4 (4,9,14,19,...): ",0
    msg_suma_parcial5: db "Sumatoria Parcial 5 (5,10,15,20,...): ",0

    ; Mensajes para el Paso 5
    msg_step5_header: db 10,"Paso 5 - Cálculos finales y Base64:",10,0
    msg_mult_1: db "ST * SP1 / (DV1+1) = ",0
    msg_mult_2: db "ST * SP2 / (DV2+1) = ",0
    msg_mult_3: db "ST * SP3 / (DV3+1) = ",0
    msg_mult_4: db "ST * SP4 / (DV4+1) = ",0
    msg_mult_5: db "ST * SP5 / (DV5+1) = ",0
    msg_suma_final: db "Sumatoria final: ",0
    msg_base64: db "Base64: ",0

    ; Mensajes para el Paso 6
    msg_step6_header: db 10,"Paso 6 - AllegedRC4 para obtener Código de Control:",10,0
    msg_input_base64: db "Entrada Base64: ",0
    msg_codigo_control: db "Código de Control: ",0

section .bss
    ;-------------------------------------------------------------------------
    ; BUFFERS PARA DATOS DE ENTRADA
    ;-------------------------------------------------------------------------
    buffer: resb 1024                ; Buffer temporal para entrada
    input_buffer: resb 2048          ; Buffer para leer todas las líneas de entrada
    
    ; Datos de facturación
    numero_autorizacion: resb 50     ; Número de autorización (max 15 dígitos)
    numero_factura: resb 50          ; Número de factura (max 12 dígitos)
    nit_cliente: resb 50             ; NIT o CI del cliente (max 12 dígitos)
    fecha_transaccion: resb 50       ; Fecha (formato AAAAMMDD, 8 dígitos)
    monto_transaccion: resb 50       ; Monto de la transacción (sin centavos)
    llave_dosificacion: resb 256     ; Llave de dosificación (max 256 caracteres)
    
    ;-------------------------------------------------------------------------
    ; BUFFERS PARA PROCESAMIENTO
    ;-------------------------------------------------------------------------
    ; Buffers para el Paso 1 (dígitos Verhoeff)
    factura_ver: resb 20             ; Factura con 2 dígitos Verhoeff
    nit_ver: resb 20                 ; NIT con 2 dígitos Verhoeff
    fecha_ver: resb 20               ; Fecha con 2 dígitos Verhoeff
    monto_ver: resb 20               ; Monto con 2 dígitos Verhoeff
    suma_str: resb 20                ; Suma total en formato string
    cinco_digitos_ver: resb 10       ; Para calcular los 5 dígitos Verhoeff
    digitos_verhoeff: resb 6         ; Los 5 dígitos Verhoeff finales
    
    ; Buffers para el Paso 2 (concatenaciones)
    auth_concat: resb 50             ; Autorización + substring 1
    factura_concat: resb 50          ; Factura + substring 2
    nit_concat: resb 50              ; NIT + substring 3
    fecha_concat: resb 50            ; Fecha + substring 4
    monto_concat: resb 50            ; Monto + substring 5
    
    ; Buffers para el Paso 3 (RC4)
    all_concat: resb 500             ; Cadena concatenada completa
    rc4_key: resb 300                ; Llave para cifrado RC4
    rc4_result: resb 500             ; Resultado del cifrado RC4
    hex_output: resb 1000            ; Representación hexadecimal del resultado
    
    ; Buffers para el algoritmo RC4
    rc4_state: resb 256              ; Estado interno del algoritmo RC4
    rc4_temp: resb 1                 ; Variable temporal para RC4
    
    ; Buffers para el Paso 6 (código final)
    base64_cifrado: resb 100         ; Resultado de cifrar la cadena Base64
    codigo_control: resb 50          ; Código de control en formato hexadecimal

    ; Buffer auxiliar para operaciones generales
    temp_buffer: resb 20             ; Buffer temporal para diversas operaciones
    substring: resb 20               ; Buffer para extraer subcadenas

    ;-------------------------------------------------------------------------
    ; VARIABLES PARA SUMATORIAS (PASO 4)
    ;-------------------------------------------------------------------------
    suma_total: resq 1               ; Sumatoria total de valores ASCII
    suma_parcial1: resq 1            ; Sumatoria posiciones 1,6,11,16,...
    suma_parcial2: resq 1            ; Sumatoria posiciones 2,7,12,17,...
    suma_parcial3: resq 1            ; Sumatoria posiciones 3,8,13,18,...
    suma_parcial4: resq 1            ; Sumatoria posiciones 4,9,14,19,...
    suma_parcial5: resq 1            ; Sumatoria posiciones 5,10,15,20,...

    ;-------------------------------------------------------------------------
    ; VARIABLES PARA CÁLCULOS FINALES (PASO 5)
    ;-------------------------------------------------------------------------
    result_mult1: resq 1             ; Resultado ST * SP1 / (DV1+1)
    result_mult2: resq 1             ; Resultado ST * SP2 / (DV2+1)
    result_mult3: resq 1             ; Resultado ST * SP3 / (DV3+1)
    result_mult4: resq 1             ; Resultado ST * SP4 / (DV4+1)
    result_mult5: resq 1             ; Resultado ST * SP5 / (DV5+1)
    suma_final: resq 1               ; Suma de todos los resultados
    base64_result: resb 20           ; Codificación Base64 del resultado final

section .text
global _start

;=============================================================================
; PROGRAMA PRINCIPAL
;=============================================================================
_start:
    ; Mostrar mensaje para recibir datos
    mov rsi, msg_input_data
    call print_string
    
    ;-------------------------------------------------------------------------
    ; RECEPCIÓN DE DATOS
    ;-------------------------------------------------------------------------
    call read_all_input              ; Leer todas las líneas de entrada
    
    mov rsi, input_buffer            ; Puntero al buffer con la entrada
    
    ; Extraer cada línea de datos
    mov rdi, numero_autorizacion
    call extract_line
    
    mov rdi, numero_factura
    call extract_line
    
    mov rdi, nit_cliente
    call extract_line
    
    mov rdi, fecha_transaccion
    call extract_line
    
    mov rdi, monto_transaccion
    call extract_line
    
    ; Procesar el monto para redondear y eliminar coma decimal
    call process_monto

    mov rdi, llave_dosificacion
    call extract_line
        
    ; Mostrar los datos de entrada recibidos
    mov rsi, numero_autorizacion
    call print_string
    call print_newline
    
    mov rsi, numero_factura
    call print_string
    call print_newline
    
    mov rsi, nit_cliente
    call print_string
    call print_newline
    
    mov rsi, fecha_transaccion
    call print_string
    call print_newline
    
    mov rsi, monto_transaccion
    call print_string
    call print_newline
    
    mov rsi, llave_dosificacion
    call print_string
    call print_newline
    call print_newline
 
;=============================================================================
; PASO 1: CALCULAR DÍGITOS VERHOEFF
;=============================================================================
    mov rsi, header
    call print_string
    
    ; Añadir 2 dígitos Verhoeff a cada campo
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
    
    ; Mostrar los valores con dígitos Verhoeff añadidos
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
    
    ; Calcular la suma de todos los valores con Verhoeff
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
    
    ; Mostrar la suma total
    mov rsi, msg_suma
    call print_string
    mov rsi, suma_str
    call print_string
    call print_newline
    
    ; Generar 5 dígitos Verhoeff para la suma total
    mov rsi, suma_str
    mov rdi, cinco_digitos_ver
    call strcpy
    mov rsi, cinco_digitos_ver
    mov rcx, 5
    call add_verhoeff_digits
    
    ; Extraer solo los 5 dígitos Verhoeff
    mov rsi, cinco_digitos_ver
    call strlen
    lea rsi, [cinco_digitos_ver + rax - 5]  ; Apuntar a los últimos 5 dígitos
    mov rdi, digitos_verhoeff
    call strcpy
    
    ; Mostrar los 5 dígitos Verhoeff
    mov rsi, msg_verhoeff
    call print_string
    mov rsi, digitos_verhoeff
    call print_string
    call print_newline

;=============================================================================
; PASO 2: EXTRAER SUBSTRINGS Y CONCATENAR CON DATOS
;=============================================================================
    mov rsi, msg_step2_header
    call print_string
    
    mov r8, 0                        ; Posición en la llave de dosificación
    
    ; --- Substring 1 ---
    movzx rcx, byte [digitos_verhoeff]  ; Primer dígito Verhoeff
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
    movzx rcx, byte [digitos_verhoeff+1]  ; Segundo dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8
    call extract_substring
    add r8, rcx
    
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
    movzx rcx, byte [digitos_verhoeff+2]  ; Tercer dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8
    call extract_substring
    add r8, rcx
    
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
    movzx rcx, byte [digitos_verhoeff+3]  ; Cuarto dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8
    call extract_substring
    add r8, rcx
    
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
    movzx rcx, byte [digitos_verhoeff+4]  ; Quinto dígito Verhoeff
    sub rcx, '0'
    inc rcx
    
    mov rdi, substring
    mov rsi, llave_dosificacion
    add rsi, r8
    call extract_substring
    add r8, rcx
    
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
    
;=============================================================================
; PASO 3: CIFRADO CON ALLEGED RC4
;=============================================================================
    mov rsi, msg_step3_header
    call print_string
    
    ; Limpiar buffer de concatenación
    mov rdi, all_concat
    xor al, al
    mov rcx, 500
    rep stosb
    
    ; Concatenar todas las cadenas
    mov rdi, all_concat
    mov rsi, auth_concat
    call strcat
    
    mov rdi, all_concat
    mov rsi, factura_concat
    call strcat
    
    mov rdi, all_concat
    mov rsi, nit_concat
    call strcat
    
    mov rdi, all_concat
    mov rsi, fecha_concat
    call strcat
    
    mov rdi, all_concat
    mov rsi, monto_concat
    call strcat
        
    ; Mostrar la cadena concatenada
    mov rsi, msg_concat_all
    call print_string
    mov rsi, all_concat
    call print_string
    call print_newline
    
    ; Construir la llave de cifrado (llave + 5 dígitos Verhoeff)
    mov rdi, rc4_key
    mov rsi, llave_dosificacion
    call strcpy
    
    mov rdi, rc4_key
    call strlen
    add rdi, rax
    mov rsi, digitos_verhoeff
    call strcpy
    
    ; Mostrar la llave de cifrado
    mov rsi, msg_llave_cifrado
    call print_string
    mov rsi, rc4_key
    call print_string
    call print_newline
    
    ; Aplicar el algoritmo AllegedRC4
    mov rsi, all_concat        ; Texto a cifrar
    call strlen
    mov rdx, rax               ; Longitud del texto
    
    mov rsi, all_concat        ; Texto a cifrar
    mov rdi, rc4_key           ; Llave de cifrado
    mov rbx, rc4_result        ; Buffer para resultado
    call alleged_rc4
    
    ; Convertir el resultado a representación hexadecimal
    mov rsi, rc4_result
    mov rdi, hex_output
    mov rcx, rdx               ; Usar la longitud original
    call to_hex
    
    ; Mostrar el resultado en hexadecimal
    mov rsi, msg_rc4_result
    call print_string
    mov rsi, hex_output
    call print_string
    call print_newline

;=============================================================================
; PASO 4: CÁLCULO DE SUMATORIAS ASCII
;=============================================================================
    mov rsi, msg_step4_header
    call print_string
    
    ; Inicializar sumatorias
    mov qword [suma_total], 0
    mov qword [suma_parcial1], 0
    mov qword [suma_parcial2], 0
    mov qword [suma_parcial3], 0
    mov qword [suma_parcial4], 0
    mov qword [suma_parcial5], 0
    
    ; Procesar cada carácter de la salida hexadecimal
    mov rsi, hex_output
    call strlen
    mov rcx, rax               ; Longitud de la cadena hexadecimal
    
    xor rbx, rbx               ; Inicializar contador

paso4_loop:
    ; Verificar si hemos procesado todos los caracteres
    cmp rbx, rcx
    jge paso4_done
    
    ; Obtener valor ASCII del carácter
    movzx rax, byte [hex_output + rbx]
    
    ; Sumar a la sumatoria total
    add [suma_total], rax
    
    ; Determinar a qué sumatoria parcial corresponde (índice % 5)
    mov rax, rbx
    xor rdx, rdx
    mov r8, 5
    div r8                     ; rdx = índice % 5
    
    ; Agregar a la sumatoria parcial correspondiente
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
    
    jmp next_byte              ; Por seguridad (nunca debería llegar aquí)
    
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
    inc rbx                    ; Avanzar al siguiente carácter
    jmp paso4_loop

paso4_done:
    ; Mostrar los resultados de las sumatorias
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
    
;=============================================================================
; PASO 5: CÁLCULOS FINALES Y CODIFICACIÓN BASE64
;=============================================================================
    mov rsi, msg_step5_header
    call print_string
    
    ; Extraer los dígitos Verhoeff y ajustar para divisores
    movzx r8, byte [digitos_verhoeff]      ; Primer dígito
    sub r8, '0'
    movzx r9, byte [digitos_verhoeff+1]    ; Segundo dígito
    sub r9, '0'
    movzx r10, byte [digitos_verhoeff+2]   ; Tercer dígito
    sub r10, '0'
    movzx r11, byte [digitos_verhoeff+3]   ; Cuarto dígito
    sub r11, '0'
    movzx r12, byte [digitos_verhoeff+4]   ; Quinto dígito
    sub r12, '0'
    
    ; Sumar 1 para obtener los divisores
    inc r8                     ; DV1+1
    inc r9                     ; DV2+1
    inc r10                    ; DV3+1
    inc r11                    ; DV4+1
    inc r12                    ; DV5+1
    
    ; Calcular multiplicaciones y divisiones
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
    
    ; Mostrar resultados de los cálculos
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

;=============================================================================
; PASO 6: APLICAR ALLEGED RC4 Y GENERAR CÓDIGO DE CONTROL
;=============================================================================
   mov rsi, msg_step6_header
   call print_string
   
   ; Mostrar entrada Base64
   mov rsi, msg_input_base64
   call print_string
   mov rsi, base64_result
   call print_string
   call print_newline
   
   ; Aplicar AllegedRC4 al resultado Base64
   mov rsi, base64_result     ; Texto a cifrar
   mov rdi, rc4_key           ; Llave (la misma que en el Paso 3)
   mov rbx, base64_cifrado    ; Buffer para resultado
   call alleged_rc4
   
   ; Convertir el resultado a hexadecimal
   mov rsi, base64_cifrado
   call strlen
   mov rcx, rax
   mov rsi, base64_cifrado
   mov rdi, codigo_control
   call to_hex
   
   ; Formatear el código de control (XX-XX-XX-XX)
   mov rsi, codigo_control
   mov rdi, temp_buffer
   call format_codigo_control
   
   ; Mostrar el código de control final
   mov rsi, msg_codigo_control
   call print_string
   mov rsi, temp_buffer
   call print_string
   call print_newline
   
   ; Terminar el programa
   mov rax, 60                ; syscall: exit
   xor rdi, rdi               ; status: 0
   syscall

;=============================================================================
; FUNCIONES PARA ALGORITMO VERHOEFF
;=============================================================================

; Añade n dígitos Verhoeff al final de una cadena
; Parámetros:
;   rsi = puntero a la cadena
;   rcx = número de dígitos Verhoeff a añadir
;   rdi = se actualiza al puntero al final de la cadena original
add_verhoeff_digits:
   push rbx
   push rcx
   push rsi
   push rdi
   mov rbx, rsi               ; Guardar puntero a la cadena original
   
   ; Encontrar el final de la cadena
   mov rdi, rbx
   call strlen
   mov rdi, rbx
   add rdi, rax               ; Posicionarse al final de la cadena
   
.digit_loop:
   test rcx, rcx              ; Verificar si hemos añadido todos los dígitos
   jz .done
   
   ; Calcular el dígito Verhoeff para la cadena actual
   mov rsi, rbx
   call verhoeff_check_digit
   
   ; Convertir a ASCII y añadir al final
   add al, '0'
   mov [rdi], al
   inc rdi
   
   ; Terminar la cadena con nulo
   mov byte [rdi], 0
   
   dec rcx                    ; Decrementar contador de dígitos
   jmp .digit_loop
   
.done:
   pop rdi
   pop rsi
   pop rcx
   pop rbx
   ret

; Calcula el dígito verificador Verhoeff para una cadena
; Parámetros:
;   rsi = puntero a la cadena
; Retorna:
;   al = dígito verificador
verhoeff_check_digit:
   push rbx
   push rcx
   push rsi
   push rdi
   
   xor rcx, rcx               ; c = 0 (acumulador)
   mov rdi, rsi
   call strlen
   mov rbx, rax               ; rbx = longitud de la cadena
   
   ; Preparar buffer temporal para la cadena invertida
   mov rdi, temp_buffer
   mov rcx, 20
   xor al, al
   rep stosb                  ; Limpiar buffer
   
   ; Construir cadena invertida con '0' inicial
   mov rdi, temp_buffer
   mov byte [rdi], '0'        ; Primer dígito es siempre '0'
   inc rdi
   
   ; Invertir la cadena original
   lea rsi, [rsi + rbx - 1]   ; Apuntar al último carácter
   
.reverse_loop:
   test rbx, rbx              ; Verificar si hemos procesado toda la cadena
   jz .reverse_done
   mov al, [rsi]              ; Obtener carácter
   mov [rdi], al              ; Almacenar en buffer invertido
   inc rdi
   dec rsi
   dec rbx
   jmp .reverse_loop
   
.reverse_done:
   mov byte [rdi], 0          ; Terminar cadena invertida
   
   ; Procesar la cadena invertida con el algoritmo Verhoeff
   mov rsi, temp_buffer
   xor rbx, rbx               ; Contador de posición
   xor rcx, rcx               ; c = 0 (acumulador)
   
.process_loop:
   movzx rax, byte [rsi]      ; Obtener carácter
   test al, al                ; Verificar si es fin de cadena
   jz .process_done
   
   sub al, '0'                ; Convertir ASCII a dígito
   
   ; Calcular índice para tabla p
   mov rdx, rbx
   and rdx, 7                 ; pos % 8
   imul rdx, 10               ; * 10 (tamaño de fila)
   add rdx, rax               ; + dígito
   movzx rax, byte [p + rdx]  ; Obtener valor de tabla p
   
   ; Calcular índice para tabla d
   imul rdx, rcx, 10          ; c * 10
   add rdx, rax               ; + valor de p
   movzx rcx, byte [d + rdx]  ; Obtener nuevo valor c
   
   inc rsi                    ; Avanzar al siguiente carácter
   inc rbx                    ; Incrementar contador de posición
   jmp .process_loop
   
.process_done:
   ; Obtener dígito inverso
   movzx rax, byte [inv + rcx]
   
   pop rdi
   pop rsi
   pop rcx
   pop rbx
   ret

;=============================================================================
; FUNCIONES PARA MANIPULACIÓN DE CADENAS
;=============================================================================

; Extrae una subcadena de longitud específica
; Parámetros:
;   rdi = buffer destino
;   rsi = cadena origen
;   rcx = longitud a extraer
extract_substring:
   push rax
   push rbx
   push rcx
   push rdx
   push rsi
   push rdi
   
   mov rbx, rcx               ; Guardar longitud a extraer
   mov rcx, 0                 ; Contador de caracteres extraídos
   
.loop:
   cmp rcx, rbx               ; Verificar si hemos extraído suficientes caracteres
   je .done
   
   movzx rax, byte [rsi]      ; Obtener carácter
   test rax, rax              ; Verificar si es fin de cadena
   jz .done                   ; Terminar si llegamos al final
   
   mov [rdi], al              ; Copiar carácter
   inc rsi
   inc rdi
   inc rcx
   jmp .loop
   
.done:
   mov byte [rdi], 0          ; Terminar cadena con nulo
   
   pop rdi
   pop rsi
   pop rdx
   pop rcx
   pop rbx
   pop rax
   ret

; Implementación del algoritmo Alleged RC4
; Parámetros:
;   rsi = texto a cifrar
;   rdi = llave de cifrado
;   rbx = buffer para resultado
; Retorna:
;   rax = longitud del resultado
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
   mov r12, rsi               ; r12 = texto a cifrar
   mov r13, rdi               ; r13 = llave
   mov r14, rbx               ; r14 = buffer resultado
   
   ; Calcular longitudes
   push rdi
   mov rsi, r12
   call strlen
   mov r15, rax               ; r15 = longitud del texto
   pop rdi
   
   push rdi
   mov rsi, r13
   call strlen
   mov r11, rax               ; r11 = longitud de la llave
   pop rdi
   
   ; Inicializar el estado (S-box)
   xor rcx, rcx
.init_state_loop:
   mov byte [rc4_state + rcx], cl  ; S[i] = i
   inc rcx
   cmp rcx, 256
   jl .init_state_loop
   
   ; Key-Scheduling Algorithm (KSA)
   xor rcx, rcx               ; j = 0
   xor rsi, rsi               ; i = 0
   
.key_schedule_loop:
   ; j = (j + S[i] + key[i % len(key)]) % 256
   movzx rax, byte [rc4_state + rsi]   ; S[i]
   add rcx, rax
   
   ; Calcular i % len(key)
   mov rax, rsi
   xor rdx, rdx
   div r11                    ; rdx = i % len(key)
   
   ; Obtener key[i % len(key)]
   movzx rax, byte [r13 + rdx]
   add rcx, rax
   and rcx, 0xFF              ; j = j % 256
   
   ; Intercambiar S[i] y S[j]
   mov al, byte [rc4_state + rsi]
   mov dl, byte [rc4_state + rcx]
   mov byte [rc4_state + rsi], dl
   mov byte [rc4_state + rcx], al
   
   inc rsi
   cmp rsi, 256
   jl .key_schedule_loop
   
   ; Pseudo-Random Generation Algorithm (PRGA)
   xor rsi, rsi               ; i = 0
   xor rcx, rcx               ; j = 0
   xor rbx, rbx               ; contador de bytes procesados
   
.prga_loop:
   cmp rbx, r15               ; Verificar si hemos procesado todo el texto
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
   ; Terminar resultado con nulo
   mov byte [r14 + r15], 0
   
   ; Devolver longitud del resultado
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

; Convierte datos binarios a representación hexadecimal
; Parámetros:
;   rsi = buffer fuente
;   rdi = buffer destino
;   rcx = longitud de los datos
to_hex:
   push rax
   push rbx
   push rcx
   push rdx
   push rsi
   push rdi
   push r8
   push r9
   
   xor rbx, rbx               ; Contador de bytes procesados
.hex_loop:
   cmp rbx, rcx               ; Verificar si hemos procesado todos los bytes
   jge .hex_done
   
   ; Obtener byte
   movzx rax, byte [rsi + rbx]
   
   ; Primer dígito hexadecimal (bits altos)
   mov r8, rax
   shr r8, 4                  ; r8 = bits altos del byte
   movzx r9, byte [hex_digits + r8]
   mov [rdi], r9b
   inc rdi
   
   ; Segundo dígito hexadecimal (bits bajos)
   and rax, 0xF               ; rax = bits bajos del byte
   movzx r9, byte [hex_digits + rax]
   mov [rdi], r9b
   inc rdi
   
   inc rbx                    ; Siguiente byte
   jmp .hex_loop
   
.hex_done:
   mov byte [rdi], 0          ; Terminar cadena con nulo
   
   pop r9
   pop r8
   pop rdi
   pop rsi
   pop rdx
   pop rcx
   pop rbx
   pop rax
   ret

; Imprime un entero en decimal
; Parámetros:
;   rax = entero a imprimir
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

; Convierte un byte a su representación hexadecimal
; Parámetros:
;   rax = byte a convertir
;   rdi = buffer destino
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
   
   mov byte [rdi + 2], 0      ; Terminar cadena
   
   pop rdx
   pop rcx
   pop rbx
   pop rax
   ret
   
; Convierte un entero a su representación Base64
; Parámetros:
;   rax = valor a convertir
;   rdi = buffer destino
base64_encode:
   push rax
   push rbx
   push rcx
   push rdx
   push rsi
   push rdi
   
   mov rbx, rdi               ; Guardar puntero al buffer destino
   
   ; Caso especial: valor = 0
   test rax, rax
   jnz .not_zero
   
   movzx rcx, byte [base64_dict]  ; Primer carácter del diccionario (0)
   mov [rdi], cl
   mov byte [rdi + 1], 0
   jmp .done
   
.not_zero:
   mov rcx, 64                ; Base 64
   
.digit_loop:
   ; Dividir por 64
   xor rdx, rdx
   div rcx                    ; rax = cociente, rdx = residuo
   
   ; Obtener carácter Base64 correspondiente al residuo
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
   
   ; Invertir la cadena resultante (Base64 se construye al revés)
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
   
; Invierte una cadena en su lugar
; Parámetros:
;   rdi = puntero a la cadena
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
   
   ; Si la cadena tiene 0 o 1 carácter, no hacer nada
   cmp rcx, 1
   jle .done
   
   ; Preparar punteros
   mov rsi, rdi               ; rsi = puntero al inicio
   lea rdi, [rdi + rcx - 1]   ; rdi = puntero al final
   shr rcx, 1                 ; rcx = longitud / 2
   
.loop:
   ; Intercambiar caracteres
   mov r8b, [rsi]
   mov r9b, [rdi]
   mov [rsi], r9b
   mov [rdi], r8b
   
   ; Avanzar al siguiente par
   inc rsi
   dec rdi
   
   dec rcx
   jnz .loop                  ; Continuar hasta la mitad
   
.done:
   pop r9
   pop r8
   pop rdi
   pop rsi
   pop rcx
   pop rax
   ret
   
; Formatea el código de control en pares separados por guiones (XX-XX-XX-XX)
; Parámetros:
;   rsi = entrada (cadena hexadecimal)
;   rdi = destino
format_codigo_control:
   push rax
   push rbx
   push rcx
   push rdx
   push rsi
   push rdi
   
   mov rbx, rsi               ; Guardar puntero a entrada
   mov rdx, rdi               ; Guardar puntero a destino
   
   ; Calcular longitud de la entrada
   call strlen
   mov rcx, rax
   
   ; Limitar a 10 caracteres (5 bytes) si es más largo
   cmp rcx, 10
   jle .process
   mov rcx, 10
   
.process:
   xor rax, rax               ; Contador de caracteres copiados
   
.copy_loop:
   ; Verificar si hemos terminado
   cmp rax, rcx
   jge .done
   
   ; Copiar primer carácter del par
   mov bl, [rsi + rax]
   mov [rdi], bl
   inc rax
   
   ; Verificar si queda otro carácter
   cmp rax, rcx
   jge .done
   
   ; Copiar segundo carácter del par
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
   
; Copia una cadena
; Parámetros:
;   rsi = origen
;   rdi = destino
strcpy:
   push rax
   push rsi
   push rdi
.loop:
   lodsb                      ; Cargar byte de [rsi] a al e incrementar rsi
   stosb                      ; Almacenar al en [rdi] e incrementar rdi
   test al, al                ; Verificar si es el byte nulo
   jnz .loop                  ; Continuar si no lo es
   pop rdi
   pop rsi
   pop rax
   ret

; Concatena cadenas
; Parámetros:
;   rdi = destino
;   rsi = cadena a añadir
strcat:
   push rax
   push rbx
   push rcx
   push rdx
   push rsi
   push rdi
   
   ; Guardar cadena a añadir
   mov rbx, rsi
   
   ; Encontrar el final de la cadena destino
   mov rsi, rdi               ; Poner la cadena destino en rsi para strlen
   call strlen
   add rdi, rax               ; Posicionarse al final de la cadena
   
   ; Recuperar cadena a añadir
   mov rsi, rbx
   
   ; Copiar la cadena a añadir
.loop:
   lodsb                      ; Cargar byte de [rsi] a al e incrementar rsi
   test al, al                ; Verificar si es el byte nulo
   jz .done                   ; Terminar si lo es
   stosb                      ; Almacenar al en [rdi] e incrementar rdi
   jmp .loop
   
.done:
   mov byte [rdi], 0          ; Asegurar terminación de cadena
   
   pop rdi
   pop rsi
   pop rdx
   pop rcx
   pop rbx
   pop rax
   ret
   
; Calcula la longitud de una cadena
; Parámetros:
;   rsi = cadena
; Retorna:
;   rax = longitud
strlen:
   push rdi
   mov rdi, rsi
   xor rax, rax               ; Contador a 0
.loop:
   cmp byte [rdi + rax], 0    ; Verificar si el byte actual es nulo
   je .done                   ; Terminar si lo es
   inc rax                    ; Incrementar contador
   jmp .loop
.done:
   pop rdi
   ret

; Imprime una cadena
; Parámetros:
;   rsi = cadena a imprimir
print_string:
   push rax
   push rdi
   push rdx
   push rsi
   
   call strlen                ; Calcular longitud
   mov rdx, rax               ; rdx = longitud
   
   mov rax, 1                 ; syscall: write
   mov rdi, 1                 ; fd: stdout
   syscall
   
   pop rsi
   pop rdx
   pop rdi
   pop rax
   ret

; Imprime un salto de línea
print_newline:
   push rsi
   mov rsi, newline
   call print_string
   pop rsi
   ret

; Convierte una cadena a entero
; Parámetros:
;   rsi = cadena
; Retorna:
;   rax = valor entero
str_to_int:
   push rbx
   push rsi
   xor rax, rax               ; Acumulador = 0
   xor rbx, rbx               ; Para dígitos individuales
.loop:
   movzx rbx, byte [rsi]      ; Obtener carácter
   test rbx, rbx              ; Verificar si es fin de cadena
   jz .done
   cmp rbx, '0'               ; Verificar si es dígito
   jb .done
   cmp rbx, '9'
   ja .done
   sub rbx, '0'               ; Convertir ASCII a dígito
   imul rax, 10               ; Multiplicar acumulador por 10
   add rax, rbx               ; Añadir nuevo dígito
   inc rsi                    ; Siguiente carácter
   jmp .loop
.done:
   pop rsi
   pop rbx
   ret

; Convierte un entero a cadena
; Parámetros:
;   rax = valor
;   rdi = buffer destino
int_to_str:
   push rbx
   push rdx
   push rdi
   
   ; Caso especial: valor = 0
   test rax, rax
   jnz .not_zero
   mov byte [rdi], '0'
   mov byte [rdi + 1], 0
   jmp .done
   
.not_zero:
   mov rbx, rdi               ; Guardar puntero inicial
   add rdi, 19                ; Ir al final del buffer (máximo 20 bytes)
   mov byte [rdi], 0          ; Añadir terminador nulo
   dec rdi                    ; Retroceder
   
   mov rcx, 10                ; Base decimal
.convert_loop:
   xor rdx, rdx               ; Limpiar parte alta para división
   div rcx                    ; rax = cociente, rdx = residuo
   add dl, '0'                ; Convertir dígito a ASCII
   mov [rdi], dl              ; Almacenar dígito
   dec rdi                    ; Retroceder en el buffer
   test rax, rax              ; Verificar si el cociente es 0
   jnz .convert_loop          ; Continuar si no lo es
   
   ; Mover los dígitos al inicio del buffer
   inc rdi                    ; Ajustar puntero (apunta al primer dígito)
   mov rsi, rdi               ; rsi = cadena temporal
   mov rdi, rbx               ; rdi = buffer destino original
   call strcpy                ; Copiar cadena a su posición correcta
   
.done:
   pop rdi
   pop rdx
   pop rbx
   ret
   
;=============================================================================
; FUNCIONES PARA ENTRADA/SALIDA
;=============================================================================

; Lee toda la entrada de una vez
read_all_input:
   push rax
   push rdi
   push rsi
   push rdx
   
   ; Limpiar el buffer de entrada
   mov rdi, input_buffer
   xor al, al
   mov rcx, 2048
   rep stosb
   
   ; Leer la entrada
   mov rax, 0                 ; syscall: read
   mov rdi, 0                 ; fd: stdin
   mov rsi, input_buffer      ; buffer
   mov rdx, 2048              ; tamaño máximo
   syscall
   
   pop rdx
   pop rsi
   pop rdi
   pop rax
   ret

; Extrae una línea del buffer de entrada
; Parámetros:
;   rsi = puntero al buffer (se actualiza para apuntar a la siguiente línea)
;   rdi = buffer destino para la línea
extract_line:
   push rax
   push rbx
   push rcx
   push rdx
   
   xor rcx, rcx               ; Contador de caracteres
   
.loop:
   movzx rax, byte [rsi]      ; Obtener carácter
   
   ; Verificar si es fin de línea o fin de cadena
   cmp al, 10                 ; LF (nueva línea)
   je .end_line
   cmp al, 13                 ; CR (retorno de carro)
   je .skip_cr
   cmp al, 0                  ; Fin de cadena
   je .end_string
   
   ; Copiar carácter al buffer destino
   mov [rdi + rcx], al
   inc rcx
   inc rsi
   jmp .loop
   
.skip_cr:
   inc rsi                    ; Saltar sobre CR
   ; Verificar si el siguiente carácter es LF
   cmp byte [rsi], 10
   jne .loop                  ; Si no es LF, continuar normalmente
   ; Si es LF, caer al manejador de LF
   
.end_line:
   ; Terminar cadena y avanzar al siguiente carácter
   mov byte [rdi + rcx], 0
   inc rsi                    ; Saltar sobre LF
   jmp .done
   
.end_string:
   ; Terminar cadena
   mov byte [rdi + rcx], 0
   
.done:
   pop rdx
   pop rcx
   pop rbx
   pop rax
   ret

; Procesa el monto para redondear y eliminar parte decimal
process_monto:
   push rax
   push rbx
   push rcx
   push rdx
   push rsi
   push rdi
   
   ; Buscar la coma o punto decimal en el monto
   mov rsi, monto_transaccion
   xor rcx, rcx
   
.find_decimal:
   movzx rax, byte [rsi + rcx]
   test rax, rax             ; Fin de cadena
   jz .no_decimal
   
   cmp al, ','               ; Buscar coma
   je .found_decimal
   cmp al, '.'               ; Buscar punto
   je .found_decimal
   
   inc rcx
   jmp .find_decimal
   
.found_decimal:
   ; Terminar la cadena en la posición del decimal
   mov byte [rsi + rcx], 0
   
   ; Verificar si hay al menos un dígito después del decimal
   movzx rax, byte [rsi + rcx + 1]
   test rax, rax
   jz .no_decimal       ; Si no hay dígitos, usar la parte entera
   
   ; Comprobar el redondeo
   cmp al, '5'          ; Si el primer decimal es >= 5
   jl .done             ; Si es < 5, ya terminamos (truncamos)
   
   ; Redondear hacia arriba (sumar 1 a la parte entera)
   mov rsi, monto_transaccion
   call str_to_int
   inc rax
   mov rdi, monto_transaccion
   call int_to_str
   jmp .done
   
.no_decimal:
   ; No hay decimal, dejar el valor como está
   
.done:
   pop rdi
   pop rsi
   pop rdx
   pop rcx
   pop rbx
   pop rax
   ret