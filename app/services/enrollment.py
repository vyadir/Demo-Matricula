from __future__ import annotations

from datetime import datetime, timedelta

from psycopg import errors

from app.core.config import get_settings
from app.db import fetch_all, fetch_one, get_conn


def get_student_profile(user_id: int) -> dict | None:
    return fetch_one(
        """
        SELECT
            e.id,
            e.carnet,
            e.estado,
            e.promedio_actual,
            e.creditos_aprobados,
            e.programa_academico_id,
            p.nombre AS programa_nombre,
            e.plan_estudio_id
        FROM estudiantes e
        JOIN programas_academicos p ON p.id = e.programa_academico_id
        WHERE e.usuario_id = %s
        """,
        (user_id,),
    )


def get_active_period() -> dict | None:
    return fetch_one(
        """
        SELECT *
        FROM periodos_academicos
        WHERE NOW() BETWEEN fecha_inicio_matricula AND fecha_fin_matricula
           OR (
                fecha_inicio_ajuste IS NOT NULL
                AND fecha_fin_ajuste IS NOT NULL
                AND NOW() BETWEEN fecha_inicio_ajuste AND fecha_fin_ajuste
           )
        ORDER BY fecha_inicio_matricula ASC
        LIMIT 1
        """
    )


def get_or_create_enrollment(student_id: int, period_id: int, *, acting_as: str) -> dict:
    enrollment = fetch_one(
        """
        SELECT *
        FROM matriculas
        WHERE estudiante_id = %s AND periodo_academico_id = %s
        """,
        (student_id, period_id),
        acting_as=acting_as,
    )
    if enrollment:
        return enrollment

    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO matriculas (
                    numero_matricula,
                    estudiante_id,
                    periodo_academico_id,
                    estado
                )
                VALUES (
                    %s,
                    %s,
                    %s,
                    'BORRADOR'
                )
                RETURNING *
                """,
                (
                    f"MAT-{period_id}-{student_id}-{int(datetime.utcnow().timestamp())}",
                    student_id,
                    period_id,
                ),
            )
            return cur.fetchone()


def list_offer(period_id: int, search: str | None = None):
    params: list = [period_id]
    filters = ""
    if search:
        filters = """
            AND (
                c.codigo ILIKE %s
                OR c.nombre ILIKE %s
                OR s.codigo_seccion ILIKE %s
                OR COALESCE(a.codigo, '') ILIKE %s
            )
        """
        term = f"%{search}%"
        params.extend([term, term, term, term])

    return fetch_all(
        f"""
        SELECT
            s.id,
            c.codigo AS curso_codigo,
            c.nombre AS curso_nombre,
            c.creditos,
            s.codigo_seccion,
            s.modalidad,
            s.cupo,
            s.total_matriculados,
            s.cupo_lista_espera,
            s.total_lista_espera,
            s.estado,
            COALESCE(a.codigo, 'Sin aula') AS aula_codigo,
            COALESCE(
                string_agg(
                    CONCAT(
                        CASE hs.dia_semana
                            WHEN 1 THEN 'Lun'
                            WHEN 2 THEN 'Mar'
                            WHEN 3 THEN 'Mié'
                            WHEN 4 THEN 'Jue'
                            WHEN 5 THEN 'Vie'
                            WHEN 6 THEN 'Sáb'
                            WHEN 7 THEN 'Dom'
                        END,
                        ' ',
                        to_char(hs.hora_inicio, 'HH24:MI'),
                        '-',
                        to_char(hs.hora_fin, 'HH24:MI')
                    ),
                    ' · '
                    ORDER BY hs.dia_semana, hs.hora_inicio
                ),
                'Horario pendiente'
            ) AS horario
        FROM secciones s
        JOIN cursos c ON c.id = s.curso_id
        LEFT JOIN aulas a ON a.id = s.aula_id
        LEFT JOIN horarios_seccion hs ON hs.seccion_id = s.id
        WHERE s.periodo_academico_id = %s
          AND s.estado IN ('ABIERTA', 'PLANIFICADA')
          {filters}
        GROUP BY s.id, c.codigo, c.nombre, c.creditos, s.codigo_seccion, s.modalidad, s.cupo,
                 s.total_matriculados, s.cupo_lista_espera, s.total_lista_espera, s.estado, a.codigo
        ORDER BY c.codigo, s.codigo_seccion
        """,
        params,
    )


def compute_section_cost(section_id: int) -> float:
    settings = get_settings()
    section = fetch_one(
        """
        SELECT c.creditos
        FROM secciones s
        JOIN cursos c ON c.id = s.curso_id
        WHERE s.id = %s
        """,
        (section_id,),
    )
    if not section:
        raise ValueError("La sección no existe.")
    return float(section["creditos"]) * settings.tuition_price_per_credit


def add_section_to_enrollment(student_id: int, user_id: int, section_id: int, *, acting_as: str) -> str:
    period = get_active_period()
    if not period:
        raise ValueError("No existe un periodo de matrícula o ajuste abierto.")

    enrollment = get_or_create_enrollment(student_id, period["id"], acting_as=acting_as)
    section_cost = compute_section_cost(section_id)

    try:
        with get_conn(acting_as=acting_as) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO detalle_matricula (matricula_id, seccion_id, costo_unitario)
                    VALUES (%s, %s, %s)
                    RETURNING estado
                    """,
                    (enrollment["id"], section_id, section_cost),
                )
                row = cur.fetchone()
                notify(
                    cur,
                    student_id,
                    user_id,
                    "INTERNO",
                    "Sección agregada a tu matrícula",
                    f"La sección {section_id} fue agregada con estado {row['estado']}.",
                    "matriculas",
                    enrollment["id"],
                )
                return row["estado"]
    except Exception as exc:  # noqa: BLE001
        raise ValueError(str(exc).replace("ERROR: ", "").strip()) from exc


