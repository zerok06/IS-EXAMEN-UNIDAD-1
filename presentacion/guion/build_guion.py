# -*- coding: utf-8 -*-
"""Genera el guion humano y el JSON que alimenta la narración y el video."""
import json
from pathlib import Path

SLIDES = [
    {
        "n": 1,
        "title": "Portada — PHP2Shell",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "PHP2Shell: de PHP 8.4.26 a root, con evidencia.",
        "text": "Buenas tardes. Somos el equipo de Seguridad de la Información y presentamos PHP2Shell, un caso de explotación controlada sobre PHP 8.4.26. Partimos de un laboratorio aislado, con seis máquinas virtuales, y llegamos hasta root. Todo está respaldado con comandos, capturas y hashes. La demostración se hará en vivo desde Kali.",
        "support": "Saludar, presentar al equipo y señalar el título, los dos CVE y el target session2.php en el puerto 8080.",
        "transition": "Pasamos al recorrido de la exposición.",
    },
    {
        "n": 2,
        "title": "Recorrido de la exposición",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "Seis bloques: contexto, método, W2, ejecución, impacto y retest.",
        "text": "El recorrido tiene seis partes. Primero, contexto y arquitectura. Luego, metodología y version gate. Después, el inventario de hallazgos. El bloque central es W2: ficha, precondiciones, offsets y rebuild. Cerramos con la ejecución, el impacto, la remediación y el retest. La idea es simple: de la versión vulnerable a root, con una cadena demostrada y evidencia en cada paso.",
        "support": "Recorrer los seis números de la diapositiva con la mano o el puntero; detenerse en el bloque 04, W2.",
        "transition": "Empezamos por el contexto.",
    },
    {
        "n": 3,
        "title": "Contexto: qué quisimos montar",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "Red aislada 10.10.10.0/24, seis VM y un auditor.",
        "text": "El laboratorio reproduce una red universitaria típica: portal web, base de datos, respaldos, un Windows heredado y estaciones de trabajo. Todo vive en 10.10.10.0/24, sin Internet mientras los servicios vulnerables están activos. M6 es Kali y solo audita. El objetivo no es atacar por atacar: es montar, enumerar, explotar, escalar, remediar y verificar. Cada paso queda con comando, captura y hash.",
        "support": "Señalar el aislamiento, las seis VM y los tres números: 24 hallazgos, 22 llevados a evidencia y 6 máquinas.",
        "transition": "Veamos cómo se conectan esas máquinas.",
    },
    {
        "n": 4,
        "title": "Arquitectura y camino de ataque",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "Una sola puerta web; pivote desde M1.",
        "text": "La topología tiene una sola puerta web: M1. Desde M1 se pivota a M2, la base de datos, y a M3, los respaldos. M4 es el Windows Server y M5 la estación cliente. R0 solo transporta. La separación es lógica, no física: documentamos que 445 de M4 y 5900 de M5 quedaron visibles desde M6. Esa desviación también es parte del hallazgo.",
        "support": "Seguir el camino M6 → M1:80 → M2/M3/M4 y M5 por VNC; señalar la nota de firewall.",
        "transition": "Estas son las versiones que encontramos.",
    },
    {
        "n": 5,
        "title": "Activos: qué expone cada máquina",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "Versiones y puertos que activan el version gate.",
        "text": "Estas son las versiones que observamos desde Kali. M1 corre Apache 2.4.49, PHP 8.4.26 y WordPress 7.0.1. M2 tiene MariaDB 10.11.19 y Redis 6.2.6. M3 expone FTP, SMB y NFS. M4 es Windows Server 2016 con DNS y SMB. M5 es Windows 10 con TightVNC. Las versiones exactas son las que disparan el version gate.",
        "support": "Leer solo las versiones clave; no detenerse en cada puerto. M1 es la prioridad.",
        "transition": "Ahora revisamos cada máquina y qué se explotó en ella.",
    },
    {
        "n": 6,
        "title": "M1 · Aplicación",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "M1: W2 Chain A, W3, W4 y root por SSH/sudo.",
        "text": "M1 es la máquina de Erick y la puerta de entrada. Publica WordPress y Moodle, y concentra la base de datos. Aquí explotamos tres cosas: W2 por Chain A, que nos dio www-data; W3, el traversal de Apache, que también dio www-data; y W4, una clave débil que permitió entrar como administrador. Con SSH y sudo cerramos el camino a root.",
        "support": "Señalar la tabla de vulns: W2, W3, W4 y M1-SSH; aclarar que W2 y W3 llegan a www-data y root se cierra por SSH/sudo.",
        "transition": "La base de datos es el siguiente eslabón.",
    },
    {
        "n": 7,
        "title": "M2 · Base de datos",
        "owner": "M2 · Doris Apaza Anahua",
        "speaker": "Doris",
        "voice": "es-PE-CamilaNeural",
        "caption": "M2: Redis sin auth y volcado de bases.",
        "text": "M2 es la base de datos, a cargo de Doris. Redis respondió sin autenticación y confirmamos el acceso con un PONG. Desde wp-config obtuvimos las claves de la base y, por un túnel SSH, leímos wordpress con doce tablas y moodle_db con cuatrocientas ochenta y siete. No hizo falta un exploit complejo: la configuración expuesta fue suficiente.",
        "support": "Señalar D1, D2 y D3; explicar que el dato sensible es el volcado, no solo el puerto abierto.",
        "transition": "Los respaldos guardaban la llave que necesitábamos.",
    },
    {
        "n": 8,
        "title": "M3 · Respaldos",
        "owner": "M3 · Rony Churata Huacani",
        "speaker": "Rony",
        "voice": "es-BO-MarceloNeural",
        "caption": "M3: FTP anónimo y NFS entregan la llave.",
        "text": "M3 es el servidor de respaldos de Rony. El FTP aceptaba acceso anónimo y dentro estaba credenciales.txt con la clave Admin13. Esa misma clave se reutilizaba en M1. Además, NFS permitía escribir como root por no_root_squash. Con esas dos debilidades, M3 se convirtió en el eslabón que entregó la llave maestra.",
        "support": "Señalar B3 y B4; insistir en que no es un exploit nuevo, es reutilización de credenciales.",
        "transition": "Pasamos a Windows Server.",
    },
    {
        "n": 9,
        "title": "M4 · Windows Server",
        "owner": "M4 · Fabiola Ancco Rafael",
        "speaker": "Fabiola",
        "voice": "es-MX-DaliaNeural",
        "caption": "M4: admin débil, AXFR y SYSTEM.",
        "text": "M4 es el Windows Server de Fabiola. La cuenta de administrador tenía una clave débil; con ella obtuvimos Pwn3d y acceso a las comparticiones. El DNS permitía transferencia de zona, así que obtuvimos el mapa completo de uni.lab. Con credenciales administrativas llegamos a SYSTEM mediante una tarea programada. No fue un privilege escalation desde un usuario limitado.",
        "support": "Señalar S3 y S4; aclarar que SYSTEM se alcanzó con credenciales administrativas, no desde un usuario común.",
        "transition": "La estación cliente es el impacto sobre el usuario.",
    },
    {
        "n": 10,
        "title": "M5 · Cliente",
        "owner": "M5 · Marco Nina Cruz",
        "speaker": "Marco",
        "voice": "es-CO-GonzaloNeural",
        "caption": "M5: VNC sin auth y escritorio comprometido.",
        "text": "M5 es la estación cliente de Marco. TightVNC no pedía autenticación, así que abrimos el escritorio directamente. whoami confirmó el usuario cliente y dejamos el marcador PWNED-M5. También se reutilizaba la clave por SMB. Es el impacto más visible: el usuario final, su escritorio y sus archivos. La remediación de M5 quedó pendiente por filtrado.",
        "support": "Señalar C4 y C2; mostrar que M5 está marcado como pendiente, no como remediado.",
        "transition": "M6 es el punto de partida y la evidencia.",
    },
    {
        "n": 11,
        "title": "M6 · Auditoría",
        "owner": "M6 · Jose Paye Mamani",
        "speaker": "Jose",
        "voice": "es-AR-TomasNeural",
        "caption": "M6: Kali, auditoría y evidencia.",
        "text": "M6 es Kali, la estación de Jose, y no es objetivo. Desde aquí ejecutamos reconocimiento, escaneo, explotación, túneles y captura de evidencia. También aloja el FTP de artefactos y los logs con SHA256. Es el punto de partida y el punto donde se demuestra que todo lo anterior es reproducible.",
        "support": "Señalar que M6 no tiene vulnerabilidades objetivo y que su función es auditar y almacenar evidencia.",
        "transition": "Con el mapa claro, dividimos PHP2Shell en seis partes.",
    },
    {
        "n": 12,
        "title": "Reparto de PHP2Shell",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "PHP2Shell en seis partes, una por integrante.",
        "text": "Para la exposición dividimos PHP2Shell en seis partes. Erick presenta la ficha, el CVSS y el version gate. Doris, las precondiciones: NTS, prefork y php.ini. Rony, los offsets reales y el staging en 8080. Fabiola, la inyección de sesión. Marco, el LFI y la ejecución. Jose cierra con la evidencia, el root por B3, SSH y sudo, y el retest.",
        "support": "Recorrer las seis tarjetas y confirmar que cada integrante tiene una parte y una máquina.",
        "transition": "Antes de entrar en W2, veamos la metodología.",
    },
    {
        "n": 13,
        "title": "Metodología y version gate",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "Siete fases; la versión decide si el CVE cuenta.",
        "text": "Trabajamos en siete fases: preparación, montaje, implementación, reconocimiento, explotación, remediación y retest. Cada flecha tiene una puerta de versión. Primero verificamos qué versión está instalada; segundo, si está dentro del rango vulnerable; tercero, qué versión la corrige; cuarto, decidimos si es explotable. Si la instalada es igual o mayor que el fix, el CVE no cuenta. Esa regla evitó falsos positivos.",
        "support": "Señalar las cuatro casillas del version gate y la regla de oro; no entrar aún en W2.",
        "transition": "Este es el inventario que resultó de ese filtro.",
    },
    {
        "n": 14,
        "title": "Inventario de hallazgos",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "24 hallazgos; 22 llevados a evidencia.",
        "text": "Identificamos veinticuatro hallazgos: nueve CVE y quince configuraciones. Veintidós se llevaron a evidencia. La distribución es M1 con siete, M2 con cuatro, M3 con cuatro, M4 con cinco y M5 con cuatro. En esta presentación mostramos solo las vías que se explotaron o validaron; no inflamos el inventario con lo que no se pudo reproducir.",
        "support": "Señalar el total y la distribución; aclarar que la diapositiva resume y que el detalle está en las fichas.",
        "transition": "Entramos de lleno en W2.",
    },
    {
        "n": 15,
        "title": "W2 · Ficha",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "W2: CVSS 9.8, RCE pre-auth y parche 8.4.27.",
        "text": "W2 son dos CVE de corrupción de memoria en PHP 8.4.26: CVE-2026-109618 y CVE-2026-109619. El vector es AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H y el CVSS v3.1 es 9.8, crítico. La versión afectada va de 8.4.0 a 8.4.26 y la corrige 8.4.27. El EPSS está sin dato porque el CVE es reciente. El resultado real: RCE como www-data y root por la cadena B3, SSH y sudo.",
        "support": "Señalar CVE, CVSS, vector, versión que corrige y estado; aclarar que no se mezclan métricas v3.1 y v4.0.",
        "transition": "La versión parece vulnerable, pero hay que comparar.",
    },
    {
        "n": 16,
        "title": "W2 · Version gate",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "8.4.26 dentro del rango; 8.4.27 corrige.",
        "text": "El version gate confirma que 8.4.26 está dentro del rango vulnerable y que 8.4.27 corrige. La build original era ZTS con MPM event, y esas condiciones no servían para el PoC. Por eso no declaramos el CVE explotable solo por la versión: primero reconstruimos el entorno y luego ejecutamos la cadena. El gate separa hay un CVE de se puede explotar aquí.",
        "support": "Señalar la línea 8.4.0–8.4.26–8.4.27 y la decisión: versión sí, condiciones no, hasta ejecutar.",
        "transition": "Veamos esas condiciones.",
    },
    {
        "n": 17,
        "title": "W2 · Precondiciones",
        "owner": "M2 · Doris Apaza Anahua",
        "speaker": "Doris",
        "voice": "es-PE-CamilaNeural",
        "caption": "Seis precondiciones de build y configuración.",
        "text": "El PoC no corre con cualquier PHP. Necesita NTS, es decir, sin Thread Safety; Apache con MPM prefork; display_errors encendido; memory_limit de 16 megabytes; session.upload_progress habilitado y con cleanup apagado; y los offsets del binario real. Esas seis condiciones se verifican con php -i, httpd -V y nm antes de ejecutar. El PoC usa comandos de hasta catorce bytes y Chain A suma una sesión compartida y un sink LFI.",
        "support": "Recorrer las seis condiciones; explicar que el entorno original no las cumplía y por eso se reconstruyó.",
        "transition": "Así llegamos al staging del puerto 8080.",
    },
    {
        "n": 18,
        "title": "W2 · Rebuild",
        "owner": "M2 · Doris Apaza Anahua",
        "speaker": "Doris",
        "voice": "es-PE-CamilaNeural",
        "caption": "Staging 8080: Apache prefork + PHP NTS.",
        "text": "El servicio del puerto 80 no se tocó. Compilamos un staging aislado en /home/ubuntu/w2, en el puerto 8080, con Apache 2.4.49 prefork y PHP 8.4.26 NTS. Ahí sí activamos display_errors, bajamos memory_limit a 16M y dejamos session2.php con HTTP 200 y sesión compartida. Es un entorno de laboratorio, separado del servicio real, y quedó documentado en EV-W2-01.",
        "support": "Comparar las dos columnas: puerto 80 vivo contra 8080 staging; señalar que el servicio real no se alteró.",
        "transition": "Con el entorno listo, ajustamos el php.ini y los offsets.",
    },
    {
        "n": 19,
        "title": "W2 · Configuración y offsets",
        "owner": "M3 · Rony Churata Huacani",
        "speaker": "Rony",
        "voice": "es-BO-MarceloNeural",
        "caption": "Offsets derivados del libphp.so real.",
        "text": "Los offsets no se copian de Internet. Se derivan del libphp.so que compilamos en M1. Con nm obtuvimos las direcciones de zif_system, zval_ptr_dtor y htdata. Un offset de otro build hace fallar el PoC aunque la versión sea correcta. Por eso el php.ini y los símbolos se verifican sobre el handler de Apache, no solo por línea de comandos.",
        "support": "Señalar los tres símbolos y la salida de nm; insistir en que son del binario real.",
        "transition": "Ahora sí, la cadena que convierte la sesión en RCE.",
    },
    {
        "n": 20,
        "title": "W2 · Chain A",
        "owner": "M4 · Fabiola Ancco Rafael",
        "speaker": "Fabiola",
        "voice": "es-MX-DaliaNeural",
        "caption": "Chain A: sesión, LFI y RCE como www-data.",
        "text": "Chain A convierte la sesión en ejecución remota en cinco pasos. Primero, session.upload_progress crea /tmp/sess con el contenido del request. Segundo, el nombre del campo y el valor inyectan código PHP. Tercero, el sink LFI incluye ese archivo. Cuarto, PHP interpreta el código en el worker. Quinto, id devuelve uid=33, www-data, y escribimos el marcador PWNED-M1-www-data. La cadena se ejecuta desde M1 y luego se escala por B3, SSH y sudo.",
        "support": "Seguir los cinco pasos; señalar la salida RCE CONFIRMED y el uid=33(www-data).",
        "transition": "Estos son los comandos exactos.",
    },
    {
        "n": 21,
        "title": "W2 · Comandos",
        "owner": "M5 · Marco Nina Cruz",
        "speaker": "Marco",
        "voice": "es-CO-GonzaloNeural",
        "caption": "Cinco comandos, cinco resultados esperados.",
        "text": "Estos son los cinco comandos clave. El primero crea la sesión con upload_progress y deja el código inyectado en /tmp/sess. El segundo fuerza el mismo worker y confirma que la sesión persiste. El tercero incluye el archivo de sesión por el LFI. El cuarto ejecuta id y devuelve www-data. El quinto reutiliza la clave de B3 para entrar por SSH como ubuntu y escalar a root con sudo. Cada paso tiene su salida esperada.",
        "support": "No leer los comandos completos: explicar qué hace cada uno y qué salida se espera. La demo en vivo los ejecuta.",
        "transition": "W2 no fue la única vía a www-data.",
    },
    {
        "n": 22,
        "title": "Otra vía · W3",
        "owner": "M1 · Erick Ramos Vera",
        "speaker": "Erick",
        "voice": "es-PE-AlexNeural",
        "caption": "W3: Apache 2.4.49 y traversal a /bin/sh.",
        "text": "W3 es una segunda vía, independiente de PHP2Shell. Apache 2.4.49 permite traversal de rutas; con CGI habilitado, la ruta llega a /bin/sh. El comando se ejecuta como www-data. No necesitamos W3 para el resultado, pero demuestra que había más de un camino al mismo nivel. W3 y W2 se parchean por separado.",
        "support": "Señalar el comando y la salida uid=33; aclarar que es una ruta alternativa, no la cadena principal.",
        "transition": "La llave para pasar de www-data a root estaba en los respaldos.",
    },
    {
        "n": 23,
        "title": "Otra vía · B3",
        "owner": "M3 · Rony Churata Huacani",
        "speaker": "Rony",
        "voice": "es-BO-MarceloNeural",
        "caption": "B3: FTP anónimo, Admin13 y root por sudo.",
        "text": "B3 es la llave maestra. El FTP de M3 permite acceso anónimo y expone /backups. Dentro está credenciales.txt con Admin13. Esa clave se reutiliza en ubuntu en M1. Entramos por SSH, ejecutamos sudo id y obtenemos uid=0 root. No es un exploit nuevo: es reutilización de credenciales. Y es lo que convierte el acceso www-data en control total.",
        "support": "Señalar el archivo credenciales.txt, la reutilización en ubuntu y la salida uid=0(root).",
        "transition": "Todo esto tiene que quedar demostrado.",
    },
    {
        "n": 24,
        "title": "W2 · Evidencia",
        "owner": "M6 · Jose Paye Mamani",
        "speaker": "Jose",
        "voice": "es-AR-TomasNeural",
        "caption": "EV-W2-07, EV-W2-09 y hashes.",
        "text": "La evidencia es lo que sostiene todo. EV-W2-07 documenta Chain A: session injection más LFI, con uid=33 www-data desde M1. EV-W2-09 documenta el root: B3, credenciales, SSH como ubuntu, sudo y el archivo /root/PWNED-M1-root.txt. Cada log tiene captura y SHA256. El intento fallido también se documenta: no ocultamos lo que no funcionó.",
        "support": "Señalar los dos identificadores y los hashes; recordar que el intento fallido también es evidencia.",
        "transition": "Este es el impacto real.",
    },
    {
        "n": 25,
        "title": "W2 · Impacto",
        "owner": "M6 · Jose Paye Mamani",
        "speaker": "Jose",
        "voice": "es-AR-TomasNeural",
        "caption": "W2 dio www-data; root vino por B3/SSH/sudo.",
        "text": "El impacto real es este. W2 por Chain A dio www-data. W3 también dio www-data. W1 solo llegó a ruta y login, sin RCE. B3 más SSH y sudo dieron root. La diferencia entre hay un CVE y se explotó está en la evidencia: un id, un archivo o una captura verificable. W2 no dio root por sí solo; la cadena completa sí.",
        "support": "Comparar las filas: W2 y W3 a www-data, W1 sin RCE, B3/SSH/sudo a root. No confundir alcance con impacto.",
        "transition": "Veamos la cadena completa en una sola línea.",
    },
    {
        "n": 26,
        "title": "Cadena completa: de Kali a root",
        "owner": "M1 Erick · M3 Rony · M6 Jose",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "Cinco eslabones de Kali a root.",
        "text": "La cadena completa tiene cinco eslabones. Kali entra a M1 por W2 Chain A y obtiene www-data. Desde M3, el FTP anónimo entrega credenciales.txt. Esa clave permite SSH como ubuntu en M1. Con sudo llegamos a root y dejamos PWNED-M1-root.txt. Todo se puede repetir desde los snapshots: vulnerable, explotar, restaurar parcheado y mostrar el bloqueo.",
        "support": "Seguir los cinco números; conectar cada eslabón con su evidencia y su máquina.",
        "transition": "El resto del laboratorio también aporta a la cadena.",
    },
    {
        "n": 27,
        "title": "Resto del laboratorio",
        "owner": "M2 Doris · M3 Rony · M4 Fabiola · M5 Marco",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "M2–M5: las vías que sostienen la cadena.",
        "text": "El resto del laboratorio sostiene la cadena. En M2, Redis sin autenticación y las claves de la base permitieron volcar datos. En M3, el FTP anónimo y NFS no_root_squash entregaron credenciales y escritura root. En M4, la clave débil del administrador y el AXFR llevaron a SYSTEM y al mapa de DNS. En M5, VNC sin autenticación abrió el escritorio. M5 sigue pendiente de remediación por filtrado.",
        "support": "Recorrer M2, M3, M4 y M5; señalar que M5 está pendiente y no se declara remediado.",
        "transition": "Pasamos a la remediación.",
    },
    {
        "n": 28,
        "title": "Remediación",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "PHP 8.4.27, WP 7.0.2, Apache 2.4.51, Redis 6.2.7.",
        "text": "La remediación cambió versiones y configuraciones. PHP pasó a 8.4.27, WordPress a 7.0.2, Apache a 2.4.51 y Redis a 6.2.7. Apagamos upload_progress, eliminamos el LFI, cerramos el FTP anónimo y deshabilitamos SMBv1. M1 a M4 quedaron cerrados. M5 no se pudo tocar porque 445, 3389 y 5900 quedaron filtrados; se declara pendiente, no remediado.",
        "support": "Leer la tabla de medidas y estados; detenerse en W2 y en la fila pendiente de M5.",
        "transition": "El retest confirma qué cambió.",
    },
    {
        "n": 29,
        "title": "Retest: antes y después",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "M1–M4 cerrados; M5 pendiente.",
        "text": "El retest usó los mismos comandos de validación. M1 tiene ocho cierres: WordPress 7.0.2, PHP 8.4.27, Apache 2.4.51, el LFI en 404 y las claves rotadas. M2 tiene cuatro: Redis con NOAUTH y puertos filtrados. M3 tiene cinco: FTP anónimo en 530, root_squash y SSH rotado. M4 tiene cinco: SMB1 off, signing on, Spooler off y AXFR cerrado. M5 sigue pendiente.",
        "support": "Señalar los cinco bloques y los estados; recordar que M5 no se pudo tocar.",
        "transition": "Cerramos con las lecciones del caso.",
    },
    {
        "n": 30,
        "title": "Cuatro lecciones de PHP2Shell",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "Versión, offsets, cadena y parche.",
        "text": "Cuatro lecciones. Primera: la versión es el punto de partida; PHP 8.4.26 habilitó la cadena. Segunda: los offsets son del binario; copiarlos de otro build hace fallar el PoC. Tercera: W2 más B3 dan root; cada eslabón tiene evidencia. Cuarta: parchear sí cambia el juego; 8.4.27, upload_progress off y LFI eliminado se verificaron en el retest. La fortaleza no es todos los CVE explotados, sino la trazabilidad.",
        "support": "Recorrer las cuatro lecciones; cerrar con la idea de trazabilidad, no con una lista de CVE.",
        "transition": "Terminamos con el cierre y las preguntas.",
    },
    {
        "n": 31,
        "title": "Cierre y preguntas",
        "owner": "Equipo completo",
        "speaker": "Equipo",
        "voice": "es-MX-JorgeNeural",
        "caption": "Preguntas y réplica en vivo.",
        "text": "Con esto cerramos. PHP2Shell quedó demostrado con Chain A, www-data y root por B3, SSH y sudo. W3 fue una segunda vía real. La remediación y el retest están documentados. Ahora respondemos preguntas y, si el docente lo permite, repetimos la demo en vivo desde Kali, en el mismo orden: version gate, precondiciones, PoC, evidencia y retest. Gracias.",
        "support": "Abrir el turno de preguntas; tener a mano los logs EV-W2-07, EV-W2-09 y EV-007-RETEST.",
        "transition": "Fin de la exposición.",
    },
]

