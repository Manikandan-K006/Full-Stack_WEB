from fastapi import APIRouter, Depends, Query

from ..deps import get_current_user
from ...schemas.post import PostCreate, PostUpdate
from ...services.post_service import PostService
from ...utils.helpers import ok

router = APIRouter(prefix="/posts", tags=["Posts"])


@router.get("/feed", summary="Home feed: posts from users you follow")
async def feed(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=30, ge=1, le=100),
    user: dict = Depends(get_current_user),
):
    posts = await PostService().feed(user["id"], skip, limit)
    return ok(posts, "Feed fetched")


@router.post("", summary="Create a new post")
async def create_post(payload: PostCreate, user: dict = Depends(get_current_user)):
    data = payload.validate_model()
    post = await PostService().create(user["id"], data["content"])
    return ok(post, "Post published")


@router.get("/user/{author_id}", summary="Posts by a specific user")
async def user_posts(author_id: str, user: dict = Depends(get_current_user)):
    posts = await PostService().user_posts(author_id, user["id"])
    return ok(posts, "User posts fetched")


@router.get("/{post_id}", summary="Get a single post")
async def get_post(post_id: str, user: dict = Depends(get_current_user)):
    return ok(await PostService().get(post_id, user["id"]), "Post fetched")


@router.put("/{post_id}", summary="Edit your own post")
async def update_post(post_id: str, payload: PostUpdate, user: dict = Depends(get_current_user)):
    data = payload.validate_model()
    return ok(await PostService().update(post_id, user["id"], data["content"]), "Post updated")


@router.delete("/{post_id}", summary="Delete your own post")
async def delete_post(post_id: str, user: dict = Depends(get_current_user)):
    await PostService().delete(post_id, user["id"])
    return ok(None, "Post deleted")


@router.post("/{post_id}/like", summary="Like a post")
async def like_post(post_id: str, user: dict = Depends(get_current_user)):
    return ok(await PostService().toggle_like(post_id, user["id"]), "Like toggled")


@router.delete("/{post_id}/like", summary="Unlike a post")
async def unlike_post(post_id: str, user: dict = Depends(get_current_user)):
    return ok(await PostService().toggle_like(post_id, user["id"]), "Like toggled")