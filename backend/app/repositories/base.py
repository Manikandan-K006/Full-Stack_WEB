from motor.motor_asyncio import AsyncIOMotorCollection

from ..core.database import get_database


class BaseRepository:
    def __init__(self, collection_name: str):
        self.collection_name = collection_name

    @property
    def collection(self) -> AsyncIOMotorCollection:
        return get_database()[self.collection_name]