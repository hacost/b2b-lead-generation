"""Test de humo: prueba que la tubería pytest funciona para este paquete."""

import client_node


def test_package_importable():
    assert client_node.__doc__ is not None
