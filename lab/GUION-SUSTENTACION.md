# Guion de sustentación · explicado para quien nunca ha explotado

> Este documento no es para ejecutar (eso es `GUIA-EXPLOTACION.md`).
> Es para **entender y explicar** la cadena en la presentación y en la réplica.
> Regla de oro: decir siempre qué es CVE, qué es mala configuración y qué es
> un componente añadido por el laboratorio.

---

## Parte 1 · Cinco conceptos y ya

| Concepto | Qué es, en simple |
|---|---|
| **Vulnerabilidad** | Un defecto en un programa: una puerta que quedó mal cerrada. |
| **Exploit** | La receta que aprovecha ese defecto. |
| **Payload** | Lo que quieres que pase después: ejecutar `id`, abrir una shell, escribir un archivo. |
| **RCE** | *Remote Code Execution*: lograr que la máquina ejecute tu código desde la red. |
| **Escalada** | Pasar de un permiso pequeño (un usuario web) a uno grande (root/SYSTEM). |
| **Pivote** | Usar una máquina ya comprometida para llegar a la siguiente. |

La cadena completa es eso: **cinco veces convertir un acceso pequeño en uno más grande.**

---

## Parte 2 · La idea en una frase

> "Entré como el usuario más débil del servidor web; desde ahí fui usando los
> defectos de cada máquina para convertirme en el usuario más poderoso de la
> siguiente, hasta llegar al escritorio del cliente."

| Salto | Lo que tengo al empezar | Lo que consigo | Por qué importa |
|---|---|---|---|
| 1 | Red y un navegador | `www-data` en M1 | Ya ejecuto comandos en el servidor |

> **Ojo con la palabra "root".** El salto 1 da `www-data`, el usuario del servicio
> web, **no root**. Root aparece en el salto 2 (M2). Si alguien pregunta "¿ya eres
> root en M1?", la respuesta honesta es: "no, y no lo necesito: el siguiente salto
> se ataca por red contra M2".
| 2 | Comandos en M1 | `root` en M2 | La base de datos y su red |
| 3 | `root` en M2 | `root` en M3 | Los respaldos y el almacenamiento |
| 4 | `root` en M3 | `SYSTEM` en M4 | El DNS y la red interna |
| 5 | `SYSTEM` en M4 | Escritorio de M5 | El cliente final |

Nadie "adivina contraseñas": cada salto explota un defecto distinto.

---

## Parte 3 · Los cinco saltos, explicados

### Salto 1 · PHP2Shell — de visitante a `www-data`

**Analogía.**
Imagina que la recepcionista del edificio tiene una libreta donde anota lo que
le dictas ("paquete para el piso 3"). Y al lado hay un conserje que dice:
"dame el nombre de un archivo y te lo abro", sin comprobar que esté dentro de su
carpeta. Nosotros dictamos código en la libreta y le pedimos al conserje que
abra la libreta. Al abrirla, el código se ejecuta.

**Qué pasa técnicamente, paso a paso.**
1. PHP tiene una función llamada `session.upload_progress` que guarda en un
   archivo (`/tmp/sess_<id>`) el nombre del campo que el navegador envía al subir
   un archivo. Ese nombre lo controla el atacante.
2. Enviamos como nombre de campo: `<?php system($_GET["c"]); ?>`.
   PHP lo escribe **tal cual** dentro del archivo de sesión.
3. El plugin `legacy-download` hace `include $carpeta . $_GET['file']` sin
   normalizar la ruta. Con `../../../../../../../tmp/sess_<id>` sale de su carpeta y
   abre el archivo de sesión.
4. `include` interpreta el archivo como plantilla PHP. Al llegar al `<?php ... ?>`
   que estaba dentro del texto serializado, lo ejecuta.
5. El comando corre con el usuario del servidor web: **`www-data`**.

**Por qué funciona.** Dos defectos se suman:
- el progreso de subida escribe datos del atacante en un archivo ejecutable;
- el plugin abre archivos sin validar la ruta (LFI).
Por separado no bastan. Juntos dan ejecución.

**Qué gano.** Un shell como `www-data`: leer `wp-config.php`, ver la red interna,
lanzar comandos. Es el primer peldaño, no el final.

