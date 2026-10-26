# Spec 006 · Fase 5 · Remediación

## Metadata

| Campo | Valor |
|---|---|
| ID | `006` |
| Fase guía | 5 |
| Nombre | Remediación por versión, configuración o mitigación |
| Estado | `lista` |
| Dueño | Cada dueño de VM |
| Dependencias | `000`, `005` |
| Specs relacionadas | `007` |
| Fuente | Guía §8 Fase 5 y §11; `docs/PLAN-MAESTRO.md` §4 |

## 1. Propósito

Aplicar la medida correcta a cada hallazgo, registrar el cambio y dejar el laboratorio en `estado-parcheado`, listo para el retest.

## 2. Alcance

**Incluye:** actualización de versión, reconfiguración segura, mitigación compensatoria, registro de cambios y snapshot final.

**No incluye:** retest (Fase 6), nuevos exploits.

## 3. Actores y precondiciones

- Actores: dueños M1–M5, coordinador, auditor.
- Precondiciones: Fase 4 cerrada; evidencia guardada; `estado-inicial-vulnerable` disponible.

## 3.1 Version gate de remediación

| ID | Fix | Artefacto |
|---|---|---|
| W1 | 7.0.2 | `fixed/wordpress-7.0.2.zip` |
| W2 | 8.4.27 | `fixed/php-8.4.27.tar.gz` |
| W3 | 2.4.51+ | `fixed/httpd-2.4.51.tar.gz` |
| D1 | 6.2.7+ | `fixed/redis-6.2.7.tar.gz` |
| B1 | 4.5.10+ | `fixed/samba-4.5.10.tar.gz` |
| B2 | 3.0.5 | `fixed/vsftpd-3.0.5.tar.gz` |
| S2 | KB / Spooler off | Windows Update |
| C4 | password/localhost | TightVNC config |

## 4. Requisitos EARS

### Reglas generales

- **REQ-006-01 (Evento).** CUANDO se inicie la remediación, el laboratorio DEBE restaurar `estado-inicial-vulnerable` y NO parchear el estado comprometido.
  - Verificación: `Snapshot Manager`.
- **REQ-006-02 (Ubicuo).** Cada hallazgo DEBE tener una medida aplicada, una versión/configuración final y un registro de cambio.
  - Verificación: tabla de cambios.
- **REQ-006-03 (No deseado).** SI no existe parche de versión, ENTONCES el laboratorio DEBE aplicar una mitigación compensatoria y documentar el riesgo residual.
  - Verificación: ficha del hallazgo.
- **REQ-006-04 (Evento).** CUANDO se termine la remediación, el laboratorio DEBE tomar `estado-parcheado`.
  - Verificación: `Snapshot Manager`.

### M1

- **REQ-006-05 (Ubicuo).** WordPress DEBE actualizarse a **7.0.2+** y eliminar administradores/plugins no autorizados.
  - Verificación: `wp core version`; `wp user list`.
- **REQ-006-06 (Ubicuo).** PHP DEBE actualizarse a **8.4.27+**; como mitigación temporal, `session.upload_progress.enabled=Off`.
  - Verificación: `php -v`; `php -i`.
- **REQ-006-07 (Ubicuo).** Apache DEBE actualizarse a **2.4.51+** y denegar `/cgi-bin/` si no se usa.
  - Verificación: `httpd -v`; `curl` 403/404.
- **REQ-006-08 (Ubicuo).** W4 y M1-SSH DEBEN tener claves únicas, 2FA/límite de intentos y sudo restringido.
  - Verificación: login viejo falla; `sudo` no escala.
- **REQ-006-09 (Ubicuo).** W5/W6/W7 DEBEN quedar restringidos, borrados o sin `+Indexes`.
  - Verificación: 403/404.

### M2

- **REQ-006-10 (Ubicuo).** Redis DEBE estar en **6.2.7+**, con `requirepass`, `bind 127.0.0.1` y `protected-mode yes`.
  - Verificación: `PING` → `NOAUTH`.
