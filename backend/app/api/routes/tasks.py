from fastapi import APIRouter, Depends, Query

from ..deps import get_current_user
from ...schemas.project import TaskCreate, TaskUpdate
from ...services.project_service import ProjectService
from ...utils.helpers import ok

router = APIRouter(prefix="/tasks", tags=["Tasks"])


@router.get("", summary="List tasks with optional filters")
async def list_tasks(
    project_id: str | None = None,
    status: str | None = None,
    priority: str | None = None,
    search: str | None = None,
    user: dict = Depends(get_current_user),
):
    return ok(await ProjectService().list_tasks(project_id, status, priority, search), "Tasks fetched")


@router.post("", summary="Create a new task")
async def create_task(payload: TaskCreate, user: dict = Depends(get_current_user)):
    data = payload.validate_model()
    return ok(await ProjectService().create_task(data), "Task created")


@router.get("/stats", summary="Task statistics")
async def task_stats(project_id: str | None = None, user: dict = Depends(get_current_user)):
    return ok(await ProjectService().tasks.stats(project_id), "Task statistics fetched")


@router.get("/{task_id}", summary="Get a single task")
async def get_task(task_id: str, user: dict = Depends(get_current_user)):
    return ok(await ProjectService().get_task(task_id), "Task fetched")


@router.put("/{task_id}", summary="Update a task (including status changes)")
async def update_task(task_id: str, payload: TaskUpdate, user: dict = Depends(get_current_user)):
    updates = payload.validate_model()
    return ok(await ProjectService().update_task(task_id, updates), "Task updated")


@router.delete("/{task_id}", summary="Delete a task")
async def delete_task(task_id: str, user: dict = Depends(get_current_user)):
    await ProjectService().delete_task(task_id)
    return ok(None, "Task deleted")