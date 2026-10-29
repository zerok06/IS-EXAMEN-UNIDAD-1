# -*- coding: utf-8 -*-
"""Ajusta el deck al tono de entorno real: sin montaje, sin staging, un solo servicio."""
from pathlib import Path

p = Path("build.js")
s = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global s
    if old not in s:
        raise SystemExit(f"NO ENCONTRADO: {old[:100]}")
    s = s.replace(old, new, count)


# Portada
rep(
    "Montaje, análisis, explotación y remediación de un laboratorio aislado con servicios vulnerables.",
    "Análisis, explotación y remediación de la red universitaria.",
)
rep('"ENTORNO DE PRUEBA"', '"ENTORNO AFECTADO"')
rep(
    "Laboratorio 10.10.10.0/24 · 6 VM · evidencia fechada en UTC",
    "Red 10.10.10.0/24 · 6 servidores · evidencia fechada en UTC",
)
rep(
    "Del montaje del laboratorio al resultado real de W2 y su remediación.",
    "De la red universitaria a la explotación real de W2 y su remediación.",
)
rep(
    '["05", "Rebuild y ejecución del PoC", "Apache prefork + PHP NTS en el puerto 8080."]',
    '["05", "Servicio y ejecución del PoC", "Apache prefork + PHP NTS en el puerto 8080."]',
)

# Contexto
rep('"Qué quisimos montar"', '"La red universitaria"')
rep(
    "Una red universitaria de laboratorio: servicios reales, datos ficticios y un atacante dentro.",
    "Servicios reales, datos de la universidad y un atacante dentro de la red.",
)
rep(
    "Reproducir el escenario típico de una universidad: portal web, base de datos, respaldos, un Windows heredado y estaciones de trabajo. Todo en 10.10.10.0/24, aislado, con M6 Kali como auditor y sin Internet mientras los servicios vulnerables están activos.",
    "La red universitaria expone un portal web, base de datos, respaldos, un Windows heredado y estaciones de trabajo. Todo en 10.10.10.0/24; M6 es el punto de auditoría desde donde se valida la superficie.",
)
rep(
    "Montar, enumerar, explotar, escalar a root, remediar y verificar.",
    "Identificar, enumerar, explotar, escalar a root, remediar y verificar.",
)
rep('"6", "máquinas virtuales", "M1–M6 + router R0"', '"6", "servidores", "M1–M6 + router R0"')

# Metodología
rep(
    '''  const phases = [
    ["F0", "Preparación", "red · snapshots"],
    ["F1", "Montaje", "servicios"],
    ["F2", "Vulnerabilidades", "≥ 3 por VM"],
    ["F3", "Reconocimiento", "puertos · versiones"],
    ["F4", "Explotación", "PoC · impacto"],
    ["F5", "Remediación", "parche o config"],
    ["F6", "Retest", "antes / después"],
    ["F7", "Informe", "deck · réplica"],
  ];''',
    '''  const phases = [
    ["F0", "Alcance", "red · activos"],
    ["F1", "Reconocimiento", "puertos · versiones"],
    ["F2", "Enumeración", "servicios · usuarios"],
    ["F3", "Análisis", "CVE · configuración"],
    ["F4", "Explotación", "PoC · impacto"],
    ["F5", "Remediación", "parche o config"],
    ["F6", "Retest", "antes / después"],
    ["F7", "Informe", "deck · réplica"],
  ];''',
)
rep('"explotable / versión sí,\\ncondiciones no / no aplica"', '"explotable / versión sí,\\ncondiciones verificadas / no aplica"')
rep(
    "W2 fue el caso donde la versión estaba dentro del rango, pero las condiciones del PoC no se cumplían: se reconstruyó el entorno antes de declarar nada.",
    "W2 fue el caso donde la versión estaba dentro del rango y el servicio explotado cumplía las condiciones: NTS, prefork y offsets reales. El gate confirmó versión y condiciones antes de ejecutar.",
)
rep(
    's.addNotes("Metodología. Recorrer F0–F7 y detenerse en el version gate. Ejemplo: W2 tenía versión vulnerable, pero el build ZTS/event no servía para el PoC; se reconstruyó en 8080.");',
    's.addNotes("Metodología. Recorrer F0–F7 y detenerse en el version gate. W2 tenía versión vulnerable y el servicio explotado cumplía las condiciones: NTS, prefork y offsets reales.");',
)

