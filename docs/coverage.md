# Matriz de cobertura del requerimiento

Esta matriz sigue el SRS cargado por el usuario.

## Cobertura funcional

| Requerimiento del SRS | Cobertura en la solución |
|---|---|
| RF-01 Autenticación mediante SSO institucional | `/auth/sso` en modo mock para pruebas locales y variables de entorno listas para OIDC real |
| RF-02 Administrar roles y permisos | control por rol en backend, navegación condicionada y asignación de roles desde `/admin/catalogs` |
| RF-03 Registrar bitácoras de auditoría | consulta de `bitacora_auditoria` en `/audit` y uso del esquema SQL entregado |
| RF-04 Gestionar carreras y planes de estudio | formularios y listados en `/admin/catalogs` |
| RF-05 Administrar catálogo de cursos | formularios y listados en `/admin/catalogs` |
| RF-06 Gestionar periodos académicos | formulario y listado en `/admin/catalogs` |
| RF-07 Configurar prerrequisitos y correquisitos | formularios de alta y validación efectiva durante la matrícula |
| RF-08 Crear secciones de cursos | formulario de secciones en `/admin/catalogs` |
| RF-09 Administrar horarios y aulas | formularios de aulas y horarios de secciones |
| RF-10 Controlar cupos por sección | el portal muestra ocupación y la BD decide matrícula o lista de espera |
| RF-11 Visualizar oferta académica | `/student/offer` |
| RF-12 Validar cupos, horarios, prerrequisitos, créditos y restricciones financieras | validaciones centrales del esquema SQL original al agregar cursos |
| RF-13 Confirmar matrícula con comprobante | pago mock + confirmación + comprobante visible en finanzas |
| RF-14 Permitir ajustes en periodos autorizados | alta y baja desde el portal dentro de las ventanas del periodo |
| RF-15 Calcular costos de matrícula | costos por crédito, descuento por beca y totales en la matrícula |
| RF-16 Generar estados de cuenta | botón `Generar estado de cuenta` |
| RF-17 Integrarse con pasarela de pago | flujo local con pasarela mock para pruebas end to end; interfaz preparada para proveedor real |
| RF-18 Bloquear matrícula por morosidad | validación existente en BD respetada por la web |
| RF-19 Registrar pagos y saldos | módulo de finanzas y reportes financieros |
| RF-20 Generar reportes de matrícula | `/reports` |
| RF-21 Generar reportes financieros | `/reports` |
| RF-22 Exportar información | exportación CSV |
| RF-23 Enviar notificaciones de matrícula | centro de notificaciones y eventos por matrícula |
| RF-24 Enviar notificaciones de pagos | eventos de pago y lectura de notificaciones |

## Cobertura no funcional

| Requerimiento no funcional del SRS | Cobertura |
|---|---|
| Seguridad | contraseñas con hash, sesiones, control por rol, auditoría y variables para HTTPS |
| Rendimiento | SSR liviano con FastAPI/Jinja y consultas directas a vistas/tablas |
| Disponibilidad | despliegue reproducible con Docker Compose |
| Usabilidad | interfaz responsive, navegación clara, formularios simples y feedback visual |
| Mantenibilidad | proyecto modular por routers, servicios, templates y acceso a datos |

## Reglas de negocio visibles en la demo

- Límite de créditos por periodo.
- Pago requerido para confirmar matrícula.
- Prerrequisitos y correquisitos antes de inscribir.
- Matrícula disponible solo dentro de fechas definidas.
- Bloqueos por deuda financiera o académica.
- Control de cupos y lista de espera.

## Lo que queda parametrizado para pasar a ambiente institucional real

1. **SSO real**  
   El proyecto trae modo mock para validar el requerimiento local. Para conectar el IdP institucional solo faltan credenciales y metadatos OIDC.

2. **Pasarela real**  
   El flujo está montado en modo mock para pruebas locales. Para producción solo faltan llaves, endpoint de checkout y callback del proveedor.
