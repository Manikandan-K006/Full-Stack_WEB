from fastapi import APIRouter, Depends

from ..deps import get_current_admin
from ...schemas.leave import LeaveBalanceUpdateRequest, LeaveDecisionRequest
from ...services.leave_service import LeaveService
from ...utils.helpers import ok, parse_object_id

router = APIRouter(prefix="/admin/leaves", tags=["Leave Management (Admin)"])


@router.get("", summary="[Admin] List all leave requests")
async def all_leave_requests(status: str | None = None, employee: str | None = None,
                             admin: dict = Depends(get_current_admin)):
    return ok(await LeaveService().all_requests(status, employee), "Leave requests fetched")


@router.put("/{request_id}/approve", summary="[Admin] Approve a leave request")
async def approve_leave(request_id: str, payload: LeaveDecisionRequest = LeaveDecisionRequest(),
                        admin: dict = Depends(get_current_admin)):
    updated = await LeaveService().decide(admin["id"], request_id, "APPROVED", payload.remark)
    return ok(updated, "Leave request approved")


@router.put("/{request_id}/reject", summary="[Admin] Reject a leave request")
async def reject_leave(request_id: str, payload: LeaveDecisionRequest = LeaveDecisionRequest(),
                       admin: dict = Depends(get_current_admin)):
    updated = await LeaveService().decide(admin["id"], request_id, "REJECTED", payload.remark)
    return ok(updated, "Leave request rejected")


@router.put("/{user_id}/balance", summary="[Admin] Update an employee's leave balance")
async def update_balance(user_id: str, payload: LeaveBalanceUpdateRequest,
                         admin: dict = Depends(get_current_admin)):
    oid = parse_object_id(user_id, "user id")
    service = LeaveService()
    updated = await service.balances.update_balance(
        str(oid),
        {
            "casual_leave": payload.casual_leave,
            "medical_leave": payload.medical_leave,
            "earned_leave": payload.earned_leave,
            "other_leave": payload.other_leave,
        },
    )
    return ok(updated, "Leave balance updated")


@router.get("/stats", summary="[Admin] Leave statistics")
async def leave_stats(admin: dict = Depends(get_current_admin)):
    return ok(await LeaveService().stats(), "Leave statistics fetched")