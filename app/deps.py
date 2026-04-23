from __future__ import annotations

from collections.abc import Callable

from fastapi import HTTPException, Request, status

from app.db import fetch_one


def get_current_user(request: Request) -> dict | None:
    user_id = request.session.get("user_id")
    if not user_id:
        return None

    user = fetch_one(
        """
        SELECT
            u.id,
            u.nombre_usuario,
            u.correo,
            u.nombres,
            u.apellidos,
            u.estado,
            COALESCE(
                array_agg(r.codigo ORDER BY r.codigo) FILTER (WHERE r.codigo IS NOT NULL),
                ARRAY[]::varchar[]
            ) AS roles
        FROM usuarios u
        LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
        LEFT JOIN roles r ON r.id = ur.rol_id
        WHERE u.id = %s
        GROUP BY u.id
        """,
        (user_id,),
    )
    return user


def require_user(request: Request) -> dict:
    user = get_current_user(request)
    if not user:
        raise HTTPException(status_code=status.HTTP_303_SEE_OTHER, headers={"Location": "/login"})
    return user


def role_required(*allowed_roles: str) -> Callable[[Request], dict]:
    def dependency(request: Request) -> dict:
        user = require_user(request)
        roles = set(user.get("roles") or [])
        if not roles.intersection(set(allowed_roles)):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tiene permisos suficientes.")
        return user

    return dependency
