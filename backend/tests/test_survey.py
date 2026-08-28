import pytest
from httpx import AsyncClient


async def create_questions(client: AsyncClient, admin_headers: dict, count: int = 8) -> list[str]:
    ids = []
    for i in range(count):
        response = await client.post("/api/admin/questions", json={
            "text": f"Sample question number {i}?",
            "type": "MCQ",
            "options": ["Alpha", "Beta", "Gamma"],
            "correct_answer": "Alpha",
            "difficulty": "EASY",
            "explanation": "Because Alpha is correct.",
        }, headers=admin_headers)
        assert response.status_code == 200, response.text
        ids.append(response.json()["data"]["id"])
    return ids


@pytest.mark.anyio
async def test_admin_can_create_question(client: AsyncClient, admin):
    ids = await create_questions(client, admin["headers"], count=2)
    assert len(ids) == 2


@pytest.mark.anyio
async def test_normal_user_cannot_create_questions(client: AsyncClient, user_a):
    response = await client.post("/api/admin/questions", json={
        "text": "Can I create?", "type": "MCQ", "options": ["A", "B"], "correct_answer": "A",
        "difficulty": "EASY",
    }, headers=user_a["headers"])
    assert response.status_code == 403
    assert response.json()["error"] == "FORBIDDEN"


@pytest.mark.anyio
async def test_mcq_validation(client: AsyncClient, admin):
    response = await client.post("/api/admin/questions", json={
        "text": "Bad MCQ", "type": "MCQ", "options": ["OnlyOne"], "correct_answer": "OnlyOne",
        "difficulty": "EASY",
    }, headers=admin["headers"])
    assert response.status_code == 400
    response = await client.post("/api/admin/questions", json={
        "text": "Bad answer", "type": "MCQ", "options": ["A", "B"], "correct_answer": "C",
        "difficulty": "EASY",
    }, headers=admin["headers"])
    assert response.status_code == 400


@pytest.mark.anyio
async def test_question_bank_public_list_hides_answers(client: AsyncClient, user_a, admin):
    await create_questions(client, admin["headers"], count=3)
    response = await client.get("/api/questions", headers=user_a["headers"])
    assert response.status_code == 200
    item = response.json()["data"]["items"][0]
    assert "correct_answer" not in item
    assert "options" in item


@pytest.mark.anyio
async def test_survey_returns_exactly_5_random_questions(client: AsyncClient, user_a, admin):
    await create_questions(client, admin["headers"], count=10)
    attempts = []
    for _ in range(3):
        response = await client.get("/api/survey/start", headers=user_a["headers"])
        assert response.status_code == 200
        data = response.json()["data"]
        assert len(data["questions"]) == 5
        assert "correct_answer" not in data["questions"][0]
        assert len({q["id"] for q in data["questions"]}) == 5
        attempts.append([q["id"] for q in data["questions"]])
    # with 10 questions, 3 attempts are very unlikely to draw identical sets
    assert len({tuple(a) for a in attempts}) >= 2


@pytest.mark.anyio
async def test_survey_needs_enough_questions(client: AsyncClient, user_a, admin):
    await create_questions(client, admin["headers"], count=3)
    response = await client.get("/api/survey/start", headers=user_a["headers"])
    assert response.status_code == 400
    assert response.json()["error"] == "INSUFFICIENT_QUESTIONS"


@pytest.mark.anyio
async def test_survey_submit_scores_mcq(client: AsyncClient, user_a, admin):
    await create_questions(client, admin["headers"], count=6)
    started = (await client.get("/api/survey/start", headers=user_a["headers"])).json()["data"]
    answers = [{"question_id": q["id"], "answer": "Alpha"} for q in started["questions"]]
    submitted = await client.post("/api/survey/submit", json={
        "attempt_id": started["attempt_id"], "answers": answers,
    }, headers=user_a["headers"])
    assert submitted.status_code == 200, submitted.text
    result = submitted.json()["data"]
    assert result["status"] == "COMPLETED"
    assert result["score"] == 5
    assert result["score_percentage"] == 100.0
    assert len(result["details"]) == 5
    assert all(d["is_correct"] for d in result["details"])


@pytest.mark.anyio
async def test_survey_cannot_resubmit(client: AsyncClient, user_a, admin):
    await create_questions(client, admin["headers"], count=6)
    started = (await client.get("/api/survey/start", headers=user_a["headers"])).json()["data"]
    answers = [{"question_id": q["id"], "answer": "Alpha"} for q in started["questions"]]
    await client.post("/api/survey/submit", json={"attempt_id": started["attempt_id"], "answers": answers},
                      headers=user_a["headers"])
    again = await client.post("/api/survey/submit", json={"attempt_id": started["attempt_id"], "answers": answers},
                              headers=user_a["headers"])
    assert again.status_code == 400
    assert again.json()["error"] == "ALREADY_SUBMITTED"


@pytest.mark.anyio
async def test_survey_history_and_stats(client: AsyncClient, user_a, admin):
    await create_questions(client, admin["headers"], count=6)
    for _ in range(2):
        started = (await client.get("/api/survey/start", headers=user_a["headers"])).json()["data"]
        answers = [{"question_id": q["id"], "answer": "Alpha"} for q in started["questions"]]
        await client.post("/api/survey/submit", json={"attempt_id": started["attempt_id"], "answers": answers},
                          headers=user_a["headers"])
    history = await client.get("/api/survey/history", headers=user_a["headers"])
    data = history.json()["data"]
    assert data["stats"]["attempts"] == 2
    assert data["stats"]["average"] == 100.0
    best_id = data["history"][0]["id"]
    results = await client.get(f"/api/survey/results?attempt_id={best_id}", headers=user_a["headers"])
    assert len(results.json()["data"]["details"]) == 5


@pytest.mark.anyio
async def test_cannot_view_others_attempt(client: AsyncClient, user_a, user_b, admin):
    await create_questions(client, admin["headers"], count=6)
    started = (await client.get("/api/survey/start", headers=user_a["headers"])).json()["data"]
    answers = [{"question_id": q["id"], "answer": "Alpha"} for q in started["questions"]]
    await client.post("/api/survey/submit", json={"attempt_id": started["attempt_id"], "answers": answers},
                      headers=user_a["headers"])
    other = await client.get(f"/api/survey/results?attempt_id={started['attempt_id']}", headers=user_b["headers"])
    assert other.status_code == 404
    assert other.json()["error"] == "ATTEMPT_NOT_FOUND"


@pytest.mark.anyio
async def test_admin_question_update_and_delete(client: AsyncClient, admin):
    ids = await create_questions(client, admin["headers"], count=1)
    qid = ids[0]
    updated = await client.put(f"/api/admin/questions/{qid}", json={"text": "Updated question text?"},
                               headers=admin["headers"])
    assert updated.json()["data"]["text"] == "Updated question text?"
    deleted = await client.delete(f"/api/admin/questions/{qid}", headers=admin["headers"])
    assert deleted.status_code == 200
    gone = await client.get("/api/questions", headers=admin["headers"])
    assert gone.json()["data"]["total"] == 0