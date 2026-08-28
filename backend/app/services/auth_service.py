from ..core.security import hash_password, verify_password, create_access_token
from ..repositories.users_repo import UserRepository
from ..utils.errors import ConflictException, UnauthorizedException, ValidationException
from ..utils.helpers import utc_now_iso, validate_email, validate_password, validate_required_text


class AuthService:
    def __init__(self):
        self.users = UserRepository()

    async def register(self, name: str, email: str, password: str) -> dict:
        name = validate_required_text(name, "Name", 80)
        email = validate_email(email)
        validate_password(password)

        existing = await self.users.find_by_email(email)
        if existing:
            raise ConflictException("An account with this email already exists", "EMAIL_TAKEN")

        user = {
            "name": name,
            "email": email,
            "password_hash": hash_password(password),
            "role": "USER",
            "bio": "",
            "created_at": utc_now_iso(),
        }
        created = await self.users.create(user)
        created.pop("password_hash", None)
        token = create_access_token(created["id"], created["role"])
        return {"token": token, "user": created}

    async def login(self, email: str, password: str) -> dict:
        email = validate_email(email)
        user = await self.users.find_by_email(email)
        if user is None or not verify_password(password, user.get("password_hash", "")):
            raise UnauthorizedException("Invalid email or password", "INVALID_CREDENTIALS")
        user.pop("password_hash", None)
        token = create_access_token(user["id"], user["role"])
        return {"token": token, "user": user}