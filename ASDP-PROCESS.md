# ASDP — Agent-Driven Spec Development Process — v10

> Proceso para construir software de producción con agentes de IA, operado en Claude Code (VS Code).
> Basado en TDD (Kent Beck), Specification by Example (Adzic), SOLID (Robert Martin).

## Por qué este proceso existe

Pedirle a un agente "hazme una API" produce un prototipo.
Este proceso produce software mantenible, testeable, seguro y predecible.

La secuencia tiene dependencias estrictas:

- No puedes diseñar bien lo que no está definido como requisito.
- No puedes escribir tests de algo sin diseño.
- No puedes implementar sin tests que definan el contrato.
- No puedes auditar calidad de código que todavía va a cambiar.
- No puedes auditar seguridad de código que no pasó calidad.

---

## Prerrequisito

El proyecto debe estar bajo control de versiones (git) antes de correr este proceso.
Tests inmutables, reconciliación de design.md, y retrocesos asumen que puedes revertir
cambios si algo sale mal — sin git, esas protecciones no tienen red de seguridad real.

### Enforcement mecánico de la Regla 1 (tests inmutables)

La Regla 1 como instrucción al agente no basta: bajo presión de "hacer pasar los tests",
los agentes de código modifican tests — es su modo de falla más documentado. La regla
se refuerza con mecanismos que el agente no puede desobedecer:

1. Al cerrar Fase 4, haz commit de tests/ con un mensaje identificable
   (ej. `test-contract: [feature]`). Ese commit es el contrato.
2. Un check automático (pre-commit hook o job de CI — se configura en Fase 0) falla
   si un diff MODIFICA o BORRA archivos dentro de tests/. La forma más simple:
   `git diff --diff-filter=MD --stat [commit-contrato] -- tests/` debe salir vacío
   al final de las Fases 5, 6 y 7.
3. Los agentes de Fases 5-7 corren esa verificación como parte de su Definition of Done
   y pegan el output. Si el diff no está vacío: la fase está RECHAZADA automáticamente,
   sin importar que los tests estén en verde.
   Excepciones — solo AGREGAR (estado A en git), nunca modificar ni borrar (M/D):

- Fase 5 puede agregar archivos NUEVOS en tests/ para edge cases descubiertos durante
  la implementación, cada uno documentado en MEMORY.md (qué cubre y por qué no estaba).
  Fundamento: el TDD de Beck es un ciclo de aprendizaje — implementar revela casos que
  el diseño no vio; prohibir capturarlos pierde ese aprendizaje. Modificar sigue prohibido.
- Fase 8 puede agregar archivos nuevos en tests/integration/.
  En Fases 6 y 7 el diff completo contra el commit-contrato debe salir vacío — esas
  fases auditan, no agregan tests.

---

## Arranque de un proyecto nuevo — del cero a la primera iteración

Paso 1 — Prepara el repo (manual, ~10 minutos).
Crea la carpeta del proyecto, corre `git init`, copia este documento como
ASDP-PROCESS.md en la raíz, abre la carpeta en VS Code y arranca Claude Code dentro
de ella. Es lo único del proceso que se hace a mano.

Paso 2 — Fase -1 (Contexto).
Pega el prompt del Agente de Contexto con la descripción del sistema a construir.
Revisa las decisiones estructurales UNA POR UNA y cierra con "Contexto aprobado" →
"CLAUDE.md aprobado". Es la sesión donde más vale tu criterio — no la corras con prisa.

Paso 3 — Fase 0 (Bootstrap).
`/clear` y pega el prompt del Agente de Bootstrap. Monta git hooks, CI,
docker-compose, migración cero, el rol sin BYPASSRLS y los slash commands del
proceso. Verificas la tabla de evidencia → "Bootstrap aprobado".

A partir de aquí, toda iteración inicia en Fase 1 (`/asdp-fase-1 [descripción del
feature]`). Recomendación para la primera iteración: el cimiento — tenant + auth +
primera entidad de negocio — antes que cualquier módulo funcional, porque los tests
de Categoría 6 necesitan el aislamiento existiendo desde la primera tabla.

---

## Cómo funciona el contexto entre fases

No hay historial de conversación entre fases. El contexto viaja en archivos.
Cada fase produce documentos. La siguiente los recibe como input.

```
Fase -1 → CLAUDE.md (una sola vez por proyecto, vía Agente de Contexto; se actualiza
          cuando cambian estándares)
Fase 0  → entorno funcional (una sola vez por proyecto, después de Fase -1 — el
          bootstrap configura el stack que CLAUDE.md decide)
Fase 1 → specs/requirements.md
Fase 2 → specs/design.md + [migrations/ si aplica] + [openapi.yaml si aplica]
         + [graph.md + prompts/ + tools.md + evals/ si el feature involucra un agente LLM]
         recibe: requirements.md + iterations/INDEX.md
Fase 3 → specs/todo.md            recibe: requirements.md + design.md + lo que Fase 2 haya producido
Fase 4 → tests/                   recibe: design.md + todo.md + lo que Fase 2 haya producido
Fase 5 → src/                     recibe: design.md + todo.md + tests/ + lo que Fase 2 haya producido
Fase 6 → reports/quality-report.md  recibe: design.md + src/ + cobertura
Fase 7 → reports/security-report.md recibe: requirements.md + src/
Fase 8 → reports/iteration-close.md recibe: requirements.md + los 3 reports
         (+ corre specs/evals/ si el feature involucra un agente LLM)
Fase 9 → reports/release-report.md  recibe: reports/iteration-close.md — corre solo
         cuando un incremento sube a producción (una o varias iteraciones por release)
```

"Si aplica" significa: solo cuando el feature persiste datos propios (migrations/),
expone endpoints propios (openapi.yaml), o involucra un agente/feature con LLM
(graph.md, prompts/, tools.md, evals/) — ver Fase 2 para el criterio completo.

MEMORY.md se actualiza en cada fase y vive en specs/iterations/[fecha]-[feature]/MEMORY.md
Tiene una entrada por fase en el camino normal (8 en total), más una entrada adicional
por cada retroceso, y una entrada de Release cuando la Fase 9 libera esa iteración a
producción. Se lee en Fase 2 y en cualquier retroceso.
CLAUDE.md es la fuente de verdad del proyecto — todos los agentes lo leen al inicio de cada fase.

---

## Cómo iniciar cada fase

Cada fase se ejecuta en una sesión nueva de Claude Code, sin historial de la fase anterior.
Esto evita que el agente arrastre razonamientos, caminos descartados o supuestos de una fase
a otra — cada fase debe partir solo de lo que está escrito en los archivos, no de lo que
"recuerda" haber discutido antes.

Al terminar una fase y antes de iniciar la siguiente:

1. Verifica que los archivos de salida de la fase existen y los revisaste.
2. Corre `/clear` en Claude Code para resetear el contexto de la conversación.
3. Invoca el slash command de la siguiente fase (o pega su prompt, si no instalaste
   los comandos — ver la subsección siguiente).

### Los prompts como slash commands (la forma recomendada de operar en Claude Code)

Copiar y pegar cada prompt, llenando [ruta] y [PEGA AQUÍ...] a mano, es fricción y
fuente de error en cada sesión. Claude Code soporta comandos personalizados: archivos
markdown dentro de `.claude/commands/` en la raíz del proyecto, que se invocan con
`/nombre-del-archivo`.

Instalación (parte del checklist de Fase 0):

1. Crea `.claude/commands/` en la raíz del proyecto.
2. Crea un archivo por fase con el prompt de este documento tal cual:
   `asdp-contexto.md` (Fase -1), `asdp-bootstrap.md` (Fase 0), `asdp-fase-1.md` …
   `asdp-fase-9.md`, y `asdp-via-corta.md`.
3. Donde el prompt dice [PEGA AQUÍ LA DESCRIPCIÓN...], sustituye por `$ARGUMENTS` —
   Claude Code inserta ahí lo que escribas después del comando.
