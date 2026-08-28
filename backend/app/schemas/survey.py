from pydantic import BaseModel, Field

from ..utils.helpers import validate_enum, validate_required_text

QUESTION_TYPES = ("MCQ", "TRUE_FALSE", "SHORT_ANSWER")
DIFFICULTIES = ("EASY", "MEDIUM", "HARD")


class QuestionCreate(BaseModel):
    text: str = Field(min_length=5, max_length=500)
    type: str = "MCQ"
    options: list[str] = Field(default_factory=list, max_length=8)
    correct_answer: str = Field(max_length=300)
    difficulty: str = "MEDIUM"
    explanation: str = Field(default="", max_length=500)

    def validate_model(self) -> dict:
        qtype = validate_enum(self.type, QUESTION_TYPES, "Question type")
        if qtype == "MCQ":
            options = [o.strip() for o in self.options if o and o.strip()]
            if len(options) < 2:
                raise ValueError("MCQ questions require at least 2 options")
            if self.correct_answer.strip() not in options:
                raise ValueError("Correct answer must be one of the options")
        elif qtype == "TRUE_FALSE":
            if self.correct_answer.strip().upper() not in ("TRUE", "FALSE"):
                raise ValueError("Correct answer must be TRUE or FALSE")
        else:
            if not self.correct_answer.strip():
                raise ValueError("Correct answer is required")
        return {
            "text": validate_required_text(self.text, "Question", 500),
            "type": qtype,
            "options": [o.strip() for o in self.options if o and o.strip()][:8],
            "correct_answer": self.correct_answer.strip()[:300],
            "difficulty": validate_enum(self.difficulty, DIFFICULTIES, "Difficulty"),
            "explanation": self.explanation.strip()[:500],
        }


class QuestionUpdate(BaseModel):
    text: str | None = Field(default=None, min_length=5, max_length=500)
    type: str | None = None
    options: list[str] | None = Field(default=None, max_length=8)
    correct_answer: str | None = Field(default=None, max_length=300)
    difficulty: str | None = None
    explanation: str | None = Field(default=None, max_length=500)

    def validate_model(self, current: dict) -> dict:
        updates: dict = {}
        if self.text is not None:
            updates["text"] = validate_required_text(self.text, "Question", 500)
        if self.type is not None:
            updates["type"] = validate_enum(self.type, QUESTION_TYPES, "Question type")
        if self.options is not None:
            updates["options"] = [o.strip() for o in self.options if o and o.strip()][:8]
        if self.correct_answer is not None:
            updates["correct_answer"] = self.correct_answer.strip()[:300]
        if self.difficulty is not None:
            updates["difficulty"] = validate_enum(self.difficulty, DIFFICULTIES, "Difficulty")
        if self.explanation is not None:
            updates["explanation"] = self.explanation.strip()[:500]
        return updates


class SurveyAnswerItem(BaseModel):
    question_id: str = Field(min_length=10, max_length=30)
    answer: str = Field(max_length=500)


class SurveySubmitRequest(BaseModel):
    attempt_id: str = Field(min_length=10, max_length=30)
    answers: list[SurveyAnswerItem] = Field(max_length=50)