from fastapi import APIRouter, Depends, Query

from ..deps import get_current_admin, get_current_user
from ...repositories.users_repo import UserRepository
from ...schemas.auth import UserUpdateRequest
from ...services.post_service import PostService
from ...utils.errors import NotFoundException
from ...utils.helpers import ok, parse_object_id

router = APIRouter(prefix="/users", tags=["Users"])


@router.put("/me", summary="Update the current user profile")
async def update_me(payload: UserUpdateRequest, user: dict = Depends(get_current_user)):
    repo = UserRepository()
    updates = {}
    if payload.name is not None:
        updates["name"] = payload.name.strip()
    if payload.bio is not None:
        updates["bio"] = payload.bio.strip()
    if updates:
        updated = await repo.update(parse_object_id(user["id"], "user id"), updates)
        updated.pop("password_hash", None)
        return ok(updated, "Profile updated")
    return ok(user, "Profile unchanged")


@router.get("/search", summary="Search users by name or email")
async def search_users(q: str = Query(..., min_length=1, max_length=60), user: dict = Depends(get_current_user)):
    result = await PostService().search_users(q, user["id"])
    return ok(result, "Search results")


@router.get("/{user_id}", summary="Get a public user profile with stats")
async def get_user(user_id: str, user: dict = Depends(get_current_user)):
    oid = parse_object_id(user_id, "user id")
    repo = UserRepository()
    profile = await repo.find_by_id(oid)
    if profile is None:
        raise NotFoundException("User not found", "USER_NOT_FOUND")
    profile.pop("password_hash", None)
    profile["stats"] = await PostService().user_stats(str(oid))
    return ok(profile, "User profile")