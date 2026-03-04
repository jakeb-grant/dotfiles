# How to Structure a FastAPI Application

A practical guide for AI agents building FastAPI backends, derived from real production patterns and the [official FastAPI docs](https://fastapi.tiangolo.com/tutorial/bigger-applications/).

---

## Directory Layout

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # App creation, middleware, router registration
│   ├── dependencies.py         # Shared dependency injection functions + type aliases
│   ├── core/                   # Cross-cutting infrastructure
│   │   ├── __init__.py
│   │   ├── config.py           # Settings via pydantic-settings
│   │   ├── database.py         # Engine, session factory, base model
│   │   ├── security.py         # JWT, hashing, token generation
│   │   ├── rate_limit.py       # Rate limiting setup
│   │   └── timezone.py         # Timestamp utilities
│   ├── models/                 # SQLAlchemy ORM models (one file per entity)
│   │   ├── __init__.py         # Re-exports all models (critical for create_all)
│   │   ├── user.py
│   │   ├── project.py
│   │   └── comment.py
│   ├── schemas/                # Pydantic request/response models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── project.py
│   │   └── auth.py
│   └── routers/                # API endpoint groups (one file per domain)
│       ├── __init__.py
│       ├── auth.py
│       └── projects.py
├── tests/
├── pyproject.toml
└── .env
```

### Why this layout works

| Layer | Responsibility | Rule of thumb |
|-------|---------------|---------------|
| `main.py` | App factory, middleware, router registration | Should be short — mostly wiring |
| `core/` | Infrastructure that routes depend on but isn't route-specific | If two routers need it, it lives here |
| `models/` | Database table definitions | One file per entity or tightly coupled group |
| `schemas/` | Pydantic models for request/response validation | Mirror the models structure |
| `routers/` | HTTP endpoints grouped by domain | One `APIRouter` per file |
| `dependencies.py` | Shared `Depends()` callables | The glue between core/ and routers/ |

### How a request flows through the layers

```
HTTP Request
  → SlowAPI Rate Limiter (429 if exceeded)
  → CORS Middleware
  → FastAPI routing (matches path to router endpoint)
  → Dependency resolution:
      HTTPBearer extracts token
      → get_db() opens database session
      → get_current_user() validates JWT, loads user
      → get_current_moderator() checks role
  → Route handler:
      → Resource-level permission checks (is_project_owner, etc.)
      → Business logic + DB queries
      → db.flush() + db.refresh() for new/updated objects
      → model_validate() to build response schema
  → get_db() auto-commits (or rolls back on error)
  → HTTP Response
```

---

## 1. App Initialization (`main.py`)

Keep `main.py` focused on four things: lifecycle, middleware, rate limiting, and router registration.

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from app.core.database import create_tables, engine
from app.core.rate_limit import limiter
from app.routers import auth, projects

@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()  # Startup
    yield
    await engine.dispose()  # Shutdown: close connection pool

app = FastAPI(title="My App", lifespan=lifespan)

# Rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)  # type: ignore[arg-type]
app.add_middleware(SlowAPIMiddleware)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers — import the module, access .router to avoid name collisions
app.include_router(auth.router)
app.include_router(projects.router)

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### Key decisions

- **Lifespan over `on_event`**: The `@asynccontextmanager` lifespan pattern is the modern replacement for deprecated `@app.on_event("startup")` decorators.
- **Import modules, not `router` directly**: Avoids name collisions when multiple routers exist.
- **Middleware registration order**: In Starlette/FastAPI, the *last* registered middleware wraps the outermost layer and executes first on incoming requests. In the code above, `CORSMiddleware` is registered last, so it runs first — handling CORS preflight and headers before `SlowAPIMiddleware` checks rate limits. This ensures rate-limited responses still include CORS headers.
- **Health check on main app**: Simple endpoints that don't belong to a domain can live directly on `app`.
- **CORS for production**: Never hardcode `allow_origins`. Pull from `settings.FRONTEND_URL` (or a list setting) so the value changes per environment. Never combine `allow_origins=["*"]` with `allow_credentials=True` — browsers will reject the response.
- **`root_path` for reverse proxies**: If the app runs behind a reverse proxy that adds a path prefix (e.g., Nginx forwarding `/api/v1/*`), set `root_path` so OpenAPI docs generate correct URLs: `app = FastAPI(..., root_path="/api/v1")`. Alternatively, pass it at runtime: `uvicorn app.main:app --root-path /api/v1`. Not needed when the proxy forwards at `/` with no path prefix.

---

## 2. Router Organization

Each router file owns a domain. Set `prefix` and `tags` at the router level — not on each endpoint.

```python
# app/routers/projects.py
from fastapi import APIRouter, HTTPException, status
from app.dependencies import CurrentUser, DbSession
from app.models.project import Project
from app.schemas.project import ProjectCreate, ProjectResponse

router = APIRouter(prefix="/projects", tags=["projects"])

@router.post("/", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    data: ProjectCreate,
    user: CurrentUser,
    db: DbSession,
) -> ProjectResponse:
    """Create a new project."""
    project = Project(owner_id=user.id, name=data.name)
    db.add(project)
    await db.flush()
    await db.refresh(project)
    return ProjectResponse.model_validate(project)
```

### HTTP status codes

Use explicit status constants from `fastapi.status`, not bare integers.

| Status | When to use | Route pattern |
|--------|-------------|---------------|
| `HTTP_201_CREATED` | Resource created | `@router.post("/", status_code=status.HTTP_201_CREATED)` |
| `HTTP_204_NO_CONTENT` | Deletion successful | `@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)` with `-> None` return |
| `HTTP_400_BAD_REQUEST` | Business logic violation | Capacity reached, duplicate entry, invalid state transition |
| `HTTP_401_UNAUTHORIZED` | Missing/invalid auth | Always include `headers={"WWW-Authenticate": "Bearer"}` |
| `HTTP_403_FORBIDDEN` | Insufficient permissions | User is authenticated but lacks the required role or resource access |
| `HTTP_404_NOT_FOUND` | Resource doesn't exist | Always include a descriptive `detail` message |

```python
# Always include detail messages — they're your API's error documentation
raise HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Not authenticated",
    headers={"WWW-Authenticate": "Bearer"},  # Required for 401s per HTTP spec
)

raise HTTPException(
    status_code=status.HTTP_400_BAD_REQUEST,
    detail="Project is archived and cannot be modified",  # Tells the client *why*
)
```

### Router registration patterns

```python
# Basic — prefix and tags defined in the router file
app.include_router(auth.router)

# Override at inclusion — useful for shared/reusable routers
app.include_router(
    admin.router,
    prefix="/admin",
    tags=["admin"],
    dependencies=[Depends(require_admin)],
)
```

### When to split a router

Split when a router file exceeds ~300 lines or handles two clearly distinct resources. A `projects.py` router that also manages tasks is fine if tasks are always accessed through a project. If tasks gain their own top-level routes, split them out.

### `async def` vs `def` route handlers

FastAPI runs `async def` handlers on the main event loop and `def` handlers in a threadpool. Choose based on what the handler does:

| Handler type | Use when | Example |
|-------------|----------|---------|
| `async def` | All I/O is async (async DB, `httpx`, etc.) | Most routes in this guide |
| `def` | Calling synchronous/blocking libraries (file I/O without `aiofiles`, CPU-bound work, sync DB drivers) | Image processing, PDF generation |

> **Trap**: An `async def` handler that calls blocking code (e.g., `time.sleep`, synchronous `requests`, CPU-heavy computation) will block the entire event loop. If you can't make the call async, use a plain `def` handler — FastAPI will run it in a threadpool automatically.

---

## 3. Dependency Injection

This is the most important architectural pattern in FastAPI. Dependencies are composable functions that handle auth, DB sessions, permissions, and shared logic.

### The dependency file

```python
# app/dependencies.py
import uuid
from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.user import User, UserRole

security_scheme = HTTPBearer(auto_error=False)

async def get_current_user_optional(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User | None:
    if not credentials:
        return None
    payload = decode_access_token(credentials.credentials)
    if not payload:
        return None
    try:
        user_id = uuid.UUID(payload["sub"])
    except (ValueError, KeyError):
        return None
    return await db.get(User, user_id)

async def get_current_user(
    user: Annotated[User | None, Depends(get_current_user_optional)],
) -> User:
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

async def get_current_moderator(user: Annotated[User, Depends(get_current_user)]) -> User:
    if user.role not in (UserRole.ADMIN, UserRole.MODERATOR):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Moderator access required")
    return user

async def get_current_admin(user: Annotated[User, Depends(get_current_user)]) -> User:
    if user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    return user

# Type aliases — the key ergonomic pattern
CurrentUser = Annotated[User, Depends(get_current_user)]
CurrentUserOptional = Annotated[User | None, Depends(get_current_user_optional)]
CurrentModerator = Annotated[User, Depends(get_current_moderator)]
CurrentAdmin = Annotated[User, Depends(get_current_admin)]
DbSession = Annotated[AsyncSession, Depends(get_db)]
```

### Why type aliases matter

Without aliases, every route parameter looks like:
```python
async def endpoint(user: Annotated[User, Depends(get_current_user)], db: Annotated[AsyncSession, Depends(get_db)]):
```

With aliases:
```python
async def endpoint(user: CurrentUser, db: DbSession):
```

The aliases are self-documenting, reusable, and enforce consistency. This is the single highest-leverage pattern in a FastAPI codebase.

### Dependency composition

Dependencies chain naturally. `get_current_moderator` depends on `get_current_user`, which depends on `get_current_user_optional`, which depends on `get_db` and the security scheme. FastAPI resolves this graph automatically and — thanks to `use_cache=True` (the default on `Depends()`) — only calls each dependency once per request, reusing the result for subsequent injections. Pass `Depends(get_value, use_cache=False)` if you need a fresh invocation each time (rare, but useful for non-deterministic values).

```
HTTPBearer → get_current_user_optional → get_current_user → get_current_moderator
                     ↑
                   get_db
```

### Dependencies with `yield` (resource cleanup)

Regular dependencies return a value. Dependencies that manage resources with a setup/teardown lifecycle use `yield` instead:

```python
async def get_http_client() -> AsyncGenerator[httpx.AsyncClient, None]:
    async with httpx.AsyncClient() as client:
        yield client  # Setup: create client, inject into route
    # Teardown: client is closed after the response is sent
```

FastAPI calls the function up to the `yield`, injects the yielded value into the route, then resumes execution after `yield` for cleanup. This is the standard pattern for database sessions, HTTP clients, file handles, and any resource that must be released. The `get_db()` dependency in Section 5 uses this pattern.

### Resource-level permission helpers

Role-based dependencies (`CurrentAdmin`, etc.) cover broad access control. For resource-level checks — "can this user modify *this specific* project?" — use helper functions called directly in routes.

```python
# app/dependencies.py (continued)
from app.models.project import Project

async def get_project_or_404(project_id: uuid.UUID, db: AsyncSession) -> Project:
    """Fetch a project or raise 404."""
    result = await db.execute(select(Project).where(Project.id == project_id))
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    return project

async def check_project_owner(project: Project, user: User) -> None:
    """Raise 403 if user doesn't own the project (unless admin)."""
    if user.role == UserRole.ADMIN:
        return
    if project.owner_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

async def check_project_member(project: Project, user: User, db: AsyncSession) -> None:
    """Raise 403 if user is not a member of the project."""
    if user.role == UserRole.ADMIN or project.owner_id == user.id:
        return
    result = await db.execute(
        select(Membership).where(
            Membership.user_id == user.id,
            Membership.project_id == project.id,
            Membership.status == MembershipStatus.ACTIVE,
        )
    )
    if result.scalar_one_or_none() is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
```

**These are not `Depends()` callables** — they take explicit parameters and are called in route handlers:

```python
@router.put("/{project_id}")
async def update_project(project_id: uuid.UUID, user: CurrentUser, db: DbSession) -> ProjectResponse:
    project = await get_project_or_404(project_id, db)  # Single fetch
    await check_project_member(project, user, db)        # No re-fetch needed
    ...
```

**When to use which pattern:**

| Pattern | Use for | Example |
|---------|---------|---------|
| `Depends()` type alias | Cross-cutting auth (every route needs it) | `CurrentUser`, `CurrentAdmin` |
| Fetch + check helpers | Resource-specific checks (varies per route) | `get_project_or_404()` + `check_project_owner()` |

---

## 4. Configuration (`core/config.py`)

Use `pydantic-settings` for validated, typed configuration from environment variables.

```python
import secrets
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    APP_NAME: str = "My App"
    DEV_MODE: bool = True
    DATABASE_URL: str = "sqlite+aiosqlite:///./dev.db"
    SECRET_KEY: str = secrets.token_urlsafe(32)  # ⚠ See warning below
    ACCESS_TOKEN_EXPIRE_DAYS: int = 30
    FRONTEND_URL: str = "http://localhost:5173"
    BACKEND_URL: str = "http://localhost:8000"

settings = Settings()
```

### Rules

- **Singleton at module level**: Import `settings` everywhere, never instantiate `Settings()` again.
- **Sensible dev defaults**: Every setting should work out of the box for local development.
- **No secrets in code**: Production secrets come from environment variables or `.env`.
- **`extra="ignore"`**: Prevents crashes from unrelated environment variables.
- **SECRET_KEY warning**: Using `secrets.token_urlsafe(32)` as the default generates a new key each time the module is loaded. This causes **two problems**: (1) **Multi-worker breakage** — with `uvicorn --workers N` or gunicorn, each worker generates a different key, so JWTs from worker 1 are invalid on worker 2, causing intermittent 401 errors. (2) **Restart invalidation** — every restart generates a new key, invalidating all existing JWTs. This default is acceptable only for single-worker local development. Always set `SECRET_KEY` explicitly via `.env` for production or multi-worker setups.
- **Commit a `.env.example`**: List every expected variable with empty or placeholder values. This serves as documentation for new developers and deployment environments. Never commit the actual `.env` file.

```bash
# .env.example — commit this, NOT .env
APP_NAME=
DEV_MODE=
DATABASE_URL=
SECRET_KEY=
FRONTEND_URL=
BACKEND_URL=
```

---

## 5. Database Setup (`core/database.py`)

```python
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.ext.asyncio import AsyncAttrs
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEV_MODE,  # Log SQL queries in development
)
async_session_factory = async_sessionmaker(engine, expire_on_commit=False)

class Base(AsyncAttrs, DeclarativeBase):
    pass

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

### Key decisions

- **`AsyncAttrs` mixin**: Recommended for async SQLAlchemy. It provides `awaitable_attrs` for accessing lazy-loaded relationships (e.g., `await user.awaitable_attrs.projects`). Without it, you must always use eager loading (`selectinload`, `joinedload`) to avoid `MissingGreenlet` errors. Including it gives you a fallback when eager loading isn't configured.
- **`expire_on_commit=False`**: Objects remain usable after commit without re-querying. Essential for returning ORM objects as responses.
- **Auto-commit in `get_db()`**: The session commits when the route succeeds and rolls back on exception. Routes don't need to call `commit()` explicitly. **Tradeoff**: This makes transaction boundaries invisible — every route is one implicit transaction. If a route needs multiple independent transactions (e.g., "save audit log even if the main operation fails"), you'll need to open a separate session manually. Note that `HTTPException` also triggers the rollback — if a route writes to the database and then raises `HTTPException` (e.g., log an access attempt then return 403), those writes are rolled back. This is intentional: the request is atomic.
- **`echo=settings.DEV_MODE`**: Logs all generated SQL in development — invaluable for debugging N+1 queries and understanding ORM behavior.
- **`create_all` on startup**: Acceptable for development. Use Alembic migrations in production (see below).

### Alembic migrations (production)

`create_all()` won't modify existing tables. For production, use Alembic:

```
backend/
├── alembic/
│   ├── versions/        # Generated migration files
│   ├── env.py           # Configure to use your async engine and Base.metadata
│   └── script.py.mako
├── alembic.ini          # Points to your DATABASE_URL
└── app/
    └── ...
```

Key setup steps:
1. `alembic init alembic` — scaffold the directory
2. In `alembic/env.py`, import your `Base.metadata` and configure the async engine (use `run_async_migrations` pattern from Alembic docs)
3. `alembic revision --autogenerate -m "description"` — generate migrations from model changes
4. `alembic upgrade head` — apply migrations

Remove `create_tables()` from the lifespan once migrations are in place.

### Transaction patterns: flush, refresh, commit

Routes rarely call `commit()` directly — `get_db()` handles that. Instead, use `flush()` and `refresh()`:

```python
@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_project(data: ProjectCreate, user: CurrentUser, db: DbSession) -> ProjectResponse:
    project = Project(owner_id=user.id, name=data.name)
    db.add(project)
    await db.flush()            # 1. Persist to DB (gets auto-generated ID) without committing
    await db.refresh(project)   # 2. Reload to pick up server-side defaults (created_at, etc.)
    return ProjectResponse.model_validate(project)  # 3. Return with all fields populated
    # get_db() auto-commits after the route returns successfully
```

**When to use each:**

| Operation | What it does | When to use |
|-----------|-------------|-------------|
| `db.add(obj)` | Stages object for insertion | Always — before flush |
| `await db.flush()` | Sends SQL to DB without committing | When you need the auto-generated ID or want to validate constraints mid-request |
| `await db.refresh(obj)` | Reloads object from DB | After flush, when you need server-side defaults (timestamps, computed columns) |
| `await db.commit()` | Finalizes the transaction | Rarely — `get_db()` handles this. Only use in standalone utility functions |

### Query result extraction

SQLAlchemy's async API returns `Result` objects. Common patterns for extracting data:

```python
# Single object (or None)
result = await db.execute(select(User).where(User.email == email))
user = result.scalar_one_or_none()

# List of objects
result = await db.execute(select(Project).where(Project.owner_id == user.id))
projects = result.scalars().all()

# Scalar value (COUNT, SUM, etc.)
result = await db.execute(select(func.count()).select_from(Comment).where(...))
count = result.scalar() or 0

# Multi-table join with tuple unpacking
result = await db.execute(
    select(Comment, User)
    .join(User, Comment.author_id == User.id)
    .where(Comment.project_id == project_id)
    .order_by(Comment.created_at)
)
rows = result.all()
for comment, author in rows:
    ...  # Each row is a tuple of (Comment, User)

# Eager loading — prevent MissingGreenlet errors on relationships
from sqlalchemy.orm import selectinload, joinedload

# selectinload: issues a second SELECT (good for one-to-many)
result = await db.execute(
    select(Project)
    .where(Project.owner_id == user.id)
    .options(selectinload(Project.comments))
)
projects = result.scalars().all()
# projects[0].comments is already loaded — no await needed

# joinedload: uses a JOIN (good for many-to-one / one-to-one)
result = await db.execute(
    select(Comment)
    .where(Comment.project_id == project_id)
    .options(joinedload(Comment.author))
)
comments = result.scalars().unique().all()  # unique() required with joinedload
# comments[0].author is already loaded
```

**Eager loading rule of thumb**: Use `selectinload` for collections (one-to-many), `joinedload` for single objects (many-to-one). Always call `.unique()` on results when using `joinedload` — the JOIN can produce duplicate parent rows.

**Relationship-level loading**: You can also set the default loading strategy on the relationship itself with `lazy="selectin"`:

```python
comments: Mapped[list["Comment"]] = relationship(
    back_populates="project", cascade="all, delete-orphan", lazy="selectin",
)
```

This eliminates `.options(selectinload(...))` on every query, but means the relationship is *always* loaded — even when you don't need it. Prefer query-time `selectinload()` for relationships only sometimes accessed. Use `lazy="selectin"` for associations that are almost always read (e.g., user role assignments).

---

## 6. Models (`models/`)

One file per entity. Use UUID primary keys and string-valued enums.

```python
# app/models/user.py
import uuid
from enum import Enum
from datetime import datetime
from sqlalchemy import String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base, StringEnum  # StringEnum defined in database.py — see below
from app.core.timezone import utc_now

class UserRole(str, Enum):
    ADMIN = "admin"
    MEMBER = "member"

class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    name: Mapped[str | None] = mapped_column(String(255))
    role: Mapped[UserRole] = mapped_column(
        StringEnum(UserRole), default=UserRole.MEMBER, index=True,
    )
    created_at: Mapped[datetime] = mapped_column(default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(default=utc_now, onupdate=utc_now)

    # Relationships
    projects: Mapped[list["Project"]] = relationship(back_populates="owner")
```

### Key model patterns

**Nullability from type annotations**: In SQLAlchemy 2.0, `Mapped[str | None]` automatically implies `nullable=True` — no need to pass it explicitly to `mapped_column()`. Conversely, `Mapped[str]` implies `nullable=False`.

**UUID primary keys**: Use `uuid.UUID` type with a callable default. FastAPI and Pydantic handle UUID serialization to/from strings automatically.

- **Python 3.14+**: Use `default=uuid.uuid7`. UUIDv7 is time-ordered (embeds a timestamp), which means database inserts are sequential rather than random. This dramatically improves B-tree index performance and makes IDs roughly sortable by creation time. Always prefer UUIDv7 when available.
- **Python 3.13 and earlier**: Use `default=uuid.uuid4`. UUIDv4 is fully random, which works fine but causes more index fragmentation at scale.

**Enums as `(str, Enum)`**: Two separate problems require two solutions:
- The `str` mixin is a **Python-side** concern — it makes enum members behave as strings, so `user.role == "admin"` works and JSON serialization is automatic.
- `StringEnum()` is a **database-side** concern — it tells SQLAlchemy to store the enum's `.value` (e.g., `"admin"`) instead of its `.name` (e.g., `"ADMIN"`), and to use `VARCHAR` instead of a database-native enum type for portability.

You need both. Without the `str` mixin, Pydantic can't serialize the enum cleanly. Without `StringEnum()`, the database stores the wrong thing.

Define the `StringEnum` helper in `core/database.py`:

```python
from enum import Enum as PyEnum
from typing import TypeVar
from sqlalchemy import Enum as SAEnum

E = TypeVar("E", bound=PyEnum)

def StringEnum(enum_class: type[E]) -> SAEnum:
    """Store enum values (not names) as strings in the database."""
    return SAEnum(
        enum_class,
        values_callable=lambda x: [e.value for e in x],
        native_enum=False,  # Use VARCHAR, not DB-native enum types (more portable)
    )
```

**Co-locate enums with their model.** `UserRole` lives in `models/user.py`, `ProjectStatus` in `models/project.py`, etc. Re-export them from `models/__init__.py` so other layers can import from one place.

**Timestamps with `utc_now`**: Define a helper in `core/timezone.py`. The convention is to store all datetimes as **naive UTC** — the `tzinfo` is intentionally stripped because SQLite doesn't support timezone-aware datetimes, and treating all stored times as implicitly UTC avoids cross-database inconsistencies:

```python
# app/core/timezone.py
from datetime import datetime, timezone

def utc_now() -> datetime:
    """Return current UTC time as a naive datetime (tzinfo stripped).
    All datetimes in the database are implicitly UTC by convention."""
    return datetime.now(timezone.utc).replace(tzinfo=None)
```

Use as `default=utc_now` (callable reference, not invocation). When migrating to PostgreSQL with timezone support, you can drop the `.replace(tzinfo=None)` call.

> **`onupdate` limitation**: The `onupdate=utc_now` parameter is a **Python-side** default
> that only fires during the ORM unit-of-work flush (when SQLAlchemy detects attribute
> changes on individually loaded objects). It does **not** fire for:
> - Bulk updates via `session.execute(update(Model).values(...))`
> - Raw SQL updates
> - Changes to related objects that don't touch the parent column directly
>
> If you use bulk updates, set `updated_at` explicitly:
> ```python
> await db.execute(
>     update(User).where(User.id == user_id).values(name="new", updated_at=utc_now())
> )
> ```

**Index strategy**: Always add `index=True` to foreign keys and columns frequently used in `WHERE` clauses (role, status, email).

**String lengths for portability**: Always specify a length for `String` columns: `String(320)` for emails (RFC 5321 max), `String(255)` for names, `String(5000)` for content. Bare `String` without a length works on PostgreSQL and SQLite but **fails on MySQL** for indexed columns.

### Relationships and cascades

```python
# app/models/project.py
class Project(Base):
    __tablename__ = "projects"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,  # Always index foreign keys
    )

    # Parent side: cascade delete orphans
    comments: Mapped[list["Comment"]] = relationship(
        back_populates="project",
        cascade="all, delete-orphan",  # ORM-level: delete children when parent is deleted
    )
```

```python
# app/models/comment.py
from sqlalchemy import UniqueConstraint

class Comment(Base):
    __tablename__ = "comments"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    author_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"),  # DB-level: cascade on FK delete
        index=True,
    )
    content: Mapped[str] = mapped_column(String(5000))
```

**Use both ORM and DB-level cascades for defense in depth.** `cascade="all, delete-orphan"` on the relationship ensures `db.delete(project)` cleans up children through SQLAlchemy. `ForeignKey(ondelete="CASCADE")` ensures the database enforces cleanup even for raw SQL or bulk deletes that bypass the ORM. Neither alone covers all cases.

### The `models/__init__.py` re-export trick

```python
# app/models/__init__.py
from app.models.user import User, UserRole
from app.models.project import Project, ProjectStatus
from app.models.comment import Comment

__all__ = ["User", "UserRole", "Project", "ProjectStatus", "Comment"]
```

This is **critical**: SQLAlchemy's `Base.metadata.create_all()` only creates tables for models that have been imported. The `__init__.py` ensures every model is imported when the package is loaded.

---

## 7. Schemas (`schemas/`)

Mirror the model structure. Use separate schemas for create, update, and response.

### Basic pattern: Create, Update, Response

```python
# app/schemas/project.py
import uuid
from pydantic import BaseModel

class ProjectCreate(BaseModel):
    name: str
    description: str | None = None

class ProjectUpdate(BaseModel):
    name: str | None = None        # All fields optional for PATCH
    status: ProjectStatus | None = None  # Validate against the enum

class ProjectResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    name: str
    status: ProjectStatus
    owner_id: uuid.UUID
```

- **`model_config = {"from_attributes": True}`**: Enables `ProjectResponse.model_validate(orm_object)` to convert SQLAlchemy models to Pydantic schemas.
- **Create schemas**: Required fields only, with defaults where appropriate.
- **Update schemas**: All fields `| None = None` for partial updates.
- **Response schemas**: Define exactly what the API exposes. Never return raw ORM objects without a schema gate.

### Partial updates with `exclude_unset`

For PATCH endpoints, distinguishing "user sent `null`" from "user didn't send the field" is critical. Use `model_dump(exclude_unset=True)`:

```python
@router.patch("/{project_id}")
async def update_project(
    project_id: uuid.UUID, data: ProjectUpdate, user: CurrentUser, db: DbSession,
) -> ProjectResponse:
    project = await db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")

    update_data = data.model_dump(exclude_unset=True)  # Only fields the client actually sent
    for field, value in update_data.items():
        setattr(project, field, value)

    await db.flush()
    await db.refresh(project)
    return ProjectResponse.model_validate(project)
```

### Nested Pydantic models for JSON fields

Complex configuration stored as JSON in the database gets its own Pydantic model for validation:

```python
from pydantic import BaseModel, Field

class NotificationSettings(BaseModel):
    """User notification preferences — stored as JSON in the users table."""
    email_enabled: bool = True
    digest_frequency: str = Field(default="weekly", pattern="^(daily|weekly|monthly)$")
    max_per_day: int = Field(default=10, ge=1, le=100)

class NotificationSettingsUpdate(BaseModel):
    """Partial settings update — all fields optional."""
    email_enabled: bool | None = None
    digest_frequency: str | None = None
    max_per_day: int | None = None

class UserCreate(BaseModel):
    name: str
    notifications: NotificationSettings = Field(default_factory=NotificationSettings)
```

**Storing and loading:**

```python
# Creating — serialize Pydantic model to dict for JSON column
user = User(
    name=data.name,
    notifications=data.notifications.model_dump(mode="json"),  # Pydantic → dict → JSON column
)

# Reading — validate dict back into Pydantic model (handled by from_attributes)
return UserResponse.model_validate(user)  # notifications dict → NotificationSettings automatically
```

**Partial update of nested config:**

```python
# 4-step merge pattern for nested partial updates
existing = NotificationSettings.model_validate(user.notifications or {})   # 1. Load existing
updates = data.notifications.model_dump(exclude_unset=True)                 # 2. Get only sent fields
merged = existing.model_copy(update=updates)                                # 3. Merge
user.notifications = merged.model_dump(mode="json")                         # 4. Store back
```

### Response model variations for different detail levels

The same entity may need different response schemas depending on context or permissions:

```python
class CommentResponse(BaseModel):
    """Basic comment data — returned when creating/updating."""
    model_config = {"from_attributes": True}

    id: uuid.UUID
    content: str
    created_at: datetime

class CommentWithAuthorResponse(BaseModel):
    """Comment + author details — returned in list views."""
    model_config = {"from_attributes": True}

    id: uuid.UUID
    content: str
    created_at: datetime
    author_name: str | None
    author_email: str | None  # Only populated for admins
```

**Conditional field visibility** — gate sensitive data based on permissions:

```python
@router.get("/{project_id}/comments")
async def list_comments(project_id: uuid.UUID, user: CurrentUser, db: DbSession) -> list[CommentWithAuthorResponse]:
    is_admin = user.role == UserRole.ADMIN

    result = await db.execute(
        select(Comment, User)
        .join(User, Comment.author_id == User.id)
        .where(Comment.project_id == project_id)
    )
    return [
        CommentWithAuthorResponse(
            id=comment.id,
            content=comment.content,
            created_at=comment.created_at,
            author_name=author.name,
            author_email=author.email if is_admin else None,  # Hide emails from non-admins
        )
        for comment, author in result.all()
    ]
```

### Explicit `model_validate()` over implicit serialization

Always call `model_validate()` explicitly rather than relying on FastAPI's automatic ORM conversion:

```python
# Preferred — explicit, type-safe, auditable
@router.get("/{id}", response_model=ProjectResponse)
async def get_project(id: uuid.UUID, db: DbSession) -> ProjectResponse:
    project = await db.get(Project, id)
    return ProjectResponse.model_validate(project)

# Avoid — implicit, harder to debug
@router.get("/{id}", response_model=ProjectResponse)
async def get_project(id: uuid.UUID, db: DbSession):
    return await db.get(Project, id)  # FastAPI converts silently
```

Explicit validation catches serialization issues at the point of return, makes the return type clear to type checkers, and gives you a place to add conditional logic before returning.

### `response_model` vs return type annotation

Both can control response serialization, but they serve different purposes:

```python
# Option A: Both (recommended) — response_model controls OpenAPI docs, return type aids type checkers
@router.get("/{id}", response_model=ProjectResponse)
async def get_project(id: uuid.UUID, db: DbSession) -> ProjectResponse:
    ...

# Option B: Return type only — FastAPI infers response_model from the annotation (Pydantic v2+)
@router.get("/{id}")
async def get_project(id: uuid.UUID, db: DbSession) -> ProjectResponse:
    ...
```

Option B works in modern FastAPI but Option A is more explicit and lets you use decorator-level settings like `response_model_exclude_none`:

```python
# Strip None fields from the response JSON
@router.get("/{id}", response_model=ProjectResponse, response_model_exclude_none=True)
```

This is especially useful for **partial update responses** and **sparse objects** where most optional fields are `None`. Without it, clients receive a wall of `null` fields that obscure the actual data. Consider making `response_model_exclude_none=True` the default for update endpoints.

### Documenting error responses in OpenAPI

Use the `responses` parameter to declare expected error responses in your API docs:

```python
@router.get(
    "/{id}",
    response_model=ProjectResponse,
    responses={
        404: {"description": "Project not found"},
        403: {"description": "Not authorized to view this project"},
    },
)
async def get_project(id: uuid.UUID, user: CurrentUser, db: DbSession) -> ProjectResponse:
    ...
```

This doesn't change runtime behavior — it only enriches the OpenAPI schema. Especially valuable when frontend types are auto-generated from the spec.

---

## 8. Security (`core/security.py`)

Isolate all cryptographic operations in one module.

```python
import secrets
import hashlib
import uuid
from datetime import datetime, timedelta, timezone
import jwt  # pip install PyJWT
from pwdlib import PasswordHash  # pip install pwdlib[bcrypt]
from pwdlib.hashers.bcrypt import BcryptHasher
from app.core.config import settings

ALGORITHM = "HS256"
pwd_hasher = PasswordHash((BcryptHasher(),))

# --- Password hashing ---

def hash_password(password: str) -> str:
    return pwd_hasher.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_hasher.verify(plain, hashed)

# --- Token generation ---

def generate_token() -> str:
    return secrets.token_urlsafe(32)

def generate_short_code(length: int = 6) -> str:
    """6-character alphanumeric code (32^6 ≈ 1 billion combinations)."""
    alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"  # No 0/O/1/I to avoid confusion
    return "".join(secrets.choice(alphabet) for _ in range(length))

def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()

# --- JWT ---

def create_access_token(user_id: uuid.UUID) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.ACCESS_TOKEN_EXPIRE_DAYS)
    payload = {"sub": str(user_id), "exp": expire, "iat": datetime.now(timezone.utc)}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)

def decode_access_token(token: str) -> dict | None:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.InvalidTokenError:
        return None
```

### Rules

- **Use `PyJWT`**: The `python-jose` library is unmaintained. `PyJWT` (`import jwt`) is the actively maintained standard. The API is nearly identical — `jwt.encode()` / `jwt.decode()`.
- **Hash passwords with `pwdlib`**: Use `pwdlib[bcrypt]` as a modern, maintained replacement for `passlib` (which is unmaintained since 2020 and broken on Python 3.13+). For new projects, consider `pwdlib[argon2]` — Argon2 is the current best practice for password hashing and what the [FastAPI official docs](https://fastapi.tiangolo.com/tutorial/security/oauth2-jwt/) recommend.
- **Hash tokens before storage**: Even if tokens are short-lived, store SHA-256 hashes, not plaintext.
- **Use `secrets` module**: Never use `random` for security-sensitive values.
- **Return `None` on decode failure**: Let the dependency layer decide whether to 401 or proceed as anonymous.
- **Human-friendly short codes**: Exclude ambiguous characters (0/O, 1/I) from verification codes.

### Token lifetime and revocation

The default `ACCESS_TOKEN_EXPIRE_DAYS = 30` creates a long window of exposure if a token is compromised. JWTs are stateless — once issued, they cannot be revoked without server-side state.

**Production strategies:**

| Strategy | How it works | Tradeoff |
|----------|-------------|----------|
| **Short-lived access + refresh tokens** | Access tokens expire in 15-60 min. A refresh token (stored server-side) issues new ones. Revoke refresh tokens to cut off access. | More complex, but industry standard |
| **Token blocklist** | Store revoked token IDs (`jti` claim) in Redis/DB. Check on every request. | Adds per-request latency. Defeats stateless benefit |
| **Short expiry only** | Set expiry to hours, not days. Users re-login more often. | Simplest. Adequate for internal tools |

> **Warning**: A 30-day JWT with no revocation means a compromised token grants access for up to 30 days. For user-facing apps, shorten the expiry or implement refresh token rotation.

---

## 9. Rate Limiting (`core/rate_limit.py`)

Use `slowapi` for endpoint-level rate limiting.

```python
# app/core/rate_limit.py
from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address

def get_real_client_ip(request: Request) -> str:
    """Extract client IP behind a reverse proxy via X-Forwarded-For."""
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    return get_remote_address(request)

limiter = Limiter(
    key_func=get_real_client_ip,
    default_limits=["30/minute"],
    storage_uri="memory://",      # Use "redis://localhost:6379" in production
)
```

> **Reverse proxy note**: The built-in `get_remote_address` returns `request.client.host`, which is the **proxy's IP** behind nginx or a load balancer. The `get_real_client_ip` function reads `X-Forwarded-For` instead. Ensure your proxy sets this header and consider Uvicorn's `--proxy-headers` flag.
>
> **Security**: `X-Forwarded-For` can be spoofed by direct clients. Only trust it when you control the reverse proxy and strip/overwrite the header at the edge.

> **Important**: Creating the `Limiter` is only part of the setup. You must also wire it into `main.py` (see Section 1): `app.state.limiter = limiter`, register the `RateLimitExceeded` exception handler, and add `SlowAPIMiddleware`. Without all three, rate limiting silently does nothing.

Apply per-endpoint limits with the `@limiter.limit()` decorator:

```python
from fastapi import Request
from app.core.rate_limit import limiter

@router.post("/login")
@limiter.limit("5/minute")  # Stricter limit on auth endpoints
async def login(request: Request, data: LoginRequest, db: DbSession):
    ...

@router.post("/register")
@limiter.limit("3/hour")  # Prevent abuse of account creation
async def register(request: Request, data: RegisterRequest, db: DbSession):
    ...
```

Rate-limited endpoints must accept `request: Request` as a parameter (slowapi needs it to extract the client IP).

---

## 11. Common Mistakes to Avoid

### Putting business logic in dependencies
Dependencies should handle **cross-cutting concerns** (auth, DB sessions, permissions). Don't put domain-specific business logic in them.

```python
# Bad — dependency does business logic
async def get_active_project(project_id: str, db: DbSession) -> Project:
    project = await db.get(Project, project_id)
    if not project:
        raise HTTPException(404)
    if project.status != "ACTIVE":
        raise HTTPException(400, "Project is not active")
    return project

# Better — keep it in the route
@router.post("/{project_id}/tasks")
async def create_task(project_id: str, user: CurrentUser, db: DbSession):
    project = await db.get(Project, project_id)
    if not project:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Project not found")
    if project.status != ProjectStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Project is not active")
    ...
```

The distinction is between **reusable access patterns** (fetching a resource and checking existence/permissions — like `get_project_or_404`) and **domain-specific validation** (checking business rules like "project must be active" or "user has remaining quota"). The former belongs in shared helpers; the latter belongs in routes where the business context is clear.

### Over-abstracting with service classes
A separate service layer adds indirection without value in small-to-medium apps. If your route handler is the only caller, the logic can live there. Extract a service class when:
- Multiple routes share complex business logic
- You need to test business logic without HTTP
- The router file exceeds ~400 lines

### Forgetting `expire_on_commit=False`
Without this, SQLAlchemy objects become detached after `commit()`. Accessing any attribute triggers a `DetachedInstanceError`. Always set it on async session factories.

### Not handling lazy-loaded relationships in async contexts
Accessing lazy-loaded relationships in async code raises `MissingGreenlet` errors. Either include `AsyncAttrs` on `Base` and use `await obj.awaitable_attrs.relationship`, or use eager loading (`selectinload`, `joinedload`) in your queries.

### Not re-exporting models in `__init__.py`
If a model isn't imported before `create_all()`, its table won't be created. The `models/__init__.py` should import every model.

### Returning ORM objects without `flush()` + `refresh()`
After `db.add()`, auto-generated fields (ID, timestamps) aren't populated until `flush()`. And server-side defaults aren't visible until `refresh()`. Always flush and refresh before returning newly created objects.

---

## 12. Testing

Structure tests to mirror the app layout:

```
tests/
├── conftest.py          # Shared fixtures (db, client, auth)
├── test_auth.py         # Tests for auth router
├── test_projects.py     # Tests for projects router
└── __init__.py
```

### Core fixtures (`conftest.py`)

```python
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from app.core.database import Base, get_db
from app.main import app

# In-memory SQLite for test isolation
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"
test_engine = create_async_engine(TEST_DATABASE_URL)
test_session_factory = async_sessionmaker(test_engine, expire_on_commit=False)

@pytest.fixture(autouse=True)
async def setup_db():
    """Create tables before each test, drop after."""
    async with test_engine.begin() as conn:
        await conn.execute(text("PRAGMA foreign_keys = ON"))  # SQLite doesn't enforce FKs by default
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
async def db():
    """Provide a test database session."""
    async with test_session_factory() as session:
        yield session

@pytest.fixture
async def client(db):
    """Async test client with dependency overrides."""
    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as client:
        yield client
    app.dependency_overrides.clear()

@pytest.fixture
async def auth_client(client, db):
    """Client pre-authenticated as a test user."""
    from app.core.security import create_access_token
    from app.models.user import User, UserRole

    user = User(email="test@example.com", name="Test User", role=UserRole.MEMBER)
    db.add(user)
    await db.flush()  # No commit needed — the route's get_db override yields this same session

    token = create_access_token(user.id)
    client.headers["Authorization"] = f"Bearer {token}"
    yield client
```

### Writing tests

```python
# tests/test_projects.py
import pytest

@pytest.mark.asyncio
async def test_create_project_requires_auth(client):
    """Unauthenticated users cannot create projects."""
    response = await client.post("/projects/", json={"name": "Test"})
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_create_project_success(auth_client):
    """Authenticated users can create projects."""
    response = await auth_client.post("/projects/", json={"name": "My Project"})
    assert response.status_code == 201
    assert response.json()["name"] == "My Project"
```

### Key patterns

- **Override `get_db`** to inject the test database session. This is the critical integration point — it ensures routes use your test DB.
- **In-memory SQLite** for speed. Each test gets fresh tables via the `autouse` fixture. **Caveat**: SQLite doesn't enforce foreign key constraints by default (the fixture enables them with `PRAGMA foreign_keys = ON`) and has a looser type system than PostgreSQL — tests may pass on SQLite and fail in production. For critical projects, consider running tests against PostgreSQL via Docker.
- **Async test markers**: Use `pytest-asyncio` with `asyncio_mode = "auto"` to skip markers entirely, or add `@pytest.mark.asyncio` to each test. Do not mix `pytest-asyncio` with `anyio`'s plugin — pick one:

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"  # No need for @pytest.mark.asyncio on every test
```
- **Build fixture variants** for different roles (`auth_client` as member, `moderator_client`, `admin_client`) to test permission boundaries.

---

## 13. Error Handling

### Custom exception handlers

Register global handlers for exceptions that aren't `HTTPException`:

```python
# app/main.py
from fastapi import Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError

@app.exception_handler(IntegrityError)
async def integrity_error_handler(request: Request, exc: IntegrityError):
    return JSONResponse(
        status_code=409,
        content={"detail": "Resource already exists or constraint violated"},
    )
```

This prevents `IntegrityError` from leaking as a 500 Internal Server Error. Register handlers for any exception type that can bubble up from your database or external services.

**Tip — parsing constraint names for specific messages**: The generic "constraint violated" message frustrates frontend developers. For better UX, parse the constraint name from the error to return actionable messages:

```python
@app.exception_handler(IntegrityError)
async def integrity_error_handler(request: Request, exc: IntegrityError):
    detail = "Resource already exists or constraint violated"
    if exc.orig and hasattr(exc.orig, "args"):
        error_msg = str(exc.orig)
        if "users.email" in error_msg or "uq_users_email" in error_msg:
            detail = "A user with this email already exists"
    return JSONResponse(status_code=409, content={"detail": detail})
```

Match on table/column names or constraint names from your schema. This turns opaque 409s into messages clients can act on.

### Validation error customization

FastAPI returns 422 with Pydantic's raw error format by default. Override `RequestValidationError` to normalize the shape for your frontend:

```python
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "detail": "Validation error",
            "errors": [
                {
                    "field": " → ".join(str(loc) for loc in err["loc"]),
                    "message": err["msg"],
                    "type": err["type"],
                }
                for err in exc.errors()
            ],
        },
    )
```

This is especially valuable when frontend clients expect a consistent error envelope rather than Pydantic's default `{"detail": [{"loc": [...], "msg": "...", "type": "..."}]}` format.

### Structured error responses

For machine-readable errors, include an error `code` alongside the human-readable `detail`:

```python
raise HTTPException(
    status_code=status.HTTP_400_BAD_REQUEST,
    detail={
        "code": "DUPLICATE_MEMBER",
        "message": "User is already a member of this project",
    },
)
```

Frontend clients can switch on `error.code` rather than parsing strings. Define error codes as constants or an enum to keep them consistent.

---

## 14. Background Tasks

Use FastAPI's `BackgroundTasks` for fire-and-forget work that shouldn't block the response (emails, logging, cleanup):

```python
from fastapi import BackgroundTasks

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_project(
    data: ProjectCreate,
    user: CurrentUser,
    db: DbSession,
    background_tasks: BackgroundTasks,
) -> ProjectResponse:
    project = Project(owner_id=user.id, name=data.name)
    db.add(project)
    await db.flush()
    await db.refresh(project)

    background_tasks.add_task(send_welcome_email, user.email, project.name)  # Runs after response
    return ProjectResponse.model_validate(project)
```

**When to use `BackgroundTasks`:**
- Sending emails or notifications
- Writing audit logs
- Lightweight cleanup (e.g., deleting expired tokens)

> **Warning — `yield` dependencies are closed before background tasks run.**
> Since FastAPI 0.106.0, dependencies that use `yield` (like `get_db()`) are torn down
> *before* background tasks execute. This means:
> - **Never pass `db` (the session)** to a background task — it will be closed.
> - **Never pass ORM model instances** — accessing lazy-loaded attributes raises `DetachedInstanceError`.
> - **Always extract primitive values** (IDs, strings) in the endpoint and pass those.
>
> If a background task needs database access, create a new session inside the task:
> ```python
> from app.core.database import async_session_factory
>
> async def process_project_background(project_id: uuid.UUID):
>     async with async_session_factory() as db:
>         project = await db.get(Project, project_id)
>         ...  # Work with project using this fresh session
> ```

**When to use a proper task queue (Celery, arq) instead:**
- Tasks that take more than a few seconds
- Tasks that need retry logic or scheduling
- Tasks that must survive server restarts

---

## 15. Pagination

Any list endpoint should support pagination. Define a reusable dependency and generic response:

```python
# app/dependencies.py
from dataclasses import dataclass

@dataclass
class PaginationParams:
    page: int = 1
    page_size: int = 20

async def get_pagination(page: int = 1, page_size: int = 20) -> PaginationParams:
    page_size = min(page_size, 100)  # Cap maximum page size
    return PaginationParams(page=max(page, 1), page_size=page_size)

Pagination = Annotated[PaginationParams, Depends(get_pagination)]
```

```python
# app/schemas/common.py
from pydantic import BaseModel
from typing import Generic, TypeVar

T = TypeVar("T")

class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    page_size: int
```

Usage in routes:

```python
from sqlalchemy import func, select
from app.dependencies import Pagination
from app.models.project import Project
from app.schemas.common import PaginatedResponse
from app.schemas.project import ProjectResponse

@router.get("/", response_model=PaginatedResponse[ProjectResponse])
async def list_projects(db: DbSession, user: CurrentUser, pagination: Pagination):
    offset = (pagination.page - 1) * pagination.page_size

    # Shared filter — count and data queries must use the same WHERE clause
    base_query = select(Project).where(Project.owner_id == user.id)

    total_result = await db.execute(
        select(func.count()).select_from(base_query.subquery())
    )
    total = total_result.scalar() or 0

    result = await db.execute(
        base_query
        .order_by(Project.created_at.desc(), Project.id)  # Deterministic ordering with tiebreaker
        .offset(offset)
        .limit(pagination.page_size)
    )
    projects = result.scalars().all()

    return PaginatedResponse(
        items=[ProjectResponse.model_validate(p) for p in projects],
        total=total,
        page=pagination.page,
        page_size=pagination.page_size,
    )
```

> **Always use `ORDER BY` with pagination.** Without a deterministic sort order,
> `OFFSET`/`LIMIT` returns unpredictable results across pages. Include a unique column
> (like the primary key) as a tiebreaker for rows with identical sort values.
>
> **Keep count and data filters in sync.** Extract a shared `base_query` so both
> `COUNT(*)` and the data `SELECT` apply the same `WHERE` clause.

### Cursor-based pagination for large datasets

Offset pagination (`OFFSET 10000`) forces the database to skip rows, degrading performance on large tables. For APIs that will see real scale, consider **cursor-based pagination** — the client passes the last seen value instead of a page number:

```python
from sqlalchemy import or_, and_

@router.get("/", response_model=CursorPaginatedResponse[ProjectResponse])
async def list_projects(
    db: DbSession,
    user: CurrentUser,
    cursor: uuid.UUID | None = None,  # Last seen project ID
    limit: int = 20,
):
    query = (
        select(Project)
        .where(Project.owner_id == user.id)
        .order_by(Project.created_at.desc(), Project.id)
        .limit(min(limit, 100))
    )
    if cursor:
        # Fetch the cursor row to get its sort values
        cursor_project = await db.get(Project, cursor)
        if cursor_project:
            # Use or_/and_ instead of tuple comparison — tuple syntax works on
            # PostgreSQL but raises an error on SQLite (used in tests).
            query = query.where(
                or_(
                    Project.created_at < cursor_project.created_at,
                    and_(
                        Project.created_at == cursor_project.created_at,
                        Project.id < cursor_project.id,
                    ),
                )
            )
    result = await db.execute(query)
    projects = result.scalars().all()
    next_cursor = projects[-1].id if projects else None
    return CursorPaginatedResponse(
        items=[ProjectResponse.model_validate(p) for p in projects],
        next_cursor=next_cursor,
    )
```

Cursor pagination is constant-time regardless of page depth but doesn't support "jump to page N". Use offset pagination for small datasets or admin UIs; use cursor pagination for feeds, timelines, and large listings.

---

## 16. Scaling the Structure

When the app grows beyond 5-6 routers, consider grouping by domain:

```
app/
├── auth/
│   ├── router.py
│   ├── schemas.py
│   ├── models.py
│   └── dependencies.py
├── projects/
│   ├── router.py
│   ├── schemas.py
│   └── models.py
├── core/
│   ├── config.py
│   ├── database.py
│   └── security.py
├── dependencies.py      # Shared deps (auth, db)
└── main.py
```

This is a tradeoff. The flat structure (`routers/`, `models/`, `schemas/` as siblings) works well up to ~10 entities and has the advantage of making cross-domain imports simple. The domain-grouped structure reduces cognitive load per feature but can create circular import challenges.

**Recommendation**: Start flat. Restructure to domain grouping only when navigating the flat structure becomes painful.

---

## Quick Reference Checklist

### `main.py`
- [ ] Uses lifespan context manager (not deprecated `on_event`)
- [ ] CORS configured for the frontend origin
- [ ] Rate limiting configured with `slowapi`
- [ ] Health check endpoint exists at `/health`
- [ ] Custom exception handler for `IntegrityError` (returns 409, not 500)
- [ ] Middleware order: `CORSMiddleware` registered last (runs first)

### `core/`
- [ ] Config uses `pydantic-settings` with dev defaults
- [ ] `SECRET_KEY` is overridden in production (not auto-generated)
- [ ] `.env.example` committed with all expected variables
- [ ] `Base` class includes `AsyncAttrs` mixin
- [ ] Database session factory uses `expire_on_commit=False`
- [ ] `get_db()` auto-commits on success, rolls back on error
- [ ] `StringEnum()` helper stores enum values (not names)
- [ ] Timestamps use naive UTC via `utc_now()` helper
- [ ] Passwords hashed with bcrypt via `pwdlib` (not unmaintained `passlib`)
- [ ] Tokens hashed before database storage
- [ ] JWT uses `PyJWT` (not unmaintained `python-jose`)

### `models/`
- [ ] All models re-exported in `models/__init__.py`
- [ ] Foreign keys have `index=True`
- [ ] Enums use both `(str, Enum)` mixin and `StringEnum()` column type
- [ ] Relationships use both ORM and DB-level cascades

### `schemas/`
- [ ] Response schemas use `model_config = {"from_attributes": True}`
- [ ] Update schemas have all fields `| None = None` for partial updates
- [ ] Nested JSON configs use Pydantic models with the 4-step merge pattern

### `routers/`
- [ ] Each router has `prefix` and `tags` set at the `APIRouter` level
- [ ] Routes use `flush()` + `refresh()` before returning new objects
- [ ] Routes call `model_validate()` explicitly
- [ ] Update endpoints use `model_dump(exclude_unset=True)`
- [ ] List endpoints support pagination with capped `page_size`
- [ ] Email/notifications use `BackgroundTasks` (not blocking the response)

### `dependencies.py`
- [ ] Dependencies are composed (chain from simple to specific)
- [ ] `Annotated` type aliases exist for all common dependencies
- [ ] Resource-level permission helpers exist for ownership/staff checks

### `tests/`
- [ ] Tests use dependency overrides for `get_db` with in-memory SQLite
- [ ] `asyncio_mode = "auto"` set in `pyproject.toml`
- [ ] Fixture variants exist for different roles (member, admin, etc.)
