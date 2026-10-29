# -*- coding: utf-8 -*-
"""Reordena por fases: agenda, tabla de activos, fases y tabla de mitigación."""
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")

# ---------- Agenda ----------
a = s.index("// 2. AGENDA")
start = s.rindex("// =", 0, a)
b = s.index("// 3. CONTEXTO")
end = s.rindex("// =", 0, b)
agenda = r'''// =====================================================================
// 2. AGENDA POR FASES
// =====================================================================
{
  const s = newSlide();
  header(s, "Recorrido", "Cinco fases, una historia",
    "De la configuración de la red a la explotación de W2 y su mitigación.");

  const items = [
    ["01", "Fase 1 · Configuración y superficie", "Red, topología, activos, puertos y versiones de cada máquina."],
    ["02", "Fase 2 · Exploración", "Dos comandos por máquina: qué servicio corre y qué devuelve."],
    ["03", "Fase 3 · Explotación PHP2Shell", "Ficha, version gate, Chain A, www-data y root."],
    ["04", "Fase 4 · Mitigación", "Versión o configuración por máquina y comando de verificación."],
    ["05", "Fase 5 · Retest y cierre", "Antes/después, evidencia, lecciones y réplica."],
  ];

  items.forEach((it, i) => {
    const y = 1.8 + i * 0.95;
    const hot = i === 2;
    card(s, M, y, 12.1, 0.82, hot ? "E8FAFC" : WHITE, hot ? CYAN : BORDER, 0.12);
    badge(s, it[0], M + 0.2, y + 0.2, 0.42, hot ? CYAN : NAVY, WHITE, 9.5);
    txt(s, it[1], {
      x: M + 0.78, y: y + 0.1, w: 4.2, h: 0.28,
      fontSize: 12.5, bold: true, color: NAVY,
    });
    txt(s, it[2], {
      x: M + 5.0, y: y + 0.13, w: 6.8, h: 0.3,
      fontSize: 9, color: MUTED,
    });
  });

  txt(s, "Tesis: de la versión vulnerable a root, con evidencia en cada fase.", {
    x: M, y: 6.62, w: 11.0, h: 0.28,
    fontSize: 10, bold: true, italic: true, color: CYAN,
  });

  footer(s, 2);
  s.addNotes("Agenda por fases. Fase 1 configuración y superficie; Fase 2 exploración con comandos; Fase 3 explotación W2; Fase 4 mitigación por máquina; Fase 5 retest y cierre.");
}

'''
s = s[:start] + agenda + s[end:]

# ---------- Activos ----------
a = s.index("// 6. ACTIVOS Y SUPERFICIE")
start = s.rindex("// =", 0, a)
b = s.index("function machineSlide(cfg)", a)
end = s.rindex("// =", 0, b)
activos = r'''// =====================================================================
// 6. ACTIVOS Y SUPERFICIE
// =====================================================================
{
  const s = newSlide();
  header(s, "Fase 1 · Activos", "Qué tiene cada máquina",
    "IP, rol, puertos y versión clave antes de explorar.");

  txt(s, "MÁQUINA", { x: M + 0.1, y: 1.68, w: 1.1, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "IP", { x: 1.9, y: 1.68, w: 1.2, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "ROL", { x: 3.25, y: 1.68, w: 1.9, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "PUERTOS", { x: 5.3, y: 1.68, w: 2.0, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });
  txt(s, "SERVICIO / VERSIÓN", { x: 7.5, y: 1.68, w: 4.8, h: 0.2, fontSize: 7, bold: true, color: CYAN, charSpacing: 0.8 });

  const rows = [
    ["M1", "10.10.10.11", "Aplicación", "22 · 80 · 8080", "Apache 2.4.49 · PHP 8.4.26 · WP 7.0.1"],
    ["M2", "10.10.10.12", "Base de datos", "3306 · 6379", "MariaDB 10.11.19 · Redis 6.2.6"],
    ["M3", "10.10.10.13", "Respaldos", "21 · 139 · 445 · 2049", "Samba 4.5.10 · vsftpd 2.3.4 · NFS"],
    ["M4", "10.10.10.14", "Windows Server", "445 · 53", "WS2016 14393 · DNS · SMB"],
    ["M5", "10.10.10.15", "Cliente", "3389 · 5900", "Windows 10 19045 · TightVNC 2.8.90"],
    ["M6", "10.10.10.20", "Auditoría", "—", "Kali · nmap · nxc · curl"],
    ["R0", "10.10.10.1", "Router", "—", "MitraStar · DHCP off"],
  ];

  rows.forEach((r, i) => {
    const y = 1.98 + i * 0.62;
    if (i % 2 === 0) {
      s.addShape(pptx.ShapeType.rect, {
        x: M, y, w: 12.1, h: 0.56,
        fill: { color: PANEL }, line: { color: PANEL, width: 0 },
      });
    }
    txt(s, r[0], { x: M + 0.1, y: y + 0.1, w: 1.0, h: 0.25, fontSize: 9.5, bold: true, color: NAVY });
    txt(s, r[1], { x: 1.9, y: y + 0.1, w: 1.25, h: 0.25, fontSize: 8.2, fontFace: "Courier New", color: MUTED });
    txt(s, r[2], { x: 3.25, y: y + 0.1, w: 1.9, h: 0.25, fontSize: 8.4, color: INK });
    txt(s, r[3], { x: 5.3, y: y + 0.1, w: 2.0, h: 0.25, fontSize: 8.2, fontFace: "Courier New", color: MUTED });
    txt(s, r[4], { x: 7.5, y: y + 0.1, w: 4.85, h: 0.25, fontSize: 7.8, color: INK });
  });

  txt(s, "M6 no es objetivo; R0 solo transporta. Las versiones son las que activan el version gate.", {
    x: M, y: 6.55, w: 11.8, h: 0.28,
    fontSize: 8.5, italic: true, color: MUTED,
  });

  footer(s, 5);
  s.addNotes("Activos. Tabla ordenada por máquina: IP, rol, puertos y versión. M1 es la puerta; M2/M3 datos y respaldos; M4/M5 Windows; M6 auditor; R0 transporte.");
}

'''
s = s[:start] + activos + s[end:]