**Cómo lo explico en 20 segundos.**
"Le pedí a PHP que guardara mi texto en su archivo de sesión, y luego convencí a
un plugin viejo de que abriera ese archivo. Al abrirlo, PHP ejecutó mi código con
el usuario del servidor web."

**Lo que debo declarar.** Esto es *session injection + LFI*, no el fallo de memoria
de CVE-2026-109618. El CVE puro está documentado aparte y no se declara resuelto.

---

### Salto 2 · Redis — de `www-data` a `root` en M2

**Analogía.**
Redis es un armario de llaves que **no pide identificación** y que además tiene
permiso de administrador del edificio. Le dices "guarda esto en la carpeta
`/root/.ssh` con el nombre `authorized_keys`", y lo hace. Acabamos de escribir
nuestra propia llave en la lista de llaves que dejan entrar como root.

**Qué pasa técnicamente.**
1. Redis escucha en `0.0.0.0:6379` **sin contraseña** (`requirepass` vacío).
2. Además corre como **root** (mala configuración intencional).
3. `CONFIG SET dir /root/.ssh` cambia la carpeta donde Redis guarda su base.
4. `CONFIG SET dbfilename authorized_keys` cambia el nombre del archivo.
5. `SET x "<nuestra llave pública>"` + `SAVE` escriben ese archivo como root.
6. `ssh -i llave root@M2` entra porque la llave ya está autorizada.

**Por qué funciona.** Un servicio sin autenticación que además tiene permisos de
root permite escribir donde quiera. No hay contraseña que adivinar.

**Qué gano.** `root` en M2: la base de datos, la red y la posibilidad de montar
sistemas de archivos de otras máquinas.

**Cómo lo explico en 20 segundos.**
"Había un Redis abierto a la red, sin contraseña, corriendo como root. Le dije que
guardara mi llave pública en la carpeta de root y entré con esa llave."

**Lo que debo declarar.** Es una **mala configuración**, no un CVE. Si el docente
exige CVE, la alternativa es CVE-2022-0543 (escape del sandbox Lua), que necesita
el paquete Debian de Redis.

---

### Salto 3 · NFS + cron — de `root` en M2 a `root` en M3

**Analogía.**
M3 comparte una carpeta con una regla peligrosa: "si vienes como root de tu
máquina, aquí también eres root" (`no_root_squash`). Y M3 tiene una alarma que
cada minuto ejecuta un script guardado **dentro de esa carpeta**. Cambiamos el
script desde M2 y esperamos: M3 lo ejecuta como root.

**Qué pasa técnicamente.**
1. `/srv/storage/backups` se exporta a toda la LAN con `no_root_squash`.
2. Un cron de M3 (`/etc/cron.d/lab-rotate`) ejecuta cada minuto
   `/srv/storage/backups/rotate.sh` **como root**.
3. Desde M2 (ya somos root) montamos el export y sobrescribimos `rotate.sh`.
4. El script nuevo añade nuestra llave a `/root/.ssh/authorized_keys` de M3.
5. Esperamos al cron y entramos con `ssh root@M3`.

**Por qué funciona.** Se confía en el root del cliente NFS y se ejecuta código
desde un directorio que ese cliente puede escribir.

**Qué gano.** `root` en M3: los respaldos y el almacenamiento compartido.

**Cómo lo explico en 20 segundos.**
"M3 confiaba en el root de sus clientes NFS y ejecutaba como root un script que
estaba en la carpeta compartida. Lo reemplacé desde M2 y esperé un minuto."

**Lo que debo declarar.** Es **configuración insegura** (NFS + cron), no un CVE.

---

### Salto 4 · PrintNightmare (CVE-2021-34527) — de `root` en M3 a `SYSTEM` en M4

**Analogía.**
El servicio de impresión de Windows es un conserje que, cuando alguien le pide
imprimir, va a buscar un controlador a la dirección que le digan. Si esa dirección
es nuestra, le damos un controlador malicioso y lo ejecuta con los máximos permisos.

**Qué pasa técnicamente.**
1. M4 tiene el **spooler** activo y sin el parche de PrintNightmare.
2. Con la cuenta limitada `soporte` pedimos instalar un controlador desde una ruta
   de red (`\\10.10.10.20\...`).
