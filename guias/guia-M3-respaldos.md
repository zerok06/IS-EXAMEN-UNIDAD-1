# Guía M3 · Respaldos / Storage (Estudiante 3)

**Rol:** NFS de la app + Samba + FTP de backups. Tus backups en claro son el **paso 3 de la cadena**.

> Versión automatizada: [`ansible/play-m3-backup.yml`](../ansible/play-m3-backup.yml).

## Estado real de la implementación (validado 2026-10-24)

| Componente | Estado real |
|---|---|
| NFS | `nfs-server` activo; exporta `wp-uploads`, `moodledata` (solo M1) y `backups` (LAN, `no_root_squash`) |
| Storage | `/srv/storage/{wp-uploads,moodledata,backups}` con dueño `www-data`, modos `2775/2770` |
| vsftpd | **2.3.4** compilado (parche `-lpam`), unidad `vsftpd-lab`, escucha `:21`, anónimo con escritura (B2/B3) |
| Backups | `credenciales.txt` con la clave común de M4/M5 (intencional, paso 3 de la cadena) |
| Samba | **PENDIENTE**: el `waf` de 4.5.10 es Python 2; el porte a Python 3 quedó a medias (vuln B1 aún no disponible) |
| Firewall | UFW: NFS solo M1, 21/139/445 abiertos (B1/B2/B3) |

## 0. Imagen base e instaladores

| Qué | Versión exacta | Origen |
|---|---|---|
| Ubuntu Server | **22.04.5** (misma ISO que M1) | https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso |
| Samba | **4.5.10** `samba-4.5.10.tar.gz` (B1) | https://download.samba.org/pub/samba/stable/samba-4.5.10.tar.gz |
| vsftpd | **2.3.4** `vsftpd-2.3.4.tar.gz` (B2) | https://security.appspot.com/downloads/vsftpd-2.3.4.tar.gz |
| NFS + SSH | repo (`nfs-kernel-server`, `openssh-server`) | repo Ubuntu |

```bash
sudo apt update && sudo apt install -y build-essential nfs-kernel-server openssh-server \
  libgnutls28-dev libpopt-dev libldap2-dev libpam0g-dev python3-dev
# vsftpd 2.3.4: tar xzf vsftpd-2.3.4.tar.gz && cd vsftpd-2.3.4 && sudo make install
# Samba 4.5.10: ./configure --without-ad-dc && make -j$(nproc) && sudo make install
smbd --version   # debe decir 4.5.10
```

## 1. VM y red

- Ubuntu Server 22.04 · 2 vCPU · 2 GB · 60 GB. Bridge al lado **INTERNO**.
- Estática: `10.10.10.13/24`, gateway `10.10.10.1`, DNS `10.10.10.14`.

## 2. Servicios

```bash
sudo apt install -y nfs-kernel-server samba vsftpd openssh-server
```

NFS (`/etc/exports`) — solo M1, con trampa intencional:

```text
/srv/storage/wp-uploads  10.10.10.11(rw,sync,no_subtree_check)
/srv/storage/moodledata  10.10.10.11(rw,sync,no_subtree_check)
/srv/storage/backups     10.10.10.0/24(rw,sync,no_subtree_check,no_root_squash)  # B4 intencional
```

```bash
sudo exportfs -ra
```

Samba **4.5.10** (B1: SambaCry CVE-2017-7494) — fijar/compilar esa rama; recurso `[backups]` → `/srv/storage/backups`, con escritura anónima o invitado en la variante.

vsftpd **2.3.4** (B2: CVE-2011-2523, puerta `:)` → shell :6200) + `anonymous_enable=YES` (B3).

SSH: cuenta `backup` que recibe el rsync de M2.

## 3. Backups con secreto intencional (B3, documentado)

```bash
sudo mkdir -p /srv/storage/backups
# Los volcados llegan de M2 por rsync. Añadir (intencional):
echo "admin M4/M5: <CLAVE_DEBIL_COMUN>" | sudo tee /srv/storage/backups/credenciales.txt
sudo chmod 644 /srv/storage/backups/credenciales.txt   # legible vía FTP anónimo/SMB (intencional)
```

> Este archivo es el que permite el salto M3→M4→M5. Sin él no hay cadena: es carga útil del escenario, no descuido.

## 4. Firewall

```bash
sudo ufw allow from 10.10.10.11 to any port 2049 proto tcp   # NFS solo M1
sudo ufw allow 445,139,21/tcp                               # superficie vulnerable intencional
sudo ufw allow from 10.10.10.12 to any port 22 proto tcp    # rsync de M2
```

## 5. Tus vulnerabilidades

| ID | Qué fijar | Validación esperada |
|---|---|---|
| B1 | Samba 4.5.10 | PoC SambaCry (`is_known_pipename`) → shell |
| B2 | vsftpd 2.3.4 | Usuario con `:)` → conexión a :6200 → shell |
| B3 | FTP anónimo + `credenciales.txt` en claro | `ftp anonymous@10.10.10.13` → leer backups y claves |
| B4 | NFS `no_root_squash` en `backups` | Montar vía pivote y escribir como root |

## 6. Snapshots y entrega

- `estado-inicial-vulnerable`, `estado-parcheado` (Samba al día, vsftpd ≥3.x sin anon, backups cifrados sin secretos, `root_squash` en todo).
- Evidencia por B1–B4 + retest.
