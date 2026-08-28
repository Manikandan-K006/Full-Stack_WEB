"""Database seeding script for the Full Stack Web Lab platform.

Usage (from the backend/ directory, after creating .env if needed):

    .venv/bin/python scripts/seed_database.py

The script is idempotent: existing documents for the seeded collections are
wiped and replaced with realistic educational demo data.
"""
import asyncio
import os
import sys
import time
from datetime import date, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__))))

from motor.motor_asyncio import AsyncIOMotorClient  # noqa: E402

from app.core.config import settings  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.utils.helpers import utc_now_iso  # noqa: E402

DEMO_USERS = [
    {"name": "Aarav Sharma", "email": "aarav@example.com", "role": "USER", "bio": "Full-stack developer student. Coffee enthusiast."},
    {"name": "Priya Patel", "email": "priya@example.com", "role": "USER", "bio": "UI/UX designer. I sketch ideas before I click."},
    {"name": "Rohan Mehta", "email": "rohan@example.com", "role": "USER", "bio": "Backend geek, MongoDB lover."},
    {"name": "Sneha Iyer", "email": "sneha@example.com", "role": "USER", "bio": "Product manager in training. Lists are my life."},
    {"name": "Vikram Singh", "email": "vikram@example.com", "role": "USER", "bio": "Data science enthusiast and weekend chef."},
    {"name": "Ananya Rao", "email": "ananya@example.com", "role": "USER", "bio": "Mobile developer. Learning Flutter Web."},
    {"name": "Karan Joshi", "email": "karan@example.com", "role": "USER", "bio": "Sold my bike, buying a laptop. Classifieds fan."},
    {"name": "Ishita Gupta", "email": "ishita@example.com", "role": "USER", "bio": "HR intern who loves organized leave calendars."},
    {"name": "Lab Admin", "email": settings.SEED_ADMIN_EMAIL, "role": "ADMIN", "bio": "Administrator of the Full Stack Web Lab."},
]

PASSWORD = "Demo@123"

RESTAURANTS = [
    {
        "name": "Spice Route Kitchen", "cuisine": "Indian", "city": "Bengaluru", "address": "12 MG Road, Bengaluru",
        "phone": "+91 98765 40001", "description": "Authentic North & South Indian dishes made with family recipes.",
        "image_url": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4",
        "delivery_estimate": 30, "delivery_fee": 40.0, "rating": 4.6, "rating_count": 128,
    },
    {
        "name": "Pizza Paradiso", "cuisine": "Italian", "city": "Bengaluru", "address": "45 Koramangala 5th Block, Bengaluru",
        "phone": "+91 98765 40002", "description": "Wood-fired Neapolitan pizzas and fresh pasta.",
        "image_url": "https://images.unsplash.com/photo-1513104890138-7c749659a591",
        "delivery_estimate": 25, "delivery_fee": 30.0, "rating": 4.4, "rating_count": 214,
    },
    {
        "name": "Sushi Central", "cuisine": "Japanese", "city": "Mumbai", "address": "8 Bandra West, Mumbai",
        "phone": "+91 98765 40003", "description": "Fresh sushi, ramen and Japanese street food.",
        "image_url": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c",
        "delivery_estimate": 40, "delivery_fee": 60.0, "rating": 4.7, "rating_count": 96,
    },
    {
        "name": "Green Bowl Café", "cuisine": "Healthy", "city": "Pune", "address": "23 Koregaon Park, Pune",
        "phone": "+91 98765 40004", "description": "Salads, smoothie bowls and guilt-free meals.",
        "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
        "delivery_estimate": 20, "delivery_fee": 20.0, "rating": 4.3, "rating_count": 342,
    },
    {
        "name": "Biryani Bazaar", "cuisine": "Indian", "city": "Hyderabad", "address": "7 Banjara Hills, Hyderabad",
        "phone": "+91 98765 40005", "description": "Hyderabadi dum biryani legends.",
        "image_url": "https://images.unsplash.com/photo-1563379091339-03a21d378bf3",
        "delivery_estimate": 35, "delivery_fee": 35.0, "rating": 4.8, "rating_count": 501,
    },
    {
        "name": "Taco Fiesta", "cuisine": "Mexican", "city": "Delhi", "address": "56 Hauz Khas Village, Delhi",
        "phone": "+91 98765 40006", "description": "Street-style tacos, burritos and churros.",
        "image_url": "https://images.unsplash.com/photo-1551504734-5ee1c4a1479b",
        "delivery_estimate": 30, "delivery_fee": 45.0, "rating": 4.2, "rating_count": 178,
    },
]

