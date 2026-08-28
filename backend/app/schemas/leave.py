from pydantic import BaseModel, Field

from ..utils.helpers import validate_date_string, validate_enum

LEAVE_TYPES = ("CASUAL", "MEDICAL", "EARNED", "OTHER")
LEAVE_STATUSES = ("PENDING", "APPROVED", "REJECTED", "CANCELLED")


class LeaveApplyRequest(BaseModel):
    leave_type: str
    start_date: str
    end_date: str
    reason: str = Field(min_length=3, max_length=500)

    def validate_model(self) -> dict:
        return {
            "leave_type": validate_enum(self.leave_type, LEAVE_TYPES, "Leave type"),
            "start_date": validate_date_string(self.start_date, "Start date"),
            "end_date": validate_date_string(self.end_date, "End date"),
            "reason": self.reason.strip()[:500] if self.reason.strip() else "General leave request",
        }


class LeaveDecisionRequest(BaseModel):
    remark: str | None = Field(default=None, max_length=300)


class LeaveBalanceUpdateRequest(BaseModel):
    casual_leave: float = Field(ge=0)
    medical_leave: float = Field(ge=0)
    earned_leave: float = Field(ge=0)
    other_leave: float = Field(ge=0)