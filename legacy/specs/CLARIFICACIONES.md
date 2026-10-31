# Clarificaciones · decisiones antes de planificar

> Paso 3 del SDD. Aquí se registran las ambigüedades y las decisiones tomadas antes de ejecutar. Si una decisión cambia, se actualiza esta tabla y `MEMORY.md`.

## 1. Decisiones cerradas

| ID | Fase | Pregunta | Decisión | Impacto |
|---|---|---|---|---|
| CL-001 | 2/4 | ¿W1 o W2 como demo principal? | **W1 wp2shell** principal; W2 con time-box | Menos riesgo; W1 tiene PoC público |
| CL-002 | 4 | ¿Cuánto tiempo para W2? | **3–4 h**; si falla, se documenta y se sigue con W1/W3 | Evita bloquear la cadena |
| CL-003 | 2 | ¿Samba 4.5.10 o 4.5.9? | **4.5.9** para que SambaCry sea real; 4.5.10 es el fix | B1 deja de ser inválido |
| CL-004 | 2 | ¿B2 con tarball limpio o troyanizado? | **Opcional**; si no se usa el troyanizado, se retira | Evita un hallazgo falso |
| CL-005 | 2/4 | ¿M4 con admin o usuario limitado? | **Usuario limitado `soporte`** + PrintNightmare local | Cumple el privesc obligatorio |
| CL-006 | 2 | ¿Redis fuente o distro para D1? | **Distro** si se quiere el 10.0; si no, documentar | CVE-2022-0543 es de empaquetado |
| CL-007 | 2 | ¿C1 EternalBlue en M5? | **No aplica** a Win10 19045; retirar | Evita un hallazgo inválido |
| CL-008 | 5 | ¿Solo configuración o versiones? | **Actualizar** WP/PHP/Apache/Redis; config para el resto | La guía premia el parche de versión |
| CL-009 | 7 | ¿Fases del informe? | **0–7** de la guía; el ciclo de ataque va como subapartado de Fase 4 | Coherencia con la guía |
| CL-010 | 7 | ¿Comandos en el informe? | **No**; van al anexo interno | La guía pide metodología, no recetas |
| CL-011 | 0 | ¿VMware o VirtualBox? | **VMware** declarado; snapshots con la ruta de VMware | La guía pide VirtualBox; se justifica |
| CL-012 | 4 | ¿Desde dónde se explota M4? | **Desde M1/pivote**, no desde M6 | El firewall de M4 solo permite M1 |

## 2. Decisiones pendientes

| ID | Fase | Pregunta | Opciones | Dueño | Fecha |
|---|---|---|---|---|---|
| CL-013 | 4 | ¿W3 se hace RCE con CGI o solo traversal? | RCE / traversal / limitación | M1 | — |
| CL-014 | 4 | ¿PrintNightmare local o `Invoke-Nightmare`? | MSF local / PowerShell | M4 | — |
| CL-015 | 4 | ¿S1 se intenta o se retira? | Intentar / retirar | M4 | — |
| CL-016 | 6 | ¿PHP 8.4.27 compilado o `upload_progress=Off`? | Compilar / mitigar | M1 | — |

## 3. Regla

Una decisión no se cambia en silencio. Se actualiza esta tabla, `MEMORY.md` y la spec afectada. Si la decisión cambia el alcance, se vuelve al Paso 2 (Spec).
