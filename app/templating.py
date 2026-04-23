from __future__ import annotations

from datetime import date, datetime
from pathlib import Path

from fastapi.templating import Jinja2Templates

from app.deps import get_current_user
from app.services.enrollment import get_student_profile


templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))


def currency(value):
    try:
        return f"₡ {float(value):,.2f}"
    except Exception:  # noqa: BLE001
        return value


def format_datetime(value):
    if not value:
        return "—"
    if isinstance(value, (datetime, date)):
        return value.strftime("%d/%m/%Y %H:%M" if isinstance(value, datetime) else "%d/%m/%Y")
    return value


templates.env.filters["currency"] = currency
templates.env.filters["format_datetime"] = format_datetime


def base_context(request):
    user = get_current_user(request)
    student = get_student_profile(user["id"]) if user and "ESTUDIANTE" in (user.get("roles") or []) else None
    return {
        "request": request,
        "current_user": user,
        "student_profile": student,
        "flashes": getattr(request.state, "flashes", []),
    }
