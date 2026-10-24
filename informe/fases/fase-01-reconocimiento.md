# Fase 1 · Reconocimiento

**Objetivo:** construir el mapa del entorno sin explotar nada: activos, nombres, roles y tecnologías.
**Ejecuta:** M6 Kali `10.10.10.20`.
**Alcance:** `10.10.10.0/24`, VM del propio grupo. Sin Internet y sin terceros.
**Fecha UTC:** 2026-10-24.

---

## 1.1 Comandos demo (simples, reproducibles en vivo)

| # | Comando | Qué muestra |
|---|---|---|
| 1 | `hostname; ip -brief a` | Identidad y dirección de M6 |
| 2 | `dig +short app.uni.lab @10.10.10.14` | Resolución DNS del entorno |
| 3 | `curl -sI http://wp.uni.lab` | Tecnología de la puerta web |
| 4 | `whatweb http://wp.uni.lab` | Fingerprint resumido |
| 5 | `nmap -sn 10.10.10.0/24` | Hosts activos (con limitación en M1) |
| 6 | `ping -c 2 10.10.10.11` | M1 responde a ICMP aunque `nmap -sn` falle |

> Estos comandos son los que se pueden teclear en la exposición. Las versiones completas y sus logs están en `evidencias/logs/`.

---

## 1.2 Identidad y red de M6

```bash
hostname; id; ip -brief a; ip route
```

**Salida real** (`F01-001`):

```text
kali
uid=1000(kali) gid=1000(kali) groups=1000(kali),4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),100(users),101(netdev),102(scanner),118(wireshark),119(kaboxer),982(bluetooth),999(lpadmin)
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             10.10.10.20/24 fe80::29c0:ba21:5407:5025/64
eth1             UP             192.168.50.10/24 fe80::8373:2985:c556:1235/64
eth2             UP             192.168.97.129/24 fe80::7d6c:b55c:cc7c:3e32/64
default via 192.168.97.2 dev eth2 proto dhcp src 192.168.97.129 metric 102
10.10.10.0/24 dev eth0 proto kernel scope link src 10.10.10.20 metric 100
```

**Interpretación:** M6 está en la LAN por `eth0` (`10.10.10.20/24`). `eth2` es NAT para descargas; **debe desconectarse antes de la explotación** para cumplir el aislamiento.

`/etc/hosts` de M6:

```text
10.10.10.11 wp.uni.lab moodle.uni.lab app.uni.lab
```

**Evidencia:** `evidencias/png/F01-001.png` · `evidencias/logs/F01-001.log` · SHA256 en `anexos/b-indice-evidencias.md`.

---

## 1.3 DNS interno `uni.lab`

```bash
for n in app wp moodle db bkp srvold pc-est01; do
  echo "== $n.uni.lab =="; dig +short "$n.uni.lab" @10.10.10.14
done
```

**Salida real** (`F01-002`):

```text
== app.uni.lab ==
10.10.10.11
== wp.uni.lab ==
app.uni.lab.
10.10.10.11
== moodle.uni.lab ==
app.uni.lab.
10.10.10.11
== db.uni.lab ==
10.10.10.12
== bkp.uni.lab ==
10.10.10.13
== srvold.uni.lab ==
10.10.10.14
== pc-est01.uni.lab ==
10.10.10.15
== SOA ==
;; communications error to 10.10.10.14#53: timed out
...
```

**Interpretación:** los registros A/CNAME resuelven correctamente. Las consultas `SOA`/`NS` dieron *timeout*; se documenta como limitación y se reintentará con `dig +tcp` y `dig axfr` en Fase 2.

**Evidencia:** `F01-002.png` · `F01-002.log`.

---

## 1.4 Cabeceras HTTP de M1

```bash
curl -sI http://10.10.10.11
curl -sI http://wp.uni.lab
```

**Salida real** (`F01-003`):

```text
HTTP/1.1 301 Moved Permanently
Date: Sat, 24 Oct 2026 16:22:31 GMT
Server: Apache/2.4.49 (Unix) PHP/8.4.26
X-Powered-By: PHP/8.4.26
X-Redirect-By: WordPress
Location: http://wp.uni.lab/
Content-Type: text/html; charset=UTF-8

HTTP/1.1 200 OK
Date: Sat, 24 Oct 2026 16:22:32 GMT
Server: Apache/2.4.49 (Unix) PHP/8.4.26
X-Powered-By: PHP/8.4.26
Link: <http://wp.uni.lab/wp-json/>; rel="https://api.w.org/"
Content-Type: text/html; charset=UTF-8
```

**Interpretación:** la IP redirige al vhost `wp.uni.lab`; el servidor declara **Apache 2.4.49** y **PHP 8.4.26**, ambos en rangos vulnerables (W3 y W2). WordPress se confirma en el siguiente paso.

