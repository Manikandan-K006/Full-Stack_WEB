"""Shared authentication dependencies for all protected API routes."""
import jwt
from fastapi import Depends, Request
from motor.motor_asyncio import AsyncIOMotorDatabase

from ..core.config import settings
from ..core.database import get_database
from ..utils.errors import ForbiddenException, UnauthorizedException
from ..utils.helpers import parse_object_id


async def get_current_user(request: Request, db: AsyncIOMotorDatabase = Depends(get_database)) -> dict:
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise UnauthorizedException("Missing or invalid authorization header", "NO_TOKEN")

    token = auth_header[7:].strip()
    if not token:
        raise UnauthorizedException("Missing token", "NO_TOKEN")

    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise UnauthorizedException("Session expired. Please login again.", "TOKEN_EXPIRED")
    except jwt.InvalidTokenError:
        raise UnauthorizedException("Invalid token", "INVALID_TOKEN")

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Invalid token payload", "INVALID_TOKEN")

    try:
        oid = parse_object_id(user_id, "user id")
    except Exception:
        raise UnauthorizedException("Invalid token payload", "INVALID_TOKEN")

    user = await db.users.find_one({"_id": oid})
    if user is None:
        raise UnauthorizedException("Account no longer exists", "USER_NOT_FOUND")

    user["id"] = str(user.pop("_id"))
    return user


async def get_current_admin(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "ADMIN":
        raise ForbiddenException("Admin access required")
    return user