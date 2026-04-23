from __future__ import annotations

from fastapi import APIRouter, Depends, Request

from app.deps import role_required
from app.services.reports import audit_report
from app.templating import base_context, templates

router = APIRouter(prefix="/audit", tags=["audit"])


@router.get("")
def audit_page(request: Request, user: dict = Depends(role_required("AUDITOR", "ADMIN_TI"))):
    context = base_context(request)
    context.update({"entries": audit_report()})
    return templates.TemplateResponse("audit.html", context)
