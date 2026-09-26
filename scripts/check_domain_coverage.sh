#!/bin/sh
# Verifica el umbral de cobertura del Definition of Done global de CLAUDE.md:
# >= 80% en código de dominio y aplicación (apps/api/src/api/domain y
# apps/api/src/api/application). Se corre explícitamente en Fase 6 (Auditoría
# de Calidad) y Fase 8 (Cierre de Iteración) — no como gate bloqueante en cada
# push de CI, porque en un repo recién iniciado (o entre iteraciones) esas
# capas pueden no tener código de negocio todavía, y forzar el umbral ahí
# generaría un rojo permanente sin significado.
set -e

cd "$(git rev-parse --show-toplevel)/apps/api"
uv run pytest tests \
    --override-ini="addopts=--import-mode=importlib" \
    --cov=api.domain \
    --cov=api.application \
    --cov-report=term-missing \
    --cov-fail-under=80
