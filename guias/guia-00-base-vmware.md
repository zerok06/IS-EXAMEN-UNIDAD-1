# Guía 00 · Base VMware + red (común a M1–M6)

**Para los 6 estudiantes. Leer primero.**

## 1. Modelo de red del laboratorio (una sola red, sin máquinas extra)

```text
WiFi LAB-INT  10.10.10.0/24  (MitraStar .1, DHCP OFF, sin DSL)
┌────┬────┬────┬────┬────┬────┐
│ M1 │ M2 │ M3 │ M4 │ M5 │ M6 │
│.11 │.12 │.13 │.14 │.15 │.20 │
└────┴────┴────┴────┴────┴────┘
 Puerta: M1:80/443 · DNS en M4 · Separación lógica por FW + disciplina
```

- **Las 6 laptops** al WiFi `LAB-INT` del MitraStar. Sin R1, sin Router2, sin nada más.
- **DNS vive en M4** (Windows DNS standalone, zona `uni.lab`): es la máquina de "servicios de red" (Fase 1 de la guía) y no requiere otra VM.
- Tu VM **siempre en bridge** al WiFi con su IP fija.

## 2. Configuración VMware (Workstation Player/Pro 17+)

> Hipervisor: VMware Workstation Player o Pro 17+ desde el **portal de soporte de Broadcom** (cuenta gratuita; el enlace directo cambió tras la migración, buscar "VMware Workstation download" en el portal). Alternativa válida según la guía: VirtualBox con Guest Additions (los pasos de red son idénticos: bridge + IP estática).

1. VM → Settings → Network Adapter → **Bridged** (+ "Replicate physical network connection state" si tu laptop va por Wi-Fi).
2. En el SO invitado: **IP estática** según tu guía (gateway + DNS indicados ahí). Nada de DHCP.
3. Instalar `open-vm-tools` (Linux) / VMware Tools (Windows) y activar sincronía de hora.
4. Desactivar carpetas compartidas, drag&drop y copiar/pegar con el host durante la práctica.
5. Snapshots: ver §5 (paso a paso obligatorio, con nombres y cuándo tomarlos).
6. Clon de respaldo: VM → Manage → Clone (full clone) antes de la Fase 2.

## 3. Verificación de red (cada uno desde su VM)

```bash
# Linux (M1, M2, M3, M6)
ip -brief a
ip route | grep default
ping -c 2 <gateway>
ping -c 2 <vecino>
```

```powershell
# Windows (M4, M5)
ipconfig /all
ping <gateway>
Test-NetConnection <vecino> -Port <puerto>
```

## 4. Reglas de convivencia

- No escanear/atacar fuera de tu alcance (M6: solo `10.10.10.11:80` + pivote autorizado; el resto le responde filtrado por FW).
- Nada de Internet con servicios vulnerables activos (parches: antes de aislar o en máquina limpia).
- Cada cambio de IP/config se avisa al coordinador y se anota con fecha.

## 5. Snapshots de la VM (paso a paso, obligatorio)

El snapshot es tu "botón de rebobinar": sin él no hay réplica en vivo ni reintentos seguros. **La guía del curso lo exige** (Fase 0: `estado-inicial-vulnerable` + `estado-parcheado`).

### 5.1 Cómo tomar un snapshot (VMware Workstation Player/Pro)

1. Apaga servicios que escriban mucho si puedes (o al menos deja la VM quieta 1 min). En Linux: `sudo sync`. En M4 (Windows): mejor con la VM **apagada**.
2. Con la VM seleccionada (puede estar encendida): **VM → Snapshots → Take Snapshot…**
3. Nombre EXACTO según la tabla §5.3 + descripción con fecha, p. ej. `M1 + Apache 2.4.49 + WP 7.0.1 listo, 2026-10-24`.
4. Pulsar **Take Snapshot** y esperar a que termine (no apagar el laptop a medias).
5. Verificar: **VM → Snapshots → Snapshot Manager** — debe aparecer en el árbol con fecha/hora.

### 5.2 Cómo restaurar (volver atrás)

1. Cierra lo que estés haciendo en la VM (o apágala si el PoC la dejó colgada).
2. **VM → Snapshots → Snapshot Manager** → selecciona el snapshot → **Go To**.
3. Confirma; VMware revierte disco + memoria al momento guardado.
4. Arranca y verifica con tu checklist (ping + servicio arriba) antes de repetir el PoC.
5. Para la demo en vivo: restaura `estado-inicial-vulnerable` DELANTE del público (es parte del show).

### 5.3 Cuándo tomarlos (calendario obligatorio)

| Snapshot | Cuándo | Para qué |
|---|---|---|
| `00-base` | SO + red + IP estática OK | Punto cero |
| `01-<rol>-listo` | Servicios instalados (sin vulns aún) | Reinstalar rápido |
| `estado-inicial-vulnerable` | Vulns implantadas + red verificada | **Réplica del ataque / demo en vivo** |
| `previo-a-<CVE>` | Antes de CADA PoC (W1, D1, B2, S1…) | Reintentar sin reconstruir |
| `estado-parcheado` | Tras Fase 5 (todo remediado) | Demo del antes/después |

### 5.4 Snapshot vs clon (no son lo mismo)

| | Snapshot | Clon full |
|---|---|---|
| Qué es | Foto del estado dentro de la misma VM | Copia completa e independiente |
| Sirve para | Rebobinar en segundos | Respaldo si se corrompe la VM |
| Cuándo | Antes de cada PoC y fase | Una vez, antes de la Fase 2 |
| Ruta | VM → Snapshots → Take Snapshot | VM → Manage → Clone → Full clone |

### 5.5 Errores típicos (evítalos)

- Cadena de 15 snapshots encadenados: consolida (restaura el bueno y borra los intermedios viejos).
- Snapshot con la VM a medio PoC: siempre sobre estado **limpio y verificado**.
- Quedarse sin disco en el host: cada snapshot crece; deja ≥20 GB libres por VM.
- Olvidar el `previo-a-<CVE>`: un PoC fallido sin snapshot = reconstruir la VM.
- No anotar fecha/descripción: en el informe cada snapshot lleva su registro (§12 del doc).