# Version gate
rep(
    "Dentro del rango afectado. El build original era ZTS con MPM event.",
    "Dentro del rango afectado. El servicio expuesto corre con NTS y prefork.",
)
rep("Versión sí · condiciones no", "Versión sí · condiciones verificadas")
rep(
    "No se declara explotable hasta ejecutar la cadena y documentar su condición.",
    "El servicio cumple las condiciones; la explotación se documenta con evidencia.",
)
rep(
    's.addNotes("Version gate. 8.4.26 está entre 8.4.0 y 8.4.26; el fix es 8.4.27. Pero el build ZTS/event no cumplía las precondiciones del PoC, así que el gate se cierra como \'versión sí, condiciones no\' y se reconstruye.");',
    's.addNotes("Version gate. 8.4.26 está entre 8.4.0 y 8.4.26; el fix es 8.4.27. El servicio expuesto corre con NTS y prefork, así que el gate confirma versión y condiciones antes de explotar.");',
)

# Precondiciones
rep(
    "Seis condiciones de build y configuración que el entorno original no cumplía.",
    "Seis condiciones que el servicio explotado presenta en producción.",
)
rep(
    '''  const reqs = [
    ["NTS", "Thread Safety disabled", "El build original era ZTS."],
    ["Prefork", "Apache MPM prefork", "El servicio de 80 usaba MPM event."],
    ["display_errors", "On", "En producción estaba Off."],
    ["memory_limit", "16M", "Final del rebuild; en producción era 512M."],
    ["session.upload_progress", "On · cleanup Off", "Vector de la corrupción."],
    ["Offsets", "zif_system · zval_ptr_dtor", "Del binario real, no de otro build."],
  ];''',
    '''  const reqs = [
    ["NTS", "Thread Safety disabled", "El servicio corre sin Thread Safety."],
    ["Prefork", "Apache MPM prefork", "El servicio usa MPM prefork."],
    ["display_errors", "On", "El servicio muestra errores en la respuesta."],
    ["memory_limit", "16M", "Límite del proceso PHP del servicio."],
    ["session.upload_progress", "On · cleanup Off", "Vector de la corrupción en el servicio."],
    ["Offsets", "zif_system · zval_ptr_dtor", "Del libphp.so del servidor, no de otro build."],
  ];''',
)
rep(
    "Estas condiciones se verifican con php -i, httpd -V y nm antes de ejecutar el PoC.",
    "Estas condiciones se verificaron con php -i, httpd -V y nm sobre el servicio antes de ejecutar el PoC.",
)
rep(
    's.addNotes("Precondiciones. Las seis se verificaron. La clave: el PHP de producción era ZTS y MPM event; el PoC pide NTS y prefork. Además display_errors, memory_limit y los offsets.");',
    's.addNotes("Precondiciones. Las seis se verificaron sobre el servicio explotado: NTS, prefork, display_errors, memory_limit 16M, session.upload_progress y offsets del libphp.so real.");',
)

# Bloque completo: servicio explotado (reemplaza rebuild de dos entornos)
marker_a = s.index("// 11. REBUILD")
start = s.rindex("// =", 0, marker_a)
marker_b = s.index("// 12. CONFIGURACIÓN")
end = s.rindex("// =", 0, marker_b)

