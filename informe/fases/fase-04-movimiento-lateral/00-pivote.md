# Fase 4.0 · Pivote hacia la LAN interna

**Objetivo:** usar el acceso a M1 para alcanzar M2–M5, manteniendo el relato “una puerta + movimiento lateral”.
**Ejecuta:** M6 `10.10.10.20` → M1 `10.10.10.11`.

---

## 4.0.1 Vías disponibles

| Vía | Comando | Estado | Uso |
|---|---|---|---|
| **SSH a M1** | `ssh ubuntu@10.10.10.11` (clave `Admin13.-`) | ✅ validado | Pivote simple para el demo |
| **Túnel SSH local** | `ssh -L 13306:10.10.10.12:3306 ubuntu@10.10.10.11 -N` | ✅ validado | MySQL/MariaDB desde Kali |
| **ligolo-ng** | `ligolo-proxy` + `ligolo-agent` | ✅ instalado (`v0.9.2`) | Túnel IP completo; sirve NFS/VNC/RDP |
| **proxychains** | `proxychains4 <comando>` | ✅ instalado | Con un SOCKS de MSF/SSH |
| **Metasploit route** | `route add 10.10.10.0/24 <session>` | ✅ disponible | Exploits MSF |

---

## 4.0.2 Evidencia del pivote

```bash
sshpass -p 'Admin13.-' ssh ubuntu@10.10.10.11 'id; hostname; ip -brief a'
```

**Salida real** (`F04-000`):

```text
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),110(lxd)
m1-app
ens33  UP  10.10.10.11/24
```

La cuenta `ubuntu` está en `sudo` y la misma clave permite root (`F04-000b`). Con eso el pivote queda resuelto.

Túnel MySQL validado (`F04-003`):

```bash
sshpass -p 'Admin13.-' ssh -N -L 13306:10.10.10.12:3306 ubuntu@10.10.10.11 &
mysql --skip-ssl -h 127.0.0.1 -P 13306 -u wp_user -p'wp_pass123' -e 'SHOW DATABASES;'
```

---

## 4.0.3 Nota sobre el modelo de red

El diseño decía “M2–M5 solo aceptan a M1”. La realidad muestra:

- **M4:445** abierto desde M6.
- **M5:5900 y 3389** abiertos desde M6.

Por eso el demo puede ser directo, pero el informe documenta la **desviación de firewall** y la corrige en la fase 6. El pivote SSH se conserva como la vía prevista y como evidencia de encadenamiento.

---

## 4.0.4 Checklist de pivote

- [x] Acceso SSH a M1.
- [x] Root en M1 vía sudo.
- [x] Túnel MySQL a M2.
- [ ] Túnel VNC/RDP a M5 (pendiente de que M5 esté encendida).
- [ ] Túnel SMB a M4 (pendiente de que M4 esté encendida).
- [ ] ligolo-ng probado end-to-end (opcional; queda documentado).
