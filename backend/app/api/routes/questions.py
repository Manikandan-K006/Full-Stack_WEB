from fastapi import APIRouter, Depends, Query

from ..deps import get_current_admin, get_current_user
from ...schemas.survey import QuestionCreate, QuestionUpdate
from ...services.survey_service import SurveyService
from ...utils.errors import BadRequestException, NotFoundException
from ...utils.helpers import ok, parse_object_id
from ...repositories.survey_repo import QuestionRepository

router = APIRouter(prefix="/questions", tags=["Survey Questions"])


@router.get("", summary="List questions (public metadata)")
async def list_questions(
    qtype: str | None = None,
    difficulty: str | None = None,
    search: str | None = None,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=200),
    user: dict = Depends(get_current_user),
):
    repo = QuestionRepository()
    questions = await repo.list_all(qtype, difficulty, search, skip, limit)
    safe = [{k: v for k, v in q.items() if k != "correct_answer"} for q in questions]
    return ok({"items": safe, "total": await repo.count()}, "Questions fetched")


@router.get("/stats", summary="[Admin] Survey statistics")
async def survey_stats(admin: dict = Depends(get_current_admin)):
    return ok(await SurveyService().admin_stats(), "Survey statistics fetched")


admin_router = APIRouter(prefix="/admin/questions", tags=["Survey Questions (Admin)"], dependencies=[Depends(get_current_admin)])


@admin_router.post("", summary="[Admin] Create a question")
async def create_question(payload: QuestionCreate):
    try:
        data = payload.validate_model()
    except ValueError as exc:
        raise BadRequestException(str(exc), "INVALID_QUESTION")
    return ok(await QuestionRepository().create({**data, "created_at": __import__("datetime")
                                                .datetime.now(__import__("datetime").timezone.utc)
                                                .isoformat(timespec="seconds").replace("+00:00", "Z")}), "Question created")


@admin_router.put("/{question_id}", summary="[Admin] Update a question")
async def update_question(question_id: str, payload: QuestionUpdate):
    oid = parse_object_id(question_id, "question id")
    repo = QuestionRepository()
    current = await repo.find_by_id(oid)
    if current is None:
        raise NotFoundException("Question not found", "QUESTION_NOT_FOUND")
    updates = payload.validate_model(current)
    return ok(await repo.update(oid, updates), "Question updated")


@admin_router.delete("/{question_id}", summary="[Admin] Delete a question")
async def delete_question(question_id: str):
    oid = parse_object_id(question_id, "question id")
    repo = QuestionRepository()
    if not await repo.delete(oid):
        raise NotFoundException("Question not found", "QUESTION_NOT_FOUND")
    return ok(None, "Question deleted")