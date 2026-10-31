# Revalidación de vulnerabilidades · versiones y artefactos

> Fecha: **2026-10-26**. Fuente: NVD/CVE.org + `guias/validacion-versiones.md` + logs `informe/evidencias/` + `artifacts/`.
> Regla: si la versión instalada es igual o mayor que la que corrige, el CVE **no se cuenta**.

## 1. Método

Para cada hallazgo se compara:

1. Versión real del servicio en el laboratorio.
2. Rango vulnerable según NVD.
3. Versión que corrige.
4. Artefacto descargado en `artifacts/`.
5. Precondición de configuración (CGI, prefork, SMB1, Spooler, etc.).
6. Estado de explotación.

Categorías:

| Categoría | Significado |
|---|---|
| **Válida** | La versión y la configuración permiten explotar; falta ejecutar o ya se validó. |
| **Válida con cambio** | La versión actual no explota, pero el artefacto o la configuración planificada sí. |
| **No reproducible** | El artefacto/versión actual no contiene la vulnerabilidad. |
| **No aplicable** | El sistema/versión no está afectado. |

## 2. Resumen

| Categoría | Cantidad | IDs |
|---|---|---|
| Válidas | 19 | W1, W4–W7, M1-SSH, D2–D4, B3–B5, S2–S5, C2–C4 |
| Válidas con cambio | 3 | W2, W3, B1 |
| No reproducibles | 2 | D1, B2 |
| No aplicables | 2 | S1, C1 |
| **Total** | **26** | 24 del inventario + M1-SSH + B5 |

> Las 24 del inventario original no incluían M1-SSH ni B5. Se agregan como hallazgos de configuración reales.

## 3. M1 · Aplicación

| ID | Servicio | Versión actual | Rango vulnerable | Corrige | Artefacto | ¿Reproduce? | Estado | Nota |
|---|---|---|---|---|---|---|---|---|
| W1 | WordPress | **7.0.1** | 6.9.0–6.9.4 / 7.0.0–7.0.1 | 6.9.5 / 7.0.2 | `vulnerable/wordpress-7.0.1.zip` | **Sí** | Válida; PoC pendiente | REST API + 5 posts; sin object cache |
| W2 | PHP | **8.4.26** | 8.4.x < 8.4.27 | 8.4.27 | `vulnerable/php-8.4.26.tar.gz` | **Sí, con cambio** | Válida con cambio | Hoy ZTS + event; recompilar NTS + prefork |
| W3 | Apache | **2.4.49** | 2.4.49 (41773); 2.4.50 (42013) | 2.4.50 / 2.4.51+ | `vulnerable/httpd-2.4.49.tar.gz` | **Sí, con cambio** | Válida con cambio | Hoy CGI 503; activar `mod_cgi` + `ScriptAlias` + `+ExecCGI` |
| W4 | WordPress admin | `usc.admin` / `Admin13.-` | config | clave fuerte + 2FA | — | **Sí** | Validada | Login 302 + cookie |
| W5 | Apache `mod_status` | `server-status` 200 | config | `Require ip 127.0.0.1` | — | **Sí** | Validada | — |
| W6 | `info.php` | 200 | config | borrar | — | **Sí** | Validada | — |
| W7 | `uploads` | `Index of` | config | `Options -Indexes` | — | **Sí** | Validada | — |
| M1-SSH | OpenSSH | `ubuntu` / `Admin13.-` + sudo | config | clave única + sudo restringido | — | **Sí** | Validada | Root en M1; pivote |

**Cambios necesarios:**

- W2: recompilar PHP **NTS** y cambiar a **prefork**; `upload_progress=On`, `display_errors=On`, `memory_limit=8M`.
- W3: activar CGI real; verificar `/cgi-bin/` 200/403, no 503.

## 4. M2 · Base de datos

