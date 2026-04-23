from __future__ import annotations

from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import RedirectResponse

from app.core.flash import add_flash
from app.deps import role_required
from app.services.enrollment import (
    add_section_to_enrollment,
    ensure_invoice,
    get_active_period,
    get_student_profile,
    list_enrollment_details,
    list_offer,
    remove_detail,
)
from app.services.finance import list_invoices, list_payments, list_receipts, list_vouchers, register_mock_payment
from app.services.notifications import list_notifications, mark_as_read
from app.templating import base_context, templates

router = APIRouter(prefix="/student", tags=["student"])


@router.get("/offer")
def offer_page(
    request: Request,
    search: str | None = None,
    user: dict = Depends(role_required("ESTUDIANTE")),
):
    student = get_student_profile(user["id"])
    period = get_active_period()
    sections = list_offer(period["id"], search) if period else []
    context = base_context(request)
    context.update({"period": period, "sections": sections, "search": search or "", "student": student})
    return templates.TemplateResponse("student_offer.html", context)


@router.post("/enroll/{section_id}")
def enroll_section(request: Request, section_id: int, user: dict = Depends(role_required("ESTUDIANTE"))):
    student = get_student_profile(user["id"])
    try:
        state = add_section_to_enrollment(student["id"], user["id"], section_id, acting_as=user["correo"])
        add_flash(request, "success", f"Se agregó la sección. Estado resultante: {state}.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/student/offer", status_code=303)


@router.get("/enrollment")
def enrollment_page(request: Request, user: dict = Depends(role_required("ESTUDIANTE"))):
    student = get_student_profile(user["id"])
    details = list_enrollment_details(student["id"])
    context = base_context(request)
    context.update({"details": details})
    return templates.TemplateResponse("student_enrollment.html", context)


@router.post("/drop/{detail_id}")
def drop_detail(request: Request, detail_id: int, user: dict = Depends(role_required("ESTUDIANTE"))):
    try:
        remove_detail(detail_id, user["id"], acting_as=user["correo"])
        add_flash(request, "success", "La sección se eliminó de la matrícula.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/student/enrollment", status_code=303)


@router.post("/checkout/{matricula_id}")
def checkout(request: Request, matricula_id: int, user: dict = Depends(role_required("ESTUDIANTE"))):
    try:
        invoice = ensure_invoice(matricula_id, acting_as=user["correo"])
        add_flash(request, "success", f"Estado de cuenta generado: {invoice['numero_factura']}.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/student/finance", status_code=303)


@router.get("/finance")
def finance_page(request: Request, user: dict = Depends(role_required("ESTUDIANTE"))):
    student = get_student_profile(user["id"])
    context = base_context(request)
    context.update(
        {
            "invoices": list_invoices(student["id"]),
            "payments": list_payments(student["id"]),
            "receipts": list_receipts(student["id"]),
            "vouchers": list_vouchers(student["id"]),
        }
    )
    return templates.TemplateResponse("student_finance.html", context)


@router.post("/pay/{factura_id}")
def pay_invoice(request: Request, factura_id: int, user: dict = Depends(role_required("ESTUDIANTE"))):
    student = get_student_profile(user["id"])
    try:
        payment = register_mock_payment(student["id"], user["id"], factura_id, acting_as=user["correo"])
        add_flash(request, "success", f"Pago aprobado: {payment['referencia_pago']}.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/student/finance", status_code=303)


@router.get("/notifications")
def notifications_page(request: Request, user: dict = Depends(role_required("ESTUDIANTE"))):
    student = get_student_profile(user["id"])
    context = base_context(request)
    context.update({"notifications": list_notifications(user["id"], student["id"])})
    return templates.TemplateResponse("student_notifications.html", context)


@router.post("/notifications/{notification_id}/read")
def read_notification(request: Request, notification_id: int, user: dict = Depends(role_required("ESTUDIANTE"))):
    try:
        mark_as_read(notification_id, acting_as=user["correo"])
        add_flash(request, "success", "Notificación marcada como leída.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/student/notifications", status_code=303)