4. La línea "El proyecto está en [ruta]" se elimina de los comandos: la sesión ya
   vive dentro del proyecto.

Uso: `/asdp-fase-1 el usuario puede registrar un pago semanal contra un crédito activo`

Ventajas verificables: cero copy-paste, prompts versionados en el repo junto al código
(iterar el proceso = un commit), y la ruta nunca se llena a mano. Nota: Claude Code
carga CLAUDE.md automáticamente al inicio de cada sesión; la instrucción "lee CLAUDE.md
completo" se mantiene en los prompts como refuerzo explícito, no como único mecanismo.

Claude Code tiene acceso directo al filesystem del proyecto — no se pega contenido de
archivos dentro de los prompts. Cada prompt le indica al agente qué archivos leer, y el
agente los abre él mismo. 

Cada fase lee CLAUDE.md completo siempre, más solo los archivos de referencia que le
apliquen a esa fase específica — no todos los archivos de referencia que existan en el
proyecto. Mientras más contenido innecesario cargue el agente, peor razona, incluso
antes de llegar a un límite técnico de contexto. Por eso CLAUDE.md se mantiene enfocado
en lo que ningún agente puede adivinar por sí mismo (ver Fase -1); cualquier detalle
extenso y específico de un módulo o tema va en un archivo de referencia aparte, dentro
de docs/, y solo se referencia en el prompt de la fase que realmente lo necesita.

---

## Qué modelo usar

| Tarea                                                                      | Modelo |
| -------------------------------------------------------------------------- | ------ |
| Verificaciones mecánicas, pre-checks                                       | Haiku  |
| Todas las fases de este proceso                                            | Sonnet |
| Decisiones de arquitectura con tradeoffs complejos donde Sonnet no alcanza | Opus   |

Regla: usa el más barato que resuelve bien la tarea.

---

## Vía corta — cambios de bajo riesgo

El proceso completo aplica la misma profundidad a un feature de 2 semanas y a un
cambio de 2 horas. Esa fricción es la forma #1 en que los procesos rigurosos mueren:
el operador empieza a saltárselos "solo por esta vez". La vía corta existe para que
el atajo esté DENTRO del proceso, con reglas, y no fuera de él, sin ninguna.
Fundamento: la profundidad de verificación se dimensiona al riesgo del cambio, no se
aplica uniforme (gestión de riesgo en testing, ISTQB).

### Criterios de entrada — TODOS deben cumplirse, sin "casi"

- [ ] No crea ni modifica tablas, columnas ni migraciones
- [ ] No crea ni modifica endpoints públicos (specs/openapi.yaml queda intacto)
- [ ] No toca prompts, graph.md, tools.md ni ningún comportamiento LLM
- [ ] No toca código de autenticación, autorización ni aislamiento multi-tenant
- [ ] Complejidad estimada S (menos de 2 horas de implementación)

Si UNO falla → proceso completo. Los criterios son binarios a propósito: si la
elegibilidad queda a criterio del momento, la vía corta se convierte en la puerta
para saltarse todo.

### La ruta reducida (2 sesiones en vez de 8)

Sesión 1 — Mini-spec:
Produce specs/iterations/[fecha]-[feature]/mini-spec.md con: qué cambia y por qué
(2-3 líneas), criterios de aceptación en formato Dado/Cuando/Entonces, archivos a
tocar, y contrato de error si aplica. Sustituye a las Fases 1-3. El humano lo
aprueba antes de continuar.

Sesión 2 — Tests + implementación + cierre ligero:

1. Tests primero (estándares de Fase 4), todos en rojo, commit `test-contract` —
   la Regla 1 aplica íntegra: esos tests son inmutables desde ese commit.
2. Implementación con el checklist por función de Fase 5.
3. Suite COMPLETO del proyecto en verde + linter limpio (la vía corta no exime
   la regresión).
4. Cierre ligero: los checklists de calidad (CLAUDE.md) y seguridad aplicables se
   verifican como Definition of Done dentro de esta sesión — no hay sesiones de
   auditoría separadas. Entrada única en MEMORY.md y línea en INDEX.md marcada
   como [VÍA CORTA].

Las Reglas Globales aplican completas (tests inmutables, sin improvisación,
retrocesos). Si a mitad de la vía corta descubres que un criterio de entrada ya no
se cumple (ej. necesitas una columna nueva): detente y reinicia por el proceso
completo — ese descubrimiento es la señal de que el cambio no era chico.

---

## Estructura de archivos

```
proyecto/
├── CLAUDE.md                      ← Todo lo que todos los agentes necesitan saber
├── ASDP-PROCESS.md                 ← Este archivo
├── specs/
│   ├── requirements.md
│   ├── design.md
│   ├── migrations/                ← Contrato de datos ejecutable/validable
│   ├── openapi.yaml               ← Contrato de API ejecutable/validable
│   ├── graph.md                   ← Contrato del grafo del agente (solo features con LLM)
│   ├── prompts/                   ← System prompts versionados (solo features con LLM)
│   ├── tools.md                   ← Contrato de cada tool del agente (solo features con LLM)
│   ├── evals/                     ← Dataset dorado + asserts estructurales (solo features con LLM)
│   ├── todo.md
│   └── iterations/                ← Un MEMORY.md por iteración, no uno global
│       ├── INDEX.md               ← Una línea por iteración: fecha, feature, módulos tocados, resultado
│       ├── 2026-06-23-nombre-feature/
│       │   └── MEMORY.md          ← Entradas de esa iteración (8 en el camino normal)
│       └── 2026-07-01-otro-feature/
│           └── MEMORY.md
├── tests/                         ← Inmutables después de Fase 4
├── src/
└── reports/
    ├── quality-report.md
    ├── security-report.md
    ├── iteration-close.md
    └── release-report.md          ← Solo cuando un incremento sube a producción (Fase 9)
```

Cada MEMORY.md tiene una entrada por fase en el camino normal (8 en total), más una
entrada adicional por cada retroceso, y una entrada de Release cuando la Fase 9
libera esa iteración a producción.
Cuando necesitas contexto de una iteración anterior, lees el MEMORY.md de esa carpeta — no un archivo infinito.
El nombre de la carpeta te dice qué feature construyó esa iteración.

specs/iterations/INDEX.md existe porque a partir de ~10 iteraciones, "lee el MEMORY.md
de la iteración anterior que tocó este módulo" requiere adivinar cuál fue. El INDEX.md
tiene exactamente una línea por iteración:
`[fecha] | [feature] | [módulos tocados] | [COMPLETADO/RECHAZADO] | [una frase de resultado]`
Fase 2 lo lee primero para ubicar qué MEMORY.md abrir. Fase 8 agrega la línea de la
iteración que cierra. Nada más va en este archivo.

---

## FASE -1 — Contexto: CLAUDE.md propuesto por agente (una sola vez por proyecto)

Crea este archivo antes de cualquier otra cosa.
Es el único documento que todos los agentes reciben en todos los prompts.
Lo que no está en CLAUDE.md no existe como estándar del proyecto.

