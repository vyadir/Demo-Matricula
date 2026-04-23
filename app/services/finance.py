from __future__ import annotations

from datetime import datetime

from app.core.config import get_settings
from app.db import fetch_all, fetch_one, get_conn
from app.services.enrollment import notify


def list_invoices(student_id: int):
    return fetch_all(
        """
        SELECT *
        FROM facturas
        WHERE estudiante_id = %s
        ORDER BY fecha_emision DESC
        """,
        (student_id,),
    )


def list_payments(student_id: int):
    return fetch_all(
        """
        SELECT *
        FROM pagos
        WHERE estudiante_id = %s
        ORDER BY fecha_pago DESC
        """,
        (student_id,),
    )


def list_receipts(student_id: int):
    return fetch_all(
        """
        SELECT *
        FROM vista_recibos_pago
        WHERE estudiante_id = %s
        ORDER BY fecha_emision DESC
        """,
        (student_id,),
    )


def list_vouchers(student_id: int):
    return fetch_all(
        """
        SELECT *
        FROM vista_comprobantes_matricula
        WHERE carnet IN (
            SELECT carnet FROM estudiantes WHERE id = %s
        )
        ORDER BY fecha_emision DESC
        """,
        (student_id,),
    )


def register_mock_payment(student_id: int, user_id: int, factura_id: int, *, acting_as: str) -> dict:
    invoice = fetch_one(
        """
        SELECT *
        FROM facturas
        WHERE id = %s AND estudiante_id = %s
        """,
        (factura_id, student_id),
        acting_as=acting_as,
    )
    if not invoice:
        raise ValueError("La factura no existe para el estudiante autenticado.")

    if float(invoice["saldo"]) <= 0:
        raise ValueError("La factura ya se encuentra saldada.")

    settings = get_settings()
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO pagos (
                    referencia_pago,
                    estudiante_id,
                    factura_id,
                    matricula_id,
                    metodo_pago,
                    id_externo_pasarela,
                    estado_externo,
                    monto,
                    moneda,
                    fecha_pago,
                    estado,
                    respuesta_pasarela_raw
                )
                VALUES (
                    %s, %s, %s, %s, 'TARJETA', %s, 'approved', %s, %s, NOW(), 'APROBADO', %s::jsonb
                )
                RETURNING *
                """,
                (
                    f"PAY-{factura_id}-{int(datetime.utcnow().timestamp())}",
                    student_id,
                    factura_id,
                    invoice["matricula_id"],
                    f"mock-{factura_id}-{int(datetime.utcnow().timestamp())}",
                    invoice["saldo"],
                    settings.default_currency,
                    '{"provider":"mock","status":"approved"}',
                ),
            )
            payment = cur.fetchone()
            if invoice["matricula_id"]:
                cur.execute("SELECT matricula.confirmar_matricula(%s, %s)", (invoice["matricula_id"], user_id))
            notify(
                cur,
                student_id,
                user_id,
                "EMAIL",
                "Pago aplicado correctamente",
                f"Se registró el pago {payment['referencia_pago']} por {payment['monto']} {payment['moneda']}.",
                "pagos",
                payment["id"],
            )
            return payment