3. El spooler carga nuestra DLL y la ejecuta como **`SYSTEM`**.
4. Prueba: el payload escribe `whoami` en el share `Transfer`, que es público.

**Por qué funciona.** El spooler confía en la ruta del controlador y lo carga con
demasiados privilegios: no valida quién lo pide ni de dónde viene.

**Qué gano.** `SYSTEM` en M4: el DNS y la red interna, y desde ahí el cliente.

**Cómo lo explico en 20 segundos.**
"El servicio de impresión de Windows cargaba un controlador desde donde le
dijéramos. Le dimos uno nuestro y lo ejecutó como SYSTEM."

**Lo que debo declarar.** Usa la cuenta limitada `soporte` (precondición del
escenario: un empleado con cuenta, sin privilegios). MS17-010 (EternalBlue) queda
como alternativa solo si M4 fuera Server 2012 R2.

---

### Salto 5 · VNC sin autenticación — de `SYSTEM` en M4 al cliente

**Analogía.**
El escritorio de M5 tiene la puerta abierta: VNC está configurado **sin
contraseña**. Cualquiera en la red ve la pantalla y controla el ratón y el teclado.

**Qué pasa técnicamente.**
1. TightVNC 2.8.90 escucha en `5900` con `UseVncAuthentication=0`.
2. `nmap --script vnc-info` responde `Authentication: None`.
3. `vncviewer M5` conecta sin pedir nada.
4. En el escritorio está la bandera del cliente.

**Por qué funciona.** Autenticación deshabilitada (CWE-306): el servicio no pide
identidad.

**Qué gano.** Acceso visual y control del equipo del usuario final.

**Cómo lo explico en 20 segundos.**
"El cliente tenía VNC sin contraseña. Me conecté y vi su escritorio y su bandera."

**Lo que debo declarar.** Da escritorio, no shell; la evidencia es la captura, no
un `id`.

---

## Parte 4 · Guion de la presentación (12–15 min)

### Diapositiva 1 · Portada (30 s)
- Título, materia, integrantes, fecha.
- Frase: "Una entrada, cinco saltos, una cadena."

### Diapositiva 2 · Qué vamos a demostrar (1 min)
- Red aislada de 6 VM.
- Objetivo: llegar de fuera a la máquina del cliente.
- Regla: **todo por vulnerabilidades, sin contraseñas adivinadas.**

### Diapositiva 3 · Qué es explotar (1 min)
- Vulnerabilidad / exploit / payload / RCE / escalada.
- Analogía de la libreta y el conserje (salto 1).

### Diapositiva 4 · Mapa de la cadena (1 min)
```
M6 → M1 (PHP2Shell) → [pivote] → M2 (Redis) → M3 (NFS) → M4 (PrintNightmare) → M5 (VNC)
```
- Decir en voz alta qué se gana en cada flecha.

### Diapositivas 5–9 · Un salto por diapositiva (5 min)
Para cada uno, mismo orden:
1. **La puerta mal cerrada** (una frase).
2. **Qué hicimos** (3 pasos, sin leer comandos).
3. **Qué obtuvimos** (usuario y privilegio).
4. **Por qué eso abre la siguiente**.
5. **Evidencia** (captura o log).

### Diapositiva 10 · La conversión de privilegios (1 min)
Tabla "qué tenía / qué conseguí". Es la diapositiva que explica la escalada.

### Diapositiva 11 · Remediación (1 min)
Qué se parchea en cada máquina y cómo se verifica que el ataque ya falla.

### Diapositiva 12 · Límites y honestidad (1 min)
- `entry-b` no es el UAF del CVE.
- Redis como root es configuración, no CVE.
- PrintNightmare usa la cuenta limitada soporte (precondición, no vulnerabilidad).
- VNC da escritorio, no shell.

### Cierre (30 s)
"El valor no es el exploit: es la cadena y la remediación."

---

## Parte 5 · Réplica en vivo (checklist)

