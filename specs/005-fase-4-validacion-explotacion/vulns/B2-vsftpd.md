# B2 · vsftpd 2.3.4 · CVE-2011-2523

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M3 `10.10.10.13` |
| Servicio | vsftpd |
| Versión instalada | **2.3.4 limpio** |
| Rango vulnerable | solo el tarball troyanizado 2011-06-30…2011-07-03 |
| Versión que corrige | 2.3.4 limpio / 3.x |
| CVSS | **9.8** v3.1 |
| CWE | CWE-78 |
| NVD | https://nvd.nist.gov/vuln/detail/CVE-2011-2523 |
| Artefacto | `artifacts/vulnerable/vsftpd-2.3.4.tar.gz` (limpio) |
| Estado | **No reproducible con el tarball limpio** |

## 2. Por qué no reproduce

El backdoor `:)` solo existe en el tarball distribuido entre el **30-jun-2011** y el **03-jul-2011**. El tarball oficial limpio tiene el banner `220 (vsFTPd 2.3.4)` pero **no abre el puerto 6200**.

Evidencia:

```bash
nc -zv 10.10.10.13 21
nc -zv 10.10.10.13 6200
```

## 3. Alternativa

- **B3**: FTP anónimo + `credenciales.txt` (real).
- **B4**: NFS `no_root_squash` (real).
- **B5**: SSH débil (real).
- **B1**: Samba 4.5.9 (real).

No se usa el binario troyanizado: no se guarda malware en el repositorio.

## 4. Evidencia de la limitación

- `EV-B2-01`: banner `220 (vsFTPd 2.3.4)`.
- `EV-B2-02`: `nc 6200` cerrado.
- `LOG-B2`.

## 5. Remediación

- Reemplazar por **vsftpd 3.0.5** (`artifacts/fixed/vsftpd-3.0.5.tar.gz`).
- `anonymous_enable=NO`.
- Backups cifrados.

## 6. Retest

```bash
nc -zv 10.10.10.13 6200   # cerrado
curl -s ftp://anonymous:anonymous@10.10.10.13/  # 530
```

## 7. EARS

- **REQ-B2-01 (No deseado).** SI el tarball es limpio, ENTONCES el laboratorio NO DEBE afirmar el backdoor de CVE-2011-2523.
- **REQ-B2-02 (Ubicuo).** La limitación DEBE documentarse y M3 DEBE sostener B1/B3/B4/B5.

## 8. Checklist

- [ ] Banner 2.3.4.
- [ ] `:6200` cerrado.
- [ ] Limitación documentada.
- [ ] Alternativa B3/B4/B5.
