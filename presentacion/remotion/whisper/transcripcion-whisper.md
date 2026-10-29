# Transcripción automática con Whisper

## 01 · Portada — PHP2Shell

**Voz:** es-MX-JorgeNeural · **Duración:** 24.8s

Buenas tardes. Somos el equipo de seguridad de la información y presentamos PHP 2L, un caso real de explotación sobre PHP 8.4.26 en la red universitaria. Partimos de la superficie expuesta, llegamos a www.dera y luego a root. Todo está respaldado con comandos, capturas y hashes. La réplica se hará en vivo desde Cali.

## 02 · Recorrido de la exposición

**Voz:** es-MX-JorgeNeural · **Duración:** 36.5s

El recorrido tiene cinco fases. Fase 1, configuración y superficie, con la red, topología, activos, puertos y versiones. Fase 2, exploración, con dos comandos por máquina y su salida. Fase 3, explotación de PHP 2L, desde el version get hasta chene, wwwdera y root. Fase 4, mitigación, con versión o configuración por máquina y el comando de verificación. Fase 5, retest y cierre. La idea es simple, de la versión vulnerable a root, con evidencia en cada fase.

## 03 · Contexto: qué quisimos montar

**Voz:** es-PE-AlexNeural · **Duración:** 29.3s

La red universitaria expone un portal web, base de datos, respaldos, un Windows heredado y estaciones de trabajo. Todo en 10.10.10.0 diagonal 24, m6 es el punto de auditoría desde donde se valida la superficie. Identificamos 24 hallazgos, 22 se llevaron a evidencia. El objetivo es identificar, enumerar, explotar, escalar a root, remediar y verificar.

## 04 · Arquitectura y camino de ataque

**Voz:** es-PE-AlexNeural · **Duración:** 32.5s

La topología tiene una sola puerta web, M1. Desde M1 se pibota a M2, la base de datos, y a M3, los respaldos. M4 es el Windows Server y M5 la estación cliente. R0 solo transporta. La separación es lógica, no física, documentamos que 445 de M4 y 5900 de M5 quedaron visibles desde M6. Ese detalle también es parte del hallazgo.

## 05 · Activos: qué expone cada máquina

**Voz:** es-PE-AlexNeural · **Duración:** 38.1s

Estas son las versiones que observamos desde Cali. M1 corre Apache 2.4.49, PHP 8.4.26 y WordPress 7.0.1. M2 tiene MariaDB 10.11.19 y Redis 6.2.6. M3 se expone FTP, SMB y NFS. M4 es Windows Server 2016 con DNS y SMB. M5 es Windows 10 con Tiktok BNC. Las versiones exactas son las que disparan el version gate.

## 06 · M1 · Aplicación

**Voz:** es-PE-AlexNeural · **Duración:** 27.3s

N1 es el servidor de aplicación y la puerta de entrada. Publica WordPress y Moodle, y concentra la base de datos. Aquí explotamos W2 por Chena, que nos dio wwwdera, W3, el traversal de Apache, que también dio wwwdera, y W4, una clave débil que permitió entrar como administrador. Con Asasach y sudo cerramos el camino a root.

## 07 · M2 · Base de datos

**Voz:** es-PE-CamilaNeural · **Duración:** 20.4s

M2 es la base de datos. Redis respondió sin autenticación y confirmamos el acceso con un PON. Desde WQQNFG obtuvimos las claves de la base y, por un túnel SSH, leímos WordPress con 12 tablas y mudé el guión bajo DB con 487. No hizo falta un exploit complejo, la configuración expuesta fue suficiente.

## 08 · M3 · Respaldos

**Voz:** es-BO-MarceloNeural · **Duración:** 23.2s

M3 es el servidor de respaldos. El Actity aceptaba acceso anónimo y dentro estaba credenciales, TXT con la clave Admin 13. Esa misma clave se reutilizaba en M1. Además, NFS permitía escribir como root por node yon bajo root yon bajo squash. Con esas dos debilidades, M3 se convirtió en el eslabón que entregó la llave maestra.

## 09 · M4 · Windows Server

