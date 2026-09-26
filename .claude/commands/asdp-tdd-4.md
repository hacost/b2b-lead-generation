Lee estos archivos antes de empezar:
- CLAUDE.md — especialmente la Regla 1, crítica en esta fase: los tests que escribas
  son contratos permanentes.
- specs/design.md
- specs/migrations/
- specs/openapi.yaml
- specs/graph.md, specs/tools.md y specs/prompts/ si existen (features con agente LLM)
- specs/todo.md

---

Actúa como un Agente TDD senior.

Tu objetivo es escribir todos los tests antes de que exista implementación.
Los tests deben fallar porque el código que testean no existe aún.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo, especialmente la Regla 1
- [ ] specs/design.md, migrations/ y openapi.yaml aprobados (tienen los contratos de
      error, validaciones de input, y estados/transiciones)
- [ ] specs/todo.md aprobado (tiene los criterios de aceptación por task)
- [ ] Stack de testing en CLAUDE.md está definido

Stack de testing que usarás: [el que está en CLAUDE.md — ej. pytest 8 + pytest-asyncio + httpx]

RETROCESO POSIBLE DESDE ESTA FASE:
Si encuentras que un contrato de error o una interfaz no está definida en design.md/openapi.yaml
y no puedes escribir el test sin inventar el contrato: aplica Regla 3.
Documenta qué test no puedes escribir y qué falta en design.md.
Propón retroceder a Fase 2. Espera aprobación antes de continuar.

---

Para cada TASK en todo.md, escribe cuatro categorías de tests:

CATEGORÍA 1 — Tests de comportamiento (flujo feliz)
Un test por cada criterio de aceptación de la TASK.
Estructura AAA estricta: Arrange (setup) / Act (ejecutar) / Assert (verificar resultado).
Cada test verifica exactamente una cosa.
Sin lógica condicional (if / for / while) dentro del test.

CATEGORÍA 2 — Tests de contratos de error
Un test por cada rama de error de la TASK. La fuente del contrato de error es, en este
orden: specs/openapi.yaml si existe y la TASK toca un endpoint documentado ahí; si no,
la sección "Contratos de error del proyecto" de CLAUDE.md más lo que design.md haya
definido para este feature. Si ninguna fuente define un error que la TASK debería
manejar: aplica Regla 2 antes de inventar el contrato.
El test verifica tres cosas: (a) que se lanza la excepción correcta, (b) que el mensaje
es genérico al caller, (c) que no expone información interna del sistema.

Ejemplo de test de error bien escrito:
    def test_should_raise_not_found_when_user_does_not_exist():
        repo = FakeUserRepository(users=[])
        service = UserService(repo)
        with pytest.raises(UserNotFoundError) as exc_info:
            service.get_user(user_id=999)
        assert "internal" not in str(exc_info.value).lower()
        assert "database" not in str(exc_info.value).lower()

CATEGORÍA 3 — Tests de validación e inputs
Un test por cada validación de input definida en la TASK.
Escribe el caso que debe ser RECHAZADO y verifica que el rechazo ocurre por la razón correcta.
Incluye siempre los límites: valor mínimo, valor máximo, string vacío, None, lista vacía.
Para datos PII o sensibles según requirements.md: verifica que no aparecen
en mensajes de error ni en logs.

CATEGORÍA 4 — Tests de transiciones de estado
Solo si la TASK involucra una entidad con tabla de "Estados y transiciones" en design.md.
Un test por cada transición marcada como Prohibida: intenta ejecutarla y verifica que
el sistema la rechaza explícitamente (excepción o resultado de error, según el contrato).
Un test por cada transición marcada como Permitida: verifica que ocurre correctamente.

CATEGORÍA 5 — Tests de comportamiento no determinista (solo si la TASK invoca un LLM)
Un agente con LLM no da el mismo output exacto ante el mismo input — comparar texto
literal como en Categoría 1 no aplica aquí. Estos tests usan un LLM fake/mock con
respuestas fijas — NUNCA llaman al proveedor real (eso es territorio de specs/evals/,
que se corre en Fase 8, no en el suite de CI). Los contratos contra los que testeas
son specs/graph.md (ruteo del grafo: cada condición de edge tiene un test que verifica
que con ese estado se toma ese camino) y specs/tools.md (cada tool se invoca con el
schema correcto). Verifica estructura y hechos, no redacción:
- ¿El agente llamó a la herramienta/función correcta con los parámetros correctos?
- ¿La respuesta contiene el dato o entidad clave esperado, sin exigir redacción exacta?
- Si la TASK involucra recuperación de memoria: verifica que el dato correcto fue
  recuperado y usado, no cómo se redactó al presentarlo.
