import pytest
from httpx import AsyncClient

from .conftest import make_food, make_restaurant


@pytest.mark.anyio
async def test_restaurants_public_listing(client: AsyncClient, admin):
    rest = await make_restaurant(client, admin["headers"])
    listed = await client.get("/api/restaurants")
    assert listed.status_code == 200
    names = [r["name"] for r in listed.json()["data"]]
    assert rest["name"] in names


@pytest.mark.anyio
async def test_restaurant_menu(client: AsyncClient, admin):
    rest = await make_restaurant(client, admin["headers"])
    await make_food(client, admin["headers"], rest["id"])
    response = await client.get(f"/api/restaurants/{rest['id']}/menu")
    assert response.status_code == 200
    assert len(response.json()["data"]["items"]) == 1
    category_filtered = await client.get(f"/api/restaurants/{rest['id']}/menu?category=Pizza")
    assert category_filtered.json()["data"]["items"] == []


@pytest.mark.anyio
async def test_cart_add_update_remove(client: AsyncClient, user_a, admin):
    rest = await make_restaurant(client, admin["headers"])
    food = await make_food(client, admin["headers"], rest["id"], name="Paneer Roll", price=150.0)

    add = await client.post("/api/cart", json={
        "restaurant_id": rest["id"], "food_item_id": food["id"], "quantity": 2,
    }, headers=user_a["headers"])
    assert add.status_code == 200
    cart = add.json()["data"]
    assert cart["total"] == 300.0
    item_id = cart["items"][0]["food_item_id"]

    update = await client.put(f"/api/cart/{item_id}", json={"quantity": 3}, headers=user_a["headers"])
    cart = update.json()["data"]
    assert cart["total"] == 450.0

    remove = await client.delete(f"/api/cart/{item_id}", headers=user_a["headers"])
    assert remove.json()["data"]["items"] == []
    assert remove.json()["data"]["total"] == 0.0


@pytest.mark.anyio
async def test_cart_tracking_restaurant_switch(client: AsyncClient, user_a, admin):
    rest1 = await make_restaurant(client, admin["headers"], name="Kitchen One")
    rest2 = await make_restaurant(client, admin["headers"], name="Kitchen Two")
    f1 = await make_food(client, admin["headers"], rest1["id"], name="Dish One", price=100.0)
    f2 = await make_food(client, admin["headers"], rest2["id"], name="Dish Two", price=200.0)
    await client.post("/api/cart", json={"restaurant_id": rest1["id"], "food_item_id": f1["id"], "quantity": 1},
                      headers=user_a["headers"])
    add2 = await client.post("/api/cart", json={"restaurant_id": rest2["id"], "food_item_id": f2["id"], "quantity": 1},
                             headers=user_a["headers"])
    # switching restaurants clears previous items
    assert len(add2.json()["data"]["items"]) == 1
    assert add2.json()["data"]["items"][0]["food_item"]["name"] == "Dish Two"


@pytest.mark.anyio
async def test_place_order_and_history(client: AsyncClient, user_a, admin):
    rest = await make_restaurant(client, admin["headers"])
    f1 = await make_food(client, admin["headers"], rest["id"], name="Roll", price=100.0)
    f2 = await make_food(client, admin["headers"], rest["id"], name="Fries", price=80.0)
    addr = await client.post("/api/addresses", json={
        "label": "Home", "full_name": "Test User", "phone": "+91 98888 88888",
        "address_line": "42 Main Road", "city": "Bengaluru", "state": "Karnataka", "postal_code": "560001",
    }, headers=user_a["headers"])
    address_id = addr.json()["data"]["id"]

    response = await client.post("/api/orders", json={
        "restaurant_id": rest["id"],
        "items": [{"food_item_id": f1["id"], "quantity": 2}, {"food_item_id": f2["id"], "quantity": 1}],
        "address_id": address_id,
        "payment_method": "CASH",
    }, headers=user_a["headers"])
    assert response.status_code == 200, response.text
    order = response.json()["data"]
    assert order["status"] == "PLACED"
    assert order["subtotal"] == 280.0
    assert order["total"] == 300.0  # + 20 delivery fee
    assert len(order["items"]) == 2

    history = await client.get("/api/orders", headers=user_a["headers"])
    assert len(history.json()["data"]) == 1
    detail = await client.get(f"/api/orders/{order['id']}", headers=user_a["headers"])
    assert detail.status_code == 200


