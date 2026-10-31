# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")
needle = '// =====================================================================\n{\n  const s = newSlide();\n  header(s, "Activos", "Qué expone cada máquina"'
a = s.index(needle)
b = s.index("const EXPLORE = {", a)
s = s[:a] + s[b:]
p.write_text(s, encoding="utf-8")
print("OK removed duplicate")
