# Guía de retest · verificar que el parchado funciona

> Objetivo: demostrar, con los **mismos comandos** que antes funcionaban, que
> después del parche los saltos fallan (incluido el opcional M4).
> Regla: se restaura `estado-inicial`, se parchea y se retesta. **No** se parchea
> una máquina comprometida.

---

## 0. Preparación

1. Restaurar el snapshot `estado-inicial` en M1–M5.
2. Aplicar los scripts de `lab/patch/` (ver `lab/patch/README.md`).
3. Confirmar que los servicios están arriba:

```bash
# en cada VM Linux
systemctl is-active apache-lab nginx redis-lab nfs-kernel-server 2>/dev/null
# Windows
Get-Service Spooler, LanmanServer | Select Name,Status
```

4. Desde M6, comprobar conectividad base:

```bash
bash lab/tests/smoke.sh
```

Si `smoke.sh` falla porque M4 ya no tiene SMB1 o M5 ya no abre 5900, **es correcto**:
esos puertos dejan de ser parte del escenario vulnerable. Anótalo.

---

## 1. Matriz antes / después

| Salto | Antes (vulnerable) | Después (parcheado) |
|---|---|---|
| 1 · M1 | PHP 8.4.26, `upload_progress=On`, sink responde 200 | PHP 8.4.27, `upload_progress=Off`, sink 404 |
| 2 · M2 | Redis 6.2.6 sin auth, como root, 0.0.0.0 | Redis 6.2.7 con `requirepass`, usuario `redis`, 127.0.0.1 |
| 3 · M3 | NFS `no_root_squash` + cron root | NFS `root_squash`, sin cron ni `rotate.sh` |
| 4 · M4 | SMB1 activo + Spooler activo | SMB1 off + Spooler detenido |
| 5 · M5 | VNC sin auth en 5900 + RDP sin NLA | VNC loopback + auth, RDP con NLA, 5900 cerrado |

---

## 2. Retest automático

Desde M6:

```bash
bash lab/patch/retest.sh
```

Salida esperada (5 PASS, 0 FAIL):

```text
[PASS] M1: sink LFI 404
[PASS] M1: PHP/8.4.27
[PASS] M2: Redis exige autenticación
[PASS] M3: export sin no_root_squash
[PASS] M3: cron sobre el export eliminado
[PASS] M4: SMB1 deshabilitado
[PASS] M5: VNC sin None (o 5900 cerrado)
```

Si algo da FAIL, usa la sección manual del salto correspondiente.

---

## 3. Retest manual por salto

### 3.1 Salto 1 · M1

```bash
# antes: PHP/8.4.26 y sink 200
# después:
/usr/local/bin/php -v                       # 8.4.27
/usr/local/bin/php -i | grep upload_progress
# session.upload_progress.enabled => Off

curl -k -o /dev/null -w '%{http_code}\n' \
  'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=default.php'
# 404

curl -ksI https://wp.uni.lab/ | grep -i x-powered-by
# X-Powered-By: PHP/8.4.27
```

El PoC de `01` debe fallar en el primer paso:

```bash
bash lab/chain/01-m1-php2shell.sh --run
# sin 'uid='; el sink no existe
```

### 3.2 Salto 2 · M2

```bash
redis-cli -h 10.10.10.12 PING
# (error) NOAUTH Authentication required

redis-cli -h 10.10.10.12 -a 'UniRedis2026!' --no-auth-warning PING
# PONG

redis-cli -h 10.10.10.12 --no-auth-warning CONFIG SET dir /tmp
# (error) NOAUTH

# en M2:
ss -lnt | grep 6379        # 127.0.0.1:6379
systemctl show -p User redis-lab   # User=redis
```

El ataque de `02` ya no puede escribir `authorized_keys`:

```bash
bash lab/chain/02-m1-to-m2.sh --run
# falla en el PING sin auth
```

### 3.3 Salto 3 · M3

```bash
ssh -i ~/lab-work/id_lab root@10.10.10.13 'exportfs -v'
# root_squash, sin no_root_squash

ssh -i ~/lab-work/id_lab root@10.10.10.13 'ls /srv/storage/backups; cat /etc/cron.d/lab-rotate'
# sin rotate.sh y sin cron

# desde M2: montar y comprobar que root ya no manda
ssh -i ~/lab-work/id_lab root@10.10.10.12 \
  'mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/bkp 2>/dev/null; touch /mnt/bkp/x 2>&1'
# Permission denied
```

