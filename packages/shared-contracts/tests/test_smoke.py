"""Test de humo: prueba que la tubería pytest funciona para este paquete."""

import shared_contracts


def test_package_imports():
    assert shared_contracts.__all__ == []
