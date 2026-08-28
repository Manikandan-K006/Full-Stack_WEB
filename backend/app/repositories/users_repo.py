from .base import BaseRepository
from ..core.database import serialize_id


class UserRepository(BaseRepository):
    def __init__(self):
        super().__init__("users")

    async def create(self, user: dict) -> dict:
        await self.collection.insert_one(user)
        user_id = user.pop("_id")
        return {**user, "id": str(user_id)}

    async def find_by_email(self, email: str) -> dict | None:
        doc = await self.collection.find_one({"email": email})
        return serialize_id(doc)

    async def find_by_id(self, user_id) -> dict | None:
        doc = await self.collection.find_one({"_id": user_id})
        return serialize_id(doc)

    async def update(self, user_id, updates: dict) -> dict | None:
        if not updates:
            return await self.find_by_id(user_id)
        doc = await self.collection.find_one_and_update(
            {"_id": user_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, user_id) -> bool:
        result = await self.collection.delete_one({"_id": user_id})
        return result.deleted_count > 0

    async def list_all(self, search: str | None = None, skip: int = 0, limit: int = 100) -> list[dict]:
        query = {}
        if search:
            query["$or"] = [
                {"email": {"$regex": search, "$options": "i"}},
                {"name": {"$regex": search, "$options": "i"}},
            ]
        cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
        return [serialize_id(doc) for doc in await cursor.to_list(length=limit)]


class TodoRepository(BaseRepository):
    def __init__(self):
        super().__init__("todos")

    async def create(self, todo: dict) -> dict:
        await self.collection.insert_one(todo)
        todo_id = todo.pop("_id")
        return {**todo, "id": str(todo_id)}

    async def list_for_user(
        self, user_id, search: str | None = None, status: str | None = None, category: str | None = None
    ) -> list[dict]:
        query: dict = {"user_id": str(user_id)}
        if search:
            query["$or"] = [
                {"title": {"$regex": search, "$options": "i"}},
                {"description": {"$regex": search, "$options": "i"}},
                {"category": {"$regex": search, "$options": "i"}},
            ]
        if status == "COMPLETED":
            query["completed"] = True
        elif status == "PENDING":
            query["completed"] = False
        if category:
            query["category"] = category
        cursor = self.collection.find(query).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=500)]

    async def find_by_id_for_user(self, todo_id, user_id) -> dict | None:
        doc = await self.collection.find_one({"_id": todo_id, "user_id": str(user_id)})
        return serialize_id(doc)

    async def update(self, todo_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": todo_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, todo_id) -> bool:
        result = await self.collection.delete_one({"_id": todo_id})
        return result.deleted_count > 0

    async def stats(self, user_id) -> dict:
        pipeline = [
            {"$match": {"user_id": str(user_id)}},
            {
                "$group": {
                    "_id": None,
                    "total": {"$sum": 1},
                    "completed": {"$sum": {"$cond": ["$completed", 1, 0]}},
                    "pending": {"$sum": {"$cond": ["$completed", 0, 1]}},
                }
            },
            {"$project": {"_id": 0, "total": 1, "completed": 1, "pending": 1}},
        ]
        rows = await self.collection.aggregate(pipeline).to_list(length=1)
        stats = rows[0] if rows else {"total": 0, "completed": 0, "pending": 0}
        categories = await self.collection.distinct("category", {"user_id": str(user_id)})
        stats["categories"] = sorted(categories, key=str.lower)
        overdue = await self.collection.count_documents(
            {
                "user_id": str(user_id),
                "completed": False,
                "due_date": {"$ne": None, "$lte": __import__("datetime").date.today().isoformat()},
            }
        )
        stats["overdue"] = overdue
        stats["completion_rate"] = round((stats["completed"] / stats["total"] * 100), 1) if stats["total"] else 0.0
        return stats