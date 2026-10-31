# Bitácora · Fase 7 · Retest

Fecha UTC: 2026-10-24 · Comandos simples, secuenciales, mismos que la validación.

## M1 (`F07-001`)

| Comando | Antes | Después |
|---|---|---|
| `curl .../server-status` | 200 | **403** |
| `curl .../info.php` | 200 + phpinfo | archivo borrado; 0 menciones |
| `curl .../uploads/` | Index of | **403** |
| `curl .../wp-json/batch/v1` | `batch\/v1` | **403** |
| `curl --path-as-is .../cgi-bin/.%2e/...` | 503 | 500 sin leak |
| `grep upload_progress.enabled php.ini` | On | **Off** |

## M2 (`F07-005`)

| Comando | Antes | Después |
|---|---|---|
| `redis-cli -h .12 PING` | PONG | `NOAUTH`/timeout (filtrado) |
| `nmap -p 3306,6379,161 .12` | 6379 open | todo **filtered** |
| `mysql -u wp_user -p'wp_pass123'` | 12 tablas | **Access denied** |
| `mysql -u wp_user -p'nueva'` | — | `wordpress` + 487 tablas |

## M3 (`F07-002`)

| Comando | Antes | Después |
|---|---|---|
| `nmap -p 21,139,445 .13` | open | **closed** |
| `cat /etc/exports` | `no_root_squash` | **`root_squash`** |
| `ls .../credenciales.txt` | existe | **no existe** |
| `touch` NFS como root | root root | **Permission denied** |

## M4 (`F07-003`)

| Comando | Antes | Después |
|---|---|---|
| `nxc smb -p 'password_2026'` | Pwn3d! | **LOGON_FAILURE** |
| `nxc smb -p 'M4_Admin_2026!'` | — | Pwn3d! |
| `dig axfr uni.lab @.14` | zona completa | **Transfer failed** |
| `Get-SmbServerConfiguration` | SMB1 True, signing False | **False / True** |
| `Get-Service Spooler` | vulnerable | **Stopped/Disabled** |

## M5 (`F07-004`)

| Comando | Antes | Después |
|---|---|---|
| `nmap -p 5900 .15` | open + auth None | **filtered** |
| `Get-Service tvnserver` | Running | **Stopped/Disabled** |
| `UserAuthentication` RDP | 0 | **1** |
