from fastapi import APIRouter, Depends

from ..deps import get_current_admin
from ...core.database import get_database
from ...utils.helpers import ok

router = APIRouter(prefix="/admin/stats", tags=["Admin"], dependencies=[Depends(get_current_admin)])


@router.get("", summary="[Admin] Overall application statistics")
async def app_stats():
    db = get_database()
    collections = [
        "users", "todos", "posts", "follows", "likes", "restaurants", "food_items",
        "carts", "orders", "addresses", "reviews", "listings", "favorites", "messages",
        "leave_balances", "leave_requests", "projects", "tasks", "questions",
        "survey_attempts", "survey_answers",
    ]
    counts: dict[str, int] = {}
    for name in collections:
        try:
            counts[name] = await db[name].count_documents({})
        except Exception:
            counts[name] = 0
    return ok(counts, "Application statistics")