# -*- coding: utf-8 -*-
"""Añade un anexo de réplica: 2 comandos por integrante y verificación de mitigaciones."""
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")
marker = "// ---------- Guardar ----------"
if marker not in s:
    raise SystemExit("No se encontró el marcador de guardado")
if "function commandSlide" in s:
    raise SystemExit("El anexo ya existe")

appendix = r'''
// =====================================================================
// ANEXO · COMANDOS DE RÉPLICA
// =====================================================================
function commandSlide(cfg) {
  const s = newSlide(WHITE, cfg.owner);
  header(s, "Anexo · " + cfg.kind, cfg.title, cfg.subtitle);

  cfg.commands.forEach((c, i) => {
    const x = M + i * 6.1;
    card(s, x, 1.72, 5.85, 4.35, WHITE, BORDER, 0.12);
    chip(s, "COMANDO " + (i + 1), x + 0.2, 1.9, 1.15, ICE, NAVY, 7.4);

    s.addShape(pptx.ShapeType.roundRect, {
      x: x + 0.2, y: 2.28, w: 5.45, h: 0.88,
      fill: { color: "071A2E" },
      line: { color: "071A2E", width: 0 },
      rectRadius: 0.08,
    });
    txt(s, "$  " + c.cmd, {
      x: x + 0.32, y: 2.38, w: 5.18, h: 0.68,
      fontSize: 7.2, fontFace: "Courier New", color: CYAN_L, lineSpacing: 9.5,
    });

    txt(s, "OUTPUT", {
      x: x + 0.2, y: 3.3, w: 1.2, h: 0.18,
      fontSize: 7, bold: true, color: CYAN, charSpacing: 1,
    });
    s.addShape(pptx.ShapeType.roundRect, {
      x: x + 0.2, y: 3.52, w: 5.45, h: 0.95,
      fill: { color: "F4F7FA" },
      line: { color: BORDER, width: 0.8 },
      rectRadius: 0.06,
    });
    txt(s, c.out, {
      x: x + 0.32, y: 3.6, w: 5.18, h: 0.8,
      fontSize: 6.9, fontFace: "Courier New", color: "166534", lineSpacing: 9,
    });

    txt(s, "QUÉ HACE", {
      x: x + 0.2, y: 4.65, w: 1.4, h: 0.18,
      fontSize: 7, bold: true, color: CYAN, charSpacing: 1,
    });
    txt(s, c.why, {
      x: x + 0.2, y: 4.88, w: 5.45, h: 0.9,
      fontSize: 8.2, color: MUTED, lineSpacing: 11,
    });
  });

  card(s, M, 6.22, 12.1, 0.5, ICE, ICE, 0.08);
  txt(s, cfg.note, {
    x: M + 0.22, y: 6.22, w: 11.7, h: 0.5,
    fontSize: 8, bold: true, fontFace: "Courier New", color: NAVY, valign: "middle",
  });

  footer(s, 0);
  s.addNotes(cfg.notes);
}

// Exploración · M1
commandSlide({
  kind: "Exploración", title: "M1 · Erick", owner: "M1 · Erick Ramos Vera",
  subtitle: "Dos comandos para ver la puerta web y confirmar el target de sesión.",
  commands: [
    { cmd: "nmap -sV -p 80 10.10.10.11",
      out: "80/tcp open http Apache httpd 2.4.49\n(Unix) PHP/8.4.26",
      why: "Confirma la puerta web y la versión exacta de PHP." },
    { cmd: "curl -s -o /dev/null -w \"%{http_code}\" http://10.10.10.11:8080/session2.php",
      out: "200",
      why: "Comprueba que el target de sesión responde antes de atacar." },
  ],
  note: "Evidencia: F02-002 · EV-W2-01",
  notes: "Exploración M1. nmmap muestra Apache 2.4.49 con PHP 8.4.26; curl confirma session2.php en 200.",
});

// Exploración · M2
commandSlide({
  kind: "Exploración", title: "M2 · Doris", owner: "M2 · Doris Apaza Anahua",
  subtitle: "Dos comandos para ver Redis y su versión sin autenticación.",
  commands: [
    { cmd: "redis-cli -h 10.10.10.12 PING",
      out: "PONG",
      why: "Redis responde sin autenticación." },
    { cmd: "redis-cli -h 10.10.10.12 INFO server | grep redis_version",
      out: "redis_version:6.2.6",
      why: "Confirma la versión del servicio y el vector de acceso." },
  ],
  note: "Evidencia: F04-001 · F04-018",
  notes: "Exploración M2. PING devuelve PONG y INFO confirma Redis 6.2.6 sin auth.",
});

// Exploración · M3
commandSlide({
  kind: "Exploración", title: "M3 · Rony", owner: "M3 · Rony Churata Huacani",
  subtitle: "Dos comandos para ver el FTP anónimo y el export NFS.",
  commands: [
    { cmd: "curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt",
      out: "admin M4/M5: Admin13.-",
      why: "El FTP anónimo expone credenciales en claro." },
    { cmd: "showmount -e 10.10.10.13",
      out: "/srv/storage/backups 10.10.10.0/24",
      why: "Lista el export NFS y confirma el punto de escritura." },
  ],
  note: "Evidencia: F04-002 · F04-006",
  notes: "Exploración M3. El FTP entrega credenciales.txt y showmount lista el backup.",
});

// Exploración · M4
commandSlide({
  kind: "Exploración", title: "M4 · Fabiola", owner: "M4 · Fabiola Ancco Rafael",
  subtitle: "Dos comandos para ver SMB sin firma y la zona DNS.",
  commands: [
    { cmd: "nmap -p445 --script smb-security-mode 10.10.10.14",
      out: "message_signing: disabled",
      why: "SMB sin firma; superficie para el acceso." },
    { cmd: "dig axfr uni.lab @10.10.10.14 +short",
      out: "app.uni.lab. 10.10.10.11\nbkp.uni.lab. 10.10.10.13",
      why: "Transferencia de zona: mapa completo de la red." },
  ],
  note: "Evidencia: F04-012 · F04-013",
  notes: "Exploración M4. SMB signing deshabilitado y AXFR entrega la zona.",
});

// Exploración · M5
commandSlide({
  kind: "Exploración", title: "M5 · Marco", owner: "M5 · Marco Nina Cruz",
  subtitle: "Dos comandos para ver VNC y confirmar que no pide autenticación.",
  commands: [
    { cmd: "nmap -sV -p5900 10.10.10.15",
      out: "5900/tcp open vnc",
      why: "VNC expuesto en la estación cliente." },
    { cmd: "nmap -p5900 --script vnc-info 10.10.10.15",
      out: "Security types: None\nWARNING: Server does not require authentication",
      why: "Confirma que el escritorio no pide clave." },
  ],
  note: "Evidencia: F04-008",
  notes: "Exploración M5. VNC responde y no requiere autenticación.",
});

// Exploración · M6
commandSlide({
  kind: "Exploración", title: "M6 · Jose", owner: "M6 · Jose Paye Mamani",
  subtitle: "Dos comandos para descubrir hosts y validar la puerta desde Kali.",
  commands: [
    { cmd: "nmap -sn 10.10.10.0/24",
      out: "Nmap done: 256 IP addresses (7 hosts up)",
      why: "Descubre los hosts activos de la red." },
    { cmd: "nmap -sV -p80 10.10.10.11",
      out: "80/tcp open http Apache httpd 2.4.49\nPHP/8.4.26",
      why: "Valida la puerta y la versión desde el auditor." },
  ],
  note: "Evidencia: F01-005 · F02-002",
  notes: "Exploración M6. nmap -sn descubre 7 hosts; nmap -sV confirma Apache/PHP en M1.",
});

// Mitigación · M1
commandSlide({
  kind: "Mitigación", title: "M1 · Erick", owner: "M1 · Erick Ramos Vera",
  subtitle: "Dos comandos para verificar versión y ausencia del LFI.",
  commands: [
    { cmd: "php -v",
      out: "PHP 8.4.27 (cli)",
      why: "Confirma la versión corregida." },
    { cmd: "curl -s -o /dev/null -w \"%{http_code}\" http://10.10.10.11:8080/lfi.php",
      out: "404",
      why: "El sink LFI ya no existe." },
  ],
  note: "Evidencia: EV-007-RETEST",
  notes: "Mitigación M1. PHP 8.4.27 y lfi.php en 404.",
});

// Mitigación · M2
commandSlide({
  kind: "Mitigación", title: "M2 · Doris", owner: "M2 · Doris Apaza Anahua",
  subtitle: "Dos comandos para verificar autenticación y puertos cerrados.",
  commands: [
    { cmd: "redis-cli -h 10.10.10.12 PING",
      out: "(error) NOAUTH Authentication required.",
      why: "Redis ya exige autenticación." },
    { cmd: "nmap -p6379,3306 10.10.10.12",
      out: "6379/tcp filtered\n3306/tcp filtered",
      why: "Los puertos ya no responden desde M6." },
  ],
  note: "Evidencia: EV-007-RETEST",
  notes: "Mitigación M2. Redis devuelve NOAUTH y los puertos están filtrados.",
});

// Mitigación · M3
commandSlide({
  kind: "Mitigación", title: "M3 · Rony", owner: "M3 · Rony Churata Huacani",
  subtitle: "Dos comandos para verificar FTP cerrado y NFS con root_squash.",
  commands: [
    { cmd: "curl -s ftp://anonymous:anonymous@10.10.10.13/",
      out: "530 Permission denied",
      why: "El acceso anónimo está deshabilitado." },
    { cmd: "showmount -e 10.10.10.13",
      out: "/srv/storage/backups ... root_squash",
      why: "NFS ya no permite escritura como root." },
  ],
  note: "Evidencia: EV-007-RETEST",
  notes: "Mitigación M3. FTP anónimo en 530 y NFS con root_squash.",
});

// Mitigación · M4
commandSlide({
  kind: "Mitigación", title: "M4 · Fabiola", owner: "M4 · Fabiola Ancco Rafael",
  subtitle: "Dos comandos para verificar SMB firmado y AXFR cerrado.",
  commands: [
    { cmd: "nxc smb 10.10.10.14",
      out: "signing:True (SMBv1:False)",
      why: "SMB firmado y sin SMBv1." },
    { cmd: "dig axfr uni.lab @10.10.10.14 +short",
      out: "; Transfer failed.",
      why: "La transferencia de zona está cerrada." },
  ],
  note: "Evidencia: EV-007-RETEST",
  notes: "Mitigación M4. SMB signing activo, SMBv1 off y AXFR falla.",
});

// Mitigación · M5
commandSlide({
  kind: "Mitigación", title: "M5 · Marco", owner: "M5 · Marco Nina Cruz",
  subtitle: "Dos comandos para confirmar que M5 sigue filtrado; no se declara remediado.",
  commands: [
    { cmd: "nmap -p445,3389,5900 10.10.10.15",
      out: "445/tcp filtered\n3389/tcp filtered\n5900/tcp filtered",
      why: "Los tres servicios están filtrados." },
    { cmd: "nmap -sV -p5900 10.10.10.15",
      out: "5900/tcp filtered vnc",
      why: "VNC no responde; M5 queda pendiente." },
  ],
  note: "Evidencia: EV-007-RETEST · M5 pendiente",
  notes: "Mitigación M5. Los puertos están filtrados; no se pudo corregir y se declara pendiente.",
});

'''

s = s.replace(marker, appendix + marker)
p.write_text(s, encoding="utf-8")
print("OK anexo")
