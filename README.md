# Full Stack Web Lab

A single unified web platform covering **Web Technology Experiments 2–8**, built with:

- **Frontend:** Flutter Web (responsive Material 3 UI)
- **Backend:** FastAPI (Python) REST API
- **Database:** MongoDB (Motor async driver)
- **Auth:** JWT bearer tokens (bcrypt password hashing)

The seven experiments live side-by-side in one app with a shared sidebar, user
session and a common design language:

| # | Experiment | What it does |
|---|------------|--------------|
| 2 | Todo Management | Personal todo lists with priorities, categories, due dates, search & stats |
| 3 | Micro Blogging | Post feed, likes, follow/unfollow and user profiles |
| 4 | Food Delivery | Restaurants + menus, cart, addresses, checkout and order tracking |
| 5 | Classifieds | Buy/sell listings, image URLs, filters, favorites, seller contact |
| 6 | Leave Management | Apply for leave, track balances, admin approve/reject |
| 7 | Project Management | Projects with a Kanban-style task board (pending/in-progress/completed) |
| 8 | Online Survey | 5 random questions per attempt, scored results, admin question bank |

## Demo accounts

Seeded by `backend/scripts/seed_database.py`:

| Role  | Email                  | Password  |
|-------|------------------------|-----------|
| Admin | `admin@weblab.local`   | `Admin@123` |
| User  | `aarav@example.com` (plus 7 more: `priya`, `rohan`, `sneha`, `vikram`, `ananya`, `karan`, `ishita` @`example.com`) | `Demo@123` |

> Admins see extra UI: food restaurant/menu management, leave approvals,
> survey question bank, platform admin stats.

## Project layout

```
├── backend/               # FastAPI application
│   ├── app/
│   │   ├── api/routes/    # 20+ routers (auth, todos, posts, food, cart, orders, ...)
│   │   ├── core/          # config, security (JWT + bcrypt), database
│   │   ├── middleware/    # rate limiting
│   │   ├── models/        # Mongo collection schemas
│   │   ├── repositories/  # data access layer
│   │   ├── schemas/       # Pydantic request/response models
│   │   └── services/      # business logic
│   ├── scripts/seed_database.py
│   ├── tests/             # 77 pytest tests (all pass)
│   └── requirements.txt
├── frontend/              # Flutter web app
│   └── lib/
│       ├── core/          # theme, constants, api client, storage, utils
│       ├── models/        # User
│       ├── services/      # Session (auth state)
│       ├── widgets/       # AppShell (sidebar), shared cards/dialogs, AuthGate
│       └── features/      # experiment2_todo … experiment8_survey + dashboard
├── docker-compose.yml
└── .env.example
```

## Run locally (without Docker)

### 1. Backend (port 8765)

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# MongoDB must be running on localhost:27017

# seed the demo data (9 users, restaurants, listings, projects, 20 questions, ...)
python scripts/seed_database.py

uvicorn app.main:app --host 0.0.0.0 --port 8765
```

Health check: `curl http://localhost:8765/health`
Interactive docs: `http://localhost:8765/docs`

Configuration comes from environment variables (see `backend/.env.example`).

### 2. Frontend (Flutter web)

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8765

# or a production build served by any static server:
flutter build web --dart-define=API_BASE_URL=http://localhost:8765
# then serve build/web (e.g. python -m http.server 3000 -d build/web)
```

> If the frontend and backend are on different machines, point
> `API_BASE_URL` at the backend host, e.g.
> `--dart-define=API_BASE_URL=http://192.168.1.10:8765`

### 3. Tests

```bash
cd backend
.venv/bin/python -m pytest -q        # 77 tests
```

## Run with Docker

```bash
cp .env.example .env          # adjust secrets
docker compose up --build
```

- Frontend: http://localhost:3000
- Backend: http://localhost:8765 (docs at `/docs`)
- MongoDB: localhost:27017 (volume `mongo_data`)

To seed demo data inside the container:

```bash
docker compose exec backend python scripts/seed_database.py
```

## API conventions

- Base path: `/api` (auth docs in OpenAPI at `/docs`)
- Every response uses the envelope `{"success": bool, "message": str, "data": ...}`
- Errors: `{"success": false, "message": str, "error": "ERROR_CODE"}`
- Protected endpoints require `Authorization: Bearer <jwt>`
- Admin endpoints (`/api/admin/*`) require the `ADMIN` role