from ..repositories.food_repo import (
    AddressRepository, CartRepository, FoodItemRepository, OrderRepository,
    RestaurantRepository, ReviewRepository,
)
from ..utils.errors import BadRequestException, ConflictException, NotFoundException
from ..utils.helpers import parse_object_id, utc_now_iso

ORDER_STATUSES = ("PLACED", "CONFIRMED", "PREPARING", "OUT_FOR_DELIVERY", "DELIVERED", "CANCELLED")


class FoodService:
    def __init__(self):
        self.restaurants = RestaurantRepository()
        self.food = FoodItemRepository()
        self.carts = CartRepository()
        self.addresses = AddressRepository()
        self.orders = OrderRepository()
        self.reviews = ReviewRepository()

    # Restaurants -----------------------------------------------------------
    async def list_restaurants(self, search, cuisine, city, min_rating, sort, skip, limit) -> list[dict]:
        restaurants = await self.restaurants.list_all(
            search=search, cuisine=cuisine, city=city, min_rating=min_rating,
            sort=sort, skip=skip, limit=limit,
        )
        for r in restaurants:
            r["rating"] = r.get("rating", 0.0)
            r["rating_count"] = r.get("rating_count", 0)
        return restaurants

    async def get_restaurant(self, restaurant_id: str) -> dict:
        oid = parse_object_id(restaurant_id, "restaurant id")
        restaurant = await self.restaurants.find_by_id(oid)
        if restaurant is None:
            raise NotFoundException("Restaurant not found", "RESTAURANT_NOT_FOUND")
        restaurant["rating"] = restaurant.get("rating", 0.0)
        restaurant["rating_count"] = restaurant.get("rating_count", 0)
        return restaurant

    async def restaurant_menu(self, restaurant_id: str, category: str | None) -> dict:
        oid = parse_object_id(restaurant_id, "restaurant id")
        restaurant = await self.restaurants.find_by_id(oid)
        if restaurant is None:
            raise NotFoundException("Restaurant not found", "RESTAURANT_NOT_FOUND")
        items = await self.food.list_by_restaurant(str(oid), category)
        return {"restaurant": restaurant, "items": items}

    # Cart ----------------------------------------------------------------
    async def get_cart(self, user_id: str) -> dict:
        cart = await self.carts.get_cart(user_id)
        if cart is None:
            return {"restaurant_id": None, "items": [], "total": 0.0}
        items = []
        for item in cart.get("items", []):
            food = await self.food.find_by_id(parse_object_id(item["food_item_id"], "food item id"))
            if food:
                items.append({**item, "food_item": food, "subtotal": round(food["price"] * item["quantity"], 2)})
        total = round(sum(i["subtotal"] for i in items), 2)
        return {"restaurant_id": cart.get("restaurant_id"), "items": items, "total": total}

    async def add_to_cart(self, user_id: str, restaurant_id: str, food_item_id: str, quantity: int) -> dict:
        rid = parse_object_id(restaurant_id, "restaurant id")
        fid = parse_object_id(food_item_id, "food item id")
        restaurant = await self.restaurants.find_by_id(rid)
        if restaurant is None:
            raise NotFoundException("Restaurant not found", "RESTAURANT_NOT_FOUND")
        food = await self.food.find_by_id(fid)
        if food is None or food.get("restaurant_id") != str(rid):
            raise NotFoundException("Food item not found in this restaurant", "FOOD_NOT_FOUND")
        if not food.get("is_available", True):
            raise BadRequestException("This item is currently unavailable", "ITEM_UNAVAILABLE")

        cart = await self.carts.get_cart(user_id)
        items = []
        if cart and cart.get("restaurant_id") and cart["restaurant_id"] != str(rid):
            items = []
        elif cart:
            items = cart.get("items", [])

        found = False
        for item in items:
            if item["food_item_id"] == str(fid):
                item["quantity"] = min(item["quantity"] + quantity, 50)
                found = True
                break
        if not found:
            items.append({"food_item_id": str(fid), "quantity": quantity})

        total = 0.0
        for item in items:
            f = await self.food.find_by_id(parse_object_id(item["food_item_id"], "food item id"))
            if f:
                total += f["price"] * item["quantity"]
        cart = await self.carts.upsert_cart(user_id, items, str(rid), round(total, 2))
        return await self.get_cart(user_id)

    async def update_cart_item(self, user_id: str, food_item_id: str, quantity: int) -> dict:
        fid = parse_object_id(food_item_id, "food item id")
        cart = await self.carts.get_cart(user_id)
        if cart is None or not cart.get("items"):
            raise NotFoundException("Cart is empty", "CART_EMPTY")
        items = cart["items"]
        found = False
        for item in items:
            if item["food_item_id"] == str(fid):
                item["quantity"] = quantity
                found = True
        if not found:
            raise NotFoundException("Item not in cart", "ITEM_NOT_IN_CART")
        total = 0.0
        for item in items:
            f = await self.food.find_by_id(parse_object_id(item["food_item_id"], "food item id"))
            if f:
                total += f["price"] * item["quantity"]
        await self.carts.upsert_cart(user_id, items, cart.get("restaurant_id"), round(total, 2))
        return await self.get_cart(user_id)

    async def remove_cart_item(self, user_id: str, food_item_id: str) -> dict:
        fid = parse_object_id(food_item_id, "food item id")
        cart = await self.carts.get_cart(user_id)
        if cart is None or not cart.get("items"):
            raise NotFoundException("Cart is empty", "CART_EMPTY")
        items = [i for i in cart["items"] if i["food_item_id"] != str(fid)]
        if len(items) == len(cart["items"]):
            raise NotFoundException("Item not in cart", "ITEM_NOT_IN_CART")
        total = 0.0
        for item in items:
            f = await self.food.find_by_id(parse_object_id(item["food_item_id"], "food item id"))
            if f:
                total += f["price"] * item["quantity"]
        if not items:
            await self.carts.clear(user_id)
            return {"restaurant_id": None, "items": [], "total": 0.0}
        await self.carts.upsert_cart(user_id, items, cart.get("restaurant_id"), round(total, 2))
        return await self.get_cart(user_id)

    # Addresses -----------------------------------------------------------
    async def list_addresses(self, user_id: str) -> list[dict]:
        return await self.addresses.list_for_user(user_id)

    async def add_address(self, user_id: str, address: dict) -> dict:
        return await self.addresses.create(user_id, address)

    async def delete_address(self, user_id: str, address_id: str) -> None:
        oid = parse_object_id(address_id, "address id")
        address = await self.addresses.find_for_user(oid, user_id)
        if address is None:
            raise NotFoundException("Address not found", "ADDRESS_NOT_FOUND")
        await self.addresses.delete(oid)

    # Orders --------------------------------------------------------------
    async def place_order(self, user_id: str, restaurant_id: str, items: list[dict], address_id: str,
                          payment_method: str) -> dict:
        rid = parse_object_id(restaurant_id, "restaurant id")
        aid = parse_object_id(address_id, "address id")
        restaurant = await self.restaurants.find_by_id(rid)
        if restaurant is None:
            raise NotFoundException("Restaurant not found", "RESTAURANT_NOT_FOUND")
        address = await self.addresses.find_for_user(aid, user_id)
        if address is None:
            raise NotFoundException("Address not found", "ADDRESS_NOT_FOUND")

        order_items = []
        total = 0.0
        for item in items:
            fid = parse_object_id(item["food_item_id"], "food item id")
            food = await self.food.find_by_id(fid)
            if food is None or food.get("restaurant_id") != str(rid):
                raise NotFoundException("Food item not found", "FOOD_NOT_FOUND")
            if not food.get("is_available", True):
                raise BadRequestException(f"{food['name']} is unavailable", "ITEM_UNAVAILABLE")
            subtotal = round(food["price"] * item["quantity"], 2)
            total += subtotal
            order_items.append({
                "food_item_id": str(fid),
                "name": food["name"],
                "price": food["price"],
                "quantity": item["quantity"],
                "subtotal": subtotal,
            })
        total = round(total, 2)
        delivery_fee = restaurant.get("delivery_fee", 0)
        order = {
            "user_id": user_id,
            "restaurant_id": str(rid),
            "restaurant_name": restaurant["name"],
            "items": order_items,
            "subtotal": total,
            "delivery_fee": delivery_fee,
            "total": round(total + delivery_fee, 2),
            "address": {k: address[k] for k in ("label", "full_name", "phone", "address_line", "city", "state", "postal_code") if k in address},
            "payment_method": payment_method.upper() if payment_method else "CASH",
            "status": "PLACED",
            "status_history": [{"status": "PLACED", "at": utc_now_iso(), "note": "Order placed"}],
            "created_at": utc_now_iso(),
        }
        created = await self.orders.create(order)
        await self.carts.clear(user_id)
        return created

    async def list_orders(self, user_id: str, status: str | None) -> list[dict]:
        return await self.orders.list_for_user(user_id, status)

    async def get_order(self, user_id: str, order_id: str) -> dict:
        oid = parse_object_id(order_id, "order id")
        order = await self.orders.find_for_user(oid, user_id)
        if order is None:
            raise NotFoundException("Order not found", "ORDER_NOT_FOUND")
        return order

    async def update_order_status(self, order_id: str, status: str, note: str | None = None) -> dict:
        oid = parse_object_id(order_id, "order id")
        order = await self.orders.find_by_id(oid)
        if order is None:
            raise NotFoundException("Order not found", "ORDER_NOT_FOUND")
        if status not in ORDER_STATUSES:
            raise BadRequestException("Invalid order status", "INVALID_STATUS")
        if order["status"] == "CANCELLED" or order["status"] == "DELIVERED":
            raise ConflictException(f"Order already {order['status'].lower()}", "ORDER_CLOSED")
        history = order.get("status_history", [])
        history.append({"status": status, "at": utc_now_iso(), "note": note or ""})
        return await self.orders.update(oid, {"status": status, "status_history": history})

    # Reviews -------------------------------------------------------------
    async def add_review(self, user_id: str, restaurant_id: str, rating: int, comment: str) -> dict:
        rid = parse_object_id(restaurant_id, "restaurant id")
        restaurant = await self.restaurants.find_by_id(rid)
        if restaurant is None:
            raise NotFoundException("Restaurant not found", "RESTAURANT_NOT_FOUND")
        review = {
            "user_id": user_id,
            "restaurant_id": str(rid),
            "rating": int(rating),
            "comment": comment.strip()[:500],
            "created_at": utc_now_iso(),
        }
        created = await self.reviews.create(review)
        avg = await self.reviews.avg_rating(str(rid))
        count = await self.reviews.for_restaurant(str(rid))
        await self.restaurants.update(rid, {"rating": avg or 0.0, "rating_count": len(count)})
        return created

    async def list_reviews(self, restaurant_id: str) -> list[dict]:
        oid = parse_object_id(restaurant_id, "restaurant id")
        reviews = await self.reviews.for_restaurant(str(oid))
        from ..repositories.users_repo import UserRepository
        user_repo = UserRepository()
        for r in reviews:
            try:
                user = await user_repo.find_by_id(parse_object_id(r["user_id"], "user id"))
                r["reviewer_name"] = user["name"] if user else "Anonymous"
            except Exception:
                r["reviewer_name"] = "Anonymous"
        return reviews