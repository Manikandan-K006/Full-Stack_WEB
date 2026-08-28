from pydantic import BaseModel, Field

from ..utils.helpers import validate_priority, validate_required_text, validate_date_string


class TodoCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    category: str | None = Field(default=None, max_length=50)
    priority: str = "MEDIUM"
    due_date: str | None = None

    def validate_model(self) -> dict:
        return {
            "title": validate_required_text(self.title, "Title", 200),
            "description": (self.description or "").strip()[:2000],
            "category": (self.category or "General").strip()[:50] or "General",
            "priority": validate_priority(self.priority, ("LOW", "MEDIUM", "HIGH", "URGENT")),
            "due_date": validate_date_string(self.due_date) if self.due_date else None,
        }


class TodoUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    category: str | None = Field(default=None, max_length=50)
    priority: str | None = None
    due_date: str | None = None
    completed: bool | None = None

    def validate_model(self, current: dict) -> dict:
        updates: dict = {}
        if self.title is not None:
            updates["title"] = validate_required_text(self.title, "Title", 200)
        if self.description is not None:
            updates["description"] = self.description.strip()[:2000]
        if self.category is not None:
            updates["category"] = self.category.strip()[:50] or "General"
        if self.priority is not None:
            updates["priority"] = validate_priority(self.priority, ("LOW", "MEDIUM", "HIGH", "URGENT"))
        if self.due_date is not None:
            updates["due_date"] = validate_date_string(self.due_date) if self.due_date.strip() else None
        if self.completed is not None:
            updates["completed"] = bool(self.completed)
        return updates