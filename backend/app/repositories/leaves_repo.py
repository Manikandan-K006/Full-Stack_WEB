from .base import BaseRepository
from ..core.database import serialize_id

LEAVE_TYPES = ("CASUAL", "MEDICAL", "EARNED", "OTHER")
DEFAULT_BALANCE = {"casual_leave": 12, "medical_leave": 10, "earned_leave": 15, "other_leave": 5}


class LeaveBalanceRepository(BaseRepository):
    def __init__(self):
        super().__init__("leave_balances")

    async def get_or_create(self, user_id) -> dict:
        doc = await self.collection.find_one({"user_id": str(user_id)})
        if doc is None:
            doc = {
                "user_id": str(user_id),
                **DEFAULT_BALANCE,
                "created_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
                .isoformat(timespec="seconds").replace("+00:00", "Z"),
            }
            result = await self.collection.insert_one(doc)
            doc["_id"] = result.inserted_id
        return serialize_id(doc)

    async def update_balance(self, user_id, updates: dict) -> dict:
        defaults = {k: v for k, v in DEFAULT_BALANCE.items() if k not in updates}
        await self.collection.update_one(
            {"user_id": str(user_id)}, {"$set": updates, "$setOnInsert": defaults}, upsert=True
        )
        return await self.get_or_create(user_id)


class LeaveRequestRepository(BaseRepository):
    def __init__(self):
        super().__init__("leave_requests")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_for_user(self, user_id, status: str | None = None) -> list[dict]:
        query: dict = {"user_id": str(user_id)}
        if status:
            query["status"] = status
        cursor = self.collection.find(query).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=200)]

    async def list_all(self, status: str | None = None, employee_name: str | None = None) -> list[dict]:
        query: dict = {}
        if status:
            query["status"] = status
        if employee_name:
            users = await get_database_lookup()["users"].find(
                {"name": {"$regex": employee_name, "$options": "i"}}, {"_id": 1}
            ).to_list(length=1000)
            query["user_id"] = {"$in": [str(u["_id"]) for u in users]}
        cursor = self.collection.find(query).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=500)]

    async def find_by_id(self, request_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": request_id}))

    async def find_by_id_for_user(self, request_id, user_id) -> dict | None:
        return serialize_id(
            await self.collection.find_one({"_id": request_id, "user_id": str(user_id)})
        )

    async def update(self, request_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": request_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def stats_all(self) -> dict:
        pipeline = [
            {"$group": {"_id": "$status", "count": {"$sum": 1}}},
        ]
        rows = await self.collection.aggregate(pipeline).to_list(length=10)
        stats = {row["_id"]: row["count"] for row in rows}
        return {
            "total": sum(stats.values()),
            "pending": stats.get("PENDING", 0),
            "approved": stats.get("APPROVED", 0),
            "rejected": stats.get("REJECTED", 0),
            "cancelled": stats.get("CANCELLED", 0),
        }


def get_database_lookup():
    from ..core.database import get_database
    return get_database()