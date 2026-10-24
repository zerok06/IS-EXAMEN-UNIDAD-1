# Guía M6 · Kali en la LAN + pivote (Estudiante 6)

**Rol:** auditor. Estás en la **misma LAN** (`10.10.10.20`), pero con disciplina + firewall ajeno: **solo atacas M1:80/443** hasta tener el pivote. El resto se alcanza **pivotando desde M1**.

## 0. Imagen base y herramientas

| Qué | Origen (verificado 2026-10-24) |
|---|---|
| Kali Linux 2024.x **imagen VMware** (no ISO: importar el `.7z` de 64-bit) | https://www.kali.org/get-kali/ → "Virtual Machines" → VMware |
| ligolo-ng (agente + proxy para el pivote) | https://github.com/nicocha30/ligolo-ng (descargar ANTES de aislar) |
| Herramientas (vienen en Kali; verificar) | `nmap wpscan nikto enum4linux-ng nxc hydra sqlmap redis-tools snmp onesixtyone metasploit-framework proxychains4` |

```bash
sudo apt update && sudo apt install -y metasploit-framework postgresql \
  whatweb nikto gobuster smbclient enum4linux hydra sqlmap dnsutils \
  redis-tools snmp onesixtyone ldap-utils proxychains4
sudo msfdb init && msfconsole -q -x "version; exit"
```

## 1. VM y red (3 NICs: lab + internet + repuesto)

- Kali 2024.x · 2 vCPU · 4 GB · 40 GB.
- **eth0 en bridge al WiFi `LAB-INT`**: estática `10.10.10.20/24`, `never-default`, DNS `10.10.10.14` → ataque.
- **eth2 en NAT (VMnet8)**: DHCP (`192.168.97.x`) → internet/descargas. **Desconectarlo antes de atacar** y evidenciar `ping 8.8.8.8` fallando + lab respondiendo.
- eth1 (`192.168.50.x`, sin gateway): ignorar o desconectar.
- `/etc/hosts`: `10.10.10.11 wp.uni.lab moodle.uni.lab app.uni.lab` (nombres del lab sin depender del DNS para HTTP).

```bash
ip -brief a
curl -sI http://10.10.10.11 | head -3     # WordPress de M1 (la puerta)
nmap -Pn -p 445 10.10.10.14               # filtered (FW de M4) = evidencia del modelo
ping -c 2 10.10.10.11 && ping -c 2 10.10.10.14
```

## 2. Paso 1 · Entrar por el web (M1)

```bash
nmap -sS -sV -O -p- --min-rate 1000 10.10.10.11
wpscan --url http://10.10.10.11 --enumerate vp,vt,u
curl -sI http://10.10.10.11 | grep -iE 'server|x-powered-by'   # Apache 2.4.49 + PHP 8.4.26
nikto -h http://10.10.10.11
# PoC wp2shell (W1) o PHP2Shell (W2) contra 10.10.10.11 -> shell www-data en M1
```

## 3. Pasos 2–5 · Pivote hacia la LAN interna

Con shell en M1, levanta el túnel (elige UNA vía y documéntala):

- **A. Metasploit:** `route add 10.10.10.0/24 <session>` + `proxychains nmap ...`
- **B. ligolo-ng:** agente en M1 + interfaz `ligolo` en Kali.
- **C. sshuttle:** si h
...[truncated 911 chars]