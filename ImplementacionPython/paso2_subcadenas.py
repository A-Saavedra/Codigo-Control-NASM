def extraer_subcadenas(llave: str, verhoeffs: str) -> list:
    """Extrae subcadenas de la llave de dosificación usando dígitos Verhoeff"""
    subcadenas = []
    pos = 0
    for d in verhoeffs:
        largo = int(d) + 1
        sub = llave[pos:pos + largo]
        subcadenas.append(sub)
        pos += largo
    return subcadenas


# Paso 2 – Datos del ejemplo
autorizacion = "79040011859"
factura_dv2 = "15272"
nit_dv2 = "102646902692"
fecha_dv2 = "2007072868"
monto_dv2 = "13541"
verhoeffs = "42765"
llave = "A3Fs4s$)2cvD(eY667A5C4A2rsdf53kw9654E2B23s24df35F5"

# Obtener subcadenas
subcadenas = extraer_subcadenas(llave, verhoeffs)
print("Subcadenas extraídas:", subcadenas)

# Concatenar cada subcadena a su campo correspondiente
autorizacion_ext = autorizacion + subcadenas[0]
factura_ext = factura_dv2 + subcadenas[1]
nit_ext = nit_dv2 + subcadenas[2]
fecha_ext = fecha_dv2 + subcadenas[3]
monto_ext = monto_dv2 + subcadenas[4]

# Mostrar resultados
print("\nCampos extendidos:")
print("Autorización + sub1:", autorizacion_ext)
print("Factura + sub2:     ", factura_ext)
print("NIT + sub3:         ", nit_ext)
print("Fecha + sub4:       ", fecha_ext)
print("Monto + sub5:       ", monto_ext)

# Concatenación total
cadena_concatenada = autorizacion_ext + factura_ext + nit_ext + fecha_ext + monto_ext
print("\nCadena total concatenada:")
print(cadena_concatenada)