out = Path(__file__).parent
(out / "guion.json").write_text(json.dumps(SLIDES, ensure_ascii=False, indent=2), encoding="utf-8")

lines = []
lines.append("# Guion de exposición · PHP2Shell (IS-1023)")
lines.append("")
lines.append("**Tono:** profesional, claro y directo. **Narración:** audio neural en español, 16 minutos aproximadamente (31 diapositivas).")
lines.append("")
lines.append("> Regla: la narración no lee comandos símbolo por símbolo; explica qué hace cada paso. Los comandos quedan visibles en la diapositiva y se ejecutan en la réplica.")
lines.append("")
lines.append("## Mapa rápido")
lines.append("")
lines.append("| # | Diapositiva | Expone |")
lines.append("|---|---|---|")
for s in SLIDES:
    lines.append(f"| {s['n']:02d} | {s['title']} | {s['owner']} |")
lines.append("")
lines.append("---")
lines.append("")

for s in SLIDES:
    lines.append(f"## {s['n']:02d} · {s['title']}")
    lines.append("")
    lines.append(f"**Expone:** {s['owner']}  ")
    lines.append(f"**Voz:** {s['speaker']}  ")
    lines.append(f"**Idea clave:** {s['caption']}")
    lines.append("")
    lines.append(f"**Narración:** {s['text']}")
    lines.append("")
    lines.append(f"**Apoyo visual:** {s['support']}")
    lines.append("")
    if s.get("transition"):
        lines.append(f"**Transición:** {s['transition']}")
        lines.append("")
    lines.append("---")
    lines.append("")

