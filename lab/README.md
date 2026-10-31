# Lab PHP2Shell · uni.lab

> Un solo vector de entrada: **PHP2Shell** en M1. De ahí, cadena M1 → M2 → M3 → M4 → M5.
> Todo lo demás (W1/W3/D1/B2/S1/C1, fases, informe viejo) está archivado en `../legacy/`.

## 1. Red

| VM | IP | Rol | SO | Servicios |
|---|---|---|---|---|
| R0 | 10.10.10.1 | router/NAT interno | — | gateway |
| M1 | 10.10.10.11 | app / entrada | Ubuntu 22.04 | nginx TLS :443 → Apache 2.4.49 prefork :8080 (mod_php 8.4.26) + WordPress 7.0.1 + Moodle 5.0.11 |
| M2 | 10.10.10.12 | base de datos | Ubuntu 22.04 | MariaDB 10.11 :3306, Redis 6.2.6 :6379, SSH |
| M3 | 10.10.10.13 | respaldos | Ubuntu 22.04 | vsftpd 2.3.4 :21, NFS :2049, Samba 4.5.9 :445, SSH |
| M4 | 10.10.10.14 | red / DNS | Windows Server 2016 | DNS `uni.lab` (AXFR), SMB, WinRM, Spooler |
| M5 | 10.10.10.15 | cliente | Windows 10 19045 | SMB, RDP sin NLA, VNC |
| M6 | 10.10.10.20 | atacante | Kali | repo + artefactos servidos en :8000 |

Dominio: **`uni.lab`**. DNS autoritativo en M4. Zona:

```
app.uni.lab      A    10.10.10.11
wp.uni.lab       CNAME app.uni.lab.
moodle.uni.lab   CNAME app.uni.lab.
db.uni.lab       A    10.10.10.12
bkp.uni.lab      A    10.10.10.13
srvold.uni.lab   A    10.10.10.14
pc-est01.uni.lab A    10.10.10.15
```

## 2. Por qué nginx + Apache (no nginx + FPM)

PHP2Shell se explota en el **worker de PHP**, y el PoC público solo se calibró para
`mod_php` sobre **prefork** (un hijo, estado entre requests). Por eso:

```
M6 --HTTPS:443--> nginx (TLS, HTTP/2, límites grandes)
                     |
                     +--proxy_pass--> 127.0.0.1:8080  Apache 2.4.49 prefork + mod_php 8.4.26
```

nginx aporta TLS, HTTP/2 y `client_max_body_size 64m`; Apache aporta el SAPI que el
exploit necesita. nginx **no** ejecuta PHP.

## 3. Entrada: PHP2Shell

Dos modos, mismo origen (M1, HTTP pre-auth):

| Modo | Qué es | Estado | Da |
|---|---|---|---|
| `entry-a` | CVE-2026-109618/109619 puro (OOM + corrupción de estado, PoC `poc_109618.py` instrumentado) | **en investigación**: el PoC público falla en stage 1 incluso en `php:8.4.26-apache` | `www-data` si cierra |
| `entry-b` | PHP2Shell Chain A: `session.upload_progress` + sink LFI del plugin legado | **operativo** | `www-data` |

`entry-b` es el que se usa para la cadena. Se declara en el informe como
"PHP2Shell (vector de sesión) + LFI", **no** como el UAF de 109618.

El sink LFI es intencional y forma parte del escenario: plugin `legacy-download`
en WordPress (`/wp-content/plugins/legacy-download/dl.php?file=`), un plugin
"heredado" mal escrito. Está versionado en `m1/app/`.

## 4. Cadena

```
M6 ──php2shell──> M1 www-data
                     │ lee wp-config.php (DB_HOST=10.10.10.12, wp_user/ClaveDebil123)
                     ▼
M2 adminm2/adminm2 (SSH) ──sudo──> root ──/root/.ssh/id_ed25519──> M3
                     │ volcado wp_db/moodle_db, Redis sin auth
                     ▼
M3 backup (llave) ──> /srv/storage/backups/credenciales.txt ──> M4
                     │ NFS no_root_squash → SUID root en M1
                     ▼
M4 Administrador/M4_Admin_2026! (WinRM) ──> DNS uni.lab, shares
                     │ AXFR + pc-est01.uni.lab + credenciales en share
                     ▼
M5 cliente/Admin13.- (SMB/RDP) ──> flag
```

Comandos por salto en `chain/`. Cada script imprime el comando exacto, no lo ejecuta
a ciegas: se corre desde M6 con el túnel/proxychains correspondiente.

## 5. Instalación automatizada

En M6 (una vez):

```bash
# servidor de despliegue
sudo bash lab/m6/install.sh
```

En cada VM (Ubuntu/Windows), desde consola:

```bash
curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m1
```

```powershell
# Windows (M4/M5)
iwr http://10.10.10.20:8000/bootstrap.ps1 -UseBasicParsing | iex
# y luego: C:\lab\m4\install.ps1
```

`bootstrap.sh` baja `lab.tar.gz` desde M6, lo extrae en `/opt/lab` y ejecuta el
instalador del rol. Todos los instaladores son **idempotentes** y terminan con
`verify.sh`, que falla ruidosamente si el servicio no quedó como se espera.

## 6. Credenciales (solo laboratorio aislado)

| Servicio | Usuario | Clave |
|---|---|---|
| WP admin | `usc.admin` | `Admin13.-` |
| Moodle admin | `moodleadmin` | `Admin13.-` |
| M1 SSH | `ubuntu` | `Admin13.-` |
| M2 SSH | `adminm2` | `adminm2` |
| M3 SSH | `rony123` | `rony123` |
| M3 backup | `backup` | solo llave de M2 |
| M4 | `Administrador` | `M4_Admin_2026!` |
| M4 limitado | `soporte` | `Soporte2026!` |
| M5 | `cliente` | `Admin13.-` |
| MariaDB | `wp_user` / `moodle_user` | `ClaveDebil123` |
| Redis | — | sin auth |

## 7. Invariantes

1. Aislado: sin Internet mientras los servicios vulnerables estén activos.
2. Snapshots antes de cada cambio: `00-base`, `01-<rol>-listo`, `estado-inicial`, `estado-parcheado`.
3. Ningún instalador pide artefactos por Internet: todo sale de `artifacts/` servido por M6.
4. No se declara RCE sin `id`/`whoami` y marcador recuperado por un canal independiente.
5. `entry-a` no se presenta como resuelto hasta que produzca `id` real.
6. Revertir todo: `git checkout pre-php2shell-2026-10-31` (el árbol viejo vive en `legacy/`).

## 8. Estructura

```
lab/
├── bootstrap.sh / bootstrap.ps1   # arranque desde M6
├── common/lib.sh                  # logging, fetch, idempotencia
├── pki/                           # CA + certs para *.uni.lab
├── m1/  install.sh  verify.sh  conf/  app/
├── m2/  install.sh  verify.sh
├── m3/  install.sh  verify.sh
├── m4/  install.ps1 verify.ps1
├── m5/  install.ps1 verify.ps1
├── m6/  install.sh  serve.sh
├── chain/  01-m1.sh … 05-m5.sh
└── tests/  smoke.sh
```
