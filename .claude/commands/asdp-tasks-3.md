Lee estos archivos antes de empezar:
- CLAUDE.md
- specs/requirements.md (aprobado)
- specs/design.md (aprobado)
- specs/migrations/
- specs/openapi.yaml
- specs/graph.md, specs/tools.md y specs/prompts/ si existen (features con agente LLM)

---

Actúa como un Agente de Planificación senior.

Tu objetivo es generar specs/todo.md: tareas atómicas, ordenadas, implementables.
No escribas código. No tomes decisiones de diseño.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo
- [ ] specs/requirements.md aprobado por el humano
- [ ] specs/design.md, migrations/ y openapi.yaml aprobados por el humano
Si encuentras algo no definido en design.md/migrations/openapi.yaml que necesitas
para planificar una tarea: aplica Regla 2 — no lo inventes, documenta qué falta y espera instrucción.

RETROCESO POSIBLE DESDE ESTA FASE:
Si design.md, migrations/ u openapi.yaml tienen una laguna que no puede resolverse
sin rediseñar: aplica Regla 3.
Documenta qué TASK no puede planificarse y por qué el diseño es insuficiente.
Propón retroceder a Fase 2. Espera aprobación antes de continuar.

---

Para cada TASK produce esta estructura:

### TASK-[N]: [Nombre que expresa exactamente qué se construye]
- REQ asociado: [REQ-XXX]
- Dependencias: [TASK-X, TASK-Y] o "ninguna"
- Complejidad: S (menos de 2h) / M (2-4h) / L (más de 4h)
- Descripción: [qué construir, referenciando design.md/migrations/openapi.yaml con nombres exactos]
- Archivos a crear o modificar: [rutas completas]
- Contrato de error a implementar: [según openapi.yaml si existe para este endpoint; si no, según CLAUDE.md/design.md]
- Validaciones de input a implementar: [según openapi.yaml si existe para este endpoint; si no, según CLAUDE.md/design.md]
- Criterio de aceptación: [condición binaria — pasa o no pasa, sin ambigüedad]

Al terminar el listado, agrega:

## Mapa de cobertura
| REQ-XXX | TASK(s) que lo implementan |
|---|---|

## Orden de implementación
[lista las tasks en el orden que deben ejecutarse, verificando que no hay dependencias circulares]

---

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Cada REQ-XXX aparece en el mapa de cobertura con al menos una TASK
- [ ] Sin dependencias circulares en el orden de implementación
- [ ] Cada TASK tiene contrato de error y validaciones según la fuente que aplique (openapi.yaml o CLAUDE.md/design.md)
- [ ] Criterios de aceptación son binarios y verificables

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Guarda en specs/todo.md.
Escribe EXACTAMENTE al final:
---
FASE 3 COMPLETA. [N] tasks generadas cubriendo [M] requisitos. Definition of Done verificada.
Revisa specs/todo.md y confirma con: "Tasks aprobadas, iniciar TDD"
---
