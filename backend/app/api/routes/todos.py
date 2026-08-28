from fastapi import APIRouter, Depends, Query

from ..deps import get_current_user
from ...schemas.todo import TodoCreate, TodoUpdate
from ...services.todo_service import TodoService
from ...utils.helpers import ok

router = APIRouter(prefix="/todos", tags=["Todos"])


@router.get("", summary="List the current user's todos with optional filters")
async def list_todos(
    search: str | None = None,
    status: str | None = Query(default=None, description="ALL, PENDING or COMPLETED"),
    category: str | None = None,
    user: dict = Depends(get_current_user),
    service: TodoService = Depends(lambda: TodoService()),
):
    items = await service.list(user["id"], search, status, category)
    stats = await service.stats(user["id"])
    return ok({"items": items, "stats": stats}, "Todos fetched")


@router.post("", summary="Create a new todo")
async def create_todo(payload: TodoCreate, user: dict = Depends(get_current_user),
                      service: TodoService = Depends(lambda: TodoService())):
    data = payload.validate_model()
    todo = await service.create(user["id"], data)
    return ok(todo, "Todo created successfully")


@router.get("/stats", summary="Todo statistics for the current user")
async def todo_stats(user: dict = Depends(get_current_user),
                     service: TodoService = Depends(lambda: TodoService())):
    return ok(await service.stats(user["id"]), "Todo statistics")


@router.get("/{todo_id}", summary="Get a single todo")
async def get_todo(todo_id: str, user: dict = Depends(get_current_user),
                   service: TodoService = Depends(lambda: TodoService())):
    return ok(await service.get(user["id"], todo_id), "Todo fetched")


@router.put("/{todo_id}", summary="Update a todo")
async def update_todo(todo_id: str, payload: TodoUpdate, user: dict = Depends(get_current_user),
                      service: TodoService = Depends(lambda: TodoService())):
    current = await service.get(user["id"], todo_id)
    updates = payload.validate_model(current)
    todo = await service.update(user["id"], todo_id, updates)
    return ok(todo, "Todo updated successfully")


@router.delete("/{todo_id}", summary="Delete a todo")
async def delete_todo(todo_id: str, user: dict = Depends(get_current_user),
                      service: TodoService = Depends(lambda: TodoService())):
    await service.delete(user["id"], todo_id)
    return ok(None, "Todo deleted successfully")