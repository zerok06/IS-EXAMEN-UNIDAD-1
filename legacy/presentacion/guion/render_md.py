# -*- coding: utf-8 -*-
"""Genera guion.md a partir de guion.json, con duración real."""
import json
from pathlib import Path

p = Path(__file__).parent
slides = json.loads((p / "guion.json").read_text(encoding="utf-8"))

lines = [
    "# Guion de exposición · PHP2Shell (IS-1023)",
    "",
    "**Tono:** profesional, claro y directo. **Narración:** audio neural en español, 15–16 minutos (31 diapositivas).",
    "",
    "> Regla: la narración no lee comandos símbolo por símbolo; explica qué hace cada paso. Los comandos quedan visibles en la diapositiva y se ejecutan en la réplica.",
    "",
    "## Mapa rápido",
    "",
    "| # | Diapositiva | Expone |",
    "|---|---|---|",
]
for s in slides:
    lines.append(f"| {s['n']:02d} | {s['title']} | {s['owner']} |")
lines += ["", "---", ""]

for s in slides:
    lines.append(f"## {s['n']:02d} · {s['title']}")
    lines.append("")
    lines.append(f"**Expone:** {s['owner']}  ")
    lines.append(f"**Voz:** {s['speaker']}  ")
    lines.append(f"**Duración:** {s.get('duration', 0):.1f} s  ")
    lines.append(f"**Idea clave:** {s['caption']}")
    lines.append("")
    lines.append(f"**Narración:** {s['text']}")
    lines.append("")
    lines.append(f"**Apoyo visual:** {s['support']}")
    lines.append("")
    if s.get("transition"):
        lines.append(f"**Transición:** {s['transition']}")
        lines.append("")
    lines.append("---")
    lines.append("")

lines += [
    "## Anexo · Réplica en vivo desde Kali",
    "",
    "1. **Version gate.** `php -v`, `httpd -V` y `wp core version` en M1; confirmar 8.4.26 y 2.4.49. Mostrar que 8.4.27 es el fix.",
    "2. **Precondiciones.** `php -i | grep -E 'Thread Safety|memory_limit|display_errors|session.upload_progress'` y `nm libphp.so | grep -E 'zif_system|zval_ptr_dtor'`.",
    "3. **Servicio.** Confirmar `session2.php` en `http://10.10.10.11:8080` y el worker prefork.",
    "4. **Chain A.** Ejecutar los cinco pasos de la diapositiva 21; la salida esperada es `uid=33(www-data)` y el marcador `PWNED-M1-www-data`.",
    "5. **Root.** `curl` al FTP de M3, leer `credenciales.txt`, `ssh ubuntu@10.10.10.11`, `sudo id`; la salida esperada es `uid=0(root)` y `PWNED-M1-root.txt`.",
    "6. **Evidencia.** Mostrar `EV-W2-07`, `EV-W2-09` y `sha256sum` de los logs.",
    "7. **Retest.** Repetir los mismos comandos: PHP 8.4.27, LFI 404, Redis `NOAUTH`, FTP `530`; M5 se declara pendiente.",
    "",
]
(p / "guion.md").write_text("\n".join(lines), encoding="utf-8")
print("OK")
