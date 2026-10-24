# Automatización Ansible · cada laptop ejecuta su playbook

**Kali (M6) y el MitraStar (R0) no llevan playbook**: Kali ya lo tienes y R0 lo configuras tú a mano (guia-R0). Aquí solo M1–M5.

## 0. Qué instala cada laptop (una vez, con Internet)

```powershell
# En Windows: instalar WSL2 + Ubuntu 22.04 (Microsoft Store)
wsl --install -d Ubuntu-22.04
```

```bash
# Dentro de WSL2 Ubuntu:
sudo apt update && sudo apt install -y python3-pip sshpass git
pip install --user ansible pywinrm
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc && source ~/.bashrc
ansible --version   # 2.15+ aprox
cd /mnt/c/RUTA/del/repo/ansible
ansible-galaxy collection install -r requirements.yml
```

## 1. Preparación mínima MANUAL de tu VM (5 min, antes del playbook)

| Tu VM | Hacer a mano (el playbook NO lo hace) |
|---|---|
| M1/M2/M3 | Instalar Ubuntu 22.04.5 de la ISO + IP estática + `sudo apt install -y openssh-server` + usuario `labadmin` con clave (o llave) |
| M4/M5 | Instalar Windows de la ISO + IP estática + renombrar equipo + en PowerShell admin: `Enable-PSRemoting -Force` y abrir el puerto 5985 solo a tu laptop |

WinRM rápido (M4/M5, PowerShell admin, SOLO laboratorio):

```powershell
winrm quickconfig -q
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
New-NetFirewallRule -DisplayName "WinRM Ansible" -Direction Inbound -Protocol TCP -LocalPort 5985 -RemoteAddress <IP-tu-laptop> -Action Allow
```

## 2. Ejecución (una línea por máquina, desde WSL2)

```bash
# Edita PRIMERO las vars del play (contraseñas CAMBIAR_*). M3/M4/M5 usan la MISMA clave débil.
ansible-playbook -i inventories/m1.ini play-m1-app.yml       # Estudiante 1
ansible-playbook -i inventories/m2.ini play-m2-db.yml        # Estudiante 2
ansible-playbook -i inventories/m3.ini play-m3-backup.yml    # Estudiante 3
ansible-playbook -i inventories/m4.ini play-m4-windows.yml  # Estudiante 4
ansible-playbook -i inventories/m5.ini play-m5-client.yml    # Estudiante 5
```

Verde todo = OK. Rojo = lee el error, corrige, repite (los plays son re-ejecutables).

## 3. Después del playbook (manual, 10 min)

1. Pasos web interactivos que Ansible no hace: instalador web de WordPress/Moodle (M1) con clave débil (W4), instalador TightVNC→auth None (M5, C4).
2. Snapshot `estado-inicial-vulnerable` (guia-00 §5).
3. Checklist de tu `guia-M*.md` + anunciar al coordinador.
4. Poner fecha de snapshot en el registro (§12 del doc).

## 4. Archivos

| Archivo | Qué hace |
|---|---|
| `ansible.cfg` | Sin `host_key_checking` (lab), timeouts |
| `requirements.yml` | Colecciones `ansible.windows` + `community.windows` |
| `inventories/mX.ini` | Tu VM: IP, usuario, conexión (editar antes de correr) |
| `play-mX-*.yml` | TODO lo demás: versiones fijadas + vulns plantadas |
| `files/` | Pon aquí los MSI/tarballs si NO hay Internet al ejecutar |
