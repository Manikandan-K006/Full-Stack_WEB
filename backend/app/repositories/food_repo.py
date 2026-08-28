from .base import BaseRepository
from ..core.database import serialize_id


class RestaurantRepository(BaseRepository):
    def __init__(self):
        super().__init__("restaurants")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_all(
        self, search: str | None = None, cuisine: str | None = None, city: str | None = None,
        min_rating: float | None = None, sort: str = "name", skip: int = 0, limit: int = 100,
    ) -> list[dict]:
        query: dict = {}
        if search:
            query["$or"] = [
                {"name": {"$regex": search, "$options": "i"}},
                {"cuisine": {"$regex": search, "$options": "i"}},
                {"city": {"$regex": search, "$options": "i"}},
            ]
        if cuisine:
            query["cuisine"] = {"$regex": cuisine, "$options": "i"}
        if city:
            query["city"] = {"$regex": city, "$options": "i"}
        if min_rating is not None:
            query["rating"] = {"$gte": min_rating}
        sort_key = "name" if sort == "name" else "rating"
        sort_dir = 1 if sort == "name" else -1
        cursor = self.collection.find(query).sort(sort_key, sort_dir).skip(skip).limit(limit)
        return [serialize_id(doc) for doc in await cursor.to_list(length=limit)]

    async def find_by_id(self, restaurant_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": restaurant_id}))

    async def update(self, restaurant_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": restaurant_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, restaurant_id) -> bool:
        result = await self.collection.delete_one({"_id": restaurant_id})
        return result.deleted_count > 0


class FoodItemRepository(BaseRepository):
    def __init__(self):
        super().__init__("food_items")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_by_restaurant(self, restaurant_id, category: str | None = None) -> list[dict]:
        query = {"restaurant_id": str(restaurant_id)}
        if category:
            query["category"] = {"$regex": category, "$options": "i"}
        cursor = self.collection.find(query).sort("category", 1).sort("name", 1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=500)]

    async def find_by_id(self, food_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": food_id}))

    async def find_many(self, food_ids) -> list[dict]:
        cursor = self.collection.find({"_id": {"$in": food_ids}})
        return [serialize_id(doc) for doc in await cursor.to_list(length=100)]

    async def update(self, food_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": food_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, food_id) -> bool:
        result = await self.collection.delete_one({"_id": food_id})
        return result.deleted_count > 0


class CartRepository(BaseRepository):
    def __init__(self):
        super().__init__("carts")

    async def get_cart(self, user_id) -> dict | None:
        doc = await self.collection.find_one({"user_id": str(user_id)})
        return serialize_id(doc)

    async def upsert_cart(self, user_id, items: list, restaurant_id: str | None, total: float) -> dict:
        doc = {
            "user_id": str(user_id),
            "restaurant_id": restaurant_id,
            "items": items,
            "total": total,
            "updated_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
            .isoformat(timespec="seconds").replace("+00:00", "Z"),
        }
        raw = await self.collection.find_one_and_update(
            {"user_id": str(user_id)}, {"$set": doc}, upsert=True, return_document=True
        )
        return serialize_id(raw)

    async def clear(self, user_id) -> None:
        await self.collection.delete_one({"user_id": str(user_id)})


class AddressRepository(BaseRepository):
    def __init__(self):
        super().__init__("addresses")

    async def create(self, user_id, address: dict) -> dict:
        doc = {**address, "user_id": str(user_id),
               "created_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
               .isoformat(timespec="seconds").replace("+00:00", "Z")}
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_for_user(self, user_id) -> list[dict]:
        cursor = self.collection.find({"user_id": str(user_id)}).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=50)]

    async def find_for_user(self, address_id, user_id) -> dict | None:
        return serialize_id(
            await self.collection.find_one({"_id": address_id, "user_id": str(user_id)})
        )

    async def delete(self, address_id) -> bool:
        result = await self.collection.delete_one({"_id": address_id})
        return result.deleted_count > 0


class OrderRepository(BaseRepository):
    def __init__(self):
        super().__init__("orders")

    async def create(self, order: dict) -> dict:
        await self.collection.insert_one(order)
        order_id = order.pop("_id")
        return {**order, "id": str(order_id)}

    async def list_for_user(self, user_id, status: str | None = None) -> list[dict]:
        query: dict = {"user_id": str(user_id)}
        if status:
            query["status"] = status
        cursor = self.collection.find(query).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=200)]

    async def find_for_user(self, order_id, user_id) -> dict | None:
        return serialize_id(
            await self.collection.find_one({"_id": order_id, "user_id": str(user_id)})
        )

    async def find_by_id(self, order_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": order_id}))

    async def update(self, order_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": order_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)


class ReviewRepository(BaseRepository):
    def __init__(self):
        super().__init__("reviews")

    async def create(self, review: dict) -> dict:
        await self.collection.insert_one(review)
        review_id = review.pop("_id")
        return {**review, "id": str(review_id)}

    async def for_restaurant(self, restaurant_id, limit: int = 50) -> list[dict]:
        cursor = self.collection.find({"restaurant_id": str(restaurant_id)}).sort("created_at", -1).limit(limit)
        return [serialize_id(doc) for doc in await cursor.to_list(length=limit)]

    async def avg_rating(self, restaurant_id) -> float | None:
        pipeline = [
            {"$match": {"restaurant_id": str(restaurant_id)}},
            {"$group": {"_id": None, "avg": {"$avg": "$rating"}, "count": {"$sum": 1}}},
        ]
        rows = await self.collection.aggregate(pipeline).to_list(length=1)
        return round(rows[0]["avg"], 1) if rows else None