from ..repositories.leaves_repo import LeaveBalanceRepository, LeaveRequestRepository
from ..repositories.users_repo import UserRepository
from ..utils.errors import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from ..utils.helpers import count_days, parse_object_id, utc_now_iso

BALANCE_FIELDS = ("casual_leave", "medical_leave", "earned_leave", "other_leave")


class LeaveService:
    def __init__(self):
        self.balances = LeaveBalanceRepository()
        self.requests = LeaveRequestRepository()
        self.users = UserRepository()

    async def get_balance(self, user_id: str) -> dict:
        return await self.balances.get_or_create(user_id)

    async def apply(self, user_id: str, leave_type: str, start_date: str, end_date: str, reason: str) -> dict:
        days = count_days(start_date, end_date)
        if days < 1:
            raise BadRequestException("Leave must be at least 1 day", "INVALID_DATES")
        balance = await self.balances.get_or_create(user_id)
        available = balance.get(leave_type.lower() + "_leave", 0)
        if available < days:
            raise ConflictException(
                f"Insufficient {leave_type.title()} leave balance. Available: {available} day(s), requested: {days}",
                "INSUFFICIENT_BALANCE",
            )
        request = {
            "user_id": user_id,
            "leave_type": leave_type,
            "start_date": start_date,
            "end_date": end_date,
            "number_of_days": days,
            "reason": reason,
            "status": "PENDING",
            "approved_by": None,
            "decision_remark": None,
            "created_at": utc_now_iso(),
        }
        created = await self.requests.create(request)
        updated = await self.balances.update_balance(
            user_id, {leave_type.lower() + "_leave": round(available - days, 1)}
        )
        return {**created, "updated_balance": updated}

    async def my_requests(self, user_id: str, status: str | None) -> list[dict]:
        requests = await self.requests.list_for_user(user_id, status)
        for req in requests:
            req["employee_name"] = (await self._user_name(req["user_id"])) or "Unknown"
        return requests

    async def cancel(self, user_id: str, request_id: str) -> dict:
        oid = parse_object_id(request_id, "leave request id")
        request = await self.requests.find_by_id_for_user(oid, user_id)
        if request is None:
            raise NotFoundException("Leave request not found", "LEAVE_NOT_FOUND")
        if request["status"] != "PENDING":
            raise ConflictException(
                f"Only pending requests can be cancelled (current: {request['status']})", "NOT_CANCELLABLE"
            )
        updated = await self.requests.update(oid, {"status": "CANCELLED", "decision_remark": "Cancelled by employee"})
        balance = await self.balances.get_or_create(user_id)
        field = request["leave_type"].lower() + "_leave"
        await self.balances.update_balance(
            user_id, {field: round(balance.get(field, 0) + request["number_of_days"], 1)}
        )
        return {**updated, "updated_balance": await self.balances.get_or_create(user_id)}

    # Admin operations ----------------------------------------------------
    async def all_requests(self, status: str | None, employee_name: str | None) -> list[dict]:
        requests = await self.requests.list_all(status, employee_name)
        for req in requests:
            req["employee_name"] = (await self._user_name(req["user_id"])) or "Unknown"
        return requests

    async def decide(self, admin_id: str, request_id: str, decision: str, remark: str | None) -> dict:
        oid = parse_object_id(request_id, "leave request id")
        request = await self.requests.find_by_id(oid)
        if request is None:
            raise NotFoundException("Leave request not found", "LEAVE_NOT_FOUND")
        if request["status"] != "PENDING":
            raise ConflictException(f"Request already {request['status'].lower()}", "ALREADY_DECIDED")
        if decision not in ("APPROVED", "REJECTED"):
            raise BadRequestException("Decision must be APPROVED or REJECTED", "INVALID_DECISION")
        updated = await self.requests.update(
            oid,
            {
                "status": decision,
                "approved_by": admin_id,
                "decision_remark": remark or "",
                "decided_at": utc_now_iso(),
            },
        )
        if decision == "REJECTED":
            balance = await self.balances.get_or_create(request["user_id"])
            field = request["leave_type"].lower() + "_leave"
            await self.balances.update_balance(
                request["user_id"], {field: round(balance.get(field, 0) + request["number_of_days"], 1)}
            )
        return updated

    async def stats(self) -> dict:
        return await self.requests.stats_all()

    async def _user_name(self, user_id: str) -> str | None:
        try:
            user = await self.users.find_by_id(parse_object_id(user_id, "user id"))
            return user["name"] if user else None
        except Exception:
            return None