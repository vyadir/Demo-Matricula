-- =========================================================
-- MODELO DE MATRÍCULA
-- =========================================================

-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN;

-- Instala la extensión pgcrypto para funciones criptográficas como UUID.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Crea el esquema 'matricula' para organizar objetos de la base de datos.
CREATE SCHEMA IF NOT EXISTS matricula;
-- Define el esquema por defecto para las consultas.
SET search_path TO matricula, public;

-- =========================================================
-- TIPOS
-- En esta sección se crean tipos ENUM para estandarizar estados y valores permitidos en distintas tablas del sistema.
-- =========================================================
-- Bloque anónimo para ejecutar lógica condicional en PostgreSQL.
DO $$
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_usuario_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_usuario_enum AS ENUM ('ACTIVO', 'INACTIVO', 'BLOQUEADO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_estudiante_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_estudiante_enum AS ENUM ('ACTIVO', 'SUSPENDIDO', 'GRADUADO', 'RETIRADO', 'INACTIVO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_periodo_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE tipo_periodo_enum AS ENUM ('SEMESTRE', 'CUATRIMESTRE', 'TRIMESTRE', 'PERSONALIZADO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_periodo_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_periodo_enum AS ENUM ('PLANIFICADO', 'MATRICULA_ABIERTA', 'EN_CURSO', 'CERRADO', 'CANCELADO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_seccion_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_seccion_enum AS ENUM ('PLANIFICADA', 'ABIERTA', 'CERRADA', 'CANCELADA');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'modalidad_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE modalidad_enum AS ENUM ('PRESENCIAL', 'VIRTUAL', 'HIBRIDA');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_matricula_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_matricula_enum AS ENUM ('BORRADOR', 'PENDIENTE_PAGO', 'CONFIRMADA', 'CANCELADA', 'AJUSTADA');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_detalle_matricula_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_detalle_matricula_enum AS ENUM ('MATRICULADO', 'LISTA_ESPERA', 'RETIRADO', 'CANCELADO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_factura_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_factura_enum AS ENUM ('BORRADOR', 'EMITIDA', 'PAGADA_PARCIAL', 'PAGADA', 'CANCELADA', 'VENCIDA');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_pago_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_pago_enum AS ENUM ('PENDIENTE', 'APROBADO', 'RECHAZADO', 'REVERSADO', 'REEMBOLSADO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'metodo_pago_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE metodo_pago_enum AS ENUM ('TARJETA', 'TRANSFERENCIA', 'CAJA', 'BECA', 'EXONERACION', 'PASARELA_EN_LINEA');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_bloqueo_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE tipo_bloqueo_enum AS ENUM ('FINANCIERO', 'ACADEMICO', 'DISCIPLINARIO', 'ADMINISTRATIVO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_bloqueo_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_bloqueo_enum AS ENUM ('ACTIVO', 'RESUELTO', 'EXPIRADO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'canal_notificacion_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE canal_notificacion_enum AS ENUM ('EMAIL', 'SMS', 'PUSH', 'INTERNO');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_notificacion_enum') THEN
-- Define un tipo ENUM para restringir valores válidos.
        CREATE TYPE estado_notificacion_enum AS ENUM ('PENDIENTE', 'ENVIADA', 'FALLIDA', 'LEIDA');
    END IF;
END$$;

-- =========================================================
-- FUNCIONES GENERALES
-- Aquí se definen funciones auxiliares reutilizables, por ejemplo para actualizar fechas de modificación y obtener el usuario actual de la aplicación.
-- =========================================================
-- Se crea o actualiza la función "matricula.actualizar_fecha_modificacion", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.actualizar_fecha_modificacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    NEW.actualizado_en := NOW();
    RETURN NEW;
END;
$$;

-- Se crea o actualiza la función "matricula.usuario_actual_app", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.usuario_actual_app()
RETURNS TEXT
LANGUAGE sql
AS $$
    SELECT COALESCE(current_setting('app.usuario_actual', true), current_user::text);
$$;

-- =========================================================
-- AUDITORÍA
-- En esta sección se crea la bitácora de auditoría y la función que registra automáticamente inserciones, cambios y eliminaciones.
-- =========================================================
-- Se crea la tabla "bitacora_auditoria" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS bitacora_auditoria (
    id                  BIGSERIAL PRIMARY KEY,
    tabla               VARCHAR(100) NOT NULL,
    operacion           VARCHAR(10) NOT NULL,
    id_registro         TEXT NOT NULL,
    datos_anteriores    JSONB,
    datos_nuevos        JSONB,
    usuario_cambio      TEXT,
    fecha_cambio        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Se crea o actualiza la función "matricula.auditar_cambios", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.auditar_cambios()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_registro TEXT;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    v_id_registro :=
        COALESCE(
            CASE
                WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD)->>'id'
                ELSE to_jsonb(NEW)->>'id'
            END,
            gen_random_uuid()::text
        );

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
    INSERT INTO bitacora_auditoria (
        tabla,
        operacion,
        id_registro,
        datos_anteriores,
        datos_nuevos,
        usuario_cambio,
        fecha_cambio
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        v_id_registro,
        CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
        matricula.usuario_actual_app(),
        NOW()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- =========================================================
-- ROLES / PERMISOS / USUARIOS
-- Este bloque define seguridad y acceso: roles, permisos, usuarios y sus relaciones.
-- =========================================================
-- Se crea la tabla "roles" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS roles (
    id                  BIGSERIAL PRIMARY KEY,
    codigo              VARCHAR(50) NOT NULL UNIQUE,
    nombre              VARCHAR(100) NOT NULL,
    descripcion         TEXT,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Se crea la tabla "permisos" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS permisos (
    id                  BIGSERIAL PRIMARY KEY,
    codigo              VARCHAR(100) NOT NULL UNIQUE,
    nombre              VARCHAR(150) NOT NULL,
    descripcion         TEXT,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Se crea la tabla "rol_permiso" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS rol_permiso (
    rol_id              BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permiso_id          BIGINT NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (rol_id, permiso_id)
);

-- Se crea la tabla "usuarios" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS usuarios (
    id                          BIGSERIAL PRIMARY KEY,
    id_externo_sso              VARCHAR(255) UNIQUE,
    nombre_usuario              VARCHAR(100) NOT NULL UNIQUE,
    correo                      VARCHAR(255) NOT NULL UNIQUE,
    hash_contrasena             TEXT,
    nombres                     VARCHAR(100) NOT NULL,
    apellidos                   VARCHAR(100) NOT NULL,
    telefono                    VARCHAR(50),
    estado                      estado_usuario_enum NOT NULL DEFAULT 'ACTIVO',
    ultimo_ingreso_en           TIMESTAMP,
    creado_en                   TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en              TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_correo_usuario CHECK (position('@' in correo) > 1)
);

-- Se crea la tabla "usuario_rol" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS usuario_rol (
    usuario_id          BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rol_id              BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (usuario_id, rol_id)
);

-- =========================================================
-- PROGRAMAS / PLANES / CURSOS
-- Aquí se modela la estructura académica: programas, planes de estudio, cursos y dependencias académicas.
-- =========================================================
-- Se crea la tabla "programas_academicos" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS programas_academicos (
    id                  BIGSERIAL PRIMARY KEY,
    codigo              VARCHAR(50) NOT NULL UNIQUE,
    nombre              VARCHAR(200) NOT NULL,
    nivel_titulo        VARCHAR(100),
    facultad            VARCHAR(150),
    departamento        VARCHAR(150),
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Se crea la tabla "planes_estudio" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS planes_estudio (
    id                      BIGSERIAL PRIMARY KEY,
    programa_academico_id   BIGINT NOT NULL REFERENCES programas_academicos(id),
    codigo                  VARCHAR(50) NOT NULL,
    nombre                  VARCHAR(200) NOT NULL,
    version                 VARCHAR(50) NOT NULL,
    creditos_totales        NUMERIC(6,2) NOT NULL DEFAULT 0,
    activo                  BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_vigencia_inicio   DATE,
    fecha_vigencia_fin      DATE,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_plan_estudio UNIQUE (programa_academico_id, codigo, version),
    CONSTRAINT chk_creditos_plan CHECK (creditos_totales >= 0)
);

-- Se crea la tabla "cursos" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS cursos (
    id                  BIGSERIAL PRIMARY KEY,
    codigo              VARCHAR(50) NOT NULL UNIQUE,
    nombre              VARCHAR(200) NOT NULL,
    descripcion         TEXT,
    creditos            NUMERIC(5,2) NOT NULL,
    horas_teoria        INTEGER NOT NULL DEFAULT 0,
    horas_practica      INTEGER NOT NULL DEFAULT 0,
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_creditos_curso CHECK (creditos > 0),
    CONSTRAINT chk_horas_curso CHECK (horas_teoria >= 0 AND horas_practica >= 0)
);

-- Se crea la tabla "plan_estudio_curso" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS plan_estudio_curso (
    id                  BIGSERIAL PRIMARY KEY,
    plan_estudio_id     BIGINT NOT NULL REFERENCES planes_estudio(id) ON DELETE CASCADE,
    curso_id            BIGINT NOT NULL REFERENCES cursos(id),
    ciclo               INTEGER,
    es_obligatorio      BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_plan_curso UNIQUE (plan_estudio_id, curso_id)
);

-- Se crea la tabla "prerequisitos_curso" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS prerequisitos_curso (
    id                      BIGSERIAL PRIMARY KEY,
    curso_id                BIGINT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    curso_prerequisito_id   BIGINT NOT NULL REFERENCES cursos(id),
    nota_minima             NUMERIC(5,2),
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_prerequisito UNIQUE (curso_id, curso_prerequisito_id),
    CONSTRAINT chk_prerequisito_distinto CHECK (curso_id <> curso_prerequisito_id)
);

-- Se crea la tabla "correquisitos_curso" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS correquisitos_curso (
    id                      BIGSERIAL PRIMARY KEY,
    curso_id                BIGINT NOT NULL REFERENCES cursos(id) ON DELETE CASCADE,
    curso_correquisito_id   BIGINT NOT NULL REFERENCES cursos(id),
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_correquisito UNIQUE (curso_id, curso_correquisito_id),
    CONSTRAINT chk_correquisito_distinto CHECK (curso_id <> curso_correquisito_id)
);

-- =========================================================
-- PERIODOS
-- En esta sección se define el calendario académico y sus ventanas de matrícula y ajuste.
-- =========================================================
-- Se crea la tabla "periodos_academicos" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS periodos_academicos (
    id                          BIGSERIAL PRIMARY KEY,
    codigo                      VARCHAR(50) NOT NULL UNIQUE,
    nombre                      VARCHAR(150) NOT NULL,
    tipo_periodo                tipo_periodo_enum NOT NULL,
    fecha_inicio                DATE NOT NULL,
    fecha_fin                   DATE NOT NULL,
    fecha_inicio_matricula      TIMESTAMP NOT NULL,
    fecha_fin_matricula         TIMESTAMP NOT NULL,
    fecha_inicio_ajuste         TIMESTAMP,
    fecha_fin_ajuste            TIMESTAMP,
    maximo_creditos             NUMERIC(5,2) NOT NULL DEFAULT 24,
    estado                      estado_periodo_enum NOT NULL DEFAULT 'PLANIFICADO',
    creado_en                   TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en              TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_fechas_periodo CHECK (
        fecha_inicio <= fecha_fin
        AND fecha_inicio_matricula <= fecha_fin_matricula
        AND maximo_creditos > 0
    )
);

-- =========================================================
-- AULAS / DOCENTES / SECCIONES / HORARIOS
-- Este bloque modela la oferta académica operativa: aulas, docentes, secciones y horarios.
-- =========================================================
-- Se crea la tabla "aulas" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS aulas (
    id                  BIGSERIAL PRIMARY KEY,
    codigo              VARCHAR(50) NOT NULL UNIQUE,
    edificio            VARCHAR(100),
    sede                VARCHAR(100),
    capacidad           INTEGER NOT NULL,
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_capacidad_aula CHECK (capacidad > 0)
);

-- Se crea la tabla "docentes" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS docentes (
    id                  BIGSERIAL PRIMARY KEY,
    usuario_id          BIGINT REFERENCES usuarios(id),
    codigo_empleado     VARCHAR(50) UNIQUE,
    especialidad        VARCHAR(150),
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Se crea la tabla "secciones" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS secciones (
    id                      BIGSERIAL PRIMARY KEY,
    periodo_academico_id    BIGINT NOT NULL REFERENCES periodos_academicos(id),
    curso_id                BIGINT NOT NULL REFERENCES cursos(id),
    codigo_seccion          VARCHAR(20) NOT NULL,
    docente_id              BIGINT REFERENCES docentes(id),
    aula_id                 BIGINT REFERENCES aulas(id),
    modalidad               modalidad_enum NOT NULL DEFAULT 'PRESENCIAL',
    cupo                    INTEGER NOT NULL,
    cupo_lista_espera       INTEGER NOT NULL DEFAULT 0,
    total_matriculados      INTEGER NOT NULL DEFAULT 0,
    total_lista_espera      INTEGER NOT NULL DEFAULT 0,
    estado                  estado_seccion_enum NOT NULL DEFAULT 'ABIERTA',
    observaciones           TEXT,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_seccion UNIQUE (periodo_academico_id, curso_id, codigo_seccion),
    CONSTRAINT chk_cupo_seccion CHECK (cupo > 0),
    CONSTRAINT chk_cupo_espera CHECK (cupo_lista_espera >= 0),
    CONSTRAINT chk_totales_no_negativos CHECK (total_matriculados >= 0 AND total_lista_espera >= 0)
);

-- Se crea la tabla "horarios_seccion" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS horarios_seccion (
    id                  BIGSERIAL PRIMARY KEY,
    seccion_id          BIGINT NOT NULL REFERENCES secciones(id) ON DELETE CASCADE,
    dia_semana          SMALLINT NOT NULL,
    hora_inicio         TIME NOT NULL,
    hora_fin            TIME NOT NULL,
    aula_id             BIGINT REFERENCES aulas(id),
    creado_en           TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_dia_semana CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT chk_horas_horario CHECK (hora_inicio < hora_fin)
);

-- =========================================================
-- ESTUDIANTES / HISTORIAL / BLOQUEOS
-- Aquí se registra la información del estudiante, su historial académico y posibles bloqueos.
-- =========================================================
-- Se crea la tabla "estudiantes" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS estudiantes (
    id                          BIGSERIAL PRIMARY KEY,
    usuario_id                  BIGINT NOT NULL UNIQUE REFERENCES usuarios(id),
    carnet                      VARCHAR(50) NOT NULL UNIQUE,
    programa_academico_id       BIGINT NOT NULL REFERENCES programas_academicos(id),
    plan_estudio_id             BIGINT REFERENCES planes_estudio(id),
    fecha_ingreso               DATE,
    estado                      estado_estudiante_enum NOT NULL DEFAULT 'ACTIVO',
    promedio_actual             NUMERIC(4,2),
    creditos_aprobados          NUMERIC(6,2) NOT NULL DEFAULT 0,
    creado_en                   TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en              TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_promedio CHECK (promedio_actual IS NULL OR (promedio_actual >= 0 AND promedio_actual <= 100))
);

-- Se crea la tabla "historial_cursos_estudiante" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS historial_cursos_estudiante (
    id                      BIGSERIAL PRIMARY KEY,
    estudiante_id           BIGINT NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    curso_id                BIGINT NOT NULL REFERENCES cursos(id),
    periodo_academico_id    BIGINT REFERENCES periodos_academicos(id),
    seccion_id              BIGINT REFERENCES secciones(id),
    nota_final              NUMERIC(5,2),
    aprobado                BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_historial UNIQUE (estudiante_id, curso_id, periodo_academico_id, seccion_id)
);

-- Se crea la tabla "bloqueos_estudiante" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS bloqueos_estudiante (
    id                      BIGSERIAL PRIMARY KEY,
    estudiante_id           BIGINT NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    tipo_bloqueo            tipo_bloqueo_enum NOT NULL,
    motivo                  TEXT NOT NULL,
    estado                  estado_bloqueo_enum NOT NULL DEFAULT 'ACTIVO',
    fecha_inicio            TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_fin               TIMESTAMP,
    creado_por              BIGINT REFERENCES usuarios(id),
    resuelto_por            BIGINT REFERENCES usuarios(id),
    resuelto_en             TIMESTAMP,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =========================================================
-- BECAS / DESCUENTOS
-- En esta sección se definen becas y la relación de becas asignadas a estudiantes.
-- =========================================================
-- Se crea la tabla "becas" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS becas (
    id                      BIGSERIAL PRIMARY KEY,
    codigo                  VARCHAR(50) NOT NULL UNIQUE,
    nombre                  VARCHAR(150) NOT NULL,
    descripcion             TEXT,
    porcentaje_descuento    NUMERIC(5,2) DEFAULT 0,
    monto_descuento_fijo    NUMERIC(12,2) DEFAULT 0,
    activa                  BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_porcentaje_beca CHECK (porcentaje_descuento >= 0 AND porcentaje_descuento <= 100),
    CONSTRAINT chk_monto_beca CHECK (monto_descuento_fijo >= 0)
);

-- Se crea la tabla "estudiante_beca" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS estudiante_beca (
    id                      BIGSERIAL PRIMARY KEY,
    estudiante_id           BIGINT NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    beca_id                 BIGINT NOT NULL REFERENCES becas(id),
    periodo_academico_id    BIGINT REFERENCES periodos_academicos(id),
    activa                  BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_estudiante_beca UNIQUE (estudiante_id, beca_id, periodo_academico_id)
);

-- =========================================================
-- MATRÍCULA
-- Este bloque modela el proceso de matrícula: cabecera, detalle y lista de espera.
-- =========================================================
-- Se crea la tabla "matriculas" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS matriculas (
    id                      BIGSERIAL PRIMARY KEY,
    numero_matricula        VARCHAR(50) NOT NULL UNIQUE,
    estudiante_id           BIGINT NOT NULL REFERENCES estudiantes(id),
    periodo_academico_id    BIGINT NOT NULL REFERENCES periodos_academicos(id),
    estado                  estado_matricula_enum NOT NULL DEFAULT 'BORRADOR',
    total_creditos          NUMERIC(6,2) NOT NULL DEFAULT 0,
    subtotal                NUMERIC(12,2) NOT NULL DEFAULT 0,
    descuento               NUMERIC(12,2) NOT NULL DEFAULT 0,
    total                   NUMERIC(12,2) NOT NULL DEFAULT 0,
    confirmada_en           TIMESTAMP,
    confirmada_por          BIGINT REFERENCES usuarios(id),
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_matricula_estudiante_periodo UNIQUE (estudiante_id, periodo_academico_id),
    CONSTRAINT chk_montos_matricula CHECK (
        total_creditos >= 0 AND subtotal >= 0 AND descuento >= 0 AND total >= 0
    )
);

-- Se crea la tabla "detalle_matricula" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS detalle_matricula (
    id                      BIGSERIAL PRIMARY KEY,
    matricula_id            BIGINT NOT NULL REFERENCES matriculas(id) ON DELETE CASCADE,
    seccion_id              BIGINT NOT NULL REFERENCES secciones(id),
    estado                  estado_detalle_matricula_enum NOT NULL DEFAULT 'MATRICULADO',
    costo_unitario          NUMERIC(12,2) NOT NULL DEFAULT 0,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_detalle_seccion UNIQUE (matricula_id, seccion_id),
    CONSTRAINT chk_costo_detalle CHECK (costo_unitario >= 0)
);

-- Se crea la tabla "lista_espera" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS lista_espera (
    id                      BIGSERIAL PRIMARY KEY,
    seccion_id              BIGINT NOT NULL REFERENCES secciones(id) ON DELETE CASCADE,
    estudiante_id           BIGINT NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    posicion                INTEGER NOT NULL,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_lista_espera_estudiante UNIQUE (seccion_id, estudiante_id),
    CONSTRAINT uq_lista_espera_posicion UNIQUE (seccion_id, posicion),
    CONSTRAINT chk_posicion_espera CHECK (posicion > 0)
);

-- =========================================================
-- FACTURAS / PAGOS
-- Aquí se modela la parte financiera del proceso: facturas, líneas de factura y pagos.
-- =========================================================
-- Se crea la tabla "facturas" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS facturas (
    id                      BIGSERIAL PRIMARY KEY,
    numero_factura          VARCHAR(50) NOT NULL UNIQUE,
    estudiante_id           BIGINT NOT NULL REFERENCES estudiantes(id),
    matricula_id            BIGINT REFERENCES matriculas(id),
    periodo_academico_id    BIGINT REFERENCES periodos_academicos(id),
    fecha_emision           TIMESTAMP NOT NULL DEFAULT NOW(),
    fecha_vencimiento       TIMESTAMP NOT NULL,
    subtotal                NUMERIC(12,2) NOT NULL DEFAULT 0,
    descuento               NUMERIC(12,2) NOT NULL DEFAULT 0,
    impuesto                NUMERIC(12,2) NOT NULL DEFAULT 0,
    total                   NUMERIC(12,2) NOT NULL DEFAULT 0,
    saldo                   NUMERIC(12,2) NOT NULL DEFAULT 0,
    estado                  estado_factura_enum NOT NULL DEFAULT 'BORRADOR',
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_montos_factura CHECK (
        subtotal >= 0 AND descuento >= 0 AND impuesto >= 0 AND total >= 0 AND saldo >= 0
    )
);

-- Se crea la tabla "lineas_factura" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS lineas_factura (
    id                      BIGSERIAL PRIMARY KEY,
    factura_id              BIGINT NOT NULL REFERENCES facturas(id) ON DELETE CASCADE,
    numero_linea            INTEGER NOT NULL,
    descripcion             VARCHAR(255) NOT NULL,
    cantidad                NUMERIC(10,2) NOT NULL DEFAULT 1,
    precio_unitario         NUMERIC(12,2) NOT NULL DEFAULT 0,
    descuento               NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_linea             NUMERIC(12,2) NOT NULL DEFAULT 0,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_linea_factura UNIQUE (factura_id, numero_linea),
    CONSTRAINT chk_linea_factura CHECK (
        cantidad > 0 AND precio_unitario >= 0 AND descuento >= 0 AND total_linea >= 0
    )
);

-- Se crea la tabla "pagos" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS pagos (
    id                          BIGSERIAL PRIMARY KEY,
    referencia_pago             VARCHAR(100) NOT NULL UNIQUE,
    estudiante_id               BIGINT NOT NULL REFERENCES estudiantes(id),
    factura_id                  BIGINT REFERENCES facturas(id),
    matricula_id                BIGINT REFERENCES matriculas(id),
    metodo_pago                 metodo_pago_enum NOT NULL,
    id_externo_pasarela         VARCHAR(255),
    estado_externo              VARCHAR(100),
    monto                       NUMERIC(12,2) NOT NULL,
    moneda                      VARCHAR(10) NOT NULL DEFAULT 'CRC',
    fecha_pago                  TIMESTAMP NOT NULL DEFAULT NOW(),
    estado                      estado_pago_enum NOT NULL DEFAULT 'PENDIENTE',
    respuesta_pasarela_raw      JSONB,
    creado_en                   TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en              TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_monto_pago CHECK (monto > 0)
);

-- =========================================================
-- NOTIFICACIONES
-- En esta sección se almacenan notificaciones enviadas o pendientes para estudiantes y usuarios.
-- =========================================================
-- Se crea la tabla "notificaciones" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS notificaciones (
    id                      BIGSERIAL PRIMARY KEY,
    estudiante_id           BIGINT REFERENCES estudiantes(id),
    usuario_id              BIGINT REFERENCES usuarios(id),
    canal                   canal_notificacion_enum NOT NULL,
    asunto                  VARCHAR(255) NOT NULL,
    mensaje                 TEXT NOT NULL,
    estado                  estado_notificacion_enum NOT NULL DEFAULT 'PENDIENTE',
    entidad_relacionada     VARCHAR(100),
    id_relacionado          BIGINT,
    enviada_en              TIMESTAMP,
    leida_en                TIMESTAMP,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- =========================================================
-- ÍNDICES
-- Aquí se crean índices para acelerar consultas frecuentes del sistema.
-- =========================================================
-- Se crea el índice "idx_estudiantes_programa" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_estudiantes_programa ON estudiantes(programa_academico_id);
-- Se crea el índice "idx_secciones_periodo_curso" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_secciones_periodo_curso ON secciones(periodo_academico_id, curso_id);
-- Se crea el índice "idx_horarios_seccion" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_horarios_seccion ON horarios_seccion(seccion_id);
-- Se crea el índice "idx_matriculas_estudiante_periodo" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_matriculas_estudiante_periodo ON matriculas(estudiante_id, periodo_academico_id);
-- Se crea el índice "idx_detalle_matricula_seccion" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_detalle_matricula_seccion ON detalle_matricula(seccion_id);
-- Se crea el índice "idx_bloqueos_estudiante_estado" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_bloqueos_estudiante_estado ON bloqueos_estudiante(estudiante_id, estado);
-- Se crea el índice "idx_pagos_factura_estado" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_pagos_factura_estado ON pagos(factura_id, estado);
-- Se crea el índice "idx_facturas_estudiante_estado" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_facturas_estudiante_estado ON facturas(estudiante_id, estado);
-- Se crea el índice "idx_historial_estudiante_curso" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_historial_estudiante_curso ON historial_cursos_estudiante(estudiante_id, curso_id);
-- Se crea el índice "idx_notificaciones_estado" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_notificaciones_estado ON notificaciones(estado);
-- Se crea el índice "idx_auditoria_tabla_registro" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_auditoria_tabla_registro ON bitacora_auditoria(tabla, id_registro);

-- =========================================================
-- FUNCIONES DE NEGOCIO
-- Este bloque contiene reglas de negocio encapsuladas en funciones PL/pgSQL.
-- =========================================================
-- Se crea o actualiza la función "matricula.periodo_matricula_abierto", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.periodo_matricula_abierto(p_periodo_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_abierto BOOLEAN;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT (NOW() BETWEEN fecha_inicio_matricula AND fecha_fin_matricula)
    INTO v_abierto
    FROM periodos_academicos
    WHERE id = p_periodo_id;

    RETURN COALESCE(v_abierto, FALSE);
END;
$$;

-- Se crea o actualiza la función "matricula.estudiante_tiene_bloqueos", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.estudiante_tiene_bloqueos(p_estudiante_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe BOOLEAN;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM bloqueos_estudiante
        WHERE estudiante_id = p_estudiante_id
          AND estado = 'ACTIVO'
          AND (fecha_fin IS NULL OR fecha_fin > NOW())
    )
    INTO v_existe;

    RETURN v_existe;
END;
$$;

-- Se crea o actualiza la función "matricula.estudiante_tiene_morosidad", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.estudiante_tiene_morosidad(p_estudiante_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe BOOLEAN;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM facturas
        WHERE estudiante_id = p_estudiante_id
          AND saldo > 0
          AND estado IN ('EMITIDA', 'PAGADA_PARCIAL', 'VENCIDA')
          AND fecha_vencimiento < NOW()
    )
    INTO v_existe;

    RETURN v_existe;
END;
$$;

-- Se crea o actualiza la función "matricula.estudiante_cumple_prerequisitos", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.estudiante_cumple_prerequisitos(p_estudiante_id BIGINT, p_curso_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_faltantes INTEGER;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT COUNT(*)
    INTO v_faltantes
    FROM prerequisitos_curso pr
    WHERE pr.curso_id = p_curso_id
      AND NOT EXISTS (
          SELECT 1
          FROM historial_cursos_estudiante h
          WHERE h.estudiante_id = p_estudiante_id
            AND h.curso_id = pr.curso_prerequisito_id
            AND h.aprobado = TRUE
            AND (pr.nota_minima IS NULL OR h.nota_final >= pr.nota_minima)
      );

    RETURN v_faltantes = 0;
END;
$$;

-- Se crea o actualiza la función "matricula.creditos_matriculados_periodo", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.creditos_matriculados_periodo(p_estudiante_id BIGINT, p_periodo_id BIGINT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT COALESCE(SUM(c.creditos), 0)
    INTO v_total
    FROM detalle_matricula dm
    JOIN matriculas m ON m.id = dm.matricula_id
    JOIN secciones s ON s.id = dm.seccion_id
    JOIN cursos c ON c.id = s.curso_id
    WHERE m.estudiante_id = p_estudiante_id
      AND m.periodo_academico_id = p_periodo_id
      AND m.estado IN ('BORRADOR', 'PENDIENTE_PAGO', 'CONFIRMADA', 'AJUSTADA')
      AND dm.estado IN ('MATRICULADO', 'LISTA_ESPERA');

    RETURN COALESCE(v_total, 0);
END;
$$;

-- Se crea o actualiza la función "matricula.hay_choque_horario", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.hay_choque_horario(
    p_estudiante_id BIGINT,
    p_periodo_id BIGINT,
    p_seccion_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_existe BOOLEAN;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM horarios_seccion nuevo
        JOIN detalle_matricula dm ON dm.estado IN ('MATRICULADO', 'LISTA_ESPERA')
        JOIN matriculas m ON m.id = dm.matricula_id
        JOIN secciones s_anterior ON s_anterior.id = dm.seccion_id
        JOIN horarios_seccion anterior ON anterior.seccion_id = s_anterior.id
        WHERE nuevo.seccion_id = p_seccion_id
          AND m.estudiante_id = p_estudiante_id
          AND m.periodo_academico_id = p_periodo_id
          AND m.estado IN ('BORRADOR', 'PENDIENTE_PAGO', 'CONFIRMADA', 'AJUSTADA')
          AND s_anterior.id <> p_seccion_id
          AND nuevo.dia_semana = anterior.dia_semana
          AND nuevo.hora_inicio < anterior.hora_fin
          AND nuevo.hora_fin > anterior.hora_inicio
    )
    INTO v_existe;

    RETURN v_existe;
END;
$$;

-- Se crea o actualiza la función "matricula.recalcular_montos_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.recalcular_montos_matricula(p_matricula_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_estudiante_id BIGINT;
    v_periodo_id BIGINT;
    v_subtotal NUMERIC(12,2);
    v_total_creditos NUMERIC(6,2);
    v_descuento NUMERIC(12,2);
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT estudiante_id, periodo_academico_id
    INTO v_estudiante_id, v_periodo_id
    FROM matriculas
    WHERE id = p_matricula_id;

    SELECT COALESCE(SUM(dm.costo_unitario), 0), COALESCE(SUM(c.creditos), 0)
    INTO v_subtotal, v_total_creditos
    FROM detalle_matricula dm
    JOIN secciones s ON s.id = dm.seccion_id
    JOIN cursos c ON c.id = s.curso_id
    WHERE dm.matricula_id = p_matricula_id
      AND dm.estado IN ('MATRICULADO', 'LISTA_ESPERA');

    SELECT COALESCE(SUM(
        CASE
            WHEN b.porcentaje_descuento > 0 THEN (v_subtotal * b.porcentaje_descuento / 100.0)
            ELSE b.monto_descuento_fijo
        END
    ), 0)
    INTO v_descuento
    FROM estudiante_beca eb
    JOIN becas b ON b.id = eb.beca_id
    WHERE eb.estudiante_id = v_estudiante_id
      AND eb.activa = TRUE
      AND (eb.periodo_academico_id IS NULL OR eb.periodo_academico_id = v_periodo_id)
      AND b.activa = TRUE;

    UPDATE matriculas
    SET total_creditos = v_total_creditos,
        subtotal = v_subtotal,
        descuento = LEAST(v_descuento, v_subtotal),
        total = v_subtotal - LEAST(v_descuento, v_subtotal)
    WHERE id = p_matricula_id;
END;
$$;

-- Se crea o actualiza la función "matricula.recalcular_saldo_factura", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.recalcular_saldo_factura(p_factura_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
    v_pagado NUMERIC(12,2);
    v_saldo NUMERIC(12,2);
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT total INTO v_total
    FROM facturas
    WHERE id = p_factura_id;

    SELECT COALESCE(SUM(monto), 0)
    INTO v_pagado
    FROM pagos
    WHERE factura_id = p_factura_id
      AND estado = 'APROBADO';

    v_saldo := GREATEST(v_total - v_pagado, 0);

    UPDATE facturas
    SET saldo = v_saldo,
        estado = CASE
                    WHEN v_saldo = 0 THEN 'PAGADA'::estado_factura_enum
                    WHEN v_pagado > 0 THEN 'PAGADA_PARCIAL'::estado_factura_enum
                    ELSE estado
                 END
    WHERE id = p_factura_id;
END;
$$;

-- =========================================================
-- VALIDACIÓN DE DETALLE DE MATRÍCULA
-- Esta función valida si un estudiante puede agregar una sección a su matrícula.
-- =========================================================
-- Se crea o actualiza la función "matricula.validar_detalle_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.validar_detalle_matricula()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_estudiante_id BIGINT;
    v_periodo_id BIGINT;
    v_curso_id BIGINT;
    v_cupo INTEGER;
    v_total_matriculados INTEGER;
    v_cupo_espera INTEGER;
    v_total_espera INTEGER;
    v_max_creditos NUMERIC(5,2);
    v_creditos_actuales NUMERIC(6,2);
    v_creditos_curso NUMERIC(5,2);
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT estudiante_id, periodo_academico_id
    INTO v_estudiante_id, v_periodo_id
    FROM matriculas
    WHERE id = NEW.matricula_id;

    IF NOT matricula.periodo_matricula_abierto(v_periodo_id) THEN
        RAISE EXCEPTION 'El periodo no está habilitado para matrícula';
    END IF;

    IF matricula.estudiante_tiene_bloqueos(v_estudiante_id) THEN
        RAISE EXCEPTION 'El estudiante tiene bloqueos activos';
    END IF;

    IF matricula.estudiante_tiene_morosidad(v_estudiante_id) THEN
        RAISE EXCEPTION 'El estudiante tiene morosidad activa';
    END IF;

    SELECT curso_id, cupo, total_matriculados, cupo_lista_espera, total_lista_espera
    INTO v_curso_id, v_cupo, v_total_matriculados, v_cupo_espera, v_total_espera
    FROM secciones
    WHERE id = NEW.seccion_id;

    IF matricula.hay_choque_horario(v_estudiante_id, v_periodo_id, NEW.seccion_id) THEN
        RAISE EXCEPTION 'Existe choque de horario';
    END IF;

    IF NOT matricula.estudiante_cumple_prerequisitos(v_estudiante_id, v_curso_id) THEN
        RAISE EXCEPTION 'El estudiante no cumple prerrequisitos';
    END IF;

    SELECT maximo_creditos INTO v_max_creditos
    FROM periodos_academicos
    WHERE id = v_periodo_id;

    SELECT creditos INTO v_creditos_curso
    FROM cursos
    WHERE id = v_curso_id;

    v_creditos_actuales := matricula.creditos_matriculados_periodo(v_estudiante_id, v_periodo_id);

    IF (v_creditos_actuales + v_creditos_curso) > v_max_creditos THEN
        RAISE EXCEPTION 'Se excede el máximo de créditos del periodo';
    END IF;

    IF v_total_matriculados < v_cupo THEN
        NEW.estado := 'MATRICULADO';
    ELSE
        IF v_total_espera < v_cupo_espera THEN
            NEW.estado := 'LISTA_ESPERA';
        ELSE
            RAISE EXCEPTION 'No hay cupo disponible ni espacio en lista de espera';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Se crea el trigger "trg_validar_detalle_matricula" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_validar_detalle_matricula
BEFORE INSERT ON detalle_matricula
FOR EACH ROW
EXECUTE FUNCTION matricula.validar_detalle_matricula();

-- =========================================================
-- POSTPROCESO DETALLE DE MATRÍCULA
-- Aquí se actualizan totales y listas de espera después de insertar, modificar o eliminar detalles de matrícula.
-- =========================================================
-- Se crea o actualiza la función "matricula.post_detalle_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.post_detalle_matricula()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_seccion_id BIGINT;
    v_matricula_id BIGINT;
    v_estudiante_id BIGINT;
    v_posicion INTEGER;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    v_seccion_id := COALESCE(NEW.seccion_id, OLD.seccion_id);
    v_matricula_id := COALESCE(NEW.matricula_id, OLD.matricula_id);

    UPDATE secciones s
    SET total_matriculados = (
            SELECT COUNT(*) FROM detalle_matricula dm
            WHERE dm.seccion_id = s.id AND dm.estado = 'MATRICULADO'
        ),
        total_lista_espera = (
            SELECT COUNT(*) FROM detalle_matricula dm
            WHERE dm.seccion_id = s.id AND dm.estado = 'LISTA_ESPERA'
        )
    WHERE s.id = v_seccion_id;

    IF TG_OP = 'INSERT' AND NEW.estado = 'LISTA_ESPERA' THEN
        SELECT estudiante_id INTO v_estudiante_id
        FROM matriculas
        WHERE id = NEW.matricula_id;

        SELECT COALESCE(MAX(posicion), 0) + 1
        INTO v_posicion
        FROM lista_espera
        WHERE seccion_id = NEW.seccion_id;

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
        INSERT INTO lista_espera(seccion_id, estudiante_id, posicion)
        VALUES (NEW.seccion_id, v_estudiante_id, v_posicion)
        ON CONFLICT DO NOTHING;
    END IF;

    PERFORM matricula.recalcular_montos_matricula(v_matricula_id);

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Se crea el trigger "trg_post_detalle_matricula" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_post_detalle_matricula
AFTER INSERT OR UPDATE OR DELETE ON detalle_matricula
FOR EACH ROW
EXECUTE FUNCTION matricula.post_detalle_matricula();

-- =========================================================
-- POSTPROCESO PAGOS
-- Este bloque recalcula saldos de factura automáticamente cuando cambia un pago.
-- =========================================================
-- Se crea o actualiza la función "matricula.post_pago", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.post_pago()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    IF COALESCE(NEW.factura_id, OLD.factura_id) IS NOT NULL THEN
        PERFORM matricula.recalcular_saldo_factura(COALESCE(NEW.factura_id, OLD.factura_id));
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Se crea el trigger "trg_post_pago" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_post_pago
AFTER INSERT OR UPDATE OR DELETE ON pagos
FOR EACH ROW
EXECUTE FUNCTION matricula.post_pago();

-- =========================================================
-- CONFIRMAR MATRÍCULA SOLO CON PAGO EXITOSO
-- Aquí se valida que la matrícula solo pueda confirmarse si el pago aprobado cubre el total.
-- =========================================================
-- Se crea o actualiza la función "matricula.confirmar_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.confirmar_matricula(p_matricula_id BIGINT, p_usuario_id BIGINT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
    v_pagado NUMERIC(12,2);
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT total INTO v_total
    FROM matriculas
    WHERE id = p_matricula_id;

    SELECT COALESCE(SUM(monto), 0)
    INTO v_pagado
    FROM pagos
    WHERE matricula_id = p_matricula_id
      AND estado = 'APROBADO';

    IF v_pagado < v_total THEN
        RAISE EXCEPTION 'No se puede confirmar la matrícula: pago insuficiente';
    END IF;

    UPDATE matriculas
    SET estado = 'CONFIRMADA',
        confirmada_en = NOW(),
        confirmada_por = p_usuario_id
    WHERE id = p_matricula_id;
END;
$$;

-- =========================================================
-- GENERAR FACTURA
-- Esta función crea una factura a partir de una matrícula.
-- =========================================================
-- Se crea o actualiza la función "matricula.generar_factura_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.generar_factura_matricula(
    p_matricula_id BIGINT,
    p_fecha_vencimiento TIMESTAMP
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_factura_id BIGINT;
    v_estudiante_id BIGINT;
    v_periodo_id BIGINT;
    v_subtotal NUMERIC(12,2);
    v_descuento NUMERIC(12,2);
    v_total NUMERIC(12,2);
    v_numero_factura VARCHAR(50);
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT estudiante_id, periodo_academico_id, subtotal, descuento, total
    INTO v_estudiante_id, v_periodo_id, v_subtotal, v_descuento, v_total
    FROM matriculas
    WHERE id = p_matricula_id;

    v_numero_factura := 'FAC-' || to_char(NOW(), 'YYYYMMDDHH24MISS') || '-' || p_matricula_id;

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
    INSERT INTO facturas (
        numero_factura,
        estudiante_id,
        matricula_id,
        periodo_academico_id,
        fecha_vencimiento,
        subtotal,
        descuento,
        impuesto,
        total,
        saldo,
        estado
    )
    VALUES (
        v_numero_factura,
        v_estudiante_id,
        p_matricula_id,
        v_periodo_id,
        p_fecha_vencimiento,
        v_subtotal,
        v_descuento,
        0,
        v_total,
        v_total,
        'EMITIDA'
    )
    RETURNING id INTO v_factura_id;

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
    INSERT INTO lineas_factura (
        factura_id,
        numero_linea,
        descripcion,
        cantidad,
        precio_unitario,
        descuento,
        total_linea
    )
    VALUES (
        v_factura_id,
        1,
        'Cobro de matrícula académica',
        1,
        v_subtotal,
        v_descuento,
        v_total
    );

    RETURN v_factura_id;
END;
$$;

-- =========================================================
-- REPORTES / VISTAS
-- En esta sección se crean vistas para facilitar consultas y reportes.
-- =========================================================
-- Se crea o actualiza la vista "vista_oferta_academica" para facilitar consultas y reportes sin duplicar datos.
-- Define una vista para facilitar consultas y reportes.
CREATE OR REPLACE VIEW vista_oferta_academica AS
SELECT
    s.id AS seccion_id,
    p.codigo AS codigo_periodo,
    p.nombre AS nombre_periodo,
    c.codigo AS codigo_curso,
    c.nombre AS nombre_curso,
    c.creditos,
    s.codigo_seccion,
    s.modalidad,
    s.cupo,
    s.total_matriculados,
    (s.cupo - s.total_matriculados) AS cupos_disponibles,
    s.cupo_lista_espera,
    s.total_lista_espera,
    s.estado
FROM secciones s
JOIN periodos_academicos p ON p.id = s.periodo_academico_id
JOIN cursos c ON c.id = s.curso_id;

-- Se crea o actualiza la vista "vista_reporte_matricula" para facilitar consultas y reportes sin duplicar datos.
-- Define una vista para facilitar consultas y reportes.
CREATE OR REPLACE VIEW vista_reporte_matricula AS
SELECT
    m.id AS matricula_id,
    m.numero_matricula,
    e.carnet,
    u.nombres,
    u.apellidos,
    p.codigo AS codigo_periodo,
    p.nombre AS nombre_periodo,
    m.estado,
    m.total_creditos,
    m.total,
    m.confirmada_en,
    m.creado_en
FROM matriculas m
JOIN estudiantes e ON e.id = m.estudiante_id
JOIN usuarios u ON u.id = e.usuario_id
JOIN periodos_academicos p ON p.id = m.periodo_academico_id;

-- Se crea o actualiza la vista "vista_reporte_financiero" para facilitar consultas y reportes sin duplicar datos.
-- Define una vista para facilitar consultas y reportes.
CREATE OR REPLACE VIEW vista_reporte_financiero AS
SELECT
    f.id AS factura_id,
    f.numero_factura,
    e.carnet,
    u.nombres,
    u.apellidos,
    f.fecha_emision,
    f.fecha_vencimiento,
    f.total,
    f.saldo,
    f.estado,
    COALESCE((
        SELECT SUM(pg.monto)
        FROM pagos pg
        WHERE pg.factura_id = f.id
          AND pg.estado = 'APROBADO'
    ), 0) AS monto_pagado
FROM facturas f
JOIN estudiantes e ON e.id = f.estudiante_id
JOIN usuarios u ON u.id = e.usuario_id;

-- =========================================================
-- TRIGGERS updated_at / actualizado_en
-- Aquí se crean triggers para actualizar automáticamente la columna actualizado_en.
-- =========================================================
-- Bloque anónimo para ejecutar lógica condicional en PostgreSQL.
DO $$
DECLARE
    t RECORD;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    FOR t IN
        SELECT unnest(ARRAY[
            'roles','permisos','usuarios','programas_academicos','planes_estudio',
            'cursos','plan_estudio_curso','periodos_academicos','aulas','docentes',
            'secciones','horarios_seccion','estudiantes','bloqueos_estudiante',
            'becas','estudiante_beca','matriculas','detalle_matricula',
            'facturas','pagos','notificaciones'
        ]) AS tabla
    LOOP
        EXECUTE format('
-- Se elimina el trigger "trg_actualizado_" si ya existe, para permitir recrearlo sin errores.
            DROP TRIGGER IF EXISTS trg_actualizado_%I ON %I;
-- Se crea el trigger "trg_actualizado_" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
            CREATE TRIGGER trg_actualizado_%I
            BEFORE UPDATE ON %I
            FOR EACH ROW
            EXECUTE FUNCTION matricula.actualizar_fecha_modificacion();
        ', t.tabla, t.tabla, t.tabla, t.tabla);
    END LOOP;
END$$;

-- =========================================================
-- TRIGGERS DE AUDITORÍA
-- Aquí se asignan triggers de auditoría a múltiples tablas del sistema.
-- =========================================================
-- Bloque anónimo para ejecutar lógica condicional en PostgreSQL.
DO $$
DECLARE
    t RECORD;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    FOR t IN
        SELECT unnest(ARRAY[
            'usuarios','usuario_rol','programas_academicos','planes_estudio','cursos',
            'prerequisitos_curso','correquisitos_curso','periodos_academicos',
            'aulas','docentes','secciones','horarios_seccion','estudiantes',
            'historial_cursos_estudiante','bloqueos_estudiante','becas','estudiante_beca',
            'matriculas','detalle_matricula','lista_espera','facturas','lineas_factura',
            'pagos','notificaciones'
        ]) AS tabla
    LOOP
        EXECUTE format('
-- Se elimina el trigger "trg_auditoria_" si ya existe, para permitir recrearlo sin errores.
            DROP TRIGGER IF EXISTS trg_auditoria_%I ON %I;
-- Se crea el trigger "trg_auditoria_" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
            CREATE TRIGGER trg_auditoria_%I
            AFTER INSERT OR UPDATE OR DELETE ON %I
            FOR EACH ROW
            EXECUTE FUNCTION matricula.auditar_cambios();
        ', t.tabla, t.tabla, t.tabla, t.tabla);
    END LOOP;
END$$;

-- =========================================================
-- DATOS BASE
-- En esta sección se insertan datos iniciales como roles y permisos.
-- =========================================================
-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
INSERT INTO roles (codigo, nombre, descripcion) VALUES
('ESTUDIANTE', 'Estudiante', 'Rol de estudiante'),
('REGISTRO_ACADEMICO', 'Registro Académico', 'Gestión académica y matrícula'),
('TESORERIA', 'Tesorería', 'Pagos y facturación'),
('DOCENTE', 'Docente', 'Rol docente'),
('ADMIN_TI', 'Administrador TI', 'Administración técnica'),
('AUDITOR', 'Auditor Institucional', 'Consulta de bitácoras')
ON CONFLICT (codigo) DO NOTHING;

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
INSERT INTO permisos (codigo, nombre, descripcion) VALUES
('VER_OFERTA', 'Ver oferta académica', 'Consulta de oferta'),
('GESTIONAR_PROGRAMAS', 'Gestionar programas', 'ABM de programas'),
('GESTIONAR_CURSOS', 'Gestionar cursos', 'ABM de cursos'),
('GESTIONAR_PERIODOS', 'Gestionar periodos', 'ABM de periodos'),
('GESTIONAR_SECCIONES', 'Gestionar secciones', 'ABM de secciones'),
('MATRICULARSE', 'Realizar matrícula', 'Proceso de matrícula'),
('AJUSTAR_MATRICULA', 'Ajustar matrícula', 'Cambios autorizados'),
('GENERAR_FACTURAS', 'Generar facturas', 'Estados de cuenta'),
('REGISTRAR_PAGOS', 'Registrar pagos', 'Pagos'),
('VER_REPORTES', 'Ver reportes', 'Reportes'),
('VER_AUDITORIA', 'Ver auditoría', 'Bitácora')
ON CONFLICT (codigo) DO NOTHING;


-- =========================================================
-- MEJORAS COMPLEMENTARIAS PARA CIERRE FUNCIONAL DE BD
-- Este bloque agrega mejoras funcionales para completar reglas de negocio y flujo financiero.
-- 1) VALIDACIÓN DE CORREQUISITOS
-- 2) CONTROL FORMAL DE AJUSTES DE MATRÍCULA
-- 3) PROMOCIÓN AUTOMÁTICA DESDE LISTA DE ESPERA
-- 4) RESTRICCIONES ADICIONALES DE DUPLICIDAD Y TRANSICIONES
-- 5) CICLO FINANCIERO/COMPROBANTES
-- =========================================================

-- =========================================================
-- AJUSTES Y CORREQUISITOS
-- Aquí se agregan funciones para validar ajustes de matrícula y cumplimiento de correquisitos.
-- =========================================================
-- Se crea o actualiza la función "matricula.periodo_ajuste_abierto", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.periodo_ajuste_abierto(p_periodo_id BIGINT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_abierto BOOLEAN;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT (
        fecha_inicio_ajuste IS NOT NULL
        AND fecha_fin_ajuste IS NOT NULL
        AND NOW() BETWEEN fecha_inicio_ajuste AND fecha_fin_ajuste
    )
    INTO v_abierto
    FROM periodos_academicos
    WHERE id = p_periodo_id;

    RETURN COALESCE(v_abierto, FALSE);
END;
$$;

-- Se crea o actualiza la función "matricula.estudiante_cumple_correquisitos", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.estudiante_cumple_correquisitos(
    p_estudiante_id BIGINT,
    p_periodo_id BIGINT,
    p_curso_id BIGINT,
    p_detalle_id_excluir BIGINT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_faltantes INTEGER;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT COUNT(*)
    INTO v_faltantes
    FROM correquisitos_curso cr
    WHERE cr.curso_id = p_curso_id
      AND NOT EXISTS (
          SELECT 1
          FROM historial_cursos_estudiante h
          WHERE h.estudiante_id = p_estudiante_id
            AND h.curso_id = cr.curso_correquisito_id
            AND h.aprobado = TRUE
      )
      AND NOT EXISTS (
          SELECT 1
          FROM detalle_matricula dm
          JOIN matriculas m ON m.id = dm.matricula_id
          JOIN secciones s ON s.id = dm.seccion_id
          WHERE m.estudiante_id = p_estudiante_id
            AND m.periodo_academico_id = p_periodo_id
            AND m.estado IN ('BORRADOR', 'PENDIENTE_PAGO', 'CONFIRMADA', 'AJUSTADA')
            AND dm.estado IN ('MATRICULADO', 'LISTA_ESPERA')
            AND s.curso_id = cr.curso_correquisito_id
            AND (p_detalle_id_excluir IS NULL OR dm.id <> p_detalle_id_excluir)
      );

    RETURN v_faltantes = 0;
END;
$$;

-- =========================================================
-- RESTRICCIONES DE INTEGRIDAD ADICIONALES
-- En esta sección se refuerza la consistencia del modelo con nuevas restricciones y validaciones.
-- =========================================================
-- Se modifica la tabla "periodos_academicos" para agregar, quitar o reforzar reglas de integridad.
ALTER TABLE periodos_academicos
DROP CONSTRAINT IF EXISTS chk_fechas_ajuste_periodo;

-- Se modifica la tabla "periodos_academicos" para agregar, quitar o reforzar reglas de integridad.
ALTER TABLE periodos_academicos
ADD CONSTRAINT chk_fechas_ajuste_periodo CHECK (
    (
        fecha_inicio_ajuste IS NULL
        AND fecha_fin_ajuste IS NULL
    )
    OR (
        fecha_inicio_ajuste IS NOT NULL
        AND fecha_fin_ajuste IS NOT NULL
        AND fecha_inicio_ajuste <= fecha_fin_ajuste
    )
);

-- Se modifica la tabla "secciones" para agregar, quitar o reforzar reglas de integridad.
ALTER TABLE secciones
DROP CONSTRAINT IF EXISTS chk_totales_dentro_de_cupo;

-- Se modifica la tabla "secciones" para agregar, quitar o reforzar reglas de integridad.
ALTER TABLE secciones
ADD CONSTRAINT chk_totales_dentro_de_cupo CHECK (
    total_matriculados <= cupo
    AND total_lista_espera <= cupo_lista_espera
);

-- Se crea o actualiza la función "matricula.validar_estudiante_plan_programa", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.validar_estudiante_plan_programa()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_programa_plan BIGINT;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    IF NEW.plan_estudio_id IS NOT NULL THEN
        SELECT programa_academico_id
        INTO v_programa_plan
        FROM planes_estudio
        WHERE id = NEW.plan_estudio_id;

        IF v_programa_plan IS NULL THEN
            RAISE EXCEPTION 'El plan de estudio indicado no existe';
        END IF;

        IF v_programa_plan <> NEW.programa_academico_id THEN
            RAISE EXCEPTION 'El plan de estudio no pertenece al programa académico del estudiante';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Se elimina el trigger "trg_validar_estudiante_plan_programa" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_validar_estudiante_plan_programa ON estudiantes;
-- Se crea el trigger "trg_validar_estudiante_plan_programa" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_validar_estudiante_plan_programa
BEFORE INSERT OR UPDATE OF programa_academico_id, plan_estudio_id
ON estudiantes
FOR EACH ROW
EXECUTE FUNCTION matricula.validar_estudiante_plan_programa();

-- Se crea o actualiza la función "matricula.validar_pago_documentos", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.validar_pago_documentos()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_factura estado_factura_enum;
    v_estado_matricula estado_matricula_enum;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    IF NEW.factura_id IS NOT NULL THEN
        SELECT estado
        INTO v_estado_factura
        FROM facturas
        WHERE id = NEW.factura_id;

        IF v_estado_factura IS NULL THEN
            RAISE EXCEPTION 'La factura asociada no existe';
        END IF;

        IF v_estado_factura = 'CANCELADA' THEN
            RAISE EXCEPTION 'No se pueden registrar pagos sobre facturas canceladas';
        END IF;
    END IF;

    IF NEW.matricula_id IS NOT NULL THEN
        SELECT estado
        INTO v_estado_matricula
        FROM matriculas
        WHERE id = NEW.matricula_id;

        IF v_estado_matricula IS NULL THEN
            RAISE EXCEPTION 'La matrícula asociada no existe';
        END IF;

        IF v_estado_matricula = 'CANCELADA' THEN
            RAISE EXCEPTION 'No se pueden registrar pagos sobre matrículas canceladas';
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.estado IN ('REVERSADO', 'REEMBOLSADO') AND NEW.estado <> OLD.estado THEN
        RAISE EXCEPTION 'Un pago en estado % no puede transicionar a %', OLD.estado, NEW.estado;
    END IF;

    RETURN NEW;
END;
$$;

-- Se elimina el trigger "trg_validar_pago_documentos" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_validar_pago_documentos ON pagos;
-- Se crea el trigger "trg_validar_pago_documentos" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_validar_pago_documentos
BEFORE INSERT OR UPDATE ON pagos
FOR EACH ROW
EXECUTE FUNCTION matricula.validar_pago_documentos();

-- =========================================================
-- COMPROBANTES Y RECIBOS
-- Este bloque crea estructuras para comprobantes de matrícula y recibos de pago.
-- =========================================================
-- Se crea la tabla "comprobantes_matricula" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS comprobantes_matricula (
    id                      BIGSERIAL PRIMARY KEY,
    matricula_id            BIGINT NOT NULL UNIQUE REFERENCES matriculas(id) ON DELETE CASCADE,
    factura_id              BIGINT REFERENCES facturas(id),
    pago_id                 BIGINT REFERENCES pagos(id),
    numero_comprobante      VARCHAR(80) NOT NULL UNIQUE,
    fecha_emision           TIMESTAMP NOT NULL DEFAULT NOW(),
    observacion             TEXT,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Se crea la tabla "recibos_pago" para almacenar información del módulo correspondiente.
-- Crea una tabla del sistema con sus respectivas columnas y restricciones.
CREATE TABLE IF NOT EXISTS recibos_pago (
    id                      BIGSERIAL PRIMARY KEY,
    pago_id                 BIGINT NOT NULL UNIQUE REFERENCES pagos(id) ON DELETE CASCADE,
    factura_id              BIGINT REFERENCES facturas(id),
    estudiante_id           BIGINT NOT NULL REFERENCES estudiantes(id),
    numero_recibo           VARCHAR(80) NOT NULL UNIQUE,
    fecha_emision           TIMESTAMP NOT NULL DEFAULT NOW(),
    monto                   NUMERIC(12,2) NOT NULL,
    moneda                  VARCHAR(10) NOT NULL DEFAULT 'CRC',
    detalle                 TEXT,
    creado_en               TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en          TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_recibo_monto CHECK (monto > 0)
);

-- Se elimina el trigger "trg_actualizado_comprobantes_matricula" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_actualizado_comprobantes_matricula ON comprobantes_matricula;
-- Se crea el trigger "trg_actualizado_comprobantes_matricula" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_actualizado_comprobantes_matricula
BEFORE UPDATE ON comprobantes_matricula
FOR EACH ROW
EXECUTE FUNCTION matricula.actualizar_fecha_modificacion();

-- Se elimina el trigger "trg_actualizado_recibos_pago" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_actualizado_recibos_pago ON recibos_pago;
-- Se crea el trigger "trg_actualizado_recibos_pago" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_actualizado_recibos_pago
BEFORE UPDATE ON recibos_pago
FOR EACH ROW
EXECUTE FUNCTION matricula.actualizar_fecha_modificacion();

-- Se elimina el trigger "trg_auditoria_comprobantes_matricula" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_auditoria_comprobantes_matricula ON comprobantes_matricula;
-- Se crea el trigger "trg_auditoria_comprobantes_matricula" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_auditoria_comprobantes_matricula
AFTER INSERT OR UPDATE OR DELETE ON comprobantes_matricula
FOR EACH ROW
EXECUTE FUNCTION matricula.auditar_cambios();

-- Se elimina el trigger "trg_auditoria_recibos_pago" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_auditoria_recibos_pago ON recibos_pago;
-- Se crea el trigger "trg_auditoria_recibos_pago" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_auditoria_recibos_pago
AFTER INSERT OR UPDATE OR DELETE ON recibos_pago
FOR EACH ROW
EXECUTE FUNCTION matricula.auditar_cambios();

-- Se crea o actualiza la función "matricula.generar_recibo_pago", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.generar_recibo_pago(p_pago_id BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_recibo_id BIGINT;
    v_factura_id BIGINT;
    v_estudiante_id BIGINT;
    v_monto NUMERIC(12,2);
    v_moneda VARCHAR(10);
    v_numero_recibo VARCHAR(80);
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT factura_id, estudiante_id, monto, moneda
    INTO v_factura_id, v_estudiante_id, v_monto, v_moneda
    FROM pagos
    WHERE id = p_pago_id;

    IF v_estudiante_id IS NULL THEN
        RAISE EXCEPTION 'No existe el pago % para generar recibo', p_pago_id;
    END IF;

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
    INSERT INTO recibos_pago (
        pago_id,
        factura_id,
        estudiante_id,
        numero_recibo,
        monto,
        moneda,
        detalle
    )
    VALUES (
        p_pago_id,
        v_factura_id,
        v_estudiante_id,
        'REC-' || to_char(NOW(), 'YYYYMMDDHH24MISSMS') || '-' || p_pago_id,
        v_monto,
        COALESCE(v_moneda, 'CRC'),
        'Recibo generado automáticamente por pago aprobado'
    )
    ON CONFLICT (pago_id) DO UPDATE
    SET factura_id = EXCLUDED.factura_id,
        estudiante_id = EXCLUDED.estudiante_id,
        monto = EXCLUDED.monto,
        moneda = EXCLUDED.moneda,
        detalle = EXCLUDED.detalle,
        actualizado_en = NOW()
    RETURNING id INTO v_recibo_id;

    RETURN v_recibo_id;
END;
$$;

-- Se crea o actualiza la función "matricula.generar_comprobante_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.generar_comprobante_matricula(p_matricula_id BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_comprobante_id BIGINT;
    v_factura_id BIGINT;
    v_pago_id BIGINT;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT f.id
    INTO v_factura_id
    FROM facturas f
    WHERE f.matricula_id = p_matricula_id
    ORDER BY f.id DESC
    LIMIT 1;

    SELECT p.id
    INTO v_pago_id
    FROM pagos p
    WHERE p.matricula_id = p_matricula_id
      AND p.estado = 'APROBADO'
    ORDER BY p.fecha_pago DESC, p.id DESC
    LIMIT 1;

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
    INSERT INTO comprobantes_matricula (
        matricula_id,
        factura_id,
        pago_id,
        numero_comprobante,
        observacion
    )
    VALUES (
        p_matricula_id,
        v_factura_id,
        v_pago_id,
        'COMP-' || to_char(NOW(), 'YYYYMMDDHH24MISSMS') || '-' || p_matricula_id,
        'Comprobante de matrícula generado automáticamente'
    )
    ON CONFLICT (matricula_id) DO UPDATE
    SET factura_id = EXCLUDED.factura_id,
        pago_id = EXCLUDED.pago_id,
        observacion = EXCLUDED.observacion,
        actualizado_en = NOW()
    RETURNING id INTO v_comprobante_id;

    RETURN v_comprobante_id;
END;
$$;

-- =========================================================
-- FACTURAS VENCIDAS Y SALDOS
-- Aquí se automatiza la actualización del estado de facturas vencidas y el recálculo de saldos.
-- =========================================================
-- Se crea o actualiza la función "matricula.actualizar_facturas_vencidas", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.actualizar_facturas_vencidas()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INTEGER;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    UPDATE facturas
    SET estado = 'VENCIDA',
        actualizado_en = NOW()
    WHERE saldo > 0
      AND estado IN ('EMITIDA', 'PAGADA_PARCIAL')
      AND fecha_vencimiento < NOW();

    GET DIAGNOSTICS v_total = ROW_COUNT;
    RETURN v_total;
END;
$$;

-- Se crea o actualiza la función "matricula.recalcular_saldo_factura", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.recalcular_saldo_factura(p_factura_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
    v_pagado NUMERIC(12,2);
    v_saldo NUMERIC(12,2);
    v_fecha_vencimiento TIMESTAMP;
    v_estado_actual estado_factura_enum;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT total, fecha_vencimiento, estado
    INTO v_total, v_fecha_vencimiento, v_estado_actual
    FROM facturas
    WHERE id = p_factura_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT COALESCE(SUM(monto), 0)
    INTO v_pagado
    FROM pagos
    WHERE factura_id = p_factura_id
      AND estado = 'APROBADO';

    v_saldo := GREATEST(v_total - v_pagado, 0);

    UPDATE facturas
    SET saldo = v_saldo,
        estado = CASE
                    WHEN v_estado_actual = 'CANCELADA' THEN 'CANCELADA'::estado_factura_enum
                    WHEN v_saldo = 0 THEN 'PAGADA'::estado_factura_enum
                    WHEN v_pagado > 0 THEN
                        CASE
                            WHEN v_fecha_vencimiento < NOW() THEN 'VENCIDA'::estado_factura_enum
                            ELSE 'PAGADA_PARCIAL'::estado_factura_enum
                        END
                    WHEN v_fecha_vencimiento < NOW() THEN 'VENCIDA'::estado_factura_enum
                    ELSE 'EMITIDA'::estado_factura_enum
                 END
    WHERE id = p_factura_id;
END;
$$;

-- =========================================================
-- VALIDACIÓN DE DETALLE DE MATRÍCULA (REEMPLAZO AMPLIADO)
-- Esta es una versión ampliada de la validación del detalle de matrícula con controles adicionales.
-- =========================================================
-- Se crea o actualiza la función "matricula.validar_detalle_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.validar_detalle_matricula()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_matricula_id BIGINT;
    v_estudiante_id BIGINT;
    v_periodo_id BIGINT;
    v_estado_matricula estado_matricula_enum;
    v_curso_id BIGINT;
    v_estado_seccion estado_seccion_enum;
    v_cupo INTEGER;
    v_total_matriculados INTEGER;
    v_cupo_espera INTEGER;
    v_total_espera INTEGER;
    v_max_creditos NUMERIC(5,2);
    v_creditos_actuales NUMERIC(6,2);
    v_creditos_curso NUMERIC(5,2);
    v_detalle_id_excluir BIGINT;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    v_matricula_id := COALESCE(NEW.matricula_id, OLD.matricula_id);

    SELECT estudiante_id, periodo_academico_id, estado
    INTO v_estudiante_id, v_periodo_id, v_estado_matricula
    FROM matriculas
    WHERE id = v_matricula_id;

    IF v_estado_matricula IS NULL THEN
        RAISE EXCEPTION 'La matrícula asociada no existe';
    END IF;

    IF TG_OP = 'DELETE' THEN
        IF v_estado_matricula = 'CANCELADA' THEN
            RAISE EXCEPTION 'No se puede eliminar detalle de una matrícula cancelada';
        END IF;

        IF v_estado_matricula = 'CONFIRMADA' AND NOT matricula.periodo_ajuste_abierto(v_periodo_id) THEN
            RAISE EXCEPTION 'Solo se puede eliminar detalle de matrícula confirmada durante el periodo de ajuste';
        END IF;

        RETURN OLD;
    END IF;

    IF v_estado_matricula = 'CANCELADA' THEN
        RAISE EXCEPTION 'No se pueden agregar o modificar detalles en una matrícula cancelada';
    END IF;

    IF v_estado_matricula IN ('BORRADOR', 'PENDIENTE_PAGO') THEN
        IF NOT matricula.periodo_matricula_abierto(v_periodo_id) THEN
            RAISE EXCEPTION 'El periodo no está habilitado para matrícula';
        END IF;
    ELSIF v_estado_matricula IN ('CONFIRMADA', 'AJUSTADA') THEN
        IF NOT matricula.periodo_ajuste_abierto(v_periodo_id) THEN
            RAISE EXCEPTION 'La modificación solo está permitida durante el periodo de ajuste';
        END IF;
    END IF;

    IF matricula.estudiante_tiene_bloqueos(v_estudiante_id) THEN
        RAISE EXCEPTION 'El estudiante tiene bloqueos activos';
    END IF;

    IF matricula.estudiante_tiene_morosidad(v_estudiante_id) THEN
        RAISE EXCEPTION 'El estudiante tiene morosidad activa';
    END IF;

    SELECT curso_id, estado, cupo, total_matriculados, cupo_lista_espera, total_lista_espera
    INTO v_curso_id, v_estado_seccion, v_cupo, v_total_matriculados, v_cupo_espera, v_total_espera
    FROM secciones
    WHERE id = NEW.seccion_id;

    IF v_curso_id IS NULL THEN
        RAISE EXCEPTION 'La sección indicada no existe';
    END IF;

    IF v_estado_seccion <> 'ABIERTA' THEN
        RAISE EXCEPTION 'Solo se permite matrícula en secciones abiertas';
    END IF;

    v_detalle_id_excluir := CASE WHEN TG_OP = 'UPDATE' THEN OLD.id ELSE NULL END;

    IF EXISTS (
        SELECT 1
        FROM detalle_matricula dm
        JOIN matriculas m ON m.id = dm.matricula_id
        JOIN secciones s ON s.id = dm.seccion_id
        WHERE m.estudiante_id = v_estudiante_id
          AND m.periodo_academico_id = v_periodo_id
          AND m.estado IN ('BORRADOR', 'PENDIENTE_PAGO', 'CONFIRMADA', 'AJUSTADA')
          AND dm.estado IN ('MATRICULADO', 'LISTA_ESPERA')
          AND s.curso_id = v_curso_id
          AND (v_detalle_id_excluir IS NULL OR dm.id <> v_detalle_id_excluir)
    ) THEN
        RAISE EXCEPTION 'El estudiante ya tiene matriculado o en lista de espera este curso en el periodo';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM historial_cursos_estudiante h
        WHERE h.estudiante_id = v_estudiante_id
          AND h.curso_id = v_curso_id
          AND h.aprobado = TRUE
    ) THEN
        RAISE EXCEPTION 'El estudiante ya aprobó este curso y no puede volver a matricularlo';
    END IF;

    IF matricula.hay_choque_horario(v_estudiante_id, v_periodo_id, NEW.seccion_id) THEN
        RAISE EXCEPTION 'Existe choque de horario';
    END IF;

    IF NOT matricula.estudiante_cumple_prerequisitos(v_estudiante_id, v_curso_id) THEN
        RAISE EXCEPTION 'El estudiante no cumple prerrequisitos';
    END IF;

    IF NOT matricula.estudiante_cumple_correquisitos(v_estudiante_id, v_periodo_id, v_curso_id, v_detalle_id_excluir) THEN
        RAISE EXCEPTION 'El estudiante no cumple correquisitos';
    END IF;

    SELECT maximo_creditos INTO v_max_creditos
    FROM periodos_academicos
    WHERE id = v_periodo_id;

    SELECT creditos INTO v_creditos_curso
    FROM cursos
    WHERE id = v_curso_id;

    v_creditos_actuales := matricula.creditos_matriculados_periodo(v_estudiante_id, v_periodo_id);

    IF TG_OP = 'UPDATE' AND OLD.seccion_id = NEW.seccion_id THEN
        -- no cambia el curso ni sus créditos; no sumar nuevamente
        NULL;
    ELSE
        IF (v_creditos_actuales + v_creditos_curso) > v_max_creditos THEN
            RAISE EXCEPTION 'Se excede el máximo de créditos del periodo';
        END IF;
    END IF;

    IF v_total_matriculados < v_cupo THEN
        NEW.estado := 'MATRICULADO';
    ELSE
        IF v_total_espera < v_cupo_espera THEN
            NEW.estado := 'LISTA_ESPERA';
        ELSE
            RAISE EXCEPTION 'No hay cupo disponible ni espacio en lista de espera';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Se elimina el trigger "trg_validar_detalle_matricula" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_validar_detalle_matricula ON detalle_matricula;
-- Se crea el trigger "trg_validar_detalle_matricula" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_validar_detalle_matricula
BEFORE INSERT OR UPDATE OR DELETE ON detalle_matricula
FOR EACH ROW
EXECUTE FUNCTION matricula.validar_detalle_matricula();

-- =========================================================
-- POSTPROCESO DETALLE DE MATRÍCULA (PROMOCIÓN LISTA ESPERA + AJUSTES)
-- Esta versión ampliada del postproceso actualiza cupos, promueve desde lista de espera y marca matrículas ajustadas.
-- =========================================================
-- Se crea o actualiza la función "matricula.post_detalle_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.post_detalle_matricula()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_seccion_id BIGINT;
    v_matricula_id BIGINT;
    v_estudiante_id BIGINT;
    v_posicion INTEGER;
    v_cupos_disponibles INTEGER;
    v_promovido RECORD;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    v_seccion_id := COALESCE(NEW.seccion_id, OLD.seccion_id);
    v_matricula_id := COALESCE(NEW.matricula_id, OLD.matricula_id);

    UPDATE secciones s
    SET total_matriculados = (
            SELECT COUNT(*) FROM detalle_matricula dm
            WHERE dm.seccion_id = s.id AND dm.estado = 'MATRICULADO'
        ),
        total_lista_espera = (
            SELECT COUNT(*) FROM detalle_matricula dm
            WHERE dm.seccion_id = s.id AND dm.estado = 'LISTA_ESPERA'
        )
    WHERE s.id = v_seccion_id;

    IF TG_OP = 'INSERT' AND NEW.estado = 'LISTA_ESPERA' THEN
        SELECT estudiante_id INTO v_estudiante_id
        FROM matriculas
        WHERE id = NEW.matricula_id;

        SELECT COALESCE(MAX(posicion), 0) + 1
        INTO v_posicion
        FROM lista_espera
        WHERE seccion_id = NEW.seccion_id;

-- Se insertan datos iniciales necesarios para que el sistema tenga catálogos básicos desde el inicio.
-- Inserta datos iniciales necesarios para el sistema.
        INSERT INTO lista_espera(seccion_id, estudiante_id, posicion)
        VALUES (NEW.seccion_id, v_estudiante_id, v_posicion)
        ON CONFLICT DO NOTHING;
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.estado = 'LISTA_ESPERA' AND NEW.estado <> 'LISTA_ESPERA' THEN
        DELETE FROM lista_espera
        WHERE seccion_id = NEW.seccion_id
          AND estudiante_id = (
              SELECT estudiante_id
              FROM matriculas
              WHERE id = NEW.matricula_id
          );
    END IF;

    IF TG_OP = 'DELETE' AND OLD.estado = 'LISTA_ESPERA' THEN
        DELETE FROM lista_espera
        WHERE seccion_id = OLD.seccion_id
          AND estudiante_id = (
              SELECT estudiante_id
              FROM matriculas
              WHERE id = OLD.matricula_id
          );
    END IF;

    PERFORM matricula.recalcular_montos_matricula(v_matricula_id);

    IF pg_trigger_depth() = 1 THEN
        SELECT (cupo - total_matriculados)
        INTO v_cupos_disponibles
        FROM secciones
        WHERE id = v_seccion_id;

        WHILE v_cupos_disponibles > 0 LOOP
            SELECT dm.id AS detalle_id,
                   dm.seccion_id,
                   dm.matricula_id,
                   le.estudiante_id,
                   le.posicion
            INTO v_promovido
            FROM lista_espera le
            JOIN matriculas m ON m.estudiante_id = le.estudiante_id
            JOIN detalle_matricula dm
              ON dm.matricula_id = m.id
             AND dm.seccion_id = le.seccion_id
             AND dm.estado = 'LISTA_ESPERA'
            WHERE le.seccion_id = v_seccion_id
            ORDER BY le.posicion
            LIMIT 1;

            EXIT WHEN v_promovido.detalle_id IS NULL;

            UPDATE detalle_matricula
            SET estado = 'MATRICULADO',
                actualizado_en = NOW()
            WHERE id = v_promovido.detalle_id;

            DELETE FROM lista_espera
            WHERE seccion_id = v_seccion_id
              AND estudiante_id = v_promovido.estudiante_id;

            UPDATE lista_espera
            SET posicion = posicion - 1
            WHERE seccion_id = v_seccion_id
              AND posicion > v_promovido.posicion;

            SELECT (cupo - total_matriculados)
            INTO v_cupos_disponibles
            FROM secciones
            WHERE id = v_seccion_id;
        END LOOP;
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE', 'DELETE') THEN
        UPDATE matriculas
        SET estado = CASE
                        WHEN estado = 'CONFIRMADA' THEN 'AJUSTADA'::estado_matricula_enum
                        ELSE estado
                     END
        WHERE id = v_matricula_id
          AND estado = 'CONFIRMADA'
          AND matricula.periodo_ajuste_abierto(periodo_academico_id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Se elimina el trigger "trg_post_detalle_matricula" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_post_detalle_matricula ON detalle_matricula;
-- Se crea el trigger "trg_post_detalle_matricula" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_post_detalle_matricula
AFTER INSERT OR UPDATE OR DELETE ON detalle_matricula
FOR EACH ROW
EXECUTE FUNCTION matricula.post_detalle_matricula();

-- =========================================================
-- POSTPROCESO PAGOS (RECIBOS)
-- Aquí se añade la generación automática de recibos cuando un pago es aprobado.
-- =========================================================
-- Se crea o actualiza la función "matricula.post_pago", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.post_pago()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_pago_id BIGINT;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    IF COALESCE(NEW.factura_id, OLD.factura_id) IS NOT NULL THEN
        PERFORM matricula.recalcular_saldo_factura(COALESCE(NEW.factura_id, OLD.factura_id));
    END IF;

    v_pago_id := COALESCE(NEW.id, OLD.id);

    IF TG_OP <> 'DELETE' AND NEW.estado = 'APROBADO' THEN
        PERFORM matricula.generar_recibo_pago(NEW.id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Se elimina el trigger "trg_post_pago" si ya existe, para permitir recrearlo sin errores.
DROP TRIGGER IF EXISTS trg_post_pago ON pagos;
-- Se crea el trigger "trg_post_pago" para ejecutar automáticamente una función ante eventos INSERT, UPDATE o DELETE.
-- Define un trigger que ejecuta automáticamente una función ante eventos.
CREATE TRIGGER trg_post_pago
AFTER INSERT OR UPDATE OR DELETE ON pagos
FOR EACH ROW
EXECUTE FUNCTION matricula.post_pago();

-- =========================================================
-- CONFIRMAR MATRÍCULA SOLO CON PAGO EXITOSO + COMPROBANTE
-- Aquí se confirma la matrícula solo con pago suficiente y además se genera un comprobante.
-- =========================================================
-- Se crea o actualiza la función "matricula.confirmar_matricula", que encapsula una regla o proceso de negocio dentro de la base de datos.
-- Define una función que implementa lógica de negocio en la base de datos.
CREATE OR REPLACE FUNCTION matricula.confirmar_matricula(p_matricula_id BIGINT, p_usuario_id BIGINT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(12,2);
    v_pagado NUMERIC(12,2);
    v_estado estado_matricula_enum;
-- Inicia una transacción para ejecutar todo el script como una unidad atómica.
BEGIN
    SELECT total, estado
    INTO v_total, v_estado
    FROM matriculas
    WHERE id = p_matricula_id;

    IF v_estado IS NULL THEN
        RAISE EXCEPTION 'La matrícula no existe';
    END IF;

    IF v_estado = 'CANCELADA' THEN
        RAISE EXCEPTION 'No se puede confirmar una matrícula cancelada';
    END IF;

    SELECT COALESCE(SUM(monto), 0)
    INTO v_pagado
    FROM pagos
    WHERE matricula_id = p_matricula_id
      AND estado = 'APROBADO';

    IF v_pagado < v_total THEN
        RAISE EXCEPTION 'No se puede confirmar la matrícula: pago insuficiente';
    END IF;

    UPDATE matriculas
    SET estado = 'CONFIRMADA',
        confirmada_en = NOW(),
        confirmada_por = p_usuario_id
    WHERE id = p_matricula_id;

    PERFORM matricula.generar_comprobante_matricula(p_matricula_id);
END;
$$;

-- =========================================================
-- VISTAS ADICIONALES
-- En esta sección se crean vistas extra para consultar comprobantes y recibos.
-- =========================================================
-- Se crea o actualiza la vista "vista_comprobantes_matricula" para facilitar consultas y reportes sin duplicar datos.
-- Define una vista para facilitar consultas y reportes.
CREATE OR REPLACE VIEW vista_comprobantes_matricula AS
SELECT
    cm.id,
    cm.numero_comprobante,
    cm.fecha_emision,
    cm.matricula_id,
    m.numero_matricula,
    e.carnet,
    u.nombres,
    u.apellidos,
    cm.factura_id,
    cm.pago_id,
    cm.observacion
FROM comprobantes_matricula cm
JOIN matriculas m ON m.id = cm.matricula_id
JOIN estudiantes e ON e.id = m.estudiante_id
JOIN usuarios u ON u.id = e.usuario_id;

-- Se crea o actualiza la vista "vista_recibos_pago" para facilitar consultas y reportes sin duplicar datos.
-- Define una vista para facilitar consultas y reportes.
CREATE OR REPLACE VIEW vista_recibos_pago AS
SELECT
    rp.id,
    rp.numero_recibo,
    rp.fecha_emision,
    rp.pago_id,
    p.referencia_pago,
    rp.factura_id,
    rp.estudiante_id,
    e.carnet,
    u.nombres,
    u.apellidos,
    rp.monto,
    rp.moneda,
    rp.detalle
FROM recibos_pago rp
JOIN pagos p ON p.id = rp.pago_id
JOIN estudiantes e ON e.id = rp.estudiante_id
JOIN usuarios u ON u.id = e.usuario_id;

-- Se crea el índice "idx_comprobantes_matricula_numero" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_comprobantes_matricula_numero ON comprobantes_matricula(numero_comprobante);
-- Se crea el índice "idx_recibos_pago_numero" para mejorar el rendimiento de búsquedas y joins frecuentes.
-- Crea un índice para mejorar el rendimiento de consultas.
CREATE INDEX IF NOT EXISTS idx_recibos_pago_numero ON recibos_pago(numero_recibo);


COMMIT;