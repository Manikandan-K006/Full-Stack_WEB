from fastapi import APIRouter, Depends, Request

from ..deps import get_current_user
from ...schemas.auth import LoginRequest, RegisterRequest
from ...services.auth_service import AuthService
from ...utils.helpers import ok

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", summary="Register a new user")
async def register(payload: RegisterRequest, service: AuthService = Depends(lambda: AuthService())):
    result = await service.register(payload.name, payload.email, payload.password)
    return ok(result, "Registration successful")


@router.post("/login", summary="Login and receive a JWT token")
async def login(payload: LoginRequest, service: AuthService = Depends(lambda: AuthService())):
    result = await service.login(payload.email, payload.password)
    return ok(result, "Login successful")


@router.get("/me", summary="Get the current authenticated user")
async def me(user: dict = Depends(get_current_user)):
    safe = {k: v for k, v in user.items() if k != "password_hash"}
    return ok(safe, "User profile")