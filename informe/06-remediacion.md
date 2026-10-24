# 7. Remediación

**Estado:** propuesta y registro de cambios. Las marcas 🟢/⬜ indican si ya se aplicó y verificó.

> Regla: cada cambio se aplica sobre `estado-inicial-vulnerable`, se prueba y se guarda `estado-parcheado`. No se declara “parcheado” sin retest.

---

## 7.1 M1 · Aplicación

| ID | Medida | Comando/acción | Estado |
|---|---|---|---|
| W1 | WordPress 7.0.2+ | `wp core update --version=7.0.2`; revisar plugins/usuarios | ⬜ |
| W2 | PHP ≥ 8.4.27 | Recompilar/instalar 8.4.27 y reiniciar Apache; temporal `session.upload_progress.enabled=0` | ⬜ |
| W3 | Apache ≥ 2.4.50 | Actualizar o `Require all denied` en `/cgi-bin/` | ⬜ |
| W4 | Clave fuerte + 2FA | Cambiar `usc.admin`; límite de intentos; 2FA | ⬜ |
| W5 | `server-status` restringido | `Require ip 127.0.0.1` o desactivar `mod_status` | ⬜ |
| W6 | Borrar `info.php` | `sudo rm /var/www/wp/info.php` | ⬜ |
| W7 | `Options -Indexes` | En `lab-vhosts.conf`, quitar `+Indexes` de uploads | ⬜ |
| M1-SSH | Clave única y sudo restringido | `passwd ubuntu`; `PermitRootLogin no`; revisar `sudoers` | ⬜ |

**Verificación:** `wp core version` 7.0.2; `php -v` 8.4.27; `httpd -v` 2.4.50; W5/W6/W7 → 403/404; login viejo falla.

---

## 7.2 M2 · Base de datos

| ID | Medida | Comando/acción | Estado |
|---|---|---|---|
| D1 | Redis 6.2.7+ + `requirepass` + `bind 127.0.0.1` | `requirepass <fuerte>`; `bind 127.0.0.1`; `protected-mode yes` | ⬜ |
| D2 | Claves únicas y least privilege | `ALTER USER ... IDENTIFIED BY ...`; limitar GRANT | ⬜ |
| D3 | Firewall solo M1 | `ufw allow from 10.10.10.11 to any port 3306`; cerrar 6379 | ⬜ |
| D4 | SNMPv3/ACL | Communities largas o `snmpv3`; `rocommunity` con ACL | ⬜ |

**Verificación:** `redis-cli PING` → `NOAUTH`; `nmap` → 3306/6379/161 filtrados desde M6.

---

## 7.3 M3 · Respaldos

| ID | Medida | Comando/acción | Estado |
|---|---|---|---|
| B1 | Samba soportado/parcheado | Actualizar a rama soportada; SMB1 OFF | ⬜ |
| B2 | Retirar vsftpd 2.3.4 | Desinstalar o reemplazar por ≥3.x sin anónimo | ⬜ |
| B3 | Anónimo OFF + backups cifrados | `anonymous_enable=NO`; GPG/age; sacar `credenciales.txt` | ⬜ |
| B4 | `root_squash` | `/etc/exports` con `root_squash`; `exportfs -ra` | ⬜ |

**Verificación:** `:6200` cerrado; `530 Login incorrect`; `showmount` sin `no_root_squash`; escritura root denegada.

---

## 7.4 M4 · Windows Server

| ID | Medida | Comando/acción | Estado |
|---|---|---|---|
| S1 | MS17-010 + SMBv1 OFF | Windows Update; `Disable-WindowsOptionalFeature -FeatureName SMB1Protocol` | ⬜ |
| S2 | PrintNightmare + Spooler | Parche; `Set-Service Spooler -StartupType Disabled` si no se imprime | ⬜ |
| S3 | Clave única / LAPS | `net user Administrator <fuerte>`; LAPS | ⬜ |
| S4 | AXFR restringido | DNS → Transferencias → solo NS autorizados | ⬜ |
| S5 | Signing ON + LLMNR/NBT-NS OFF | `Set-SmbServerConfiguration -RequireSecuritySignature $true`; GPO | ⬜ |

**Verificación:** `smb-vuln-ms17-010` limpio; `smb-security-mode` signing required; `dig axfr` REFUSED; `nxc` denegado.

---

## 7.5 M5 · Estación cliente

| ID | Medida | Comando/acción | Estado |
|---|---|---|---|
| C1 | Parches + SMBv1 OFF | Windows Update; deshabilitar SMB1 | ⬜ |
| C2 | Clave única / LAPS | Cambiar `cliente`; no reutilizar | ⬜ |
| C3 | NLA + software al día | `UserAuthentication=1`; actualizar Firefox/Office | ⬜ |
| C4 | VNC con clave + localhost/firewall o desinstalar | TightVNC → password; `localhost`; regla; o desinstalar | ⬜ |

**Verificación:** VNC pide clave; `445 filtered`; RDP con NLA; credencial vieja falla.

---

## 7.6 M6 / R0

| Elemento | Medida | Estado |
|---|---|---|
| M6 | Cerrar `eth2` durante la explotación; limpiar artefactos; conservar logs | ⬜ |
| R0 | DHCP OFF, sin DSL, WPA2, UPnP/WPS OFF | ✅ según guía; verificar foto |

---

## 7.7 Registro de cambios

| Fecha UTC | Máquina | Cambio | Versión/config final | Responsable | Evidencia |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

> Completar al aplicar cada parche. La tabla es la fuente para la sección 7 del informe y para el retest.