FOOD_ITEMS = [
    # Spice Route Kitchen
    {"restaurant": "Spice Route Kitchen", "name": "Butter Chicken with Naan", "description": "Creamy tomato-butter gravy with tandoori chicken and two butter naans.", "price": 320.0, "category": "Main Course", "is_vegetarian": False},
    {"restaurant": "Spice Route Kitchen", "name": "Paneer Tikka Masala", "description": "Char-grilled paneer cubes in rich masala gravy.", "price": 280.0, "category": "Main Course", "is_vegetarian": True},
    {"restaurant": "Spice Route Kitchen", "name": "Veg Biryani", "description": "Fragrant basmati rice layered with spiced vegetables.", "price": 240.0, "category": "Biryani", "is_vegetarian": True},
    {"restaurant": "Spice Route Kitchen", "name": "Gulab Jamun (2 pcs)", "description": "Warm khoya dumplings in rose syrup.", "price": 90.0, "category": "Dessert", "is_vegetarian": True},
    {"restaurant": "Spice Route Kitchen", "name": "Masala Chai", "description": "Spiced Indian tea brewed to order.", "price": 60.0, "category": "Beverages", "is_vegetarian": True},
    # Pizza Paradiso
    {"restaurant": "Pizza Paradiso", "name": "Margherita Pizza", "description": "San Marzano tomato, fior di latte, fresh basil.", "price": 290.0, "category": "Pizza", "is_vegetarian": True},
    {"restaurant": "Pizza Paradiso", "name": "Pepperoni Pizza", "description": "Loaded with crispy pepperoni and mozzarella.", "price": 420.0, "category": "Pizza", "is_vegetarian": False},
    {"restaurant": "Pizza Paradiso", "name": "Penne Arrabbiata", "description": "Spicy tomato sauce with garlic and chilli.", "price": 260.0, "category": "Pasta", "is_vegetarian": True},
    {"restaurant": "Pizza Paradiso", "name": "Garlic Breadsticks", "description": "Buttery breadsticks with herb dip.", "price": 140.0, "category": "Sides", "is_vegetarian": True},
    {"restaurant": "Pizza Paradiso", "name": "Tiramisu", "description": "Classic Italian coffee dessert.", "price": 180.0, "category": "Dessert", "is_vegetarian": True},
    # Sushi Central
    {"restaurant": "Sushi Central", "name": "Veg California Roll", "description": "Avocado, cucumber and sesame roll (8 pcs).", "price": 350.0, "category": "Sushi", "is_vegetarian": True},
    {"restaurant": "Sushi Central", "name": "Salmon Nigiri (4 pcs)", "description": "Fresh salmon over seasoned rice.", "price": 480.0, "category": "Sushi", "is_vegetarian": False},
    {"restaurant": "Sushi Central", "name": "Chicken Ramen", "description": "Rich chicken broth, noodles, soft egg.", "price": 390.0, "category": "Ramen", "is_vegetarian": False},
    {"restaurant": "Sushi Central", "name": "Miso Soup", "description": "Classic soybean paste soup with tofu.", "price": 120.0, "category": "Soups", "is_vegetarian": True},
    # Green Bowl Café
    {"restaurant": "Green Bowl Café", "name": "Quinoa Power Bowl", "description": "Quinoa, kale, chickpeas, avocado and tahini.", "price": 310.0, "category": "Bowls", "is_vegetarian": True},
    {"restaurant": "Green Bowl Café", "name": "Greek Salad", "description": "Feta, olives, cucumber, cherry tomatoes.", "price": 250.0, "category": "Salads", "is_vegetarian": True},
    {"restaurant": "Green Bowl Café", "name": "Mango Smoothie Bowl", "description": "Blended mango topped with granola and seeds.", "price": 220.0, "category": "Smoothies", "is_vegetarian": True},
    {"restaurant": "Green Bowl Café", "name": "Cold Brew Coffee", "description": "18-hour cold brew, served black.", "price": 150.0, "category": "Beverages", "is_vegetarian": True},
    # Biryani Bazaar
    {"restaurant": "Biryani Bazaar", "name": "Hyderabadi Chicken Dum Biryani", "description": "Signature dum-cooked biryani with raita.", "price": 350.0, "category": "Biryani", "is_vegetarian": False},
    {"restaurant": "Biryani Bazaar", "name": "Mutton Biryani", "description": "Slow-cooked mutton biryani with saffron.", "price": 420.0, "category": "Biryani", "is_vegetarian": False},
    {"restaurant": "Biryani Bazaar", "name": "Veg Dum Biryani", "description": "Seasonal vegetables and basmati, dum style.", "price": 260.0, "category": "Biryani", "is_vegetarian": True},
    {"restaurant": "Biryani Bazaar", "name": "Double Ka Meetha", "description": "Hyderabadi bread pudding with dry fruits.", "price": 130.0, "category": "Dessert", "is_vegetarian": True},
    # Taco Fiesta
    {"restaurant": "Taco Fiesta", "name": "Chicken Taco (3 pcs)", "description": "Soft corn tortillas, chipotle chicken, salsa.", "price": 240.0, "category": "Tacos", "is_vegetarian": False},
    {"restaurant": "Taco Fiesta", "name": "Veg Burrito", "description": "Beans, rice, cheese and salsa wrapped large.", "price": 280.0, "category": "Burritos", "is_vegetarian": True},
    {"restaurant": "Taco Fiesta", "name": "Churros with Chocolate", "description": "Crispy cinnamon churros, dark chocolate dip.", "price": 160.0, "category": "Dessert", "is_vegetarian": True},
]

