Lee ASDP-PROCESS.md — la tabla "Alcance del proceso" define qué artefactos exige cada tipo de proyecto.

Actúa como un Agente de Contexto senior.

Voy a construir el siguiente sistema:
Distributed Scraping System with Local Execution Control.
1. INTERFACES (User Layer) Web App   Telegram.
2. BACKEND (Control Plane)
   1. FastAPI (API)   
   2. Authentication   
   3. Payment validation   
   4. Job generator (por un agente, interpreta la instrucción del humano y genera los Jobs en base a esa instrucción)  
   5. Scheduler (cron + queues)   
   6. Payment automation   
   7. Never executes scrapers   
   8. PostgreSQL database (Estrategia Multitenat, datos independientes, sin mezclar datos de cada usuario)
   9. WebSocket server (real-time control)
3. CLIENT NODE (Worker)  
   1. Local Client (Worker Node)   
      1. WebSocket connection   
      2. Token authentication   
      3. Job receiver   
      4. Local execution   
      5. Results + logs sender   
      6. Usage limiter   
      7. No business logic  
   2. Scraper Engine   
      1. Playwright + Chromium   
      2. Behavior rotation   
      3. Random delays   
      4. Variable navigation   
      5. Unique fingerprint per client
      6. busca zonas y categorias separadas por punto y coma 
      7. busca de acuerdo a la configuración de cada usuario,
   por default te comparto un ejemplo de los parametros o configuracion del usuario, pero recuerda esos valores vendran de la configuración de cada usuario o la misma instrucción, por ejemplo si un usuario dice buscame academias de bellasa de 5 estrellas en todo nuevo leon, el agente debe preparar los JOBS POR CADA MUNICIPIO DE NUEVO LEON  más los parametros acorde a esa instruccion, más la configuración indicada en este punto descrapper engine {
    "segmentation": {
        "micro_max_reviews": 20,
        "corporate_min_reviews": 21,
        "good_rating_threshold": 3.5
    },
    "search": {
        "max_scroll_attempts": 5,
        "wait_between_actions_ms": 3000,
        "_comment_headless": "Set to false to see the browser UI visually. Set to true to run fully in the background (console only).",
        "headless": false
    }
}   
1. TARGET WEBSITES
   1. Target websites (zonas y categorias que cumplan con los parametros de busqueda del usuario)  
2. FLUJOS Y CONEXIONES (Flujo de datos)
   1. Entre Interfaces y Backend:
      1. Create search (Web App / Telegram -> Backend)   
      2. Only iny secure API (Entre Web App / Telegram y Backend)   
      3. Results delivery (Backend -> Telegram / Web App)   
   2. Entre Backend y Client Node:
      1. Send job (WebSocket) (Backend -> Local Client)   
      2. Results + logs (Local Client -> Backend)   
   3. Entre Client Node y Target Websites:
      1. Scraping (Scraper Engine -> Target websites (zonas y categorias + parametros del usuario))
3. SECURITY LAYER
   1. Untrusted client environment  
   2. Rotating tokens   
   3. No secrets exposed   
   4. No critical logic in client   
   5. Principio clave del sistema:"The client executes, the server decides" 

existe un ejemplo del scrapper que ya funciona, pero no toma en cuenta de forma dinamica traerlos desde la configuracion de cada usuario los parametros, está en: [~/repositories/bastion-core/b2b-lead-generation/google_maps_scraper.py]

Tu objetivo NO es generar CLAUDE.md todavía. Primero produce
specs/context-proposal.md con las decisiones estructurales del proyecto, cada una en este formato (el mismo ADL de la Fase 2):

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

Si te di un template de fábrica: parte de sus decisiones como base y propón SOLO los deltas — qué mantienes tal cual, qué cambias y por qué.

Regla 2 aplica: si mi descripción no alcanza para recomendar una decisión, pregunta — no rellenes con suposiciones.

Espera mi respuesta decisión por decisión: "DECISIÓN-N aprobada", "DECISIÓN-N: cámbiala a [X]", o "DECISIÓN-N rechazada, propón otra opción".
NO generes CLAUDE.md hasta que yo escriba: "Contexto aprobado".

Cuando reciba "Contexto aprobado": genera CLAUDE.md completo con el template de ASDP-PROCESS.md, llenando cada campo con las decisiones aprobadas — sin agregar decisiones nuevas que no pasaron por la propuesta.

Escribe EXACTAMENTE al final:
---
FASE -1 COMPLETA. CLAUDE.md generado con [N] decisiones aprobadas.
Revisa CLAUDE.md y confirma con: "CLAUDE.md aprobado"