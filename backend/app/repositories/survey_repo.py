from .base import BaseRepository
from ..core.database import serialize_id


class QuestionRepository(BaseRepository):
    def __init__(self):
        super().__init__("questions")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def random_questions(self, count: int = 5) -> list[dict]:
        cursor = self.collection.aggregate([{"$sample": {"size": count}}])
        return [serialize_id(doc) for doc in await cursor.to_list(length=count)]

    async def list_all(self, qtype: str | None = None, difficulty: str | None = None,
                       search: str | None = None, skip: int = 0, limit: int = 100) -> list[dict]:
        query: dict = {}
        if qtype:
            query["type"] = qtype
        if difficulty:
            query["difficulty"] = difficulty
        if search:
            query["text"] = {"$regex": search, "$options": "i"}
        cursor = self.collection.find(query).sort("created_at", -1).skip(skip).limit(limit)
        return [serialize_id(doc) for doc in await cursor.to_list(length=limit)]

    async def find_by_id(self, question_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": question_id}))

    async def update(self, question_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": question_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, question_id) -> bool:
        result = await self.collection.delete_one({"_id": question_id})
        return result.deleted_count > 0

    async def count(self) -> int:
        return await self.collection.count_documents({})

    async def type_stats(self) -> dict:
        pipeline = [{"$group": {"_id": "$type", "count": {"$sum": 1}}}]
        rows = await self.collection.aggregate(pipeline).to_list(length=10)
        return {row["_id"]: row["count"] for row in rows}


class SurveyAttemptRepository(BaseRepository):
    def __init__(self):
        super().__init__("survey_attempts")

    async def create(self, doc: dict) -> dict:
        await self.collection.insert_one(doc)
        doc_id = doc.pop("_id")
        return {**doc, "id": str(doc_id)}

    async def find_by_id(self, attempt_id) -> dict | None:
        return serialize_id(await self.collection.find_one({"_id": attempt_id}))

    async def list_for_user(self, user_id) -> list[dict]:
        cursor = self.collection.find({"user_id": str(user_id)}).sort("created_at", -1)
        return [serialize_id(doc) for doc in await cursor.to_list(length=100)]

    async def update(self, attempt_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": attempt_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def stats(self) -> dict:
        total = await self.collection.count_documents({})
        avg_pipeline = [
            {"$group": {"_id": None, "avg": {"$avg": "$score_percentage"}}},
        ]
        rows = await self.collection.aggregate(avg_pipeline).to_list(length=1)
        avg = round(rows[0]["avg"], 1) if rows else 0.0
        recent = self.collection.find({}).sort("created_at", -1).limit(5)
        return {
            "total_attempts": total,
            "avg_score": avg,
            "recent": [serialize_id(doc) for doc in await recent.to_list(length=5)],
        }


class SurveyAnswerRepository(BaseRepository):
    def __init__(self):
        super().__init__("survey_answers")

    async def create_many(self, docs: list[dict]) -> None:
        if docs:
            await self.collection.insert_many(docs)

    async def for_attempt(self, attempt_id) -> list[dict]:
        cursor = self.collection.find({"attempt_id": str(attempt_id)})
        return [serialize_id(doc) for doc in await cursor.to_list(length=50)]