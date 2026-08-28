import pytest
from httpx import AsyncClient

from .conftest import make_food, make_restaurant


async def make_listing(client: AsyncClient, headers: dict, title: str = "Used iPhone 13",
                       price: float = 30000.0, category: str = "MOBILES") -> dict:
    response = await client.post("/api/listings", json={
        "title": title,
        "description": "Used phone in good condition with box and charger.",
        "price": price,
        "category": category,
        "condition": "GOOD",
        "location": "Bengaluru",
        "images": ["https://example.com/phone.jpg"],
    }, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()["data"]


@pytest.mark.anyio
async def test_create_and_list_listings(client: AsyncClient, user_a):
    await make_listing(client, user_a["headers"])
    response = await client.get("/api/listings", headers=user_a["headers"])
    assert response.status_code == 200
    items = response.json()["data"]
    assert len(items) == 1
    assert items[0]["category"] == "MOBILES"
    assert items[0]["seller_name"] == "Test User"


@pytest.mark.anyio
async def test_listing_validation(client: AsyncClient, user_a):
    response = await client.post("/api/listings", json={
        "title": "x", "description": "short", "price": -5, "category": "UNKNOWN", "condition": "BAD",
        "location": "", "images": [],
    }, headers=user_a["headers"])
    assert response.status_code == 422
    assert response.json()["success"] is False


@pytest.mark.anyio
async def test_edit_own_listing(client: AsyncClient, user_a):
    listing = await make_listing(client, user_a["headers"], price=30000.0)
    response = await client.put(f"/api/listings/{listing['id']}", json={"price": 27500.0}, headers=user_a["headers"])
    assert response.status_code == 200
    assert response.json()["data"]["price"] == 27500.0


@pytest.mark.anyio
async def test_user_cannot_modify_another_users_listing(client: AsyncClient, user_a, user_b):
    listing = await make_listing(client, user_a["headers"])
    response = await client.put(f"/api/listings/{listing['id']}", json={"price": 1.0}, headers=user_b["headers"])
    assert response.status_code == 403
    assert response.json()["error"] == "FORBIDDEN"
    delete_response = await client.delete(f"/api/listings/{listing['id']}", headers=user_b["headers"])
    assert delete_response.status_code == 403
    # original listing still intact
    intact = await client.get(f"/api/listings/{listing['id']}", headers=user_a["headers"])
    assert intact.status_code == 200
    assert intact.json()["data"]["price"] == 30000.0


@pytest.mark.anyio
async def test_mark_sold_and_my_listings(client: AsyncClient, user_a):
    listing = await make_listing(client, user_a["headers"])
    sold = await client.put(f"/api/listings/{listing['id']}/sold", headers=user_a["headers"])
    assert sold.json()["data"]["status"] == "SOLD"
    mine = await client.get("/api/listings/mine", headers=user_a["headers"])
    assert len(mine.json()["data"]) == 1
    # sold listings no longer appear in the public list
    public = await client.get("/api/listings", headers=user_a["headers"])
    assert public.json()["data"] == []


@pytest.mark.anyio
async def test_search_filters_and_sort_by_price(client: AsyncClient, user_a, user_b):
    await make_listing(client, user_a["headers"], title="Gaming Laptop", price=65000.0, category="LAPTOPS")
    await make_listing(client, user_b["headers"], title="Cheap Book", price=200.0, category="BOOKS")
    await make_listing(client, user_b["headers"], title="Table", price=3000.0, category="FURNITURE")

    searched = (await client.get("/api/listings?search=laptop", headers=user_a["headers"])).json()["data"]
    assert len(searched) == 1

    by_category = (await client.get("/api/listings?category=books", headers=user_a["headers"])).json()["data"]
    assert len(by_category) == 1
    assert by_category[0]["title"] == "Cheap Book"

    sorted_asc = (await client.get("/api/listings?sort=price&direction=asc", headers=user_a["headers"])).json()["data"]
    prices = [l["price"] for l in sorted_asc]
    assert prices == sorted(prices)

    price_range = (await client.get("/api/listings?min_price=100&max_price=1000", headers=user_a["headers"])).json()["data"]
    assert len(price_range) == 1


@pytest.mark.anyio
async def test_favorites_flow(client: AsyncClient, user_a, user_b):
    listing = await make_listing(client, user_a["headers"])
    add = await client.post(f"/api/favorites/{listing['id']}", headers=user_b["headers"])
    assert add.json()["data"]["favorited"] is True
    favs = await client.get("/api/favorites", headers=user_b["headers"])
    assert len(favs.json()["data"]) == 1
    remove = await client.delete(f"/api/favorites/{listing['id']}", headers=user_b["headers"])
    assert remove.json()["data"]["favorited"] is False
    favs = await client.get("/api/favorites", headers=user_b["headers"])
    assert favs.json()["data"] == []


@pytest.mark.anyio
async def test_contact_seller_and_messages(client: AsyncClient, user_a, user_b):
    listing = await make_listing(client, user_a["headers"])
    response = await client.post(f"/api/listings/{listing['id']}/contact", json={
        "name": "Buyer", "message": "Is this still available? Can you negotiate?",
    }, headers=user_b["headers"])
    assert response.status_code == 200
    seller_messages = await client.get("/api/messages", headers=user_a["headers"])
    assert len(seller_messages.json()["data"]) == 1
    assert seller_messages.json()["data"][0]["listing_title"] == "Used iPhone 13"


@pytest.mark.anyio
async def test_admin_cannot_delete_user_listing_directly(client: AsyncClient, user_a, admin):
    # Even admins can only delete through their own listing ownership
    listing = await make_listing(client, user_a["headers"])
    response = await client.delete(f"/api/listings/{listing['id']}", headers=admin["headers"])
    assert response.status_code == 403