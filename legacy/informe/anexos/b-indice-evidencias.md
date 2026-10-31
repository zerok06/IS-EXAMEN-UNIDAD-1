# Anexo B · Índice de evidencias

**Fecha UTC de la sesión:** 2026-10-24
**Estación:** M6 Kali `10.10.10.20`
**Manifiesto completo:** `evidencias/hashes.txt` (SHA256 de los 24 logs y 24 capturas)

> Cada captura corresponde a una ventana de terminal real (`xterm`) con el comando y su salida. El log es la transcripción completa; la captura es la prueba visual. Los hashes permiten verificar que no se alteraron después.

| ID | Qué demuestra | Log | PNG | SHA256 log (16) | SHA256 PNG (16) |
|---|---|---|---|---|---|
| `F01-001` | Identidad, interfaces y rutas de M6 | 1102 B | 27369 B | `1c79c697e7e2214a…` | `297b1038dc6a7f52…` |
| `F01-002` | DNS interno uni.lab (A/CNAME; SOA/NS con timeout) | 644 B | 20505 B | `d9dba67f881c0c78…` | `13cff95230e9e1eb…` |
| `F01-003` | Cabeceras HTTP de M1, robots.txt y wp-json | 1477 B | 41092 B | `77e6a5c266b30241…` | `c36874fb3ee2e4e0…` |
| `F01-004` | Fingerprint Apache 2.4.49 / PHP 8.4.26 / WP 7.0.1 | 1921 B | 89680 B | `52d9c4089d8f4a2b…` | `a3a94636288b6a14…` |
| `F01-005` | Descubrimiento de hosts en 10.10.10.0/24 | 851 B | 31254 B | `e14ef1987a503640…` | `757fcdff4eaf01cf…` |
| `F01-006` | M1 responde a ping/HTTP pero nmap -sn da falso negativo | 812 B | 29410 B | `4e326b634aa0851d…` | `e41a8ac86bf1212a…` |
| `F02-001` | Puertos M2–M5 (M1 falló por latencia) | 1632 B | 38406 B | `f048fe98efb64259…` | `5e49c52bfd350a2d…` |
| `F02-001b` | Puertos 22/80/443 de M1 | 336 B | 17749 B | `8b08eb31d0b68d16…` | `6c1d3cd454777cee…` |
| `F02-002` | nmap -sV de M1: Apache 2.4.49 / PHP 8.4.26 | 439 B | 20201 B | `c256325763fecb8a…` | `2339725c3f5c804c…` |
| `F02-003` | WPScan vp,vt,u (interrumpido en temas) | 3208 B | 39745 B | `1ed9ffa0dd4f6aea…` | `6128f3d73417a443…` |
| `F02-003b` | WPScan usuarios: WP 7.0.1 + usc-admin | 3775 B | 100859 B | `c389096754806293…` | `ef299446d572785f…` |
| `F02-004` | W5 server-status, W6 info.php, W7 listing | 5753 B | 129056 B | `18032ffcf3735f66…` | `3cfe2bd533793bdd…` |
| `F03-001` | W1 ruta batch + login W4 (usc.admin) | 370 B | 27625 B | `3ec289e3aebca978…` | `9d3f99cc6f58b0a9…` |
| `F03-002` | W3 Apache traversal: 403/503 (no explotable) | 202 B | 17882 B | `30c825efa8e51ec7…` | `9d22db6d7e4399af…` |
| `F04-000` | SSH a M1 con clave reutilizada | 251 B | 15791 B | `f0148ecaba91d7ff…` | `1aaca63b0a17d675…` |
| `F04-000b` | M1: sudo con clave débil → root | 96 B | 12361 B | `4161efaf3fd6b7e1…` | `79d1a3ebf82ebd81…` |
| `F04-001` | M2 Redis sin auth: PONG, 6.2.6, requirepass vacío | 134 B | 14194 B | `c75c5b1f251a70e3…` | `0cbaf30c6e084297…` |
| `F04-001b` | M2 Redis: datos y intento CVE-2022-0543 | 278 B | 21566 B | `d337135aac699b0c…` | `86d91a5a2a3fe2c5…` |
| `F04-002` | M3 FTP anónimo: backups y credenciales.txt | 381 B | 16423 B | `e4e2c6595e35dcf2…` | `aebdfddb9cb69eca…` |
| `F04-003` | M2 MariaDB por túnel SSH: wordpress, 12 tablas | 92 B | 18295 B | `b435985eb38eb1a0…` | `ab7fb6456fb5e7c1…` |
| `F04-004` | M1 wp-config.php: credenciales de BD | 173 B | 15730 B | `792a648df1f592cb…` | `72cf7dd4fac9cedf…` |
| `F04-004b` | Moodle: DB moodle_db y 487 tablas | 208 B | 21716 B | `19de8c6b4d348599…` | `85824bc40daa3d7a…` |
| `F04-005` | M3 SMB shares backups/IPC$ | 396 B | 13562 B | `6e8e8034e7f9db83…` | `371808f344d60086…` |
| `F04-006` | M3 NFS no_root_squash: archivo root | 140 B | 17905 B | `2e2917e5f6efd744…` | `9c1b445459ed4a58…` |
| `F04-008` | M5 VNC: `Authentication: None` | 455 B | 21407 B | `4ef2e8c19208bee8…` | `183bc390ef907079…` |
| `F04-009` | M5 escritorio remoto vía VNC (sin clave) | 541 B | 11334 B | `c6bd8c217c710478…` | `1ad2488ef94350d2…` |
| `F04-010` | M5 interacción remota: menú de inicio | — | 166511 B | `—` | `f81c374787ebc43c…` |
| `F04-011` | M5 `whoami` en consola: `desktop-dt5f05n\cliente` | — | 20474 B | `—` | `9830e8ee48cb5a90…` |
| `F05-001` | M5 marcador `PWNED-M5` en el escritorio | — | 28518 B | `—` | `f4d5421bae8ba550…` |
| `F04-007` | M5 SMB con `cliente` / `Admin13.-` por túnel desde M1 | 920 B | 23219 B | `36f173c098d835c4…` | `a379c9495bd6153e…` |
| `F04-012` | M4 AXFR: zona `uni.lab` completa (S4) | 680 B | 24993 B | `67988476208c2f13…` | `27bfcf53b87a5b92…` |
| `F04-013` | M4 SMB signing desactivado (S5) | 428 B | 21424 B | `fc212677c0d39dad…` | `9bbfb1665a7e5c27…` |
| `F04-014` | M4 autenticación fallida con `Admin13.-` | 300 B | 15990 B | `7b42045fd7e54195…` | `3f3256d1beff2a78…` |
| `F05-002` | M1 marcador `PWNED-M1` servido por HTTP | 117 B | 18363 B | `734c15e8fde99c5e…` | `adb84066d6860127…` |
| `F04-015` | M4 admin con `Administrador` / `password_2026` (S3) | 1831 B | 38124 B | `6e4bba63d6c77f80…` | `2d88fac72e1d926e…` |
| `F04-016` | M4 PrintNightmare: check vulnerable + exploit sin sesión (S2) | 4075 B | 140117 B | `df1197a39b9dcfaa…` | `2e10f7df9ec6bd93…` |
| `F04-017` | M4: `nt authority\system` vía tarea programada por WinRM | 1327 B | 35314 B | `28916fb819ed8203…` | `9a67b17355c70bfb…` |
| `F05-003` | M4: creación del marcador en `LegacyShare` | 1062 B | 27247 B | `d11edb892e8e9950…` | `222e4266007b6ada…` |
| `F05-003b` | M4: `PWNED-M4.txt` leído por SMB | 455 B | 20938 B | `19a62b385ee8bbb0…` | `18c674dd8a83aaad…` |
| `F06-001` | M1: W5 403, W6 500, W7 403 | 55 B | 14682 B | `a2025370311615af…` | `207cec5966799194…` |
| `F06-001b` | M1: `info.php` eliminado (sin phpinfo) | 126 B | 16966 B | `32fb60b196300ffd…` | `7215f9d1bc61cfe5…` |
| `F06-002` | M3: FTP/SMB cerrados + NFS deniega root | 553 B | 29390 B | `f69750e34c260b8c…` | `884aedb442b1bccb…` |
| `F06-003` | M4: AXFR falla, SMB1 off, signing on, Spooler off | 2047 B | 40046 B | `d8202009ed1cc64c…` | `c72ecfb13d083933…` |
| `F06-004w` | M5: TightVNC Stopped/Disabled; 5900 sin listener | — | 258308 B | `—` | `40431e628fee55cd…` |
| `F06-005` | M5: SMB1 False + NLA `UserAuthentication=1` | — | 290433 B | `—` | `7edfd01ec4981522…` |
| `F06-006b` | M5: clave de `cliente` cambiada y requerida | — | 320577 B | `—` | `28b25d322af62826…` |
| `F06-007` | M4: mitigación final S1/S2/S3/S4/S5 | 2529 B | 46913 B | `216f857ca22309a7…` | `f1399e8f42c07aef…` |
| `F07-001` | Retest M1: W1 403, W3 500, W5 403, W6 sin phpinfo, W7 403, W2 Off | 117 B | 22235 B | `9b5de6c659fbd383…` | `400b631dda0e75a2…` |
| `F07-002` | Retest M3: FTP/SMB cerrados, `root_squash`, sin credenciales | 553 B | 37374 B | `42af5778a0489672…` | `9f352ed508713c50…` |
| `F07-003` | Retest M4: clave vieja falla, AXFR denegado, SMB1 off, Spooler off | 2529 B | 47632 B | `1c83bb72a6fc1739…` | `7e34d9370bc9e119…` |
| `F07-004` | Retest M5: VNC filtrado, 3389 abierto, SMB filtrado | 570 B | 31919 B | `875cd6794534c66d…` | `3993aa30551ad6f7…` |
| `F04-018` | M2: D1/D2/D3 validados (PONG, 6.2.6, wordpress) | 413 B | 30402 B | `9d0987b6e29048aa…` | `3a8e04188d2ff8bd…` |
| `F04-019` | M2: D4 (`public`/`private`, socket 161) | 485 B | 24161 B | `509f0363f8a49e58…` | `0be40f825c34a3a5…` |
| `F06-008` | M2: mitigación (`requirepass`, claves, UFW, SNMP) | 819 B | 34644 B | `4fb390cbd3c65b6d…` | `2fde9a5e47497129…` |
| `F07-005` | Retest M2: NOAUTH/timeout, vieja denegada, todo filtrado | 523 B | 34573 B | `6b87f1c91b6f1852…` | `8dadf8ef5712df60…` |

