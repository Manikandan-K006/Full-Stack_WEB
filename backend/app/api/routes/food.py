from fastapi import APIRouter, Depends

from ..deps import get_current_admin
from ...services.food_service import FoodService
from ...utils.errors import NotFoundException
from ...utils.helpers import ok, parse_object_id
from ...repositories.food_repo import FoodItemRepository

router = APIRouter(prefix="/food", tags=["Food"])


@router.get("/{food_id}", summary="Get food item details")
async def get_food(food_id: str):
    oid = parse_object_id(food_id, "food item id")
    item = await FoodItemRepository().find_by_id(oid)
    if item is None:
        raise NotFoundException("Food item not found", "FOOD_NOT_FOUND")
    return ok(item, "Food item fetched")


@router.put("/{food_id}/availability", summary="[Admin] Toggle food item availability",
            dependencies=[Depends(get_current_admin)])
async def toggle_availability(food_id: str, available: bool = True):
    oid = parse_object_id(food_id, "food item id")
    repo = FoodItemRepository()
    updated = await repo.update(oid, {"is_available": available})
    if updated is None:
        raise NotFoundException("Food item not found", "FOOD_NOT_FOUND")
    return ok(updated, "Availability updated")