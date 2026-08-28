from .base import BaseRepository
from ..core.database import get_database, serialize_id


def get_database_lookup():
    return get_database()


class ListingRepository(BaseRepository):
    def __init__(self):
        super().__init__("listings")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_all(
        self,
        search: str | None = None,
        category: str | None = None,
        condition: str | None = None,
        min_price: float | None = None,
        max_price: float | None = None,
        location: str | None = None,
        sort: str = "created_at",
        direction: str = "desc",
        skip: int = 0,
        limit: int = 50,
    ) -> list[dict]:
        query: dict = {"status": "AVAILABLE"}
        if search:
            query["$or"] = [
                {"title": {"$regex": search, "$options": "i"}},
                {"description": {"$regex": search, "$options": "i"}},
            ]
        if category:
            query["category"] = category.upper().replace(" ", "_")
        if condition:
            query["condition"] = condition.upper().replace(" ", "_")
        if min_price is not None or max_price is not None:
            lower = min_price if min_price is not None else 0
            upper = max_price if max_price is not None else 10**12
            query["price"] = {"$gte": lower, "$lte": upper}
        if location:
            query["location"] = {"$regex": location, "$options": "i"}
        sort_mapping = {
            "price": "price",
            "created_at": "created_at",
            "title": "title",
        }
        sort_key = sort_mapping.get(sort, "created_at")
        cursor = self.collection.find(query).sort(
            sort_key, 1 if direction == "asc" else -1
        ).skip(skip).limit(limit)
        return [serialize_id(doc) for doc in await cursor.to_list(length=limit)]

    async def list_by_seller(self, seller_id, status: str | None = None) -> list[dict]:
        query: dict = {"seller_id": str(seller_id)}
        if status:
            query["status"] = status
        cursor = self.collection.find(query).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=200)]

    async def find_by_id(self, listing_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": listing_id}))

    async def update(self, listing_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": listing_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, listing_id) -> bool:
        result = await self.collection.delete_one({"_id": listing_id})
        return result.deleted_count > 0

    async def count_by_category(self, category: str | None = None) -> int:
        query = {"status": "AVAILABLE"}
        if category:
            query["category"] = category
        return await self.collection.count_documents(query)


class FavoriteRepository(BaseRepository):
    def __init__(self):
        super().__init__("favorites")

    async def add(self, user_id, listing_id) -> bool:
        try:
            await self.collection.insert_one({
                "user_id": str(user_id),
                "listing_id": str(listing_id),
                "created_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
                .isoformat(timespec="seconds").replace("+00:00", "Z"),
            })
            return True
        except Exception:
            return False

    async def remove(self, user_id, listing_id) -> bool:
        result = await self.collection.delete_one({"user_id": str(user_id), "listing_id": str(listing_id)})
        return result.deleted_count > 0

    async def remove_for_listing(self, listing_id) -> None:
        await self.collection.delete_many({"listing_id": str(listing_id)})

    async def ids_for_user(self, user_id) -> list[str]:
        cursor = self.collection.find({"user_id": str(user_id)}, {"listing_id": 1})
        return [doc["listing_id"] for doc in await cursor.to_list(length=1000)]

    async def listings_for_user(self, user_id) -> list[dict]:
        from bson import ObjectId
        favs = []
        cursor = self.collection.find({"user_id": str(user_id)}).sort("created_at", -1).limit(100)
        for fav in await cursor.to_list(length=100):
            if ObjectId.is_valid(fav["listing_id"]):
                favs.append((fav["created_at"], ObjectId(fav["listing_id"])))
        if not favs:
            return []
        oids = [oid for _, oid in favs]
        listing_cursor = get_database_lookup()["listings"].find({"_id": {"$in": oids}})
        by_id = {str(l["_id"]): l for l in await listing_cursor.to_list(length=100)}
        result = []
        for created_at, oid in favs:
            listing = by_id.get(str(oid))
            if listing:
                doc = serialize_id(listing)
                doc["favorited_at"] = created_at
                result.append(doc)
        return result


class MessageRepository(BaseRepository):
    def __init__(self):
        super().__init__("messages")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_for_user(self, user_id) -> list[dict]:
        cursor = self.collection.find(
            {"$or": [{"sender_id": str(user_id)}, {"recipient_id": str(user_id)}]}
        ).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=200)]