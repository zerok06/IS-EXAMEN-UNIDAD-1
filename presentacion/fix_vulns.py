import re

p = 'build.js'
s = open(p, encoding='utf-8').read()

# Collapse 5-string vuln rows to 4 fields: drop the duplicated CVSS/status field.
s = re.sub(
    r'(\["[^"]+", "[^"]+", "[^"]+", )"[^"]+", ("[^"]+"\])',
    r'\1\2',
    s,
)

old = '''    txt(s, v[2], {
      x: 11.05, y, w: 0.55, h: 0.22,
      fontSize: 8, bold: true, color: v[3] || MUTED, align: "right",
    });
    txt(s, v[4], {
      x: 11.65, y, w: 0.95, h: 0.22,
      fontSize: 7.4, color: MUTED, align: "right",
    });'''
new = '''    txt(s, v[2], {
      x: 10.85, y, w: 0.55, h: 0.22,
      fontSize: 8, bold: true, color: NAVY, align: "right",
    });
    txt(s, v[3], {
      x: 11.5, y, w: 1.1, h: 0.22,
      fontSize: 7.2, color: MUTED, align: "right",
    });'''
if old not in s:
    print('helper block not found')
else:
    s = s.replace(old, new, 1)

open(p, 'w', encoding='utf-8').write(s)
print('patched')
