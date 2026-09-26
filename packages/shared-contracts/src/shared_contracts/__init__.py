"""Contratos Pydantic compartidos entre apps del monorepo.

Dependencia de build-time únicamente (ver CLAUDE.md, sección Arquitectura):
cada app fija la versión que necesita al construirse. Ninguna app importa
este paquete como una conexión viva en producción.
"""

__all__: list[str] = []
