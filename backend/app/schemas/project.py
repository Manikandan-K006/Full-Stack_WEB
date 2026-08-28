from pydantic import BaseModel, Field

from ..utils.helpers import validate_date_string, validate_enum, validate_priority, validate_required_text

STATUSES = ("PENDING", "IN_PROGRESS", "COMPLETED")
PRIORITIES = ("LOW", "MEDIUM", "HIGH", "CRITICAL")


class ProjectCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    description: str = Field(default="", max_length=2000)
    color: str = Field(default="#4f46e5", max_length=20)

    def validate_model(self) -> dict:
        return {
            "name": validate_required_text(self.name, "Name", 100),
            "description": self.description.strip()[:2000],
            "color": self.color.strip()[:20],
        }


class ProjectUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    description: str | None = Field(default=None, max_length=2000)
    color: str | None = Field(default=None, max_length=20)


class TaskCreate(BaseModel):
    project_id: str = Field(min_length=10, max_length=30)
    title: str = Field(min_length=2, max_length=150)
    description: str = Field(default="", max_length=2000)
    priority: str = "MEDIUM"
    status: str = "PENDING"
    due_date: str | None = None
    assigned_to: str | None = Field(default=None, max_length=80)

    def validate_model(self) -> dict:
        return {
            "project_id": validate_required_text(self.project_id, "Project"),
            "title": validate_required_text(self.title, "Title", 150),
            "description": self.description.strip()[:2000],
            "priority": validate_priority(self.priority, PRIORITIES),
            "status": validate_enum(self.status, STATUSES, "Status"),
            "due_date": validate_date_string(self.due_date) if self.due_date else None,
            "assigned_to": (self.assigned_to or "").strip()[:80] or None,
        }


class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=150)
    description: str | None = Field(default=None, max_length=2000)
    priority: str | None = None
    status: str | None = None
    due_date: str | None = None
    assigned_to: str | None = Field(default=None, max_length=80)

    def validate_model(self) -> dict:
        updates: dict = {}
        if self.title is not None:
            updates["title"] = validate_required_text(self.title, "Title", 150)
        if self.description is not None:
            updates["description"] = self.description.strip()[:2000]
        if self.priority is not None:
            updates["priority"] = validate_priority(self.priority, PRIORITIES)
        if self.status is not None:
            updates["status"] = validate_enum(self.status, STATUSES, "Status")
        if self.due_date is not None:
            updates["due_date"] = validate_date_string(self.due_date) if self.due_date.strip() else None
        if self.assigned_to is not None:
            updates["assigned_to"] = self.assigned_to.strip()[:80] or None
        return updates