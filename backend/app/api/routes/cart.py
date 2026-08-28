from fastapi import APIRouter, Depends

from ..deps import get_current_user
from ...schemas.food import AddressCreate, CartAddRequest, CartUpdateRequest, ReviewCreate
from ...services.food_service import FoodService
from ...utils.helpers import ok

router = APIRouter(prefix="/cart", tags=["Cart"])


@router.get("", summary="Get the current user's cart")
async def get_cart(user: dict = Depends(get_current_user)):
    return ok(await FoodService().get_cart(user["id"]), "Cart fetched")


@router.post("", summary="Add an item to the cart")
async def add_to_cart(payload: CartAddRequest, user: dict = Depends(get_current_user)):
    cart = await FoodService().add_to_cart(
        user["id"], payload.restaurant_id, payload.food_item_id, payload.quantity
    )
    return ok(cart, "Item added to cart")


@router.put("/{item_id}", summary="Update quantity of a cart item")
async def update_cart_item(item_id: str, payload: CartUpdateRequest, user: dict = Depends(get_current_user)):
    cart = await FoodService().update_cart_item(user["id"], item_id, payload.quantity)
    return ok(cart, "Cart updated")


@router.delete("/{item_id}", summary="Remove an item from the cart")
async def remove_cart_item(item_id: str, user: dict = Depends(get_current_user)):
    cart = await FoodService().remove_cart_item(user["id"], item_id)
    return ok(cart, "Item removed from cart")


address_router = APIRouter(prefix="/addresses", tags=["Addresses"])


@address_router.get("", summary="List the current user's addresses")
async def list_addresses(user: dict = Depends(get_current_user)):
    return ok(await FoodService().list_addresses(user["id"]), "Addresses fetched")


@address_router.post("", summary="Add a delivery address")
async def add_address(payload: AddressCreate, user: dict = Depends(get_current_user)):
    data = payload.validate_model()
    return ok(await FoodService().add_address(user["id"], data), "Address saved")


@address_router.delete("/{address_id}", summary="Delete an address")
async def delete_address(address_id: str, user: dict = Depends(get_current_user)):
    await FoodService().delete_address(user["id"], address_id)
    return ok(None, "Address deleted")


@address_router.post("/{restaurant_id}/review", summary="Rate and review a restaurant")
async def add_review(restaurant_id: str, payload: ReviewCreate, user: dict = Depends(get_current_user)):
    return ok(
        await FoodService().add_review(user["id"], restaurant_id, payload.rating, payload.comment),
        "Review submitted",
    )