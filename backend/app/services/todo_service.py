from ..repositories.users_repo import TodoRepository
from ..utils.errors import NotFoundException
from ..utils.helpers import parse_object_id, utc_now_iso


class TodoService:
    def __init__(self):
        self.repo = TodoRepository()

    async def list(self, user_id: str, search: str | None, status: str | None, category: str | None) -> list[dict]:
        return await self.repo.list_for_user(user_id, search, status, category)

    async def create(self, user_id: str, payload: dict) -> dict:
        doc = {
            "user_id": user_id,
            "completed": False,
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
            **payload,
        }
        return await self.repo.create(doc)

    async def get(self, user_id: str, todo_id: str) -> dict:
        oid = parse_object_id(todo_id, "todo id")
        todo = await self.repo.find_by_id_for_user(oid, user_id)
        if todo is None:
            raise NotFoundException("Todo not found", "TODO_NOT_FOUND")
        return todo

    async def update(self, user_id: str, todo_id: str, payload: dict) -> dict:
        oid = parse_object_id(todo_id, "todo id")
        current = await self.repo.find_by_id_for_user(oid, user_id)
        if current is None:
            raise NotFoundException("Todo not found", "TODO_NOT_FOUND")
        updates = {**payload, "updated_at": utc_now_iso()}
        return await self.repo.update(oid, updates)

    async def delete(self, user_id: str, todo_id: str) -> None:
        oid = parse_object_id(todo_id, "todo id")
        current = await self.repo.find_by_id_for_user(oid, user_id)
        if current is None:
            raise NotFoundException("Todo not found", "TODO_NOT_FOUND")
        await self.repo.delete(oid)

    async def stats(self, user_id: str) -> dict:
        return await self.repo.stats(user_id)