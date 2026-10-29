# -*- coding: utf-8 -*-
"""Actualiza el guion al tono de entorno real y elimina referencias de laboratorio."""
import json
from pathlib import Path

p = Path("guion.json")
slides = json.loads(p.read_text(encoding="utf-8"))

updates = {
    1: {
        "caption": "PHP2Shell: de PHP 8.4.26 a root, con evidencia.",
        "text": "Buenas tardes. Somos el equipo de Seguridad de la Información y presentamos PHP2Shell, un caso real de explotación sobre PHP 8.4.26 en la red universitaria. Partimos de la superficie expuesta, llegamos a www-data y luego a root. Todo está respaldado con comandos, capturas y hashes. La réplica se hará en vivo desde Kali.",
        "support": "Saludar, presentar al equipo y señalar el título, los dos CVE y el target session2.php en el puerto 8080.",
    },
    2: {
        "text": "El recorrido tiene seis partes. Primero, contexto y arquitectura. Luego, metodología y version gate. Después, el inventario de hallazgos. El bloque central es W2: ficha, precondiciones, servicio y ejecución. Cerramos con el impacto, la remediación y el retest. La idea es simple: de la versión vulnerable a root, con una cadena demostrada y evidencia en cada paso.",
    },
    3: {
        "caption": "Red universitaria, servicios reales y un atacante dentro.",
        "text": "La red universitaria expone un portal web, base de datos, respaldos, un Windows heredado y estaciones de trabajo. Todo en 10.10.10.0/24; M6 es el punto de auditoría desde donde se valida la superficie. Identificamos veinticuatro hallazgos; veintidós se llevaron a evidencia. El objetivo es identificar, enumerar, explotar, escalar a root, remediar y verificar.",
        "support": "Señalar la red, los seis servidores y los tres números: 24 hallazgos, 22 con evidencia y 6 servidores.",
    },
    4: {
        "text": "La topología tiene una sola puerta web: M1. Desde M1 se pivota a M2, la base de datos, y a M3, los respaldos. M4 es el Windows Server y M5 la estación cliente. R0 solo transporta. La separación es lógica, no física: documentamos que 445 de M4 y 5900 de M5 quedaron visibles desde M6. Ese detalle también es parte del hallazgo.",
    },
    5: {
        "text": "Estas son las versiones que observamos desde Kali. M1 corre Apache 2.4.49, PHP 8.4.26 y WordPress 7.0.1. M2 tiene MariaDB 10.11.19 y Redis 6.2.6. M3 expone FTP, SMB y NFS. M4 es Windows Server 2016 con DNS y SMB. M5 es Windows 10 con TightVNC. Las versiones exactas son las que disparan el version gate.",
    },
    6: {
        "text": "M1 es el servidor de aplicación y la puerta de entrada. Publica WordPress y Moodle, y concentra la base de datos. Aquí explotamos W2 por Chain A, que nos dio www-data; W3, el traversal de Apache, que también dio www-data; y W4, una clave débil que permitió entrar como administrador. Con SSH y sudo cerramos el camino a root.",
        "support": "Señalar la tabla de vulns: W2, W3, W4 y M1-SSH; aclarar que W2 y W3 llegan a www-data y root se cierra por SSH/sudo.",
    },
    7: {
        "text": "M2 es la base de datos. Redis respondió sin autenticación y confirmamos el acceso con un PONG. Desde wp-config obtuvimos las claves de la base y, por un túnel SSH, leímos wordpress con doce tablas y moodle_db con cuatrocientas ochenta y siete. No hizo falta un exploit complejo: la configuración expuesta fue suficiente.",
        "support": "Señalar D1, D2 y D3; explicar que el dato sensible es el volcado, no solo el puerto abierto.",
    },
    8: {
        "text": "M3 es el servidor de respaldos. El FTP aceptaba acceso anónimo y dentro estaba credenciales.txt con la clave Admin13. Esa misma clave se reutilizaba en M1. Además, NFS permitía escribir como root por no_root_squash. Con esas dos debilidades, M3 se convirtió en el eslabón que entregó la llave maestra.",
    },
    9: {
        "text": "M4 es el Windows Server. La cuenta de administrador tenía una clave débil; con ella obtuvimos Pwn3d y acceso a las comparticiones. El DNS permitía transferencia de zona, así que obtuvimos el mapa completo de uni.lab. Con credenciales administrativas llegamos a SYSTEM mediante una tarea programada. No fue un privilege escalation desde un usuario limitado.",
    },
    10: {
        "text": "M5 es la estación cliente. TightVNC no pedía autenticación, así que abrimos el escritorio directamente. whoami confirmó el usuario cliente y dejamos el marcador PWNED-M5. También se reutilizaba la clave por SMB. Es el impacto más visible: el usuario final, su escritorio y sus archivos. La remediación de M5 quedó pendiente por filtrado.",
    },
    11: {
        "text": "M6 es Kali, la estación de auditoría, y no es objetivo. Desde aquí ejecutamos reconocimiento, escaneo, explotación, túneles y captura de evidencia. También aloja el FTP de artefactos y los logs con SHA256. Es el punto de partida y el punto donde se demuestra que todo lo anterior es reproducible.",
    },
    12: {
        "text": "Para la exposición dividimos PHP2Shell en seis partes. Erick presenta la ficha, el CVSS y el version gate. Doris, las precondiciones: NTS, prefork y php.ini. Rony, los offsets reales y el servicio en 8080. Fabiola, la inyección de sesión. Marco, el LFI y la ejecución. Jose cierra con la evidencia, el root por B3, SSH y sudo, y el retest.",
    },
    13: {
        "text": "Trabajamos en siete fases: alcance, reconocimiento, enumeración, análisis, explotación, remediación y retest. Cada flecha tiene una puerta de versión. Primero verificamos qué versión está instalada; segundo, si está dentro del rango vulnerable; tercero, qué versión la corrige; cuarto, decidimos si es explotable. Si la instalada es igual o mayor que el fix, el CVE no cuenta. En W2 la versión estaba en rango y el servicio explotado cumplía las condiciones: NTS, prefork y offsets reales. El gate confirmó versión y condiciones antes de ejecutar.",
        "support": "Señalar las fases y las cuatro casillas del version gate; no entrar aún en W2.",
    },
    14: {
        "text": "Identificamos veinticuatro hallazgos: nueve CVE y quince configuraciones. Veintidós se llevaron a evidencia. La distribución es M1 con siete, M2 con cuatro, M3 con cuatro, M4 con cinco y M5 con cuatro. En esta presentación mostramos solo las vías que se explotaron o validaron; no inflamos el inventario con lo que no se pudo reproducir.",
    },
    15: {
        "text": "W2 son dos CVE de corrupción de memoria en PHP 8.4.26: CVE-2026-109618 y CVE-2026-109619. El vector es de red, sin autenticación y sin interacción; el CVSS v3.1 es 9.8, crítico. La versión afectada va de 8.4.0 a 8.4.26 y la corrige 8.4.27. El EPSS está sin dato porque el CVE es reciente. El resultado real: RCE como www-data y root por la cadena B3, SSH y sudo.",
        "support": "Señalar CVE, CVSS, versión que corrige y estado; aclarar que no se mezclan métricas v3.1 y v4.0.",
    },
    16: {
        "text": "El version gate confirma que 8.4.26 está dentro del rango vulnerable y que 8.4.27 corrige. El servicio expuesto corre con NTS y prefork, y cumple las condiciones del PoC. Por eso declaramos versión y condiciones verificadas, y ejecutamos la cadena. El gate separa hay un CVE de se puede explotar aquí.",
    },
    17: {
        "text": "El servicio explotado presenta seis condiciones. Necesita NTS, es decir, sin Thread Safety; Apache con MPM prefork; display_errors encendido; memory_limit de 16 megabytes; session.upload_progress habilitado y con cleanup apagado; y los offsets del binario real. Se verificaron con php -i, httpd -V y nm antes de ejecutar. El PoC usa comandos de hasta catorce bytes y Chain A suma una sesión compartida y un sink LFI.",
    },
    18: {
        "caption": "PHP 8.4.26 NTS en el servicio 8080.",
        "text": "El servicio vulnerable es PHP 8.4.26 NTS sobre Apache 2.4.49 prefork, publicado en el puerto 8080. Presenta display_errors, memory_limit de 16M, session.upload_progress y session2.php con HTTP 200 y sesión compartida. Es el entorno que se explotó y quedó documentado en EV-W2-01.",
        "support": "Señalar un solo servicio en 8080; no hablar de puertos alternos ni de montaje.",
    },
    19: {
        "text": "Los offsets no se copian de Internet. Se derivan del libphp.so del servidor M1. Con nm obtuvimos las direcciones de zif_system, zval_ptr_dtor y htdata. Un offset de otro build hace fallar el PoC aunque la versión sea correcta. Por eso el php.ini y los símbolos se verifican sobre el handler de Apache, no solo por línea de comandos.",
    },
    20: {
        "text": "Chain A convierte la sesión en ejecución remota en cinco pasos. Primero, session.upload_progress crea /tmp/sess con el contenido del request. Segundo, el nombre del campo y el valor inyectan código PHP. Tercero, el sink LFI incluye ese archivo. Cuarto, PHP interpreta el código en el worker. Quinto, id devuelve uid=33, www-data, y escribimos el marcador PWNED-M1-www-data. La cadena se ejecuta contra el servicio 8080 y luego se escala por B3, SSH y sudo.",
    },
    21: {
        "text": "Estos son los cinco comandos clave. El primero crea la sesión con upload_progress y deja el código inyectado en /tmp/sess. El segundo fuerza el mismo worker y confirma que la sesión persiste. El tercero incluye el archivo de sesión por el LFI. El cuarto ejecuta id y devuelve www-data. El quinto reutiliza la clave de B3 para entrar por SSH como ubuntu y escalar a root con sudo. Cada paso tiene su salida esperada.",
    },
    22: {
        "text": "W3 es una segunda vía, independiente de PHP2Shell. Apache 2.4.49 permite traversal de rutas; con CGI habilitado, la ruta llega a /bin/sh. El comando se ejecuta como www-data. No necesitamos W3 para el resultado, pero demuestra que había más de un camino al mismo nivel. W3 y W2 se parchean por separado.",
    },
    23: {
        "text": "B3 es la llave maestra. El FTP de M3 permite acceso anónimo y expone /backups. Dentro está credenciales.txt con Admin13. Esa clave se reutiliza en ubuntu en M1. Entramos por SSH, ejecutamos sudo id y obtenemos uid=0 root. No es un exploit nuevo: es reutilización de credenciales. Y es lo que convierte el acceso www-data en control total.",
    },
    24: {
        "text": "La evidencia es lo que sostiene todo. EV-W2-07 documenta Chain A: session injection más LFI, con uid=33 www-data desde M1. EV-W2-09 documenta el root: B3, credenciales, SSH como ubuntu, sudo y el archivo /root/PWNED-M1-root.txt. Cada log tiene captura y SHA256.",
        "support": "Señalar los dos identificadores y los hashes; evidencia verificable, sin intentos fallidos.",
    },
    25: {
        "text": "El impacto real es este. W2 por Chain A dio www-data. W3 también dio www-data. B3 más SSH y sudo dieron root. La diferencia entre hay un CVE y se explotó está en la evidencia: un id, un archivo o una captura verificable. W2 no dio root por sí solo; la cadena completa sí.",
    },
    26: {
        "text": "La cadena completa tiene cinco eslabones. Kali entra a M1 por W2 Chain A y obtiene www-data. Desde M3, el FTP anónimo entrega credenciales.txt. Esa clave permite SSH como ubuntu en M1. Con sudo llegamos a root y dejamos PWNED-M1-root.txt. La réplica en vivo sigue el mismo orden: versión, precondiciones, PoC, evidencia y retest.",
    },
    27: {
        "text": "El resto de la red también aporta. En M2, Redis sin autenticación y las claves de la base permitieron volcar datos. En M3, el FTP anónimo y NFS no_root_squash entregaron credenciales y escritura root. En M4, la clave débil del administrador y el AXFR llevaron a SYSTEM y al mapa de DNS. En M5, VNC sin autenticación abrió el escritorio. M5 sigue pendiente de remediación por filtrado.",
    },
    28: {
        "text": "La remediación cambió versiones y configuraciones. PHP pasó a 8.4.27, WordPress a 7.0.2, Apache a 2.4.51 y Redis a 6.2.7. Apagamos upload_progress, eliminamos el LFI, cerramos el FTP anónimo y deshabilitamos SMBv1. M1 a M4 quedaron cerrados. M5 no se pudo tocar porque 445, 3389 y 5900 quedaron filtrados; se declara pendiente, no remediado.",
    },
    29: {
        "text": "El retest usó los mismos comandos de validación. M1 tiene ocho cierres: WordPress 7.0.2, PHP 8.4.27, Apache 2.4.51, el LFI en 404 y las claves rotadas. M2 tiene cuatro: Redis con NOAUTH y puertos filtrados. M3 tiene cinco: FTP anónimo en 530, root_squash y SSH rotado. M4 tiene cinco: SMB1 off, signing on, Spooler off y AXFR cerrado. M5 sigue pendiente.",
    },
    30: {
        "text": "Cuatro lecciones. Primera: la versión es el punto de partida; PHP 8.4.26 habilitó la cadena. Segunda: los offsets son del binario; copiarlos de otro build hace fallar el PoC. Tercera: W2 más B3 dan root; cada eslabón tiene evidencia. Cuarta: parchear sí cambia el juego; 8.4.27, upload_progress off y LFI eliminado se verificaron en el retest. La fortaleza es la trazabilidad de lo demostrado.",
    },
    31: {
        "text": "Con esto cerramos. PHP2Shell quedó demostrado con Chain A, www-data y root por B3, SSH y sudo. W3 fue una segunda vía real. La remediación y el retest están documentados. Ahora respondemos preguntas y, si el docente lo permite, repetimos la réplica en vivo desde Kali, en el mismo orden: version gate, precondiciones, PoC, evidencia y retest. Gracias.",
    },
}

for s in slides:
    if s["n"] in updates:
        s.update(updates[s["n"]])

p.write_text(json.dumps(slides, ensure_ascii=False, indent=2), encoding="utf-8")
print("OK guion.json")
