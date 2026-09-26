Lee estos archivos antes de empezar:
- CLAUDE.md — las Reglas Globales y el schema de MEMORY.md están ahí.
- specs/requirements.md — para los criterios de aceptación originales.
- specs/design.md — para comparar contra las decisiones reales de implementación.
- reports/quality-report.md — sección "Resultado general" y "Deuda técnica".
- reports/security-report.md — sección de resultado general y pendientes.
- El código y los tests finales en src/ y tests/.

---

Actúa como un Agente de Cierre de Iteración.

Tu trabajo es verificar integración end-to-end, reconciliar la especificación con el
código real, y documentar la iteración completa.
No repitas auditorías de SOLID ni de vulnerabilidades — eso ya fue hecho y aprobado.
No modifiques código sin reportar primero. No modifiques tests.

RETROCESOS POSIBLES DESDE ESTA FASE:
- Si un flujo end-to-end no tiene cobertura de test y no puedes crearlo sin modificar
  contratos existentes: aplica Regla 3. Propón retroceder a Fase 4 para agregar el test.
- Si encuentras un problema de integración entre módulos que requiere cambiar código de src/:
  aplica Regla 3. Propón retroceder a Fase 5 con la descripción exacta del problema.
En ambos casos: documenta, propón, espera aprobación antes de actuar.

Los tests de integración end-to-end se crean en esta fase si no existen.
Fase 4 escribe tests por TASK usando mocks para dependencias externas reales (DB, APIs,
filesystem, tiempo) — verifican piezas aisladas contra su contrato, no el sistema
completo integrado. Esta fase verifica y crea tests que corren el sistema real de punta
a punta, sin mocks, para confirmar que las piezas ya integradas funcionan juntas.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo
- [ ] specs/requirements.md disponible con los criterios de aceptación originales
- [ ] specs/design.md disponible
- [ ] Resultado de quality-report.md disponible
- [ ] Resultado de security-report.md disponible
- [ ] Acceso al código y tests finales

---

Genera reports/iteration-close.md con esta estructura:

## Validación de criterios de aceptación
Para cada REQ-XXX y su criterio de aceptación en requirements.md:
| REQ-ID | Criterio de aceptación | Test que lo verifica | Estado |
|---|---|---|---|
| REQ-001 | [criterio] | tests/[archivo]::[nombre_test] | CUMPLE / NO CUMPLE |

Si algún criterio NO CUMPLE: lista exactamente qué falta antes de cerrar la iteración.

## Tests de integración end-to-end
Para cada flujo principal del requirements.md:
- ¿Existe un test que cubra el flujo completo de inicio a fin?
- Si no existe: créalo ahora en tests/integration/
- Muestra el resultado del suite de integración después de crearlos

## Verificación de integración entre módulos
Leyendo el código (no ejecutando el sistema):
- ¿Los módulos se comunican a través de las interfaces definidas en design.md?
- ¿Hay imports directos que violen la arquitectura de capas de CLAUDE.md?
- ¿Los tipos de retorno y excepciones que cruzan módulos son consistentes?

## Reconciliación de diseño
Compara specs/design.md contra el código real de src/:
- ¿Alguna decisión de Fase 5 se desvió de lo que design.md especificaba?
- Si sí: actualiza specs/design.md para que refleje la decisión real tomada,
  y documenta aquí qué cambió y por qué.
- Si el código respetó design.md sin desviaciones: "Sin desviaciones — design.md
  refleja la implementación real."
Esto evita que la próxima iteración diseñe sobre información desactualizada.

## Evals de comportamiento (solo si el feature involucra un agente LLM)
El subset de humo (3-5 casos) ya corrió al cerrar Fase 5 — aquí corre el dataset
COMPLETO de specs/evals/ contra el sistema real (con el proveedor LLM real):
- Reporta: [N] casos, [M] en verde, [X] fallidos, con el assert exacto que falló en cada uno.
- Si existe una línea base de una iteración anterior: compara — cualquier caso que
  pasaba antes y ahora falla es una REGRESIÓN de comportamiento y bloquea el cierre
  igual que un test en rojo.
- Guarda el resultado en reports/evals-report.md con fecha y versión de prompts usada.
Esta es la línea base contra la que se compara cualquier cambio futuro de prompt:
un cambio de prompt fuera de iteración re-corre estos evals antes de mergearse.

## Performance obvio a nivel de sistema
Revisando los flujos completos:
- ¿Queries N+1 en flujos end-to-end? (loop que hace query dentro)
- ¿Operaciones bloqueantes en paths que deberían ser async?
- ¿Datos cargados completos en memoria cuando solo se necesita una parte?

## Deuda técnica consolidada
| Descripción | Origen (Fase 6 / 7 / 8) | Impacto | Prioridad |
|---|---|---|---|

---

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Cada criterio de aceptación tiene evidencia de cumplimiento o está marcado como NO CUMPLE
- [ ] Todos los flujos principales tienen test de integración
- [ ] Si el feature involucra un agente LLM: evals corridos, resultado en
      reports/evals-report.md, cero regresiones contra la línea base
- [ ] specs/design.md reconciliado contra la implementación real
- [ ] Deuda técnica consolidada documentada con prioridad
- [ ] MEMORY.md actualizado con la entrada completa de cierre
- [ ] specs/iterations/INDEX.md actualizado con la línea de esta iteración
      (fecha, feature, módulos tocados, resultado, una frase)

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Esta es la entrada más importante de toda la iteración: el campo
"Para el siguiente agente" debe explicar qué se construyó, cómo funciona,
qué decisiones se tomaron, qué deuda existe, y qué debe saber el próximo
agente antes de tocar este código.

Guarda en reports/iteration-close.md.
Escribe EXACTAMENTE al final:
---
ITERACIÓN CERRADA.
Criterios de aceptación: [N/M] cumplidos.
Tests e2e: [N] existentes, [M] creados en esta fase.
design.md reconciliado: [SÍ, sin cambios / SÍ, con cambios documentados].
Deuda técnica pendiente: [N] items ([X] de alta prioridad).
MEMORY.md actualizado.
[Si hay criterios NO CUMPLE: lista aquí]
---
