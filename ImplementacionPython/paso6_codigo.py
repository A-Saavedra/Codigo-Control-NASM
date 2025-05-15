def formatear_codigo_control(hex_string: str) -> str:
    """Formatea una cadena hexadecimal en pares separados por guiones"""
    return "-".join(hex_string[i:i+2] for i in range(0, len(hex_string), 2))

resultado_base64 = "rylG"
clave_rc4 = "A3Fs4s$)2cvD(eY667A5C4A2rsdf53kw9654E2B23s24df35F542765"

def rc4(key: str, message: str) -> str:
    """Implementación del Alleged RC4 (en hexadecimal)"""
    S = list(range(256))
    j = 0
    out = []

    # KSA – Key Scheduling Algorithm
    for i in range(256):
        j = (j + S[i] + ord(key[i % len(key)])) % 256
        S[i], S[j] = S[j], S[i]

    # PRGA – Pseudo-Random Generation Algorithm
    i = j = 0
    for char in message:
        i = (i + 1) % 256
        j = (j + S[i]) % 256
        S[i], S[j] = S[j], S[i]
        K = S[(S[i] + S[j]) % 256]
        out.append("%02X" % (ord(char) ^ K))  # salida en HEX

    return ''.join(out)

# Paso 6 – cifrado final
codigo_hex = rc4(clave_rc4, resultado_base64)
codigo_control = formatear_codigo_control(codigo_hex)

# Mostrar el resultado final
print("Código de Control final:")
print(codigo_control)