@pytest.mark.anyio
async def test_order_isolation_between_users(client: AsyncClient, user_a, user_b, admin):
    rest = await make_restaurant(client, admin["headers"])
    food = await make_food(client, admin["headers"], rest["id"], name="Roll", price=100.0)
    addr = await client.post("/api/addresses", json={
        "label": "Home", "full_name": "Test User", "phone": "+91 98888 88888",
        "address_line": "42 Main Road", "city": "Bengaluru", "state": "Karnataka", "postal_code": "560001",
    }, headers=user_a["headers"])
    order = await client.post("/api/orders", json={
        "restaurant_id": rest["id"],
        "items": [{"food_item_id": food["id"], "quantity": 1}],
        "address_id": addr.json()["data"]["id"],
        "payment_method": "CASH",
    }, headers=user_a["headers"])
    other = await client.get(f"/api/orders/{order.json()['data']['id']}", headers=user_b["headers"])
    assert other.status_code == 404


@pytest.mark.anyio
async def test_order_empty_cart_after_order(client: AsyncClient, user_a, admin):
    rest = await make_restaurant(client, admin["headers"])
    food = await make_food(client, admin["headers"], rest["id"], name="Roll", price=100.0)
    await client.post("/api/cart", json={"restaurant_id": rest["id"], "food_item_id": food["id"], "quantity": 1},
                      headers=user_a["headers"])
    addr = await client.post("/api/addresses", json={
        "label": "Home", "full_name": "Test User", "phone": "+91 98888 88888",
        "address_line": "42 Main Road", "city": "Bengaluru", "state": "Karnataka", "postal_code": "560001",
    }, headers=user_a["headers"])
    await client.post("/api/orders", json={
        "restaurant_id": rest["id"],
        "items": [{"food_item_id": food["id"], "quantity": 1}],
        "address_id": addr.json()["data"]["id"],
        "payment_method": "CASH",
    }, headers=user_a["headers"])
    cart = (await client.get("/api/cart", headers=user_a["headers"])).json()["data"]
    assert cart["items"] == []


@pytest.mark.anyio
async def test_admin_can_update_order_status(client: AsyncClient, user_a, admin):
    rest = await make_restaurant(client, admin["headers"])
    food = await make_food(client, admin["headers"], rest["id"], name="Roll", price=100.0)
    addr = await client.post("/api/addresses", json={
        "label": "Home", "full_name": "Test User", "phone": "+91 98888 88888",
        "address_line": "42 Main Road", "city": "Bengaluru", "state": "Karnataka", "postal_code": "560001",
    }, headers=user_a["headers"])
    order = (await client.post("/api/orders", json={
        "restaurant_id": rest["id"],
        "items": [{"food_item_id": food["id"], "quantity": 1}],
        "address_id": addr.json()["data"]["id"],
        "payment_method": "CASH",
    }, headers=user_a["headers"])).json()["data"]
    updated = await client.put(f"/api/admin/orders/{order['id']}/status?status=PREPARING", headers=admin["headers"])
    assert updated.status_code == 200
    assert updated.json()["data"]["status"] == "PREPARING"


@pytest.mark.anyio
async def test_normal_user_cannot_access_admin_order_endpoints(client: AsyncClient, user_a):
    response = await client.get("/api/admin/orders", headers=user_a["headers"])
    assert response.status_code == 403
    assert response.json()["error"] == "FORBIDDEN"