- **REQ-006-11 (Ubicuo).** MariaDB DEBE tener claves únicas y least privilege; M1 DEBE actualizar `wp-config.php` y Moodle.
  - Verificación: login viejo falla.
- **REQ-006-12 (Ubicuo).** 3306/6379/161 DEBEN quedar filtrados desde M6.
  - Verificación: `nmap` → `filtered`.
- **REQ-006-13 (Ubicuo).** SNMP DEBE usar SNMPv3/ACL y eliminar `public`/`private`.
  - Verificación: `snmpwalk` con `public` falla.

### M3

- **REQ-006-14 (Ubicuo).** Samba DEBE estar en **4.5.10+** y SMB1 off.
  - Verificación: `smbd --version`; `smb-vuln*` limpio.
- **REQ-006-15 (Ubicuo).** vsftpd DEBE ser limpio/3.x, con anónimo off.
  - Verificación: `:6200` cerrado; `530`.
- **REQ-006-16 (Ubicuo).** Los backups DEBEN estar cifrados y sin `credenciales.txt` en claro.
  - Verificación: inspección del share.
- **REQ-006-17 (Ubicuo).** NFS DEBE usar `root_squash` en todas las exportaciones.
  - Verificación: escritura root denegada.
- **REQ-006-18 (Ubicuo).** SSH DEBE tener clave única y sin reutilización.
  - Verificación: `rony123` falla.

### M4

- **REQ-006-19 (Ubicuo).** M4 DEBE tener MS17-010 y SMB1 off.
  - Verificación: `smb-vuln-ms17-010` limpio.
- **REQ-006-20 (Ubicuo).** PrintNightmare DEBE estar parcheado o el Spooler deshabilitado.
  - Verificación: `Get-Service Spooler`; PoC falla.
- **REQ-006-21 (Ubicuo).** Administrator DEBE tener clave larga/LAPS; `soporte` DEBE eliminarse o tener clave fuerte.
  - Verificación: `nxc` denegado.
- **REQ-006-22 (Ubicuo).** AXFR DEBE estar restringido, SMB signing ON y LLMNR/NBT-NS OFF.
  - Verificación: `dig axfr` → `REFUSED`; signing required.

### M5

- **REQ-006-23 (Ubicuo).** M5 DEBE estar parcheado, SMB1 off y clave única.
  - Verificación: `smb-vuln*` limpio; `nxc` denegado.
- **REQ-006-24 (Ubicuo).** RDP DEBE tener NLA y VNC contraseña/localhost/firewall o estar desinstalado.
  - Verificación: NLA requerido; VNC pide clave.

## 5. Criterios de aceptación

- [ ] Artefactos corregidos instalados desde `artifacts/fixed/`.
- [ ] `estado-inicial-vulnerable` restaurado antes de parchear.
- [ ] Cada hallazgo con medida y versión/config final.
- [ ] WP/PHP/Apache/Redis actualizados.
- [ ] Configuraciones inseguras cerradas.
- [ ] `estado-parcheado` tomado.
- [ ] Registro de cambios completo.
- [ ] Version gate: versión final igual o mayor que la que corrige.

## 6. Trazabilidad

| REQ | Evidencia | Tarea |
|---|---|---|
| REQ-006-05–09 | `EV-006-M1-*` | T-006-01–04 |
| REQ-006-10–13 | `EV-006-M2-*` | T-006-05–07 |
| REQ-006-14–18 | `EV-006-M3-*` | T-006-08–10 |
| REQ-006-19–22 | `EV-006-M4-*` | T-006-11–13 |
| REQ-006-23–24 | `EV-006-M5-*` | T-006-14–15 |

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| La actualización rompe la app | Snapshot; probar en clon |
| PHP 8.4.27 no compila | Mitigación temporal `upload_progress=Off` |
| Apache 2.4.51+ rompe CGI | Denegar `/cgi-bin/` |
| Redis 6.2.7+ no está en repo | Compilar o usar paquete con backport |
| M4 inestable | Snapshot; cambio con VM apagada |

## 8. Fuera de alcance

- Retest.
- Nuevos exploits.
- Cambios de arquitectura.
