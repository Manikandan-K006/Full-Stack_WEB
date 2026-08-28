import pytest
from httpx import AsyncClient


async def make_project(client: AsyncClient, headers: dict, name: str = "Web Lab") -> dict:
    response = await client.post("/api/projects", json={
        "name": name, "description": "Building the lab platform", "color": "#4f46e5",
    }, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()["data"]


async def make_task(client: AsyncClient, headers: dict, project_id: str, title: str = "Write tests",
                    status: str = "PENDING", priority: str = "MEDIUM") -> dict:
    response = await client.post("/api/tasks", json={
        "project_id": project_id, "title": title, "description": "Task description",
        "priority": priority, "status": status, "due_date": "2026-12-31", "assigned_to": "Team",
    }, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.mark.anyio
async def test_project_crud(client: AsyncClient, user_a):
    project = await make_project(client, user_a["headers"])
    assert project["name"] == "Web Lab"
    projects = await client.get("/api/projects", headers=user_a["headers"])
    assert len(projects.json()["data"]) == 1
    assert projects.json()["data"][0]["stats"]["total"] == 0
    updated = await client.put(f"/api/projects/{project['id']}", json={"name": "Renamed Lab"},
                               headers=user_a["headers"])
    assert updated.json()["data"]["name"] == "Renamed Lab"
    deleted = await client.delete(f"/api/projects/{project['id']}", headers=user_a["headers"])
    assert deleted.status_code == 200
    projects = await client.get("/api/projects", headers=user_a["headers"])
    assert projects.json()["data"] == []


@pytest.mark.anyio
async def test_task_create_status_change_and_stats(client: AsyncClient, user_a):
    project = await make_project(client, user_a["headers"])
    task = await make_task(client, user_a["headers"], project["id"], title="Design schema")
    assert task["status"] == "PENDING"
    assert task["priority"] == "MEDIUM"

    moved = await client.put(f"/api/tasks/{task['id']}", json={"status": "IN_PROGRESS"},
                             headers=user_a["headers"])
    assert moved.json()["data"]["status"] == "IN_PROGRESS"
    done = await client.put(f"/api/tasks/{task['id']}", json={"status": "COMPLETED"},
                            headers=user_a["headers"])
    assert done.json()["data"]["status"] == "COMPLETED"

    stats = await client.get(f"/api/tasks/stats?project_id={project['id']}", headers=user_a["headers"])
    data = stats.json()["data"]
    assert data["total"] == 1
    assert data["completed"] == 1
    assert data["progress"] == 100.0

    project_stats = (await client.get("/api/projects", headers=user_a["headers"])).json()["data"][0]["stats"]
    assert project_stats["completed"] == 1


@pytest.mark.anyio
async def test_task_status_validation(client: AsyncClient, user_a):
    project = await make_project(client, user_a["headers"])
    response = await client.post("/api/tasks", json={
        "project_id": project["id"], "title": "Bad status", "description": "x", "priority": "MEDIUM",
        "status": "DONE", "due_date": "2026-12-31",
    }, headers=user_a["headers"])
    assert response.status_code == 422


@pytest.mark.anyio
async def test_task_filters(client: AsyncClient, user_a):
    project = await make_project(client, user_a["headers"])
    await make_task(client, user_a["headers"], project["id"], title="High prio task", status="PENDING", priority="HIGH")
    await make_task(client, user_a["headers"], project["id"], title="Done task", status="COMPLETED", priority="LOW")
    await make_task(client, user_a["headers"], project["id"], title="In progress", status="IN_PROGRESS", priority="MEDIUM")

    pending = (await client.get("/api/tasks?status=PENDING", headers=user_a["headers"])).json()["data"]
    assert len(pending) == 1 and pending[0]["title"] == "High prio task"
    high = (await client.get("/api/tasks?priority=HIGH", headers=user_a["headers"])).json()["data"]
    assert len(high) == 1
    searched = (await client.get("/api/tasks?search=done", headers=user_a["headers"])).json()["data"]
    assert len(searched) == 1


@pytest.mark.anyio
async def test_delete_project_removes_tasks(client: AsyncClient, user_a):
    project = await make_project(client, user_a["headers"])
    await make_task(client, user_a["headers"], project["id"], title="Orphaned soon")
    await client.delete(f"/api/projects/{project['id']}", headers=user_a["headers"])
    tasks = (await client.get("/api/tasks", headers=user_a["headers"])).json()["data"]
    assert tasks == []


@pytest.mark.anyio
async def test_delete_task(client: AsyncClient, user_a):
    project = await make_project(client, user_a["headers"])
    task = await make_task(client, user_a["headers"], project["id"])
    deleted = await client.delete(f"/api/tasks/{task['id']}", headers=user_a["headers"])
    assert deleted.status_code == 200
    gone = await client.get(f"/api/tasks/{task['id']}", headers=user_a["headers"])
    assert gone.status_code == 404