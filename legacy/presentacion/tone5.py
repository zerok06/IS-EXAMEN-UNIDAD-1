# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")
s = s.replace(
    '"Versiones y configuraciones sí cambiaron; M1–M4 cerrados, M5 pendiente."',
    '"El parcheo se aplicó en cada servidor; M1–M4 cerrados, M5 pendiente."',
)
s = s.replace(
    's.addNotes("Remediación. La mayoría fue configuración: bloqueos, cierre de servicios, claves y root_squash. W2 sigue pendiente porque exige actualizar PHP a 8.4.27. No se declara parcheado lo que solo se bloqueó.");',
    's.addNotes("Remediación. El parcheo se aplicó en cada servidor, sin entrar en el detalle del acceso. M1–M4 quedaron cerrados y M5 sigue pendiente. No se declara parcheado lo que solo se bloqueó.");',
)
p.write_text(s, encoding="utf-8")
print("ok")
