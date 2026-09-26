# CLAUDE.md — B2B Lead Generation (Distributed Scraping System with Local Execution Control)
Versión: 1.0 | Fecha: 2026-09-25

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
- Lenguaje y versión: Python 3.12 en todo el sistema (Control Plane, Client Node, Admin Panel, Channels Service) — DECISIÓN-1
- Framework: FastAPI 0.115+ (Control Plane) · Flet (Client Node y Admin Panel, DECISIÓN-1/14) · framework de bot async para Telegram/WhatsApp — sin definir todavía, se decide en la primera iteración de `channels-service` (no fue objeto de ADL en Fase -1)
- Base de datos: PostgreSQL 16
- ORM: SQLAlchemy 2.0 (async) + Alembic — DECISIÓN-2
- Cola y broker: Redis + `arq` (colas async + cron) — DECISIÓN-9
- LLM (Job Generator): multi-proveedor vía LangChain `init_chat_model` (Anthropic Claude / OpenAI GPT / Google Gemini / Groq / otros soportados por LangChain) — DECISIÓN-8
- Testing: pytest + pytest-asyncio + httpx (Control Plane) + pytest-playwright (Client Node) — DECISIÓN-6
- Package manager: uv (workspace de monorepo) — DECISIÓN-6
- Linter: ruff (lint + format, único para todo el monorepo) — DECISIÓN-6

## Arquitectura
- Patrón: Monorepo multi-app, Clean Architecture dentro de `apps/api` — DECISIÓN-3
- Capas (Control Plane): domain → application → infrastructure → api
- Regla de dependencias: las capas internas no conocen las externas; ninguna app del monorepo importa código interno de otra — solo se comunican a través de la API pública del Control Plane y de `packages/shared-contracts`
- Estructura del repositorio (DECISIÓN-3):
  - `apps/api` — es el "Control Plane" completo (FastAPI): expone la API REST + WebSocket, Job Generator, Scheduler, Payment. El panel admin NO vive aquí (ver abajo)
  - `apps/client-node` — Flet, un solo paquete Python; interfaz de búsqueda del cliente final Y ejecutor local del Scraper Engine (Playwright) en la misma app — DECISIÓN-1
  - `apps/admin-panel` — Flet web, panel de administración de un solo operador — DECISIÓN-14
  - `apps/channels-service` — Telegram hoy, WhatsApp después, vía interfaz `ChannelAdapter`; solo consume la API pública del Control Plane, sin lógica de negocio propia
  - `packages/shared-contracts` — DTOs Pydantic (Job, JobResult, mensajes WebSocket) compartidos entre apps; única dependencia cruzada permitida entre apps del repo. Es una **dependencia de build-time, no de runtime**: cada app fija/empaqueta la versión de `shared-contracts` que necesita al momento de construirse (igual que cualquier librería externa, ej. `pydantic` mismo) — en producción no hay ninguna conexión viva entre `apps/api` y `apps/client-node` a través de este paquete, así que compartirlo no rompe el despliegue independiente de cada app. Compartir código NO es lo mismo que compartir despliegue: define QUÉ forma tienen los datos, no CUÁNDO corre cada proceso.
  - Una Web App de navegador para el cliente final es un despliegue secundario y opcional del mismo código de `apps/client-node`, sin capacidad de ejecución local — se construye en repo aparte solo cuando se decida (no es parte del alcance inicial)
- Compatibilidad de contrato entre Backend y Client Node: el Client Node vive en la computadora de cada usuario — el operador NO controla cuándo (ni si) cada usuario actualiza su instalación, a diferencia de un microservicio normal donde el mismo equipo redespliega ambos lados a la vez. Por eso el campo `"version"` del envelope WebSocket (DECISIÓN-10, `{"type", "version", "payload"}`) existe específicamente para esto: `apps/api` debe seguir entendiendo Client Nodes en versiones de contrato viejas indefinidamente, ramificando su lógica por `version` en vez de asumir que todo cliente conectado trae la última forma del mensaje. Regla de evolución de `shared-contracts`: los cambios son aditivos y retrocompatibles (agregar campos opcionales) siempre que se pueda; quitar o renombrar un campo, o cambiar el significado de uno existente, exige subir el `version` del mensaje afectado — nunca se rompe un campo existente sin eso.
- Aislamiento multi-tenant: PostgreSQL con Row-Level Security, columna `user_id` en cada tabla (la cuenta de login ES el límite de aislamiento, no existe un `tenant_id` separado) — DECISIÓN-5
- Tipo de proyecto combinado (para criterio de artefactos de Fase 2, según la tabla "Alcance del proceso" de ASDP-PROCESS.md): API/backend + Agente LLM (Job Generator) + Sistema multi-tenant + Worker/job (Client Node) — DECISIÓN-3

