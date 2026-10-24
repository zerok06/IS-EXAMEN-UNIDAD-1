# Anexo E · Referencias CVE verificadas

**Fecha de consulta:** 2026-10-24
**Fuentes:** NVD (`nvd.nist.gov`) y CVE.org (`cve.org`). Para cada CVE se usó la API/registro oficial y se contrastó la puntuación.

---

## E.1 Tabla de referencias

| CVE | Producto afectado | CVSS v3.1 | Severidad | KEV | NVD | CVE.org |
|---|---|---|---|---|---|---|
| CVE-2026-63030 | WordPress 6.9.0–6.9.4 / 7.0.0–7.0.1 | **9.8** `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` | Crítica | **Sí** (2026-07-21) | https://nvd.nist.gov/vuln/detail/CVE-2026-63030 | https://cve.org/CVERecord?id=CVE-2026-63030 |
| CVE-2026-109618 | PHP 8.2 < 8.2.35, 8.3 < 8.3.36, 8.4 < 8.4.27, 8.5 < 8.5.12 | **9.8** v3.1 / **9.2** v4.0 | Crítica | No | https://nvd.nist.gov/vuln/detail/CVE-2026-109618 | https://cve.org/CVERecord?id=CVE-2026-109618 |
| CVE-2026-109619 | Mismo rango PHP | **8.1** v3.1 / **9.2** v4.0 | Alta / Crítica | No | https://nvd.nist.gov/vuln/detail/CVE-2026-109619 | https://cve.org/CVERecord?id=CVE-2026-109619 |
| CVE-2021-41773 | Apache httpd 2.4.49 | **9.8** | Crítica | No (verificar) | https://nvd.nist.gov/vuln/detail/CVE-2021-41773 | https://cve.org/CVERecord?id=CVE-2021-41773 |
| CVE-2022-0543 | Redis 5.0–5.0.14, 6.0–6.0.16, 6.2–6.2.6 (Debian/Ubuntu) | **10.0** | Crítica | No | https://nvd.nist.gov/vuln/detail/CVE-2022-0543 | https://cve.org/CVERecord?id=CVE-2022-0543 |
| CVE-2017-7494 | Samba 3.5.0 < 4.6.4, < 4.5.10, < 4.4.14 | **9.8** | Crítica | No | https://nvd.nist.gov/vuln/detail/CVE-2017-7494 | https://cve.org/CVERecord?id=CVE-2017-7494 |
| CVE-2011-2523 | vsftpd 2.3.4 (tarball 2011-06-30 a 2011-07-03) | **9.8** | Crítica | No | https://nvd.nist.gov/vuln/detail/CVE-2011-2523 | https://cve.org/CVERecord?id=CVE-2011-2523 |
| CVE-2017-0144 | SMBv1 en Windows Vista/7/8.1/10 (hasta 1607) y Server 2008/2012/2016 | **8.8** | Alta | No | https://nvd.nist.gov/vuln/detail/CVE-2017-0144 | https://cve.org/CVERecord?id=CVE-2017-0144 |
| CVE-2021-34527 | Windows Print Spooler | **8.8** | Alta | No | https://nvd.nist.gov/vuln/detail/CVE-2021-34527 | https://cve.org/CVERecord?id=CVE-2021-34527 |

---

## E.2 Discrepancias detectadas y corregidas

| Punto | Guía interna | NVD/CVE.org | Acción |
|---|---|---|---|
| W1 CVSS | 7.5 Alta | **9.8 Crítica**, KEV | Se reporta 9.8 |
| W3 CVSS | 7.5 Alta | **9.8 Crítica** | Se reporta 9.8 |
| W2 CVSS | 9.2 | 9.8 v3.1 / 9.2 v4.0 (109618); 8.1 v3.1 / 9.2 v4.0 (109619) | Se declara la métrica |
| B1 Samba 4.5.10 | “vulnerable a SambaCry” | 4.5.10 es la **versión que corrige** CVE-2017-7494 | No explotable; se documenta |
| C1 Win10 21H2 | “EternalBlue” | CVE-2017-0144 no afecta a 21H2 | No aplica; se usa C2/C4 |
| B2 vsftpd 2.3.4 | “backdoor :)” | Solo el tarball de 2011-06-30 a 2011-07-03 | `:6200` cerrado; no explotable |
| D1 Redis | “CVE-2022-0543 RCE” | Debian-specific; build de fuente con `enable_strict_lua` | RCE no reproducible; se reporta acceso sin auth |

> Estas correcciones son parte del valor del informe: no se copian identificadores ni puntuaciones sin verificarlos.

---

## E.3 Cómo se verificó

```bash
# NVD API
curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=CVE-2026-63030" | head

# CVE.org (registro CVE JSON)
curl -s "https://cveawg.mitre.org/api/cve/CVE-2026-63030" | head
```

Se guardó la fecha de consulta y se contrastó la puntuación con la ficha HTML. Para el informe final, adjuntar captura de cada ficha (NVD y CVE.org).
