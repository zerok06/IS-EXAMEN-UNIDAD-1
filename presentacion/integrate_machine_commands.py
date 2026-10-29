# -*- coding: utf-8 -*-
"""Integra dos comandos de exploración en cada slide de máquina."""
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")

a = s.index("function machineSlide(cfg) {")
b = s.index("// =====================================================================\n// M1", a)

nuevo = r'''const EXPLORE = {
  M1: [
    { cmd: "nmap -sV -p 80 10.10.10.11",
      out: "80/tcp open http Apache 2.4.49 (Unix) PHP/8.4.26",
      why: "Confirma la puerta web y la versión exacta de PHP." },
    { cmd: "curl -s -o /dev/null -w \"%{http_code}\" http://10.10.10.11:8080/session2.php",
      out: "200",
      why: "Comprueba que el target de sesión responde antes de atacar." },
  ],
  M2: [
    { cmd: "redis-cli -h 10.10.10.12 PING",
      out: "PONG",
      why: "Redis responde sin autenticación." },
    { cmd: "redis-cli -h 10.10.10.12 INFO server | grep redis_version",
      out: "redis_version:6.2.6",
      why: "Confirma la versión del servicio y el vector de acceso." },
  ],
  M3: [
    { cmd: "curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt",
      out: "admin M4/M5: Admin13.-",
      why: "El FTP anónimo expone credenciales en claro." },
    { cmd: "showmount -e 10.10.10.13",
      out: "/srv/storage/backups 10.10.10.0/24",
      why: "Lista el export NFS y confirma el punto de escritura." },
  ],
  M4: [
    { cmd: "nmap -p445 --script smb-security-mode 10.10.10.14",
      out: "message_signing: disabled",
      why: "SMB sin firma; superficie para el acceso." },
    { cmd: "dig axfr uni.lab @10.10.10.14 +short",
      out: "app.uni.lab. 10.10.10.11 / bkp.uni.lab. 10.10.10.13",
      why: "Transferencia de zona: mapa completo de la red." },
  ],
  M5: [
    { cmd: "nmap -sV -p5900 10.10.10.15",
      out: "5900/tcp open vnc",
      why: "VNC expuesto en la estación cliente." },
    { cmd: "nmap -p5900 --script vnc-info 10.10.10.15",
      out: "Security types: None · WARNING: no authentication",
      why: "Confirma que el escritorio no pide clave." },
  ],
  M6: [
    { cmd: "nmap -sn 10.10.10.0/24",
      out: "Nmap done: 256 IP addresses (7 hosts up)",
      why: "Descubre los hosts activos de la red." },
    { cmd: "nmap -sV -p80 10.10.10.11",
      out: "80/tcp open http Apache 2.4.49 · PHP/8.4.26",
      why: "Valida la puerta y la versión desde el auditor." },
  ],
};

function machineSlide(cfg) {
  const s = newSlide(WHITE, cfg.owner);

  header(s, "Activo · " + cfg.vm, cfg.vm + " · " + cfg.role, cfg.subtitle);

  // Función y stack
  card(s, M, 1.7, 5.35, 2.85, WHITE, BORDER, 0.16);
  txt(s, "FUNCIÓN PRINCIPAL", {
    x: M + 0.22, y: 1.85, w: 3.5, h: 0.2,
    fontSize: 7.4, bold: true, color: CYAN, charSpacing: 1,
  });
  txt(s, cfg.func, {
    x: M + 0.22, y: 2.12, w: 4.95, h: 0.75,
    fontSize: 9.2, color: INK, lineSpacing: 12,
  });
  txt(s, "STACK INSTALADO", {
    x: M + 0.22, y: 2.95, w: 3.5, h: 0.2,
    fontSize: 7.4, bold: true, color: CYAN, charSpacing: 1,
  });
  cfg.stack.forEach((line, i) => {
    txt(s, "•  " + line, {
      x: M + 0.22, y: 3.22 + i * 0.28, w: 4.95, h: 0.22,
      fontSize: 8.2, color: MUTED,
    });
  });

  // Vulnerabilidades
  card(s, 6.2, 1.7, 6.55, 2.85, WHITE, BORDER, 0.16);
  txt(s, "VULNERABILIDADES Y CVE", {
    x: 6.42, y: 1.85, w: 4.0, h: 0.2,
    fontSize: 7.4, bold: true, color: CYAN, charSpacing: 1,
  });
  cfg.vulns.forEach((v, i) => {
    const y = 2.14 + i * 0.46;
    txt(s, v[0], {
      x: 6.42, y, w: 1.15, h: 0.22,
      fontSize: 8, bold: true, color: NAVY,
    });
    txt(s, v[1], {
      x: 7.6, y, w: 3.4, h: 0.22,
      fontSize: 8, color: INK,
    });
    txt(s, v[2], {
      x: 10.85, y, w: 0.55, h: 0.22,
      fontSize: 8, bold: true, color: NAVY, align: "right",
    });
    txt(s, v[3], {
      x: 11.5, y, w: 1.1, h: 0.22,
      fontSize: 7.2, color: MUTED, align: "right",
    });
  });

  // Qué hicimos
  txt(s, "QUÉ HICIMOS:  " + cfg.did, {
    x: M, y: 4.6, w: 11.95, h: 0.26,
    fontSize: 8, bold: true, color: NAVY,
  });

  // Comandos de exploración
  card(s, M, 4.95, 12.15, 1.95, WHITE, BORDER, 0.12);
  txt(s, "EXPLORACIÓN · 2 COMANDOS", {
    x: M + 0.2, y: 5.04, w: 3.2, h: 0.2,
    fontSize: 7.2, bold: true, color: CYAN, charSpacing: 1,
  });
  EXPLORE[cfg.vm].forEach((c, i) => {
    const x = M + 0.2 + i * 6.0;
    txt(s, "$  " + c.cmd, {
      x, y: 5.28, w: 5.75, h: 0.36,
      fontSize: 6.8, fontFace: "Courier New", color: NAVY, lineSpacing: 8.5,
    });
    txt(s, "→  " + c.out, {
      x, y: 5.64, w: 5.75, h: 0.33,
      fontSize: 6.8, fontFace: "Courier New", color: "166534", lineSpacing: 8.5,
    });
    txt(s, "Qué hace: " + c.why, {
      x, y: 5.98, w: 5.75, h: 0.42,
      fontSize: 7.3, color: MUTED, lineSpacing: 9.5,
    });
  });
  txt(s, "Evidencia: " + cfg.evidence, {
    x: M + 0.2, y: 6.58, w: 11.7, h: 0.22,
    fontSize: 7.2, fontFace: "Courier New", color: MUTED,
  });

  footer(s, 0);
  s.addNotes(cfg.notes);
}

'''
s = s[:a] + nuevo + s[b:]
p.write_text(s, encoding="utf-8")
print("OK machine commands")
