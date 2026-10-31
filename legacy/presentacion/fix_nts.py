# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")
s = s.replace('"PHP 8.4.26 (ZTS)"', '"PHP 8.4.26 (NTS)"')
p.write_text(s, encoding="utf-8")
print("ok")
