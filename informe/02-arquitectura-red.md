# 3. Arquitectura del entorno

**Red:** `10.10.10.0/24` · WiFi `LAB-INT` · router MitraStar `10.10.10.1` · DHCP OFF · sin salida a Internet durante la explotación.
**Modelo:** una sola puerta (M1:80) + separación lógica por firewall de host + pivote desde M1 hacia M2–M5.

---

## 3.1 Diagrama lógico

```text
                         ┌──────────────────────────────┐
                         │ R0 MitraStar 10.10.10.1      │
                         │ transporte · DHCP OFF · sin DSL │
                         └──────────────┬───────────────┘
                                        │ LAN 10.10.10.0/24
        ┌───────────────┬───────────────┼───────────────┬───────────────┐
        │               │               │               │               │
   ┌────▼────┐     ┌────▼────┐     ┌────▼────┐     ┌────▼────┐     ┌────▼────┐
   │ M6 Kali │     │ M1 App  │     │ M2 DB   │     │ M3 BKP  │     │ M4 Win  │
   │ .20     │     │ .11     │     │ .12     │     │ .13     │     │ .14     │
   │ auditor │     │ PUERTA  │     │ MariaDB │     │ NFS/SMB │     │ WS2016  │
   └─────────┘     │ 80/443  │     │ Redis   │     │ FTP     │     │ DNS/SMB │
                   └────┬────┘     └─────────┘     └─────────┘     └────┬────┘
                        │                                              │
                        │ pivote                                       │
                        └──────────────────────────────────────────────┘
                                   M5 Win10 .15 (cliente)
```

> El diagrama editable está en `../arquitectura-universitaria.drawio`; la vista previa en `../arquitectura-universitaria.png`.

---

## 3.2 Inventario y roles

| VM | Rol | IP | Hostname | FQDN | SO / servicio principal | Responsable |
|---|---|---|---|---|---|---|
| M1 | Servidor de aplicación | `10.10.10.11` | `app01` | `app.uni.lab` (`wp`, `moodle`) | Ubuntu 22.04 · Apache 2.4.49 · PHP 8.4.26 · WP 7.0.1 · Moodle 5.0.11 | Estudiante 1 |
| M2 | Servidor de base de datos | `10.10.10.12` | `db01` | `db.uni.lab` | Ubuntu 22.04 · MariaDB 10.11.19 · Redis 6.2.6 · SNMP | Estudiante 2 |
| M3 | Servidor de respaldos | `10.10.10.13` | `bkp01` | `bkp.uni.lab` | Ubuntu 22.04 · NFS · Samba 4.5.10 · vsftpd 2.3.4 | Estudiante 3 |
| M4 | Windows Server heredado | `10.10.10.14` | `SRVOLD` | `srvold.uni.lab` | WS2016 sin parches · DNS · SMBv1 · Spooler | Estudiante 4 |
| M5 | Estación de trabajo | `10.10.10.15` | `PC-EST01` | `pc-est01.uni.lab` | Win10 21H2 · SMBv1 · RDP sin NLA · TightVNC | Estudiante 5 |
| M6 | Kali / auditoría | `10.10.10.20` | `kali01` | `kali.uni.lab` | Kali Linux · nmap, wpscan, nxc, redis-cli, etc. | Estudiante 6 |
| R0 | Router / transporte | `10.10.10.1` | — | — | MitraStar DSL-2401HN-T1C | Coordinador |

---

## 3.3 Direccionamiento y DNS

| Registro | Tipo | Valor |
|---|---|---|
| `app.uni.lab` | A | `10.10.10.11` |
| `wp.uni.lab` | CNAME → `app.uni.lab` | `10.10.10.11` |
| `moodle.uni.lab` | CNAME → `app.uni.lab` | `10.10.10.11` |
| `db.uni.lab` | A | `10.10.10.12` |
| `bkp.uni.lab` | A | `10.10.10.13` |
| `srvold.uni.lab` | A | `10.10.10.14` |
| `pc-est01.uni.lab` | A | `10.10.10.15` |