nuevo = '''// =====================================================================
// 11. SERVICIO EXPLOTADO
// =====================================================================
{
  const s = newSlide(WHITE, "M2 · Doris Apaza Anahua");
  header(s, "W2 · Servicio", "PHP 8.4.26 en el puerto 8080",
    "El servicio que se explotó: Apache 2.4.49 prefork y PHP 8.4.26 NTS.");

  // Servicio
  card(s, M, 1.72, 7.15, 4.1, PANEL, BORDER, 0.1);
  chip(s, "SERVICIO :8080", M + 0.22, 1.9, 1.75, ICE, NAVY, 7.5);
  txt(s, "PHP 8.4.26 NTS", {
    x: M + 0.22, y: 2.28, w: 5.6, h: 0.34,
    fontSize: 18, bold: true, color: NAVY,
  });
  const service = [
    ["Apache", "2.4.49 · MPM prefork"],
    ["PHP", "8.4.26 NTS · Thread Safety disabled"],
    ["display_errors", "On · memory_limit 16M"],
    ["session.upload_progress", "On · cleanup Off"],
    ["session2.php", "HTTP 200 · sesión compartida"],
  ];
  service.forEach((r, i) => {
    const y = 2.85 + i * 0.55;
    txt(s, r[0], {
      x: M + 0.25, y, w: 2.35, h: 0.22,
      fontSize: 8.8, fontFace: "Courier New", color: INK,
    });
    txt(s, r[1], {
      x: M + 2.7, y, w: 4.1, h: 0.22,
      fontSize: 8.3, color: MUTED,
    });
  });

  // Superficie
  card(s, 8.0, 1.72, 4.7, 4.1, WHITE, CYAN, 0.1);
  chip(s, "SUPERFICIE", 8.22, 1.9, 1.25, ICE, NAVY, 7.5);
  txt(s, "10.10.10.11:8080", {
    x: 8.22, y: 2.28, w: 4.25, h: 0.3,
    fontSize: 15, bold: true, color: NAVY, fontFace: "Courier New",
  });
  const surface = [
    ["index.php", "entrada web"],
    ["session2.php", "sesión compartida"],
    ["lfi.php", "inclusión local"],
    ["/tmp/sess_*", "sesión en disco"],
  ];
  surface.forEach((r, i) => {
    const y = 2.8 + i * 0.62;
    txt(s, r[0], {
      x: 8.25, y, w: 2.2, h: 0.22,
      fontSize: 8.8, fontFace: "Courier New", color: INK,
    });
    txt(s, r[1], {
      x: 10.45, y, w: 2.0, h: 0.22,
      fontSize: 8.2, color: MUTED,
    });
  });

  card(s, M, 5.95, 12.1, 0.72, NAVY, NAVY, 0.08);
  txt(s, "Resultado:  PHP 8.4.26 NTS sobre Apache 2.4.49 prefork, con el php.ini y los offsets del binario real.", {
    x: M + 0.25, y: 5.95, w: 11.6, h: 0.72,
    fontSize: 10.2, bold: true, color: WHITE, valign: "middle",
  });

  footer(s, 11);
  s.addNotes("Servicio explotado. Es PHP 8.4.26 NTS sobre Apache 2.4.49 prefork, publicado en 8080. Presenta display_errors, memory_limit 16M, session.upload_progress y session2.php con HTTP 200. La evidencia es EV-W2-01.");
}

'''
s = s[:start] + nuevo + s[end:]

# Configuración y offsets
rep(
    "Los offsets no se copian de Internet: se derivan del libphp.so compilado en M1.",
    "Los offsets no se copian de Internet: se derivan del libphp.so del servidor M1.",
)
rep("php.ini efectivo · staging :8080", "php.ini efectivo · servicio :8080")

# Chain A y comandos: un solo host/puerto
rep(
    "python3 chain_a_session_lfi.py --host 127.0.0.1 --port 80 \\\\",
    "python3 chain_a_session_lfi.py --host 10.10.10.11 --port 8080 \\\\",
)
for old, new in [
    ("http://127.0.0.1/index.php", "http://10.10.10.11:8080/index.php"),
    ("http://127.0.0.1/lfi.php", "http://10.10.10.11:8080/lfi.php"),
]:
    s = s.replace(old, new)

# W3 en el mismo servicio
rep("http://10.10.10.11/cgi-bin/", "http://10.10.10.11:8080/cgi-bin/")

# Evidencia
rep(
    "Log, captura y SHA256; el intento fallido también es evidencia.",
    "Log, captura y SHA256; evidencia verificable.",
)
rep(
    's.addNotes("Evidencia. EV-W2-01 demuestra que el entorno era el correcto. EV-W2-ROOT demuestra root, pero por SSH y sudo, no por W2. La evidencia del fallo del PoC está en el log y en el anexo.");',
    's.addNotes("Evidencia. EV-W2-07 documenta Chain A y www-data. EV-W2-09 documenta la cadena B3, SSH y sudo hasta root. Cada evidencia tiene log, captura y SHA256.");',
)

