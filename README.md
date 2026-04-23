# Sistema de Matrícula Universitaria


## Cómo ejecutar

```bash
docker compose up --build
```

Luego abre:

```text
http://localhost:8000
```

## Usuarios demo

| Rol | Usuario | Contraseña |
|---|---|---|
| Administrador TI | `admin` | `Admin123!` |
| Registro académico | `registro` | `Registro123!` |
| Tesorería | `tesoreria` | `Tesoreria123!` |
| Estudiante | `estudiante` | `Estudiante123!` |
| Auditor | `auditor` | `Auditor123!` |

También puedes entrar por **SSO mock** desde `/auth/sso`.

## Estructura
- `app/`: código de la aplicación
- `db/init/00_schema.sql`: esquema original entregado
- `db/init/10_demo_seed.sql`: datos demo y escenarios de prueba
- `docs/coverage.md`: matriz de cobertura del requerimiento
- `docker-compose.yml`: orquestación local
- `.env.production.example`: referencia base para despliegue

## Despliegue
Para una salida más cercana a producción:
1. Copia `.env.production.example` a `.env`
2. Cambia `SECRET_KEY`
3. Define `APP_ENV=production`
4. Activa `SESSION_HTTPS_ONLY=true`
5. Sustituye `SSO_MODE=mock` por configuración OIDC real cuando exista IdP institucional
6. Publica detrás de HTTPS y reverse proxy

## Escenarios de prueba sugeridos
1. Inicia como **estudiante**.
2. Ve a **Oferta académica** y agrega:
   - `BD101-A`: debería matricularse.
   - `ING101-A`: debería entrar en **lista de espera** porque ya está llena.
   - `RED201-A`: debería bloquearse por prerrequisito.
   - `MAT102-A` junto con `BD101-A`: debería bloquearse por choque de horario.
3. Ve a **Mi matrícula** y genera el estado de cuenta.
4. Ve a **Finanzas** y paga la factura con la pasarela mock.
5. Verifica recibo, comprobante y notificaciones.
6. Entra como **admin** o **registro** para administrar catálogos.
7. Entra como **auditor** para consultar la bitácora.

## Notas importantes
- El proyecto queda **listo para SSO** con modo mock y adaptable a **OIDC**.
- El flujo de pago queda integrado en **modo mock** para validar el requerimiento localmente.
- Las reglas críticas de negocio viven en la base de datos entregada y la web las respeta.
