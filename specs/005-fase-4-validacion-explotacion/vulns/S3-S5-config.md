# S3–S5 · Configuraciones de M4

## 1. Ficha

| ID | Servicio | Configuración | CWE | CVSS |
|---|---|---|---|---|
| S3 | Administrador | `Administrador` / `password_2026` | CWE-521 + CWE-269 | ~8.8 |
| S4 | DNS | AXFR abierto | CWE-200 | ~5.3 |
| S5 | SMB | signing off + LLMNR/NBT-NS | CWE-319 | ~7.5 |

## 2. Flujo

1. Snapshot M4: `previo-a-S3`.
2. S3:

```bash
nxc smb 10.10.10.14 -u Administrador -p 'password_2026' --shares
nxc smb 10.10.10.14 -u Administrador -p 'password_2026' -x whoami
```

> `-x whoami` con admin devuelve `nt authority\system` porque el servicio corre como SYSTEM. **No es privesc**; es ejecución con credenciales administrativas. El privesc real es S2 desde `soporte`.

3. S4:

```bash
dig axfr uni.lab @10.10.10.14 +short
```

4. S5:

```bash
nmap -sT --script smb-security-mode -p 445 10.10.10.14
```

## 3. Resultado esperado

```text
S3: Pwn3d! / shares ADMIN$, C$, legacy
S4: app.uni.lab, db.uni.lab, bkp.uni.lab, ...
S5: signing:False / message_signing: disabled
```

## 4. Evidencia

- `EV-S3-01`: `Pwn3d!` y shares.
- `EV-S4-01`: AXFR.
- `EV-S5-01`: `smb-security-mode`.
- `LOG-M4`.

## 5. Impacto y siguiente salto

- S3: acceso administrativo a M4.
- S4: inventario completo de la red.
- S5: captura/relay de hash NetNTLM con Responder.

## 6. Remediación

```powershell
# S3
net user Administrador "M4_Admin_2026!"
# LAPS

# S4
# DNS → zona uni.lab → Transferencias → solo NS autorizados

# S5
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
# GPO: LLMNR/NBT-NS OFF
```

## 7. Retest

```bash
nxc smb 10.10.10.14 -u Administrador -p 'password_2026' --shares  # falla
dig axfr uni.lab @10.10.10.14                                     # REFUSED
nmap -sT --script smb-security-mode -p 445 10.10.10.14            # signing required
```

## 8. EARS

- **REQ-S3-01 (Evento).** CUANDO se valide S3, el laboratorio DEBE capturar `Pwn3d!` y los shares.
- **REQ-S4-01 (Evento).** CUANDO se valide S4, el laboratorio DEBE capturar la zona completa.
- **REQ-S5-01 (Evento).** CUANDO se valide S5, el laboratorio DEBE capturar `signing:False`.
- **REQ-S3S5-02 (Ubicuo).** La remediación DEBE invalidar la clave, restringir AXFR y exigir signing.

## 9. Checklist

- [ ] Snapshot `previo-a-S3`.
- [ ] S3 acceso.
- [ ] S4 AXFR.
- [ ] S5 signing.
- [ ] Remediación.
- [ ] Retest.