| ID | Servicio | Versión actual | Rango vulnerable | Corrige | Artefacto | ¿Reproduce? | Estado | Nota |
|---|---|---|---|---|---|---|---|---|
| D1 | Redis | **6.2.6** compilado de fuente | paquete Debian/Ubuntu 5.0–5.0.14, 6.0–6.0.16, 6.2–6.2.6 | 5.0.15 / 6.0.17 / 6.2.7 | `vulnerable/redis-6.2.6.tar.gz` | **No** | No reproducible | CVE-2022-0543 es de empaquetado Debian; el build de fuente no enlaza Lua dinámicamente |
| D2 | MariaDB | **10.11.19** + `wp_pass123` | config | claves únicas + least privilege | — | **Sí** | Válida | 12 + 487 tablas |
| D3 | Puertos 3306/6379/161 | abiertos a la LAN | config | UFW solo M1 | — | **Sí** | Válida | 6379/161 abiertos |
| D4 | SNMP | `public` / `private` | config | SNMPv3/ACL | — | **Sí** | Válida | Lectura/escritura |

**Decisión D1:** si se quiere el 10.0, usar el paquete Debian/Ubuntu vulnerable (no descargado) o un contenedor `redis:6.2.6` basado en Debian. Si no, documentar la limitación y sostener M2 con D2/D3/D4. **No afirmar RCE de D1 con el build de fuente.**

## 5. M3 · Respaldos

| ID | Servicio | Versión actual | Rango vulnerable | Corrige | Artefacto | ¿Reproduce? | Estado | Nota |
|---|---|---|---|---|---|---|---|---|
| B1 | Samba | **4.5.10** (fix) | 3.5.0–4.6.3 / 4.5.0–4.5.9 / 4.4.0–4.4.13 | 4.6.4 / 4.5.10 / 4.4.14 | `vulnerable/samba-4.5.9.tar.gz` | **Sí, con cambio** | Válida con cambio | Instalar 4.5.9; 4.5.10 es el fix |
| B2 | vsftpd | **2.3.4 limpio** | tarball troyanizado 2011-06-30…07-03 | 2.3.4 limpio / 3.x | `vulnerable/vsftpd-2.3.4.tar.gz` | **No** | No reproducible | El tarball oficial no tiene backdoor; `:6200` cerrado |
| B3 | FTP anónimo | `anonymous` + `credenciales.txt` | config | anónimo off + cifrado | — | **Sí** | Validada | Entrega claves de M4/M5 |
| B4 | NFS | `no_root_squash` | config | `root_squash` | — | **Sí** | Validada | Escritura root desde M1 |
| B5 | OpenSSH | `rony123` / `rony123` | config | clave única | — | **Sí** | Válida | Tercera vuln de M3 si B2 se retira |

**Decisión B2:** retirar o documentar como no aplicable. No usar binarios troyanizados. B1 (4.5.9) + B3 + B4 + B5 dan profundidad suficiente.

## 6. M4 · Windows heredado

| ID | Servicio | Versión actual | Rango vulnerable | Corrige | Artefacto | ¿Reproduce? | Estado | Nota |
|---|---|---|---|---|---|---|---|---|
| S1 | SMBv1 | WS2016 14393; SMB1 **off** | WS2016 sin MS17-010 | MS17-010 + SMB1 off | — | **No aplicable tal como está** | No aplicable | Requiere SMB1 activo y build sin parche |
| S2 | Spooler | WS2016 14393; Spooler activo | builds bajo umbral | KB / Spooler off | — | **Sí, con cambio** | Válida con cambio | Requiere usuario limitado `soporte` + MSF local |
| S3 | Administrador | `password_2026` | config | clave larga/LAPS | — | **Sí** | Validada | `Pwn3d!`; shares |
| S4 | DNS AXFR | abierto | config | solo NS autorizados | — | **Sí** | Validada | Zona completa |
| S5 | SMB signing | off + LLMNR/NBT-NS | config | signing on + LLMNR off | — | **Sí** | Validada | Responder |

**Decisión S1:** no contar EternalBlue si SMB1 está off. Si se quiere demostrar, activar SMB1 y verificar `smb-vuln-ms17-010`; si el build tiene MS17-010, retirar. **S2 es el privesc obligatorio** y debe partir de `soporte`, no de Administrador.

## 7. M5 · Cliente

