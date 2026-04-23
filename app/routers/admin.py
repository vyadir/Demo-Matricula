from __future__ import annotations

from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import RedirectResponse

from app.core.flash import add_flash
from app.deps import role_required
from app.services import admin as admin_service
from app.templating import base_context, templates

router = APIRouter(prefix="/admin", tags=["admin"])


ADMIN_ROLES = ("ADMIN_TI", "REGISTRO_ACADEMICO", "TESORERIA")


@router.get("/catalogs")
def catalogs_page(request: Request, user: dict = Depends(role_required(*ADMIN_ROLES))):
    context = base_context(request)
    context.update(
        {
            "programs": admin_service.list_programs(),
            "plans": admin_service.list_plans(),
            "courses": admin_service.list_courses(),
            "course_rules": admin_service.list_course_rules(),
            "periods": admin_service.list_periods(),
            "classrooms": admin_service.list_classrooms(),
            "sections": admin_service.list_sections(),
            "teachers": admin_service.list_teachers(),
            "users": admin_service.list_users(),
            "roles": admin_service.list_roles(),
        }
    )
    return templates.TemplateResponse("admin_catalogs.html", context)


@router.post("/programs")
def create_program(
    request: Request,
    codigo: str = Form(...),
    nombre: str = Form(...),
    nivel_titulo: str = Form(...),
    facultad: str = Form(""),
    departamento: str = Form(""),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.create_program(
            {
                "codigo": codigo,
                "nombre": nombre,
                "nivel_titulo": nivel_titulo,
                "facultad": facultad,
                "departamento": departamento,
            },
            acting_as=user["correo"],
        )
        add_flash(request, "success", "Programa académico creado.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/plans")
def create_plan(
    request: Request,
    programa_academico_id: int = Form(...),
    codigo: str = Form(...),
    nombre: str = Form(...),
    version: str = Form(...),
    creditos_totales: float = Form(...),
    fecha_vigencia_inicio: str = Form(""),
    fecha_vigencia_fin: str = Form(""),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.create_plan(
            {
                "programa_academico_id": programa_academico_id,
                "codigo": codigo,
                "nombre": nombre,
                "version": version,
                "creditos_totales": creditos_totales,
                "fecha_vigencia_inicio": fecha_vigencia_inicio,
                "fecha_vigencia_fin": fecha_vigencia_fin,
            },
            acting_as=user["correo"],
        )
        add_flash(request, "success", "Plan de estudio creado.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/courses")
def create_course(
    request: Request,
    codigo: str = Form(...),
    nombre: str = Form(...),
    descripcion: str = Form(""),
    creditos: float = Form(...),
    horas_teoria: int = Form(...),
    horas_practica: int = Form(...),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.create_course(
            {
                "codigo": codigo,
                "nombre": nombre,
                "descripcion": descripcion,
                "creditos": creditos,
                "horas_teoria": horas_teoria,
                "horas_practica": horas_practica,
            },
            acting_as=user["correo"],
        )
        add_flash(request, "success", "Curso creado.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/prerequisites")
def add_prerequisite(
    request: Request,
    course_id: int = Form(...),
    prereq_id: int = Form(...),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.add_prerequisite(course_id, prereq_id, acting_as=user["correo"])
        add_flash(request, "success", "Prerequisito agregado.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/corequisites")
def add_corequisite(
    request: Request,
    course_id: int = Form(...),
    coreq_id: int = Form(...),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.add_corequisite(course_id, coreq_id, acting_as=user["correo"])
        add_flash(request, "success", "Correquisito agregado.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/periods")
def create_period(
    request: Request,
    codigo: str = Form(...),
    nombre: str = Form(...),
    tipo_periodo: str = Form(...),
    fecha_inicio: str = Form(...),
    fecha_fin: str = Form(...),
    fecha_inicio_matricula: str = Form(...),
    fecha_fin_matricula: str = Form(...),
    fecha_inicio_ajuste: str = Form(""),
    fecha_fin_ajuste: str = Form(""),
    maximo_creditos: float = Form(...),
    estado: str = Form(...),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.create_period(
            {
                "codigo": codigo,
                "nombre": nombre,
                "tipo_periodo": tipo_periodo,
                "fecha_inicio": fecha_inicio,
                "fecha_fin": fecha_fin,
                "fecha_inicio_matricula": fecha_inicio_matricula,
                "fecha_fin_matricula": fecha_fin_matricula,
                "fecha_inicio_ajuste": fecha_inicio_ajuste,
                "fecha_fin_ajuste": fecha_fin_ajuste,
                "maximo_creditos": maximo_creditos,
                "estado": estado,
            },
            acting_as=user["correo"],
        )
        add_flash(request, "success", "Periodo académico creado.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/classrooms")
def create_classroom(
    request: Request,
    codigo: str = Form(...),
    edificio: str = Form(""),
    sede: str = Form(""),
    capacidad: int = Form(...),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.create_classroom(
            {"codigo": codigo, "edificio": edificio, "sede": sede, "capacidad": capacidad},
            acting_as=user["correo"],
        )
        add_flash(request, "success", "Aula creada.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/sections")
def create_section(
    request: Request,
    periodo_academico_id: int = Form(...),
    curso_id: int = Form(...),
    codigo_seccion: str = Form(...),
    docente_id: int | None = Form(None),
    aula_id: int | None = Form(None),
    modalidad: str = Form(...),
    cupo: int = Form(...),
    cupo_lista_espera: int = Form(...),
    estado: str = Form(...),
    dia_semana: int = Form(...),
    hora_inicio: str = Form(...),
    hora_fin: str = Form(...),
    observaciones: str = Form(""),
    user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO")),
):
    try:
        admin_service.create_section(
            {
                "periodo_academico_id": periodo_academico_id,
                "curso_id": curso_id,
                "codigo_seccion": codigo_seccion,
                "docente_id": docente_id,
                "aula_id": aula_id,
                "modalidad": modalidad,
                "cupo": cupo,
                "cupo_lista_espera": cupo_lista_espera,
                "estado": estado,
                "dia_semana": dia_semana,
                "hora_inicio": hora_inicio,
                "hora_fin": hora_fin,
                "observaciones": observaciones,
            },
            acting_as=user["correo"],
        )
        add_flash(request, "success", "Sección creada.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)


@router.post("/user-roles")
def assign_user_role(
    request: Request,
    user_id: int = Form(...),
    role_id: int = Form(...),
    user: dict = Depends(role_required("ADMIN_TI")),
):
    try:
        admin_service.assign_role(user_id, role_id, acting_as=user["correo"])
        add_flash(request, "success", "Rol asignado al usuario.")
    except Exception as exc:  # noqa: BLE001
        add_flash(request, "error", str(exc))
    return RedirectResponse(url="/admin/catalogs", status_code=303)
