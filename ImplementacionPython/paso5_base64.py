BASE64_DICT = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"

def base64_custom_encode(number: int) -> str:
    """Convierte un número entero a Base64 según el diccionario personalizado"""
    if number == 0:
        return BASE64_DICT[0]
    result = ""
    while number > 0:
        result = BASE64_DICT[number % 64] + result
        number //= 64
    return result

def paso5_operaciones(st: int, parciales: list, verhoeffs: str) -> str:
    """Realiza el paso 5: multiplicaciones, truncamiento y codificación Base64"""
    total = 0
    for i in range(5):
        vi = int(verhoeffs[i]) + 1
        parcial = (st * parciales[i]) // vi
        total += parcial
    base64_final = base64_custom_encode(total)
    return base64_final

# Valores esperados del ejemplo 1
st = 8523
parciales = [1739, 1755, 1720, 1679, 1630]
verhoeffs = "42765"

# Ejecutar paso 5
resultado_base64 = paso5_operaciones(st, parciales, verhoeffs)
print("Resultado codificado en Base64:", resultado_base64)
