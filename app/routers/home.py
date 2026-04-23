from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from fastapi.responses import RedirectResponse

from app.deps import require_user
from app.services.admin import admin_overview
from app.services.enrollment import dashboard_summary, get_active_period, get_student_profile, list_enrollment_details
from app.services.finance import list_invoices
from app.templating import base_context, templates

router = APIRouter()


@router.get("/")
def home(request: Request):
    context = base_context(request)
    context.update({"active_period": get_active_period()})
    return templates.TemplateResponse("index.html", context)


@router.get("/app")
def app_home(request: Request, user: dict = Depends(require_user)):
    roles = set(user.get("roles") or [])
    context = base_context(request)

    if "ESTUDIANTE" in roles:
        student = get_student_profile(user["id"])
        context.update(
            {
                "summary": dashboard_summary(student["id"]),
                "active_period": get_active_period(),
                "details": list_enrollment_details(student["id"])[:5],
                "invoices": list_invoices(student["id"])[:5],
            }
        )
        return templates.TemplateResponse("dashboard_student.html", context)

    context.update({"overview": admin_overview()})
    return templates.TemplateResponse("dashboard_staff.html", context)
