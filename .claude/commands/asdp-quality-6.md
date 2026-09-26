Lee estos archivos antes de empezar:
- CLAUDE.md — es la fuente de verdad de los estándares que auditas.
- specs/design.md
- El reporte de cobertura de Fase 5 (o vuelve a correrlo si no está guardado)
- src/ — empieza por los archivos de dominio.

---

Actúa como un Auditor de Calidad de Código senior.

Tu objetivo es verificar que el código cumple los estándares de CLAUDE.md.
No es para arreglar lo que debió hacerse bien — es para confirmar que se hizo bien
y detectar lo que no se hizo bien para activar el protocolo correcto.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo
- [ ] specs/design.md está disponible como referencia de lo que debía implementarse
- [ ] El reporte de cobertura de Fase 5 está disponible
- [ ] El código de src/ está disponible para leer

Reglas absolutas en esta fase:
- No modifiques tests (Regla 1 de CLAUDE.md)
- No cambies decisiones de arquitectura — eso requiere retroceder a Fase 2
- Si encuentras violaciones que vienen del diseño, no de la implementación:
  aplica Regla 3 — documenta, propón retroceso, espera aprobación

---

Genera reports/quality-report.md con esta estructura:

## Resultado general
[APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO]
Si RECHAZADO: especifica a qué fase retroceder y qué corregir específicamente.

## Cobertura
- Cobertura actual: [X]%
- Umbral requerido en CLAUDE.md: [Y]%
- Estado: CUMPLE / NO CUMPLE
- Módulos por debajo del umbral: [lista con % actual de cada uno]

## Auditoría SOLID
Para cada violación encontrada:
| Principio | Archivo:Línea | Código problemático | Por qué viola | Corrección exacta | Impacto |
|---|---|---|---|---|---|
Si no hay violaciones: "Sin violaciones de SOLID detectadas."

## Auditoría de patrones de diseño
| Patrón en CLAUDE.md | Estado | Problemas encontrados | Corrección |
|---|---|---|---|

## Auditoría de estándares de código
Para cada violación de las reglas de calidad de CLAUDE.md:
| Regla violada | Archivo:Línea | Violación concreta | Corrección |
|---|---|---|---|

## Acoplamiento y cohesión
| Módulo A | Depende de | Módulo B | Problema | Solución |
|---|---|---|---|---|
Si no hay problemas: "Acoplamiento adecuado."

## Cumplimiento del design aprobado
| Decisión en design.md | Cómo fue implementado | Estado |
|---|---|---|

## Deuda técnica
| Descripción | Intencional / Accidental | Impacto si no se atiende | Prioridad |
|---|---|---|---|

---

Correcciones:
- Impacto ALTO (viola estándares de CLAUDE.md): aplica directamente.
  Después de cada corrección corre el suite de tests completo.
  Si un test falla después de tu corrección: no lo modifiques.
  Documenta cuál falló y por qué — escala al humano.
- Impacto MEDIO y BAJO: lista en el reporte y espera aprobación del humano.

RETROCESOS POSIBLES DESDE ESTA FASE:
- Si las violaciones vienen de la implementación (Fase 5 no cumplió CLAUDE.md):
  Resultado: RECHAZADO. Propón retroceder a Fase 5.
  El agente de Fase 5 recibirá este quality-report.md como input adicional.
- Si las violaciones vienen del diseño (el problema está en design.md, no en cómo se implementó):
  Resultado: RECHAZADO. Propón retroceder a Fase 2.
  Documenta exactamente qué decisión de diseño causó la violación.
En ambos casos: aplica Regla 3 — documenta, propón, espera aprobación. No continues.

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Las 5 categorías auditadas y documentadas con resultado explícito
- [ ] Cobertura verificada contra el umbral de CLAUDE.md
- [ ] Resultado APROBADO / OBSERVACIONES / RECHAZADO con evidencia concreta
- [ ] Si hubo correcciones de impacto alto: suite de tests corrido y en verde

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Guarda en reports/quality-report.md.
Escribe EXACTAMENTE al final:
---
FASE 6 COMPLETA. Resultado: [APROBADO / OBSERVACIONES / RECHAZADO].
Cobertura: [X]% ([CUMPLE / NO CUMPLE]).
Violaciones SOLID: [N]. Aplicadas: [M]. Pendientes aprobación: [P].
Definition of Done verificada.
Confirma con: "Calidad aprobada, iniciar auditoría de seguridad"
---
