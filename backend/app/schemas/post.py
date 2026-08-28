from pydantic import BaseModel, Field

from ..utils.errors import ValidationException
from ..utils.helpers import validate_required_text

POST_MAX_LENGTH = 280


class PostCreate(BaseModel):
    content: str = Field(min_length=1)

    def validate_model(self) -> dict:
        content = validate_required_text(self.content, "Content")
        if len(content) > POST_MAX_LENGTH:
            raise ValidationException(
                f"Post content cannot exceed {POST_MAX_LENGTH} characters", "POST_TOO_LONG"
            )
        return {"content": content}


class PostUpdate(BaseModel):
    content: str = Field(min_length=1)

    def validate_model(self) -> dict:
        content = validate_required_text(self.content, "Content")
        if len(content) > POST_MAX_LENGTH:
            raise ValidationException(
                f"Post content cannot exceed {POST_MAX_LENGTH} characters", "POST_TOO_LONG"
            )
        return {"content": content}