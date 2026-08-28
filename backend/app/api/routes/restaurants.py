from fastapi import APIRouter, Depends, Query

from ..deps import get_current_admin
from ...schemas.food import FoodItemCreate, RestaurantCreate
from ...repositories.food_repo import FoodItemRepository, RestaurantRepository
from ...services.food_service import FoodService
from ...utils.errors import NotFoundException
from ...utils.helpers import ok, parse_object_id

router = APIRouter(prefix="/restaurants", tags=["Restaurants"])


@router.get("", summary="List restaurants with search and filters")
async def list_restaurants(
    search: str | None = None,
    cuisine: str | None = None,
    city: str | None = None,
    min_rating: float | None = Query(default=None, ge=0, le=5),
    sort: str = Query(default="name", description="name or rating"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
):
    return ok(await FoodService().list_restaurants(search, cuisine, city, min_rating, sort, skip, limit), "Restaurants fetched")


@router.get("/{restaurant_id}", summary="Get restaurant details")
async def get_restaurant(restaurant_id: str):
    return ok(await FoodService().get_restaurant(restaurant_id), "Restaurant fetched")


@router.get("/{restaurant_id}/menu", summary="Get restaurant menu (optionally filtered by category)")
async def get_menu(restaurant_id: str, category: str | None = None):
    return ok(await FoodService().restaurant_menu(restaurant_id, category), "Menu fetched")


@router.get("/{restaurant_id}/reviews", summary="Get restaurant reviews")
async def get_reviews(restaurant_id: str):
    return ok(await FoodService().list_reviews(restaurant_id), "Reviews fetched")


admin_router = APIRouter(prefix="/admin/restaurants", tags=["Restaurants (Admin)"], dependencies=[Depends(get_current_admin)])


@admin_router.post("", summary="[Admin] Create a restaurant")
async def create_restaurant(payload: RestaurantCreate):
    data = payload.validate_model()
    repo = RestaurantRepository()
    return ok(await repo.create({**data, "rating": 0.0, "rating_count": 0}), "Restaurant created")


@admin_router.put("/{restaurant_id}", summary="[Admin] Update a restaurant")
async def update_restaurant(restaurant_id: str, payload: RestaurantCreate):
    data = payload.validate_model()
    repo = RestaurantRepository()
    oid = parse_object_id(restaurant_id, "restaurant id")
    updated = await repo.update(oid, data)
    if updated is None:
        raise NotFoundException("Restaurant not found", "RESTAURANT_NOT_FOUND")
    return ok(updated, "Restaurant updated")


@admin_router.delete("/{restaurant_id}", summary="[Admin] Delete a restaurant")
async def delete_restaurant(restaurant_id: str):
    repo = RestaurantRepository()
    oid = parse_object_id(restaurant_id, "restaurant id")
    if await repo.delete(oid) is False:
        raise NotFoundException("Restaurant not found", "RESTAURANT_NOT_FOUND")
    return ok(None, "Restaurant deleted")


@admin_router.post("/{restaurant_id}/food", summary="[Admin] Add a food item")
async def create_food(restaurant_id: str, payload: FoodItemCreate):
    data = payload.validate_model()
    repo = FoodItemRepository()
    food = await repo.create(data)
    return ok(food, "Food item created")


@admin_router.put("/food/{food_id}", summary="[Admin] Update a food item")
async def update_food(food_id: str, payload: FoodItemCreate):
    data = payload.validate_model()
    repo = FoodItemRepository()
    oid = parse_object_id(food_id, "food item id")
    updated = await repo.update(oid, data)
    if updated is None:
        raise NotFoundException("Food item not found", "FOOD_NOT_FOUND")
    return ok(updated, "Food item updated")


@admin_router.delete("/food/{food_id}", summary="[Admin] Delete a food item")
async def delete_food(food_id: str):
    repo = FoodItemRepository()
    oid = parse_object_id(food_id, "food item id")
    if await repo.delete(oid) is False:
        raise NotFoundException("Food item not found", "FOOD_NOT_FOUND")
    return ok(None, "Food item deleted")