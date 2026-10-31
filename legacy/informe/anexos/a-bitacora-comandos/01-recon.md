# Bitácora · Fase 1 · Reconocimiento

Fecha UTC: 2026-10-24 · Ejecuta: M6 `10.10.10.20`

| ID | Comando | Explicación | Salida real (resumen) | Evidencia | Lectura |
|---|---|---|---|---|---|
| CMD-F01-001 | `hostname; id; ip -brief a; ip route` | Identifica la estación y su posición en la red | `kali`, `uid=1000(kali)`, `eth0 10.10.10.20/24`, ruta directa a `10.10.10.0/24` | `F01-001` | M6 está en la LAN; `eth2` es NAT y debe desconectarse |
| CMD-F01-002 | `dig +short app.uni.lab @10.10.10.14` | Consulta el DNS interno de M4 | `10.10.10.11` | `F01-002` | El DNS de M4 resuelve `uni.lab` |
| CMD-F01-003 | `for n in app wp moodle db bkp srvold pc-est01; do dig +short ...; done` | Enumera los nombres del entorno | `wp/moodle → app.uni.lab → .11`, `db .12`, `bkp .13`, `srvold .14`, `pc-est01 .15` | `F01-002` | Mapa de nombres completo |
| CMD-F01-004 | `dig +short SOA uni.lab @10.10.10.14` | Comprueba el tipo SOA | `communications error ... timed out` | `F01-002` | Limitación del DNS; se reintenta con `+tcp`/AXFR |
| CMD-F01-005 | `curl -sI http://10.10.10.11` | Lee cabeceras de la puerta | `301`, `Apache/2.4.49 (Unix) PHP/8.4.26`, `Location: http://wp.uni.lab/` | `F01-003` | Apache/PHP vulnerables; IP redirige al vhost |
| CMD-F01-006 | `curl -sI http://wp.uni.lab` | Cabeceras del vhost correcto | `200 OK`, `Server: Apache/2.4.49`, `X-Powered-By: PHP/8.4.26` | `F01-003` | Se confirma el vhost y las versiones |
| CMD-F01-007 | `curl -s http://10.10.10.11/robots.txt` | Busca rutas declaradas | `Disallow: /wp-admin/`, `Sitemap: ...` | `F01-003` | WordPress confirmado |
| CMD-F01-008 | `whatweb http://wp.uni.lab` | Fingerprint automático | `Apache[2.4.49]`, `PHP[8.4.26]`, `WordPress[7.0.1]` | `F01-004` | Confirma W1/W2/W3 por versión |
| CMD-F01-009 | `nmap -sn 10.10.10.0/24` | Descubre hosts | 7 hosts: `.1`, `.2`, `.12`, `.13`, `.14`, `.15`, `.20` | `F01-005` | M1 `.11` no aparece: falso negativo |
| CMD-F01-010 | `ping -c 2 10.10.10.11` | Comprueba ICMP a M1 | `2 received`, RTT 317–1349 ms | `F01-006` | M1 está arriba pero con latencia alta |
| CMD-F01-011 | `nmap -sn 10.10.10.11` | Descubrimiento puntual | `Host seems down` | `F01-006` | `nmap -sn` no es fiable en M1; usar `-Pn` |
| CMD-F01-012 | `curl -sI http://10.10.10.11` | Confirma servicio pese al falso negativo | `301`, Apache/PHP | `F01-006` | La evidencia de servicio manda sobre el descubrimiento |

**Cierre:** mapa de activos y tecnologías completo; limitaciones de DNS y de `nmap -sn` documentadas.
