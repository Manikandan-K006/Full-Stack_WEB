from fastapi import APIRouter, Depends, Query

from ..deps import get_current_user
from ...schemas.classified import ListingCreate, ListingUpdate
from ...services.classified_service import ClassifiedService
from ...utils.helpers import ok

router = APIRouter(prefix="/listings", tags=["Classifieds"])


@router.get("", summary="List available listings with search, filters and sorting")
async def list_listings(
    search: str | None = None,
    category: str | None = None,
    condition: str | None = None,
    min_price: float | None = Query(default=None, ge=0),
    max_price: float | None = Query(default=None, ge=0),
    location: str | None = None,
    sort: str = Query(default="created_at", description="created_at, price or title"),
    direction: str = Query(default="desc", description="asc or desc"),
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=30, ge=1, le=100),
    user: dict = Depends(get_current_user),
):
    items = await ClassifiedService().list_listings(
        search, category, condition, min_price, max_price, location, sort, direction, skip, limit
    )
    return ok(items, "Listings fetched")


@router.post("", summary="Create a new listing")
async def create_listing(payload: ListingCreate, user: dict = Depends(get_current_user)):
    data = payload.validate_model()
    return ok(await ClassifiedService().create(user["id"], data), "Listing created successfully")


@router.get("/mine", summary="My listings")
async def my_listings(user: dict = Depends(get_current_user)):
    return ok(await ClassifiedService().my_listings(user["id"]), "My listings fetched")


@router.get("/{listing_id}", summary="Get listing details")
async def get_listing(listing_id: str, user: dict = Depends(get_current_user)):
    return ok(await ClassifiedService().get(listing_id), "Listing fetched")


@router.put("/{listing_id}", summary="Edit your own listing")
async def update_listing(listing_id: str, payload: ListingUpdate, user: dict = Depends(get_current_user)):
    updates = payload.validate_model()
    return ok(await ClassifiedService().update(user["id"], listing_id, updates), "Listing updated")


@router.delete("/{listing_id}", summary="Delete your own listing")
async def delete_listing(listing_id: str, user: dict = Depends(get_current_user)):
    await ClassifiedService().delete(user["id"], listing_id)
    return ok(None, "Listing deleted")


@router.put("/{listing_id}/sold", summary="Mark your listing as sold")
async def mark_sold(listing_id: str, user: dict = Depends(get_current_user)):
    return ok(await ClassifiedService().mark_sold(user["id"], listing_id), "Listing marked as sold")


@router.post("/{listing_id}/contact", summary="Contact the seller about a listing")
async def contact_seller(listing_id: str, payload: dict, user: dict = Depends(get_current_user)):
    name = (payload.get("name") or "").strip()
    message = (payload.get("message") or "").strip()
    return ok(await ClassifiedService().contact_seller(user["id"], listing_id, name, message), "Message sent")