from __future__ import annotations

from app.db import fetch_all, execute


def list_notifications(user_id: int, student_id: int | None = None):
    if student_id:
        return fetch_all(
            """
            SELECT *
            FROM notificaciones
            WHERE estudiante_id = %s OR usuario_id = %s
            ORDER BY creado_en DESC
            """,
            (student_id, user_id),
        )
    return fetch_all(
        """
        SELECT *
        FROM notificaciones
        WHERE usuario_id = %s
        ORDER BY creado_en DESC
        """,
        (user_id,),
    )


def mark_as_read(notification_id: int, *, acting_as: str) -> None:
    execute(
        """
        UPDATE notificaciones
        SET estado = 'LEIDA',
            leida_en = NOW(),
            actualizado_en = NOW()
        WHERE id = %s
        """,
        (notification_id,),
        acting_as=acting_as,
    )
