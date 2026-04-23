from __future__ import annotations

from contextlib import contextmanager
from typing import Any, Iterable

import psycopg
from psycopg.rows import dict_row

from app.core.config import get_settings


@contextmanager
def get_conn(acting_as: str | None = None):
    settings = get_settings()
    with psycopg.connect(settings.database_url, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute("SET search_path TO matricula, public;")
            if acting_as:
                cur.execute("SELECT set_config('app.usuario_actual', %s, false);", (acting_as,))
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise


def fetch_one(sql: str, params: Iterable[Any] | None = None, *, acting_as: str | None = None):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchone()


def fetch_all(sql: str, params: Iterable[Any] | None = None, *, acting_as: str | None = None):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchall()


def execute(sql: str, params: Iterable[Any] | None = None, *, acting_as: str | None = None):
    with get_conn(acting_as=acting_as) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return True
