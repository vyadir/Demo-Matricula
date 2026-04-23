from __future__ import annotations

from starlette.requests import Request


def add_flash(request: Request, level: str, message: str) -> None:
    if "session" not in request.scope:
        return
    flashes = request.session.get("_flashes", [])
    flashes.append({"level": level, "message": message})
    request.session["_flashes"] = flashes


def pop_flashes(request: Request) -> list[dict[str, str]]:
    if "session" not in request.scope:
        return []
    flashes = request.session.pop("_flashes", [])
    return flashes
