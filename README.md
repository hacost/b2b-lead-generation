# B2B Lead Generation — Distributed Scraping System with Local Execution Control

Monorepo Python 3.12 (ver `CLAUDE.md` para stack, arquitectura y decisiones completas).

## Estructura

```
apps/
  api/              Control Plane (FastAPI): REST + WebSocket, Job Generator, Scheduler, Payment
  client-node/      Ventana Flet: búsqueda + ejecutor local del Scraper Engine (Playwright)
  admin-panel/      Panel de administración (Flet web, rol admin)
  channels-service/ Canales de entrada conversacional (Telegram hoy, WhatsApp después)
packages/
  shared-contracts/ DTOs Pydantic compartidos entre apps (dependencia de build-time)
specs/              requirements.md, design.md, todo.md por iteración; specs/iterations/ tiene el historial
tests/integration/  Tests de integración end-to-end (solo se agregan en Fase 8)
reports/            Reportes de auditoría de calidad/seguridad/cierre por iteración
infra/postgres-init/ Scripts de inicialización de Postgres (rol de aplicación sin BYPASSRLS)
```

## Requisitos

- [uv](https://docs.astral.sh/uv/) (gestor de paquetes del monorepo)
- [colima](https://github.com/abiosoft/colima) + Docker CLI + Docker Compose (entorno local reproducible)
  ```
  brew install colima docker docker-compose
  colima start
  ```

## Levantar el entorno local

```bash
cp .env.example .env        # completa los valores marcados "change-me"
docker compose --env-file .env up -d
uv sync --all-packages
```

Verifica que Postgres y Redis estén sanos:

```bash
docker compose ps
```

## Migraciones (Alembic, en apps/api)

Las migraciones corren con el rol dueño del esquema (`DATABASE_MIGRATIONS_URL`); el
runtime de la aplicación (`DATABASE_URL`) usa `app_role`, que nunca tiene BYPASSRLS.

```bash
cd apps/api
set -a && source ../../.env && set +a
uv run alembic upgrade head
uv run alembic downgrade base   # revertir
```

## Correr tests

Desde la raíz del repo (corre los tests de todas las apps + packages del workspace):

```bash
uv run pytest
```

Con reporte de cobertura:

```bash
uv run pytest --cov-report=term-missing
```

## Linter (ruff — único para todo el monorepo)

```bash
uv run ruff check .
uv run ruff format .
```

## Cobertura de dominio y aplicación (Definition of Done)

CLAUDE.md exige >= 80% de cobertura en `apps/api/src/api/domain` y
`apps/api/src/api/application` para declarar un feature terminado. Este gate
se verifica explícitamente en Fase 6 (Calidad) y Fase 8 (Cierre) — no bloquea
cada push de CI, porque entre iteraciones esas capas pueden no tener código
de negocio todavía:

```bash
./scripts/check_domain_coverage.sh
```

## Tests inmutables (Regla 1 de CLAUDE.md)

Los archivos dentro de cualquier `tests/` son contratos permanentes: no se
modifican ni se borran una vez commiteados (solo se agregan archivos nuevos,
y solo donde el proceso lo autoriza explícitamente). Esto se enforce con:

1. Un hook de pre-commit local — actívalo una vez por clon del repo:
   ```bash
   git config core.hooksPath .githooks
   ```
2. El job `immutable-tests-check` en CI (`.github/workflows/ci.yml`), que
   falla si un push o PR modifica o borra algo dentro de un `tests/`.

Verificación manual:

```bash
./scripts/check_immutable_tests.sh <base-ref> <head-ref>
```

## Proceso de desarrollo (ASDP)

Este proyecto sigue `ASDP-PROCESS.md`. Los slash commands de cada fase viven en
`.claude/commands/` (`/asdp-requirements-1`, `/asdp-design-2`, ... `/asdp-release-9`,
`/asdp-express`). Cada iteración de feature vive en
`specs/iterations/[fecha]-[feature]/MEMORY.md`.
