import logging
from typing import Any

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from .config import settings

logger = logging.getLogger("weblab.database")

_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


async def connect_to_mongo() -> None:
    global _client, _db
    try:
        _client = AsyncIOMotorClient(
            settings.MONGODB_URI,
            serverSelectionTimeoutMS=15000,
            connectTimeoutMS=15000,
            socketTimeoutMS=15000,
            maxPoolSize=50,
            uuidRepresentation="standard",
            tls=True,
            tlsAllowInvalidCertificates=True,
        )
        _db = _client[settings.DATABASE_NAME]
        await _client.admin.command("ping")
        await _ensure_indexes()
        logger.info("MongoDB connected: %s",
                    settings.MONGODB_URI.split("@")[-1] if "@" in settings.MONGODB_URI else settings.MONGODB_URI)
    except Exception as exc:  # pragma: no cover - surfaced via /health
        _client = None
        _db = None
        logger.error("MongoDB connection failed: %s", exc)


async def close_mongo_connection() -> None:
    global _client, _db
    if _client is not None:
        _client.close()
    _client = None
    _db = None


def get_database() -> AsyncIOMotorDatabase:
    if _db is None:
        raise RuntimeError("Database not initialized")
    return _db


async def _ensure_indexes() -> None:
    if _db is None:
        return
    try:
        await _db.users.create_index("email", unique=True)
        await _db.todos.create_index([("user_id", 1), ("created_at", -1)])
        await _db.posts.create_index([("author_id", 1), ("created_at", -1)])
        await _db.posts.create_index([("content", "text")])
        await _db.follows.create_index([("follower_id", 1), ("following_id", 1)], unique=True)
        await _db.likes.create_index([("user_id", 1), ("post_id", 1)], unique=True)
        await _db.restaurants.create_index("name")
        await _db.restaurants.create_index([("cuisine", 1)])
        await _db.food_items.create_index([("restaurant_id", 1), ("category", 1)])
        await _db.carts.create_index("user_id", unique=True)
        await _db.orders.create_index([("user_id", 1), ("created_at", -1)])
        await _db.listings.create_index([("seller_id", 1), ("created_at", -1)])
        await _db.listings.create_index([("category", 1), ("status", 1)])
        await _db.listings.create_index([("title", "text"), ("description", "text")])
        await _db.favorites.create_index([("user_id", 1), ("listing_id", 1)], unique=True)
        await _db.messages.create_index([("sender_id", 1), ("created_at", 1)])
        await _db.leave_balances.create_index("user_id", unique=True)
        await _db.leave_requests.create_index([("user_id", 1), ("created_at", -1)])
        await _db.leave_requests.create_index([("status", 1)])
        await _db.projects.create_index([("owner_id", 1)])
        await _db.tasks.create_index([("project_id", 1), ("created_at", -1)])
        await _db.questions.create_index([("type", 1), ("difficulty", 1)])
        await _db.survey_attempts.create_index([("user_id", 1), ("created_at", -1)])
        logger.info("MongoDB indexes ensured")
    except Exception as exc:
        logger.error("Failed to create indexes: %s", exc)


def serialize_id(document: dict[str, Any] | None) -> dict[str, Any] | None:
    """Convert a Mongo document's _id / ObjectIds to strings for JSON responses."""
    if document is None:
        return None
    result: dict[str, Any] = {}
    for key, value in document.items():
        if key == "_id":
            result["id"] = str(value)
        elif isinstance(value, list):
            result[key] = [str(v) if hasattr(v, "__str__") and v.__class__.__name__ == "ObjectId" else v for v in value]
        else:
            result[key] = value
    return result