## Glosario de dominio
| Término | Definición | Por qué se presta a confusión |
|---|---|---|
| Cliente / Client Node | "Cliente" es ambiguo en este proyecto: puede referirse a la persona que paga (dueño del negocio) o al software instalado en su computadora. Convención: "usuario" o "cliente final" = la persona; "Client Node" = la app Flet que corre en su máquina. | Se usa "cliente" en ambos sentidos en el lenguaje cotidiano del negocio |
| `user_id` | Identificador de la cuenta de login. Es también el límite de aislamiento multi-tenant (DECISIÓN-5) — no existe un `tenant_id` separado. | Se puede confundir con un ID de sesión o con el `device_id` |
| `device_id` | Identifica una instalación física del Client Node (una computadora). Un mismo `user_id` puede tener varios `device_id` (varias computadoras), cada uno con su propio fingerprint (DECISIÓN-12). | Se puede confundir con `user_id`; NO es lo mismo — el fingerprint se asigna por `device_id`, nunca por `user_id` |
| Search / Job | Una "Search" es la instrucción del usuario (ej. "academias de belleza 5 estrellas en Nuevo León"). El Job Generator la expande en uno o varios "Job" (uno por combinación zona × categoría). | Una Search y un Job no son 1:1 — una sola Search puede generar decenas de Jobs |
| Lead | Un negocio encontrado y calificado por el Scraper Engine, ya clasificado en un segmento. | No confundir con "resultado crudo" — un Lead ya pasó el filtro de `good_rating_threshold` |
| Segmento (Micro / Corporate / Master) | Micro = pocas reseñas; Corporate = muchas reseñas o cadena conocida; **Master no es un segmento** — es la vista/archivo que contiene TODOS los Leads válidos sin importar segmento. | "Master" se confunde fácilmente con un tercer segmento cuando en realidad es "todo junto" |
| Fingerprint | Identidad de navegador (user-agent, viewport, locale, timezone) que el Backend genera y asigna a un `device_id` (DECISIÓN-12). | No es la identidad del usuario ni una credencial de seguridad — es un parámetro anti-detección del scraper |
| Canal (Channel) | Vía de entrada conversacional (Telegram, WhatsApp) para crear Searches — DECISIÓN-3. | No confundir con el Client Node: un canal nunca ejecuta scraping, solo traduce mensajes a llamadas de la API pública |

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
- Lógica de negocio: solo en capa de dominio/aplicación. Nunca en routers, nunca en el Client Node.

### Patrones de diseño del proyecto
- Repository pattern: toda interacción con datos vía SQLAlchemy pasa por un repositorio (capa infrastructure).
- Service layer: lógica de negocio en application services, no en endpoints/routers ni en el Client Node.
- DTO/modelo de transferencia: datos que cruzan capas o procesos (API, WebSocket) van en modelos Pydantic de `packages/shared-contracts` — DECISIÓN-10.
- Adapter pattern: `ChannelAdapter` para canales de mensajería (Telegram/WhatsApp, DECISIÓN-3); `PaymentProvider` para proveedores de pago (DIP, DECISIÓN-13).
- Factory pattern: selección de proveedor LLM activo vía `init_chat_model` a partir de `ai_provider_config` (DECISIÓN-8).
- "The client executes, the server decides": ninguna decisión de negocio, límite, fingerprint o catálogo se genera en el Client Node — DECISIÓN-11/12.

## Estándares de seguridad — todos los agentes los aplican

### Reglas absolutas
- Secrets, keys, passwords, tokens: solo en variables de entorno. Nunca en código.
- Logging: nunca loguear passwords, tokens, PII, datos de tarjeta, sesiones.
- Inputs externos: todo input se valida antes de usarse. Sin excepciones.
- Errores al cliente: mensajes genéricos. La información interna va al logger, nunca al cliente.
- Permisos: cada endpoint verifica autenticación Y autorización antes de ejecutar lógica.

