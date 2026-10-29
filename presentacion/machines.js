function machineSlide(cfg) {
  const s = newSlide(WHITE, cfg.owner);

  header(s, "Activo · " + cfg.vm, cfg.vm + " · " + cfg.role, cfg.subtitle);

  // Función y stack
  card(s, M, 1.7, 5.35, 3.55, WHITE, BORDER, 0.16);
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
  card(s, 6.2, 1.7, 6.55, 3.55, WHITE, BORDER, 0.16);
  txt(s, "VULNERABILIDADES Y CVE", {
    x: 6.42, y: 1.85, w: 4.0, h: 0.2,
    fontSize: 7.4, bold: true, color: CYAN, charSpacing: 1,
  });
  cfg.vulns.forEach((v, i) => {
    const y = 2.14 + i * 0.52;
    txt(s, v[0], {
      x: 6.42, y, w: 1.15, h: 0.22,
      fontSize: 8, bold: true, color: NAVY,
    });
    txt(s, v[1], {
      x: 7.6, y, w: 3.4, h: 0.22,
      fontSize: 8, color: INK,
    });
    txt(s, v[2], {
      x: 11.05, y, w: 0.55, h: 0.22,
      fontSize: 8, bold: true, color: v[3] || MUTED, align: "right",
    });
    txt(s, v[4], {
      x: 11.65, y, w: 0.95, h: 0.22,
      fontSize: 7.4, color: MUTED, align: "right",
    });
  });

  // Qué hicimos
  card(s, M, 5.5, 12.15, 0.78, NAVY, NAVY, 0.16);
  txt(s, "QUÉ HICIMOS:  " + cfg.did, {
    x: M + 0.22, y: 5.5, w: 11.7, h: 0.78,
    fontSize: 8.8, bold: true, color: WHITE, valign: "middle",
  });
  txt(s, "Evidencia: " + cfg.evidence, {
    x: M + 0.22, y: 6.42, w: 11.7, h: 0.26,
    fontSize: 8, fontFace: "Courier New", color: MUTED,
  });

  footer(s, 0);
  s.addNotes(cfg.notes);
}

// =====================================================================
// M1
// =====================================================================
machineSlide({
  vm: "M1", role: "Aplicación", owner: "M1 · Erick Ramos Vera",
  subtitle: "La puerta web de la universidad y el punto de pivote.",
  func: "Servidor de aplicación: publica WordPress y Moodle, concentra la base de datos y es la única entrada web (80/443). Desde aquí se pivota al resto.",
  stack: ["Ubuntu 22.04", "Apache 2.4.49", "PHP 8.4.26 (ZTS)", "WordPress 7.0.1 · Moodle 5.0.11", "OpenSSH · usuario ubuntu"],
  vulns: [
    ["W1", "CVE-2026-63030 · WordPress", "9.8", "9.8", "ruta/login"],
    ["W2", "CVE-2026-109618/109619 · PHP", "9.8", "9.8", "RCE Chain A"],
    ["W3", "CVE-2021-41773 · Apache", "9.8", "9.8", "RCE"],
    ["W4-W7", "Claves y rutas expuestas", "8.8", "8.8", "config"],
    ["M1-SSH", "Clave reutilizada + sudo", "8.8", "8.8", "root"],
  ],
  did: "W2 Chain A dio www-data; W3 dio RCE; W4 login admin; SSH + sudo dio root.",
  evidence: "EV-W2-07/08/09 · EV-005-M1-03 · EV-ROOT-CHAIN",
  notes: "M1 es la puerta. Aquí se concentran W1-W7, W2 Chain A, W3, W4 y SSH. Erick expone esta máquina y la ficha de PHP2Shell.",
});

