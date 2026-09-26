Lee estos archivos antes de empezar:
- CLAUDE.md — la Regla 1 aplica aquí: no modifiques tests. La Regla 2 aplica aquí: no improvises.
- specs/design.md
- specs/migrations/
- specs/openapi.yaml
- specs/graph.md, specs/tools.md y specs/prompts/ si existen (features con agente LLM).
  Los prompts de specs/prompts/ se COPIAN a src/ tal cual — no los reescribas, no los
  "mejores". Un prompt es un contrato de Fase 2, igual que openapi.yaml. Si crees que
  un prompt está mal: aplica Regla 3, propón retroceder a Fase 2.
- specs/todo.md
- specs/iterations/INDEX.md y de ahí el MEMORY.md de las iteraciones anteriores que
  tocaron este módulo, si existen. Si no existen, es primera iteración — sin historial previo.

---

Actúa como un Agente de Implementación senior.

Implementa el código en src/ dentro de la ruta del proyecto.
Lee la estructura de carpetas existente antes de empezar para respetar lo que ya existe.

Tu objetivo es escribir el código para que TODOS los tests pasen — los que Fase 4
escribió para las TASKs de este feature, Y los de features anteriores del proyecto
(regresión: no debes romper lo que ya funcionaba).
El código debe cumplir los estándares de CLAUDE.md desde la primera línea.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo
- [ ] specs/design.md, migrations/ y openapi.yaml aprobados
- [ ] specs/todo.md aprobado
- [ ] Los tests en tests/ fueron aprobados por el humano y están todos en rojo
- [ ] Leíste el MEMORY.md de iteraciones anteriores si existe

RETROCESOS POSIBLES DESDE ESTA FASE:
- Si el diseño es incorrecto o incompleto: aplica Regla 3.
  Documenta qué parte de design.md/migrations/openapi.yaml es incorrecta y qué impacto
  tiene en la implementación.
  Propón retroceder a Fase 2. Espera aprobación antes de continuar. No improvises.
- Si un test parece mal escrito e impide implementar correctamente: aplica Regla 1.
  Documenta cuál test, por qué parece incorrecto, y qué comportamiento esperarías.
  Propón retroceder a Fase 4. Espera aprobación. No modifiques el test por tu cuenta.

---

Implementa en el orden del "Orden de implementación" de todo.md.

Para cada función que implementes, ejecuta este checklist ANTES de pasar a la siguiente:
- [ ] SOLID-S: esta función tiene exactamente una responsabilidad
- [ ] SOLID-D: las dependencias son hacia abstracciones, no implementaciones concretas
- [ ] Nombre expresa intención (sin data, tmp, aux, result)
- [ ] Máximo 20 líneas. Si supera: dividir ahora, no después.
- [ ] Input validado antes de usarse según openapi.yaml
- [ ] Manejo de errores explícito según el contrato de error aplicable (openapi.yaml si
      existe para este endpoint, si no CLAUDE.md/design.md)
- [ ] Sin secret ni dato sensible en código ni en mensajes de log
- [ ] Mensajes de error al cliente son genéricos

Flujo de implementación — sigue este orden estrictamente:
1. Lee el test fallido más simple (el de menor dependencia)
2. Implementa el mínimo código para pasarlo, cumpliendo el checklist
3. Corre los tests afectados: los de la TASK actual más los últimos fallidos
   (ej. `pytest --lf` o el marker del módulo) — el suite completo en cada micro-paso
   no escala cuando el proyecto crece
4. Al cerrar cada TASK: corre el suite COMPLETO — todos los tests anteriores deben
   seguir en verde. Si algún test anterior falla: tienes acoplamiento — corrígelo
   antes de continuar
5. Refactoriza si es necesario sin romper tests
6. Marca [x] la TASK en specs/todo.md cuando todos sus tests pasan
7. Pasa al siguiente test

Si durante la implementación descubres un edge case que NINGÚN test cubre:
- NO modifiques tests existentes (Regla 1).
- Escribe el caso en un ARCHIVO NUEVO dentro de tests/ (el check de tests inmutables
  permite archivos nuevos — estado A en git — y rechaza modificaciones o borrados).
- Documenta en MEMORY.md qué cubre y por qué no estaba, y repórtalo en tu output final.

Al terminar:
- Corre el suite completo y muestra el output completo
- Corre el linter y muestra el output completo
- Corre el reporte de cobertura y muestra el porcentaje por módulo
- Si el feature involucra un agente LLM: corre el subset de humo de specs/evals/
  (los 3-5 casos marcados como "smoke") contra el proveedor real. Si alguno falla:
  aplica Regla 3 — la causa probable es el prompt o el grafo (Fase 2), no el código.
  No cierres la fase con el humo en rojo.

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Todos los tests en verde
- [ ] Cero tests MODIFICADOS ni eliminados respecto a los aprobados en Fase 4 —
      verifícalo mecánicamente: corre
      `git diff --diff-filter=MD --stat [commit test-contract] -- tests/`
      y pega el output. Debe estar vacío. Si no lo está, la fase está RECHAZADA.
- [ ] Archivos de test NUEVOS agregados (si los hay): listados aquí, cada uno con su
      justificación en MEMORY.md
- [ ] Si el feature involucra LLM: subset de humo de evals en verde (evidencia pegada)
- [ ] Cobertura >= umbral definido en CLAUDE.md
- [ ] Linter: cero warnings, cero errores
- [ ] Todas las TASKs marcadas [x] en specs/todo.md

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Escribe EXACTAMENTE al final:
---
FASE 5 COMPLETA. [N] tests en verde. Cobertura: [X]%. Linter: OK.
Definition of Done verificada.
Confirma con: "Implementación aprobada, iniciar auditoría de calidad"
---
