# Fase 5 · Impacto y anti-forense controlado

**Objetivo:** demostrar el impacto real (marcadores, lectura de datos, control) y documentar la capacidad anti-forense **sin destruir evidencia**.
**Estado:** ⚠️ parcial; M1–M3 disponibles, M4/M5 apagadas.
**Regla:** en el informe oficial solo va el impacto. La técnica de borrado de huellas queda en este anexo interno y se prueba sobre un log de prueba, no sobre logs reales.

---

## 5.1 Impacto por servidor

| Servidor | Qué se demuestra | Comando/acción | Estado |
|---|---|---|---|
| M1 | Archivo marcador en uploads | `sudo -u www-data sh -c 'echo PWNED-M1 ... > .../uploads/PWNED-M1.txt'` | ✅ `F05-002` |
| M1 | Lectura de configuración | `wp-config.php` (ya hecho) | ✅ `F04-004` |
| M2 | Muestra de BD | `SELECT COUNT(*)` / 5 filas de `wp_users` | ⬜ |
| M2 | Datos de Redis | `DBSIZE`, `KEYS *` | ✅ `F04-001b` |
| M3 | Descarga de backup | `curl ftp://.../wordpress-2026-10-24.sql.gz -o /tmp/...` | ⬜ |
| M3 | Credenciales | `credenciales.txt` | ✅ `F04-002` |
| M4 | `whoami` SYSTEM + marcador | Tarea `SYSTEM` vía WinRM; `PWNED-M4.txt` en `LegacyShare` | ✅ `F04-017`, `F05-003b` |
| M5 | Marcador en escritorio | `echo PWNED-M5 %DATE% %TIME% > C:\Users\cliente\Desktop\PWNED-M5.txt` | ✅ `F05-001` |
| M5 | Escritorio VNC | `vncviewer 10.10.10.15` | ✅ `F04-009` |
| M5 | Consola remota | `whoami` → `desktop-dt5f05n\cliente` | ✅ `F04-011` |

---

## 5.2 Comandos demo (simples)

```bash
# M1: marcador visible por W7
echo "PWNED-M1 $(date -u)" | sudo tee /var/www/wp/wp-content/uploads/PWNED-M1.txt
curl -s http://wp.uni.lab/wp-content/uploads/PWNED-M1.txt

# M2: conteo de usuarios
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' \
  -e 'SELECT COUNT(*) FROM wordpress.wp_users;'

# M3: descarga de un backup
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt
```

**Evidencia:** captura del archivo/marcador y `sha256sum` del archivo descargado.

---

## 5.3 Logs: qué se puede leer (sin borrar)

| Servidor | Log | Comando |
|---|---|---|
| M1 | Apache access/error | `sudo tail -5 /usr/local/apache2/logs/wp-access_log` |
| M1 | SSH/auth | `sudo tail -5 /var/log/auth.log` |
| M2 | Redis | `sudo tail -5 /var/log/redis/redis-server.log` |
| M3 | vsftpd/Samba | `sudo tail -5 /var/log/vsftpd.log`; `sudo tail -5 /usr/local/samba/var/log.smbd` |
| M4 | Security/System | `wevtutil qe Security /c:5 /rd:true /f:text` |
| M5 | Security/System | `Get-WinEvent -LogName Security -MaxEvents 5` |

**Lectura:** el atacante puede leer los logs; eso ya es impacto. No se borran.

---

## 5.4 Anti-forense (solo anexo interno)

**Qué se documenta:** la capacidad de borrar un log **de prueba** y su efecto, dentro de un snapshot, y luego restaurar.

```bash
# En una VM de prueba, NO en logs reales:
echo "linea de prueba $(date -u)" | sudo tee /tmp/log-de-prueba.log
sudo truncate -s 0 /tmp/log-de-prueba.log
ls -l /tmp/log-de-prueba.log
```

**Qué NO se hace:** no se borran `auth.log`, `wp-access_log`, logs de M4/M5, ni backups. No se usa ransomware ni se destruyen datos.

**Para el informe oficial:** solo se menciona el impacto (“el atacante puede leer/alterar logs”) y la recomendación (centralizar logs, WORM, SIEM). La receta queda aquí.

---

## 5.5 Cierre

- [ ] Marcador M1 y captura.
- [ ] Conteo/volcado M2 y hash.
- [ ] Backup M3 y hash.
- [ ] `whoami` SYSTEM y marcador M4.
- [ ] Marcador/escritorio M5.
- [ ] Logs leídos, no borrados.
- [ ] Snapshot restaurado tras la prueba.