**Voz:** es-MX-DaliaNeural · **Duración:** 24.4s

M4 es el Windows Server. La cuenta de administrador tenía una clave débil, con ello obtuvimos PWN3 de y acceso a las comparticiones. El DNS permitía transferencia de zona, así que obtuvimos el mapa completo de Unic Lab. Con credenciales administrativas llegamos a Sistem mediante una tarea programada. No fue un privilege escalation desde un usuario limitado.

## 10 · M5 · Cliente

**Voz:** es-CO-GonzaloNeural · **Duración:** 23.0s

M5 es la estación cliente. Tituense no pedía autenticación, así que abrimos el escritorio directamente. Buami confirmó el usuario cliente y dejamos el marcador poner M5. También se reutilizaba la clave por SMB. Es el impacto más visible, el usuario final, su escritorio y sus archivos. La remediación de M5 quedó pendiente por filtrado.

## 11 · M6 · Auditoría

**Voz:** es-AR-TomasNeural · **Duración:** 20.8s

M6 Scali, la estación de auditoría, y no es objetivo. Desde aquí ejecutamos reconocimiento, escaneo, explotación, túneles y captura de evidencia. También aloja el FTP de artefactos y los lows con Sa-256. Es el punto de partida y el punto donde se demuestra que todo lo anterior es reproducible.

## 12 · Reparto de PHP2Shell

**Voz:** es-MX-JorgeNeural · **Duración:** 30.9s

Para la exposición dividimos PHP 2L en seis partes. Eric presenta la ficha, el CVSS y el version get. Doris, las precondiciones, NTS, Prefork y PHP, INI. Ronny, los offsets reales y el servicio en 8080. Fabiola, la inyección de sesión. Marco, el LFI y la ejecución. José cierra con evidencia, el root por B3, SSH y sudo, y el retest.

## 13 · Metodología y version gate

**Voz:** es-PE-AlexNeural · **Duración:** 42.1s

Trabajamos en 7 fases, alcance, reconocimiento, enumeración, análisis, explotación, remediación y retest. Cada flecha tiene una puerta de versión. Primero verificamos que versión está instalada, segundo, si está dentro del rango vulnerable, tercero, que versión la corrige, cuarto, decidimos si es explotable. Si la instalada es igual o mayor que el fix, el CV no cuenta. En W2 la versión estaba en rango y el servicio explotado cumplía las condiciones, NTS, Prefork y Offset reales. El gate confirmó versión y condiciones antes de ejecutar.

## 14 · Qué es PHP2Shell y por qué importa

**Voz:** es-PE-AlexNeural · **Duración:** 44.4s

PHP 12 es el caso de 12v de corrupción de memoria en PHP 8.4.26 que permiten ejecución remota antes de autenticarse. Se vuelve relevante porque afecta una versión muy extendida, el ataque es remoto y de baja complejidad, y el pose es reproducible, además, la historia se entiende rápido, de un PHP vulnerable a root. En nuestro caso, la versión 8.4.26 estaba en rango, el servicio 8,080 cumplía las condiciones y Chena dio WWW dera, luego B3, SSH y sudo dieron root. Por eso el version get, la evidencia y el retest son parte de la misma cadena.

## 15 · W2 · Ficha

**Voz:** es-PE-AlexNeural · **Duración:** 46.8s

W2 son 2 CV de corrupción de memoria en PHP 8.4.26, CV 2026, 1096, 18 y CV 2026, 1096, 19. El vector es de red, sin autenticación y sin interacción, el CVS es versión 3.1 es 9.8, crítico. La versión afectada va de 8.4.0 a 8.4.26 y la corrige 8.4.27. El EPSS está sin dato porque el CV es reciente. El resultado real, RCE como wwwdera y root por la cadena B3, SSH y sudo.

## 16 · W2 · Version gate

**Voz:** es-PE-AlexNeural · **Duración:** 25.1s

El Dorsion Gate confirma que 8.4.26 está dentro del rango vulnerable y que 8.4.27 corrige. El servicio expuesto corre con NTS y Prefork y cumple las condiciones del posee. Por eso declaramos versión y condiciones verificadas y ejecutamos la cadena. El Gate separa a Ion CVE de se puede explotar aquí.

