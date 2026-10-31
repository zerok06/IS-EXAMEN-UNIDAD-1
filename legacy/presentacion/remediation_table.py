# -*- coding: utf-8 -*-
"""Reemplaza remediación y retest por tablas de versiones/configuración y comandos."""
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")
a = s.index("// 18. REMEDIACIÓN")
start = s.rindex("// =", 0, a)
b = s.index("// 20. LECCIONES", a)
end = s.rindex("// =", 0, b)

nuevo = r'''// =====================================================================
// 18. REMEDIACIÓN POR MAQUINA
// =====================================================================
{
  const s = newSlide();
  header(s, "Remediación", "Qué cambió en cada máquina",
    "Versión y configuración aplicadas; M5 queda pendiente.");

  txt(s, "MÁQUINA", { x: M + 0.1, y: 1.72, w: 1.3, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "ANTES", { x: 2.25, y: 1.72, w: 2.8, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "DESPUÉS / CONFIGURACIÓN", { x: 6.0, y: 1.72, w: 5.4, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "ESTADO", { x: 11.55, y: 1.72, w: 1.0, h: 0.22, fontSize: 7.2, bold: true, color: CYAN, charSpacing: 0.8 });

  const rows = [
    ["M1", "PHP 8.4.26 · WP 7.0.1\nApache 2.4.49",
      "PHP 8.4.27 · WP 7.0.2 · Apache 2.4.51\nupload_progress Off · LFI fuera", "Aplicado"],
    ["M2", "Redis 6.2.6 · 6379 abierto",
      "Redis 6.2.7 · requirepass · UFW\nclaves de BD rotadas", "Aplicado"],
    ["M3", "FTP anónimo · NFS rw",
      "FTP off · root_squash\nSSH rotado · SMB2", "Aplicado"],
    ["M4", "SMBv1 · signing off · AXFR",
      "SMB1 off · signing on\nSpooler off · AXFR cerrado", "Aplicado"],
    ["M5", "VNC/RDP/SMB abiertos",
      "445/3389/5900 filtrados", "Pendiente"],
  ];

  rows.forEach((r, i) => {
    const y = 2.02 + i * 0.82;
    if (i % 2 === 0) {
      s.addShape(pptx.ShapeType.rect, {
        x: M, y, w: 12.1, h: 0.74,
        fill: { color: PANEL }, line: { color: PANEL, width: 0 },
      });
    }
    txt(s, r[0], {
      x: M + 0.1, y: y + 0.12, w: 1.3, h: 0.26,
      fontSize: 10, bold: true, color: NAVY,
    });
    txt(s, r[1], {
      x: 2.25, y: y + 0.08, w: 3.4, h: 0.55,
      fontSize: 7.4, color: INK, lineSpacing: 9.5,
    });
    txt(s, r[2], {
      x: 6.0, y: y + 0.08, w: 5.3, h: 0.58,
      fontSize: 7.4, color: INK, lineSpacing: 9.5,
    });
    chip(s, r[3], 11.3, y + 0.16, 1.3,
      r[3] === "Pendiente" ? "FEF3C7" : "DCFCE7",
      r[3] === "Pendiente" ? "92400E" : "166534", 7.2);
  });

  card(s, M, 6.35, 12.1, 0.55, ICE, ICE, 0.08);
  txt(s, "El parcheo se aplicó en cada servidor; M1–M4 cerrados, M5 pendiente. No se declara parcheado lo que solo se bloqueó.", {
    x: M + 0.22, y: 6.35, w: 11.7, h: 0.55,
    fontSize: 8.8, bold: true, color: NAVY, valign: "middle",
  });

  footer(s, 18);
  s.addNotes("Remediación. Recorrer la tabla por máquina: versión antes, versión/configuración después y estado. M1–M4 cerrados; M5 filtrado y pendiente.");
}

// =====================================================================
// 19. RETEST CON COMANDOS
// =====================================================================
{
  const s = newSlide();
  header(s, "Retest", "Comandos de verificación",
    "Los mismos comandos, ahora sobre el servicio corregido.");

  const cols = [
    ["M1", "OK", ["php -v", "→ 8.4.27", "curl /lfi.php", "→ 404", "WP 7.0.2"], CYAN],
    ["M2", "OK", ["redis-cli PING", "→ NOAUTH", "nmap -p6379", "→ filtered"], NAVY3],
    ["M3", "OK", ["curl ftp://…", "→ 530", "showmount -e", "→ root_squash"], NAVY3],
    ["M4", "OK", ["nxc smb", "→ signing:True", "dig axfr", "→ failed"], NAVY3],
    ["M5", "PENDIENTE", ["nmap -p445,3389,5900", "→ filtered", "sin cambios"], AMBER],
  ];

  cols.forEach((c, i) => {
    const x = 0.5 + i * 2.5;
    card(s, x, 1.75, 2.3, 3.45, WHITE, BORDER, 0.14);
    txt(s, c[0], {
      x: x + 0.16, y: 1.9, w: 1.0, h: 0.3,
      fontSize: 16, bold: true, color: c[4],
    });
    txt(s, c[1], {
      x: x + 0.16, y: 2.28, w: 2.0, h: 0.22,
      fontSize: 8.4, bold: true, color: c[1] === "PENDIENTE" ? AMBER : GREEN,
    });
    c[2].forEach((line, j) => {
      txt(s, line, {
        x: x + 0.16, y: 2.65 + j * 0.34, w: 2.0, h: 0.3,
        fontSize: 6.9, fontFace: "Courier New",
        color: line.startsWith("→") ? "166534" : MUTED,
        lineSpacing: 8.5,
      });
    });
  });

  card(s, M, 5.45, 12.1, 0.6, PANEL, BORDER, 0.12);
  txt(s, "M1–M4 verificados con los mismos comandos; M5 sigue filtrado y se declara pendiente, no remediado.", {
    x: M + 0.22, y: 5.45, w: 11.7, h: 0.6,
    fontSize: 9, bold: true, color: INK, valign: "middle",
  });

  txt(s, "El retest no se basa en la versión: repite el comando y compara la salida.", {
    x: M, y: 6.35, w: 12.0, h: 0.3,
    fontSize: 8.8, italic: true, color: MUTED,
  });

  footer(s, 19);
  s.addNotes("Retest con comandos. M1: php 8.4.27 y lfi 404. M2: NOAUTH y puerto filtrado. M3: FTP 530 y root_squash. M4: signing True y AXFR falla. M5: puertos filtrados, pendiente.");
}

'''
s = s[:start] + nuevo + s[end:]
p.write_text(s, encoding="utf-8")
print("OK remediation/retest")
