import os

os.environ["MONGODB_URI"] = "mongodb://localhost:27017"
os.environ["DATABASE_NAME"] = "fullstack_web_lab_test"
os.environ["RATE_LIMIT_ENABLED"] = "false"
os.environ["JWT_SECRET"] = "test-secret-for-weblab-tests"

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from app.core.database import close_mongo_connection, connect_to_mongo, get_database
from app.main import app

COLLECTIONS = [
    "users", "todos", "posts", "follows", "likes", "restaurants", "food_items",
    "carts", "orders", "addresses", "reviews", "listings", "favorites", "messages",
    "leave_balances", "leave_requests", "projects", "tasks", "questions",
    "survey_attempts", "survey_answers",
]


@pytest_asyncio.fixture(scope="function")
async def db_session():
    await connect_to_mongo()
    yield
    await close_mongo_connection()


@pytest_asyncio.fixture(autouse=True)
async def clean_db(db_session):
    db = get_database()
    for name in COLLECTIONS:
        await db[name].delete_many({})


@pytest_asyncio.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def register_user(client: AsyncClient, email: str, password: str = "Strong@123", name: str = "Test User"):
    response = await client.post("/api/auth/register", json={"name": name, "email": email, "password": password})
    assert response.status_code == 200, response.text
    return response.json()["data"]


async def auth_client(client: AsyncClient, email: str) -> dict:
    response = await client.post("/api/auth/login", json={"email": email, "password": "Strong@123"})
    assert response.status_code == 200, response.text
    token = response.json()["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def user_a(client: AsyncClient) -> dict:
    data = await register_user(client, "user_a@test.com")
    return {"user": data["user"], "headers": {"Authorization": f"Bearer {data['token']}"}}


@pytest_asyncio.fixture
async def user_b(client: AsyncClient) -> dict:
    data = await register_user(client, "user_b@test.com")
    return {"user": data["user"], "headers": {"Authorization": f"Bearer {data['token']}"}}


@pytest_asyncio.fixture
async def admin(client: AsyncClient) -> dict:
    await register_user(client, "admin@test.com", name="Lab Admin")
    db = get_database()
    await db.users.update_one({"email": "admin@test.com"}, {"$set": {"role": "ADMIN"}})
    response = await client.post("/api/auth/login", json={"email": "admin@test.com", "password": "Strong@123"})
    token = response.json()["data"]["token"]
    return {"user": response.json()["data"]["user"], "headers": {"Authorization": f"Bearer {token}"}}


async def make_restaurant(client: AsyncClient, admin_headers: dict, name: str = "Test Kitchen") -> dict:
    response = await client.post(
        "/api/admin/restaurants",
        json={
            "name": name, "cuisine": "Indian", "city": "Bengaluru", "address": "1 Test Street",
            "phone": "+91 90000 00000", "description": "Test restaurant", "image_url": "",
            "delivery_estimate": 30, "delivery_fee": 20.0,
        },
        headers=admin_headers,
    )
    assert response.status_code == 200, response.text
    return response.json()["data"]


async def make_food(client: AsyncClient, admin_headers: dict, restaurant_id: str, name: str = "Paneer Roll",
                    price: float = 150.0, category: str = "Main Course") -> dict:
    response = await client.post(
        f"/api/admin/restaurants/{restaurant_id}/food",
        json={
            "restaurant_id": restaurant_id, "name": name, "description": "Test item",
            "price": price, "category": category, "image_url": "", "is_vegetarian": True,
            "is_available": True,
        },
        headers=admin_headers,
    )
    assert response.status_code == 200, response.text
    return response.json()["data"]