# ---------- Fases en kickers ----------
reps = {
    '"Contexto", "La red universitaria"': '"Fase 1 · Contexto", "La red universitaria"',
    '"Arquitectura", "Topología de la red y camino de ataque"': '"Fase 1 · Arquitectura", "Topología de la red y camino de ataque"',
    '"Activo · " + cfg.vm': '"Fase 1-2 · " + cfg.vm',
    '"W2 · El caso"': '"Fase 3 · W2 · El caso"',
    '"W2 · Ficha"': '"Fase 3 · W2 · Ficha"',
    '"W2 · Version gate"': '"Fase 3 · W2 · Version gate"',
    '"W2 · Precondiciones"': '"Fase 3 · W2 · Precondiciones"',
    '"W2 · Servicio"': '"Fase 3 · W2 · Servicio"',
    '"W2 · Configuración"': '"Fase 3 · W2 · Configuración"',
    '"W2 · Chain A"': '"Fase 3 · W2 · Chain A"',
    '"W2 · Comandos"': '"Fase 3 · W2 · Comandos"',
    '"Otra vía · W3"': '"Fase 3 · Otra vía · W3"',
    '"Otra vía · B3"': '"Fase 3 · Otra vía · B3"',
    '"W2 · Evidencia"': '"Fase 3 · Evidencia"',
    '"W2 · Impacto"': '"Fase 3 · Impacto"',
    '"Cadena completa"': '"Fase 3 · Cadena completa"',
    '"Resto de la red"': '"Fase 3 · Resto de la red"',
    '"Remediación", "Qué cambió en cada máquina"': '"Fase 4 · Remediación", "Qué cambió en cada máquina"',
    '"Retest", "Comandos de verificación"': '"Fase 5 · Retest", "Comandos de verificación"',
    '"Cierre", "Cuatro lecciones de PHP2Shell"': '"Fase 5 · Cierre", "Cuatro lecciones de PHP2Shell"',
}
for old, new in reps.items():
    s = s.replace(old, new, 1)

# ---------- Mitigación: tipo V+C / CFG ----------
s = s.replace(
    '''    ["M1", "PHP 8.4.26 · WP 7.0.1\\nApache 2.4.49",
      "PHP 8.4.27 · WP 7.0.2 · Apache 2.4.51\\nupload_progress Off · LFI fuera", "Aplicado"],
    ["M2", "Redis 6.2.6 · 6379 abierto",
      "Redis 6.2.7 · requirepass · UFW\\nclaves de BD rotadas", "Aplicado"],
    ["M3", "FTP anónimo · NFS rw",
      "FTP off · root_squash\\nSSH rotado · SMB2", "Aplicado"],
    ["M4", "SMBv1 · signing off · AXFR",
      "SMB1 off · signing on\\nSpooler off · AXFR cerrado", "Aplicado"],
    ["M5", "VNC/RDP/SMB abiertos",
      "445/3389/5900 filtrados", "Pendiente"],''',
    '''    ["M1", "PHP 8.4.26 · WP 7.0.1\\nApache 2.4.49",
      "PHP 8.4.27 · WP 7.0.2 · Apache 2.4.51\\nupload_progress Off · LFI fuera", "Aplicado", "V+C"],
    ["M2", "Redis 6.2.6 · 6379 abierto",
      "Redis 6.2.7 · requirepass · UFW\\nclaves de BD rotadas", "Aplicado", "V+C"],
    ["M3", "FTP anónimo · NFS rw",
      "FTP off · root_squash\\nSSH rotado · SMB2", "Aplicado", "CFG"],
    ["M4", "SMBv1 · signing off · AXFR",
      "SMB1 off · signing on\\nSpooler off · AXFR cerrado", "Aplicado", "CFG"],
    ["M5", "VNC/RDP/SMB abiertos",
      "445/3389/5900 filtrados", "Pendiente", "—"],''',
)
s = s.replace(
    '''    txt(s, r[0], {
      x: M + 0.1, y: y + 0.12, w: 1.3, h: 0.26,
      fontSize: 10, bold: true, color: NAVY,
    });''',
    '''    txt(s, r[0], {
      x: M + 0.1, y: y + 0.12, w: 1.3, h: 0.26,
      fontSize: 10, bold: true, color: NAVY,
    });
    txt(s, r[4], {
      x: M + 0.12, y: y + 0.43, w: 1.2, h: 0.2,
      fontSize: 6.2, bold: true, color: CYAN,
    });''',
)
s = s.replace(
    "El parcheo se aplicó en cada servidor; M1–M4 cerrados, M5 pendiente. No se declara parcheado lo que solo se bloqueó.",
    "El parcheo se aplicó en cada servidor; M1–M4 cerrados, M5 pendiente. V+C = versión + configuración; CFG = solo configuración.",
)

p.write_text(s, encoding="utf-8")
print("OK fases")