### Antes de entrar al salón
```bash
bash lab/chain/00-preflight.sh --full   # FAIL=0
bash lab/tests/smoke.sh                 # todo PASS
# snapshots: estado-inicial en todas las VM
# terminales abiertas: una en M6, una en M4 (opcional), una en M5
# fuentes grandes, historial limpio
```

### Orden de la demo
1. `01 --run` → mostrar `uid=33(www-data)`.
2. `02 --run` → `uid=0(root)` en M2.
3. `03 --run` → `uid=0(root)` en M3 + `PWNED-M3.txt`.
4. `04 --run` → `nt authority\system`.
5. `05 --run` → captura del escritorio con la bandera.

### Si algo falla en vivo
- **Nunca improvisar un "ya funcionó".** Decir: "este salto depende de X; lo
  muestro con el log de la ejecución anterior" y enseñar la evidencia.
- Tener a mano `LOG-0X.txt` de cada salto por si la red falla.
- Si PrintNightmare no cierra: revisar spooler y el módulo, y explicar.

---

## Parte 6 · Preguntas del jurado y respuestas

**"¿Por qué no usaron contraseñas?"**
"El objetivo era demostrar vulnerabilidades, no fuerza bruta. Las cuentas del
laboratorio son solo de administración y no forman parte de la cadena."

**"¿Eso es un CVE de verdad?"**
"El salto 1 usa el vector de PHP2Shell, pero materializado con session injection
y un LFI del laboratorio; no es el fallo de memoria de CVE-2026-109618. Los saltos
4 sí es CVE (PrintNightmare); el salto 1 usa el vector PHP2Shell. Los saltos 2, 3 y 5 son configuraciones inseguras."

**"¿Por qué M4 y M5 son Windows?"**
"Para demostrar que la cadena no depende de un solo sistema: Linux para la
entrada y los servicios, Windows para la red y el puesto del cliente."

**"¿Cómo se detiene esto?"**
"Tabla de remediación: PHP 8.4.27 y quitar el plugin; Redis con contraseña y sin
root; NFS con `root_squash` y sin cron sobre el export; PrintNightmare parcheado y spooler detenido; VNC
con contraseña."

**"¿Por qué Redis corre como root?"**
"Es una mala configuración deliberada del escenario, documentada. Si se exige un
CVE, la variante es CVE-2022-0543 con el paquete Debian de Redis."

**"¿Hay pivote real?"**
"Sí: después del salto 1, `01b-pivot.sh` sube el agente de ligolo-ng a M1 y monta
un túnel con rutas /32. A partir de ahí, el tráfico a M2–M5 sale por M1; M6 solo
habla directo con M1."

**"¿Qué evidencia tienen?"**
"Por salto: comando, salida, captura, SHA256 y hora UTC. Sin `id`/`whoami` y
marcador, el salto no se declara."

---

## Parte 7 · Errores que hunden una demo

1. **Decir "root" cuando solo hay `www-data`.** Cada salto tiene su usuario.
2. **Presentar el LFI como el CVE.** Separar siempre vector, sink y CVE.
3. **Leer comandos en voz alta.** Explicar el concepto; el comando se ve en pantalla.
4. **No tener evidencia de respaldo.** Si la red falla, se muestra el log.
5. **Prometer un salto que depende de un módulo.** PrintNightmare puede fallar; decirlo.
6. **Mezclar CVSS v3.1 y v4.0.** Usar una sola métrica por hallazgo.

---

## Parte 8 · Cómo explicar la remediación

No es "actualicen todo". Es: **cada salto se cae si se quita su condición.**

| Salto | Se cae si… | Verificación |
|---|---|---|
| 1 | PHP 8.4.27, `upload_progress=Off`, plugin legado eliminado | el LFI da 404 y el vector no escribe sesión |
| 2 | Redis con `requirepass`, `bind 127.0.0.1`, sin root | `PING` sin auth falla |
| 3 | NFS con `root_squash` y sin cron sobre el export | `mount` no permite escribir como root |
| 4 | PrintNightmare parcheado y spooler detenido | el exploit ya no carga la DLL |
| 5 | VNC con contraseña (o localhost) | `vnc-info` ya no dice `None` |

Ese es el mensaje final: **la cadena se rompe por cualquier eslabón.**
