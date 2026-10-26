# FTP · transferencia de artefactos a las VM

> El servidor FTP se levanta en **M6** (`10.10.10.20:2121`), dentro de la LAN aislada. Las VM descargan solo lo que necesitan. No hay Internet durante la transferencia.

## 1. Preparar M6

Copiar la carpeta `artifacts/` a M6 (USB, carpeta compartida o `scp` desde el host antes de aislar):

```bash
# En M6
mkdir -p ~/artifacts
# copiar el contenido de artifacts/ a ~/artifacts
```

Verificar:

```bash
cd ~/artifacts
sha256sum -c checksums.sha256
```

## 2. Levantar el servidor

```bash
cd ~/artifacts
chmod +x ftp/serve-ftp.sh
./ftp/serve-ftp.sh
```

Por defecto:

- Host: `10.10.10.20`
- Puerto: `2121`
- Usuario: `lab`
- Clave: `lab123`
- Raíz: `~/artifacts`

Si `pyftpdlib` no está:

```bash
sudo apt update && sudo apt install -y python3-pyftpdlib
# o
pip install pyftpdlib
```

Alternativa HTTP (si el FTP falla):

```bash
python3 -m http.server 8080 --directory ~/artifacts
```

## 3. Firewall

En M6:

```bash
sudo ufw allow 2121/tcp
# o, si se usa HTTP:
sudo ufw allow 8080/tcp
```

En M1–M5, el firewall debe permitir la salida hacia `10.10.10.20:2121`. En el laboratorio, el tráfico de la LAN está permitido; si hay reglas, agregar la excepción temporal.

## 4. Descargar por rol

```bash
# M1
./ftp/fetch-artifacts.sh m1

# M2
./ftp/fetch-artifacts.sh m2

# M3
./ftp/fetch-artifacts.sh m3

# M6
./ftp/fetch-artifacts.sh m6

# Fase 5
./ftp/fetch-artifacts.sh m1-fixed
./ftp/fetch-artifacts.sh m2-fixed
./ftp/fetch-artifacts.sh m3-fixed
```

Cada script descarga a `~/artifacts/` y verifica con `sha256sum -c --ignore-missing checksums.sha256`.

## 5. M5 (Windows)

En M5, usar PowerShell:

```powershell
# Descargar el MSI de TightVNC
curl.exe -sS --fail -u lab:lab123 -o "$env:TEMP\tightvnc.msi" `
  "ftp://10.10.10.20:2121/vulnerable/tightvnc-2.8.90-gpl-setup-64bit.msi"

# Verificar
Get-FileHash -Algorithm SHA256 "$env:TEMP\tightvnc.msi"
# Comparar con checksums.sha256:
# 9693cb4cdc2e7e482e8e3f5890415b57ef87de3369fa5c337db516218a1170ce
```

Instalar:

```powershell
msiexec /i "$env:TEMP\tightvnc.msi" /qn
```

## 6. M4 (Windows)

M4 no necesita artefactos de software: usa características de Windows (DNS, SMBv1, Spooler, `legacy`). Solo se necesitan los scripts de configuración y el módulo de Metasploit desde Kali.

## 7. Verificación

```bash
cd ~/artifacts
sha256sum -c --ignore-missing checksums.sha256
```

Si una línea falla:

1. Borrar el archivo.
2. Volver a descargarlo.
3. Verificar de nuevo.
4. Si sigue fallando, no instalarlo y documentar.

## 8. Reglas

- No descargar durante la explotación.
- No usar FTP fuera de `10.10.10.0/24`.
- No instalar sin SHA256 verificado.
- No guardar binarios troyanizados ni malware.
- Cerrar el FTP al terminar.
