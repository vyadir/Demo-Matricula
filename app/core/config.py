from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Sistema de Matrícula Universitaria"
    app_env: str = "development"
    secret_key: str = "change-me"
    database_url: str = "postgresql://postgres:postgres@db:5432/matricula_db"
    tuition_price_per_credit: float = 27500
    default_currency: str = "CRC"
    sso_mode: str = "mock"
    oidc_client_id: str | None = None
    oidc_client_secret: str | None = None
    oidc_discovery_url: str | None = None
    oidc_redirect_uri: str | None = None
    payment_provider: str = "mock"
    payment_success_redirect: str = "http://localhost:8000/student/finance"
    session_https_only: bool = False

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