// =====================================================================
// M2
// =====================================================================
machineSlide({
  vm: "M2", role: "Base de datos", owner: "M2 · Doris Apaza Anahua",
  subtitle: "Datos de WordPress y Moodle; Redis para sesiones.",
  func: "Servidor de base de datos: MariaDB guarda wordpress y moodle_db; Redis se usa para sesiones y caché. Es el objetivo del pivote desde M1.",
  stack: ["Ubuntu 22.04", "MariaDB 10.11.19", "Redis 6.2.6", "SNMP public/private", "3306/6379 en la LAN"],
  vulns: [
    ["D1", "CVE-2022-0543 · Redis", "10.0", "10.0", "no repr."],
    ["D2", "Claves de BD débiles", "8.1", "8.1", "datos"],
    ["D3", "6379/3306 expuestos", "7.5", "7.5", "config"],
    ["D4", "SNMP public/private", "7.5", "7.5", "config"],
  ],
  did: "Redis respondió PONG sin auth; por túnel SSH se leyó wordpress (12 tablas) y moodle_db (487).",
  evidence: "F04-001 · F04-003 · EV-007-RETEST",
  notes: "M2. Doris expone base de datos y Redis: acceso sin auth, volcado por túnel y remediación a 6.2.7.",
});

// =====================================================================
// M3
// =====================================================================
machineSlide({
  vm: "M3", role: "Respaldos", owner: "M3 · Rony Churata Huacani",
  subtitle: "El backup que guarda la llave de M1 y M4/M5.",
  func: "Servidor de respaldos: FTP, NFS y Samba. Guarda copias de las bases y archivos; es el eslabón que entrega credenciales reutilizadas.",
  stack: ["Ubuntu 22.04", "Samba 4.5.10", "vsftpd 2.3.4", "NFS · /srv/storage/backups", "OpenSSH · rony123"],
  vulns: [
    ["B1", "CVE-2017-7494 · Samba", "9.8", "9.8", "4.5.10 = fix"],
    ["B2", "CVE-2011-2523 · vsftpd", "9.8", "9.8", "sin backdoor"],
    ["B3", "FTP anónimo + credenciales", "8.6", "8.6", "expl."],
    ["B4", "NFS no_root_squash", "8.1", "8.1", "expl."],
    ["B5", "SSH clave débil", "8.8", "8.8", "expl."],
  ],
  did: "FTP anónimo entregó Admin13.-; NFS permitió escribir como root; esa clave abrió M1.",
  evidence: "F04-002 · F04-006 · EV-ROOT-CHAIN",
  notes: "M3. Rony expone los respaldos: FTP anónimo, NFS sin root_squash y la clave que termina en root.",
});

// =====================================================================
// M4
// =====================================================================
machineSlide({
  vm: "M4", role: "Windows Server", owner: "M4 · Fabiola Ancco Rafael",
  subtitle: "Identidad heredada, DNS y SMB sin firmar.",
  func: "Windows Server 2016 heredado: DNS de uni.lab, SMBv1, Spooler y comparticiones. Es el salto a Windows y la identidad administrativa.",
  stack: ["WS2016 build 14393", "DNS standalone", "SMBv1 · signing off", "Spooler activo", "Administrador / soporte"],
  vulns: [
    ["S1", "CVE-2017-0144 · EternalBlue", "8.8", "8.8", "no expl."],
    ["S2", "CVE-2021-34527 · PrintNightmare", "8.8", "8.8", "check"],
    ["S3", "Admin con clave débil", "8.8", "8.8", "expl."],
    ["S4", "AXFR abierto", "5.3", "5.3", "expl."],
    ["S5", "SMB signing off", "7.5", "7.5", "expl."],
  ],
  did: "S3 dio Pwn3d! y shares; AXFR entregó la zona; S5 confirmó signing off; SYSTEM por tarea programada.",
  evidence: "F04-012/013/015/016/017 · EV-007-RETEST",
  notes: "M4. Fabiola expone el Windows heredado: S3, AXFR, signing y el nivel SYSTEM con credenciales admin.",
});

