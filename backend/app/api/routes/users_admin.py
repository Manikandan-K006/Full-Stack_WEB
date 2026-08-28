from fastapi import APIRouter, Depends

from ..deps import get_current_admin
from ...repositories.users_repo import UserRepository
from ...utils.errors import NotFoundException
from ...utils.helpers import ok, parse_object_id

router = APIRouter(prefix="/admin/users", tags=["Admin"], dependencies=[Depends(get_current_admin)])


@router.get("", summary="[Admin] List all users")
async def list_users(search: str | None = None, skip: int = 0, limit: int = 100):
    users = await UserRepository().list_all(search, skip, limit)
    for u in users:
        u.pop("password_hash", None)
    return ok(users, "Users fetched")


@router.delete("/{user_id}", summary="[Admin] Delete a user account")
async def delete_user(user_id: str):
    oid = parse_object_id(user_id, "user id")
    if not await UserRepository().delete(oid):
        raise NotFoundException("User not found", "USER_NOT_FOUND")
    return ok(None, "User deleted")