| ID | Servicio | Versión actual | Rango vulnerable | Corrige | Artefacto | ¿Reproduce? | Estado | Nota |
|---|---|---|---|---|---|---|---|---|
| C1 | SMBv1 | Win10 **19045** | solo 1507/1511/1607 | MS17-010 | — | **No aplicable** | No aplicable | 19045 no es vulnerable |
| C2 | Clave reutilizada | `cliente` / `Admin13.-` | config | clave única/LAPS | — | **Sí** | Validada | SMB por túnel |
| C3 | RDP | sin NLA | config | NLA on | — | **Sí** | Válida | Falta login RDP |
| C4 | TightVNC | **2.8.90** auth None | config | password + localhost | `vulnerable/tightvnc-2.8.90...msi` | **Sí** | Validada | Escritorio sin clave |

**Decisión C1:** retirar EternalBlue de M5. Sostener M5 con C2 + C3 + C4.

## 8. No reproducibles / no aplicables

| ID | Motivo | Evidencia | Acción |
|---|---|---|---|
| D1 | Redis de fuente no es el paquete Debian con Lua dinámico | `redis-server --version` 6.2.6; `enable_strict_lua` | Documentar; usar D2/D3/D4 o cambiar a paquete distro |
| B2 | Tarball limpio sin backdoor | `nc -zv 10.10.10.13 6200` cerrado | Retirar o documentar; usar B1/B3/B4/B5 |
| S1 | SMB1 off / build no vulnerable | `Get-WindowsOptionalFeature SMB1Protocol`; `nxc` SMBv1:None | Retirar o activar y verificar |
| C1 | Win10 19045 no afectado | `winver`; NVD CVE-2017-0144 | Retirar |

## 9. Cambios necesarios para que las válidas con cambio sean explotables

| ID | Cambio | Verificación |
|---|---|---|
| W2 | Recompilar PHP NTS + MPM prefork; `upload_progress=On`, `display_errors=On`, `memory_limit=8M` | `httpd -V \| grep prefork`; `php -i` |
| W3 | Activar `mod_cgi` + `ScriptAlias` + `Options +ExecCGI` | `curl /cgi-bin/` ≠ 503 |
| B1 | Instalar Samba 4.5.9 desde `artifacts/vulnerable/` | `smbd --version` = 4.5.9 |
| S2 | Crear `soporte` limitado + WinRM; usar MSF local | `whoami` = `srvold\soporte` antes; SYSTEM después |

## 10. Version gate final

| ID | Instalada | Fix | ¿Cumple? |
|---|---|---|---|
| W1 | 7.0.1 | 7.0.2 | Sí, vulnerable |
| W2 | 8.4.26 | 8.4.27 | Sí, vulnerable (con rebuild) |
| W3 | 2.4.49 | 2.4.51 | Sí, vulnerable (con CGI) |
| D1 | 6.2.6 fuente | 6.2.7 | No aplica al build |
| B1 | 4.5.10 | 4.5.10 | **No**: instalar 4.5.9 |
| B2 | 2.3.4 limpio | 2.3.4 limpio | No aplica |
| S1 | WS2016 | MS17-010 | No aplica (SMB1 off) |
| S2 | WS2016 | KB/off | Válido con `soporte` |
| C1 | 19045 | MS17-010 | No aplica |
| C4 | 2.8.90 | password | Válido |

## 11. Conclusión

- **22 hallazgos** son demostrables (19 ya + 3 con cambio).
- **2 no reproducibles** (D1, B2) y **2 no aplicables** (S1, C1) deben salir del conteo de profundidad.
- La cadena real recomendada es: **W1/W4 → M1-SSH → D2/D3/D4 → B3/B4/B5 → S3/S4/S5 + S2 → C2/C3/C4**.
- W2/W3/B1 se demuestran si se aplican los cambios de §9.
- La nota de criticidad se sostiene con **W1 9.8** y **W2/W3 9.8**; D1 10.0 queda como limitación documentada.
- Flujo concreto por vulnerabilidad: [`specs/005-fase-4-validacion-explotacion/vulns/`](../specs/005-fase-4-validacion-explotacion/vulns/).