`robots.txt` real:

```text
User-agent: *
Disallow: /wp-admin/
Allow: /wp-admin/admin-ajax.php

Sitemap: http://wp.uni.lab/wp-sitemap.xml
```

**Evidencia:** `F01-003.png` · `F01-003.log`.

---

## 1.5 Fingerprint con `whatweb`

```bash
whatweb http://wp.uni.lab
```

**Salida real** (`F01-004`, sin códigos ANSI):

```text
http://wp.uni.lab [200 OK] Apache[2.4.49], HTTPServer[Unix][Apache/2.4.49 (Unix) PHP/8.4.26], IP[10.10.10.11], MetaGenerator[WordPress 7.0.1], PHP[8.4.26], Title[Universidad Sideral Carrión – Formación al alcance de tod@s], WordPress[7.0.1], X-Powered-By[PHP/8.4.26]
```

**Interpretación:** confirma la combinación exacta del escenario:

- **Apache 2.4.49** → CVE-2021-41773 (W3).
- **PHP 8.4.26** → CVE-2026-109618/109619 (W2).
- **WordPress 7.0.1** → CVE-2026-63030 (W1).

**Evidencia:** `F01-004.png` · `F01-004.log`.

---

## 1.6 Descubrimiento de hosts

```bash
nmap -sn 10.10.10.0/24
```

**Salida real** (`F01-005`, resumida):

```text
Nmap scan report for 10.10.10.1    (MitraStar)
Nmap scan report for 10.10.10.2    (Dell)
Nmap scan report for 10.10.10.12   (M2)
Nmap scan report for 10.10.10.13   (M3)
Nmap scan report for 10.10.10.14   (M4)
Nmap scan report for 10.10.10.15   (M5)
Nmap scan report for 10.10.10.20   (M6)
Nmap done: 256 IP addresses (7 hosts up) scanned in 22.09 seconds
```

**Observación:** M1 `10.10.10.11` no aparece en el descubrimiento, aunque responde a `ping` y a HTTP. Es un **falso negativo** por la latencia/tiempo de espera de `nmap -sn`.

Verificación puntual (`F01-006`):

```text
== ping ==
64 bytes from 10.10.10.11: icmp_seq=1 ttl=64 time=1349 ms
64 bytes from 10.10.10.11: icmp_seq=2 ttl=64 time=317 ms
== nmap -sn ==
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
== curl ==
HTTP/1.1 301 Moved Permanently
Server: Apache/2.4.49 (Unix) PHP/8.4.26
```

**Lección para el informe:** en M1 hay que usar **`-Pn`** en los escaneos; el descubrimiento por ICMP/ARP no es fiable. Se documenta como limitación del entorno.

**Evidencia:** `F01-005.png` · `F01-005.log` · `F01-006.png` · `F01-006.log`.

---

## 1.7 Resultado del reconocimiento

| IP | Hostname | Rol | Servicio/tecnología conocida | Fuente |
|---|---|---|---|---|
| `10.10.10.11` | `app01` | Aplicación / puerta | Apache 2.4.49 · PHP 8.4.26 · WP 7.0.1 · Moodle 5.0.11 | HTTP, whatweb |
| `10.10.10.12` | `db01` | Base de datos | MariaDB 10.11.19 · Redis 6.2.6 · SNMP | DNS, documentación |
| `10.10.10.13` | `bkp01` | Respaldos | NFS · Samba 4.5.10 · vsftpd 2.3.4 | DNS, documentación |
| `10.10.10.14` | `SRVOLD` | Windows heredado | DNS · SMBv1 · Spooler | DNS, nmap |
| `10.10.10.15` | `PC-EST01` | Cliente | SMBv1 · RDP · TightVNC | DNS, nmap |
| `10.10.10.20` | `kali01` | Auditor | Kali + herramientas | Local |
| `10.10.10.1` | — | Router | MitraStar | `nmap -sn` |

---

## 1.8 Evidencia de la fase

| ID | Archivo | Qué demuestra |
|---|---|---|
| F01-001 | `evidencias/png/F01-001.png` | Identidad, interfaces y rutas de M6 |
| F01-002 | `evidencias/png/F01-002.png` | DNS `uni.lab` y limitación SOA/NS |
| F01-003 | `evidencias/png/F01-003.png` | Cabeceras HTTP y `robots.txt` |
| F01-004 | `evidencias/png/F01-004.png` | Fingerprint Apache/PHP/WordPress |
| F01-005 | `evidencias/png/F01-005.png` | Hosts activos en la LAN |
| F01-006 | `evidencias/png/F01-006.png` | M1 responde a `ping`/HTTP pero no a `nmap -sn` |

**Cierre:** mapa de activos completo; tecnologías de M1 confirmadas; limitaciones de DNS y descubrimiento documentadas.
