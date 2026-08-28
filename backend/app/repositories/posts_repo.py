from bson import ObjectId

from .base import BaseRepository
from ..core.database import serialize_id


class PostRepository(BaseRepository):
    def __init__(self):
        super().__init__("posts")

    async def create(self, post: dict) -> dict:
        await self.collection.insert_one(post)
        post_id = post.pop("_id")
        return {**post, "id": str(post_id)}

    async def find_by_id(self, post_id) -> dict | None:
        doc = await self.collection.find_one({"_id": post_id})
        return serialize_id(doc)

    async def update(self, post_id, updates: dict) -> dict | None:
        doc = await self.collection.find_one_and_update(
            {"_id": post_id}, {"$set": updates}, return_document=True
        )
        return serialize_id(doc)

    async def delete(self, post_id) -> bool:
        result = await self.collection.delete_one({"_id": post_id})
        return result.deleted_count > 0

    async def feed(self, author_ids: list[str], skip: int = 0, limit: int = 50) -> list[dict]:
        cursor = (
            self.collection.find({"author_id": {"$in": [str(i) for i in author_ids]}})
            .sort("created_at", -1)
            .skip(skip)
            .limit(limit)
        )
        return [serialize_id(doc) for doc in await cursor.to_list(length=limit)]

    async def by_author(self, author_id, limit: int = 50) -> list[dict]:
        cursor = (
            self.collection.find({"author_id": str(author_id)})
            .sort("created_at", -1)
            .limit(limit)
        )
        return [serialize_id(doc) for doc in await cursor.to_list(length=limit)]

    async def count_by_author(self, author_id) -> int:
        return await self.collection.count_documents({"author_id": str(author_id)})


class FollowRepository(BaseRepository):
    def __init__(self):
        super().__init__("follows")

    async def follow(self, follower_id, following_id) -> bool:
        doc = {
            "follower_id": str(follower_id),
            "following_id": str(following_id),
            "created_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc)
            .isoformat(timespec="seconds").replace("+00:00", "Z"),
        }
        try:
            await self.collection.insert_one(doc)
            return True
        except Exception:
            return False

    async def unfollow(self, follower_id, following_id) -> bool:
        result = await self.collection.delete_one(
            {"follower_id": str(follower_id), "following_id": str(following_id)}
        )
        return result.deleted_count > 0

    async def is_following(self, follower_id, following_id) -> bool:
        return (
            await self.collection.count_documents(
                {"follower_id": str(follower_id), "following_id": str(following_id)}
            )
        ) > 0

    async def following_ids(self, follower_id) -> list[ObjectId]:
        cursor = self.collection.find({"follower_id": str(follower_id)}, {"following_id": 1})
        return [ObjectId(doc["following_id"]) for doc in await cursor.to_list(length=10000)]

    async def follower_ids(self, following_id) -> list[ObjectId]:
        cursor = self.collection.find({"following_id": str(following_id)}, {"follower_id": 1})
        return [ObjectId(doc["follower_id"]) for doc in await cursor.to_list(length=10000)]

    async def counts(self, user_id) -> dict:
        following = await self.collection.count_documents({"follower_id": str(user_id)})
        followers = await self.collection.count_documents({"following_id": str(user_id)})
        return {"following": following, "followers": followers}


class LikeRepository(BaseRepository):
    def __init__(self):
        super().__init__("likes")

    async def like(self, user_id, post_id) -> bool:
        doc = {"user_id": str(user_id), "post_id": str(post_id)}
        try:
            await self.collection.insert_one(doc)
            return True
        except Exception:
            return False

    async def unlike(self, user_id, post_id) -> bool:
        result = await self.collection.delete_one({"user_id": str(user_id), "post_id": str(post_id)})
        return result.deleted_count > 0

    async def count(self, post_id) -> int:
        return await self.collection.count_documents({"post_id": str(post_id)})

    async def has_liked(self, user_id, post_id) -> bool:
        return (
            await self.collection.count_documents({"user_id": str(user_id), "post_id": str(post_id)})
        ) > 0

    async def liked_post_ids(self, user_id, post_ids: list[str]) -> set[str]:
        cursor = self.collection.find({"user_id": str(user_id), "post_id": {"$in": post_ids}}, {"post_id": 1})
        return {doc["post_id"] for doc in await cursor.to_list(length=1000)}