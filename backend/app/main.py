import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pymongo.errors import PyMongoError
from .core.config import settings
from .core.database import close_mongo_connection, connect_to_mongo, get_database
from .middleware.rate_limit import RateLimitMiddleware
from .utils.errors import AppException
from .utils.helpers import fail

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s - %(message)s")
logger = logging.getLogger("weblab")


def create_app() -> FastAPI:
    app = FastAPI(
        title="Full Stack Web Lab API",
        description=(
            "Backend for the Full Stack Web Lab platform covering 7 experiments: "
            "Todo Management, Micro Blogging, Food Delivery, Classifieds, Leave Management, "
            "Project Management and Online Survey. MongoDB-backed, JWT-secured."
        ),
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(RateLimitMiddleware)

    from .api.routes import admin_leaves, admin_stats, auth, cart, favorites, follows, food
    from .api.routes import leaves, listings, orders, posts, projects, questions
    from .api.routes import restaurants, survey, tasks, todos, users, users_admin

    prefix = settings.API_PREFIX
    app.include_router(auth.router, prefix=prefix)
    app.include_router(users.router, prefix=prefix)
    app.include_router(users_admin.router, prefix=prefix)
    app.include_router(todos.router, prefix=prefix)
    app.include_router(posts.router, prefix=prefix)
    app.include_router(follows.router, prefix=prefix)
    app.include_router(restaurants.router, prefix=prefix)
    app.include_router(restaurants.admin_router, prefix=prefix)
    app.include_router(food.router, prefix=prefix)
    app.include_router(cart.router, prefix=prefix)
    app.include_router(cart.address_router, prefix=prefix)
    app.include_router(orders.router, prefix=prefix)
    app.include_router(orders.admin_router, prefix=prefix)
    app.include_router(listings.router, prefix=prefix)
    app.include_router(favorites.router, prefix=prefix)
    app.include_router(favorites.messages_router, prefix=prefix)
    app.include_router(leaves.router, prefix=prefix)
    app.include_router(admin_leaves.router, prefix=prefix)
    app.include_router(projects.router, prefix=prefix)
    app.include_router(tasks.router, prefix=prefix)
    app.include_router(survey.router, prefix=prefix)
    app.include_router(questions.router, prefix=prefix)
    app.include_router(questions.admin_router, prefix=prefix)
    app.include_router(admin_stats.router, prefix=prefix)

    @app.get("/health", tags=["System"], summary="Health check")
    async def health():
        db_status = "connected"
        try:
            await get_database().command("ping")
        except Exception:
            db_status = "disconnected"
        return {"success": True, "message": "Full Stack Web Lab API is running", "data": {
            "status": "ok" if db_status == "connected" else "degraded",
            "database": db_status,
        }}

    @app.get("/", tags=["System"], summary="API root")
    async def root():
        return {
            "success": True,
            "message": "Full Stack Web Lab API",
            "data": {
                "docs": "/docs",
                "redoc": "/redoc",
                "health": "/health",
                "experiments": {
                    "experiment_2": "Todo Management",
                    "experiment_3": "Micro Blogging",
                    "experiment_4": "Food Delivery",
                    "experiment_5": "Classifieds",
                    "experiment_6": "Leave Management",
                    "experiment_7": "Project Management",
                    "experiment_8": "Online Survey",
                },
            },
        }

    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException):
        return JSONResponse(
            status_code=exc.status_code,
            content=fail(exc.message, exc.error_code),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        errors = exc.errors()
        first = errors[0] if errors else {}
        location = ".".join(str(p) for p in first.get("loc", []))
        message = first.get("msg", "Invalid request")
        return JSONResponse(
            status_code=422,
            content=fail(
                f"{location}: {message}" if location else "Validation failed: " + str(message),
                "VALIDATION_ERROR",
            ),
        )

    @app.exception_handler(PyMongoError)
    async def mongo_exception_handler(request: Request, exc: PyMongoError):
        logger.error("MongoDB error: %s", exc)
        return JSONResponse(
            status_code=503,
            content=fail("Database is temporarily unavailable. Please try again later.", "DATABASE_UNAVAILABLE"),
        )

    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception):
        logger.exception("Unhandled error: %s", exc)
        return JSONResponse(
            status_code=500,
            content=fail("Something went wrong on the server. Please try again later.", "INTERNAL_ERROR"),
        )

    return app


from contextlib import asynccontextmanager


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    yield
    await close_mongo_connection()


app = create_app()