CLASSIFIED_LISTINGS = [
    {"title": "iPhone 13 128GB - Midnight", "description": "2 years old, single owner, battery health 87%. Comes with box, charger and a clear case. No scratches, works perfectly.", "price": 32000.0, "category": "MOBILES", "condition": "GOOD",
     "location": "Bengaluru", "images": ["https://images.unsplash.com/photo-1592750475338-74b7b21085ab"], "seller": "karan@example.com"},
    {"title": "Dell XPS 15 (2021) - i7 / 16GB / 512GB", "description": "Upgraded SSD, mint condition. Great for development work. Selling because I moved to a Mac.", "price": 68000.0, "category": "LAPTOPS", "condition": "LIKE_NEW",
     "location": "Pune", "images": ["https://images.unsplash.com/photo-1517336714731-489689fd1ca8"], "seller": "aarav@example.com"},
    {"title": "Honda Activa 6G - 2022", "description": "12,000 km driven, recently serviced, new tyres. First owner, all papers clear.", "price": 58000.0, "category": "VEHICLES", "condition": "GOOD",
     "location": "Hyderabad", "images": ["https://images.unsplash.com/photo-1541899481282-d53bffe3c35d"], "seller": "vikram@example.com"},
    {"title": "IKEA Bookshelf - White", "description": "Practical 5-shelf unit. Minor scuff on one shelf, otherwise great. Easy pick-up by buyer.", "price": 4500.0, "category": "FURNITURE", "condition": "GOOD",
     "location": "Mumbai", "images": ["https://images.unsplash.com/photo-1594026112284-02bb6f3352fe"], "seller": "priya@example.com"},
    {"title": "Introduction to Algorithms (CLRS)", "description": "3rd edition, like new with no highlighting. A classic for every CS student.", "price": 1200.0, "category": "BOOKS", "condition": "LIKE_NEW",
     "location": "Delhi", "images": ["https://images.unsplash.com/photo-1544947950-fa07a98d237f"], "seller": "rohan@example.com"},
    {"title": "Samsung 43-inch 4K Smart TV", "description": "Bought 1 year ago, moving abroad. Includes wall mount and remote. All smart apps work smoothly.", "price": 24000.0, "category": "HOME_APPLIANCES", "condition": "GOOD",
     "location": "Bengaluru", "images": ["https://images.unsplash.com/photo-1593359677879-a4bb92f829d1"], "seller": "sneha@example.com"},
    {"title": "Nike Air Zoom Pegasus 40 - Size 9", "description": "Worn twice, practically new. Comfortable daily runner.", "price": 5000.0, "category": "CLOTHING", "condition": "NEW",
     "location": "Chennai", "images": ["https://images.unsplash.com/photo-1542291026-7eec264c27ff"], "seller": "ananya@example.com"},
    {"title": "Canon EOS 200D Mark II + 18-55mm Kit Lens", "description": "2500 shutter count, boxed with all accessories. Ideal starter DSLR.", "price": 38000.0, "category": "ELECTRONICS", "condition": "LIKE_NEW",
     "location": "Bengaluru", "images": ["https://images.unsplash.com/photo-1516035069371-29a1b244cc32"], "seller": "vikram@example.com"},
    {"title": "Mountain Bike - 27.5 inch", "description": "Hero Ranger, dual suspension, new chain and brake pads. Great for weekend trails.", "price": 9500.0, "category": "VEHICLES", "condition": "FAIR",
     "location": "Pune", "images": ["https://images.unsplash.com/photo-1507035895480-2b3156c31e8d"], "seller": "rohan@example.com"},
]