lines.append("## Anexo · Réplica en vivo desde Kali")
lines.append("")
lines.append("1. **Version gate.** `php -v`, `httpd -V` y `wp core version` en M1; confirmar 8.4.26 y 2.4.49. Mostrar que 8.4.27 es el fix.")
lines.append("2. **Precondiciones.** `php -i | grep -E 'Thread Safety|memory_limit|display_errors|session.upload_progress'` y `nm libphp.so | grep -E 'zif_system|zval_ptr_dtor'`.")
lines.append("3. **Staging.** Confirmar `session2.php` en `http://10.10.10.11:8080` y el worker prefork.")
lines.append("4. **Chain A.** Ejecutar los cinco pasos de la diapositiva 21; la salida esperada es `uid=33(www-data)` y el marcador `PWNED-M1-www-data`.")
lines.append("5. **Root.** `curl` al FTP de M3, leer `credenciales.txt`, `ssh ubuntu@10.10.10.11`, `sudo id`; la salida esperada es `uid=0(root)` y `PWNED-M1-root.txt`.")
lines.append("6. **Evidencia.** Mostrar `EV-W2-07`, `EV-W2-09` y `sha256sum` de los logs.")
lines.append("7. **Retest.** Repetir los mismos comandos: PHP 8.4.27, LFI 404, Redis `NOAUTH`, FTP `530`; M5 se declara pendiente.")
lines.append("")

(out / "guion.md").write_text("\n".join(lines), encoding="utf-8")
print(f"OK: {len(SLIDES)} slides")
