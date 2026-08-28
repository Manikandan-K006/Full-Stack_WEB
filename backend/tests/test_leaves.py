import pytest
from httpx import AsyncClient


async def apply_leave(client: AsyncClient, headers: dict, leave_type: str = "CASUAL",
                      start: str = "2026-11-10", end: str = "2026-11-12", reason: str = "Going home") -> dict:
    response = await client.post("/api/leaves", json={
        "leave_type": leave_type, "start_date": start, "end_date": end, "reason": reason,
    }, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.mark.anyio
async def test_leave_balance_defaults(client: AsyncClient, user_a):
    response = await client.get("/api/leaves/balance", headers=user_a["headers"])
    assert response.status_code == 200
    balance = response.json()["data"]
    assert balance["casual_leave"] == 12.0
    assert balance["medical_leave"] == 10.0
    assert balance["earned_leave"] == 15.0


@pytest.mark.anyio
async def test_apply_leave_deducts_balance(client: AsyncClient, user_a):
    result = await apply_leave(client, user_a["headers"], leave_type="CASUAL", start="2026-11-10", end="2026-11-12")
    assert result["number_of_days"] == 3
    assert result["status"] == "PENDING"
    assert result["updated_balance"]["casual_leave"] == 9.0
    history = await client.get("/api/leaves", headers=user_a["headers"])
    assert len(history.json()["data"]) == 1
    assert history.json()["data"][0]["employee_name"] == "Test User"


@pytest.mark.anyio
async def test_leave_date_validation(client: AsyncClient, user_a):
    response = await client.post("/api/leaves", json={
        "leave_type": "CASUAL", "start_date": "2026-12-20", "end_date": "2026-12-10", "reason": "Bad dates",
    }, headers=user_a["headers"])
    assert response.status_code == 422
    response = await client.post("/api/leaves", json={
        "leave_type": "NOT_A_TYPE", "start_date": "2026-12-10", "end_date": "2026-12-11", "reason": "Bad type",
    }, headers=user_a["headers"])
    assert response.status_code == 422


@pytest.mark.anyio
async def test_insufficient_balance_rejected(client: AsyncClient, user_a):
    response = await client.post("/api/leaves", json={
        "leave_type": "CASUAL", "start_date": "2026-11-01", "end_date": "2027-01-15", "reason": "Too many days",
    }, headers=user_a["headers"])
    assert response.status_code == 409
    assert response.json()["error"] == "INSUFFICIENT_BALANCE"


@pytest.mark.anyio
async def test_cancel_pending_leave_restores_balance(client: AsyncClient, user_a):
    result = await apply_leave(client, user_a["headers"], start="2026-11-10", end="2026-11-11")
    cancelled = await client.put(f"/api/leaves/{result['id']}/cancel", headers=user_a["headers"])
    assert cancelled.status_code == 200
    assert cancelled.json()["data"]["status"] == "CANCELLED"
    assert cancelled.json()["data"]["updated_balance"]["casual_leave"] == 12.0
    # cannot cancel an already-cancelled request
    again = await client.put(f"/api/leaves/{result['id']}/cancel", headers=user_a["headers"])
    assert again.status_code == 409


@pytest.mark.anyio
async def test_admin_approve_and_reject(client: AsyncClient, user_a, admin):
    result = await apply_leave(client, user_a["headers"], leave_type="MEDICAL", start="2026-11-10", end="2026-11-12")
    approved = await client.put(f"/api/admin/leaves/{result['id']}/approve", json={"remark": "Approved"},
                                headers=admin["headers"])
    assert approved.status_code == 200
    assert approved.json()["data"]["status"] == "APPROVED"

    result2 = await apply_leave(client, user_a["headers"], leave_type="EARNED", start="2026-12-01", end="2026-12-03")
    rejected = await client.put(f"/api/admin/leaves/{result2['id']}/reject", json={"remark": "Conflicts"},
                                headers=admin["headers"])
    assert rejected.status_code == 200
    assert rejected.json()["data"]["status"] == "REJECTED"
    # balance restored on rejection
    balance = await client.get("/api/leaves/balance", headers=user_a["headers"])
    assert balance.json()["data"]["earned_leave"] == 15.0

    # cannot reject a request already approved
    again = await client.put(f"/api/admin/leaves/{result['id']}/reject", headers=admin["headers"])
    assert again.status_code == 409


@pytest.mark.anyio
async def test_admin_sees_all_requests(client: AsyncClient, user_a, user_b, admin):
    await apply_leave(client, user_a["headers"])
    await apply_leave(client, user_b["headers"])
    all_requests = await client.get("/api/admin/leaves", headers=admin["headers"])
    assert len(all_requests.json()["data"]) == 2
    stats = await client.get("/api/admin/leaves/stats", headers=admin["headers"])
    assert stats.json()["data"]["pending"] == 2


@pytest.mark.anyio
async def test_normal_user_cannot_access_admin_leaves(client: AsyncClient, user_a):
    response = await client.get("/api/admin/leaves", headers=user_a["headers"])
    assert response.status_code == 403
    response = await client.put("/api/admin/leaves/some-id/approve", headers=user_a["headers"])
    assert response.status_code == 403


@pytest.mark.anyio
async def test_admin_update_balance(client: AsyncClient, user_a, admin):
    response = await client.put(f"/api/admin/leaves/{user_a['user']['id']}/balance", json={
        "casual_leave": 20, "medical_leave": 5, "earned_leave": 30, "other_leave": 10,
    }, headers=admin["headers"])
    assert response.status_code == 200
    assert response.json()["data"]["casual_leave"] == 20