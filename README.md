# Algoritmo de Código de Control en Ensamblador

## Descripción General

Este programa implementa el algoritmo para la generación de Códigos de Control de facturas según las especificaciones de la normativa tributaria boliviana. El código está escrito en lenguaje ensamblador x86-64 y sigue meticulosamente los pasos definidos en la especificación oficial del Servicio de Impuestos Nacionales (SIN) de Bolivia.

## Datos de Entrada

El programa utiliza los siguientes datos como entrada:

- **Número de Autorización**: "29040011007"
- **Número de Factura**: "1503"
- **NIT/CI del Cliente**: "4189179011"
- **Fecha de Transacción**: "20070702" (formato AAAAMMDD)
- **Monto de la Transacción**: "2500"
- **Llave de Dosificación**: "9rCB7Sv4X29d)5k7N%3ab89p-3(5[A"

## Estructura del Algoritmo y Flujo de Ejecución

El algoritmo se implementa en 6 pasos secuenciales, donde cada paso utiliza estructuras de datos y registros específicos:

### Paso 1: Añadir Dígitos Verhoeff

1. Aplica el algoritmo de Verhoeff para añadir 2 dígitos de verificación a cada uno de los siguientes datos:
   - Número de factura
   - NIT/CI cliente
   - Fecha de transacción
   - Monto de la transacción
2. Calcula la suma de estos cuatro valores verificados
3. Obtiene 5 dígitos Verhoeff para esta suma

**Implementación y registros:**
- La función `add_verhoeff_digits` se llama 4 veces para añadir 2 dígitos a cada campo
- RSI contiene el puntero a la cadena a procesar
- RDI apunta al buffer de destino (ej: factura_ver, nit_ver)
- RCX contiene el número de dígitos a añadir (2)
- Después, los valores se convierten a enteros con `str_to_int` que devuelve el valor en RAX
- La suma total se acumula en RBX
- Finalmente, la suma se convierte a cadena con `int_to_str` y se calculan 5 dígitos Verhoeff adicionales

El algoritmo de Verhoeff utiliza las tablas `d`, `p` e `inv` definidas al inicio del código. La función `verhoeff_check_digit` realiza cálculos matriciales con estas tablas para generar dígitos de verificación resistentes a errores comunes de transcripción.

### Paso 2: Concatenar con Subsegmentos de la Llave

1. Para cada uno de los 5 dígitos Verhoeff obtenidos en el paso anterior:
   - Extrae un subsegmento de la llave de dosificación, cuya longitud es igual al dígito Verhoeff + 1
   - Concatena cada valor original con su subsegmento correspondiente

**Detalles de implementación:**
- Los dígitos Verhoeff se almacenan en registros R8-R12 (uno por registro)
- R8 se utiliza también como índice para rastrear la posición actual en la llave de dosificación
- Para cada dígito:
  1. Se convierte de ASCII a valor numérico (substracción de '0')
  2. Se incrementa en 1 para obtener la longitud del subsegmento
  3. Se llama a `extract_substring` con:
     - RDI: Buffer temporal (substring)
     - RSI: Llave de dosificación + posición actual
     - RCX: Longitud a extraer (dígito + 1)
  4. Se concatena usando `strcpy` en dos pasos:
     - Primero se copia el valor original al buffer
     - Luego se añade el subsegmento al final del buffer

Los subsegmentos se extraen secuencialmente de la llave, posicionándose desde donde terminó el subsegmento anterior, manteniendo el registro R8 actualizado después de cada extracción.

### Paso 3: Cifrado con AllegedRC4

1. Concatena todas las cadenas resultantes del paso 2
2. Prepara la llave de cifrado combinando la llave de dosificación con los 5 dígitos Verhoeff
3. Aplica el algoritmo AllegedRC4 para cifrar la cadena concatenada
4. Convierte el resultado a formato hexadecimal

**Detalles técnicos:**
- La concatenación se realiza manualmente mediante varios bucles, usando:
  - RDI como puntero al buffer de destino `all_concat`
  - RSI como puntero a cada subcadena fuente
  - Instrucciones LODSB y STOSB para transferir bytes
  - La instrucción TEST AL, AL para detectar fin de cadena (byte nulo)

- La llave de cifrado se crea con:
  - Copia de la llave de dosificación a buffer `rc4_key`
  - Concatenación de los 5 dígitos Verhoeff al final

- La función `alleged_rc4` recibe:
  - RSI: Puntero a `all_concat` (cadena a cifrar)
  - RDI: Puntero a `rc4_key` (llave de cifrado)
  - RBX: Puntero a `rc4_result` (buffer de resultado)
  - El resultado se almacena en la dirección apuntada por RBX
  - La longitud de los datos procesados se guarda en RDX

