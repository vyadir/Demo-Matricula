# Fixes applied after Docker startup issues

## Fixed in this package
- Removed obsolete `version` from `docker-compose.yml`
- Corrected `periodos_academicos.estado` from invalid `ACTIVO` to valid `MATRICULA_ABIERTA`
- Corrected `secciones.modalidad` insert by casting `s.modalidad::modalidad_enum`
- Patched `db/init/00_schema.sql` so enum updates in invoice recalculation use explicit enum casts in `matricula.recalcular_saldo_factura`
- Patched `db/init/00_schema.sql` so adjustment updates on `matriculas.estado` cast `AJUSTADA` to `estado_matricula_enum`
- Fixed middleware order in `app/main.py` so `SessionMiddleware` wraps the flash middleware
- Added defensive checks in `app/core/flash.py` to avoid crashing if `request.session` is unavailable
- Corrected previous seed/schema mismatches:
  - `planes_estudio.requiere_tfg` -> `planes_estudio.activo`
  - `planes_estudio_curso` -> `plan_estudio_curso`
  - `ciclo_recomendado`/`tipo` -> `ciclo`/`es_obligatorio`
  - removed `aulas.piso`
  - `historial_academico` -> `historial_cursos_estudiante`
  - aligned history columns to `nota_final` and `aprobado`
  - aligned `becas` columns to `porcentaje_descuento` and `monto_descuento_fijo`
  - aligned `estudiante_beca` to `periodo_academico_id` and `activa`
  - removed nonexistent `pagos.creado_por`
  - replaced nonexistent `f.moneda` with literal `'CRC'`

## If startup failed before
Run again with a clean volume:

```bash
docker compose down -v
docker compose up --build
```
