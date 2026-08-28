from bson import ObjectId

from ..repositories.posts_repo import FollowRepository, LikeRepository, PostRepository
from ..repositories.users_repo import UserRepository
from ..utils.errors import BadRequestException, NotFoundException
from ..utils.helpers import parse_object_id, utc_now_iso


class PostService:
    def __init__(self):
        self.posts = PostRepository()
        self.follows = FollowRepository()
        self.likes = LikeRepository()
        self.users = UserRepository()

    async def create(self, author_id: str, content: str) -> dict:
        post = {
            "author_id": author_id,
            "content": content,
            "likes_count": 0,
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
        }
        return await self.posts.create(post)

    async def feed(self, user_id: str, skip: int, limit: int) -> list[dict]:
        following = await self.follows.following_ids(user_id)
        if not following:
            return []
        posts = await self.posts.feed(following, skip, limit)
        return await self._enrich(posts, user_id)

    async def user_posts(self, author_id: str, viewer_id: str) -> list[dict]:
        posts = await self.posts.by_author(author_id)
        return await self._enrich(posts, viewer_id)

    async def get(self, post_id: str, viewer_id: str) -> dict:
        oid = parse_object_id(post_id, "post id")
        post = await self.posts.find_by_id(oid)
        if post is None:
            raise NotFoundException("Post not found", "POST_NOT_FOUND")
        return (await self._enrich([post], viewer_id))[0]

    async def update(self, post_id: str, author_id: str, content: str) -> dict:
        oid = parse_object_id(post_id, "post id")
        post = await self.posts.find_by_id(oid)
        if post is None:
            raise NotFoundException("Post not found", "POST_NOT_FOUND")
        if post["author_id"] != author_id:
            from ..utils.errors import ForbiddenException
            raise ForbiddenException("You can only edit your own posts")
        return await self.posts.update(oid, {"content": content, "updated_at": utc_now_iso()})

    async def delete(self, post_id: str, author_id: str) -> None:
        oid = parse_object_id(post_id, "post id")
        post = await self.posts.find_by_id(oid)
        if post is None:
            raise NotFoundException("Post not found", "POST_NOT_FOUND")
        if post["author_id"] != author_id:
            from ..utils.errors import ForbiddenException
            raise ForbiddenException("You can only delete your own posts")
        from ..core.database import get_database
        await get_database()["likes"].delete_many({"post_id": str(oid)})
        await self.posts.delete(oid)

    async def toggle_like(self, post_id: str, user_id: str) -> dict:
        oid = parse_object_id(post_id, "post id")
        post = await self.posts.find_by_id(oid)
        if post is None:
            raise NotFoundException("Post not found", "POST_NOT_FOUND")
        liked = await self.likes.has_liked(user_id, str(oid))
        if liked:
            await self.likes.unlike(user_id, str(oid))
            likes_count = await self.likes.count(str(oid))
            await self.posts.update(oid, {"likes_count": likes_count, "updated_at": utc_now_iso()})
            return {"liked": False, "likes_count": likes_count}
        await self.likes.like(user_id, str(oid))
        likes_count = await self.likes.count(str(oid))
        await self.posts.update(oid, {"likes_count": likes_count, "updated_at": utc_now_iso()})
        return {"liked": True, "likes_count": likes_count}

    async def _enrich(self, posts: list[dict], viewer_id: str) -> list[dict]:
        if not posts:
            return []
        post_ids = [p["id"] for p in posts]
        liked_ids = await self.likes.liked_post_ids(viewer_id, post_ids)
        author_ids = {p["author_id"] for p in posts}
        authors: dict[str, dict] = {}
        for aid in author_ids:
            author = await self.users.find_by_id(ObjectId(aid))
            if author:
                authors[aid] = {"id": author["id"], "name": author["name"], "bio": author.get("bio", "")}
        for post in posts:
            post["liked_by_me"] = post["id"] in liked_ids
            post["author"] = authors.get(post["author_id"], {"id": post["author_id"], "name": "Unknown"})
        return posts

    async def user_stats(self, user_id: str) -> dict:
        counts = await self.follows.counts(user_id)
        counts["posts"] = await self.posts.count_by_author(user_id)
        return counts

    async def follow(self, follower_id: str, target_id: str) -> dict:
        oid = parse_object_id(target_id, "user id")
        if str(oid) == follower_id:
            raise BadRequestException("You cannot follow yourself", "SELF_FOLLOW")
        target = await self.users.find_by_id(oid)
        if target is None:
            raise NotFoundException("User not found", "USER_NOT_FOUND")
        ok = await self.follows.follow(follower_id, str(oid))
        return {"following": ok}

    async def unfollow(self, follower_id: str, target_id: str) -> dict:
        oid = parse_object_id(target_id, "user id")
        await self.follows.unfollow(follower_id, str(oid))
        return {"following": False}

    async def followers(self, target_id: str, viewer_id: str) -> list[dict]:
        oid = parse_object_id(target_id, "user id")
        ids = await self.follows.follower_ids(oid)
        users = []
        for uid in ids:
            user = await self.users.find_by_id(uid)
            if user:
                is_following = await self.follows.is_following(viewer_id, str(uid))
                user.pop("password_hash", None)
                user["followed_by_me"] = is_following
                users.append(user)
        return users

    async def following(self, target_id: str, viewer_id: str) -> list[dict]:
        oid = parse_object_id(target_id, "user id")
        ids = await self.follows.following_ids(oid)
        users = []
        for uid in ids:
            user = await self.users.find_by_id(uid)
            if user:
                is_following = await self.follows.is_following(viewer_id, str(uid))
                user.pop("password_hash", None)
                user["followed_by_me"] = is_following
                users.append(user)
        return users

    async def search_users(self, query: str, viewer_id: str) -> list[dict]:
        if not query or not query.strip():
            return []
        users = await self.users.list_all(search=query.strip(), limit=30)
        result = []
        for user in users:
            if user["id"] == viewer_id:
                continue
            user.pop("password_hash", None)
            user["followed_by_me"] = await self.follows.is_following(viewer_id, user["id"])
            result.append(user)
        return result