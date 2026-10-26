# Manifiesto de artefactos

> Fecha de descarga: **2026-10-26**. Los SHA256 están en [`checksums.sha256`](./checksums.sha256). Verificar antes de instalar.

## 1. Versiones vulnerables (Fase 2)

| Archivo | Versión | VM | Uso | SHA256 |
|---|---|---|---|---|
| [`vulnerable/wordpress-7.0.1.zip`](./vulnerable/wordpress-7.0.1.zip) | 7.0.1 | M1 | W1 wp2shell | `f171740cf45b1f5a1bf52194ca914787cd9d8ea078599b430eca951b62b2d000` |
| [`vulnerable/php-8.4.26.tar.gz`](./vulnerable/php-8.4.26.tar.gz) | 8.4.26 | M1 | W2 PHP2Shell | `c248abaebc4bb777b80968f0760da0da8e989836e896c9ff637b6775d7d37662` |
| [`vulnerable/httpd-2.4.49.tar.gz`](./vulnerable/httpd-2.4.49.tar.gz) | 2.4.49 | M1 | W3 CVE-2021-41773 | `345d3b9b218b1974d1cebd5ae72f6a661d83b52d839310222ff9ec94abb62205` |
| [`vulnerable/moodle-5.0.11.tar.gz`](./vulnerable/moodle-5.0.11.tar.gz) | 5.0.11 | M1 | Moodle | `1e79e8568719034ba570074ecd073ebba0b35c8063458135412d5c27fa01551f` |
| [`vulnerable/redis-6.2.6.tar.gz`](./vulnerable/redis-6.2.6.tar.gz) | 6.2.6 | M2 | D1 (fuente; no Debian) | `5b2b8b7a50111ef395bf1c1d5be11e6e167ac018125055daa8b5c2317ae131ab` |
| [`vulnerable/samba-4.5.9.tar.gz`](./vulnerable/samba-4.5.9.tar.gz) | 4.5.9 | M3 | B1 SambaCry | `e7b04b5d7ce10ed1205cc552200958e3c487ecf9647ea4c7b8c5f049f97c6be4` |
| [`vulnerable/vsftpd-2.3.4.tar.gz`](./vulnerable/vsftpd-2.3.4.tar.gz) | 2.3.4 limpio | M3 | B2/B3 | `b466edf96437afa2b2bea6981d4ab8b0204b83ca0a2ac94bef6b62b42cc71a5a` |
| [`vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi`](./vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi) | 2.8.90 | M5 | C4 VNC sin auth | `9693cb4cdc2e7e482e8e3f5890415b57ef87de3369fa5c337db516218a1170ce` |

## 2. Versiones corregidas (Fase 5)

| Archivo | Versión | VM | Uso | SHA256 |
|---|---|---|---|---|
| [`fixed/wordpress-7.0.2.zip`](./fixed/wordpress-7.0.2.zip) | 7.0.2 | M1 | W1 fix | `a616580ed2152ae71d81439884b4bcda329c5322f9bd2092ac7a3a68dbcea7a7` |
| [`fixed/php-8.4.27.tar.gz`](./fixed/php-8.4.27.tar.gz) | 8.4.27 | M1 | W2 fix | `5bafed9994c1a49796b25b5f61c22c9183bfe046b6acc7b363842d03c77f972f` |
| [`fixed/httpd-2.4.51.tar.gz`](./fixed/httpd-2.4.51.tar.gz) | 2.4.51 | M1 | W3 fix | `c2cedb0b47666bea633b44d5b3a2ebf3c466e0506955fbc3012a5a9b078ca8b4` |
| [`fixed/redis-6.2.7.tar.gz`](./fixed/redis-6.2.7.tar.gz) | 6.2.7 | M2 | D1 fix | `b7a79cc3b46d3c6eb52fa37dde34a4a60824079ebdfb3abfbbfa035947c55319` |
| [`fixed/samba-4.5.10.tar.gz`](./fixed/samba-4.5.10.tar.gz) | 4.5.10 | M3 | B1 fix | `7cb753f5f6d5527ef40d4c1f47dacafb7c876cb304b4906ccb390c6a18477714` |
| [`fixed/vsftpd-3.0.5.tar.gz`](./fixed/vsftpd-3.0.5.tar.gz) | 3.0.5 | M3 | B2/B3 fix | `26b602ae454b0ba6d99ef44a09b6b9e0dfa7f67228106736df1f278c70bc91d3` |

## 3. PoCs y herramientas

| Archivo | Uso | SHA256 |
|---|---|---|
| [`pocs/wp2shell-vulhub-poc.py`](./pocs/wp2shell-vulhub-poc.py) | W1 · crear admin (stops before webshell) | `6f592cac96318e6c18fe76c1f3483fa9d5f1a57dc19708529acedc4266cc2fd5` |
| [`pocs/wp2shell-poc-main.zip`](./pocs/wp2shell-poc-main.zip) | W1 · PoC alternativo | `f685ed7513af257af54c51643777b600f23dbaa6e8fb72123a6aaa3567d35f65` |
| [`pocs/php2shell-poc-main.zip`](./pocs/php2shell-poc-main.zip) | W2 · PoC PHP2Shell | `ebeb7e8bd1a8000a0ff24b2fda57d3327d66db438bfcf5429aeae907e0125eaf` |
| [`pocs/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz`](./pocs/ligolo-ng_proxy_0.9.2_linux_amd64.tar.gz) | Pivote · proxy en Kali | `6c683c403502d366276595197749e620c975908dae7314c21079ec8ebee4e5d0` |
| [`pocs/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz`](./pocs/ligolo-ng_agent_0.9.2_linux_amd64.tar.gz) | Pivote · agent en M1 | `714534917a4a58812669619667cc57dfad03d34d0de5b0d7c468d76819f84111` |

> **PrintNightmare:** el PoC PowerShell está bloqueado por Windows Defender y no se guarda. Usar el módulo de Metasploit `exploit/windows/local/cve_2021_1675_printnightmare` o `exploit/windows/dcerpc/cve_2021_1675_printnightmare`, que vienen en Kali.

## 4. No descargado

| Artefacto | Motivo | Dónde |
|---|---|---|
| Ubuntu Server 22.04.5 ISO | ~2 GB; se descarga aparte | [`os/README.md`](./os/README.md) |
| Windows Server 2016 Eval | ~6 GB; licencia/evaluación | [`os/README.md`](./os/README.md) |
| Windows 10 22H2 ISO | ~5 GB; licencia | [`os/README.md`](./os/README.md) |
| Kali Linux VMware | ~4 GB; imagen oficial | [`os/README.md`](./os/README.md) |
| Paquete Redis distro para D1 | Depende de la distro; ver nota | [`README.md`](./README.md) §6 |

## 5. Verificación

```bash
cd artifacts
sha256sum -c checksums.sha256
```

Si una línea falla, re-descargar el archivo con `download.ps1 -Force` o `download.sh --force`.
