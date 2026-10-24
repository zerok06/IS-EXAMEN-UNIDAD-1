# Guía R0 · Red plana + separación lógica (solo MitraStar)

**Responsable:** coordinador del grupo. El MitraStar YA quedó configurado (§2 hecho); aquí va lo que falta para que el modelo "una sola puerta + pivote" se cumpla **por firewall de cada VM**.

## 1. Modelo real (un solo router)

```text
MitraStar WiFi "LAB-INT" 10.10.10.0/24 (DHCP OFF, sin DSL)
 ├── M1 .11 · M2 .12 · M3 .13 · M4 .14 · M5 .15 (VMs en bridge al WiFi)
 └── M6 .20 (Kali en bridge al mismo WiFi)
```

No hay DNAT (misma subred) ni segundo segmento: la separación es **lógica** y la impone el firewall de cada máquina + la disciplina de M6. Se documenta así en el informe, sin mentir (§15 guía: alcance por encadenamiento, no por topología).

## 2. MitraStar DSL-2401HN-T1C (YA HECHO ✓)

- [x] Entrar a `http://192.168.1.1` (anotar usuario que funcionó).
- [x] Red → LAN: IP `10.10.10.1/24`, **DHCP OFF**.
- [x] WiFi SSID `LAB-INT`, WPA2-PSK, canal 1 (o 5 GHz libre).
- [x] OFF: UPnP, WPS, admin remota WAN, WiFi invitado.
- [x] Cable DSL/teléfono **desenchufado** (foto para anexos).
- [x] Firmware anotado (Estado → Versión).

## 3. Separación lógica: cada VM solo acepta lo suyo

### 3.0 DNS: quién apunta a quién (no confundir)

| Equipo | Su DNS debe ser | Dónde se configura |
|---|---|---|
| M1, M2, M3, M5, M6 | `10.10.10.14` (M4) | IP estática de cada VM (netplan / adaptador Windows) |
| M4 | `127.0.0.1` (él mismo) | Su propia IP estática |
| MitraStar | irrelevante (DHCP OFF + sin DSL: no reparte DNS a nadie) | No tocar |

> M4 resuelve **solo** `uni.lab` (sin reenviadores: no hay internet). Que `nslookup google.com` falle es **normal y esperado**; lo que debe funcionar es `nslookup wp.uni.lab 10.10.10.14`.

Regla: **M2–M5 solo aceptan tráfico de M1 (`10.10.10.11`)**, salvo DNS (53) que M4 abre a la LAN para que M5 resuelva. M1 acepta 80/443 de toda la LAN (es la puerta). M6 puede *ver* todo en el escaneo, pero **solo ataca M1:80/443 hasta tener el pivote** (disciplina de bitácora + §14 guía).

```bash
# M2 y M3 (UFW): ya lo hacen sus playbooks/guías. Repaso:
sudo ufw allow from 10.10.10.11 to any port 3306 proto tcp  # M2 ejemplo
```

```powershell
# M4 (PowerShell admin): SMB/RDP/DNS así (no "toda la LAN" a ciegas)
New-NetFirewallRule -DisplayName "SMB solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 445 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "RDP solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 3389 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "DNS LAN" -Direction Inbound -Protocol UDP `
  -LocalPort 53 -RemoteAddress 10.10.10.0/24 -Action Allow
# No crear regla "Block" para 445: en Windows Block gana sobre Allow y también
# bloquearía a M1. La política por defecto ya deniega el resto.
```

```powershell
# M5 (PowerShell admin): igual, solo M1 entra
New-NetFirewallRule -DisplayName "SMB solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 445 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "RDP solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 3389 -RemoteAddress 10.10.10.11 -Action Allow
New-NetFirewallRule -DisplayName "VNC solo M1" -Direction Inbound -Protocol TCP `
  -LocalPort 5900 -RemoteAddress 10.10.10.11 -Action Allow
# Sin regla Block: la política por defecto deniega el resto.
```

> M1 **no** se restringe (debe servir 80/443 a M5 y M6). M6 no filtra nada (atacante).

## 4. VMs por WiFi (las 6 laptops)

- Adaptador en **bridge sobre la WiFi** + **"Replicate physical network connection state"** en VMware.
- Las 6 al `LAB-INT` con IP fija (.11–.15, .20).
- Gate de Fase 1: `ping` entre vecinos ANTES de seguir; si un laptop no cruza, probar 5 GHz o actualizar su driver WiFi.

## 5. Verificación (evidencia para el informe)

Desde M6 (`10.10.10.20`):

```bash
curl -sI http://10.10.10.11 | head -3        # 200 OK (la puerta)
nmap -Pn -p 445 10.10.10.14                  # filtered/closed DESDE M6 (FW de M4) [*]
ping -c 2 10.10.10.11 && ping -c 2 10.10.10.14
```

[*] Si el escaneo muestra 445 open desde M6 es que falta la regla DROP: corregir y repetir. Desde M1 (`proxychains` tras el pivote) el mismo puerto sí debe responder: esa pareja demuestra el encadenamiento.

Desde M1–M5: `ping -c 2 10.10.10.1` y entre vecinos OK. DNS: `nslookup wp.uni.lab 10.10.10.14` OK desde M5/M6. Capturar todo con fecha.
