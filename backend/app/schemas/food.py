from pydantic import BaseModel, Field

from ..utils.helpers import validate_enum, validate_price, validate_required_text


class AddressCreate(BaseModel):
    label: str = "Home"
    full_name: str = Field(min_length=2, max_length=80)
    phone: str = Field(min_length=7, max_length=20)
    address_line: str = Field(min_length=3, max_length=200)
    city: str = Field(min_length=2, max_length=60)
    state: str = Field(min_length=2, max_length=60)
    postal_code: str = Field(min_length=3, max_length=12)

    def validate_model(self) -> dict:
        return {
            "label": (self.label or "Home").strip()[:30],
            "full_name": validate_required_text(self.full_name, "Full name", 80),
            "phone": validate_required_text(self.phone, "Phone", 20),
            "address_line": validate_required_text(self.address_line, "Address", 200),
            "city": validate_required_text(self.city, "City", 60),
            "state": validate_required_text(self.state, "State", 60),
            "postal_code": validate_required_text(self.postal_code, "Postal code", 12),
        }


class CartAddRequest(BaseModel):
    restaurant_id: str = Field(min_length=10, max_length=30)
    food_item_id: str = Field(min_length=10, max_length=30)
    quantity: int = Field(default=1, ge=1, le=50)


class CartUpdateRequest(BaseModel):
    quantity: int = Field(ge=1, le=50)


class OrderItemIn(BaseModel):
    food_item_id: str
    quantity: int = Field(ge=1, le=50)


class OrderCreate(BaseModel):
    restaurant_id: str = Field(min_length=10, max_length=30)
    items: list[OrderItemIn] = Field(min_length=1, max_length=50)
    address_id: str = Field(min_length=10, max_length=30)
    payment_method: str = "CASH"


class ReviewCreate(BaseModel):
    restaurant_id: str = Field(min_length=10, max_length=30)
    rating: int = Field(ge=1, le=5)
    comment: str = Field(default="", max_length=500)


class RestaurantCreate(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    cuisine: str = Field(min_length=2, max_length=60)
    city: str = Field(min_length=2, max_length=60)
    address: str = Field(min_length=3, max_length=200)
    phone: str = Field(default="", max_length=20)
    description: str = Field(default="", max_length=1000)
    image_url: str = Field(default="", max_length=500)
    delivery_estimate: int = Field(default=30, ge=5, le=180)
    delivery_fee: float = Field(default=0, ge=0)

    def validate_model(self) -> dict:
        return {
            "name": validate_required_text(self.name, "Name", 100),
            "cuisine": validate_required_text(self.cuisine, "Cuisine", 60),
            "city": validate_required_text(self.city, "City", 60),
            "address": validate_required_text(self.address, "Address", 200),
            "phone": self.phone.strip()[:20],
            "description": self.description.strip()[:1000],
            "image_url": self.image_url.strip()[:500],
            "delivery_estimate": int(self.delivery_estimate),
            "delivery_fee": validate_price(self.delivery_fee),
        }


class FoodItemCreate(BaseModel):
    restaurant_id: str = Field(min_length=10, max_length=30)
    name: str = Field(min_length=2, max_length=100)
    description: str = Field(default="", max_length=500)
    price: float = Field(gt=0)
    category: str = Field(min_length=2, max_length=50)
    image_url: str = Field(default="", max_length=500)
    is_vegetarian: bool = False
    is_available: bool = True

    def validate_model(self) -> dict:
        return {
            "restaurant_id": validate_required_text(self.restaurant_id, "Restaurant"),
            "name": validate_required_text(self.name, "Name", 100),
            "description": self.description.strip()[:500],
            "price": validate_price(self.price),
            "category": validate_required_text(self.category, "Category", 50),
            "image_url": self.image_url.strip()[:500],
            "is_vegetarian": bool(self.is_vegetarian),
            "is_available": bool(self.is_available),
        }