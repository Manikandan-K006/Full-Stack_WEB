from fastapi import APIRouter, Depends

from ..deps import get_current_user
from ...services.classified_service import ClassifiedService
from ...utils.helpers import ok

router = APIRouter(prefix="/favorites", tags=["Favorites"])


@router.get("", summary="List the current user's favorite listings")
async def my_favorites(user: dict = Depends(get_current_user)):
    return ok(await ClassifiedService().my_favorites(user["id"]), "Favorites fetched")


@router.post("/{listing_id}", summary="Add a listing to favorites")
async def add_favorite(listing_id: str, user: dict = Depends(get_current_user)):
    return ok(await ClassifiedService().toggle_favorite(user["id"], listing_id), "Favorite updated")


@router.delete("/{listing_id}", summary="Remove a listing from favorites")
async def remove_favorite(listing_id: str, user: dict = Depends(get_current_user)):
    return ok(await ClassifiedService().toggle_favorite(user["id"], listing_id), "Favorite updated")


messages_router = APIRouter(prefix="/messages", tags=["Messages"])


@messages_router.get("", summary="List messages sent to or from the current user")
async def my_messages(user: dict = Depends(get_current_user)):
    return ok(await ClassifiedService().my_messages(user["id"]), "Messages fetched")