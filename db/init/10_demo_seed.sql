SET search_path TO matricula, public;
SELECT set_config('app.usuario_actual', 'seed-demo', false);

-- ===========================
-- USUARIOS Y ROLES DEMO
-- ===========================
INSERT INTO usuarios (nombre_usuario, correo, hash_contrasena, nombres, apellidos, telefono)
VALUES
    ('admin', 'admin@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$1e57bc33bfca46449964832e9438172349bd2f8111af4aed847868d03c26acee', 'Alicia', 'Admin', '7000-1001'),
    ('registro', 'registro@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$19f0f7cf2c57ffc0d4440693f7de798b658071732423e8da689ed7e87bcecc5a', 'Raúl', 'Registro', '7000-1002'),
    ('tesoreria', 'tesoreria@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$4b321e077e4ca9f2f1f4a9156d3dcd6886365dd419d6e011f75ce6ab21386610', 'Teresa', 'Tesorería', '7000-1003'),
    ('estudiante', 'estudiante@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$dc36b01b043d734ece0be5b2bbd9cef268ef37115275b3bbf2c193b26cec26a2', 'Elena', 'Estudiante', '7000-1004'),
    ('estudiante2', 'estudiante2@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$dc36b01b043d734ece0be5b2bbd9cef268ef37115275b3bbf2c193b26cec26a2', 'Mario', 'Mora', '7000-1005'),
    ('auditor', 'auditor@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$725c44ca3f45f0f1ec5f6287380fbe14eba8820bfe97206aced88a4f8ff6895a', 'Ana', 'Auditor', '7000-1006'),
    ('docente', 'docente@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$d67578fa2d2e63913662a937440085f5da48b8410812dddf33f396c654ea4aaa', 'Daniel', 'Docente', '7000-1007');

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id
FROM usuarios u
JOIN roles r ON
    (u.nombre_usuario = 'admin' AND r.codigo = 'ADMIN_TI') OR
    (u.nombre_usuario = 'registro' AND r.codigo = 'REGISTRO_ACADEMICO') OR
    (u.nombre_usuario = 'tesoreria' AND r.codigo = 'TESORERIA') OR
    (u.nombre_usuario = 'estudiante' AND r.codigo = 'ESTUDIANTE') OR
    (u.nombre_usuario = 'estudiante2' AND r.codigo = 'ESTUDIANTE') OR
    (u.nombre_usuario = 'estudiante3' AND r.codigo = 'ESTUDIANTE') OR
    (u.nombre_usuario = 'estudiante4' AND r.codigo = 'ESTUDIANTE') OR
    (u.nombre_usuario = 'auditor' AND r.codigo = 'AUDITOR');

-- ===========================
-- CATÁLOGOS BASE
-- ===========================
INSERT INTO programas_academicos (codigo, nombre, nivel_titulo, facultad, departamento)
VALUES
    ('ING-SIS', 'Ingeniería en Sistemas', 'BACHILLERATO', 'Ingeniería', 'Computación');

INSERT INTO planes_estudio (
    programa_academico_id, codigo, nombre, version, creditos_totales,
    fecha_vigencia_inicio, activo
)
SELECT p.id, 'PLAN-ING-SIS-2026', 'Plan Ingeniería en Sistemas 2026', '2026', 144, CURRENT_DATE - INTERVAL '180 day', TRUE
FROM programas_academicos p
WHERE p.codigo = 'ING-SIS';

INSERT INTO cursos (codigo, nombre, descripcion, creditos, horas_teoria, horas_practica)
VALUES
    ('MAT101', 'Matemática I', 'Fundamentos matemáticos para ingeniería.', 4, 4, 0),
    ('PRO101', 'Programación I', 'Introducción al desarrollo de software.', 4, 3, 2),
    ('BD101', 'Bases de Datos', 'Modelado relacional y SQL.', 4, 3, 2),
    ('PRO102', 'Programación II', 'Estructuras de datos y programación orientada a objetos.', 4, 3, 2),
    ('MAT102', 'Matemática II', 'Cálculo diferencial e integral.', 4, 4, 0),
    ('ING101', 'Inglés Técnico', 'Comunicación técnica aplicada a TI.', 2, 2, 0),
    ('RED201', 'Redes I', 'Fundamentos de redes y conectividad.', 3, 2, 2);

