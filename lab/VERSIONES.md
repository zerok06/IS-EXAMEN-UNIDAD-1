# Matriz de versiones · Lab PHP2Shell

> Fuente de verdad de versiones. Si un instalador no coincide con esta tabla,
> el chequeo `lab/tests/check-versions.sh` falla.
> Todo artefacto se verifica por SHA256 contra `artifacts/checksums.sha256`.

## 1. Componentes vulnerables (fijados y verificados)

| Componente | Versión exacta | Artefacto | SHA256 (inicio) |
|---|---|---|---|
| Apache httpd | **2.4.49** | `vulnerable/httpd-2.4.49.tar.gz` | `345d3b9b…` |
| PHP | **8.4.26 NTS** | `vulnerable/php-8.4.26.tar.gz` | `c248abae…` |
| WordPress | **7.0.1** | `vulnerable/wordpress-7.0.1.zip` | `f171740c…` |
| Moodle | **5.0.11** | `vulnerable/moodle-5.0.11.tar.gz` | `1e79e856…` |
| Redis | **6.2.6** | `vulnerable/redis-6.2.6.tar.gz` | `5b2b8b7a…` |
| vsftpd | **2.3.4** | `vulnerable/vsftpd-2.3.4.tar.gz` | `b466edf9…` |
| TightVNC | **2.8.90** | `vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi` | `9693cb4c…` |

## 2. Componentes corregidos (para parchado)

| Componente | Versión exacta | Artefacto |
|---|---|---|
| PHP | **8.4.27** | `fixed/php-8.4.27.tar.gz` |
| WordPress | **7.0.2** | `fixed/wordpress-7.0.2.zip` |
| Apache httpd | **2.4.51** | `fixed/httpd-2.4.51.tar.gz` |
| Redis | **6.2.7** | `fixed/redis-6.2.7.tar.gz` |
| vsftpd | **3.0.5** | `fixed/vsftpd-3.0.5.tar.gz` |

## 3. Sistema operativo e infraestructura

| VM | SO | Versión | Nota |
|---|---|---|---|
| M1–M3 | Ubuntu Server | **22.04.5 LTS** | mismo ISO en las tres |
| M4 | Windows Server | **2016 build 14393** | revisión exacta se verifica con `verify.ps1` |
| M5 | Windows 10 | **22H2 build 19045** | idem |
| M6 | Kali | **2026.x** | solo herramientas |

Paquetes de soporte (vienen del repo de la ISO; se registran tras instalar):

| Paquete | Versión esperada en 22.04.5 | Se usa en |
|---|---|---|
| nginx | **1.18.x** | M1 (TLS) |
| MariaDB | **10.6.x** | M2 (WP) |
| OpenSSH | **8.9p1** | M1–M3 |
| nfs-kernel-server | **2.6.x** | M3 |
| cron | **3.0** | M3 |
| python3 | **3.10.x** | M1 (salts) |
| Metasploit | **6.x** | M6 |

## 4. Decisión sobre Moodle

Moodle **5.0.11 exige MariaDB 10.11 o MySQL 8.4** (verificado en
`admin/environment.xml`). Ubuntu 22.04 solo trae MariaDB 10.6 / MySQL 8.0.

Por eso el instalador **no instala Moodle por defecto** (`INSTALL_MOODLE=0`).
La cadena no lo usa. Si se quiere Moodle:

- opción A: añadir MariaDB 10.11 al espejo local y fijar
  `mariadb-server=1:10.11.*` en `lab/m2/install.sh`;
- opción B: usar Moodle 4.5.x (acepta 10.6).

## 5. Verificación

```bash
bash lab/tests/check-versions.sh m1    # en M1
bash lab/tests/check-versions.sh m2
bash lab/tests/check-versions.sh m3
```

En Windows: `lab\\m4\\verify.ps1` y `lab\\m5\\verify.ps1` imprimen build y revisión.
