# -*- coding: utf-8 -*-
import json
from pathlib import Path
p = Path("guion.json")
slides = json.loads(p.read_text(encoding="utf-8"))
for s in slides:
    if s["n"] == 14:
        s["title"] = "Qué es PHP2Shell y por qué importa"
        s["caption"] = "Qué es PHP2Shell y por qué importa."
        s["text"] = "PHP2Shell es el caso de dos CVE de corrupción de memoria en PHP 8.4.26 que permiten ejecución remota antes de autenticarse. Se vuelve relevante porque afecta una versión muy extendida, el ataque es remoto y de baja complejidad, y el PoC es reproducible; además, la historia se entiende rápido: de un PHP vulnerable a root. En nuestro caso, la versión 8.4.26 estaba en rango, el servicio 8080 cumplía las condiciones y Chain A dio www-data; luego B3, SSH y sudo dieron root. Por eso el version gate, la evidencia y el retest son parte de la misma cadena."
        s["support"] = "Explicar qué es, por qué llama la atención y cómo se conecta con la cadena; no entrar aún en offsets."
        s["transition"] = "Con el caso claro, veamos la ficha técnica."
p.write_text(json.dumps(slides, ensure_ascii=False, indent=2), encoding="utf-8")
print("ok")
