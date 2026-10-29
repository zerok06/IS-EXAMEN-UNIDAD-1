# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")
s = s.replace(
    '"El retest usó los mismos comandos de validación. M1–M4 cambiaron de versión; M5 no se pudo tocar y se declara pendiente, no remediado."',
    '"El retest usó los mismos comandos de validación. M1–M4 cambiaron de versión; M5 no se pudo corregir y se declara pendiente, no remediado."',
)
s = s.replace(
    '"445/3389/5900 filtrados; sin acceso a C2/C3/C4"',
    '"445/3389/5900 filtrados; C2/C3/C4 pendientes"',
)
p.write_text(s, encoding="utf-8")
print("ok")
