# Plantilla de plan

## 1. Enfoque

Cómo se implementa la spec, en 3–5 frases.

## 2. Actividades por máquina

| VM | Actividad | Comando/Herramienta | Evidencia |
|---|---|---|---|
| M1 | ... | ... | ... |

## 3. Comandos (uso interno)

> No van al informe oficial.

```bash
# ...
```

## 3.1 Version gate

| Campo | Valor |
|---|---|
| Versión instalada | ... |
| Rango vulnerable | ... |
| Versión que corrige | ... |
| Comando de verificación | ... |
| Evidencia | ... |

## 4. Snapshots

| Snapshot | Cuándo | Para qué |
|---|---|---|
| `previo-a-...` | ... | ... |

## 5. Evidencia

- Captura: `EV-F0X-NNN.png`
- Log: `LOG-F0X-NNN.txt`
- Hash: `sha256sum`

## 6. Riesgos y rollback

- Si falla: restaurar `...` y documentar.
- Si el servicio no arranca: ...

## 7. Definición de terminado

- [ ] Requisitos cumplidos.
- [ ] Evidencia registrada.
- [ ] `tasks.md` actualizado.
- [ ] `MEMORY.md` actualizado.

## 8. Estimación

| Actividad | Horas |
|---|---|
| ... | ... |