Mantén CLAUDE.md enfocado en lo que ningún agente puede adivinar por sí mismo:reglas, stack, arquitectura, estándares. No es el lugar para documentación extensa de un módulo específico, guías de uso de una librería, o contenido que solo aplica a una fase o feature puntual — eso va en un archivo de referencia aparte dentro de docs/, y se referencia solo en el prompt de la fase que lo necesita (ver "Cómo iniciar cada
fase"). Mientras más contenido acumula CLAUDE.md, peor razonan los agentes que lo leen completo en cada una de las 8 fases.

### El CLAUDE.md lo propone un agente — tú lo apruebas decisión por decisión

El resto del proceso ya funciona así: el agente produce, el humano aprueba. Esta fase no es la excepción — no llenes el template a mano. Pero el CLAUDE.md mal decidido es el error más caro del proceso, porque lo heredan todas las fases de todas las iteraciones. Por eso la propuesta NO llega como documento cerrado para aceptar de
golpe: llega como decisiones estructurales separadas, en el mismo formato ADL de la Fase 2, que apruebas, rechazas o modificas una por una. Delegas la generación; el juicio no.

### Prompt del Agente de Contexto — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta] (o va a crearse ahí). Lee ASDP-PROCESS.md — la tabla
"Alcance del proceso" define qué artefactos exige cada tipo de proyecto.

Actúa como un Agente de Contexto senior.

Voy a construir el siguiente sistema:
[DESCRIBE: qué hace, quién lo usa, tipo según la tabla de alcance (API / agente LLM /
cliente web / cliente móvil / librería / worker), si es multi-tenant, y las
restricciones que ya conozcas]

Si existe un template de fábrica para este tipo de proyecto, está en: [ruta o "no existe"]

Tu objetivo NO es generar CLAUDE.md todavía. Primero produce
specs/context-proposal.md con las decisiones estructurales del proyecto, cada una
en este formato (el mismo ADL de la Fase 2):

### DECISIÓN-[N]: [nombre]
- Contexto: [por qué este sistema obliga a decidir esto]
- Opciones: [2-3 alternativas reales, una línea de tradeoff cada una]
- Recomendación: [cuál y por qué, en términos de los requisitos que te di]
- Consecuencias: [qué implica para el resto del sistema]

Decisiones mínimas que debes proponer (agrega las que el tipo de proyecto exija):
1. Lenguaje, versión y framework
2. Base de datos y ORM (o su ausencia, justificada)
3. Patrón de arquitectura y capas
4. Autenticación y autorización
5. Mecanismo de aislamiento multi-tenant (si aplica)
6. Stack de testing, linter y package manager
7. Contratos de error del proyecto
8. Si involucra LLM: proveedor(es), política de reintentos, presupuesto de tokens

Si te di un template de fábrica: parte de sus decisiones como base y propón SOLO los
deltas — qué mantienes tal cual, qué cambias y por qué.

Regla 2 aplica: si mi descripción no alcanza para recomendar una decisión, pregunta —
no rellenes con suposiciones.

Espera mi respuesta decisión por decisión: "DECISIÓN-N aprobada", "DECISIÓN-N:
cámbiala a [X]", o "DECISIÓN-N rechazada, propón otra opción".
NO generes CLAUDE.md hasta que yo escriba: "Contexto aprobado".

Cuando reciba "Contexto aprobado": genera CLAUDE.md completo con el template de
ASDP-PROCESS.md, llenando cada campo con las decisiones aprobadas — sin agregar decisiones nuevas que no pasaron por la propuesta.
Escribe EXACTAMENTE al final:
---
FASE -1 COMPLETA. CLAUDE.md generado con [N] decisiones aprobadas.
Revisa CLAUDE.md y confirma con: "CLAUDE.md aprobado"
---
```

### Si el proyecto ya existe (no parte de cero)

Los campos de abajo (Stack, Arquitectura, Patrones de diseño) deben describir lo que el código YA hace, no una decisión nueva ni un objetivo deseado. Antes de llenarlos:

1. Abre una sesión de Claude Code y dile: "El proyecto está en [ruta]. Lee la estructura completa de src/ y los archivos de configuración/dependencias.
   Repórtame: lenguaje y versión, framework(s), base de datos si existe, patrón de arquitectura real que sigue el código (aunque sea inconsistente), y cualquier convención que detectes ya en uso."
2. Revisa ese reporte tú mismo — el agente puede malinterpretar código legacy o
   inconsistente. Corrige lo que no sea preciso.
3. Llena CLAUDE.md con esa realidad verificada, no con la arquitectura ideal que te
   gustaría tener. Si algo del código actual viola lo que pondrías como estándar
   (ej. no hay separación de capas), decide explícitamente: ¿el estándar nuevo aplica
   solo a código nuevo, o vas a exigir refactor progresivo? Documenta esa decisión en
   CLAUDE.md para que los agentes de las 8 fases sepan qué esperar del código existente.

Si el proyecto parte de cero, omite esta subsección y llena los campos como decisiones
nuevas normalmente.

```
# CLAUDE.md — [NOMBRE DEL PROYECTO]
Versión: [X.X] | Fecha: [YYYY-MM-DD]

---

## REGLAS GLOBALES DEL PROCESO

Estas reglas aplican a todos los agentes sin excepción.

### Regla 1 — Tests inmutables
Los tests escritos en Fase 4 son contratos permanentes de comportamiento del sistema.
Ningún agente puede modificar, eliminar, comentar, ni hacer pasar un test
cambiando el test en lugar del código que testea.
Agregar archivos de test NUEVOS solo está permitido donde el proceso lo autoriza
explícitamente (Fase 5 en tests/, Fase 8 en tests/integration/) — modificar o
eliminar existentes, nunca.
Si un test parece incorrecto: detente, documenta el problema en tu output,
espera instrucción humana antes de continuar.

### Regla 2 — Sin improvisación
Si durante tu fase encuentras algo no definido en los documentos de input:
no lo inventes ni asumas. Detente, documenta qué falta y por qué lo necesitas,
espera instrucción humana antes de continuar.

### Regla 3 — Protocolo de retroceso
Si detectas un error que proviene de una fase anterior:
1. Documenta: qué fase lo produjo, qué produjo mal, qué impacto tiene.
2. Propón: a qué fase retroceder y qué corregir específicamente.
3. Espera: aprobación humana antes de continuar o retroceder.
No corrijas silenciosamente errores de fases anteriores.

### Regla 4 — Cada fase escribe sus outputs
Cada fase produce archivos concretos antes de declararse completa.
El humano verifica esos archivos, no las palabras del agente.

### Regla 5 — MEMORY.md tiene schema fijo
Cada iteración tiene su propio MEMORY.md en specs/iterations/[fecha]-[nombre-feature]/MEMORY.md
Cuando actualices MEMORY.md, usa exactamente este formato.
No agregues secciones. No omitas secciones. El orden es fijo.

### [YYYY-MM-DD] — Fase [N] — [Nombre del feature]
**Agente:** [Requirements / Design / Tasks / TDD / Implementation / Quality / Security / Cierre / Release]
**Resultado:** [COMPLETADO / COMPLETADO CON OBSERVACIONES / RECHAZADO / ESCALADO]
**Produjo:**
- [archivo o output concreto generado]
**Decisiones tomadas:**
- [decisión]: [justificación en una línea]
**Problemas encontrados:**
- [problema]: [cómo se resolvió o por qué se escaló]
**Deuda técnica:**
- [descripción]: [impacto si no se atiende]
**Para el siguiente agente:**
- [contexto crítico que el próximo agente necesita saber]

---

## Stack tecnológico
- Lenguaje y versión: [ej. Python 3.12]
- Framework: [ej. FastAPI 0.111]
- Base de datos: [ej. PostgreSQL 16]
- ORM: [ej. SQLAlchemy 2.0 async]
- Testing: [ej. pytest 8 + pytest-asyncio + httpx]
- Package manager: [ej. uv]
- Linter: [ej. ruff]

## Arquitectura
- Patrón: [ej. Clean Architecture]
- Capas: [ej. domain → application → infrastructure → api]
- Regla de dependencias: [ej. las capas internas no conocen las externas]
- Estructura: [ej. feature-based dentro de cada capa]

## Glosario de dominio
Solo términos de negocio que se prestan a confusión o ambigüedad en este proyecto —
no una definición de cada palabra. Llénalo con lo que aplique a tu dominio.
| Término | Definición | Por qué se presta a confusión |
|---|---|---|
| [ej. colegiatura] | [ej. pago periódico de escolaridad] | [ej. se confunde con "factura", que es el comprobante fiscal, no el pago en sí] |
Si el dominio del proyecto no tiene términos ambiguos, deja la tabla vacía o con una nota: "Sin términos ambiguos identificados."

## Estándares de calidad — todos los agentes los aplican

### SOLID — criterios verificables
- S (SRP): Una función/clase = una razón para cambiar.
  Señal de violación: el nombre usa "and", o la función hace más de una cosa.
- O (OCP): Agregar comportamiento no requiere modificar código existente.
  Señal de violación: if-elif que crece cada vez que se agrega un tipo nuevo.
- L (LSP): Las subclases reemplazan a sus bases sin cambiar el comportamiento del sistema.
  Señal de violación: subclase lanza excepciones que la base no lanza.
- I (ISP): Interfaces específicas, no generales.
  Señal de violación: clase que implementa interfaz pero deja métodos con pass.
- D (DIP): Depender de abstracciones, no de implementaciones concretas.
  Señal de violación: import directo de clase concreta de infraestructura desde dominio.

### Calidad de código — criterios verificables
- Funciones: máximo 20 líneas. Si supera: dividir antes de continuar.
  Excepciones: solo las documentadas explícitamente en este archivo, con justificación.
  (Ejemplo típico: la función declarativa que construye un grafo de agente —
  add_node/add_edge — o una tabla de configuración; dividirla empeora la lectura.
  El auditor de Fase 6 respeta las excepciones aquí documentadas y rechaza las que no.)
- Nombres: expresan intención. Prohibido: data, tmp, aux, result, obj, x, temp.
- Comentarios: explican el "por qué". El código explica el "qué".
- Errores: manejo explícito. Prohibido: bare except, pass en except, swallow errors.
- Dead code: prohibido. Sin funciones, variables, o imports sin usar.
- Lógica de negocio: solo en capa de dominio/aplicación. Nunca en routers.

### Patrones de diseño del proyecto
Lista abierta — agrega los que apliquen a tu stack y arquitectura, sin límite de cantidad.
- [ej. Repository pattern: toda interacción con datos a través de un repositorio]
- [ej. Service layer: lógica de negocio en services, no en endpoints/controllers]
- [ej. DTO/modelo de transferencia: datos que cruzan capas van en un tipo/estructura
  validado del lenguaje del proyecto, no en estructuras genéricas sin tipo]

## Estándares de seguridad — todos los agentes los aplican

### Reglas absolutas
- Secrets, keys, passwords, tokens: solo en variables de entorno. Nunca en código.
- Logging: nunca loguear passwords, tokens, PII, datos de tarjeta, sesiones.
- Inputs externos: todo input se valida antes de usarse. Sin excepciones.
- Errores al cliente: mensajes genéricos. La información interna va al logger, nunca al cliente.
- Permisos: cada endpoint verifica autenticación Y autorización antes de ejecutar lógica.

### Contratos de seguridad del proyecto
- Autenticación: [ej. JWT con expiración de 1h + refresh token con rotación]
- Autorización: [ej. RBAC con roles: admin, user]
- Validación: [ej. librería/mecanismo de validación de esquemas del stack del proyecto,
  aplicado en todos los puntos de entrada, sin bypass]
- Rate limiting: [ej. 100 req/min en endpoints públicos, 10 req/min en auth]

## Contratos de agente/LLM
Solo si el proyecto invoca modelos de lenguaje (agentes, features con IA). Si no aplica, omite esta sección.
- Proveedor(es) del modelo: [ej. Anthropic API, modelo(s) usado(s)]
- Política de reintento ante falla del proveedor: [ej. 3 reintentos con backoff exponencial, luego falla controlada]
- Presupuesto de tokens/costo esperado por operación típica: [ej. máx 4000 tokens por respuesta de este agente]
- Mecanismo de recuperación de memoria (si aplica): [ej. qué se recupera, de dónde, cómo se valida que es lo correcto]

## Contratos de error del proyecto
- Excepciones de dominio: [ej. DomainError base, subclases específicas por caso]
- Excepciones de infraestructura: [ej. se capturan en infra y se convierten a DomainError]
- Respuestas de error al cliente: [ej. {"error": "mensaje genérico", "code": "ERROR_CODE"}]
- Logging de errores: [ej. ERROR para inesperados, WARNING para validaciones de negocio]

## Definition of Done global
Un feature está terminado cuando:
- [ ] Todos los tests pasan en verde
- [ ] Cobertura >= [define tu umbral, ej. 85%] en código de dominio y aplicación
- [ ] Linter sin warnings ni errores
- [ ] Auditoría de calidad: APROBADO o APROBADO CON OBSERVACIONES menores
- [ ] Auditoría de seguridad: cero severidades Críticas o Altas sin resolver
- [ ] MEMORY.md actualizado con entrada de cierre de iteración

## Prohibido para todos los agentes
- Modificar tests existentes por cualquier razón
- Hardcodear cualquier secret, token, URL de entorno, o valor de configuración
- Ignorar errores silenciosamente
- Implementar algo no definido en design.md sin escalar primero
- Declarar una fase completa sin verificar su Definition of Done
```

---

## FASE 0 — Bootstrap del entorno (una sola vez por proyecto)

El proceso asume desde la Fase 4 que el proyecto compila, tiene base de datos, y puede
correr tests. Si eso no está listo, la primera iteración se ahoga configurando entorno
en vez de construyendo el feature. Esta fase se ejecuta UNA VEZ por proyecto, antes de
la primera iteración, y no se repite. Requiere CLAUDE.md ya aprobado (Fase -1): el
stack, package manager, linter y dependencias que este bootstrap configura se deciden
ahí. El orden de ejecución es natural: Fase -1 (Contexto) → Fase 0 (Bootstrap) →
primera iteración.
La ejecuta un agente en Claude Code; el humano no corre comandos — verifica evidencia.

Checklist de salida — el proyecto no entra a Fase 1 hasta que todo está en verde:

- [ ] Repositorio git inicializado, con .gitignore correcto para el stack
- [ ] Rama principal protegida (si el hosting lo permite): sin push directo, merge por PR
- [ ] Estructura base de carpetas creada: src/, tests/, specs/, specs/iterations/, reports/, docs/
- [ ] specs/iterations/INDEX.md creado (vacío, solo con el header de formato)
- [ ] Gestor de paquetes funcionando (ej. uv/npm/cargo según stack) con lockfile commiteado
- [ ] Test de humo: un test trivial (assert True o equivalente) corre y pasa con el
      runner del stack — prueba que la tubería de testing funciona
- [ ] Linter configurado y corriendo sin errores sobre el esqueleto
- [ ] CI configurado: en cada push corre linter + suite de tests + reporte de cobertura
- [ ] CI incluye el check de tests inmutables (ver Prerrequisito): falla si tests/
      cambia sin autorización explícita del humano
- [ ] Entorno local reproducible: docker-compose (o equivalente) levanta las
      dependencias del stack (ej. PostgreSQL, Redis) con un solo comando
- [ ] .env.example completo con TODAS las variables que el sistema necesita,
      con valores de ejemplo falsos — es el contrato de configuración del proyecto
- [ ] Si hay base de datos: herramienta de migraciones configurada (ej. Alembic) y una
      "migración cero" aplicada y revertida con éxito — prueba que la tubería funciona
- [ ] Si hay base de datos multi-tenant con RLS: la aplicación se conecta con un rol
      NO-superusuario y sin BYPASSRLS, verificado con una consulta de prueba
- [ ] README con: cómo levantar el entorno, cómo correr tests, cómo correr el linter

Al terminar: commit "bootstrap: entorno funcional" y de ahí en adelante toda iteración
empieza directamente en Fase 1.

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee CLAUDE.md completo — el stack, package manager,
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
```

---

## FASE 1 — Agente Requirements

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee CLAUDE.md completo antes de empezar — ahí están las
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
[PEGA AQUÍ LA DESCRIPCIÓN DE LO QUE QUIERES CONSTRUIR]

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
```

---

## FASE 2 — Agente Design

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
- CLAUDE.md (Reglas Globales, estándares de calidad y seguridad, schema de MEMORY.md)
- specs/requirements.md (aprobado por el humano)
- specs/iterations/INDEX.md — te dice qué iteraciones anteriores tocaron los módulos
  de este feature. Con eso, lee el MEMORY.md de esas iteraciones: te dirá qué
  decisiones se tomaron antes y por qué, para no repetirlas ni contradecirlas sin
  justificación explícita. Si INDEX.md está vacío, es primera iteración — no hay
  historial previo.

---

Actúa como un Agente de Arquitectura senior.

Tu objetivo es generar specs/design.md, y además:
- specs/migrations/ SOLO si este feature crea o modifica datos propios del proyecto
  (el proyecto tiene su propia base de datos). Si el feature es un cliente/frontend
  que únicamente consume datos de una API externa sin persistir nada propio, omite
  este artefacto — no inventes una base de datos que no existe.
- specs/openapi.yaml SOLO si este feature expone endpoints propios (el proyecto es o
  incluye un backend/API). Si el proyecto es un cliente puro que consume una API ya
  documentada en otro lugar (por ejemplo, la API de otro servicio de tu stack), omite
  este artefacto y referencia en su lugar la documentación de esa API existente.
- SOLO si este feature involucra un agente o funcionalidad con LLM, produce además
  estos cuatro artefactos. Son los contratos del agente — el equivalente de
  migrations/openapi.yaml para comportamiento agéntico. No los documentes como prosa
  dentro de design.md:
  - specs/graph.md: el grafo de orquestación. Estado del grafo (campos exactos y sus
    tipos), nodos (nombre, responsabilidad en una línea, qué caso de uso invoca),
    edges y condiciones de ruteo (cuándo se toma cada camino, en términos verificables),
    y un diagrama Mermaid del grafo completo. Fase 4 escribe tests de ruteo contra
    esta tabla igual que escribe tests de transición contra "Estados y transiciones".
  - specs/prompts/: un archivo por prompt (system prompt, prompts de nodos de
    clasificación/extracción), con nombre y versión (ej. conversacion.v1.md). Fase 5
    los copia a src/ sin reescribirlos — el prompt es un contrato, no código que el
    implementador redacta a su gusto. Cambiar un prompt después es un cambio de
    contrato: pasa por el proceso y re-corre los evals.
  - specs/tools.md: contrato de cada tool del agente. Nombre, descripción que ve el
    modelo, parámetros con JSON Schema (tipos, requeridos, límites), qué caso de uso
    de application invoca, errores posibles y qué recibe el modelo en cada error.
  - specs/evals/: dataset dorado de comportamiento. Entre 10 y 30 casos por feature
    al inicio (crece con casos reales de producción). Marca 3 a 5 de esos casos como
    "smoke": son los que la Fase 5 corre como humo antes de cerrar — la primera
    validación contra el proveedor real no puede esperar hasta la Fase 8. Cada caso define: contexto de
    entrada (historial, memoria, estado), mensaje del usuario, y asserts
    ESTRUCTURALES verificables — llamó al tool correcto con los parámetros correctos,
    extrajo/usó el dato clave, no inventó datos que no están en el contexto, respetó
    la regla de negocio aplicable. Nunca se compara redacción literal. Los evals se
    corren en Fase 8 y ante cualquier cambio de prompt — no en el suite de CI normal,
    porque llaman al proveedor LLM real.
Si tienes duda sobre si el proyecto genera alguno de estos artefactos: aplica
Regla 2 — pregunta antes de omitir o de crear uno que no corresponde.

No escribas código de implementación.
El diseño debe cumplir desde el inicio los estándares de CLAUDE.md.
No se diseña algo "para arreglarlo después".

Los modelos de datos y los contratos de API NO se documentan como prosa dentro de
design.md — se generan como archivos ejecutables/validables aparte:
- specs/migrations/: migraciones SQL reales (una por cambio de esquema), con la
  definición completa de tablas, tipos, FKs, constraints, índices.
- specs/openapi.yaml: definición completa de endpoints, payloads, headers, errores,
  status codes, campos requeridos/nullable, auth.
design.md referencia esos archivos en vez de repetir su contenido.

Al generar specs/migrations/, cumple estos estándares de modelado de datos:
- Normalización mínima 3FN, salvo que documentes explícitamente por qué te desvías.
- Relaciones entre entidades van como FK explícitas — nunca datos repetidos o
  mezclados dentro de la misma tabla para evitar un join.
- Tipos de dato correctos: fechas y horas en tipo fecha/timestamp, nunca texto.
  Montos y cantidades de dinero en DECIMAL/NUMERIC con precisión fija — nunca
  FLOAT/DOUBLE (imprecisión binaria en cálculos monetarios) ni tipo texto.
- Cada FK tiene su índice correspondiente.
- Constraints de integridad (NOT NULL, UNIQUE, CHECK) se aplican en la base de
  datos misma — no se confían únicamente a validación en la capa de aplicación.
- Prohibido el anti-patrón de "tabla basurero": una tabla no mezcla entidades
  no relacionadas entre sí solo por conveniencia.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo
- [ ] specs/requirements.md está disponible y fue aprobado por el humano
- [ ] Leíste el MEMORY.md de iteraciones anteriores si existe
Si CLAUDE.md tiene Glosario de dominio, úsalo para nombrar entidades, campos y
conceptos de negocio en el diseño de forma consistente con esa definición.
Si hay ambigüedad en los requirements que impide una decisión de diseño:
aplica Regla 2 — documenta la ambigüedad y espera confirmación antes de continuar.

RETROCESO POSIBLE DESDE ESTA FASE:
Si los requirements son insuficientes para tomar una decisión de diseño y el humano
no puede completarlos sin volver a definirlos: aplica Regla 3.
Documenta qué sección de requirements.md está incompleta y por qué bloquea el diseño.
Propón retroceder a Fase 1. Espera aprobación antes de continuar.

---

Produce specs/design.md con esta estructura:

## Decisión de arquitectura
- Patrón elegido: [y justificación respecto a los requirements]
- Cómo se mapea al stack y capas de CLAUDE.md: [explicación concreta]

## Estructura de módulos y carpetas
[árbol de carpetas con una línea de responsabilidad por carpeta]
Justifica cada separación en términos de SOLID-S: ¿por qué esta responsabilidad va aquí?

## Modelos de datos
Resumen breve por entidad (nombre, propósito, una línea).
El detalle completo (campos, tipos, constraints, relaciones, índices) vive en
specs/migrations/ — esa es la fuente de verdad, no este documento.
Datos sensibles: [qué campos son PII o secretos, con referencia a migrations/]

## Estados y transiciones
Solo para entidades con ciclo de vida (ej. una entidad con campo de estado/status).
Para cada una:
### [NombreEntidad]
| Estado origen | Estado destino | Permitido | Motivo si está prohibido |
|---|---|---|---|
Esta tabla es la fuente que usa Fase 4 para generar los tests que verifican que
las transiciones prohibidas son rechazadas por el sistema.
Si el feature no tiene entidades con ciclo de vida, omite esta sección.

## Interfaces y contratos públicos
Resumen breve por endpoint/función pública (nombre, propósito, una línea).
El detalle completo (payload, headers, status, errores, validaciones) vive en
specs/openapi.yaml — esa es la fuente de verdad, no este documento.

## Flujo de datos
Para cada flujo principal del requirements:
### Flujo: [nombre del REQ]
1. Input entra por: [capa/módulo]
2. Validación en: [dónde exactamente, qué se valida]
3. Lógica de negocio en: [capa/módulo]
4. Acceso a datos en: [capa/módulo]
5. Respuesta sale por: [capa/módulo]
6. En caso de error: [qué excepción, dónde se captura, qué llega al cliente]

## Diagramas de secuencia
Solo si el feature involucra webhooks, OAuth, colas, o procesos asíncronos donde el
orden de llamadas entre sistemas y el manejo de fallos/retrasos no es evidente.
Para CRUD síncrono simple, omite esta sección — no aporta.
Para cada flujo asíncrono relevante, un diagrama Mermaid `sequenceDiagram` mostrando:
- Quién llama a quién y en qué orden (incluyendo sistemas externos)
- Qué pasa si un paso falla
- Qué pasa si un evento llega tarde o fuera de orden (ej. webhook duplicado o tardío)

## Decisiones de seguridad
- Dónde se validan y sanitizan los inputs: [módulo y función exactos]
- Qué información de error llega al cliente vs. qué se loguea
- Cómo se gestiona autenticación/autorización en este feature
- Qué datos sensibles existen y cómo se protegen

## Decisiones de observabilidad
Solo si este feature es o forma parte de un servicio que corre de forma continua en
producción (ej. un agente, una API, un worker) — no aplica a scripts de un solo uso ni
a páginas estáticas simples.
- Qué eventos clave de este feature se loguean de forma estructurada, y con qué nivel
  (INFO/WARNING/ERROR)
- Qué métrica(s) permiten detectar si este feature está fallando en producción
  (ej. tasa de error, latencia, tasa de reintentos)
- Estrategia de rollback si este feature falla en producción: ¿se puede desactivar sin
  desplegar código nuevo (feature flag), o requiere revertir el despliegue?

## Architecture Decision Log (ADL)
Para cada decisión no trivial:
### ADL-001: [Nombre de la decisión]
- Contexto: [por qué se tuvo que tomar]
- Decisión: [qué se eligió]
- Justificación: [por qué, incluyendo cumplimiento de SOLID y seguridad]
- Alternativas descartadas: [opción — por qué no]
- Consecuencias: [qué implica para el resto del sistema]

## Dependencias externas
| Librería | Versión exacta | Propósito |
|---|---|---|

## Riesgos técnicos
| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|

---

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Cada REQ-XXX tiene implementación en el diseño
- [ ] specs/migrations/ generado y sintácticamente válido (si el feature persiste datos propios)
- [ ] specs/openapi.yaml generado y sintácticamente válido (si el feature expone endpoints propios)
- [ ] Cada función/endpoint público tiene contrato de error definido en openapi.yaml
      si aplica, o en la sección "Contratos de error del proyecto" de CLAUDE.md si el
      feature no expone API
- [ ] Entidades con ciclo de vida tienen tabla completa de estados y transiciones
- [ ] specs/migrations/ cumple los estándares de modelado de datos (normalización,
      FKs con índice, tipos correctos, constraints en base de datos, sin tablas basurero)
- [ ] Flujos asíncronos (webhooks/OAuth/colas) tienen diagrama de secuencia si aplica
- [ ] Si es un servicio de producción continua: decisiones de observabilidad definidas
      (logging, métrica de fallo, estrategia de rollback)
- [ ] Cada flujo incluye dónde van las validaciones de seguridad
- [ ] ADL tiene entrada por cada decisión no trivial
- [ ] Sin violaciones a la arquitectura de capas de CLAUDE.md
- [ ] Si el feature involucra un agente LLM: graph.md tiene estado, nodos, edges con
      condiciones verificables y diagrama; prompts/ tiene cada prompt versionado;
      tools.md tiene JSON Schema por tool; evals/ tiene al menos 10 casos con asserts
      estructurales
- [ ] Si el proyecto es multi-tenant: toda tabla nueva en migrations/ incluye tenant_id
      y su política RLS (o el mecanismo de aislamiento definido en CLAUDE.md) en la
      misma migración

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Guarda en specs/design.md, specs/migrations/ y specs/openapi.yaml
(+ specs/graph.md, specs/prompts/, specs/tools.md, specs/evals/ si el feature involucra un agente LLM).
Escribe EXACTAMENTE al final:
---
FASE 2 COMPLETA. Definition of Done verificada.
Artefactos generados: [lista exacta].
Revisa los artefactos y confirma con: "Design aprobado"
---
```

---

## FASE 3 — Agente Tasks

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
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
```

---

## FASE 4 — Agente TDD

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
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
```

---

## FASE 5 — Agente Implementation

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
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
```

---

## FASE 6 — Auditoría de Calidad

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
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
```

---

## FASE 7 — Auditoría de Seguridad

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
- CLAUDE.md — las Reglas Globales y el schema de MEMORY.md están ahí.
- specs/requirements.md — necesario para identificar flujos críticos de negocio.
- src/ en [ruta] — léelo completo para el análisis estático.

---

Actúa como un Auditor de Seguridad senior especializado en análisis estático (SAST).

Tu trabajo es encontrar vulnerabilidades de seguridad leyendo el código fuente.
No ejecutas el sistema. No tienes acceso a runtime ni a logs de ejecución.
Análisis estático significa: lees el código, no ejecutas el sistema.

ANTES DE EMPEZAR — verifica:
- [ ] Leíste CLAUDE.md completo
- [ ] specs/requirements.md disponible para identificar flujos críticos de negocio
- [ ] El código de src/ disponible para leer

Reglas absolutas en esta fase:
- No modifiques tests (Regla 1 de CLAUDE.md)
- No cambies arquitectura

RETROCESOS POSIBLES DESDE ESTA FASE:
- Si la vulnerabilidad fue introducida en la implementación (Fase 5):
  Aplica Regla 3. Propón retroceder a Fase 5 con este security-report.md como input adicional.
- Si la vulnerabilidad viene del diseño (ej. flujo sin validación de autorización en design.md):
  Aplica Regla 3. Propón retroceder a Fase 2.
  Documenta exactamente qué decisión de diseño generó la vulnerabilidad.
En ambos casos: documenta, propón, espera aprobación. No continues con Fase 8.

---

Para cada vulnerabilidad encontrada usa este formato:

### VULN-[N]: [Nombre descriptivo]
- Categoría: [A / B / C / D / E / F / G]
- Severidad: Crítica / Alta / Media / Baja
- Archivo:Línea: [ruta exacta:número de línea]
- Evidencia: [fragmento exacto del código problemático]
- Descripción: qué es y cómo podría explotarse en este contexto específico
- Corrección: [cambio exacto de código a aplicar]

Genera reports/security-report.md auditando estas 7 categorías:

CATEGORÍA A — Validación de inputs
Lee cada punto de entrada al sistema: endpoints, websockets, colas, archivos.
- ¿El input se valida antes de usarse? ¿Qué pasa con None, vacío, fuera de rango?
- ¿Hay concatenación de strings en queries SQL o NoSQL? (inyección SQL)
- ¿Hay subprocess, os.system, eval con variables de input externo? (inyección de comandos)
- ¿Hay deserialización de datos externos con pickle o yaml.load sin Loader?
- ¿Hay construcción de rutas de archivo con input de usuario? (path traversal)

CATEGORÍA B — Autenticación y autorización
Lee cada endpoint y handler del sistema.
- ¿Los endpoints protegidos verifican autenticación antes de ejecutar lógica?
- ¿La autorización verifica que el usuario tiene acceso a ESE recurso específico?
  (No solo que está autenticado — que puede acceder a ese objeto concreto)
- ¿Hay IDOR? Acceder al recurso de otro usuario con ID conocido sin validar propiedad.
- ¿Los tokens tienen expiración definida? ¿Son revocables?
- ¿Hay rutas de bypass de autenticación?

CATEGORÍA C — Datos sensibles en el código
Busca en todo el código:
- Strings literales que parezcan secrets, API keys, passwords o tokens
- Llamadas a logger o print que incluyan variables de usuario, tokens o PII
- Respuestas de error que incluyan stack traces, rutas internas o datos del sistema
- Mensajes de error que distingan "usuario no existe" de "password incorrecto"
  (esto revela si el usuario existe — es un oracle de enumeración)
- Datos sensibles en parámetros de URL

CATEGORÍA D — Lógica de negocio
Usa specs/requirements.md para identificar los flujos críticos de negocio.
Para cada flujo crítico, traza el código y verifica:
- ¿Pueden ejecutarse los pasos en orden incorrecto?
- ¿Puede saltarse algún paso de validación manipulando el orden de llamadas?
- ¿Hay condiciones de carrera? (verificar saldo y luego cobrar sin atomicidad)
- ¿Los límites numéricos están validados? (negativos, cero, overflow, decimal vs entero)
- ¿Puede un usuario escalar privilegios manipulando parámetros?

CATEGORÍA E — Configuración
Lee archivos de configuración, settings e inicialización de la aplicación:
- ¿CORS con origins específicos o con wildcard *?
- ¿Rate limiting en endpoints públicos y en endpoints de autenticación?
- ¿Headers de seguridad HTTP configurados?
- ¿Modos de debug desactivados para producción?
- ¿Excepciones no manejadas producen respuestas genéricas o stack traces?

CATEGORÍA F — Dependencias
Lee el archivo de dependencias del stack del proyecto (ej. requirements.txt/pyproject.toml
en Python, package.json en Node/TypeScript, pom.xml/build.gradle en Java, mix.exs en
Elixir, go.mod en Go, o el equivalente que use CLAUDE.md):
- Lista las dependencias críticas con su versión exacta
- Para frameworks, librerías de auth y librerías de parsing:
  indica si la versión tiene CVEs conocidos según tu conocimiento de entrenamiento
- Para CVEs Críticos o Altos: propón la versión segura específica
- Indica qué dependencias requieren verificación manual con NIST CVE o Snyk

CATEGORÍA G — Específico del stack del proyecto
Adapta esta sección al stack real definido en CLAUDE.md. Los siguientes son ejemplos de
qué verificar por tipo de pieza de software — no una lista cerrada ni específica de un
framework: aplica el principio equivalente en el framework/lenguaje real del proyecto.

Si el proyecto expone endpoints HTTP (cualquier framework backend):
- ¿Todo endpoint protegido tiene el mecanismo de autenticación del proyecto aplicado
  antes de ejecutar su lógica (middleware, decorador, guard, o equivalente)?
- ¿Las respuestas declaran explícitamente qué campos exponen (allowlist), en vez de
  serializar objetos completos que podrían incluir campos no deseados?
- ¿Los campos de entrada tienen validación de formato/longitud con el mecanismo de
  validación de esquemas que define CLAUDE.md?
- ¿CORS (si aplica) está configurado con origins específicos, no wildcard?

Si el proyecto incluye WebSockets o conexiones persistentes:
- ¿La autenticación se verifica durante el handshake, antes de aceptar la conexión?
- ¿Los mensajes recibidos se validan antes de procesarse?
- ¿Hay límite de tamaño de mensaje para prevenir agotamiento de memoria?

Si el proyecto es multi-tenant:
- ¿Toda tabla de negocio tiene el mecanismo de aislamiento que define CLAUDE.md
  (ej. política RLS sobre tenant_id) creado en la MISMA migración que creó la tabla?
- ¿El rol de base de datos con el que se conecta la aplicación es NO-superusuario
  y sin capacidad de bypass del aislamiento (ej. sin BYPASSRLS en PostgreSQL)?
- ¿Hay alguna query, búsqueda vectorial, job en background, o recuperación de memoria
  que se ejecute SIN contexto de tenant establecido? Cada una es Severidad Crítica.
- ¿Algún endpoint deriva el tenant de un parámetro controlable por el cliente
  (body, query param, header no firmado) en vez del token/firma verificada?
- ¿Los recursos de otro tenant responden "no existe" en vez de "no autorizado"?
  (Distinguirlos confirma la existencia del recurso — enumeración cross-tenant.)

Si el proyecto invoca LLMs (agente o feature con IA):
- ¿Texto proveniente de usuarios externos se interpola dentro del system prompt?
  (Prompt injection directa — el input de usuario va como mensaje de usuario, nunca
  como parte de las instrucciones del sistema.)
- ¿Contenido recuperado de memoria/RAG/documentos se trata como instrucciones o
  como datos? (Prompt injection indirecta.)
- ¿Las tools del agente validan sus parámetros en código antes de ejecutar, o
  confían en que el modelo "manda bien los datos"? Toda tool valida como si su
  input viniera de internet — porque efectivamente viene de ahí.
- ¿Alguna tool permite al agente acceder a datos fuera del tenant/usuario de la
  conversación actual?
- ¿Qué PII viaja al proveedor del LLM y está eso documentado/minimizado?
- ¿Los logs guardan prompts completos con PII conversacional?

Si el proyecto incluye Playwright o scraping:
- ¿Las credenciales de sitios objetivo no aparecen en código ni en logs?
- ¿Los resultados del scraping se sanitizan antes de guardarse o enviarse?
- ¿Los tokens de autenticación del worker no se exponen en logs?

Si el proyecto es una aplicación frontend/cliente (web, mobile, o desktop):
- ¿Hay secrets, API keys, o tokens hardcodeados que terminarían expuestos en el bundle
  o binario entregado al usuario final? (todo secret real vive solo en el backend)
- ¿El contenido dinámico que se renderiza (inputs de usuario, datos de API) pasa por
  un mecanismo de escape/sanitización del framework antes de insertarse en el DOM,
  para prevenir XSS?
- ¿Las llamadas a APIs externas van siempre por HTTPS?
- ¿Hay dependencias de terceros con CVEs conocidos en el bundle final (cubierto también
  en Categoría F, pero relevante aquí porque en frontend esas dependencias se entregan
  directo al cliente)?
- ¿Los datos sensibles (tokens de sesión, PII) evitan guardarse en localStorage/
  almacenamiento del cliente sin cifrar, cuando el framework ofrece una alternativa más segura?

---

Correcciones:
- Severidad Crítica y Alta: aplica directamente, luego corre el suite de tests.
  Si un test falla después de tu corrección: el test probablemente validaba el comportamiento
  inseguro. No lo modifiques. Documenta el caso y escala al humano.
- Severidad Media y Baja: lista en el reporte y espera aprobación.
- CVEs en dependencias: propón la actualización, no la apliques sin aprobación.
  Una actualización de versión puede tener breaking changes.

Antes de declarar la fase completa, verifica tu Definition of Done:
- [ ] Las 7 categorías auditadas con resultado documentado para cada una
- [ ] Cero severidades Críticas o Altas sin resolución documentada
- [ ] Dependencias verificadas con CVEs identificados o descartados
- [ ] Flujos críticos de negocio de requirements.md trazados en Categoría D

Actualiza MEMORY.md usando el schema de la Regla 5 de CLAUDE.md.
Guarda en reports/security-report.md.
Escribe EXACTAMENTE al final:
---
FASE 7 COMPLETA.
Vulnerabilidades: [N] Críticas, [M] Altas, [X] Medias, [Y] Bajas.
Aplicadas: [críticas y altas]. Pendientes aprobación: [medias y bajas].
Dependencias con CVEs: [N].
Definition of Done verificada.
Confirma con: "Seguridad aprobada, iniciar cierre de iteración"
---
```

---

## FASE 8 — Cierre de Iteración

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
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
```

---

## FASE 9 — Release (solo cuando un incremento sube a producción)

Una iteración cerrada (Fase 8) es código integrado y auditado en el repositorio —
no es software en manos del usuario. "Terminado" significa liberado en producción,
no mergeado (principio central de Continuous Delivery, Humble y Farley). Esta fase
corre cada vez que un incremento sube a producción: puede ser cada iteración o un
lote de iteraciones — esa decisión es del humano y se registra en el release-report.

### Prompt — copia todo lo que está dentro de este bloque:

```
El proyecto está en [ruta]. Lee estos archivos antes de empezar:
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
```

---

## Cómo usar MEMORY.md en retrocesos

Cualquier fase (de la 3 a la 8) puede detectar un error y activar retroceso.
Para decidir a qué fase retroceder, la pregunta no es "qué combinación aparece en una
tabla" — es "¿dónde se definió mal esto?". Responde en este orden:

- ¿El requisito mismo estaba mal o incompleto? → retrocede a **Fase 1**
- ¿El requisito estaba bien, pero el diseño lo interpretó mal o dejó un hueco (incluyendo
  contratos de datos/API, estados/transiciones, seguridad, u observabilidad)? → retrocede a **Fase 2**
- ¿El diseño estaba bien, pero el test no lo reflejó correctamente? → retrocede a **Fase 4**
- ¿El test estaba bien, pero el código no lo cumple? → retrocede a **Fase 5**

Esto aplica sin importar en qué fase estés parado — Fase 6, 7 u 8 pueden retroceder
directo a Fase 1 si la causa raíz real es un requisito mal definido, no solo a la fase
inmediatamente anterior. No hay una lista cerrada de combinaciones permitidas.

El protocolo es el mismo en todos los casos:

1. El agente que detecta el error escribe su entrada en MEMORY.md con Resultado: RECHAZADO
   y documenta en "Problemas encontrados" qué falló, en qué fase se originó, y qué impacto tiene.

2. Corres `/clear` para abrir una sesión nueva de Claude Code para la fase a la que hay que retroceder.

3. En el prompt de esa fase, dile al agente: "Lee specs/iterations/[fecha]-[feature]/MEMORY.md
   antes de empezar." El agente sabe qué se intentó antes y qué falló — no repite el error.

4. El agente corrige, completa su fase, y el proceso continúa desde ese punto —
   repitiendo las fases intermedias que dependían de lo que se corrigió.

---

## Señales de que algo salió mal

| Síntoma                                                                                                                                                              | Causa                                                                                  | Acción correcta                                                                           |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Fase 6 encuentra violaciones masivas de SOLID                                                                                                                        | Fase 5 no cumplió estándares de CLAUDE.md                                              | Retroceder a Fase 5 con quality-report como input adicional                               |
| Fase 7 encuentra muchos secrets hardcodeados                                                                                                                         | Fase 5 ignoró estándares de seguridad                                                  | Retroceder a Fase 5                                                                       |
| Un agente modificó un test                                                                                                                                           | No cumplió Regla 1                                                                     | Revertir el cambio. El test original es el contrato.                                      |
| Tests fallan después de correcciones de Fase 6                                                                                                                       | Corrección rompió acoplamiento                                                         | El agente corre el suite después de CADA corrección, no al final                          |
| Fase 7 encuentra CVE crítico en dependencia                                                                                                                          | Versión desactualizada                                                                 | Proponer versión segura y escalar al humano                                               |
| Un agente implementó algo no en design.md                                                                                                                            | No cumplió Regla 2                                                                     | Aplicar Regla 3: documentar, proponer retroceso, esperar aprobación                       |
| Fase 8 encuentra flujos sin test e2e                                                                                                                                 | Normal — Fase 4 solo cubre units                                                       | Fase 8 los crea. No es un error.                                                          |
| Fase 6 resultado RECHAZADO                                                                                                                                           | Violaciones críticas en implementación                                                 | Retroceder a Fase 5 con quality-report como input adicional                               |
| Fase 8 encuentra desviaciones entre design.md y el código real                                                                                                       | Normal en implementaciones complejas                                                   | Fase 8 reconcilia design.md. No es un error si está documentado.                          |
| Evals fallan en Fase 8 pero todos los tests están en verde                                                                                                           | Los tests verifican el grafo con LLM mockeado; los evals verifican comportamiento real | Retroceder a Fase 2: el prompt o el diseño del grafo es la causa, no el código            |
| Un test de Categoría 6 (aislamiento) falla                                                                                                                           | Falta política RLS o hay un camino sin contexto de tenant                              | Severidad Crítica siempre. Retroceder a Fase 2 (diseño de datos) o Fase 5 según origen    |
| `git diff --diff-filter=MD -- tests/` no está vacío al cerrar Fases 5-7, o hay archivos nuevos fuera de las excepciones (Fase 5: tests/; Fase 8: tests/integration/) | Un agente violó la Regla 1                                                             | Fase RECHAZADA automáticamente. Revertir tests/ al commit test-contract y repetir la fase |
| El smoke de evals falla al cerrar Fase 5 con todos los tests en verde                                                                                                | El prompt o el grafo es la causa, no el código (los tests usan LLM mockeado)           | Regla 3: retroceder a Fase 2                                                              |
| El smoke test post-deploy de Fase 9 falla                                                                                                                            | El incremento no funciona en el entorno real                                           | Ejecutar el plan de reversión de inmediato, luego Regla 3 para ubicar la fase de origen   |

---

## Alcance del proceso — qué tipos de software cubre y cómo se adapta

El proceso es el mismo para cualquier pieza de software en cualquier lenguaje: las 8
fases, las reglas globales, los retrocesos y MEMORY.md no cambian nunca. Lo que cambia
por tipo de proyecto son dos cosas: (a) el contenido de CLAUDE.md (stack, arquitectura,
estándares del lenguaje) y (b) qué artefactos condicionales produce la Fase 2. Esta
tabla define ambas por tipo:

| Tipo de software                      | Artefactos de Fase 2 además de design.md                                                                                                                                                                                             | Qué cambia en tests (Fase 4)                                                                                         | Notas                                                                                                |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| API / backend                         | migrations/ + openapi.yaml                                                                                                                                                                                                           | Nada — es el caso base del proceso                                                                                   |                                                                                                      |
| Agente LLM                            | migrations/ + openapi.yaml (si aplica) + graph.md + prompts/ + tools.md + evals/                                                                                                                                                     | Categoría 5 obligatoria; evals en Fase 8                                                                             | El comportamiento conversacional es el producto: sin evals no hay contrato real                      |
| Sistema multi-tenant (cualquier tipo) | migrations/ con aislamiento en la misma migración                                                                                                                                                                                    | Categoría 6 obligatoria                                                                                              | Se combina con cualquier otra fila — multi-tenant es una propiedad, no un tipo                       |
| Cliente web (SPA/SSR)                 | Sin migrations ni openapi propios — referencia el openapi.yaml del backend que consume. Produce en su lugar: inventario de rutas/pantallas y estados de cada una (cargando/vacío/error/éxito), y contrato de componentes compartidos | Tests de componentes + tests de estados de pantalla; Fase 8 crea los e2e con herramienta de browser (ej. Playwright) | La tabla de "Estados y transiciones" aplica igual: estados de UI son estados                         |
| Cliente móvil                         | Igual que cliente web + matriz de plataformas/versiones soportadas y comportamiento offline si aplica                                                                                                                                | Tests de la capa de lógica separada de la UI; e2e con el framework de testing de la plataforma                       | Exigir en design.md que la lógica de negocio viva fuera de las vistas — igual que "nunca en routers" |
| Librería / SDK                        | Sin migrations ni openapi. Produce: contrato de API pública (cada función/clase exportada: firma, errores, ejemplos de uso) + política de versionado (semver: qué es breaking)                                                       | Los ejemplos de uso del contrato SE CONVIERTEN en tests — un ejemplo que no compila/corre es documentación falsa     | El contrato de API pública es el openapi.yaml de una librería                                        |
| Worker / job / CLI                    | migrations/ si persiste datos. Produce: contrato de entrada/salida (argumentos, códigos de salida, formato de output) + contrato de idempotencia (¿qué pasa si corre dos veces?)                                                     | Tests de idempotencia y de reanudación tras falla obligatorios                                                       | Un worker que no define idempotencia duplica efectos en producción                                   |

Reglas de adaptación:

- Las filas se combinan: un "agente LLM multi-tenant con API" produce la unión de los
  artefactos de las tres filas.
- El lenguaje es irrelevante para el proceso: CLAUDE.md define el runner de tests, el
  linter, el gestor de paquetes y los estándares idiomáticos del lenguaje; los prompts
  de cada fase leen eso de CLAUDE.md, no lo tienen hardcodeado.
- Si un tipo de proyecto nuevo no encaja en la tabla, la pregunta para derivar sus
  artefactos es siempre la misma: ¿cuáles son los contratos de esta pieza que deben ser
  ejecutables/validables en vez de prosa? Datos → migrations. Interfaz expuesta →
  openapi/contrato de API pública. Comportamiento no determinista → evals. Aislamiento →
  tests de aislamiento. Esa es la regla generadora de todo el proceso.