SURVEY_QUESTIONS = [
    {"text": "Which HTTP status code represents a successful request?", "type": "MCQ", "options": ["200", "301", "404", "500"], "correct_answer": "200", "difficulty": "EASY",
     "explanation": "200 OK indicates the request succeeded."},
    {"text": "What does REST stand for?", "type": "MCQ", "options": ["Representational State Transfer", "Remote Entity State Transfer", "Rapid Execution Server Technology", "Representative System Testing"], "correct_answer": "Representational State Transfer", "difficulty": "EASY",
     "explanation": "REST = Representational State Transfer, an architectural style for APIs."},
    {"text": "FastAPI's automatic interactive API documentation is available at which URL by default?", "type": "MCQ", "options": ["/docs", "/swagger", "/api-docs", "/documentation"], "correct_answer": "/docs", "difficulty": "MEDIUM",
     "explanation": "FastAPI serves Swagger UI at /docs and ReDoc at /redoc."},
    {"text": "MongoDB stores data in which format?", "type": "MCQ", "options": ["JSON-like documents (BSON)", "CSV rows", "XML files", "SQL tables"], "correct_answer": "JSON-like documents (BSON)", "difficulty": "EASY",
     "explanation": "MongoDB is a document database storing BSON documents."},
    {"text": "JWT stands for JSON Web Token.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "EASY",
     "explanation": "JWT = JSON Web Token, used for stateless authentication."},
    {"text": "An index in MongoDB can improve query performance.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "EASY",
     "explanation": "Indexes allow the database to locate documents faster."},
    {"text": "In the SOLID principles, 'S' stands for Single Responsibility.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "EASY",
     "explanation": "Single Responsibility Principle: a class should have one reason to change."},
    {"text": "Which of these is a NoSQL database?", "type": "MCQ", "options": ["MongoDB", "PostgreSQL", "MySQL", "SQLite"], "correct_answer": "MongoDB", "difficulty": "EASY",
     "explanation": "MongoDB is document-oriented NoSQL; the others are relational SQL databases."},
    {"text": "Which programming language is used by Flutter?", "type": "MCQ", "options": ["Dart", "Kotlin", "Swift", "JavaScript"], "correct_answer": "Dart", "difficulty": "EASY",
     "explanation": "Flutter apps are written in Dart."},
    {"text": "What is the default port of MongoDB?", "type": "MCQ", "options": ["27017", "3306", "5432", "6379"], "correct_answer": "27017", "difficulty": "MEDIUM",
     "explanation": "MongoDB listens on TCP port 27017 by default."},
    {"text": "CORS is a browser security mechanism.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "EASY",
     "explanation": "Cross-Origin Resource Sharing controls which origins may access resources."},
    {"text": "Password hashing is required before storing passwords in a database.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "EASY",
     "explanation": "Storing plaintext passwords is a severe security risk."},
    {"text": "Which widget in Flutter provides navigation between routes?", "type": "MCQ", "options": ["Navigator", "Container", "Column", "Scaffold"], "correct_answer": "Navigator", "difficulty": "MEDIUM",
     "explanation": "The Navigator manages a stack of routes."},
    {"text": "Which HTTP method is conventionally used for updating a resource?", "type": "MCQ", "options": ["PUT", "GET", "POST", "DELETE"], "correct_answer": "PUT", "difficulty": "EASY",
     "explanation": "PUT (or PATCH) is used to update resources; GET reads, POST creates, DELETE removes."},
    {"text": "BCrypt is an example of a secure password hashing algorithm.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "MEDIUM",
     "explanation": "BCrypt includes a salt and adaptive work factor."},
    {"text": "A Kanban board typically groups tasks by their status.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "EASY",
     "explanation": "Kanban columns such as Pending / In Progress / Done group tasks by status."},
    {"text": "What does CRUD stand for?", "type": "MCQ", "options": ["Create, Read, Update, Delete", "Create, Run, Update, Deploy", "Compile, Review, Upload, Download", "Copy, Rename, Undo, Delete"], "correct_answer": "Create, Read, Update, Delete", "difficulty": "EASY",
     "explanation": "CRUD is the four basic operations of persistent storage."},
    {"text": "Which protocol is used for secure web communication?", "type": "MCQ", "options": ["HTTPS", "FTP", "SMTP", "Telnet"], "correct_answer": "HTTPS", "difficulty": "EASY",
     "explanation": "HTTPS encrypts traffic between client and server using TLS."},
    {"text": "In a survey, true/false questions can be auto-scored.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "EASY",
     "explanation": "Both MCQ and TRUE/FALSE questions have deterministic correct answers."},
    {"text": "Flutter's build system for web produces JavaScript output.", "type": "TRUE_FALSE", "options": ["True", "False"], "correct_answer": "True", "difficulty": "MEDIUM",
     "explanation": "Flutter Web compiles Dart to JavaScript (or WebAssembly) for the browser."},
]

