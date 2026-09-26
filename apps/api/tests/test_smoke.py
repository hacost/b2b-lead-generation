"""Test de humo: prueba que FastAPI + pytest-asyncio corren en este paquete."""

from api.api.main import app
from fastapi.testclient import TestClient


def test_health_endpoint():
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_asyncio_pipeline_works():
    assert True
