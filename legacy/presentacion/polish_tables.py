# -*- coding: utf-8 -*-
from pathlib import Path
p = Path("build.js")
s = p.read_text(encoding="utf-8")

# Slide 14: marcar W2 como caso principal
old = '''    c[2].forEach((item, j) => {
      txt(s, "•  " + item, {
        x: x + 0.2, y: 2.55 + j * 0.55, w: 3.45, h: 0.48,
        fontSize: 8.6, color: MUTED, lineSpacing: 11,
      });
    });'''
new = '''    c[2].forEach((item, j) => {
      txt(s, "•  " + item, {
        x: x + 0.2, y: 2.55 + j * 0.55, w: 3.45, h: 0.48,
        fontSize: 8.6, color: MUTED, lineSpacing: 11,
      });
    });
    if (i === 2) {
      chip(s, "CASO PRINCIPAL", x + 0.2, 5.5, 1.55, "FEF3C7", "92400E", 7.2);
    }'''
if old not in s:
    print("NO slide14")
else:
    s = s.replace(old, new, 1)

# Slide 29: qué hace cada verificación
old2 = '''    c[2].forEach((line, j) => {
      txt(s, line, {
        x: x + 0.16, y: 2.65 + j * 0.34, w: 2.0, h: 0.3,
        fontSize: 6.9, fontFace: "Courier New",
        color: line.startsWith("→") ? "166534" : MUTED,
        lineSpacing: 8.5,
      });
    });'''
new2 = '''    c[2].forEach((line, j) => {
      txt(s, line, {
        x: x + 0.16, y: 2.65 + j * 0.34, w: 2.0, h: 0.3,
        fontSize: 6.9, fontFace: "Courier New",
        color: line.startsWith("→") ? "166534" : MUTED,
        lineSpacing: 8.5,
      });
    });
    txt(s, ["versión y LFI", "auth y puerto", "FTP y NFS", "SMB y DNS", "sigue filtrado"][i], {
      x: x + 0.16, y: 4.55, w: 2.0, h: 0.5,
      fontSize: 7, italic: true, color: MUTED, lineSpacing: 9,
    });'''
if old2 not in s:
    print("NO slide29")
else:
    s = s.replace(old2, new2, 1)

p.write_text(s, encoding="utf-8")
print("ok")
