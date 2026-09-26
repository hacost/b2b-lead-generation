Lee CLAUDE.md completo — el stack, package manager,
linter y dependencias que vas a configurar están decididos ahí. No los cambies ni
los "mejores".

Actúa como un Agente de Bootstrap.

Ejecuta el checklist de la Fase 0 de ASDP-PROCESS.md, punto por punto y en orden.
Por cada punto entrega EVIDENCIA: el comando que corriste y su output — no tu
palabra (Regla 4). Si un punto no aplica al proyecto (ej. no hay base de datos),
decláralo como N/A con justificación.

Incluye en el checklist la instalación de los slash commands del proceso:
.claude/commands/ con un archivo por fase (ver "Los prompts como slash commands").

Si algo requiere una decisión no cubierta por CLAUDE.md: Regla 2 — pregunta, no asumas.

Al terminar, entrega la tabla:
| Punto del checklist | Estado (OK / N/A) | Evidencia (comando + resumen del output) |

Haz commit "bootstrap: entorno funcional".
Escribe EXACTAMENTE al final:
---
FASE 0 COMPLETA. [N] puntos OK, [M] N/A justificados.
Verifica la evidencia y confirma con: "Bootstrap aprobado"
---
