from ..repositories.survey_repo import QuestionRepository, SurveyAnswerRepository, SurveyAttemptRepository
from ..utils.errors import BadRequestException, NotFoundException
from ..utils.helpers import parse_object_id, utc_now_iso

SURVEY_SIZE = 5


class SurveyService:
    def __init__(self):
        self.questions = QuestionRepository()
        self.attempts = SurveyAttemptRepository()
        self.answers = SurveyAnswerRepository()

    async def start(self, user_id: str) -> dict:
        total = await self.questions.count()
        if total < SURVEY_SIZE:
            raise BadRequestException(
                f"Not enough questions in the question bank (need {SURVEY_SIZE}, have {total}). Please try again later.",
                "INSUFFICIENT_QUESTIONS",
            )
        questions = await self.questions.random_questions(SURVEY_SIZE)
        attempt = {
            "user_id": user_id,
            "questions": [q["id"] for q in questions],
            "status": "IN_PROGRESS",
            "started_at": utc_now_iso(),
            "completed_at": None,
            "score": None,
            "score_percentage": None,
        }
        created = await self.attempts.create(attempt)
        safe_questions = [
            {k: v for k, v in q.items() if k != "correct_answer"}
            for q in questions
        ]
        return {"attempt_id": created["id"], "questions": safe_questions}

    async def submit(self, user_id: str, attempt_id: str, answers: list[dict]) -> dict:
        oid = parse_object_id(attempt_id, "attempt id")
        attempt = await self.attempts.find_by_id(oid)
        if attempt is None or attempt.get("user_id") != user_id:
            raise NotFoundException("Survey attempt not found", "ATTEMPT_NOT_FOUND")
        if attempt.get("status") == "COMPLETED":
            raise BadRequestException("This survey attempt is already submitted", "ALREADY_SUBMITTED")

        answer_map = {a["question_id"]: a["answer"].strip() for a in answers}
        question_ids = [parse_object_id(q, "question id") for q in attempt["questions"]]

        details = []
        correct = 0
        scored = 0
        for qid in question_ids:
            question = await self.questions.find_by_id(qid)
            if question is None:
                continue
            given = answer_map.get(str(qid), "")
            is_correct = False
            is_scored = question["type"] in ("MCQ", "TRUE_FALSE")
            if is_scored:
                scored += 1
                if given.lower() == question["correct_answer"].lower():
                    is_correct = True
                    correct += 1
            details.append({
                "question_id": str(qid),
                "question_text": question["text"],
                "question_type": question["type"],
                "given_answer": given,
                "correct_answer": question["correct_answer"],
                "is_correct": is_correct,
                "is_scored": is_scored,
                "explanation": question.get("explanation", ""),
            })

        score = correct if scored else 0
        percentage = round(correct / scored * 100, 1) if scored else 0.0
        await self.answers.create_many([
            {
                "attempt_id": str(oid),
                "user_id": user_id,
                **d,
                "created_at": utc_now_iso(),
            }
            for d in details
        ])
        updated = await self.attempts.update(
            oid,
            {
                "status": "COMPLETED",
                "completed_at": utc_now_iso(),
                "score": score,
                "score_percentage": percentage,
                "total_scored": scored,
            },
        )
        return {**updated, "details": details, "score": score, "score_percentage": percentage}

    async def results(self, user_id: str, attempt_id: str | None) -> dict:
        if attempt_id:
            oid = parse_object_id(attempt_id, "attempt id")
            attempt = await self.attempts.find_by_id(oid)
            if attempt is None or attempt.get("user_id") != user_id:
                raise NotFoundException("Survey attempt not found", "ATTEMPT_NOT_FOUND")
            if attempt.get("status") != "COMPLETED":
                raise BadRequestException("Attempt not completed yet", "ATTEMPT_INCOMPLETE")
            details = await self.answers.for_attempt(oid)
            return {**attempt, "details": details}
        history = await self.attempts.list_for_user(user_id)
        completed = [a for a in history if a["status"] == "COMPLETED"]
        stats = {
            "attempts": len(completed),
            "best": max((a["score_percentage"] for a in completed), default=0.0),
            "average": round(sum(a["score_percentage"] for a in completed) / len(completed), 1) if completed else 0.0,
        }
        return {"history": history, "stats": stats}

    async def admin_stats(self) -> dict:
        total_questions = await self.questions.count()
        type_stats = await self.questions.type_stats()
        attempt_stats = await self.attempts.stats()
        return {
            "total_questions": total_questions,
            "question_types": type_stats,
            **attempt_stats,
        }