# ISOs y sistemas operativos

> No se descargan por tamaño y licencia. Descargar **antes de aislar** la red y verificar el SHA256 oficial.

| Sistema | Versión | Uso | URL | Verificación |
|---|---|---|---|---|
| Ubuntu Server | 22.04.5 `live-server-amd64` | M1, M2, M3 | https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso | [`ubuntu-22.04-SHA256SUMS`](./ubuntu-22.04-SHA256SUMS) |
| Windows Server 2016 | Evaluación 180 días | M4 | https://www.microsoft.com/en-us/evalcenter/download-windows-server-2016 | Hash en la página de Microsoft |
| Windows 10 | 22H2 (o 21H2) | M5 | https://www.microsoft.com/en-us/software-download/windows10ISO | Hash en la página de Microsoft |
| Kali Linux | 2024.x VMware | M6 | https://www.kali.org/get-kali/#kali-virtual-machines | SHA256 en kali.org |

## Notas

- **M4/M5:** no instalar Windows Update después de la instalación; un parche cierra S1/S2/C1. Documentar `winver` y `systeminfo`.
- **M6:** importar la imagen VMware; no usar ISO si se puede evitar.
- **Aislamiento:** descargar todo antes de desconectar DSL/NAT.
- **Espacio:** reservar ≥20 GB libres por VM para snapshots.
- **Licencias:** usar ediciones de evaluación o licencias del laboratorio; no distribuir ISOs.
