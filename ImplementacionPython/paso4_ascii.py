def calcular_sumatorias_ascii(cadena_hex: str):
    """Calcula sumatoria total y cinco sumatorias parciales de una cadena HEX"""
    total = 0
    parciales = [0, 0, 0, 0, 0]

    for i, char in enumerate(cadena_hex):
        valor = ord(char)
        total += valor
        parciales[i % 5] += valor  # porque i parte en 0 → posición i+1

    return total, parciales

# Resultado del paso 3 (simulado o real)
# resultado_rc4 = rc4(clave_rc4, cadena_a_cifrar)
resultado_rc4 = "69DD0A42536C9900C4AE6484726C122ABDBF95D80A4BA403FB7834B3EC2A88595E2149A3D965923BA4547B42B9528AAE7B8CFB9996BA2B58516913057C9D791B6B748A"

# Paso 4: calcular sumatorias
suma_total, parciales = calcular_sumatorias_ascii(resultado_rc4)

# Mostrar resultados
print("Sumatoria total (ST):", suma_total)
for i, sp in enumerate(parciales):
    print(f"Sumatoria Parcial SP{i+1}:", sp)
