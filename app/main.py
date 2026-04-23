from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI, Request, status
from fastapi.exceptions import HTTPException
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware

from app.core.config import get_settings
from app.core.flash import pop_flashes
from app.routers import admin, audit, auth, home, reports, student
from app.templating import base_context, templates

settings = get_settings()

app = FastAPI(title=settings.app_name)


@app.middleware("http")
async def load_flashes(request: Request, call_next):
    request.state.flashes = pop_flashes(request)
    response = await call_next(request)
    return response


app.add_middleware(
    SessionMiddleware,
    secret_key=settings.secret_key,
    https_only=settings.session_https_only,
    same_site="lax",
)

app.mount("/static", StaticFiles(directory=str(Path(__file__).parent / "static")), name="static")


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    location = (exc.headers or {}).get("Location")
    if location and exc.status_code in {301, 302, 303, 307, 308}:
        return RedirectResponse(url=location, status_code=exc.status_code)

    if exc.status_code == status.HTTP_403_FORBIDDEN:
        context = base_context(request)
        context.update({"error_title": "Acceso denegado", "error_message": "No tiene permisos para acceder a este recurso."})
        return templates.TemplateResponse("error.html", context, status_code=status.HTTP_403_FORBIDDEN)

    context = base_context(request)
    context.update({"error_title": "Ocurrió un error", "error_message": exc.detail if isinstance(exc.detail, str) else "No fue posible completar la solicitud."})
    return templates.TemplateResponse("error.html", context, status_code=exc.status_code)


@app.get("/health")
def health():
    return {"status": "ok"}


app.include_router(home.router)
app.include_router(auth.router)
app.include_router(student.router)
app.include_router(admin.router)
app.include_router(reports.router)
app.include_router(audit.router)
