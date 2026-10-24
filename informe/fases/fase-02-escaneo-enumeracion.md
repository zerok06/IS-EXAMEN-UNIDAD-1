# Fase 2 · Escaneo y análisis de vulnerabilidades

**Objetivo:** confirmar puertos, servicios, versiones y configuraciones; correlacionar cada hallazgo con un CVE o una debilidad de configuración.
**Ejecuta:** M6 `10.10.10.20` (M1 directo; M2–M5 según el modelo de red).
**Fecha UTC:** 2026-10-24.

---

## 2.1 Comandos demo (simples, sustanciosos)

| # | Comando | Qué muestra |
|---|---|---|
| 1 | `nmap -Pn -p 22,80,443 10.10.10.11` | Puerta M1 |
| 2 | `nmap -Pn -p 3306,6379,161 10.10.10.12` | Servicios de M2 |
| 3 | `nmap -Pn -p 21,139,445,2049 10.10.10.13` | Servicios de M3 |
| 4 | `nmap -Pn -p 53,445,3389 10.10.10.14` | Servicios de M4 |
| 5 | `nmap -Pn -p 445,3389,5900 10.10.10.15` | Servicios de M5 |
| 6 | `nmap -sV -Pn -p 80 --version-light --host-timeout 30s 10.10.10.11` | Versión de Apache/PHP |
| 7 | `wpscan --url http://wp.uni.lab --enumerate u` | Usuario de WordPress |
| 8 | `curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/server-status` | W5 |
| 9 | `curl -s http://wp.uni.lab/info.php \| grep -i 'PHP Version'` | W6 |
| 10 | `curl -s http://wp.uni.lab/wp-content/uploads/ \| grep -i 'Index of'` | W7 |

> Los escaneos completos (`-p-`, `-sS -sV -O`) no se usan en la exposición; quedan en la bitácora como evidencia ampliada si se necesitan.

---

## 2.2 Modelo de puertos real

```bash
nmap -Pn -p 22,80,443 10.10.10.11
nmap -Pn -p 3306,6379,161 10.10.10.12
nmap -Pn -p 21,139,445,2049 10.10.10.13
nmap -Pn -p 445,3389 10.10.10.14
nmap -Pn -p 445,3389,5900 10.10.10.15
```

**Salida real** (`F02-001` + `F02-001b`):

```text
== M1 10.10.10.11 ==
22/tcp  open   ssh
80/tcp  open   http
443/tcp closed https

== M2 10.10.10.12 ==
161/tcp  filtered snmp
3306/tcp filtered mysql
6379/tcp open     redis

== M3 10.10.10.13 ==
21/tcp   open     ftp
139/tcp  open     netbios-ssn
445/tcp  open     microsoft-ds
2049/tcp filtered nfs

== M4 10.10.10.14 ==
445/tcp  open     microsoft-ds
3389/tcp filtered ms-wbt-server

== M5 10.10.10.15 ==
445/tcp  filtered microsoft-ds
3389/tcp open     ms-wbt-server
5900/tcp open     vnc
```

### Lectura de resultados

| Máquina | Hallazgo | Implicación |
|---|---|---|
| M1 | 22, 80 abiertos; 443 cerrado | La puerta es HTTP; SSH queda para administración/pivote |
| M2 | Redis `6379` abierto a la LAN; MySQL/SNMP filtrados | D1/D3 accesibles directamente; D2/D4 requieren M1 o pivote |
| M3 | FTP/SMB abiertos; NFS filtrado | B2/B3/B1 accesibles; B4 requiere pivote o M1 |
| M4 | **445 abierto desde M6** | ⚠️ Desviación: SMB no está restringido a M1 |
| M5 | **5900 y 3389 abiertos desde M6**; 445 filtrado | ⚠️ Desviación: VNC/RDP visibles; SMB sí restringido |

**Evidencia:** `F02-001.png`, `F02-001.log`, `F02-001b.png`, `F02-001b.log`.

---

## 2.3 Versión de Apache/PHP

```bash
nmap -sV -Pn -p 80 --version-light --host-timeout 30s 10.10.10.11
```

**Salida real** (`F02-002`):

```text
PORT   STATE SERVICE VERSION
80/tcp open  http    Apache httpd 2.4.49 ((Unix) PHP/8.4.26)
```

**Interpretación:** confirma **Apache 2.4.49** y **PHP 8.4.26** desde el propio servicio. Se correlaciona con W3 (CVE-2021-41773) y W2 (CVE-2026-109618/109619).

> M1 tiene latencia variable (300 ms–1.5 s). Sin `--host-timeout 30s`, `nmap -sV` puede devolver “0 hosts up”. Se documenta como limitación y se usa `-Pn` + timeout.

**Evidencia:** `F02-002.png` · `F02-002.log`.

---

