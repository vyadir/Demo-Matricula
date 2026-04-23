from __future__ import annotations

from app.db import fetch_all


def enrollment_report():
    return fetch_all(
        """
        SELECT *
        FROM vista_reporte_matricula
        ORDER BY creado_en DESC
        """
    )


def financial_report():
    return fetch_all(
        """
        SELECT *
        FROM vista_reporte_financiero
        ORDER BY fecha_emision DESC
        """
    )


def audit_report(limit: int = 100):
    return fetch_all(
        """
        SELECT *
        FROM bitacora_auditoria
        ORDER BY fecha_cambio DESC
        LIMIT %s
        """,
        (limit,),
    )
