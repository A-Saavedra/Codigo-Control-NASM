
# -*- coding: utf-8 -*-
# Generador del Código de Control - Versión 7.0 (Ejemplo basado en el SIN de Bolivia)

# --- Verhoeff -----------------------------------
d_table = [[0,1,2,3,4,5,6,7,8,9],
           [1,2,3,4,0,6,7,8,9,5],
           [2,3,4,0,1,7,8,9,5,6],
           [3,4,0,1,2,8,9,5,6,7],
           [4,0,1,2,3,9,5,6,7,8],
           [5,9,8,7,6,0,4,3,2,1],
           [6,5,9,8,7,1,0,4,3,2],
           [7,6,5,9,8,2,1,0,4,3],
           [8,7,6,5,9,3,2,1,0,4],
           [9,8,7,6,5,4,3,2,1,0]]
p_table = [[0,1,2,3,4,5,6,7,8,9],
           [1,5,7,6,2,8,3,0,9,4],
           [5,8,0,3,7,9,6,1,4,2],
           [8,9,1,6,0,4,3,5,2,7],
           [9,4,5,3,1,2,6,8,7,0],
           [4,2,8,6,5,7,3,9,0,1],
           [2,7,9,3,8,0,6,4,1,5],
           [7,0,4,6,9,1,3,2,5,8]]
inv_table = [0,4,3,2,1,5,6,7,8,9]

def verhoeff_digit(number: str) -> str:
    c = 0
    for i, item in enumerate(reversed(number)):
        c = d_table[c][p_table[(i + 1) % 8][int(item)]]
    return str(inv_table[c])

def append_verhoeff(number: str, n: int = 1) -> str:
    for _ in range(n):
        number += verhoeff_digit(number)
    return number

# --- RC4 ----------------------------------------
def rc4(key: str, message: str) -> str:
    S = list(range(256))
    j = 0
    out = []

    for i in range(256):
        j = (j + S[i] + ord(key[i % len(key)])) % 256
        S[i], S[j] = S[j], S[i]

    i = j = 0
    for char in message:
        i = (i + 1) % 256
        j = (j + S[i]) % 256
        S[i], S[j] = S[j], S[i]
        K = S[(S[i] + S[j]) % 256]
        out.append("%02X" % (ord(char) ^ K))
    return ''.join(out)

# --- Base64 personalizada ------------------------
BASE64_DICT = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"

def base64_custom_encode(number: int) -> str:
    if number == 0:
        return BASE64_DICT[0]
    result = ""
    while number > 0:
        result = BASE64_DICT[number % 64] + result
        number //= 64
    return result

# --- Paso 2: Subcadenas -------------------------
def extraer_subcadenas(llave: str, verhoeffs: str) -> list:
    subcadenas = []
    pos = 0
    for d in verhoeffs:
        largo = int(d) + 1
        sub = llave[pos:pos + largo]
        subcadenas.append(sub)
        pos += largo
    return subcadenas

# --- Paso 4: Sumatorias -------------------------
def calcular_sumatorias_ascii(cadena_hex: str):
    total = 0
    parciales = [0, 0, 0, 0, 0]
    for i, char in enumerate(cadena_hex):
        valor = ord(char)
        total += valor
        parciales[i % 5] += valor
    return total, parciales

# --- Paso 5: Operaciones matemáticas -----------
def paso5_operaciones(st: int, parciales: list, verhoeffs: str) -> str:
    total = 0
    for i in range(5):
        vi = int(verhoeffs[i]) + 1
        parcial = (st * parciales[i]) // vi
        total += parcial
    return base64_custom_encode(total)

# --- Formatear Código Final ---------------------
def formatear_codigo_control(hex_string: str) -> str:
    return "-".join(hex_string[i:i+2] for i in range(0, len(hex_string), 2))

# === FLUJO PRINCIPAL ============================
def generar_codigo_control(autorizacion, factura, nit, fecha, monto, llave):
    # Paso 1
    factura_dv2 = append_verhoeff(factura, 2)
    nit_dv2 = append_verhoeff(nit, 2)
    fecha_dv2 = append_verhoeff(fecha, 2)
    monto_dv2 = append_verhoeff(monto, 2)

    suma_total = sum([int(factura_dv2), int(nit_dv2), int(fecha_dv2), int(monto_dv2)])
    verhoeffs = append_verhoeff(str(suma_total), 5)[-5:]

    # Paso 2
    subcadenas = extraer_subcadenas(llave, verhoeffs)
    cadena_total = (
        autorizacion + subcadenas[0] +
        factura_dv2 + subcadenas[1] +
        nit_dv2 + subcadenas[2] +
        fecha_dv2 + subcadenas[3] +
        monto_dv2 + subcadenas[4]
    )

    # Paso 3
    clave_rc4 = llave + verhoeffs
    rc4_resultado = rc4(clave_rc4, cadena_total)

    # Paso 4
    st, parciales = calcular_sumatorias_ascii(rc4_resultado)

    # Paso 5
    base64_intermedio = paso5_operaciones(st, parciales, verhoeffs)

    # Paso 6
    rc4_final = rc4(clave_rc4, base64_intermedio)
    codigo_control = formatear_codigo_control(rc4_final)

    return codigo_control

# === EJEMPLO DE USO =============================
if __name__ == "__main__":
    autorizacion = "79040011859"
    factura = "152"
    nit = "1026469026"
    fecha = "20070728"
    monto = "135"
    llave = "A3Fs4s$)2cvD(eY667A5C4A2rsdf53kw9654E2B23s24df35F5"

    codigo = generar_codigo_control(autorizacion, factura, nit, fecha, monto, llave)
    print("Código de Control generado:", codigo)
