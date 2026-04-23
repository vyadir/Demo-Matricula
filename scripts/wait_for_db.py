import os
import time
import psycopg

database_url = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/matricula_db")

for attempt in range(1, 31):
    try:
        with psycopg.connect(database_url) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                print("Database is ready.")
                raise SystemExit(0)
    except Exception as exc:
        print(f"[{attempt}/30] Waiting for database: {exc}")
        time.sleep(2)

raise SystemExit("Database did not become ready in time.")