> `F04-010`, `F04-011` y `F05-001` son capturas de la ventana VNC, no de una terminal local; por eso no tienen `.log` de terminal. La evidencia es la imagen y el hash.

---

## Pre-0 · Artefactos y FTP (2026-10-27)

| ID | Qué demuestra | Log | PNG | SHA256 log (16) | SHA256 PNG (16) |
|---|---|---|---|---|---|
| `LOG-000-04` | 19 artefactos con SHA256 OK y descarga local del rol m6 | 1335 B | — | `456ff2366810ea1a…` | — |
| `LOG-000-05` | Servidor FTP en `10.10.10.20:2121` y transferencias | 17344 B | — | `712e2892351d6b83…` | — |
| `LOG-000-06` | M1 descarga WP/PHP/Apache/Moodle + fixed; hashes OK | 1058 B | — | `f78dc29434ccea9d…` | — |
| `LOG-000-07` | M2 descarga Redis 6.2.6/6.2.7; hashes OK | 334 B | — | `6084904a67f801f0…` | — |
| `LOG-000-08` | M3 descarga Samba 4.5.9/4.5.10 y vsftpd; hashes OK | 503 B | — | `71a5e486ed1e6b17…` | — |
| `EV-000-10` | Versiones instaladas M1–M5 (WP 7.0.1, PHP 8.4.26, Apache 2.4.49, Redis 6.2.6, Samba 4.5.10, M5 filtrado) | 1204 B | 78 KB | `037657df3c03d9df…` | `1ddc100f350859af…` |
| `EV-000-11` | Auditoría de estado vulnerable: W1/W3/W4/W5/W6/W7 OK; W2 y B1 pendientes; M4 con `soporte`; M5 filtrada | 2961 B | 120 KB | `0af178c6ec02bef0…` | `132c612a45baa510…` |
| `EV-W2-01` | W2: Apache prefork, PHP 8.4.26 NTS, php.ini, offsets y target de sesión | 1093 B | 75 KB | `535550c1e379e165…` | `1d3c075a78dcf705…` |
| `EV-W2-ROOT` | M1: `ubuntu/Admin13.-` + `sudo` → `uid=0(root)` y `/etc/shadow` | 693 B | 43 KB | `f265b916439adaae…` | `16df7be7309a730b…` |
| `EV-W2-02` | Intento final W2: sesión compartida, OOM, `HEAP_LEAK_FAILED`, sin `/tmp/p1` | 1057 B | 72 KB | `3cd7486b71fd69b2…` | `c59746aff05d47e5…` |
| `EV-W2-03` | Reintento W2 con `cleanup=On`: mismo `HEAP_LEAK_FAILED`, sin `/tmp/p1` | 1052 B | 72 KB | `ef157cef472aee23…` | `a2e2e70846bbe315…` |
| `EV-W2-04` | W2 con PHP del set oficial (sin `intl/gd/exif`) y Apache mínimo en 8081: `HEAP_LEAK_FAILED` | 1119 B | 79 KB | `714c265b107b7475…` | `b00cfdea8eb20b79…` |
| `EV-W2-05` | W2 contra target oficial `php:8.4.26-apache` (Docker), offsets reales `0x465370/0x65eb60`: `HEAP_LEAK_FAILED` | 1218 B | 85 KB | `9427fc9342304bc8…` | `e197fb6acc249231…` |
| `EV-ROOT-CHAIN` | B3 FTP anónimo expone `Admin13.-` → reutilizada en `ubuntu` M1 → `sudo` → `root` | 750 B | 45 KB | `6b9696235223f989…` | `9bf7486db69bc8d8…` |
| `EV-W2-06` | CVE-2026-109618 estilo Datadog: OOM del parser a ~3.00MB, 16M, sin fuga `PHPSESSID` y sin RCE | 908 B | 53 KB | `f6fc04843c1c2fca…` | `3ab8d494bad82869…` |
| `EV-W2-07` | **Chain A** (`ikow/php2shell-poc`) desde M1: session injection + LFI → `uid=33(www-data)` | 651 B | 42 KB | `e9916fa598a6f11f…` | `4d70ad73306cdf16…` |
| `EV-W2-08` | Chain A completa + marcador `PWNED-M1-www-data` y verificación HTTP | 919 B | 56 KB | `2567481dc62faf0d…` | `a93f0a7c466f54d4…` |
| `EV-W2-09` | ROOT en M1 por B3/sudo + `/root/PWNED-M1-root.txt` | 516 B | 34 KB | `30ebe1ebb93b76a9…` | `b457edc6ac57325c…` |
| `EV-007-RETEST` | Retest Fase 6: versiones, W1/W3/W5/W6/W7, W4, SSH, Redis/DB/UFW, FTP/NFS/Samba, SMB/Spooler/admin/AXFR, M5 | 2769 B | 106 KB | `edbe0ae23cc03d69…` | `9c476d90c43f65ba…` |

> Los `LOG-000-0x` son logs de transferencia (sin captura de ventana). `EV-000-10` sí tiene captura y log.

---

## Evidencias pendientes (VM apagadas o prueba no ejecutada)

| ID previsto | Qué falta | Motivo |
|---|---|---|
| `F04-017` | M4 privesc a SYSTEM (reintento S2) | PrintNightmare `check` vulnerable, pero el primer `run` no creó sesión; M4 se cayó |
| `F04-018` | M4 S1 EternalBlue | `enum4linux-ng` reporta `SMB1 only: false`; el scanner no accede a IPC$ → no explotable por esta vía |
| `F05-003` | Impacto M2/M3/M4 | M2 caída; M3/M4 sin sesión de escritura/shell |
| `F06-...` | Mitigación | Pendiente de aplicar parches |
| `F07-...` | Retest | Depende de la mitigación |

---

## Cómo verificar

```bash
cd informe
sha256sum -c evidencias/hashes.txt
```

Si algún hash no coincide, la evidencia fue modificada y no debe usarse en el informe.
