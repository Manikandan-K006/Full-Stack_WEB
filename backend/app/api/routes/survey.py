from fastapi import APIRouter, Depends

from ..deps import get_current_user
from ...schemas.survey import SurveySubmitRequest
from ...services.survey_service import SurveyService
from ...utils.helpers import ok

router = APIRouter(prefix="/survey", tags=["Survey"])


@router.get("/start", summary="Start a new survey with 5 random questions")
async def start_survey(user: dict = Depends(get_current_user)):
    return ok(await SurveyService().start(user["id"]), "Survey started")


@router.post("/submit", summary="Submit answers for a survey attempt")
async def submit_survey(payload: SurveySubmitRequest, user: dict = Depends(get_current_user)):
    result = await SurveyService().submit(
        user["id"], payload.attempt_id, [{"question_id": a.question_id, "answer": a.answer} for a in payload.answers]
    )
    return ok(result, "Survey submitted")


@router.get("/results", summary="View results of a completed attempt, or overall history and stats")
async def survey_results(attempt_id: str | None = None, user: dict = Depends(get_current_user)):
    return ok(await SurveyService().results(user["id"], attempt_id), "Survey results fetched")


@router.get("/history", summary="Previous survey attempts")
async def survey_history(user: dict = Depends(get_current_user)):
    return ok(await SurveyService().results(user["id"], None), "Survey history fetched")