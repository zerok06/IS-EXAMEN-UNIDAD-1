import re

p = 'build.js'
s = open(p, encoding='utf-8').read()

owners = {
    'W2 · Ficha': 'M1 · Erick Ramos Vera',
    'W2 · Version gate': 'M1 · Erick Ramos Vera',
    'W2 · Precondiciones': 'M2 · Doris Apaza Anahua',
    'W2 · Rebuild': 'M2 · Doris Apaza Anahua',
    'W2 · Configuración': 'M3 · Rony Churata Huacani',
    'W2 · Chain A': 'M4 · Fabiola Ancco Rafael',
    'W2 · Comandos': 'M5 · Marco Nina Cruz',
    'W2 · Evidencia': 'M6 · Jose Paye Mamani',
    'W2 · Impacto': 'M6 · Jose Paye Mamani',
    'Otra vía · W3': 'M1 · Erick Ramos Vera',
    'Otra vía · B3': 'M3 · Rony Churata Huacani',
    'Cadena completa': 'M1 Erick · M3 Rony · M6 Jose',
    'Resto del laboratorio': 'M2 Doris · M3 Rony · M4 Fabiola · M5 Marco',
}

count = 0
for kicker, owner in owners.items():
    pattern = r'const s = newSlide\(\);\s*header\(s, "' + re.escape(kicker) + r'"'
    repl = 'const s = newSlide(WHITE, "' + owner + '");\n  header(s, "' + kicker + '"'
    s2, n = re.subn(pattern, repl, s, count=1)
    if n == 0:
        print('NOT FOUND', kicker)
    else:
        count += n
        s = s2

open(p, 'w', encoding='utf-8').write(s)
print('assigned', count)