INSERT INTO plan_estudio_curso (plan_estudio_id, curso_id, ciclo, es_obligatorio)
SELECT pe.id, c.id,
       CASE c.codigo
           WHEN 'MAT101' THEN 1
           WHEN 'PRO101' THEN 1
           WHEN 'ING101' THEN 1
           WHEN 'BD101' THEN 2
           WHEN 'PRO102' THEN 2
           WHEN 'MAT102' THEN 2
           WHEN 'RED201' THEN 3
       END,
       TRUE
FROM planes_estudio pe
JOIN cursos c ON c.codigo IN ('MAT101', 'PRO101', 'BD101', 'PRO102', 'MAT102', 'ING101', 'RED201')
WHERE pe.codigo = 'PLAN-ING-SIS-2026';

INSERT INTO prerequisitos_curso (curso_id, curso_prerequisito_id, nota_minima)
SELECT c.id, p.id, 70
FROM cursos c
JOIN cursos p ON
    (c.codigo = 'BD101' AND p.codigo = 'PRO101') OR
    (c.codigo = 'PRO102' AND p.codigo = 'PRO101') OR
    (c.codigo = 'MAT102' AND p.codigo = 'MAT101') OR
    (c.codigo = 'RED201' AND p.codigo = 'BD101');

INSERT INTO correquisitos_curso (curso_id, curso_correquisito_id)
SELECT c.id, p.id
FROM cursos c
JOIN cursos p ON c.codigo = 'PRO102' AND p.codigo = 'BD101';

INSERT INTO aulas (codigo, edificio, sede, capacidad)
VALUES
    ('LAB-A1', 'Ingeniería', 'Campus Central', 30),
    ('AULA-B2', 'Humanidades', 'Campus Central', 35),
    ('VIRT-01', 'Virtual', 'Remoto', 999);

INSERT INTO periodos_academicos (
    codigo, nombre, tipo_periodo, fecha_inicio, fecha_fin,
    fecha_inicio_matricula, fecha_fin_matricula, fecha_inicio_ajuste, fecha_fin_ajuste,
    maximo_creditos, estado
)
VALUES (
    '2026-1',
    'I Semestre 2026',
    'SEMESTRE',
    CURRENT_DATE - INTERVAL '15 day',
    CURRENT_DATE + INTERVAL '120 day',
    CURRENT_TIMESTAMP - INTERVAL '7 day',
    CURRENT_TIMESTAMP + INTERVAL '20 day',
    CURRENT_TIMESTAMP + INTERVAL '21 day',
    CURRENT_TIMESTAMP + INTERVAL '35 day',
    18,
    'MATRICULA_ABIERTA'
);

-- ===========================
-- DOCENTE Y ESTUDIANTES
-- ===========================
INSERT INTO docentes (usuario_id, codigo_empleado, especialidad)
SELECT id, 'DOC-1001', 'Ingeniería de software'
FROM usuarios
WHERE nombre_usuario = 'docente';

INSERT INTO estudiantes (
    usuario_id, carnet, programa_academico_id, plan_estudio_id, fecha_ingreso,
    promedio_actual, creditos_aprobados, estado
)
SELECT
    u.id,
    CASE u.nombre_usuario
        WHEN 'estudiante' THEN '20260001'
        ELSE '20260002'
    END,
    p.id,
    pe.id,
    CURRENT_DATE - INTERVAL '180 day',
    CASE u.nombre_usuario
        WHEN 'estudiante' THEN 88.50
        ELSE 82.10
    END,
    CASE u.nombre_usuario
        WHEN 'estudiante' THEN 12
        ELSE 8
    END,
    'ACTIVO'
