from __future__ import annotations

import binascii
import hashlib
import hmac
import os


def hash_password(password: str, *, iterations: int = 390000) -> str:
    salt = binascii.hexlify(os.urandom(16)).decode()
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), iterations)
    return f"pbkdf2_sha256${iterations}${salt}${binascii.hexlify(digest).decode()}"


def verify_password(password: str, hashed_value: str | None) -> bool:
    if not password or not hashed_value:
        return False

    try:
        algorithm, iterations, salt, stored_hash = hashed_value.split("$", 3)
    except ValueError:
        return False

    if algorithm != "pbkdf2_sha256":
        return False

    derived = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode(),
        salt.encode(),
        int(iterations),
    )
    calculated = binascii.hexlify(derived).decode()
    return hmac.compare_digest(calculated, stored_hash)
