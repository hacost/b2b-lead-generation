#!/bin/sh
# Enforcement mecánico de la Regla 1 de CLAUDE.md (tests inmutables):
# ningún diff puede MODIFICAR ni BORRAR un archivo dentro de un directorio
# tests/ ya commiteado. Agregar archivos NUEVOS sí está permitido (Fase 5 en
# tests/, Fase 8 en tests/integration/) — ese caso no es M/D, así que el
# filtro --diff-filter=MD nunca lo bloquea.
#
# Uso: scripts/check_immutable_tests.sh <args para "git diff", antes del --}
#   Pre-commit (staged vs HEAD):        check_immutable_tests.sh --cached
#   CI en push (vs commit anterior):    check_immutable_tests.sh HEAD~1 HEAD
#   CI en pull_request (vs base branch): check_immutable_tests.sh origin/main...HEAD
set -e

if [ "$#" -eq 0 ]; then
    echo "uso: check_immutable_tests.sh <args para git diff>" >&2
    exit 2
fi

CHANGED=$(git diff --diff-filter=MD --name-only "$@" -- '**/tests/**' 2>/dev/null || true)

if [ -n "$CHANGED" ]; then
    echo "RECHAZADO: los siguientes archivos de tests/ fueron modificados o borrados:" >&2
    echo "$CHANGED" >&2
    echo "" >&2
    echo "Regla 1 de CLAUDE.md: los tests son contratos inmutables. Si un test" >&2
    echo "parece incorrecto, detente y espera instrucción humana (no lo edites)." >&2
    exit 1
fi

echo "OK: ningún archivo de tests/ fue modificado ni borrado ($*)."