FROM usuarios u
JOIN programas_academicos p ON p.codigo = 'ING-SIS'
JOIN planes_estudio pe ON pe.codigo = 'PLAN-ING-SIS-2026'
WHERE u.nombre_usuario IN ('estudiante', 'estudiante2');

INSERT INTO historial_cursos_estudiante (
    estudiante_id, periodo_academico_id, curso_id, seccion_id, nota_final, aprobado
)
SELECT e.id, pa.id, c.id, NULL,
       CASE c.codigo
           WHEN 'MAT101' THEN 90
           WHEN 'PRO101' THEN 89
       END,
       TRUE
FROM estudiantes e
JOIN usuarios u ON u.id = e.usuario_id
JOIN periodos_academicos pa ON pa.codigo = '2026-1'
JOIN cursos c ON c.codigo IN ('MAT101', 'PRO101')
WHERE u.nombre_usuario = 'estudiante';

INSERT INTO historial_cursos_estudiante (
    estudiante_id, periodo_academico_id, curso_id, seccion_id, nota_final, aprobado
)
SELECT e.id, pa.id, c.id, NULL,
       CASE c.codigo
           WHEN 'MAT101' THEN 78
           WHEN 'PRO101' THEN 81
       END,
       TRUE
FROM estudiantes e
JOIN usuarios u ON u.id = e.usuario_id
JOIN periodos_academicos pa ON pa.codigo = '2026-1'
JOIN cursos c ON c.codigo IN ('MAT101', 'PRO101')
WHERE u.nombre_usuario = 'estudiante2';

INSERT INTO becas (codigo, nombre, descripcion, porcentaje_descuento, monto_descuento_fijo, activa)
VALUES ('BECA-25', 'Beca de excelencia 25%', 'Beca parcial de demostración', 25, 0, TRUE);

INSERT INTO estudiante_beca (estudiante_id, beca_id, periodo_academico_id, activa)
SELECT e.id, b.id, p.id, TRUE
FROM estudiantes e
JOIN usuarios u ON u.id = e.usuario_id
JOIN becas b ON b.codigo = 'BECA-25'
JOIN periodos_academicos p ON p.codigo = '2026-1'
WHERE u.nombre_usuario = 'estudiante';

-- ===========================
-- OFERTA ACADÉMICA
-- ===========================
INSERT INTO secciones (
    periodo_academico_id, curso_id, codigo_seccion, docente_id, aula_id, modalidad,
    cupo, cupo_lista_espera, estado, observaciones
)
SELECT p.id, c.id, s.codigo, d.id, a.id, s.modalidad::modalidad_enum, s.cupo, s.cupo_espera, 'ABIERTA', s.obs
FROM periodos_academicos p
JOIN docentes d ON d.codigo_empleado = 'DOC-1001'
JOIN LATERAL (
    VALUES
        ('BD101', 'A', 'PRESENCIAL', 25, 5, 'Martes 08:00'),
        ('PRO102', 'A', 'PRESENCIAL', 25, 5, 'Martes 10:30'),
        ('MAT102', 'A', 'PRESENCIAL', 25, 5, 'Martes 08:30'),
        ('ING101', 'A', 'VIRTUAL', 1, 5, 'Miércoles 18:00'),
        ('RED201', 'A', 'PRESENCIAL', 20, 5, 'Jueves 08:00')
) AS s(curso_codigo, codigo, modalidad, cupo, cupo_espera, obs) ON TRUE
JOIN cursos c ON c.codigo = s.curso_codigo
JOIN aulas a ON a.codigo = CASE
    WHEN s.curso_codigo = 'ING101' THEN 'VIRT-01'
    WHEN s.curso_codigo = 'PRO102' THEN 'LAB-A1'
    WHEN s.curso_codigo = 'BD101' THEN 'LAB-A1'
    WHEN s.curso_codigo = 'MAT102' THEN 'AULA-B2'
    ELSE 'AULA-B2'
