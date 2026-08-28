from .base import BaseRepository
from ..core.database import serialize_id


class ProjectRepository(BaseRepository):
    def __init__(self):
        super().__init__("projects")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_all(self) -> list[dict]:
        cursor = self.collection.find({}).sort("created_at", 1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=100)]

    async def find_by_id(self, project_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": project_id}))

    async def update(self, project_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": project_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete_with_tasks(self, project_id) -> None:
        await self.collection.delete_one({"_id": project_id})
        from ..core.database import get_database
        await get_database()["tasks"].delete_many({"project_id": str(project_id)})


class TaskRepository(BaseRepository):
    def __init__(self):
        super().__init__("tasks")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def list_all(self, project_id: str | None = None, status: str | None = None,
                       priority: str | None = None, search: str | None = None) -> list[dict]:
        query: dict = {}
        if project_id:
            query["project_id"] = project_id
        if status:
            query["status"] = status
        if priority:
            query["priority"] = priority
        if search:
            query["$or"] = [
                {"title": {"$regex": search, "$options": "i"}},
                {"description": {"$regex": search, "$options": "i"}},
            ]
        cursor = self.collection.find(query).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=1000)]

    async def find_by_id(self, task_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": task_id}))

    async def update(self, task_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": task_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, task_id) -> bool:
        result = await self.collection.delete_one({"_id": task_id})
        return result.deleted_count > 0

    async def delete_many(self, project_id) -> None:
        await self.collection.delete_many({"project_id": project_id})

    async def stats(self, project_id: str | None = None) -> dict:
        query = {"project_id": project_id} if project_id else {}
        pipeline = [
            {"$match": query},
            {"$group": {
                "_id": None,
                "total": {"$sum": 1},
                "completed": {"$sum": {"$cond": [{"$eq": ["$status", "COMPLETED"]}, 1, 0]}},
                "in_progress": {"$sum": {"$cond": [{"$eq": ["$status", "IN_PROGRESS"]}, 1, 0]}},
                "pending": {"$sum": {"$cond": [{"$eq": ["$status", "PENDING"]}, 1, 0]}},
            }},
        ]
        rows = await self.collection.aggregate(pipeline).to_list(length=1)
        stats = rows[0] if rows else {"total": 0, "completed": 0, "in_progress": 0, "pending": 0}
        stats["_id"] = None
        stats.pop("_id", None)
        stats["progress"] = round(stats["completed"] / stats["total"] * 100, 1) if stats["total"] else 0.0
        return stats

    async def counts_by_project(self, project_ids: list[str]) -> dict:
        result: dict = {}
        for pid in project_ids:
            result[str(pid)] = await self.stats(project_id=str(pid))
        return result