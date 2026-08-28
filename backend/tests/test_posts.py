import pytest
from httpx import AsyncClient


async def make_post(client: AsyncClient, headers: dict, content: str = "Hello world! #weblab") -> dict:
    response = await client.post("/api/posts", json={"content": content}, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.mark.anyio
async def test_create_post(client: AsyncClient, user_a):
    post = await make_post(client, user_a["headers"])
    assert post["content"] == "Hello world! #weblab"
    assert post["author_id"] == user_a["user"]["id"]
    assert post["likes_count"] == 0


@pytest.mark.anyio
async def test_post_length_limit(client: AsyncClient, user_a):
    response = await client.post("/api/posts", json={"content": "x" * 281}, headers=user_a["headers"])
    assert response.status_code == 422
    assert "280" in response.json()["message"]


@pytest.mark.anyio
async def test_post_requires_content(client: AsyncClient, user_a):
    response = await client.post("/api/posts", json={"content": ""}, headers=user_a["headers"])
    assert response.status_code == 422


@pytest.mark.anyio
async def test_edit_delete_own_post(client: AsyncClient, user_a):
    post = await make_post(client, user_a["headers"])
    edited = await client.put(f"/api/posts/{post['id']}", json={"content": "Edited content!"}, headers=user_a["headers"])
    assert edited.status_code == 200
    assert edited.json()["data"]["content"] == "Edited content!"
    deleted = await client.delete(f"/api/posts/{post['id']}", headers=user_a["headers"])
    assert deleted.status_code == 200
    gone = await client.get(f"/api/posts/{post['id']}", headers=user_a["headers"])
    assert gone.status_code == 404


@pytest.mark.anyio
async def test_cannot_edit_others_post(client: AsyncClient, user_a, user_b):
    post = await make_post(client, user_a["headers"])
    response = await client.put(f"/api/posts/{post['id']}", json={"content": "hacked"}, headers=user_b["headers"])
    assert response.status_code == 403
    response = await client.delete(f"/api/posts/{post['id']}", headers=user_b["headers"])
    assert response.status_code == 403


@pytest.mark.anyio
async def test_feed_shows_followed_users_only(client: AsyncClient, user_a, user_b):
    await make_post(client, user_b["headers"], content="B's post, followed stream")
    response = await client.get("/api/posts/feed", headers=user_a["headers"])
    assert response.json()["data"] == []

    # A follows B and B follows A
    await client.post(f"/api/users/{user_b['user']['id']}/follow", headers=user_a["headers"])
    response = await client.get("/api/posts/feed", headers=user_a["headers"])
    assert len(response.json()["data"]) == 1
    assert response.json()["data"][0]["content"] == "B's post, followed stream"


@pytest.mark.anyio
async def test_follow_unfollow_and_lists(client: AsyncClient, user_a, user_b):
    follow = await client.post(f"/api/users/{user_b['user']['id']}/follow", headers=user_a["headers"])
    assert follow.status_code == 200
    followers = await client.get(f"/api/users/{user_b['user']['id']}/followers", headers=user_a["headers"])
    ids = [u["id"] for u in followers.json()["data"]]
    assert user_a["user"]["id"] in ids
    following = await client.get(f"/api/users/{user_a['user']['id']}/following", headers=user_a["headers"])
    assert user_b["user"]["id"] in [u["id"] for u in following.json()["data"]]

    unfollow = await client.delete(f"/api/users/{user_b['user']['id']}/follow", headers=user_a["headers"])
    assert unfollow.status_code == 200
    followers = await client.get(f"/api/users/{user_b['user']['id']}/followers", headers=user_a["headers"])
    assert user_a["user"]["id"] not in [u["id"] for u in followers.json()["data"]]


@pytest.mark.anyio
async def test_cannot_follow_self(client: AsyncClient, user_a):
    response = await client.post(f"/api/users/{user_a['user']['id']}/follow", headers=user_a["headers"])
    assert response.status_code == 400
    assert response.json()["error"] == "SELF_FOLLOW"


@pytest.mark.anyio
async def test_like_and_unlike_post(client: AsyncClient, user_a, user_b):
    post = await make_post(client, user_a["headers"])
    liked = await client.post(f"/api/posts/{post['id']}/like", headers=user_b["headers"])
    assert liked.status_code == 200
    assert liked.json()["data"]["liked"] is True
    assert liked.json()["data"]["likes_count"] == 1
    post_detail = await client.get(f"/api/posts/{post['id']}", headers=user_b["headers"])
    assert post_detail.json()["data"]["liked_by_me"] is True
    unliked = await client.delete(f"/api/posts/{post['id']}/like", headers=user_b["headers"])
    assert unliked.json()["data"]["likes_count"] == 0


@pytest.mark.anyio
async def test_search_users(client: AsyncClient, user_a, user_b):
    response = await client.get("/api/users/search?q=Test", headers=user_a["headers"])
    emails = [u["email"] for u in response.json()["data"]]
    assert "user_b@test.com" in emails
    assert "user_a@test.com" not in emails


@pytest.mark.anyio
async def test_user_profile_stats(client: AsyncClient, user_a, user_b):
    await make_post(client, user_a["headers"])
    response = await client.get(f"/api/users/{user_a['user']['id']}", headers=user_b["headers"])
    assert response.status_code == 200
    stats = response.json()["data"]["stats"]
    assert stats["posts"] == 1