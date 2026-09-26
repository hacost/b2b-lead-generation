"""Test de humo: prueba que la tubería pytest funciona para este paquete."""

import channels_service


def test_package_importable():
    assert channels_service.__doc__ is not None