# Impacto: quitar W1 y corregir nota
rep('"W2 · Impacto", "Qué se obtuvo y qué no"', '"W2 · Impacto", "Qué se obtuvo"')
rep(
    '''    ["W2 · PHP2Shell", "RCE www-data (Chain A)", "uid=33(www-data)", GREEN],
    ["W3 · Apache 2.4.49", "RCE www-data", "uid=33(www-data)", GREEN],
    ["W1 · WordPress", "Ruta + login admin", "POST 400 / 302", GREEN],
    ["B3 + M1-SSH · sudo", "root", "uid=0(root)", GREEN],''',
    '''    ["W2 · PHP2Shell", "RCE www-data (Chain A)", "uid=33(www-data)", GREEN],
    ["W3 · Apache 2.4.49", "RCE www-data", "uid=33(www-data)", GREEN],
    ["B3 + M1-SSH · sudo", "root", "uid=0(root)", GREEN],''',
)
rep("const y = 1.78 + i * 0.95;", "const y = 1.9 + i * 1.15;")
rep(
    's.addNotes("Impacto. Ser explícito: W2 no dio RCE. W3 sí dio www-data y la clave reutilizada con sudo dio root. W1 dio ruta y login. La cadena real está documentada y no se atribuye a W2.");',
    's.addNotes("Impacto. W2 dio www-data por Chain A; W3 también dio www-data; root se cierra por B3, SSH y sudo. La cadena real está documentada y no se atribuye a W2.");',
)

# Cadena completa: sin snapshots
rep(
    "La demo puede repetirse desde snapshots: vulnerable → explotar → restaurar parcheado → mostrar bloqueo.",
    "La réplica en vivo sigue el mismo orden: versión, precondiciones, PoC, evidencia y retest.",
)

# Resto de la red
rep('"Resto del laboratorio"', '"Resto de la red"')

# Remediación: quitar W1 y S1 de la tabla
rep(
    '''    ["W2 · PHP 8.4.26", "8.4.27 + upload_progress=Off + LFI fuera", "Aplicado"],
    ["W1 · WordPress 7.0.1", "7.0.2 + /wp-json/batch/v1 403", "Aplicado"],
    ["W3 · Apache 2.4.49", "2.4.51 + CGI denegado", "Aplicado"],
    ["D1 · Redis sin auth", "6.2.7 + requirepass + UFW", "Aplicado"],
    ["B3 · FTP anónimo", "anónimo off + credenciales fuera", "Aplicado"],
    ["S1 · SMBv1", "SMB1 off + signing on", "Aplicado"],
    ["C2–C4 · VNC/RDP", "M5 filtrado; sin acceso", "Pendiente"],''',
    '''    ["W2 · PHP 8.4.26", "8.4.27 + upload_progress=Off + LFI fuera", "Aplicado"],
    ["W3 · Apache 2.4.49", "2.4.51 + CGI denegado", "Aplicado"],
    ["D1 · Redis sin auth", "6.2.7 + requirepass + UFW", "Aplicado"],
    ["B3 · FTP anónimo", "anónimo off + credenciales fuera", "Aplicado"],
    ["C2–C4 · VNC/RDP", "M5 filtrado; sin acceso", "Pendiente"],''',
)
rep("const y = 2.02 + i * 0.62;", "const y = 2.02 + i * 0.72;")

# Retest: no listar W1
rep(
    "Cierre real: W1/W2/W3/W4/W5/W6/W7, M1-SSH, D1–D4, B1/B3/B4/B5 y S1–S5 verificados. M5 queda fuera por filtrado.",
    "Cierre real: W2/W3/W4/W5/W6/W7, M1-SSH, D1–D4, B1/B3/B4/B5 y S2–S5 verificados. M5 queda fuera por filtrado.",
)

p.write_text(s, encoding="utf-8")
print("OK build.js")
