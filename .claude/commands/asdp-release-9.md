Lee estos archivos antes de empezar:
- CLAUDE.md
- reports/iteration-close.md de la(s) iteración(es) incluidas en este release
- specs/design.md — sección "Decisiones de observabilidad" (define la estrategia
  de rollback de cada feature)
- .env.example — el contrato de configuración del proyecto

---

Actúa como un Agente de Release senior.

Tu objetivo es llevar el incremento a producción con verificación en cada paso y
plan de reversión definido ANTES de desplegar. Nada se declara liberado sin smoke
test contra producción real. Por cada punto entrega EVIDENCIA: comando + output
(Regla 4).

1. STAGING
- [ ] Migraciones pendientes aplicadas en staging sin error, y esquema resultante
      verificado contra specs/migrations/
- [ ] Variables de entorno de staging completas contra .env.example
- [ ] Suite completo de tests en verde contra staging
- [ ] Tests de integración (tests/integration/) en verde contra staging
- [ ] Si hay features LLM: subset de humo de specs/evals/ en verde contra staging

2. PLAN DE REVERSIÓN — antes del deploy, no después
- [ ] ¿Cómo se revierte este release? (feature flag, redeploy de la versión
      anterior, o migración de reversa) — documentado con los comandos exactos
- [ ] Si hay migraciones destructivas (DROP, cambio de tipo, NOT NULL sobre datos
      existentes): respaldo de base de datos tomado y verificado ANTES del deploy

3. PRODUCCIÓN
- [ ] Migraciones aplicadas en producción
- [ ] Deploy ejecutado
- [ ] Smoke test post-deploy: los flujos P0 de requirements.md ejecutados contra
      producción real, con evidencia
- [ ] Logs de producción sin errores nuevos en los primeros minutos post-deploy

Si el smoke test falla: ejecuta el plan de reversión INMEDIATAMENTE, documenta qué
falló, y aplica Regla 3 para determinar a qué fase retroceder. Un release revertido
no es un fracaso del proceso — un release roto en producción sí lo es.

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Evidencia pegada de cada punto de staging y producción
- [ ] Plan de reversión documentado con comandos exactos
- [ ] Smoke test post-deploy en verde
- [ ] reports/release-report.md generado

Agrega una entrada de Release en el MEMORY.md de cada iteración incluida
(schema de la Regla 5, Agente: Release).
Guarda en reports/release-report.md: fecha, iteraciones incluidas, evidencia,
plan de reversión, resultado del smoke test.
Escribe EXACTAMENTE al final:
---
FASE 9 COMPLETA. Release en producción.
Iteraciones incluidas: [lista].
Smoke test: [N] flujos P0 verificados.
Plan de reversión: [tipo] documentado.
Definition of Done verificada.
---
