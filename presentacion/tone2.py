# -*- coding: utf-8 -*-
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")
reps = {
    '["Rony", "M3", "Offsets reales y staging 8080", NAVY3]':
    '["Rony", "M3", "Offsets reales y servicio 8080", NAVY3]',
    'notes: "M1 es la puerta. Aquí se concentran W1-W7, W2 Chain A, W3, W4 y SSH. Erick expone esta máquina y la ficha de PHP2Shell."':
    'notes: "M1 es la puerta. Aquí se concentran W2 Chain A, W3, W4 y SSH. Erick expone esta máquina y la ficha de PHP2Shell."',
    's.addNotes("Inventario. Bajar el entusiasmo del número 24: 22 demostrables y 4 que no cuentan. W1 y W2 quedan como parciales; W3 es el RCE real que sostiene la cadena.");':
    's.addNotes("Inventario. 24 hallazgos identificados; 22 se llevaron a evidencia. W2 y W3 son los RCE reales que sostienen la cadena.");',
    '["Salto", "mismo loot que W1 → M2"]':
    '["Salto", "acceso a datos de M2"]',
    '["Artefacto", "php-8.4.26.tar.gz (SHA256 verificado)"]':
    '["Binario", "libphp.so del servidor"]',
    '["PoC", "php2shell-poc-main.zip"]':
    '["Exploit", "php2shell-poc (validado)"]',
}
for a, b in reps.items():
    if a not in s:
        print("NO:", a[:80])
    s = s.replace(a, b)
p.write_text(s, encoding="utf-8")
print("ok")
