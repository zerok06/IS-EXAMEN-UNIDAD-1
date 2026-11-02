# Lab PHP2Shell · uni.lab

> Un solo vector de entrada: **PHP2Shell** en M1. De ahí, cadena M1 → M2 → M3 → M5.
> M4 (PrintNightmare) es un salto **opcional**: usa la cuenta limitada `soporte`
> como precondición y **no es requisito** para llegar a M5.
> Todo lo demás (W1/W3/D1/B2/S1/C1, fases, informe viejo) está archivado en `../legacy/`.

## 1. Red

| VM | IP | Rol | SO | Servicios |
|---|---|---|---|---|
| R0 | 10.10.10.1 | router/NAT interno | — | gateway |
| M1 | 10.10.10.11 | app / entrada | Ubuntu 22.04 | nginx TLS :443 → Apache 2.4.49 prefork :8080 (mod_php 8.4.26) + WordPress 7.0.1 (Moodle 5.0.11 opcional) |
| M2 | 10.10.10.12 | base de datos | Ubuntu 22.04 | MariaDB 10.6 :3306, Redis 6.2.6 :6379 **sin auth y como root**, SSH |
| M3 | 10.10.10.13 | respaldos | Ubuntu 22.04 | vsftpd 2.3.4 :21, NFS `no_root_squash` :2049, cron root sobre el export, SSH |
| M4 | 10.10.10.14 | red / DNS | Windows Server 2016 | DNS `uni.lab` (AXFR), SMB1, SMB, WinRM, Spooler |
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

### Red de M6 (dos NIC, DNS partido)

M6 es la única VM con dos tarjetas: **NAT** (Internet y ruta por defecto) y
**bridge** (laboratorio). Se configura con `sudo bash lab/m6/net.sh`
(`lab/m6/install.sh` lo llama):

| Elemento | Valor |
|---|---|
| NIC del lab | `eth1` → `10.10.10.20/24`, **sin gateway** (la ruta por defecto es del NAT) |
| Ruta al lab | `10.10.10.0/24` por el prefijo de la dirección; gateway `10.10.10.1` = R0 |
| DNS de `uni.lab` | M4 `10.10.10.14`, consultado **solo** para `uni.lab` |
| DNS del resto | el del NAT (`192.168.25.2` en el entorno de referencia) |
| Resolvedor local | `dnsmasq` en `127.0.0.1:53` (`lab-dns.service`), `server=/uni.lab/10.10.10.14` |

M4 se instala **sin reenviadores** (`Disable-DnsForwarders` en `lab/m4/install.ps1`),
así que no resuelve nombres de Internet: ponerlo como único `nameserver` deja a M6
sin `apt`/`curl` externos y con timeouts. Por eso el split: `uni.lab` a M4, el resto
al NAT. No se usan entradas de `uni.lab` en `/etc/hosts` porque `files` gana sobre
`dns` y taparía a M4; el bloque existe solo como plan B (`LAB_HOSTS=1`).

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

## 4. Cadena (cada salto es una vulnerabilidad)

| # | Salto | Vulnerabilidad | Resultado |
|---|---|---|---|
| 1 | M6 → M1 | **PHP2Shell** (CVE-2026-109618/619) + sink LFI | `www-data` en M1 |
| 1.5 | M1 (pivote) | ligolo-ng: M1 pasa a ser la puerta | tráfico a M2/M3 por M1; M4/M5 directos |
| 2 | M1 → M2 | **Redis 6.2.6 sin auth y como root**: `CONFIG SET dir/dbfilename` + `SAVE` → `authorized_keys` | `root` en M2 |
| 3 | M2 → M3 | **NFS `no_root_squash`** + cron root sobre el export: se sobrescribe `rotate.sh` | `root` en M3 |
| 4 (opcional) | M3 → M4 | **PrintNightmare** (CVE-2021-34527, spooler), con la cuenta limitada `soporte` | `SYSTEM` en M4 |
| 5 | M1–M3 → M5 | **VNC sin autenticación** (TightVNC 2.8.90, CWE-306); no depende de M4 | escritorio de M5 |

Los saltos 1, 2, 3 y 5 **no usan credenciales**. El salto 4 es opcional y usa la
cuenta limitada `soporte` como **precondición** de PrintNightmare: no se obtiene
por explotación, pero es una credencial y se declara como tal. Las cuentas de
`§6` son de administración y **no forman parte de la cadena**.

```
M6 ──php2shell──> M1 www-data
                     │ Redis 0.0.0.0:6379 sin auth, como root
                     ▼
M2 root ──NFS no_root_squash + cron root──> M3 root
                     │                         │
                     │ (opcional)              └── VNC sin auth ──> M5
                     ▼
                M4 SYSTEM (PrintNightmare, requiere cuenta `soporte`)
```

> **Pivote real:** `01b-pivot.sh` sube el agente de ligolo-ng a M1 y monta un
> túnel con rutas `/32` para M2 y M3. M4 y M5 están en el mismo segmento L2 que
> M6; forzar su tráfico por el túnel rompe las conexiones inversas (por ejemplo,
> el callback de PrintNightmare). Esas dos `/32` deben omitirse: la ruta directa
> por `eth1` es la correcta. Si el túnel no está montado, los saltos avisan de
> que están yendo directo.

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

## 6. Credenciales del laboratorio

| Servicio | Usuario | Clave |
|---|---|---|
| WP admin | `usc.admin` | `Admin13.-` |
| Moodle admin | `moodleadmin` | `Admin13.-` |
| M1 SSH | `ubuntu` | `Admin13.-` |
| M2 SSH | `adminm2` | `adminm2` |
| M3 SSH | `rony123` | `rony123` |
| M3 backup | `backup` | solo llave de M2 |
| M4 | `Administrador` | `M4_Admin_2026!` |
| M4 limitado | `soporte` | `UniLab2026!` |
| M5 | `cliente` | `Admin13.-` |
| MariaDB | `wp_user` / `moodle_user` | `ClaveDebil123` |
| Redis | — | sin auth |

`soporte` es la única credencial que forma parte de la cadena, y solo en el
salto **opcional** 4 (PrintNightmare). Las demás son de administración.

## 7. Invariantes

1. Aislado: sin Internet mientras los servicios vulnerables estén activos.
2. Snapshots antes de cada cambio: `00-base`, `01-<rol>-listo`, `estado-inicial`, `estado-parcheado`.
3. Ningún instalador pide artefactos por Internet: todo sale de `artifacts/` servido por M6.
4. No se declara RCE sin `id`/`whoami` y marcador recuperado por un canal independiente.
5. `entry-a` no se presenta como resuelto hasta que produzca `id` real.
6. Revertir todo: `git checkout pre-php2shell-2026-10-31` (el árbol viejo vive en `legacy/`).

## 9. Versiones y parchado

- Versiones exactas y SHA256: [`VERSIONES.md`](./VERSIONES.md).
- Chequeo en cada VM: `bash lab/tests/check-versions.sh m1` (o m2/m3/m6).
- Parchado y retest: [`patch/README.md`](./patch/README.md) · [`GUIA-RETEST.md`](./GUIA-RETEST.md).

## 10. Estructura

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
├── chain/  00-preflight.sh  01-m1-php2shell.sh  01b-pivot.sh  02-m1-to-m2.sh … 05-m4-to-m5.sh
├── patch/  m1-php.sh  m2-redis.sh  m3-nfs.sh  m4.ps1  m5.ps1  retest.sh
└── tests/  smoke.sh  check-versions.sh
```