- La conversión a hexadecimal llama a `to_hex` con:
  - RSI: Resultado del cifrado (`rc4_result`)
  - RDI: Buffer de salida (`hex_output`)
  - RCX: Longitud de los datos a convertir

El algoritmo AllegedRC4 implementa una versión modificada del cifrado de flujo RC4 que incluye:
- Inicialización del estado (S-box) en el array de 256 bytes `rc4_state`
- Key Scheduling Algorithm (KSA) que mezcla el estado usando la llave
- Pseudo-Random Generation Algorithm (PRGA) que genera bytes pseudoaleatorios
- XOR de los bytes de entrada con la secuencia pseudoaleatoria generada

### Paso 4: Cálculo de Sumatorias de Valores ASCII

1. Calcula la sumatoria total (ST) de los valores ASCII de los caracteres hexadecimales del resultado anterior
2. Calcula 5 sumatorias parciales (SP1-SP5), agrupando caracteres por posición módulo 5:
   - SP1: suma de caracteres en posiciones 0, 5, 10, 15, ...
   - SP2: suma de caracteres en posiciones 1, 6, 11, 16, ...
   - SP3: suma de caracteres en posiciones 2, 7, 12, 17, ...
   - SP4: suma de caracteres en posiciones 3, 8, 13, 18, ...
   - SP5: suma de caracteres en posiciones 4, 9, 14, 19, ...

**Implementación de sumatorias:**
- Las sumatorias se almacenan en variables globales:
  - `suma_total`: Acumula todos los valores ASCII
  - `suma_parcial1` a `suma_parcial5`: Para las sumatorias específicas

- El proceso utiliza:
  - RSI: Puntero a la cadena hexadecimal (`hex_output`)
  - RCX: Contador de longitud total
  - RBX: Índice de posición actual
  - RAX: Valor temporal para cálculos
  - R8: Constante 5 para cálculo de módulo

- Para cada carácter hexadecimal:
  1. Se carga el valor ASCII con: `movzx rax, byte [hex_output + rbx]`
  2. Se añade a la sumatoria total: `add [suma_total], rax`
  3. Se calcula el módulo 5 con división: `div r8` (resultado en RDX)
  4. Según el módulo (0-4), se añade a la sumatoria parcial correspondiente
  5. Se incrementa el índice RBX y continúa hasta procesar todos los caracteres

El uso de la instrucción `movzx` (move with zero-extend) asegura que solo se considere el byte sin extensión de signo, importante para mantener valores ASCII correctos.

### Paso 5: Cálculos Finales y Codificación Base64

1. Para cada uno de los 5 dígitos Verhoeff (DV1-DV5), calcula:
   - ST * SP1 / (DV1+1)
   - ST * SP2 / (DV2+1)
   - ST * SP3 / (DV3+1)
   - ST * SP4 / (DV4+1)
   - ST * SP5 / (DV5+1)
2. Suma los resultados de estas operaciones
3. Codifica esta suma final en Base64 utilizando el diccionario definido

**Detalles de implementación:**
- Se utilizan registros de 64 bits para garantizar precisión en las operaciones:
  - R8-R12: Almacenan los dígitos Verhoeff + 1 (divisores)
  - RAX: Acumulador para operaciones multiplicación/división
  - Variables globales `result_mult1` a `result_mult5`: Almacenan resultados intermedios

- Para cada operación matemática:
  1. Se carga el valor de `suma_total` en RAX
  2. Se multiplica por la sumatoria parcial correspondiente con `mul qword [suma_parcialX]`
  3. Se divide por el dígito Verhoeff+1 con `div rX`
  4. El resultado (cociente) se guarda en la variable correspondiente

- La suma final se calcula mediante adiciones sucesivas en RAX y se almacena en `suma_final`

- La codificación Base64 utiliza:
  - RAX: Valor a codificar (suma_final)
  - RDI: Buffer de destino (`base64_result`)
  - Función `base64_encode` que implementa la codificación según el diccionario específico requerido

### Paso 6: Generación del Código de Control

1. Aplica nuevamente el algoritmo AllegedRC4 al resultado Base64, utilizando la misma llave que en el paso 3
2. Convierte a formato hexadecimal
3. Toma los primeros 5 bytes (10 caracteres hexadecimales)
4. Da formato final al código separando los pares de caracteres con guiones

