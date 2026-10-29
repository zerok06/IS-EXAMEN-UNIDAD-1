p = 'build.js'
s = open(p, encoding='utf-8').read()
a = s.index('const OWNERS = {')
b = s.index('function footer')
s = s[:a] + 'let currentOwner = "Equipo completo · 6 integrantes";\n\n' + s[b:]
open(p, 'w', encoding='utf-8').write(s)
print('ok')
