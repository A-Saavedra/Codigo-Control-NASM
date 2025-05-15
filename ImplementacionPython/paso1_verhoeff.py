# -----------------------------------------------
# PASO 1: Implementación del Algoritmo Verhoeff
# Ejemplo 1 - Código de Control (PDF Ver.7.0)
# -----------------------------------------------

# Tablas necesarias para Verhoeff
d_table = [
    [0,1,2,3,4,5,6,7,8,9],
    [1,2,3,4,0,6,7,8,9,5],
    [2,3,4,0,1,7,8,9,5,6],
    [3,4,0,1,2,8,9,5,6,7],
    [4,0,1,2,3,9,5,6,7,8],
    [5,9,8,7,6,0,4,3,2,1],
    [6,5,9,8,7,1,0,4,3,2],
    [7,6,5,9,8,2,1,0,4,3],
    [8,7,6,5,9,3,2,1,0,4],
    [9,8,7,6,5,4,3,2,1,0]
]

p_table = [
    [0,1,2,3,4,5,6,7,8,9],
    [1,5,7,6,2,8,3,0,9,4],
    [5,8,0,3,7,9,6,1,4,2],
    [8,9,1,6,0,4,3,5,2,7],
    [9,4,5,3,1,2,6,8,7,0],
    [4,2,8,6,5,7,3,9,0,1],
    [2,7,9,3,8,0,6,4,1,5],
    [7,0,4,6,9,1,3,2,5,8]
]

inv_table = [0,4,3,2,1,5,6,7,8,9]

def verhoeff_digit(number: str) -> str:
    """Genera un dígito Verhoeff para una cadena numérica"""
    c = 0
    for i, item in enumerate(reversed(number)):
        c = d_table[c][p_table[(i + 1) % 8][int(item)]]
    return str(inv_table[c])

def append_verhoeff(number: str, n: int = 1) -> str:
    """Agrega n dígitos Verhoeff al final de una cadena numérica"""
    for _ in range(n):
        number += verhoeff_digit(number)
    return number

# Datos de entrada del ejemplo
factura = "152"
nit = "1026469026"
fecha = "20070728"
monto = "135"  # Ya redondeado

# Agregar 2 dígitos Verhoeff
factura_dv2 = append_verhoeff(factura, 2)
nit_dv2 = append_verhoeff(nit, 2)
fecha_dv2 = append_verhoeff(fecha, 2)
monto_dv2 = append_verhoeff(monto, 2)

# Mostrar resultados parciales
print("Factura + 2DV:", factura_dv2)
print("NIT + 2DV:    ", nit_dv2)
print("Fecha + 2DV:  ", fecha_dv2)
print("Monto + 2DV:  ", monto_dv2)

# Concatenar y sumar dígitos
# cadena_concat = factura_dv2 + nit_dv2 + fecha_dv2 + monto_dv2
# suma_total = sum(int(c) for c in cadena_concat)  # ❌ suma de caracteres individuales
# suma_total = int(cadena_concat)  # ✅ interpretar toda la cadena como número
suma_total = int(factura_dv2) + int(nit_dv2) + int(fecha_dv2) + int(monto_dv2)  # ✅ correcto


# print("\nCadena concatenada:", cadena_concat)
print("Suma total:        ", suma_total)

# Agregar 5 dígitos Verhoeff a la suma total
suma_str = str(suma_total)
suma_con_5dv = append_verhoeff(suma_str, 5)
ultimos_5_dv = suma_con_5dv[-5:]

print("\n5 dígitos Verhoeff adicionales:", ultimos_5_dv)