**Implementación final:**
- Para el cifrado RC4 final:
  - RSI: Expresión Base64 (`base64_result`)
  - RDI: Llave de cifrado (`rc4_key`, la misma que en el paso 3)
  - RBX: Buffer para resultado cifrado (`base64_cifrado`)

- La conversión a hexadecimal utiliza:
  - RSI: Resultado cifrado
  - RCX: Longitud de datos
  - RDI: Buffer para representación hexadecimal (`codigo_control`)

- El formateo final con la función `format_codigo_control`:
  - RSI: Cadena hexadecimal sin formato
  - RDI: Buffer temporal (`temp_buffer`)
  - Recorre la cadena tomando pares de caracteres
  - Inserta guiones entre cada par
  - Limita la salida a 10 caracteres (5 bytes)
  - Usa una lógica de copia controlada por bytes para mantener la estructura de pares-guiones

## Detalle de Funciones y Manejo de Registros

El programa hace un uso extensivo de los registros de 64 bits disponibles en la arquitectura x86-64, siguiendo convenciones específicas para optimizar el rendimiento y la claridad del código.

### Principales Registros Utilizados

- **RAX**: Utilizado para valores de retorno de funciones y operaciones aritméticas
- **RBX**: Frecuentemente usado como registro auxiliar para preservar valores
- **RCX**: Empleado como contador en bucles y para pasar parámetros
- **RDX**: Usado para dividendos en divisiones y como registro temporal
- **RSI**: Puntero de origen (Source Index) para operaciones con cadenas
- **RDI**: Puntero de destino (Destination Index) para operaciones con cadenas
- **R8-R15**: Registros extendidos usados para almacenar valores temporales y dígitos Verhoeff

### Funciones Principales y su Uso de Registros

#### 1. Algoritmo de Verhoeff

- **add_verhoeff_digits**:
  - **Entrada**: 
    - RSI: Puntero a la cadena a la que se añadirán dígitos
    - RCX: Número de dígitos Verhoeff a añadir
  - **Salida**: 
    - Modifica la cadena en RSI añadiendo los dígitos calculados
  - **Registros preservados**: RBX, RCX, RSI, RDI (mediante push/pop)

- **verhoeff_check_digit**:
  - **Entrada**:
    - RSI: Puntero a la cadena de entrada
  - **Salida**:
    - AL: Dígito Verhoeff calculado (valor numérico, no ASCII)
  - **Registros usados**: RAX, RBX, RCX, RDX, RSI, RDI
  - **Lógica interna**: 
    - Invierte la cadena de entrada
    - Aplica el algoritmo de Verhoeff usando las tablas d, p e inv
    - Calcula y devuelve el dígito de verificación

#### 2. Cifrado AllegedRC4

- **alleged_rc4**:
  - **Entrada**:
    - RSI: Puntero a los datos a cifrar
    - RDI: Puntero a la llave de cifrado
    - RBX: Puntero al buffer de salida
  - **Salida**:
    - Buffer en RBX contiene los datos cifrados
    - RAX: Longitud de los datos cifrados
  - **Registros preservados**: Guarda y restaura todos los registros de R8 a R15
  - **Estados internos**:
    - R12: Almacena datos a cifrar
    - R13: Almacena llave
    - R14: Almacena buffer de salida
    - R15: Almacena longitud de datos
    - R11: Almacena longitud de llave
  - **Implementación**: 
    - Inicializa array S de 256 bytes (0-255)
    - Realiza mezcla con KSA (Key Scheduling Algorithm)
    - Ejecuta PRGA (Pseudo-Random Generation Algorithm)
    - Cifra datos mediante XOR byte a byte

#### 3. Manipulación de Cadenas

- **strcpy**:
  - **Entrada**: 
    - RSI: Puntero a cadena origen
    - RDI: Puntero a buffer destino
  - **Implementación**: Utiliza las instrucciones LODSB y STOSB para copiar byte a byte

- **strlen**:
  - **Entrada**: 
    - RSI: Puntero a la cadena
  - **Salida**:
    - RAX: Longitud de la cadena
  - **Lógica**: Incrementa contador hasta encontrar byte nulo (0)

- **extract_substring**:
  - **Entrada**:
    - RDI: Buffer destino
    - RSI: Cadena origen
    - RCX: Longitud a extraer
  - **Implementación**: Copia exactamente RCX bytes o hasta encontrar fin de cadena

#### 4. Conversión Numérica

- **str_to_int**:
  - **Entrada**:
    - RSI: Puntero a cadena numérica
  - **Salida**:
    - RAX: Valor entero convertido
  - **Algoritmo**: Multiplica el acumulador por 10 y suma cada dígito convertido de ASCII