### Contratos de seguridad del proyecto
- Autenticación: JWT (access + refresh con rotación); vínculo Telegram/WhatsApp ↔ cuenta vía token de enlace de un solo uso; Client Node se autentica con las credenciales de la cuenta del usuario final dentro de la propia ventana Flet y recibe un token de sesión de corta duración (ej. 1h), rotado en cada reconexión WebSocket — DECISIÓN-4
- Autorización: RBAC simple, roles `admin` / `user` por cuenta (`user_id`). El Client Node no tiene rol de negocio propio: hereda el `user_id` de quien inició sesión, con scope técnico "worker" sin acceso a endpoints administrativos. El Admin Panel exige exclusivamente el rol `admin` — DECISIÓN-4/14
- Aislamiento multi-tenant: PostgreSQL RLS, `user_id NOT NULL` en cada tabla, rol de aplicación sin BYPASSRLS (verificado en Fase 0) — DECISIÓN-5
- Validación: modelos Pydantic v2 en todos los puntos de entrada (REST, WebSocket, mensajes de canal), sin bypass
- Anti-detección / fingerprinting: el Backend genera y asigna el fingerprint por `device_id` desde un pool curado con garantía de unicidad; el Client Node nunca genera ni decide su propio fingerprint, solo lo cachea y lo aplica — DECISIÓN-12
- Confianza del Client Node: entorno no confiable. Nunca contiene claves de LLM, credenciales de proveedor de pago, ni datos de otro usuario — solo el token de sesión rotativo — DECISIÓN-11
- Rate limiting: no se definió un número global en Fase -1 (Regla 2 — no inventar); se define endpoint por endpoint en la Fase 2 de la iteración que lo exponga

## Contratos de agente/LLM
- Proveedor(es) del modelo: multi-proveedor configurable en caliente vía LangChain `init_chat_model` (Anthropic Claude, OpenAI GPT, Google Gemini, Groq/Llama, u otro soportado por LangChain). Selección de proveedor + modelo activo en la tabla `ai_provider_config` (Postgres); las API keys de cada proveedor viven exclusivamente en variables de entorno, nunca en la base de datos ni en código — DECISIÓN-8
- Política de reintento ante falla del proveedor: 3 reintentos con backoff exponencial vía `.with_retry()` de LangChain, iguales para cualquier proveedor. Si los 3 fallan, el Job se encola para revisión humana — nunca se ejecuta con una salida no validada contra el schema de Job.
- Presupuesto de tokens/costo esperado por operación típica: ~2000 tokens de salida por instrucción de generación de Jobs, aplicado como límite de la tool/schema, independiente del proveedor activo.
- Mecanismo de recuperación de memoria: no aplica — el Job Generator no mantiene memoria conversacional entre instrucciones; cada instrucción se procesa de forma independiente, con el catálogo verificado de municipios/zonas como contexto de la tool `generar_jobs`.

## Contratos de error del proyecto
- Excepciones de dominio: `DomainError` base, subclases específicas por caso (`ValidationError`, `UserIsolationError`, `JobExecutionError`, `PaymentError`, ...) — DECISIÓN-7
- Excepciones de infraestructura: se capturan en la capa de infraestructura y se convierten a `DomainError` antes de cruzar a application/api.
- Respuestas de error al cliente: `{"error": {"code": "...", "message": "mensaje genérico", "details": {...}}}` en REST; en el protocolo WebSocket, un mensaje tipo `error` versionado con el mismo `code` — catálogo propio para fallos del Client Node (`JOB_TIMEOUT`, `BROWSER_CRASH`, `RATE_LIMITED_BY_TARGET`, ...) — DECISIÓN-10
- Logging de errores: ERROR para inesperados, WARNING para validaciones de negocio

## Definition of Done global
Un feature está terminado cuando:
- [ ] Todos los tests pasan en verde
- [ ] Cobertura >= 80% en código de dominio y aplicación (`apps/api/src/api/domain`, `apps/api/src/api/application`) — definido en Fase 0 (Bootstrap), 2026-09-26. Verificable con `scripts/check_domain_coverage.sh`.
- [ ] Linter (ruff) sin warnings ni errores en todo el monorepo
- [ ] Auditoría de calidad: APROBADO o APROBADO CON OBSERVACIONES menores
- [ ] Auditoría de seguridad: cero severidades Críticas o Altas sin resolver
- [ ] MEMORY.md actualizado con entrada de cierre de iteración

## Prohibido para todos los agentes
- Modificar tests existentes por cualquier razón
- Hardcodear cualquier secret, token, URL de entorno, o valor de configuración
- Ignorar errores silenciosamente
- Implementar algo no definido en design.md sin escalar primero
- Declarar una fase completa sin verificar su Definition of Done
- Agregar lógica de negocio, límites, o generación de fingerprint dentro del Client Node (`apps/client-node`) — esa lógica vive exclusivamente en `apps/api`
- Introducir un lenguaje nuevo en el monorepo sin pasar por una decisión ADL explícita (el sistema es 100% Python por decisión deliberada — DECISIÓN-1/14)
