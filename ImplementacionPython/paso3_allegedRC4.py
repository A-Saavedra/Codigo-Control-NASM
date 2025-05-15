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

# Entradas para el paso 3
cadena_a_cifrar = "290400110079rCB7Sv4150312X24189179011589d)5k7N2007070201%3a250031b8"
llave = "9rCB7Sv4X29d)5k7N%3ab89p-3(5[A"
verhoeffs = "71621"
clave_rc4 = llave + verhoeffs

# Aplicar RC4
resultado_rc4 = rc4(clave_rc4, cadena_a_cifrar)

# Mostrar resultado
print("Resultado RC4 (HEX):")
print(resultado_rc4)