END
WHERE p.codigo = '2026-1';

INSERT INTO horarios_seccion (seccion_id, dia_semana, hora_inicio, hora_fin, aula_id)
SELECT s.id,
       CASE c.codigo
           WHEN 'BD101' THEN 2
           WHEN 'PRO102' THEN 2
           WHEN 'MAT102' THEN 2
           WHEN 'ING101' THEN 3
           ELSE 4
       END,
       CASE c.codigo
           WHEN 'BD101' THEN TIME '08:00'
           WHEN 'PRO102' THEN TIME '10:30'
           WHEN 'MAT102' THEN TIME '08:30'
           WHEN 'ING101' THEN TIME '18:00'
           ELSE TIME '08:00'
       END,
       CASE c.codigo
           WHEN 'BD101' THEN TIME '10:00'
           WHEN 'PRO102' THEN TIME '12:30'
           WHEN 'MAT102' THEN TIME '10:30'
           WHEN 'ING101' THEN TIME '20:00'
           ELSE TIME '10:00'
       END,
       s.aula_id
FROM secciones s
JOIN cursos c ON c.id = s.curso_id
JOIN periodos_academicos p ON p.id = s.periodo_academico_id
WHERE p.codigo = '2026-1';

-- ===========================
-- MATRÍCULA PREVIA DE SEGUNDO ESTUDIANTE
-- Se usa para llenar la sección ING101 y demostrar lista de espera.
-- ===========================
INSERT INTO matriculas (numero_matricula, estudiante_id, periodo_academico_id, estado)
SELECT 'MAT-DEMO-0001', e.id, p.id, 'BORRADOR'
FROM estudiantes e
JOIN usuarios u ON u.id = e.usuario_id
JOIN periodos_academicos p ON p.codigo = '2026-1'
WHERE u.nombre_usuario = 'estudiante2';

INSERT INTO detalle_matricula (matricula_id, seccion_id, costo_unitario)
SELECT m.id, s.id, c.creditos * 27500
FROM matriculas m
JOIN estudiantes e ON e.id = m.estudiante_id
JOIN usuarios u ON u.id = e.usuario_id
JOIN secciones s ON s.codigo_seccion = 'A'
JOIN cursos c ON c.id = s.curso_id
JOIN periodos_academicos p ON p.id = s.periodo_academico_id
WHERE u.nombre_usuario = 'estudiante2'
  AND p.codigo = '2026-1'
  AND c.codigo = 'ING101';

-- Factura y pago del segundo estudiante para poblar reportes y comprobantes.
DO $$
DECLARE
    v_factura_id BIGINT;
    v_matricula_id BIGINT;
    v_estudiante_id BIGINT;
    v_tesoreria_id BIGINT;
BEGIN
    SELECT m.id, m.estudiante_id
    INTO v_matricula_id, v_estudiante_id
    FROM matriculas m
    JOIN estudiantes e ON e.id = m.estudiante_id
    JOIN usuarios u ON u.id = e.usuario_id
    WHERE u.nombre_usuario = 'estudiante2'
    LIMIT 1;

    SELECT id INTO v_tesoreria_id
    FROM usuarios
    WHERE nombre_usuario = 'tesoreria';

    SELECT matricula.generar_factura_matricula(v_matricula_id, CURRENT_DATE + INTERVAL '10 day')
    INTO v_factura_id;

    INSERT INTO pagos (
        referencia_pago, estudiante_id, factura_id, matricula_id, metodo_pago,
        id_externo_pasarela, estado_externo, monto, moneda, fecha_pago, estado,
        respuesta_pasarela_raw
    )
    SELECT
        'PAY-DEMO-0001',
        v_estudiante_id,
        f.id,
        f.matricula_id,
        'TRANSFERENCIA',
        'bank-demo-0001',
        'approved',
        f.saldo,
        'CRC',
        NOW() - INTERVAL '1 day',
        'APROBADO',
        '{"provider":"seed","status":"approved"}'::jsonb
    FROM facturas f
    WHERE f.id = v_factura_id;

    PERFORM matricula.confirmar_matricula(v_matricula_id, v_tesoreria_id);