### 3.4 Salto 4 · M4 (Windows)

En M4, consola elevada:

```powershell
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Select State
# Disabled (o DisablePending: reiniciar)

(Get-SmbServerConfiguration).EnableSMB1Protocol
# False

Get-Service Spooler | Select Status,StartType
# Stopped, Disabled
```

Desde M6:

```bash
nmap -Pn -p445 --script smb-protocols 10.10.10.14 | grep -i smb
# sin SMBv1

smbclient //10.10.10.14/Transfer -N -c 'ls'
# NT_STATUS_ACCESS_DENIED (SMB anónimo cerrado)
```

El salto con PrintNightmare debe fallar; si el Spooler está detenido, el módulo
no tiene servicio que explotar.

### 3.5 Salto 5 · M5 (Windows)

En M5, consola elevada:

```powershell
$rdp='HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
(Get-ItemProperty $rdp -Name UserAuthentication).UserAuthentication
# 1 (NLA obligatorio)

Get-ItemProperty 'HKLM:\SOFTWARE\TightVNC\Server' -Name AllowOnlyLoopbackConnections
# 1

Get-NetFirewallRule -DisplayName 'LAB-M5-VNC-5900' -ErrorAction SilentlyContinue
# no debe existir
```

Desde M6:

```bash
nmap -Pn -p5900 --script vnc-info 10.10.10.15
# 5900 cerrado o Authentication != None

vncviewer 10.10.10.15
# no conecta
```

---

## 4. Evidencias del retest

| ID | Qué demuestra |
|---|---|
| `LOG-PATCH-M1.txt` … `LOG-PATCH-M5.txt` | salida de cada script de parchado |
| `LOG-RETEST.txt` | salida de `lab/patch/retest.sh` |
| `EV-RETEST-01.png` | sink 404 y `PHP/8.4.27` |
| `EV-RETEST-02.png` | `NOAUTH` en Redis |
| `EV-RETEST-03.png` | `exportfs -v` con `root_squash` |
| `EV-RETEST-04.png` | SMB1 `Disabled` y Spooler `Stopped` |
| `EV-RETEST-05.png` | VNC sin `None` / 5900 cerrado |

Captura recomendada: terminal con el comando y la salida, hora UTC visible.
Después: `sha256sum` de logs e imágenes.

---

## 5. Qué cuenta como “parcheado”

| Sí cuenta | No cuenta |
|---|---|
| Versión corregida instalada y verificada | Bloquear una URL en el WAF |
| Directiva que elimina el vector (`upload_progress=Off`) | Renombrar el plugin |
| Servicio detenido que elimina el vector (Spooler) | Solo cerrar el puerto |
| NFS con `root_squash` | Montar el export en solo lectura |
| VNC loopback + auth | Cambiar el puerto 5900 |

Si solo se bloqueó una ruta, se declara como **mitigación**, no como parche.

---

## 6. Problemas típicos

| Síntoma | Causa | Solución |
|---|---|---|
| Sink sigue 200 | no se reinició Apache o no se borró el plugin | `systemctl restart apache-lab`; `ls /var/www/wp/wp-content/plugins` |
| PHP sigue 8.4.26 | `make install` no reemplazó `libphp.so` | revisar `php -v` y `apachectl -M | grep php` |
| Redis sigue sin auth | unidad vieja o config no aplicada | `systemctl cat redis-lab`; `redis-cli CONFIG GET requirepass` |
| `exportfs` sigue `no_root_squash` | no se recargó | `exportfs -ra`; `cat /etc/exports` |
| SMB1 `DisablePending` | falta reinicio | reiniciar M4 y repetir |
| Spooler vuelve a arrancar | otra política/servicio lo inicia | `Set-Service Spooler -StartupType Disabled` |
| VNC sigue abierto | regla de firewall o servicio | `Get-NetFirewallRule`; `Get-Service tvnserver` |
| `retest.sh` no ve M2 | M2 apagada o 6379 filtrado | es esperado si Redis es loopback; valida en M2 |

---

## 7. Cierre

1. `lab/patch/retest.sh` → **0 FAIL**.
2. Guardar logs, capturas y SHA256.
3. Tomar snapshot **`estado-parcheado`** en M1–M5.
4. En la réplica: mostrar primero el ataque (snapshot vulnerable) y luego el
   retest (snapshot parcheado), con los mismos comandos.
