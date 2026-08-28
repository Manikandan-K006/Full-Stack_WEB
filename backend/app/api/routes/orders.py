from fastapi import APIRouter, Depends, Query

from ..deps import get_current_admin, get_current_user
from ...schemas.food import OrderCreate
from ...services.food_service import FoodService
from ...utils.errors import NotFoundException
from ...utils.helpers import ok

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("", summary="Place an order")
async def place_order(payload: OrderCreate, user: dict = Depends(get_current_user)):
    order = await FoodService().place_order(
        user["id"],
        payload.restaurant_id,
        [{"food_item_id": i.food_item_id, "quantity": i.quantity} for i in payload.items],
        payload.address_id,
        payload.payment_method,
    )
    return ok(order, "Order placed successfully")


@router.get("", summary="List the current user's orders")
async def list_orders(status: str | None = None, user: dict = Depends(get_current_user)):
    return ok(await FoodService().list_orders(user["id"], status), "Orders fetched")


@router.get("/{order_id}", summary="Get order details")
async def get_order(order_id: str, user: dict = Depends(get_current_user)):
    return ok(await FoodService().get_order(user["id"], order_id), "Order fetched")


admin_router = APIRouter(prefix="/admin/orders", tags=["Orders (Admin)"], dependencies=[Depends(get_current_admin)])


@admin_router.get("", summary="[Admin] List all orders")
async def admin_list_orders(status: str | None = None):
    from ...repositories.food_repo import OrderRepository
    repo = OrderRepository()
    query = {}
    if status:
        query["status"] = status
    return ok(await repo.collection.find(query).sort("created_at", -1).to_list(length=500), "Orders fetched")


@admin_router.put("/{order_id}/status", summary="[Admin] Update order status")
async def update_order_status(order_id: str, status: str = Query(...)):
    updated = await FoodService().update_order_status(order_id, status.upper())
    if updated is None:
        raise NotFoundException("Order not found", "ORDER_NOT_FOUND")
    return ok(updated, f"Order status updated to {status.upper()}")