from fastapi import APIRouter, Depends

from ..deps import get_current_user
from ...schemas.project import ProjectCreate, ProjectUpdate
from ...services.project_service import ProjectService
from ...utils.helpers import ok

router = APIRouter(prefix="/projects", tags=["Projects"])


@router.get("", summary="List projects with task statistics")
async def list_projects(user: dict = Depends(get_current_user)):
    return ok(await ProjectService().list_projects_with_stats(), "Projects fetched")


@router.post("", summary="Create a new project")
async def create_project(payload: ProjectCreate, user: dict = Depends(get_current_user)):
    data = payload.validate_model()
    return ok(await ProjectService().create_project(data), "Project created")


@router.put("/{project_id}", summary="Update a project")
async def update_project(project_id: str, payload: ProjectUpdate, user: dict = Depends(get_current_user)):
    updates = {k: v for k, v in payload.model_dump().items() if v is not None}
    return ok(await ProjectService().update_project(project_id, updates), "Project updated")


@router.delete("/{project_id}", summary="Delete a project and its tasks")
async def delete_project(project_id: str, user: dict = Depends(get_current_user)):
    await ProjectService().delete_project(project_id)
    return ok(None, "Project deleted")