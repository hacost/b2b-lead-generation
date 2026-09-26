"""Test de humo: prueba que la tubería pytest funciona para este paquete."""

import admin_panel


def test_package_importable():
    assert admin_panel.__doc__ is not None
