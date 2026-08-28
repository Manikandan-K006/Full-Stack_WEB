from fastapi import APIRouter, Depends

from ..deps import get_current_user
from ...schemas.leave import LeaveApplyRequest
from ...services.leave_service import LeaveService
from ...utils.helpers import ok

router = APIRouter(prefix="/leaves", tags=["Leave Management"])


@router.get("/balance", summary="View the current user's leave balance")
async def leave_balance(user: dict = Depends(get_current_user)):
    return ok(await LeaveService().get_balance(user["id"]), "Leave balance fetched")


@router.post("", summary="Apply for leave")
async def apply_leave(payload: LeaveApplyRequest, user: dict = Depends(get_current_user)):
    data = payload.validate_model()
    result = await LeaveService().apply(user["id"], data["leave_type"], data["start_date"], data["end_date"], data["reason"])
    return ok(result, "Leave application submitted")


@router.get("", summary="Leave history of the current user")
async def my_leaves(status: str | None = None, user: dict = Depends(get_current_user)):
    return ok(await LeaveService().my_requests(user["id"], status), "Leave history fetched")


@router.put("/{request_id}/cancel", summary="Cancel a pending leave request")
async def cancel_leave(request_id: str, user: dict = Depends(get_current_user)):
    return ok(await LeaveService().cancel(user["id"], request_id), "Leave request cancelled")