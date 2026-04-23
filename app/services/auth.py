from __future__ import annotations

from app.core.security import verify_password
from app.db import fetch_one


def authenticate_user(username_or_email: str, password: str) -> dict | None:
    user = fetch_one(
        """
        SELECT id, nombre_usuario, correo, nombres, apellidos, hash_contrasena, estado
        FROM usuarios
        WHERE nombre_usuario = %s OR correo = %s
        """,
        (username_or_email, username_or_email),
    )
    if not user or user["estado"] != "ACTIVO":
        return None

    if not verify_password(password, user.get("hash_contrasena")):
        return None

    return user


def get_user_by_email(email: str) -> dict | None:
    return fetch_one(
        """
        SELECT id, nombre_usuario, correo, nombres, apellidos, estado
        FROM usuarios
        WHERE correo = %s
        """,
        (email,),
    )
