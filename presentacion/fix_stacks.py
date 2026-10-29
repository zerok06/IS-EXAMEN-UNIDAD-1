p = 'build.js'
s = open(p, encoding='utf-8').read()

repls = {
'  stack: ["Ubuntu 22.04", "Apache 2.4.49", "PHP 8.4.26 (ZTS)", "OpenSSH · usuario ubuntu"],':
'  stack: ["Ubuntu 22.04", "Apache 2.4.49", "PHP 8.4.26 (ZTS)", "WordPress 7.0.1 · Moodle 5.0.11", "OpenSSH · usuario ubuntu"],',
'  stack: ["Ubuntu 22.04", "MariaDB 10.11.19", "Redis 6.2.6", "3306/6379 en la LAN"],':
'  stack: ["Ubuntu 22.04", "MariaDB 10.11.19", "Redis 6.2.6", "SNMP public/private", "3306/6379 en la LAN"],',
'  stack: ["Ubuntu 22.04", "Samba 4.5.10", "vsftpd 2.3.4", "OpenSSH · rony123"],':
'  stack: ["Ubuntu 22.04", "Samba 4.5.10", "vsftpd 2.3.4", "NFS · /srv/storage/backups", "OpenSSH · rony123"],',
'  stack: ["WS2016 build 14393", "DNS standalone", "SMBv1 · signing off", "Administrador / soporte"],':
'  stack: ["WS2016 build 14393", "DNS standalone", "SMBv1 · signing off", "Spooler activo", "Administrador / soporte"],',
'  stack: ["Windows 10 21H2 · 19045", "SMBv1", "RDP sin NLA", "cliente / Admin13.-"],':
'  stack: ["Windows 10 21H2 · 19045", "SMBv1", "RDP sin NLA", "TightVNC 2.8.90", "cliente / Admin13.-"],',
'  stack: ["Kali Linux", "nmap · whatweb · wpscan", "nxc · redis-cli · smbclient", "FTP de artefactos :2121"],':
'  stack: ["Kali Linux", "nmap · whatweb · wpscan", "nxc · redis-cli · smbclient", "curl · ssh · vncviewer", "FTP de artefactos :2121"],',
}

for a, b in repls.items():
    if a in s:
        s = s.replace(a, b, 1)
    else:
        print('NOT FOUND', a[:60])

s = s.replace('txt(s, "  " + line, {', 'txt(s, "•  " + line, {')

open(p, 'w', encoding='utf-8').write(s)
print('done')