PROJECTS = [
    {"name": "Full Stack Web Lab", "description": "Building the unified laboratory platform with 7 experiments.", "color": "#6366f1"},
    {"name": "Portfolio Website", "description": "Personal portfolio with resume, projects and contact form.", "color": "#0ea5e9"},
    {"name": "DBMS Mini Project", "description": "Library management database schema design and queries.", "color": "#10b981"},
]

TASKS = [
    {"project": "Full Stack Web Lab", "title": "Design FastAPI backend structure", "description": "Define routes, schemas, services and repositories.", "priority": "HIGH", "status": "COMPLETED", "assigned_to": "Aarav Sharma", "due_offset": -3},
    {"project": "Full Stack Web Lab", "title": "Implement JWT authentication", "description": "Register, login, password hashing and protected routes.", "priority": "CRITICAL", "status": "COMPLETED", "assigned_to": "Rohan Mehta", "due_offset": -2},
    {"project": "Full Stack Web Lab", "title": "Build TODO experiment UI", "description": "Login-gated todo dashboard with filters and stats.", "priority": "HIGH", "status": "IN_PROGRESS", "assigned_to": "Ananya Rao", "due_offset": 1},
    {"project": "Full Stack Web Lab", "title": "Seed MongoDB with demo data", "description": "Restaurants, listings, questions, tasks and users.", "priority": "MEDIUM", "status": "IN_PROGRESS", "assigned_to": "Sneha Iyer", "due_offset": 2},
    {"project": "Full Stack Web Lab", "title": "Write backend integration tests", "description": "Auth, todos, posts, orders, leaves, tasks and survey tests.", "priority": "MEDIUM", "status": "PENDING", "assigned_to": "Rohan Mehta", "due_offset": 4},
    {"project": "Full Stack Web Lab", "title": "Animate dashboard cards", "description": "Hover effects and page transitions for the lab dashboard.", "priority": "LOW", "status": "PENDING", "assigned_to": "Priya Patel", "due_offset": 6},
    {"project": "Portfolio Website", "title": "Set up home page hero", "description": "Hero section with intro, photo and call to action.", "priority": "HIGH", "status": "COMPLETED", "assigned_to": "Aarav Sharma", "due_offset": -6},
    {"project": "Portfolio Website", "title": "Add projects gallery", "description": "Grid of project cards with hover effects.", "priority": "MEDIUM", "status": "COMPLETED", "assigned_to": "Aarav Sharma", "due_offset": -4},
    {"project": "Portfolio Website", "title": "Write blog section", "description": "Markdown-rendered blog with 3 posts.", "priority": "LOW", "status": "IN_PROGRESS", "assigned_to": "Ishita Gupta", "due_offset": 3},
    {"project": "DBMS Mini Project", "title": "Normalize schema to 3NF", "description": "Library schema: members, books, loans.", "priority": "HIGH", "status": "COMPLETED", "assigned_to": "Rohan Mehta", "due_offset": -5},
    {"project": "DBMS Mini Project", "title": "Write aggregation queries", "description": "Top borrowed books, overdue reports.", "priority": "MEDIUM", "status": "PENDING", "assigned_to": "Sneha Iyer", "due_offset": 5},
]

BLOG_SEED = [
    ("aarav@example.com", "Just deployed my first FastAPI app to production. The /docs endpoint is such a gift for API users. #webdev #fastapi"),
    ("aarav@example.com", "Tip of the day: always hash passwords with bcrypt. Your future self (and your users) will thank you. #security"),
    ("priya@example.com", "Designed a Material 3 dashboard today. The color system saves me so much time. #flutter #ui"),
    ("priya@example.com", "Empty states matter! A friendly empty state is better than a scary blank page. #ux"),
    ("rohan@example.com", "MongoDB indexes turn slow queries into instant ones. Learned this the hard way in the lab. #mongodb"),
    ("rohan@example.com", "Debugging a flaky integration test at 11 PM. Sleep is for people with passing test suites. #codinglife"),
    ("sneha@example.com", "My todo list just crossed 40 items. Time to prioritize and archive. #productivity"),
    ("vikram@example.com", "Cooked butter chicken from scratch today. The lab can wait. 😋"),
    ("ananya@example.com", "Flutter Web is surprisingly smooth for dashboards. Single codebase, zero regrets. #flutterweb"),
    ("karan@example.com", "Sold my Activa through the classifieds module demo. Negotiation is an art form. #marketplace"),
    ("ishita@example.com", "Leave balance: casual 8, medical 10, earned 15. Planning a short trip next month. #worklife"),
    ("aarav@example.com", "Random survey questions on every attempt make demo days way more interesting. #survey"),
]


