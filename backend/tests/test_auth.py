import pytest
from httpx import AsyncClient


@pytest.mark.anyio
async def test_register_success(client: AsyncClient):
    response = await client.post("/api/auth/register", json={
        "name": "Aarav", "email": "aarav@test.com", "password": "Strong@123",
    })
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["data"]["token"]
    assert body["data"]["user"]["email"] == "aarav@test.com"
    assert body["data"]["user"]["role"] == "USER"


@pytest.mark.anyio
async def test_register_duplicate_email(client: AsyncClient):
    payload = {"name": "Aarav", "email": "dup@test.com", "password": "Strong@123"}
    first = await client.post("/api/auth/register", json=payload)
    second = await client.post("/api/auth/register", json=payload)
    assert first.status_code == 200
    assert second.status_code == 409
    assert second.json()["error"] == "EMAIL_TAKEN"


@pytest.mark.anyio
async def test_register_weak_password(client: AsyncClient):
    response = await client.post("/api/auth/register", json={
        "name": "Aarav", "email": "weak@test.com", "password": "short",
    })
    assert response.status_code == 422
    assert response.json()["success"] is False


@pytest.mark.anyio
async def test_register_invalid_email(client: AsyncClient):
    response = await client.post("/api/auth/register", json={
        "name": "Aarav", "email": "not-an-email", "password": "Strong@123",
    })
    assert response.status_code == 422
    assert response.json()["success"] is False


@pytest.mark.anyio
async def test_login_success(client: AsyncClient):
    await client.post("/api/auth/register", json={
        "name": "Priya", "email": "priya@test.com", "password": "Strong@123",
    })
    response = await client.post("/api/auth/login", json={"email": "priya@test.com", "password": "Strong@123"})
    assert response.status_code == 200
    assert response.json()["data"]["token"]


@pytest.mark.anyio
async def test_login_wrong_password(client: AsyncClient):
    await client.post("/api/auth/register", json={
        "name": "Priya", "email": "priya2@test.com", "password": "Strong@123",
    })
    response = await client.post("/api/auth/login", json={"email": "priya2@test.com", "password": "Wrong@999"})
    assert response.status_code == 401
    assert response.json()["error"] == "INVALID_CREDENTIALS"


@pytest.mark.anyio
async def test_password_not_stored_in_plaintext(client: AsyncClient, user_a):
    from app.core.database import get_database
    db = get_database()
    user_doc = await db.users.find_one({"email": "user_a@test.com"})
    assert user_doc["password_hash"] != "Strong@123"
    assert "Strong@123" not in user_doc["password_hash"]


@pytest.mark.anyio
async def test_me_requires_token(client: AsyncClient):
    response = await client.get("/api/auth/me")
    assert response.status_code == 401
    assert response.json()["error"] == "NO_TOKEN"


@pytest.mark.anyio
async def test_me_with_invalid_token(client: AsyncClient):
    response = await client.get("/api/auth/me", headers={"Authorization": "Bearer not.a.jwt"})
    assert response.status_code == 401
    assert response.json()["error"] == "INVALID_TOKEN"


@pytest.mark.anyio
async def test_me_with_expired_token(client: AsyncClient, user_a):
    import jwt as pyjwt
    from app.core.config import settings
    from datetime import datetime, timedelta, timezone
    expired = pyjwt.encode(
        {"sub": user_a["user"]["id"], "role": "USER", "exp": datetime.now(timezone.utc) - timedelta(minutes=5)},
        settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM,
    )
    response = await client.get("/api/auth/me", headers={"Authorization": f"Bearer {expired}"})
    assert response.status_code == 401
    assert response.json()["error"] == "TOKEN_EXPIRED"


@pytest.mark.anyio
async def test_me_with_valid_token(client: AsyncClient, user_a):
    response = await client.get("/api/auth/me", headers=user_a["headers"])
    assert response.status_code == 200
    assert response.json()["data"]["email"] == "user_a@test.com"


@pytest.mark.anyio
async def test_health(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["success"] is True


@pytest.mark.anyio
async def test_openapi_available(client: AsyncClient):
    response = await client.get("/openapi.json")
    assert response.status_code == 200
    schema = response.json()
    assert "/api/auth/register" in schema["paths"]
    assert "/api/survey/start" in schema["paths"]