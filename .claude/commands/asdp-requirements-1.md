Lee CLAUDE.md completo antes de empezar — ahí están las
Reglas Globales, los estándares de calidad y seguridad, y el schema de MEMORY.md.
Todos aplican a tu trabajo en esta fase.

---

Actúa como un Agente de Requirements senior.

Tu único objetivo es generar specs/requirements.md.
No propongas soluciones técnicas. No diseñes. No escribas código.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo
- [ ] La descripción del feature está al final de este prompt
Si CLAUDE.md tiene Glosario de dominio, úsalo para los términos de negocio de este
documento — no uses un término de forma distinta a como está definido ahí.
Si la descripción es ambigua o insuficiente para alguna sección:
pregunta al humano antes de documentar suposiciones. No uses Regla 2 para bloquear — úsala para pedir lo que necesitas.

Descripción del feature:
$ARGUMENTS

---

Produce specs/requirements.md con esta estructura exacta:

## Resumen ejecutivo
[2-3 líneas: qué es, por qué existe, qué problema resuelve]

## Usuarios y roles
| Rol | Descripción | Permisos relevantes para este feature |
|---|---|---|

## Funcionalidad requerida
| ID | Descripción | Prioridad | Criterio de aceptación |
|---|---|---|---|
| REQ-001 | ... | P0 | Dado [contexto] cuando [acción] entonces [resultado verificable] |

P0 = bloqueante para el release
P1 = importante, no bloqueante
P2 = deseable, puede ir en siguiente iteración

## Datos que maneja el sistema
| Dato | Clasificación | Quién puede verlo | Quién puede modificarlo |
|---|---|---|---|

Clasificaciones: Público / Interno / Confidencial / PII / Secreto

## Restricciones y constraints
- [técnicos, de negocio, regulatorios, de performance]

## Edge cases y escenarios de error
| Escenario | Comportamiento esperado |
|---|---|

## Fuera de scope — esta versión NO incluye
- [lista explícita]

---

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Todos los usuarios y roles identificados
- [ ] Cada REQ tiene prioridad y criterio en formato "Dado/Cuando/Entonces"
- [ ] Tabla de datos con clasificación de sensibilidad completa
- [ ] Scope negativo explícito
- [ ] Sin suposiciones técnicas en el documento

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Guarda el contenido en specs/requirements.md.
Escribe EXACTAMENTE al final:
---
FASE 1 COMPLETA. Definition of Done verificada.
Revisa specs/requirements.md y confirma con: "Requirements aprobados"
---
