# Specs por vulnerabilidad · Fase 4

> Un archivo por vulnerabilidad. Cada uno tiene ficha, precondiciones, snapshot, flujo concreto, evidencia, impacto, fallback, remediación, retest y EARS.
> La revalidación de versiones está en [`docs/VALIDACION-VULNERABILIDADES.md`](../../../docs/VALIDACION-VULNERABILIDADES.md).

## 1. Estado

| ID | VM | Tipo | Estado | Spec |
|---|---|---|---|---|
| W1 | M1 | CVE-2026-63030 | Válida; PoC pendiente | [`W1-wp2shell.md`](./W1-wp2shell.md) |
| W2 | M1 | CVE-2026-109618/19 | Válida con cambio | [`W2-php2shell.md`](./W2-php2shell.md) |
| W3 | M1 | CVE-2021-41773 | Válida con cambio | [`W3-apache-41773.md`](./W3-apache-41773.md) |
| W4 | M1 | Config | Validada | [`W4-wp-admin.md`](./W4-wp-admin.md) |
| W5–W7 | M1 | Config | Validadas | [`W5-W7-config.md`](./W5-W7-config.md) |
| M1-SSH | M1 | Config | Validada | [`M1-SSH.md`](./M1-SSH.md) |
| D1 | M2 | CVE-2022-0543 | **No reproducible** | [`D1-redis.md`](./D1-redis.md) |
| D2–D4 | M2 | Config | Validadas | [`D2-D4-config.md`](./D2-D4-config.md) |
| B1 | M3 | CVE-2017-7494 | Válida con cambio | [`B1-samba.md`](./B1-samba.md) |
| B2 | M3 | CVE-2011-2523 | **No reproducible** | [`B2-vsftpd.md`](./B2-vsftpd.md) |
| B3–B5 | M3 | Config | Validadas | [`B3-B5-config.md`](./B3-B5-config.md) |
| S1 | M4 | CVE-2017-0144 | **No aplicable** | [`S1-eternalblue.md`](./S1-eternalblue.md) |
| S2 | M4 | CVE-2021-34527 | Válida con cambio | [`S2-printnightmare.md`](./S2-printnightmare.md) |
| S3–S5 | M4 | Config | Validadas | [`S3-S5-config.md`](./S3-S5-config.md) |
| C1 | M5 | CVE-2017-0144 | **No aplicable** | [`C1-eternalblue.md`](./C1-eternalblue.md) |
| C2–C3 | M5 | Config | Validadas | [`C2-C3-config.md`](./C2-C3-config.md) |
| C4 | M5 | Config | Validada | [`C4-vnc.md`](./C4-vnc.md) |

## 2. Orden recomendado

1. **W1** → shell `www-data` (principal).
2. **W4** → respaldo si W1 falla.
3. **W3** → segundo CVE 9.8 si CGI está operativo.
4. **W2** → time-box; si falla, documentar.
5. **M1-SSH** → root y pivote.
6. **D2/D3/D4** → datos y SNMP.
7. **B3/B4/B5** → credenciales de M4/M5.
8. **B1** → Samba 4.5.9.
9. **S3/S4/S5** → acceso admin, AXFR, signing.
10. **S2** → privesc desde `soporte` a SYSTEM.
11. **C2/C3/C4** → cierre de M5.
12. **D1/B2/S1/C1** → documentar como no reproducibles/no aplicables.

## 3. Formato

Cada spec tiene:

- Ficha de versión y CVE.
- Precondiciones.
- Snapshot.
- Flujo concreto (comandos simples).
- Resultado esperado.
- Evidencia.
- Impacto y siguiente salto.
- Fallback.
- Remediación.
- Retest.
- EARS.
- Checklist.

## 4. Reglas

- Snapshot `previo-a-<ID>` antes de cada PoC.
- `id`/`whoami`/archivo como prueba.
- No se afirma éxito sin evidencia.
- Si falla, se documenta la limitación y el fallback.
- No se borran logs ni backups.
