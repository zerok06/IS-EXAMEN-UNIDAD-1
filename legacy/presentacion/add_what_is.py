# -*- coding: utf-8 -*-
"""Reemplaza el inventario por una slide explicativa de PHP2Shell."""
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")

a = s.index("// 7. INVENTARIO")
start = s.rindex("// =", 0, a)
b = s.index("// 8. FICHA W2")
end = s.rindex("// =", 0, b)

nuevo = '''// =====================================================================
// 7. QUE ES PHP2SHELL
// =====================================================================
{
  const s = newSlide(WHITE, "M1 · Erick Ramos Vera");
  header(s, "W2 · El caso", "¿Qué es PHP2Shell y por qué importa?",
    "Dos CVE de PHP 8.4.26 que se convierten en una cadena de explotación real.");

  const cols = [
    ["01", "QUÉ ES", [
      "Dos CVE de corrupción de memoria en PHP 8.4.26.",
      "Ejecución remota antes de autenticarse.",
      "Chain A: session injection + LFI.",
      "Resultado: www-data.",
    ], CYAN],
    ["02", "POR QUÉ SE VOLVIÓ VIRAL", [
      "Versión muy extendida en servidores web.",
      "Ataque remoto, pre-auth y de baja complejidad.",
      "PoC reproducible y CVSS 9.8.",
      "La historia de PHP a root se comunica sola.",
    ], AMBER],
    ["03", "CÓMO SE RELACIONA", [
      "Version gate: 8.4.26 < 8.4.27.",
      "Servicio 8080 con NTS y prefork.",
      "Chain A dio www-data.",
      "B3, SSH y sudo dieron root.",
      "Parche 8.4.27 y retest.",
    ], GREEN],
  ];

  cols.forEach((c, i) => {
    const x = M + i * 4.05;
    card(s, x, 1.7, 3.85, 4.35, WHITE, BORDER, 0.1);
    badge(s, c[0], x + 0.2, 1.88, 0.42, c[3], WHITE, 10);
    txt(s, c[1], {
      x: x + 0.72, y: 1.9, w: 2.9, h: 0.45,
      fontSize: 10.5, bold: true, color: NAVY, lineSpacing: 11,
    });
    c[2].forEach((item, j) => {
      txt(s, "•  " + item, {
        x: x + 0.2, y: 2.55 + j * 0.55, w: 3.45, h: 0.48,
        fontSize: 8.6, color: MUTED, lineSpacing: 11,
      });
    });
  });

  card(s, M, 6.18, 12.1, 0.62, NAVY, NAVY, 0.12);
  txt(s, "No es solo un CVE: es una cadena. La versión abre la puerta; la configuración y las credenciales la convierten en root.", {
    x: M + 0.22, y: 6.18, w: 9.9, h: 0.62,
    fontSize: 9.2, bold: true, color: WHITE, valign: "middle",
  });
  txt(s, "24 hallazgos · 22 con evidencia", {
    x: 10.2, y: 6.18, w: 2.2, h: 0.62,
    fontSize: 7.8, bold: true, color: CYAN_L, align: "right", valign: "middle",
  });

  footer(s, 14);
  s.addNotes("Qué es PHP2Shell. Explicar los dos CVE, por qué llama la atención y cómo se conecta con la cadena: version gate, servicio 8080, Chain A, www-data, B3/SSH/sudo y retest.");
}

'''
s = s[:start] + nuevo + s[end:]
p.write_text(s, encoding="utf-8")
print("OK")
