# Artefactos · software versionado del laboratorio

Esta carpeta contiene las **versiones exactas** que se instalan en M1–M5, separadas en vulnerable y corregida, más los PoCs y herramientas de pivote. Todo se verifica con SHA256 antes de instalar.

## 1. Estructura

```text
artifacts/
├── vulnerable/     versiones que se instalan en Fase 2
├── fixed/          versiones que se instalan en Fase 5
├── pocs/           PoCs y herramientas de pivote
├── os/             URLs y hashes de ISOs (no descargadas por tamaño)
├── ftp/            servidor FTP y scripts de descarga por VM
├── download.ps1    descarga y genera checksums (Windows)
├── download.sh     descarga y genera checksums (Linux)
├── checksums.sha256
├── MANIFEST.md
└── README.md
```

## 2. Verificar

```bash
cd artifacts
sha256sum -c checksums.sha256
```

```powershell
Get-FileHash -Algorithm SHA256 .\artifacts\vulnerable\php-8.4.26.tar.gz
# comparar con checksums.sha256
```

## 3. Servir por FTP

En M6 (Kali), con la carpeta `artifacts/` copiada:

```bash
cd ~/artifacts
./ftp/serve-ftp.sh
# Servidor: ftp://10.10.10.20:2121
# Usuario: lab / lab123
```

Si no está `pyftpdlib`:

```bash
pip install pyftpdlib
```

Alternativa HTTP (si el FTP falla):

```bash
python3 -m http.server 8080 --directory ~/artifacts
```

## 4. Descargar en cada VM

```bash
# M1
./ftp/fetch-artifacts.sh m1
# M2
./ftp/fetch-artifacts.sh m2
# M3
./ftp/fetch-artifacts.sh m3
# M6
./ftp/fetch-artifacts.sh m6
# Versiones corregidas
./ftp/fetch-artifacts.sh m1-fixed
./ftp/fetch-artifacts.sh m2-fixed
./ftp/fetch-artifacts.sh m3-fixed
```

En M5 (Windows), usar `ftp/fetch-artifacts.ps1` o el comando del README de `ftp/`.

## 5. Instalar

| VM | Artefacto | Ruta de instalación |
|---|---|---|
| M1 | `wordpress-7.0.1.zip` | `/var/www/wp` |
| M1 | `php-8.4.26.tar.gz` | `/usr/local` (mod_php) |
| M1 | `httpd-2.4.49.tar.gz` | `/usr/local/apache2` |
| M1 | `moodle-5.0.11.tar.gz` | `/var/www/moodle` |
| M2 | `redis-6.2.6.tar.gz` | `/usr/local/bin` |
| M3 | `samba-4.5.9.tar.gz` | `/usr/local/samba` |
| M3 | `vsftpd-2.3.4.tar.gz` | `/usr/local/sbin` |
| M5 | `tightvnc-2.8.90-gpl-setup-64bit.msi` | `C:\Program Files\TightVNC` |

Las versiones corregidas se instalan en Fase 5 sobre `estado-inicial-vulnerable`, no sobre el estado comprometido.

## 6. Notas críticas

- **Redis 6.2.6 de fuente no es vulnerable a CVE-2022-0543.** Ese CVE es del empaquetado Debian/Ubuntu. Si se quiere el 10.0, usar el paquete distro; si no, documentar la limitación y sostener M2 con D2/D3/D4.
- **vsftpd 2.3.4 limpio no tiene backdoor.** El CVE-2011-2523 aplica al tarball troyanizado de 2011-06-30 a 2011-07-03. En este laboratorio se usa el tarball limpio; B2 se documenta como no explotable o se retira.
- **PrintNightmare:** el PoC PowerShell (`Invoke-Nightmare` / `CVE-2021-1675.ps1`) lo bloquea Windows Defender. Se usa el módulo de Metasploit `exploit/windows/local/cve_2021_1675_printnightmare`, que ya viene en Kali.
- **ISOs:** no se descargan por tamaño/licencia. Ver [`os/README.md`](./os/README.md).
- **Aislamiento:** descargar todo antes de aislar la red. Durante la explotación, el FTP es solo LAN `10.10.10.0/24`.

## 7. Reglas

1. No se instala nada sin SHA256 verificado.
2. No se descarga nada durante la explotación.
3. No se usa un artefacto fuera de `10.10.10.0/24`.
4. No se guardan binarios troyanizados ni malware.
5. Cada instalación se registra en `templates/version-gate.md`.