- **int_to_str**:
  - **Entrada**:
    - RAX: Valor entero a convertir
    - RDI: Buffer destino
  - **Implementación**: 
    - Divide repetidamente por 10, almacenando residuos como caracteres
    - Invierte los dígitos resultantes

- **to_hex**:
  - **Entrada**:
    - RSI: Buffer de datos binarios
    - RDI: Buffer destino para representación hexadecimal
    - RCX: Longitud de datos a convertir
  - **Lógica**: 
    - Extrae bits altos y bajos de cada byte
    - Convierte a caracteres hexadecimales usando tabla hex_digits

#### 5. Codificación Base64

- **base64_encode**:
  - **Entrada**:
    - RAX: Valor numérico a codificar
    - RDI: Buffer destino
  - **Salida**:
    - Cadena Base64 en buffer RDI
  - **Algoritmo**:
    - Divide repetidamente por 64, obteniendo residuos
    - Usa el diccionario base64_dict para convertir valores
    - Invierte la cadena resultante

#### 6. Otras Funciones Importantes

- **reverse_string**:
  - **Entrada**:
    - RDI: Puntero a cadena a invertir
  - **Implementación**:
    - Intercambia pares de caracteres desde extremos opuestos
    - Avanza hasta encontrarse en el medio

- **format_codigo_control**:
  - **Entrada**:
    - RSI: Cadena hexadecimal de entrada
    - RDI: Buffer destino
  - **Salida**:
    - Código de control formateado con guiones
  - **Lógica**:
    - Toma pares de caracteres y los separa con guiones
    - Limita el resultado a 5 bytes (10 caracteres hexadecimales)

## Manejo de Memoria y Estructuras de Datos

El programa utiliza varios segmentos de memoria claramente definidos:

### Segmento .data
Contiene datos estáticos inicializados:
- **Tablas del algoritmo Verhoeff**: Matrices `d`, `p` e `inv` para cálculos de verificación
- **Datos de entrada**: Cadenas como `numero_autorizacion`, `numero_factura`, etc.
- **Buffers para resultados**: `factura_ver`, `nit_ver`, etc. inicializados con ceros
- **Diccionario Base64**: Secuencia específica de caracteres para codificación
- **Mensajes de salida**: Textos para mostrar resultados intermedios y finales

### Segmento .bss
Contiene variables no inicializadas:
- **Buffers temporales**: `temp_buffer`, `substring`
- **Estado RC4**: `rc4_state` (256 bytes), `rc4_temp` (1 byte)

### Manejo de Pila
El programa utiliza la pila de manera intensiva:
- Preservación de registros al entrar a funciones con push/pop
- Paso de parámetros principalmente a través de registros (convención System V AMD64)
- Uso ordenado de la pila para llamadas anidadas

## Ejemplo de Ejecución

El programa muestra en pantalla el resultado de cada paso, permitiendo verificar que el algoritmo se está ejecutando correctamente:

1. Paso 1: Muestra cada valor original con sus 2 dígitos Verhoeff añadidos
2. Paso 2: Presenta cada concatenación con su subsegmento de llave
3. Paso 3: Visualiza la cadena completa concatenada, la llave de cifrado y el resultado RC4 en hexadecimal
4. Paso 4: Muestra los valores de las sumatorias total y parciales
5. Paso 5: Presenta los resultados de las operaciones matemáticas y la codificación Base64
6. Paso 6: Muestra el código de control final en formato XX-XX-XX-XX-XX

Esta organización secuencial facilita la depuración y verificación paso a paso del algoritmo.

## Características de Seguridad y Rendimiento

### Seguridad
El código de control resultante es prácticamente imposible de revertir debido al uso de:
- Algoritmo de Verhoeff para la detección de errores (resistente a transposiciones)
- Cifrado AllegedRC4, implementación específica con manipulación de estados
- Múltiples transformaciones matemáticas no lineales
- Codificación Base64 con un alfabeto específico
- Uso de la llave de dosificación en múltiples etapas del proceso

### Rendimiento
El código está optimizado para arquitectura x86-64:
- Uso eficiente de registros de 64 bits
- Minimización de accesos a memoria utilizando registros cuando es posible
- Reutilización de buffers para operaciones intermedias
- Operaciones directas de byte a través de instrucciones LODSB/STOSB
- Preservación adecuada del estado de los registros en llamadas a funciones

Este mecanismo garantiza la autenticidad e integridad de la información contenida en las facturas emitidas según la normativa tributaria boliviana, mientras mantiene un rendimiento eficiente incluso en sistemas con recursos limitados.