**Verificación real 2026-10-24:** los registros A y CNAME resuelven correctamente desde M6. Las consultas `SOA`/`NS` a `10.10.10.14` dieron *timeout* (ver `F01-002`); se documenta como limitación del DNS de M4 y se reintenta con `+tcp`/`dig axfr` en la fase de enumeración.

---

## 3.4 Puertos y superficie real

| Destino | Puertos esperados | Estado real desde M6 (2026-10-24) | Observación |
|---|---|---|---|
| M1 `.11` | 80, 443, 22 | **80 open, 22 open, 443 closed** | La puerta real es HTTP; 443 no está publicado |
| M2 `.12` | 3306, 6379, 161 | **6379 open; 3306 filtered; 161 filtered** | Redis expuesto a la LAN; MySQL/SNMP solo vía M1 |
| M3 `.13` | 21, 139, 445, 2049 | **21, 139, 445 open; 2049 filtered** | FTP/SMB expuestos; NFS solo M1 |
| M4 `.14` | 53, 135, 139, 445, 3389 | **445 open desde M6**; 3389 filtered | ⚠️ **Desviación:** M4 no está invisible desde M6 |
| M5 `.15` | 445, 3389, 5900 | **3389 open, 5900 open desde M6**; 445 filtered | ⚠️ **Desviación:** VNC/RDP visibles desde M6 |
| M6 `.20` | — | — | Atacante / evidencia |

**Evidencia:** `evidencias/logs/F02-001.log` y `evidencias/png/F02-001.png`.

### Interpretación

El diseño pretendía que M2–M5 solo aceptaran tráfico de M1 (`10.10.10.11`), salvo DNS en M4. La realidad muestra dos brechas:

1. **M4:445 abierto desde M6** → la regla “SMB solo M1” no está aplicada o lo está de forma parcial.
2. **M5:5900 abierto desde M6** → la regla “VNC solo M1” no está aplicada.

Esto se documenta como **hallazgo de configuración** (no como diseño) y se corrige en la fase de mitigación. Para el livecoding permite un demo directo y sencillo; para el informe se explica que el pivote era el camino previsto y que la exposición directa fue una desviación real.

---

## 3.5 Cadena de ataque prevista

| Paso | Origen → destino | Técnica | Nivel obtenido |
|---|---|---|---|
| 1 | M6 → M1:80 | W1 / W4 / W3 / W2 | `www-data` |
| 2 | M1 → M2:6379/3306 | D1 / D2 / D3 / D4 | `redis` / usuario DB |
| 3 | M1/M2 → M3:21/445/2049 | B3 / B2 / B1 / B4 | `root` |
| 4 | M1 → M4:445 | S3 → S2 / S1 | **SYSTEM** |
| 5 | M4 → M5:445/3389/5900 | C2 / C3 / C4 | Admin / escritorio |

> El “cliente” es **M5**, la estación Windows. No se toca la laptop física del estudiante.

---

## 3.6 Dependencias funcionales

| Dependencia | Si falla… |
|---|---|
| M5 → M1:80 | Sin acceso a WordPress/Moodle |
| M1 → M2:3306 | WordPress/Moodle con error de base de datos |
| M1 → M3:2049 | Subidas y `moodledata` rotos |
| * → M4:53 | Sin resolución de `*.uni.lab` |
| M2 → M3 | Sin respaldos actualizados |

---

## 3.7 Aislamiento y supuestos

- El laboratorio no debe tener salida a Internet mientras los servicios vulnerables estén activos. **Estado actual:** M6 tiene `eth2` con NAT (`192.168.97.129`) y ruta por defecto; se desconectará antes de la fase de explotación.
- El router no tiene DSL; DHCP está apagado.
- La separación es **lógica** (firewall de host), no física; se documenta como limitación honesta.
- Todo el trabajo se realiza con autorización del docente y solo sobre las VM del grupo.
