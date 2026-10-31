# 8. Conclusiones

## 8.1 Qué se aprendió

1. **La cadena manda, no el CVE aislado.** El acceso real a M1 no vino de un RCE pre-auth, sino de una **clave débil reutilizada** en WordPress y SSH. Esa misma clave, encontrada en un backup de M3, abrió M4 y M5.
2. **La configuración pesa tanto como la versión.** `server-status`, `info.php`, listado de uploads, FTP anónimo, NFS `no_root_squash`, VNC sin clave y SNMP `public/private` son debilidades reales sin CVE.
3. **No todo lo que dice la versión es explotable.** Apache 2.4.49 estaba presente, pero el CGI devolvía 503; Samba 4.5.10 ya corrige SambaCry; vsftpd 2.3.4 no tenía el backdoor; Win10 21H2 no es vulnerable a EternalBlue. Documentar la limitación es parte del rigor.
4. **La evidencia debe ser reproducible.** Cada comando quedó con log, captura, hash y una explicación; lo que no se ejecutó se marca como pendiente.
5. **El aislamiento lógico falla si el firewall no se aplica.** M4:445 y M5:5900 estaban visibles desde M6; se documentó como hallazgo y se corrige en la fase 6.

## 8.2 Recomendaciones

- **Identidades:** claves únicas por servicio, sin reutilización; 2FA en el CMS; LAPS en Windows; `sudo` restringido.
- **Servicios de gestión:** SSH solo por llave, sin root directo; FTP reemplazado por SFTP/SCP; VNC con clave y solo localhost; SNMPv3.
- **Datos:** backups cifrados, sin credenciales en claro, con permisos mínimos; `root_squash` en NFS.
- **Plataforma:** parchear WordPress, PHP, Apache, Samba, Redis y Windows; deshabilitar SMBv1 y Spooler si no se usa.
- **Red:** aplicar de verdad “M2–M5 solo M1”; monitorear el tráfico este-oeste; separar VLAN si se puede.
- **Proceso:** inventario de CVE verificado en NVD/CVE.org, con fecha y CVSS; retest obligatorio antes/después.

## 8.3 Limitaciones del trabajo

- M4 y M5 estaban apagadas al momento de la explotación (16:44 UTC); sus pruebas de acceso quedan pendientes.
- W1/W2 no se ejecutaron con PoC completo; W3, B1, B2, D1 y C1 no fueron explotables en la configuración real.
- La separación de red es lógica, no física; se documenta como limitación.
- Los datos son ficticios y el entorno es de laboratorio.

## 8.4 Cierre

El entorno, tal como estaba, permitía **encadenar** debilidades hasta los datos y los backups; con la misma clave se llegaba a la estación del usuario. La remediación propuesta ataca la causa (credenciales y servicios expuestos) además de las versiones. El valor del informe no está en “todos los CVE explotados”, sino en la **trazabilidad honesta** de qué se demostró, qué no y por qué.
