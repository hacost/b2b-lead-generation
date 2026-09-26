Lee CLAUDE.md completo antes de empezar — Reglas Globales, estándares de calidad
y seguridad, y el schema de MEMORY.md aplican íntegros también en esta vía.

---

Actúa como agente de la Vía Corta de ASDP-PROCESS.md (cambios de bajo riesgo).

ANTES DE EMPEZAR — verifica que TODOS estos criterios de entrada se cumplen, sin
"casi". Si UNO falla, detente y dilo explícitamente: este cambio debe pasar por
el proceso completo (`/asdp-requirements-1`), no por esta vía.
- [ ] No crea ni modifica tablas, columnas ni migraciones
- [ ] No crea ni modifica endpoints públicos (specs/openapi.yaml queda intacto)
- [ ] No toca prompts, graph.md, tools.md ni ningún comportamiento LLM
- [ ] No toca código de autenticación, autorización ni aislamiento multi-tenant
- [ ] Complejidad estimada S (menos de 2 horas de implementación)

Descripción del cambio:
$ARGUMENTS

Si la descripción es ambigua o insuficiente: pregunta al humano antes de asumir
(Regla 2 — úsala para pedir lo que necesitas, no para bloquear).

---

Sesión 1 — Mini-spec:
Produce `specs/iterations/[fecha]-[feature]/mini-spec.md` con:
- Qué cambia y por qué (2-3 líneas)
- Criterios de aceptación en formato Dado/Cuando/Entonces
- Archivos a tocar
- Contrato de error si aplica

Detente aquí y espera aprobación humana del mini-spec antes de continuar a la
Sesión 2.

---

Sesión 2 — Tests + implementación + cierre ligero (solo tras aprobación del mini-spec):

1. Tests primero, con los mismos estándares de Fase 4 (cuatro categorías: felices,
   error/validación, edge cases, y de aislamiento/seguridad si aplica). Todos en
   rojo. Haz commit `test-contract: [feature]` — desde ese commit esos tests son
   inmutables (Regla 1), igual que en el proceso completo.
2. Implementación con el checklist por función de Fase 5 (SOLID, límite de 20
   líneas, manejo explícito de errores, sin dead code, sin lógica de negocio fuera
   de dominio/aplicación).
3. Corre la suite COMPLETA del proyecto en verde + linter (ruff) limpio — la vía
   corta no exime la regresión sobre el resto del sistema.
4. Cierre ligero: verifica como Definition of Done los checklists de calidad y
   seguridad de CLAUDE.md que apliquen a este cambio — no hay sesiones de
   auditoría separadas. Corre `./scripts/check_immutable_tests.sh` contra el
   commit-contrato y pega el resultado.

Si a mitad de la Sesión 2 descubres que un criterio de entrada ya no se cumple
(ej. necesitas una columna nueva): detente y dilo — reinicia por el proceso
completo. Ese descubrimiento es la señal de que el cambio no era chico.

Al terminar:
- Entrada única en `specs/iterations/[fecha]-[feature]/MEMORY.md` (schema de la
  Regla 5 de CLAUDE.md).
- Línea en `specs/iterations/INDEX.md` marcada `[VÍA CORTA]`.

Escribe EXACTAMENTE al final:
---
VÍA CORTA COMPLETA. Definition of Done verificada.
Confirma con: "Vía corta aprobada"
---