END $$;

INSERT INTO notificaciones (
    estudiante_id, usuario_id, canal, asunto, mensaje, estado,
    entidad_relacionada, id_relacionado, enviada_en
)
SELECT e.id, u.id, 'EMAIL', 'Bienvenida al portal',
       'Ya puedes explorar la oferta académica, generar tu estado de cuenta y completar el pago en línea.',
       'ENVIADA', 'estudiantes', e.id, NOW() - INTERVAL '2 hour'
FROM estudiantes e
JOIN usuarios u ON u.id = e.usuario_id
WHERE u.nombre_usuario = 'estudiante';

INSERT INTO notificaciones (
    estudiante_id, usuario_id, canal, asunto, mensaje, estado,
    entidad_relacionada, id_relacionado, enviada_en
)
SELECT e.id, u.id, 'SMS', 'Recuerda completar tu matrícula',
       'Tu periodo de matrícula está abierto. Agrega cursos y genera el estado de cuenta cuando termines.',
       'PENDIENTE', 'periodos_academicos', p.id, NOW() - INTERVAL '30 minute'
FROM estudiantes e
JOIN usuarios u ON u.id = e.usuario_id
JOIN periodos_academicos p ON p.codigo = '2026-1'
WHERE u.nombre_usuario = 'estudiante';




INSERT INTO usuarios (nombre_usuario, correo, hash_contrasena, nombres, apellidos, telefono)
VALUES
('estudiante3', 'estudiante3@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$dc36b01b043d734ece0be5b2bbd9cef268ef37115275b3bbf2c193b26cec26a2', 'Laura', 'Pérez', '7000-1008');

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id
FROM usuarios u
JOIN roles r ON r.codigo = 'ESTUDIANTE'
WHERE u.nombre_usuario = 'estudiante3';

INSERT INTO estudiantes (
    usuario_id, carnet, programa_academico_id, plan_estudio_id, fecha_ingreso,
    promedio_actual, creditos_aprobados, estado
)
SELECT
    u.id,
    '20260003',
    p.id,
    pe.id,
    CURRENT_DATE - INTERVAL '180 day',
    79.25,
    0,
    'ACTIVO'
FROM usuarios u
JOIN programas_academicos p ON p.codigo = 'ING-SIS'
JOIN planes_estudio pe ON pe.codigo = 'PLAN-ING-SIS-2026'
WHERE u.nombre_usuario = 'estudiante3';

INSERT INTO usuarios (nombre_usuario, correo, hash_contrasena, nombres, apellidos, telefono)
VALUES
('estudiante4', 'estudiante4@demo.edu', 'pbkdf2_sha256$390000$staticdemo123456$dc36b01b043d734ece0be5b2bbd9cef268ef37115275b3bbf2c193b26cec26a2', 'Andrés', 'Mora', '7000-1009');

INSERT INTO usuario_rol (usuario_id, rol_id)
SELECT u.id, r.id
FROM usuarios u
JOIN roles r ON r.codigo = 'ESTUDIANTE'
WHERE u.nombre_usuario = 'estudiante4';

INSERT INTO estudiantes (
    usuario_id, carnet, programa_academico_id, plan_estudio_id, fecha_ingreso,
    promedio_actual, creditos_aprobados, estado
)
SELECT
    u.id,
    '20260004',
    p.id,
    pe.id,
    CURRENT_DATE - INTERVAL '120 day',
    81.50,
    6,
    'ACTIVO'
FROM usuarios u
JOIN programas_academicos p ON p.codigo = 'ING-SIS'
JOIN planes_estudio pe ON pe.codigo = 'PLAN-ING-SIS-2026'
WHERE u.nombre_usuario = 'estudiante4';