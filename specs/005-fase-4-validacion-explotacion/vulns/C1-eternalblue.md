# C1 · EternalBlue en M5 · CVE-2017-0144

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M5 `10.10.10.15` |
| Servicio | SMBv1 |
| Sistema | Windows 10 **19045** (22H2) |
| Rango vulnerable | Win10 1507/1511/1607; **no 19045** |
| Versión que corrige | MS17-010 |
| CVSS | **8.8** v3.1 |
| CWE | CWE-94 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2017-0144 |
| Estado | **No aplicable** |

## 2. Por qué no aplica

CVE-2017-0144 afecta a Windows 10 Gold/1511/1607 y Windows Server 2016. **Windows 10 19045 no es vulnerable**, aunque SMBv1 esté activado.

Evidencia:

```powershell
winver
# Versión 22H2 (19045)
```

```bash
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.15
```

## 3. Alternativa

M5 se sostiene con:

- **C2**: clave reutilizada `cliente` / `Admin13.-`.
- **C3**: RDP sin NLA.
- **C4**: VNC sin clave.

## 4. Evidencia de la limitación

- `EV-C1-01`: `winver` 19045.
- `EV-C1-02`: `smb-vuln-ms17-010` sin confirmación.
- `LOG-C1`.

## 5. Remediación

- Mantener Windows Update.
- SMBv1 off.
- No contar C1 como profundidad.

## 6. Retest

```bash
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.15  # limpio/no aplica
```

## 7. EARS

- **REQ-C1-01 (No deseado).** SI M5 es Windows 10 19045, ENTONCES el laboratorio NO DEBE declarar EternalBlue.
- **REQ-C1-02 (Ubicuo).** La limitación DEBE documentarse y M5 DEBE sostener C2/C3/C4.

## 8. Checklist

- [ ] `winver` 19045.
- [ ] `smb-vuln-ms17-010` ejecutado.
- [ ] Limitación documentada.
- [ ] Alternativa C2/C3/C4.