- Test de manejo de falla del proveedor del modelo: simula que la llamada al LLM falla
  o tarda — verifica que el sistema reintenta según la política definida en CLAUDE.md
  o falla de forma controlada, no que se cae silenciosamente.
- Si CLAUDE.md define un presupuesto de tokens/costo esperado por operación: test que
  verifique que una operación típica no lo excede.
Fuera de scope de esta categoría: evaluación de calidad subjetiva de respuestas.
Eso vive en specs/evals/ (generado en Fase 2, corrido en Fase 8 y ante cambios de
prompt) — no en el suite de tests, porque llama al proveedor real y no es determinista.

CATEGORÍA 6 — Tests de aislamiento multi-tenant (solo si el proyecto es multi-tenant)
Este es el contrato más importante de un sistema multi-tenant: los datos de un tenant
jamás son visibles ni modificables desde el contexto de otro. Por cada tabla o
colección nueva que este feature introduce, y por cada camino de lectura que expone
(query SQL, endpoint, búsqueda vectorial, recuperación de memoria):
- Test de lectura: con el contexto establecido en tenant A (ej. la variable de sesión
  o mecanismo que defina CLAUDE.md), una consulta que intentaría leer datos de
  tenant B devuelve vacío o error — nunca los datos.
- Test de escritura: con contexto de tenant A, un intento de UPDATE/DELETE sobre un
  registro de tenant B no afecta ninguna fila.
- Test de bypass por aplicación: el endpoint/caso de uso que recibe un ID de recurso
  de tenant B estando autenticado como tenant A responde como "no existe" (mismo
  contrato que un ID inexistente — no revela que el recurso existe en otro tenant).
- Si el feature incluye búsqueda vectorial o recuperación de memoria: test de que la
  recuperación con contexto de tenant A jamás devuelve documentos/vectores de tenant B,
  incluso cuando son los más similares semánticamente.
Estos tests corren contra una base de datos real (contenedor de test), no contra mocks —
el aislamiento por RLS/políticas solo puede verificarse en la base real.

Estándares de calidad de los tests — aplica a todos:
- Nombre: test_should_[comportamiento]_when_[condición] sin abreviaciones
- Un solo assert de comportamiento por test
- Mocks solo para dependencias externas reales: DB, APIs externas, filesystem, tiempo
- Cada test es independiente: no depende del estado que dejó otro test
- Sin prints ni logs dentro del test

Al terminar de escribir todos los tests:
1. Corre el suite completo
2. Verifica que TODOS los tests fallan
3. Si algún test pasa sin implementación: el test tiene un error, corrígelo ahora
4. Si algún test falla con algo distinto a ImportError / AttributeError / NotImplemented:
   el test asume algo que ya existe — revísalo

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Al menos un test por cada criterio de aceptación de cada TASK
- [ ] Al menos un test por cada rama de error identificada (openapi.yaml si existe, o CLAUDE.md/design.md si no)
- [ ] Al menos un test por cada validación de input/seguridad en todo.md
- [ ] Al menos un test por cada transición (permitida y prohibida) de las tablas de design.md
- [ ] Si alguna TASK invoca un LLM: tiene tests de Categoría 5 (estructura/hechos,
      manejo de fallo del proveedor, presupuesto de tokens si aplica) contra
      specs/graph.md y specs/tools.md, con LLM mockeado
- [ ] Si el proyecto es multi-tenant: cada tabla y camino de lectura nuevo tiene
      tests de Categoría 6 (lectura, escritura, bypass por aplicación, y vectorial
      si aplica)
- [ ] Todos los tests fallan por la razón correcta
- [ ] Sin lógica condicional en ningún test

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Guarda los tests en tests/.
Haz commit de tests/ con mensaje `test-contract: [feature]` — este commit es el
contrato que el check de tests inmutables usará en las Fases 5-7 (ver Prerrequisito).
Escribe EXACTAMENTE al final:
---
FASE 4 COMPLETA. [N] tests en [M] archivos. Todos en rojo.
Distribución: [X] comportamiento, [Y] errores, [Z] validaciones, [W] transiciones de
estado, [V] aislamiento multi-tenant (si aplica).
Commit de contrato: [hash].
Definition of Done verificada.
Confirma con: "Tests verificados, iniciar implementación"
---
