from fastapi import APIRouter, Depends

from ..deps import get_current_user
from ...services.post_service import PostService
from ...utils.helpers import ok

router = APIRouter(prefix="/users/{user_id}", tags=["Follows"])


@router.post("/follow", summary="Follow a user")
async def follow(user_id: str, user: dict = Depends(get_current_user)):
    return ok(await PostService().follow(user["id"], user_id), "Follow updated")


@router.delete("/follow", summary="Unfollow a user")
async def unfollow(user_id: str, user: dict = Depends(get_current_user)):
    return ok(await PostService().unfollow(user["id"], user_id), "Unfollowed")


@router.get("/followers", summary="List followers of a user")
async def followers(user_id: str, user: dict = Depends(get_current_user)):
    return ok(await PostService().followers(user_id, user["id"]), "Followers fetched")


@router.get("/following", summary="List users a user follows")
async def following(user_id: str, user: dict = Depends(get_current_user)):
    return ok(await PostService().following(user_id, user["id"]), "Following fetched")