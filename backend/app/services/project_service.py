from ..repositories.projects_repo import ProjectRepository, TaskRepository
from ..utils.errors import NotFoundException
from ..utils.helpers import parse_object_id, utc_now_iso


class ProjectService:
    def __init__(self):
        self.projects = ProjectRepository()
        self.tasks = TaskRepository()

    async def list_projects_with_stats(self) -> list[dict]:
        projects = await self.projects.list_all()
        for project in projects:
            project["stats"] = await self.tasks.stats(project_id=project["id"])
        return projects

    async def create_project(self, payload: dict) -> dict:
        return await self.projects.create({**payload, "created_at": utc_now_iso()})

    async def update_project(self, project_id: str, payload: dict) -> dict:
        oid = parse_object_id(project_id, "project id")
        project = await self.projects.find_by_id(oid)
        if project is None:
            raise NotFoundException("Project not found", "PROJECT_NOT_FOUND")
        return await self.projects.update(oid, payload)

    async def delete_project(self, project_id: str) -> None:
        oid = parse_object_id(project_id, "project id")
        project = await self.projects.find_by_id(oid)
        if project is None:
            raise NotFoundException("Project not found", "PROJECT_NOT_FOUND")
        await self.projects.delete_with_tasks(oid)

    async def list_tasks(self, project_id, status, priority, search) -> list[dict]:
        return await self.tasks.list_all(project_id, status, priority, search)

    async def create_task(self, payload: dict) -> dict:
        return await self.tasks.create({**payload, "created_at": utc_now_iso(), "updated_at": utc_now_iso()})

    async def get_task(self, task_id: str) -> dict:
        oid = parse_object_id(task_id, "task id")
        task = await self.tasks.find_by_id(oid)
        if task is None:
            raise NotFoundException("Task not found", "TASK_NOT_FOUND")
        return task

    async def update_task(self, task_id: str, payload: dict) -> dict:
        oid = parse_object_id(task_id, "task id")
        task = await self.tasks.find_by_id(oid)
        if task is None:
            raise NotFoundException("Task not found", "TASK_NOT_FOUND")
        return await self.tasks.update(oid, {**payload, "updated_at": utc_now_iso()})

    async def delete_task(self, task_id: str) -> None:
        oid = parse_object_id(task_id, "task id")
        task = await self.tasks.find_by_id(oid)
        if task is None:
            raise NotFoundException("Task not found", "TASK_NOT_FOUND")
        await self.tasks.delete(oid)

    async def dashboard(self) -> dict:
        projects = await self.projects.list_all()
        tasks = await self.tasks.list_all()
        stats = await self.tasks.stats()
        project_ids = [p["id"] for p in projects]
        per_project = await self.tasks.counts_by_project(project_ids)
        return {
            "projects": projects,
            "tasks": tasks,
            "stats": stats,
            "per_project": per_project,
        }