// =====================================================================
// M5
// =====================================================================
machineSlide({
  vm: "M5", role: "Cliente", owner: "M5 · Marco Nina Cruz",
  subtitle: "La estación del usuario y el control gráfico.",
  func: "Estación cliente Windows 10: navegador, SMB, RDP y TightVNC. Es el destino final de la cadena y el impacto sobre el usuario.",
  stack: ["Windows 10 21H2 · 19045", "SMBv1", "RDP sin NLA", "TightVNC 2.8.90", "cliente / Admin13.-"],
  vulns: [
    ["C1", "CVE-2017-0144 · EternalBlue", "8.8", "8.8", "no aplica"],
    ["C2", "Clave reutilizada", "8.8", "8.8", "expl."],
    ["C3", "RDP sin NLA", "var.", "var.", "config"],
    ["C4", "VNC sin autenticación", "9.8", "9.8", "expl."],
  ],
  did: "VNC sin clave abrió el escritorio; whoami confirmó desktop-dt5f05n\\cliente; se dejó el marcador PWNED-M5.",
  evidence: "F04-008/011 · F05-001 · EV-007-RETEST",
  notes: "M5. Marco expone la estación cliente: VNC sin autenticación, whoami y marcador; M5 queda pendiente de remediación por filtrado.",
});

// =====================================================================
// M6
// =====================================================================
machineSlide({
  vm: "M6", role: "Auditoría", owner: "M6 · Jose Paye Mamani",
  subtitle: "Kali: el punto de partida y la evidencia.",
  func: "Estación de auditoría: no es objetivo. Ejecuta reconocimiento, escaneo, explotación, transferencia de artefactos y captura de evidencia.",
  stack: ["Kali Linux", "nmap · whatweb · wpscan", "nxc · redis-cli · smbclient", "curl · ssh · vncviewer", "FTP de artefactos :2121"],
  vulns: [
    ["—", "No es objetivo del ataque", "—", "—", "auditor"],
  ],
  did: "Se ejecutaron escaneos, PoCs, túneles y capturas; M6 aloja el FTP de artefactos y los logs con SHA256.",
  evidence: "LOG-000-04…08 · EV-000-10/11 · galería de evidencias",
  notes: "M6. Jose expone la estación de auditoría: herramientas, FTP de artefactos y generación de evidencia.",
});

// =====================================================================
// REPARTO PHP2SHELL
// =====================================================================
{
  const s = newSlide();
  header(s, "Reparto", "PHP2Shell en seis partes",
    "Cada integrante expone su máquina y una parte del caso W2.");

  const parts = [
    ["Erick", "M1", "Ficha, CVSS, EPSS y version gate", CYAN],
    ["Doris", "M2", "Precondiciones: NTS, prefork y php.ini", NAVY3],
    ["Rony", "M3", "Offsets reales y staging 8080", NAVY3],
    ["Fabiola", "M4", "Chain A: session injection", NAVY3],
    ["Marco", "M5", "LFI, ejecución y evidencia", NAVY3],
    ["Jose", "M6", "Root por B3/SSH/sudo y retest", NAVY3],
  ];

  parts.forEach((p, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const x = M + col * 6.15;
    const y = 1.75 + row * 1.45;
    card(s, x, y, 5.9, 1.2, WHITE, BORDER, 0.16);
    badge(s, String(i + 1), x + 0.2, y + 0.32, 0.45, p[3], WHITE, 11);
    txt(s, p[0] + " · " + p[1], {
      x: x + 0.8, y: y + 0.18, w: 4.8, h: 0.24,
      fontSize: 12, bold: true, color: NAVY,
    });
    txt(s, p[2], {
      x: x + 0.8, y: y + 0.55, w: 4.8, h: 0.5,
      fontSize: 9, color: MUTED, lineSpacing: 11,
    });
  });

  txt(s, "La exposición sigue el orden de la cadena: versión → precondiciones → offsets → sesión → LFI → root y retest.", {
    x: M, y: 6.4, w: 12.0, h: 0.3,
    fontSize: 9, italic: true, color: MUTED,
  });

  footer(s, 0);
  s.addNotes("Reparto. Cada uno tiene una parte de PHP2Shell y su máquina. Erick ficha, Doris precondiciones, Rony offsets, Fabiola session injection, Marco LFI/ejecución, Jose root y retest.");
}
