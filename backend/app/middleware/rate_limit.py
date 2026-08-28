"""Rate limiting middleware.

A lightweight in-memory sliding-window rate limiter keyed by client IP.
Note: for a single-process lab deployment this is sufficient; for a
multi-worker production deployment use a shared store (e.g. Redis).
"""
import time
from collections import defaultdict, deque
from typing import Deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

from ..core.config import settings


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, requests: int | None = None, window_seconds: int | None = None):
        super().__init__(app)
        self.requests = requests or settings.RATE_LIMIT_REQUESTS
        self.window = window_seconds or settings.RATE_LIMIT_WINDOW_SECONDS
        self.hits: dict[str, Deque[float]] = defaultdict(deque)

    async def dispatch(self, request: Request, call_next):
        if not settings.RATE_LIMIT_ENABLED or request.url.path.startswith("/docs") \
                or request.url.path.startswith("/redoc") or request.url.path.startswith("/openapi.json") \
                or request.url.path.startswith("/health"):
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        now = time.monotonic()
        queue = self.hits[client_ip]
        while queue and now - queue[0] > self.window:
            queue.popleft()
        if len(queue) >= self.requests:
            return JSONResponse(
                status_code=429,
                content={
                    "success": False,
                    "message": f"Too many requests. Please slow down (limit {self.requests} per {self.window}s).",
                    "error": "RATE_LIMITED",
                },
            )
        queue.append(now)
        return await call_next(request)