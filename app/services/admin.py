from __future__ import annotations

from app.db import fetch_all, fetch_one, get_conn


def admin_overview():
    return fetch_one(
        """
        SELECT
            (SELECT COUNT(*) FROM usuarios WHERE estado = 'ACTIVO') AS usuarios_activos,
            (SELECT COUNT(*) FROM estudiantes WHERE estado = 'ACTIVO') AS estudiantes_activos,
            (SELECT COUNT(*) FROM secciones WHERE estado = 'ABIERTA') AS secciones_abiertas,
            (SELECT COUNT(*) FROM facturas WHERE saldo > 0) AS facturas_pendientes
        """
    )


def list_programs():
    return fetch_all("SELECT * FROM programas_academicos ORDER BY codigo")


def create_program(data: dict, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO programas_academicos (codigo, nombre, nivel_titulo, facultad, departamento)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    data["codigo"],
                    data["nombre"],
                    data.get("nivel_titulo"),
                    data.get("facultad"),
                    data.get("departamento"),
                ),
            )


def list_plans():
    return fetch_all(
        """
        SELECT pe.*, pa.nombre AS programa_nombre
        FROM planes_estudio pe
        JOIN programas_academicos pa ON pa.id = pe.programa_academico_id
        ORDER BY pa.codigo, pe.codigo, pe.version
        """
    )


def create_plan(data: dict, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO planes_estudio (
                    programa_academico_id, codigo, nombre, version, creditos_totales,
                    fecha_vigencia_inicio, fecha_vigencia_fin
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    data["programa_academico_id"],
                    data["codigo"],
                    data["nombre"],
                    data["version"],
                    data["creditos_totales"],
                    data.get("fecha_vigencia_inicio") or None,
                    data.get("fecha_vigencia_fin") or None,
                ),
            )


def list_courses():
    return fetch_all("SELECT * FROM cursos ORDER BY codigo")


def create_course(data: dict, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO cursos (codigo, nombre, descripcion, creditos, horas_teoria, horas_practica)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (
                    data["codigo"],
                    data["nombre"],
                    data.get("descripcion"),
                    data["creditos"],
                    data["horas_teoria"],
                    data["horas_practica"],
                ),
            )


def list_course_rules():
    return fetch_all(
        """
        SELECT
            c.codigo AS curso_codigo,
            c.nombre AS curso_nombre,
            cp.codigo AS prerequisito_codigo,
            cc.codigo AS correquisito_codigo
        FROM cursos c
        LEFT JOIN prerequisitos_curso pr ON pr.curso_id = c.id
        LEFT JOIN cursos cp ON cp.id = pr.curso_prerequisito_id
        LEFT JOIN correquisitos_curso cor ON cor.curso_id = c.id
        LEFT JOIN cursos cc ON cc.id = cor.curso_correquisito_id
        ORDER BY c.codigo
        """
    )


def add_prerequisite(course_id: int, prereq_id: int, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO prerequisitos_curso (curso_id, curso_prerequisito_id, nota_minima)
                VALUES (%s, %s, 70)
                ON CONFLICT DO NOTHING
                """,
                (course_id, prereq_id),
            )


def add_corequisite(course_id: int, coreq_id: int, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO correquisitos_curso (curso_id, curso_correquisito_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING
                """,
                (course_id, coreq_id),
            )


def list_periods():
    return fetch_all("SELECT * FROM periodos_academicos ORDER BY fecha_inicio DESC")


def create_period(data: dict, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO periodos_academicos (
                    codigo, nombre, tipo_periodo, fecha_inicio, fecha_fin,
                    fecha_inicio_matricula, fecha_fin_matricula,
                    fecha_inicio_ajuste, fecha_fin_ajuste, maximo_creditos, estado
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    data["codigo"],
                    data["nombre"],
                    data["tipo_periodo"],
                    data["fecha_inicio"],
                    data["fecha_fin"],
                    data["fecha_inicio_matricula"],
                    data["fecha_fin_matricula"],
                    data.get("fecha_inicio_ajuste") or None,
                    data.get("fecha_fin_ajuste") or None,
                    data["maximo_creditos"],
                    data["estado"],
                ),
            )


def list_classrooms():
    return fetch_all("SELECT * FROM aulas ORDER BY codigo")


def create_classroom(data: dict, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO aulas (codigo, edificio, sede, capacidad)
                VALUES (%s, %s, %s, %s)
                """,
                (data["codigo"], data.get("edificio"), data.get("sede"), data["capacidad"]),
            )


def list_teachers():
    return fetch_all(
        """
        SELECT d.id, d.codigo_empleado, u.nombres, u.apellidos
        FROM docentes d
        JOIN usuarios u ON u.id = d.usuario_id
        WHERE d.activo = TRUE
        ORDER BY u.apellidos, u.nombres
        """
    )


def list_sections():
    return fetch_all(
        """
        SELECT
            s.*,
            c.codigo AS curso_codigo,
            c.nombre AS curso_nombre,
            p.codigo AS periodo_codigo,
            a.codigo AS aula_codigo,
            CONCAT(u.nombres, ' ', u.apellidos) AS docente_nombre
        FROM secciones s
        JOIN cursos c ON c.id = s.curso_id
        JOIN periodos_academicos p ON p.id = s.periodo_academico_id
        LEFT JOIN aulas a ON a.id = s.aula_id
        LEFT JOIN docentes d ON d.id = s.docente_id
        LEFT JOIN usuarios u ON u.id = d.usuario_id
        ORDER BY p.fecha_inicio DESC, c.codigo, s.codigo_seccion
        """
    )


def create_section(data: dict, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO secciones (
                    periodo_academico_id, curso_id, codigo_seccion, docente_id, aula_id,
                    modalidad, cupo, cupo_lista_espera, estado, observaciones
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    data["periodo_academico_id"],
                    data["curso_id"],
                    data["codigo_seccion"],
                    data.get("docente_id") or None,
                    data.get("aula_id") or None,
                    data["modalidad"],
                    data["cupo"],
                    data["cupo_lista_espera"],
                    data["estado"],
                    data.get("observaciones"),
                ),
            )
            section = cur.fetchone()
            cur.execute(
                """
                INSERT INTO horarios_seccion (seccion_id, dia_semana, hora_inicio, hora_fin, aula_id)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    section["id"],
                    data["dia_semana"],
                    data["hora_inicio"],
                    data["hora_fin"],
                    data.get("aula_id") or None,
                ),
            )


def list_users():
    return fetch_all(
        """
        SELECT
            u.id,
            u.nombre_usuario,
            u.correo,
            u.nombres,
            u.apellidos,
            u.estado,
            COALESCE(string_agg(r.codigo, ', ' ORDER BY r.codigo), 'Sin rol') AS roles
        FROM usuarios u
        LEFT JOIN usuario_rol ur ON ur.usuario_id = u.id
        LEFT JOIN roles r ON r.id = ur.rol_id
        GROUP BY u.id
        ORDER BY u.apellidos, u.nombres
        """
    )


def list_roles():
    return fetch_all("SELECT * FROM roles ORDER BY codigo")


def assign_role(user_id: int, role_id: int, *, acting_as: str):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO usuario_rol (usuario_id, rol_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING
                """,
                (user_id, role_id),
            )
