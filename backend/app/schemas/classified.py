from pydantic import BaseModel, Field

from ..utils.helpers import validate_enum, validate_price, validate_required_text

CATEGORIES = (
    "ELECTRONICS",
    "MOBILES",
    "LAPTOPS",
    "VEHICLES",
    "FURNITURE",
    "BOOKS",
    "CLOTHING",
    "HOME_APPLIANCES",
    "OTHERS",
)

CONDITIONS = ("NEW", "LIKE_NEW", "GOOD", "FAIR")


class ListingCreate(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    description: str = Field(min_length=10, max_length=3000)
    price: float = Field(ge=0)
    category: str = Field(min_length=2, max_length=40)
    condition: str = "GOOD"
    location: str = Field(min_length=2, max_length=100)
    images: list[str] = Field(default_factory=list, max_length=6)

    def validate_model(self) -> dict:
        images = [i.strip()[:500] for i in self.images if i and i.strip()]
        return {
            "title": validate_required_text(self.title, "Title", 120),
            "description": validate_required_text(self.description, "Description", 3000),
            "price": validate_price(self.price),
            "category": validate_enum(self.category, CATEGORIES, "Category"),
            "condition": validate_enum(self.condition, CONDITIONS, "Condition"),
            "location": validate_required_text(self.location, "Location", 100),
            "images": images[:6],
        }


class ListingUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=3, max_length=120)
    description: str | None = Field(default=None, min_length=10, max_length=3000)
    price: float | None = Field(default=None, ge=0)
    category: str | None = None
    condition: str | None = None
    location: str | None = None
    images: list[str] | None = Field(default=None, max_length=6)
    status: str | None = None

    def validate_model(self) -> dict:
        updates: dict = {}
        fields = {
            "title": (self.title, 120),
            "description": (self.description, 3000),
            "location": (self.location, 100),
        }
        for name, (value, max_len) in fields.items():
            if value is not None:
                updates[name] = validate_required_text(value, name.replace("_", " ").title(), max_len)
        if self.categories_value is not None:
            updates["category"] = validate_enum(self.categories_value, CATEGORIES, "Category")
        if self.conditions_value is not None:
            updates["condition"] = validate_enum(self.conditions_value, CONDITIONS, "Condition")
        if self.price is not None:
            updates["price"] = validate_price(self.price)
        if self.images is not None:
            updates["images"] = [i.strip()[:500] for i in self.images if i and i.strip()][:6]
        if self.status is not None:
            updates["status"] = validate_enum(self.status, ("AVAILABLE", "SOLD", "REMOVED"), "Status")
        return updates

    @property
    def categories_value(self) -> str | None:
        return self.category

    @property
    def conditions_value(self) -> str | None:
        return self.condition


class ContactSellerRequest(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    message: str = Field(min_length=2, max_length=1000)