## 2.4 WordPress: versión y usuario

```bash
wpscan --url http://wp.uni.lab --no-banner --enumerate u --max-threads 4
```

**Salida real** (`F02-003b`, resumida):

```text
[+] WordPress version 7.0.1 identified (Insecure, released on 2026-07-09).
[+] WordPress theme in use: usc-oficial
[i] User(s) Identified:
[+] usc-admin
 | Found By: Author Id Brute Forcing - Author Pattern (Aggressive Detection)
[!] No WPScan API Token given, as a result vulnerability data has not been output.
[+] Finished: Sat Oct 24 12:36:57 2026
[+] Requests Done: 21
[+] Elapsed time: 00:00:12
```

**Interpretación:**
- WP **7.0.1** confirmado → W1 (CVE-2026-63030).
- Usuario enumerado: **`usc-admin`** (el slug). La guía interna decía `usc.admin`; hay que probar ambos en el login.
- Sin API token, WPScan no muestra datos de vulnerabilidad; la correlación se hace con NVD/CVE.org.

**Evidencia:** `F02-003b.png` · `F02-003b.log`. El intento con `--enumerate vp,vt,u` (`F02-003`) quedó interrumpido en la enumeración agresiva de temas; se conserva como evidencia parcial.

---

## 2.5 Configuraciones expuestas W5/W6/W7

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://wp.uni.lab/server-status
curl -s http://wp.uni.lab/info.php | grep -i 'PHP Version'
curl -s http://wp.uni.lab/wp-content/uploads/ | grep -i 'Index of'
```

**Salida real** (`F02-004`, limpia):

```text
== W5 server-status ==
200
== W6 info.php ==
<h1 class="p">PHP Version 8.4.26</h1>
== W7 uploads ==
<title>Index of /wp-content/uploads</title>
<h1>Index of /wp-content/uploads</h1>
```

**Interpretación:**
- W5: `server-status` responde **200** → `mod_status` expuesto.
- W6: `info.php` responde con **PHP 8.4.26** → `phpinfo()` público.
- W7: `uploads/` devuelve **Index of** → listado de directorios.

Las tres son debilidades de configuración (no CVE) y se clasifican con CWE-200 / CWE-548.

**Evidencia:** `F02-004.png` · `F02-004.log`.

---

## 2.6 Correlación preliminar

| Servicio/versión | CVE/debilidad | ID | Estado |
|---|---|---|---|
| WordPress 7.0.1 | CVE-2026-63030 (wp2shell) | W1 | Confirmado por versión |
| PHP 8.4.26 | CVE-2026-109618 / 109619 (PHP2Shell) | W2 | Confirmado por versión |
| Apache 2.4.49 | CVE-2021-41773 | W3 | Confirmado por versión |
| `server-status` 200 | CWE-200 | W5 | Confirmado |
| `info.php` 200 | CWE-200 | W6 | Confirmado |
| `uploads/` Index of | CWE-548 | W7 | Confirmado |
| Redis 6.2.6 en 6379 | CVE-2022-0543 | D1 | Por validar (build de fuente) |
| MariaDB 10.11.19 + claves débiles | CWE-521 | D2 | Por validar |
| SNMP `public/private` | CWE-306 | D4 | Por validar (filtrado desde M6) |
| vsftpd 2.3.4 | CVE-2011-2523 | B2 | Por validar (tarball) |
| Samba 4.5.10 | CVE-2017-7494 | B1 | **No explotable tal cual** (4.5.10 es fix) |
| SMBv1 M4 | CVE-2017-0144 | S1 | Por validar |
| Spooler M4 | CVE-2021-34527 | S2 | Por validar |
| AXFR M4 | CWE-200 | S4 | Por validar |
| SMB signing M4 | CWE-319 | S5 | Por validar |
| Win10 21H2 + SMBv1 | CVE-2017-0144 | C1 | **No aplica a 21H2** |
| VNC 5900 sin auth | CWE-306 | C4 | Confirmado por puerto |

---

## 2.7 Evidencia de la fase

| ID | Archivo | Qué demuestra |
|---|---|---|
| F02-001 | `evidencias/png/F02-001.png` | Puertos M2–M5 |
| F02-001b | `evidencias/png/F02-001b.png` | Puertos M1 |
| F02-002 | `evidencias/png/F02-002.png` | Apache 2.4.49 / PHP 8.4.26 |
| F02-003 | `evidencias/png/F02-003.png` | WPScan parcial |
| F02-003b | `evidencias/png/F02-003b.png` | WP 7.0.1 + usuario `usc-admin` |
| F02-004 | `evidencias/png/F02-004.png` | W5/W6/W7 |

**Cierre:** superficie confirmada; tecnologías correlacionadas con CVE; desviaciones de firewall y limitaciones de M1 documentadas.
