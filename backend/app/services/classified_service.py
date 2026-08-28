from ..repositories.classified_repo import FavoriteRepository, ListingRepository, MessageRepository
from ..repositories.users_repo import UserRepository
from ..utils.errors import ConflictException, ForbiddenException, NotFoundException
from ..utils.helpers import parse_object_id, utc_now_iso


class ClassifiedService:
    def __init__(self):
        self.listings = ListingRepository()
        self.favorites = FavoriteRepository()
        self.messages = MessageRepository()
        self.users = UserRepository()

    async def list_listings(self, search, category, condition, min_price, max_price, location,
                            sort, direction, skip, limit) -> list[dict]:
        items = await self.listings.list_all(
            search=search, category=category, condition=condition, min_price=min_price,
            max_price=max_price, location=location, sort=sort, direction=direction,
            skip=skip, limit=limit,
        )
        return await self._enrich_sellers(items)

    async def get(self, listing_id: str) -> dict:
        oid = parse_object_id(listing_id, "listing id")
        listing = await self.listings.find_by_id(oid)
        if listing is None:
            raise NotFoundException("Listing not found", "LISTING_NOT_FOUND")
        seller = await self.users.find_by_id(parse_object_id(listing["seller_id"], "seller id"))
        if seller:
            listing["seller"] = {"id": seller["id"], "name": seller["name"], "email": seller.get("email"), "bio": seller.get("bio", "")}
        else:
            listing["seller"] = {"id": listing["seller_id"], "name": "Unknown"}
        return listing

    async def my_listings(self, seller_id: str) -> list[dict]:
        return await self.listings.list_by_seller(seller_id)

    async def create(self, seller_id: str, payload: dict) -> dict:
        doc = {
            "seller_id": seller_id,
            "status": "AVAILABLE",
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
            **payload,
        }
        return await self.listings.create(doc)

    async def update(self, seller_id: str, listing_id: str, payload: dict) -> dict:
        oid = parse_object_id(listing_id, "listing id")
        listing = await self.listings.find_by_id(oid)
        if listing is None:
            raise NotFoundException("Listing not found", "LISTING_NOT_FOUND")
        if listing["seller_id"] != seller_id:
            raise ForbiddenException("You can only modify your own listings")
        return await self.listings.update(oid, {**payload, "updated_at": utc_now_iso()})

    async def delete(self, seller_id: str, listing_id: str) -> None:
        oid = parse_object_id(listing_id, "listing id")
        listing = await self.listings.find_by_id(oid)
        if listing is None:
            raise NotFoundException("Listing not found", "LISTING_NOT_FOUND")
        if listing["seller_id"] != seller_id:
            raise ForbiddenException("You can only delete your own listings")
        await self.favorites.remove_for_listing(str(oid))
        await self.listings.delete(oid)

    async def mark_sold(self, seller_id: str, listing_id: str) -> dict:
        return await self.update(seller_id, listing_id, {"status": "SOLD"})

    async def toggle_favorite(self, user_id: str, listing_id: str) -> dict:
        oid = parse_object_id(listing_id, "listing id")
        listing = await self.listings.find_by_id(oid)
        if listing is None:
            raise NotFoundException("Listing not found", "LISTING_NOT_FOUND")
        ids = await self.favorites.ids_for_user(user_id)
        if str(oid) in ids:
            await self.favorites.remove(user_id, str(oid))
            return {"favorited": False}
        await self.favorites.add(user_id, str(oid))
        return {"favorited": True}

    async def my_favorites(self, user_id: str) -> list[dict]:
        return await self.favorites.listings_for_user(user_id)

    async def contact_seller(self, sender_id: str, listing_id: str, name: str, message: str) -> dict:
        oid = parse_object_id(listing_id, "listing id")
        listing = await self.listings.find_by_id(oid)
        if listing is None:
            raise NotFoundException("Listing not found", "LISTING_NOT_FOUND")
        doc = {
            "listing_id": str(oid),
            "sender_id": sender_id,
            "recipient_id": listing["seller_id"],
            "name": name.strip()[:80],
            "message": message.strip()[:1000],
            "listing_title": listing["title"],
            "created_at": utc_now_iso(),
        }
        return await self.messages.create(doc)

    async def my_messages(self, user_id: str) -> list[dict]:
        return await self.messages.list_for_user(user_id)

    async def _enrich_sellers(self, listings: list[dict]) -> list[dict]:
        for listing in listings:
            try:
                seller = await self.users.find_by_id(parse_object_id(listing["seller_id"], "seller id"))
                listing["seller_name"] = seller["name"] if seller else "Unknown"
            except Exception:
                listing["seller_name"] = "Unknown"
        return listings