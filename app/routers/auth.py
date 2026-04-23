from __future__ import annotations

from fastapi import APIRouter, Form, Request
from fastapi.responses import RedirectResponse

from app.core.config import get_settings
from app.core.flash import add_flash
from app.db import fetch_all, fetch_one
from app.services.auth import authenticate_user
from app.templating import base_context, templates

router = APIRouter()


@router.get("/login")
def login_page(request: Request):
    if request.session.get("user_id"):
        return RedirectResponse(url="/app", status_code=303)
    demo_users = fetch_all(
        """
        SELECT nombre_usuario, correo, nombres, apellidos
        FROM usuarios
        WHERE nombre_usuario IN ('admin', 'registro', 'tesoreria', 'estudiante', 'auditor')
        ORDER BY nombre_usuario
        """
    )
    settings = get_settings()
    context = base_context(request)
    context.update({"demo_users": demo_users, "show_demo_users": settings.app_env.lower() != "production"})
    return templates.TemplateResponse("login.html", context)


@router.post("/login")
def login_submit(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
):
    user = authenticate_user(username, password)
    if not user:
        add_flash(request, "error", "Credenciales inválidas o usuario inactivo.")
        return RedirectResponse(url="/login", status_code=303)

    request.session["user_id"] = user["id"]
    add_flash(request, "success", f"Bienvenido, {user['nombres']}.")
    return RedirectResponse(url="/app", status_code=303)


@router.get("/auth/sso")
def sso_login(request: Request):
    settings = get_settings()
    if settings.sso_mode.lower() == "mock":
        demo_users = fetch_all(
            """
            SELECT nombre_usuario, correo, nombres, apellidos
            FROM usuarios
            WHERE nombre_usuario IN ('admin', 'registro', 'tesoreria', 'estudiante', 'auditor')
            ORDER BY nombre_usuario
            """
        )
        context = base_context(request)
        context.update({"demo_users": demo_users, "mock_sso": True, "show_demo_users": settings.app_env.lower() != "production"})
        return templates.TemplateResponse("login.html", context)

    add_flash(
        request,
        "warning",
        "El modo OIDC quedó preparado por variables de entorno, pero requiere credenciales reales del IdP institucional.",
    )
    return RedirectResponse(url="/login", status_code=303)


@router.post("/auth/sso/mock")
def mock_sso(request: Request, username: str = Form(...)):
    user = fetch_one(
        """
        SELECT id, nombre_usuario, nombres, apellidos, estado
        FROM usuarios
        WHERE nombre_usuario = %s
        """,
        (username,),
    )
    if not user or user["estado"] != "ACTIVO":
        add_flash(request, "error", "No fue posible iniciar sesión con el usuario seleccionado.")
        return RedirectResponse(url="/login", status_code=303)

    request.session["user_id"] = user["id"]
    add_flash(request, "success", f"SSO simulado iniciado para {user['nombre_usuario']}.")
    return RedirectResponse(url="/app", status_code=303)


@router.get("/logout")
def logout(request: Request):
    request.session.clear()
    add_flash(request, "success", "Sesión cerrada correctamente.")
    return RedirectResponse(url="/", status_code=303)