## 17 · W2 · Precondiciones

**Voz:** es-PE-CamilaNeural · **Duración:** 29.4s

El servicio explotado presenta seis condiciones. Necesita NTS, es decir, Sintrad Safety, Apache con MP MP4, Display yo bajo Error se encendido, Memory yo bajo Limit de 16 MB, Session. Upload yo bajo Progres habilitado y con Clean up apagado, y los Offsets del binario real. Se verificaron con PHP y HTTP de VINM antes de ejecutar. El pose usa comandos de hasta 14 bytes y Chen asuma una sesión compartida y un ZenKalafá.

## 18 · W2 · Rebuild

**Voz:** es-PE-CamilaNeural · **Duración:** 24.3s

El servicio vulnerable es php8.4.26 nts sobre Apache 2.4.49 preform, publicado en el puerto 8080. Presente display y gomajo errors, memory gomajo limit de 16m, session, upload gomajo progress y session 2, PHP con HTTP 200 y session compartida. Es el entorno que se explotó y quedó documentado en UVW 2-Gion 01.

## 19 · W2 · Configuración y offsets

**Voz:** es-BO-MarceloNeural · **Duración:** 23.7s

Los offsets no se copian de internet. Se derivan del lib.s o del servidor m1. Con nm obtuvimos las direcciones de sifgion bajo system, spalgion bajo ptrgion bajo toritrata. An offset de otro b oda hace fallar el pose aunque la versión sea correcta. Por eso el PHP, INI y los símbolos se verifican sobre el handler de apache, no solo por línea de comandos.

## 20 · W2 · Chain A

**Voz:** es-MX-DaliaNeural · **Duración:** 40.5s

China convierte la sesión en ejecución remota en cinco pasos. Primero, Sashen uploadió majo progres creaba radional TMP barradionalses con el contenido del request. Segundo, el nombre del campo y el valor inyectan código PHP. Tercero, el sencoutfá incluye ese archivo. Cuarto, PHP interpreta el código en el worker. Quinto, ID devuelve UID 33, www, y escribimos el marcador PnetM1-WWWWData. La cadena se ejecuta contra el servicio 8080 y luego se escala por B3, SSH y sudo.

## 21 · W2 · Comandos

**Voz:** es-CO-GonzaloNeural · **Duración:** 28.3s

Estos son los cinco comandos clave. El primero crea la sesión con un plug-in bajo progres y deja el código inyectado en barra diagonal tmp barra diagonal ses. El segundo fuerza el mismo Worker y confirma que la sesión persiste. El tercero incluye el archivo de sesión por el LFI. El cuarto ejecuta id y devuelve wwwdata. El quinto reutiliza la clave b3 para entrar por sch como Ubuntu y escalar a root console. Cada paso tiene su salida esperada.

## 22 · Otra vía · W3

**Voz:** es-PE-AlexNeural · **Duración:** 30.2s

W3 es una segunda vía, independiente de PHP 2L. Apache 2.4.49 permite traversal de rutas, conseje y habilitado, la ruta llega a barra diagonal-bin-diagonal-esach. El comando se ejecuta como wwwdera. No necesitamos W3 para el resultado, pero demuestra que había más de un camino al mismo nivel. W3 y W12 se parchean por separado.

## 23 · Otra vía · B3

**Voz:** es-BO-MarceloNeural · **Duración:** 28.6s

V3 es la llave maestra. El aptity de M3 permite acceso anónimo y expone barra diagonal backups. Dentro está Credenciales, TXT con Admin 13. Esa clave se reutiliza en Ubuntu en M1. Entramos por SSH, ejecutamos su DoID y obtenemos su ID cero root. No es un exploit nuevo, es reutilización de credenciales. Y es lo que convierte el acceso wwwdata en control total.

## 24 · W2 · Evidencia

**Voz:** es-AR-TomasNeural · **Duración:** 28.6s

