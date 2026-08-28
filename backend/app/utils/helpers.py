import re
from datetime import date, datetime, timezone
from typing import Any

from bson import ObjectId

from .errors import BadRequestException, NotFoundException, ValidationException

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$")
PASSWORD_MIN = 8


def ok(data: Any = None, message: str = "Success") -> dict:
    return {"success": True, "message": message, "data": data}


def fail(message: str, error_code: str = "ERROR") -> dict:
    return {"success": False, "message": message, "error": error_code}


def parse_object_id(value: str, label: str = "id") -> ObjectId:
    try:
        return ObjectId(value)
    except Exception:
        raise BadRequestException(f"Invalid {label} format", "INVALID_ID")


def require_object(document: dict | None, label: str = "resource") -> dict:
    if document is None:
        raise NotFoundException(f"{label.replace('_', ' ').title()} not found", "NOT_FOUND")
    return document


def validate_email(email: str) -> str:
    email = email.strip().lower()
    if not EMAIL_RE.match(email):
        raise ValidationException("Invalid email address", "INVALID_EMAIL")
    return email


def validate_password(password: str) -> str:
    if len(password) < PASSWORD_MIN:
        raise ValidationException(
            f"Password must be at least {PASSWORD_MIN} characters long", "WEAK_PASSWORD"
        )
    if not re.search(r"[A-Za-z]", password) or not re.search(r"\d", password):
        raise ValidationException(
            "Password must contain at least one letter and one digit", "WEAK_PASSWORD"
        )
    return password


def validate_required_text(value: str | None, label: str, max_length: int | None = None) -> str:
    if value is None or not str(value).strip():
        raise ValidationException(f"{label} is required", "REQUIRED_FIELD")
    value = str(value).strip()
    if max_length and len(value) > max_length:
        raise ValidationException(f"{label} must be at most {max_length} characters", "TOO_LONG")
    return value


def validate_date_string(value: str | None, label: str = "date") -> str:
    if value is None or not str(value).strip():
        raise ValidationException(f"{label} is required", "REQUIRED_FIELD")
    try:
        d = date.fromisoformat(str(value).strip())
        return d.isoformat()
    except ValueError:
        raise ValidationException(f"{label} must be a valid date (YYYY-MM-DD)", "INVALID_DATE")


def validate_price(value: float | None) -> float:
    if value is None:
        raise ValidationException("Price is required", "REQUIRED_FIELD")
    value = float(value)
    if value < 0:
        raise ValidationException("Price cannot be negative", "INVALID_PRICE")
    if value > 99_999_999:
        raise ValidationException("Price is unreasonably large", "INVALID_PRICE")
    return round(value, 2)


def validate_priority(value: str | None, allowed: tuple[str, ...]) -> str:
    if value is None or value.upper() not in allowed:
        raise ValidationException(
            f"Priority must be one of: {', '.join(a.title() for a in allowed)}", "INVALID_PRIORITY"
        )
    return value.upper()


def validate_enum(value: str | None, allowed: tuple[str, ...], label: str) -> str:
    if value is None:
        raise ValidationException(f"{label} is required", "REQUIRED_FIELD")
    normalized = value.upper().replace(" ", "_")
    if normalized not in allowed:
        raise ValidationException(
            f"{label} must be one of: {', '.join(a.replace('_', ' ').title() for a in allowed)}",
            "INVALID_VALUE",
        )
    return normalized


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def parse_datetime_iso(value: str) -> datetime:
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        raise ValidationException("Invalid date time format", "INVALID_DATETIME")


def count_days(start: str, end: str) -> int:
    s = date.fromisoformat(start)
    e = date.fromisoformat(end)
    if e < s:
        raise ValidationException("End date cannot be before start date", "INVALID_DATE_RANGE")
    return (e - s).days + 1