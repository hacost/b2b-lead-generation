Lee estos archivos antes de empezar:
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
