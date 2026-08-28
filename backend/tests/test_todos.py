import pytest
from httpx import AsyncClient


async def make_todo(client: AsyncClient, headers: dict, title: str = "Buy groceries",
                    priority: str = "MEDIUM", due_date: str | None = "2026-12-31") -> dict:
    response = await client.post("/api/todos", json={
        "title": title, "description": "Milk and bread", "category": "Personal",
        "priority": priority, "due_date": due_date,
    }, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.mark.anyio
async def test_create_todo(client: AsyncClient, user_a):
    todo = await make_todo(client, user_a["headers"])
    assert todo["title"] == "Buy groceries"
    assert todo["completed"] is False
    assert todo["user_id"] == user_a["user"]["id"]


@pytest.mark.anyio
async def test_create_todo_validation(client: AsyncClient, user_a):
    response = await client.post("/api/todos", json={"title": "", "priority": "NONSENSE"}, headers=user_a["headers"])
    assert response.status_code == 422
    response = await client.post("/api/todos", json={
        "title": "Valid title", "priority": "NONSENSE", "due_date": "not-a-date",
    }, headers=user_a["headers"])
    assert response.status_code == 422
    assert response.json()["success"] is False


@pytest.mark.anyio
async def test_list_todos_scoped_to_user(client: AsyncClient, user_a, user_b):
    await make_todo(client, user_a["headers"], title="A's secret task")
    await make_todo(client, user_b["headers"], title="B's personal task")

    response = await client.get("/api/todos", headers=user_a["headers"])
    items = response.json()["data"]["items"]
    assert len(items) == 1
    assert items[0]["title"] == "A's secret task"


@pytest.mark.anyio
async def test_update_and_complete_todo(client: AsyncClient, user_a):
    todo = await make_todo(client, user_a["headers"])
    response = await client.put(f"/api/todos/{todo['id']}", json={"completed": True, "priority": "HIGH"},
                                headers=user_a["headers"])
    assert response.status_code == 200
    updated = response.json()["data"]
    assert updated["completed"] is True
    assert updated["priority"] == "HIGH"


@pytest.mark.anyio
async def test_user_cannot_access_another_users_todo(client: AsyncClient, user_a, user_b):
    todo = await make_todo(client, user_a["headers"])
    response = await client.get(f"/api/todos/{todo['id']}", headers=user_b["headers"])
    assert response.status_code == 404
    assert response.json()["error"] == "TODO_NOT_FOUND"
    response = await client.put(f"/api/todos/{todo['id']}", json={"completed": True}, headers=user_b["headers"])
    assert response.status_code == 404
    response = await client.delete(f"/api/todos/{todo['id']}", headers=user_b["headers"])
    assert response.status_code == 404
    still = await client.get(f"/api/todos/{todo['id']}", headers=user_a["headers"])
    assert still.status_code == 200


@pytest.mark.anyio
async def test_delete_todo(client: AsyncClient, user_a):
    todo = await make_todo(client, user_a["headers"])
    response = await client.delete(f"/api/todos/{todo['id']}", headers=user_a["headers"])
    assert response.status_code == 200
    gone = await client.get(f"/api/todos/{todo['id']}", headers=user_a["headers"])
    assert gone.status_code == 404


@pytest.mark.anyio
async def test_filter_and_search(client: AsyncClient, user_a):
    await make_todo(client, user_a["headers"], title="Finish report", priority="HIGH", due_date="2026-12-01")
    await make_todo(client, user_a["headers"], title="Clean room", priority="LOW", due_date="2026-12-05")
    # mark one completed
    items = (await client.get("/api/todos", headers=user_a["headers"])).json()["data"]["items"]
    await client.put(f"/api/todos/{items[0]['id']}", json={"completed": True}, headers=user_a["headers"])

    pending = (await client.get("/api/todos?status=PENDING", headers=user_a["headers"])).json()["data"]["items"]
    completed = (await client.get("/api/todos?status=COMPLETED", headers=user_a["headers"])).json()["data"]["items"]
    assert len(pending) == 1 and len(completed) == 1

    searched = (await client.get("/api/todos?search=report", headers=user_a["headers"])).json()["data"]["items"]
    assert len(searched) == 1 and searched[0]["title"] == "Finish report"


@pytest.mark.anyio
async def test_todo_invalid_object_id(client: AsyncClient, user_a):
    response = await client.get("/api/todos/not-a-valid-id", headers=user_a["headers"])
    assert response.status_code == 400
    assert response.json()["error"] == "INVALID_ID"


@pytest.mark.anyio
async def test_todo_stats(client: AsyncClient, user_a):
    await make_todo(client, user_a["headers"], title="One")
    await make_todo(client, user_a["headers"], title="Two")
    response = await client.get("/api/todos/stats", headers=user_a["headers"])
    stats = response.json()["data"]
    assert stats["total"] == 2
    assert stats["completed"] == 0
    assert stats["pending"] == 2
    assert stats["completion_rate"] == 0.0