def remove_detail(detail_id: int, user_id: int, *, acting_as: str) -> None:
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT m.estudiante_id, dm.matricula_id
                FROM detalle_matricula dm
                JOIN matriculas m ON m.id = dm.matricula_id
                WHERE dm.id = %s
                """,
                (detail_id,),
            )
            row = cur.fetchone()
            if not row:
                raise ValueError("El detalle no existe.")

            cur.execute("DELETE FROM detalle_matricula WHERE id = %s", (detail_id,))
            notify(
                cur,
                row["estudiante_id"],
                user_id,
                "INTERNO",
                "Sección retirada de la matrícula",
                "Se eliminó una sección de tu matrícula actual.",
                "detalle_matricula",
                detail_id,
            )


def list_enrollment_details(student_id: int):
    return fetch_all(
        """
        SELECT
            dm.id,
            dm.estado,
            dm.costo_unitario,
            m.id AS matricula_id,
            m.numero_matricula,
            m.estado AS matricula_estado,
            m.total_creditos,
            m.subtotal,
            m.descuento,
            m.total,
            p.nombre AS periodo_nombre,
            c.codigo AS curso_codigo,
            c.nombre AS curso_nombre,
            c.creditos,
            s.codigo_seccion,
            COALESCE(
                string_agg(
                    CONCAT(
                        CASE hs.dia_semana
                            WHEN 1 THEN 'Lun'
                            WHEN 2 THEN 'Mar'
                            WHEN 3 THEN 'Mié'
                            WHEN 4 THEN 'Jue'
                            WHEN 5 THEN 'Vie'
                            WHEN 6 THEN 'Sáb'
                            WHEN 7 THEN 'Dom'
                        END,
                        ' ',
                        to_char(hs.hora_inicio, 'HH24:MI'),
                        '-',
                        to_char(hs.hora_fin, 'HH24:MI')
                    ),
                    ' · '
                    ORDER BY hs.dia_semana, hs.hora_inicio
                ),
                'Horario pendiente'
            ) AS horario
        FROM detalle_matricula dm
        JOIN matriculas m ON m.id = dm.matricula_id
        JOIN periodos_academicos p ON p.id = m.periodo_academico_id
        JOIN secciones s ON s.id = dm.seccion_id
        JOIN cursos c ON c.id = s.curso_id
        LEFT JOIN horarios_seccion hs ON hs.seccion_id = s.id
        WHERE m.estudiante_id = %s
          AND m.estado IN ('BORRADOR', 'PENDIENTE_PAGO', 'CONFIRMADA', 'AJUSTADA')
        GROUP BY dm.id, m.id, p.nombre, c.codigo, c.nombre, c.creditos, s.codigo_seccion
        ORDER BY m.creado_en DESC, c.codigo
        """,
        (student_id,),
    )


def ensure_invoice(matricula_id: int, *, acting_as: str) -> dict:
    existing = fetch_one(
        """
        SELECT *
        FROM facturas
        WHERE matricula_id = %s
        ORDER BY id DESC
        LIMIT 1
        """,
        (matricula_id,),
        acting_as=acting_as,
    )
    if existing and existing["estado"] != "CANCELADA":
        return existing

    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT matricula.generar_factura_matricula(%s, %s) AS factura_id",
                (matricula_id, datetime.utcnow() + timedelta(days=7)),
            )
            factura_id = cur.fetchone()["factura_id"]
            cur.execute("SELECT * FROM facturas WHERE id = %s", (factura_id,))
            return cur.fetchone()


def notify(cur, student_id: int | None, user_id: int | None, channel: str, subject: str, message: str, entity: str, related_id: int | None) -> None:
    cur.execute(
        """
        INSERT INTO notificaciones (
            estudiante_id,
            usuario_id,
            canal,
            asunto,
            mensaje,
            estado,
            entidad_relacionada,
            id_relacionado,
            enviada_en
        )
        VALUES (%s, %s, %s, %s, %s, 'ENVIADA', %s, %s, NOW())
        """,
        (student_id, user_id, channel, subject, message, entity, related_id),
    )


def dashboard_summary(student_id: int):
    return fetch_one(
        """
        WITH enrollment AS (
            SELECT COUNT(*) AS cursos, COALESCE(SUM(total), 0) AS total
            FROM matriculas
            WHERE estudiante_id = %s
              AND estado IN ('BORRADOR', 'PENDIENTE_PAGO', 'CONFIRMADA', 'AJUSTADA')
        ),
        debt AS (
            SELECT COALESCE(SUM(saldo), 0) AS saldo
            FROM facturas
            WHERE estudiante_id = %s
              AND estado IN ('EMITIDA', 'PAGADA_PARCIAL', 'VENCIDA')
        ),
        unread AS (
            SELECT COUNT(*) AS pendientes
            FROM notificaciones
            WHERE estudiante_id = %s
              AND estado IN ('PENDIENTE', 'ENVIADA')
        )
        SELECT enrollment.cursos, enrollment.total, debt.saldo, unread.pendientes
        FROM enrollment, debt, unread
        """,
        (student_id, student_id, student_id),
    )
