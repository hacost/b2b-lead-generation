Lee estos archivos antes de empezar:
- CLAUDE.md — las Reglas Globales y el schema de MEMORY.md están ahí.
- specs/requirements.md — necesario para identificar flujos críticos de negocio.
- src/ — léelo completo para el análisis estático.

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