def days_from_now(days: int) -> str:
    return (date.today() + timedelta(days=days)).isoformat()


async def seed(db, db_name: str, verbose: bool = True) -> None:
    def log(msg: str) -> None:
        if verbose:
            print(msg)

    start = time.perf_counter()

    # --- Users ---
    await db.users.drop()
    user_ids: dict[str, str] = {}
    for i, u in enumerate(DEMO_USERS):
        password = settings.SEED_ADMIN_PASSWORD if u["role"] == "ADMIN" else PASSWORD
        doc = {
            **u,
            "password_hash": hash_password(password),
            "created_at": utc_now_iso(),
        }
        result = await db.users.insert_one(doc)
        user_ids[u["email"]] = str(result.inserted_id)
    log(f"Seeded {len(DEMO_USERS)} users (demo password: {PASSWORD}, admin: {settings.SEED_ADMIN_EMAIL})")

    # --- Follows ---
    await db.follows.drop()
    follow_pairs = [
        ("aarav@example.com", "priya@example.com"),
        ("aarav@example.com", "rohan@example.com"),
        ("priya@example.com", "aarav@example.com"),
        ("priya@example.com", "sneha@example.com"),
        ("rohan@example.com", "aarav@example.com"),
        ("rohan@example.com", "sneha@example.com"),
        ("sneha@example.com", "aarav@example.com"),
        ("vikram@example.com", "aarav@example.com"),
        ("ananya@example.com", "priya@example.com"),
        ("karan@example.com", "vikram@example.com"),
        ("ishita@example.com", "sneha@example.com"),
    ]
    if follow_pairs:
        await db.follows.insert_many([
            {"follower_id": user_ids[f], "following_id": user_ids[t], "created_at": utc_now_iso()}
            for f, t in follow_pairs
        ])
    log(f"Seeded {len(follow_pairs)} follow relationships")

    # --- Blog posts + likes ---
    await db.posts.drop()
    await db.likes.drop()
    import random
    random.seed(42)
    posts = []
    likes = []
    post_ids: list[str] = []
    for i, (author_email, content) in enumerate(BLOG_SEED):
        result = await db.posts.insert_one({
            "author_id": user_ids[author_email],
            "content": content,
            "likes_count": 0,
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
        })
        post_ids.append(str(result.inserted_id))
        posts.append((str(result.inserted_id), user_ids[author_email]))
    # random likes
    like_users = list(user_ids.values())[:8]
    for pid in post_ids:
        for lu in random.sample(like_users, k=random.randint(0, 3)):
            likes.append({"user_id": lu, "post_id": pid})
    if likes:
        try:
            await db.likes.insert_many(likes)
        except Exception:
            pass
    like_counts: dict[str, int] = {}
    for l in likes:
        like_counts[l["post_id"]] = like_counts.get(l["post_id"], 0) + 1
    for pid, count in like_counts.items():
        await db.posts.update_one({"_id": pid}, {"$set": {"likes_count": count}})
    log(f"Seeded {len(BLOG_SEED)} posts and {len(likes)} likes")

    # --- Todos ---
    await db.todos.drop()
    todos = [
        ("aarav@example.com", "Submit DBMS assignment", "Normalize the library schema to 3NF and upload report.", "Academics", "HIGH", 1, False),
        ("aarav@example.com", "Prepare for viva", "Revise ER diagrams and relational algebra.", "Academics", "MEDIUM", 3, False),
        ("aarav@example.com", "Buy groceries", "Milk, eggs, bread and coffee beans.", "Personal", "LOW", 0, True),
        ("priya@example.com", "Wireframe the survey app", "Sketch question flow for 5 random questions.", "Work", "HIGH", 2, False),
        ("priya@example.com", "Weekly design review", "Peer review of the food delivery cards.", "Work", "MEDIUM", -1, True),
        ("rohan@example.com", "Set up MongoDB Atlas", "Create cluster and whitelist IPs for the lab.", "Lab", "URGENT", 1, False),
        ("rohan@example.com", "Refactor repository layer", "Move query logic out of routes.", "Lab", "MEDIUM", 5, False),
        ("sneha@example.com", "Plan product roadmap deck", "Slides for the leave management demo.", "Work", "HIGH", 4, False),
        ("sneha@example.com", "Yoga class booking", "Book Monday evening session.", "Personal", "LOW", 0, True),
        ("vikram@example.com", "Research survey scoring", "How to auto-score short answers meaningfully.", "Lab", "MEDIUM", 6, False),
        ("ananya@example.com", "Fix chart animation jank", "Optimize animated counters on dashboard.", "Lab", "MEDIUM", 2, False),
        ("ishita@example.com", "Review leave policy", "Read updated casual leave policy document.", "Work", "LOW", 7, False),
    ]
    for email, title, desc, cat, priority, due_offset, done in todos:
        await db.todos.insert_one({
            "user_id": user_ids[email],
            "title": title,
            "description": desc,
            "category": cat,
            "priority": priority,
            "due_date": days_from_now(due_offset),
            "completed": done,
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
        })
    log(f"Seeded {len(todos)} todos")

    # --- Restaurants + food items ---
    await db.restaurants.drop()
    await db.food_items.drop()
    rid_by_name: dict[str, str] = {}
    for r in RESTAURANTS:
        result = await db.restaurants.insert_one(r)
        rid_by_name[r["name"]] = str(result.inserted_id)
    for item in FOOD_ITEMS:
        await db.food_items.insert_one({
            "restaurant_id": rid_by_name[item["restaurant"]],
            "name": item["name"],
            "description": item["description"],
            "price": item["price"],
            "category": item["category"],
            "is_vegetarian": item["is_vegetarian"],
            "is_available": True,
        })
    log(f"Seeded {len(RESTAURANTS)} restaurants and {len(FOOD_ITEMS)} food items")

    # --- Classified listings + favorites ---
    await db.listings.drop()
    await db.favorites.drop()
    listing_ids: list[str] = []
    for i, l in enumerate(CLASSIFIED_LISTINGS):
        result = await db.listings.insert_one({
            "seller_id": user_ids[l["seller"]],
            "title": l["title"],
            "description": l["description"],
            "price": l["price"],
            "category": l["category"],
            "condition": l["condition"],
            "location": l["location"],
            "images": l["images"],
            "status": "AVAILABLE",
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
        })
        listing_ids.append(str(result.inserted_id))
    await db.favorites.insert_many([
        {"user_id": user_ids["aarav@example.com"], "listing_id": listing_ids[0], "created_at": utc_now_iso()},
        {"user_id": user_ids["aarav@example.com"], "listing_id": listing_ids[3], "created_at": utc_now_iso()},
        {"user_id": user_ids["priya@example.com"], "listing_id": listing_ids[7], "created_at": utc_now_iso()},
    ])
    log(f"Seeded {len(CLASSIFIED_LISTINGS)} listings and 3 favorites")

    # --- Leave balances + requests ---
    await db.leave_balances.drop()
    await db.leave_requests.drop()
    for email in ["aarav@example.com", "priya@example.com", "rohan@example.com", "sneha@example.com",
                  "vikram@example.com", "ananya@example.com", "karan@example.com", "ishita@example.com"]:
        await db.leave_balances.insert_one({
            "user_id": user_ids[email],
            "casual_leave": 6.0,
            "medical_leave": 8.0,
            "earned_leave": 10.0,
            "other_leave": 3.0,
            "created_at": utc_now_iso(),
        })
    leave_requests = [
        ("aarav@example.com", "CASUAL", 1, "Going home for a family function", "APPROVED", "ishita@example.com"),
        ("aarav@example.com", "MEDICAL", 2, "Doctor appointment and rest", "PENDING", None),
        ("priya@example.com", "EARNED", 5, "Vacation trip to Goa", "PENDING", None),
        ("rohan@example.com", "CASUAL", 1, "Sick", "REJECTED", "ishita@example.com"),
        ("sneha@example.com", "MEDICAL", 1, "Dental procedure", "APPROVED", "ishita@example.com"),
    ]
    admin_id = user_ids[settings.SEED_ADMIN_EMAIL]
    for email, ltype, days, reason, status, approver in leave_requests:
        await db.leave_requests.insert_one({
            "user_id": user_ids[email],
            "leave_type": ltype,
            "start_date": days_from_now(2),
            "end_date": days_from_now(2 + days - 1),
            "number_of_days": days,
            "reason": reason,
            "status": status,
            "approved_by": admin_id if approver else None,
            "decision_remark": "" if status == "PENDING" else "Seeded demo decision",
            "created_at": utc_now_iso(),
        })
    log(f"Seeded {len(leave_requests)} leave requests and 8 balances")

    # --- Projects + tasks ---
    await db.projects.drop()
    await db.tasks.drop()
    pid_by_name: dict[str, str] = {}
    for p in PROJECTS:
        result = await db.projects.insert_one({**p, "created_at": utc_now_iso()})
        pid_by_name[p["name"]] = str(result.inserted_id)
    for t in TASKS:
        await db.tasks.insert_one({
            "project_id": pid_by_name[t["project"]],
            "title": t["title"],
            "description": t["description"],
            "priority": t["priority"],
            "status": t["status"],
            "due_date": days_from_now(t["due_offset"]),
            "assigned_to": t["assigned_to"],
            "created_at": utc_now_iso(),
            "updated_at": utc_now_iso(),
        })
    log(f"Seeded {len(PROJECTS)} projects and {len(TASKS)} tasks")

    # --- Survey questions ---
    await db.questions.drop()
    for q in SURVEY_QUESTIONS:
        await db.questions.insert_one({**q, "created_at": utc_now_iso()})
    log(f"Seeded {len(SURVEY_QUESTIONS)} survey questions")

    # --- Example orders (delivered demo order) ---
    await db.orders.drop()
    await db.addresses.drop()
    address_result = await db.addresses.insert_one({
        "user_id": user_ids["aarav@example.com"],
        "label": "Home",
        "full_name": "Aarav Sharma",
        "phone": "+91 98989 12345",
        "address_line": "Flat 302, Indiranagar 2nd Stage",
        "city": "Bengaluru",
        "state": "Karnataka",
        "postal_code": "560038",
        "created_at": utc_now_iso(),
    })
    food_rid = rid_by_name["Pizza Paradiso"]
    pepperoni = await db.food_items.find_one({"restaurant_id": food_rid, "name": "Pepperoni Pizza"})
    margherita = await db.food_items.find_one({"restaurant_id": food_rid, "name": "Margherita Pizza"})
    items = [
        {"food_item_id": str(pepperoni["_id"]), "name": pepperoni["name"], "price": pepperoni["price"], "quantity": 1, "subtotal": pepperoni["price"]},
        {"food_item_id": str(margherita["_id"]), "name": margherita["name"], "price": margherita["price"], "quantity": 2, "subtotal": margherita["price"] * 2},
    ]
    subtotal = round(sum(i["subtotal"] for i in items), 2)
    await db.orders.insert_one({
        "user_id": user_ids["aarav@example.com"],
        "restaurant_id": food_rid,
        "restaurant_name": "Pizza Paradiso",
        "items": items,
        "subtotal": subtotal,
        "delivery_fee": 30.0,
        "total": round(subtotal + 30.0, 2),
        "address": {"label": "Home", "full_name": "Aarav Sharma", "phone": "+91 98989 12345",
                    "address_line": "Flat 302, Indiranagar 2nd Stage", "city": "Bengaluru",
                    "state": "Karnataka", "postal_code": "560038"},
        "payment_method": "ONLINE",
        "status": "DELIVERED",
        "status_history": [
            {"status": "PLACED", "at": utc_now_iso(), "note": "Order placed"},
            {"status": "CONFIRMED", "at": utc_now_iso(), "note": "Restaurant confirmed"},
            {"status": "PREPARING", "at": utc_now_iso(), "note": "Being prepared"},
            {"status": "OUT_FOR_DELIVERY", "at": utc_now_iso(), "note": "On the way"},
            {"status": "DELIVERED", "at": utc_now_iso(), "note": "Delivered"},
        ],
        "created_at": utc_now_iso(),
    })
    log("Seeded 1 example order and 1 address")

    elapsed = round(time.perf_counter() - start, 2)
    log(f"Seeding completed in {elapsed}s against database '{db_name}'")


async def main() -> None:
    import os
    import sys
    override_uri = os.environ.get("MONGODB_URI", "")
    uri = override_uri or settings.MONGODB_URI
    db_name = os.environ.get("DATABASE_NAME", settings.DATABASE_NAME)

    print(f"Connecting to MongoDB: {uri.split('@')[-1] if '@' in uri else uri}")
    client = AsyncIOMotorClient(uri, serverSelectionTimeoutMS=10000)
    try:
        await client.admin.command("ping")
    except Exception as exc:
        print(f"ERROR: could not connect to MongoDB at {uri}: {exc}")
        sys.exit(1)

    db = client[db_name]
    await seed(db, db_name)
    client.close()
    print("Done. You can now run: .venv/bin/uvicorn app.main:app --reload")


if __name__ == "__main__":
    asyncio.run(main())