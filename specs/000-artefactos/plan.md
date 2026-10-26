# Plan 000 · Artefactos y transferencia FTP

## 1. Enfoque

Se descargan las versiones exactas en el host (con Internet), se verifica el SHA256, se copia `artifacts/` a M6 y se sirve por FTP. Cada VM descarga solo lo suyo. No se instala nada sin hash verificado.

## 2. Descarga

```powershell
# Windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\artifacts\download.ps1
```

```bash
# Linux/WSL
./artifacts/download.sh
```

## 3. Verificación

```bash
cd artifacts
sha256sum -c checksums.sha256
```

```powershell
Get-FileHash -Algorithm SHA256 .\artifacts\vulnerable\php-8.4.26.tar.gz
# comparar con checksums.sha256
```

## 4. Copiar a M6

Antes de aislar, copiar `artifacts/` a M6:

```bash
# Desde el host (ejemplo con scp)
scp -r artifacts kali@10.10.10.20:~/artifacts
```

Alternativa: USB o carpeta compartida. Verificar de nuevo en M6:

```bash
cd ~/artifacts
sha256sum -c checksums.sha256
```

## 5. Servidor FTP

```bash
cd ~/artifacts
chmod +x ftp/serve-ftp.sh
./ftp/serve-ftp.sh
```

Salida esperada:

```text
ftp://10.10.10.20:2121
Usuario: lab
Clave:   lab123
```

Firewall:

```bash
sudo ufw allow 2121/tcp
```

## 6. Descarga por rol

| VM | Comando | Artefactos |
|---|---|---|
| M1 | `./ftp/fetch-artifacts.sh m1` | WP 7.0.1, PHP 8.4.26, Apache 2.4.49, Moodle, PoCs |
| M2 | `./ftp/fetch-artifacts.sh m2` | Redis 6.2.6 |
| M3 | `./ftp/fetch-artifacts.sh m3` | Samba 4.5.9, vsftpd 2.3.4 |
| M5 | `ftp/fetch-artifacts.ps1 -Role m5` | TightVNC 2.8.90 |
| M6 | `./ftp/fetch-artifacts.sh m6` | PoCs, ligolo |
| M1 fix | `./ftp/fetch-artifacts.sh m1-fixed` | WP 7.0.2, PHP 8.4.27, Apache 2.4.51 |
| M2 fix | `./ftp/fetch-artifacts.sh m2-fixed` | Redis 6.2.7 |
| M3 fix | `./ftp/fetch-artifacts.sh m3-fixed` | Samba 4.5.10, vsftpd 3.0.5 |

Cada script verifica con `sha256sum -c --ignore-missing checksums.sha256`.

## 7. Instalación

| VM | Artefacto | Ruta |
|---|---|---|
| M1 | `wordpress-7.0.1.zip` | `/var/www/wp` |
| M1 | `php-8.4.26.tar.gz` | `/usr/local` |
| M1 | `httpd-2.4.49.tar.gz` | `/usr/local/apache2` |
| M1 | `moodle-5.0.11.tar.gz` | `/var/www/moodle` |
| M2 | `redis-6.2.6.tar.gz` | `/usr/local/bin` |
| M3 | `samba-4.5.9.tar.gz` | `/usr/local/samba` |
| M3 | `vsftpd-2.3.4.tar.gz` | `/usr/local/sbin` |
| M5 | `tightvnc-2.8.90...msi` | `C:\Program Files\TightVNC` |

**Fase 2:** versiones vulnerables.
**Fase 5:** versiones corregidas, sobre `estado-inicial-vulnerable`.

## 8. Evidencia

- `LOG-000-01.txt`: descarga y hashes.
- `LOG-000-02.txt`: `sha256sum -c`.
- `LOG-000-03.txt`: FTP server.
- `LOG-000-04.txt`: descarga por VM.
- `EV-000-05.png`: `--version` / `wp core version` / `php -v`.
- `templates/version-gate.md` actualizado.

## 9. Riesgos y rollback

| Riesgo | Acción |
|---|---|
| SHA256 no coincide | Borrar, re-descargar, verificar |
| FTP no conecta | Revisar UFW, IP y `pyftpdlib`; usar HTTP |
| Defender bloquea PoC | Usar MSF; no instalar el .ps1 |
| Disco lleno | Liberar espacio; borrar duplicados |
| Artefacto equivocado | Restaurar snapshot y reinstalar |

## 10. Definición de terminado

- [ ] 19 artefactos descargados.
- [ ] `checksums.sha256` verificado.
- [ ] `artifacts/` copiado a M6.
- [ ] FTP funcionando.
- [ ] Cada VM con sus artefactos.
- [ ] Versiones instaladas registradas.
- [ ] `version-gate.md` completo.

## 11. Estimación

| Actividad | Horas |
|---|---|
| Descarga | 0.5 |
| Verificación | 0.2 |
| Copia a M6 | 0.3 |
| FTP + descarga por VM | 0.5 |
| **Total** | **1.5** |