La evidencia es lo que sostiene todo. EV-W2G107 documenta China, session injection más LFI, con UI de 33WWWW data desde M1. EV-W2G109 documenta el root, V3, credenciales, SSH como Ubuntu, sudo y el archivo barra diagonal root barra diagonal PNED M1 root TXT. Cada lo tiene captura ISO 256.

## 25 · W2 · Impacto

**Voz:** es-AR-TomasNeural · **Duración:** 25.1s

El impacto real es este. WW2 por China dio WWWWData. WW3 también dio WWWWData. V3 más SSH y sudo dieron root. La diferencia entre hay un CV y se explotó está en la evidencia, un ID, un archivo o una captura verificable. WW2 no dio root por sí solo, la cadena completa sí.

## 26 · Cadena completa: de Kali a root

**Voz:** es-MX-JorgeNeural · **Duración:** 29.1s

La cadena completa tiene cinco eslabones. Cali entra a M1 por W2 China y obtiene WWW Dera. Desde M3, el FTP Anónimo Entrega Credenciales, TXT. Esa clave permite SSH como Ubuntu en M1. Con sudo llegamos a Root y dejamos Net, M1, Root, etc. La réplica en vivo sigue el mismo orden, versión, precondiciones, pose, evidencia y retest.

## 27 · Resto de la red

**Voz:** es-MX-JorgeNeural · **Duración:** 31.6s

El resto de la red también aporta. NM-2, redicina autenticación y las claves de la base permitieron volcar datos. NM-3, el FTP anónimo y ANAFAS NOD YON BAJO RUT YON BAJO ESQUAZ entregaron credenciales y escritura RUT. NM-4, la clave débil del administrador y el AXFR llevaron a Sistem y al mapa de DNS. NM-5, VNC sin autenticación abrió el escritorio. M5 sigue pendiente de remediación por filtrado.

## 28 · Remediación

**Voz:** es-MX-JorgeNeural · **Duración:** 38.0s

El parcheo se aplicó en cada servidor. Cambiaron versiones y configuraciones. PHP pasó a 8.4.27, WordPress a 7.0.2, Apache a 2.4.51 y Redis a 6.2.7. Apagamos su pl ratio en bajo progres, eliminamos el LFI, cerramos el FTP anónimo y deshabilitamos SMV1, M1 a M4 que daron cerrados. M5 no se pudo corregir porque 445, 3389 y 5900 quedaron filtrados, se declara pendiente, no remediado.

## 29 · Retest: antes y después

**Voz:** es-MX-JorgeNeural · **Duración:** 38.0s

El retesto son los mismos comandos de validación. M1 tiene 8 cierres, WordPress 7.0.2, PHP 8.4.27, Apache 2.4.51, el LFI en 404 y las claves rotadas. M2 tiene 4, Redisconnouse y puertos filtrados. M3 tiene 5, FTP anónimo en 530, Rucion bajo escuas y SSH rotado. M4 tiene 5, SMB1off, Sanenon, Spulerooff y AXFR cerrado. M5 sigue pendiente.

## 30 · Cuatro lecciones de PHP2Shell

**Voz:** es-MX-JorgeNeural · **Duración:** 32.7s

Cuatro lecciones. Primera, la versión es el punto de partida. PHP 8.4.26 habilitó la cadena. Segunda, los offsets son del binario. Copiarlos de otro pódase fallar el posee. Tercera, W2 más B3 tan rude. Cada eslabón tiene evidencia. Cuarta, parchear si cambia el juego. 8.4.27, Upload y un bajo progreso y LFI eliminado se verificaron en el retest. La fortaleza es la transabilidad de lo demostrado.

## 31 · Cierre y preguntas

**Voz:** es-MX-JorgeNeural · **Duración:** 29.1s

Con esto cerramos. PHP 2 el quedó demostrado con Chene, WWWDRE y Root por B3, SSH y sudo. W3 fue una segunda vía real. La remediación y el retest están documentados. Ahora respondemos preguntas si, si el docente lo permite, repetimos la réplica en vivo desde Cali, en el mismo orden, DORGENGATE, precondiciones, pose, evidencia y retest. Gracias.
