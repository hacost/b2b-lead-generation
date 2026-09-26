from fastapi import FastAPI

app = FastAPI(title="B2B Lead Generation — Control Plane")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
