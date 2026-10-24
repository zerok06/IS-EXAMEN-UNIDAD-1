# Bitácora · Fase 2 · Escaneo y enumeración

Fecha UTC: 2026-10-24 · Ejecuta: M6 `10.10.10.20`

| ID | Comando | Explicación | Salida real (resumen) | Evidencia | Lectura |
|---|---|---|---|---|---|
| CMD-F02-001 | `nmap -Pn -p 22,80,443 10.10.10.11` | Puerta M1 | `22 open`, `80 open`, `443 closed` | `F02-001b` | Solo HTTP publicado; SSH para administración |
| CMD-F02-002 | `nmap -Pn -p 3306,6379,161 10.10.10.12` | Servicios M2 | `6379 open`; `3306 filtered`; `161 filtered` | `F02-001` | Redis expuesto a la LAN |
| CMD-F02-003 | `nmap -Pn -p 21,139,445,2049 10.10.10.13` | Servicios M3 | `21/139/445 open`; `2049 filtered` | `F02-001` | FTP/SMB expuestos; NFS solo M1 |
| CMD-F02-004 | `nmap -Pn -p 445,3389 10.10.10.14` | Servicios M4 | `445 open`; `3389 filtered` | `F02-001` | ⚠️ SMB visible desde M6 |
| CMD-F02-005 | `nmap -Pn -p 445,3389,5900 10.10.10.15` | Servicios M5 | `445 filtered`; `3389 open`; `5900 open` | `F02-001` | ⚠️ RDP/VNC visibles desde M6 |
| CMD-F02-006 | `nmap -sV -Pn -p 80 --version-light --host-timeout 30s 10.10.10.11` | Versión de HTTP | `Apache httpd 2.4.49 ((Unix) PHP/8.4.26)` | `F02-002` | W3 y W2 confirmados por servicio |
| CMD-F02-007 | `wpscan --url http://wp.uni.lab --enumerate u` | Enumera WordPress | `WordPress 7.0.1`; `usc-admin`; 12 s | `F02-003b` | W1 confirmado; usuario para W4 |
| CMD-F02-008 | `curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/server-status` | W5 | `200` | `F02-004` | `mod_status` expuesto |
| CMD-F02-009 | `curl -s http://wp.uni.lab/info.php \| grep -i 'PHP Version'` | W6 | `PHP Version 8.4.26` | `F02-004` | `phpinfo()` público |
| CMD-F02-010 | `curl -s http://wp.uni.lab/wp-content/uploads/ \| grep -i 'Index of'` | W7 | `Index of /wp-content/uploads` | `F02-004` | Listado de directorios |

**Limitaciones:** `nmap -sV` sin `--host-timeout` falla en M1 por latencia; `wpscan --enumerate vp,vt,u` se interrumpió en la fase agresiva de temas. Se documenta el intento parcial (`F02-003`).

**Cierre:** superficie y versiones correlacionadas; W5/W6/W7 confirmados.
