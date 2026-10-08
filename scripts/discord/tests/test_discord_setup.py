import email.message
import io
import json
import urllib.error
from typing import Any

import pytest

import discord_setup as ds


class FakeApi:
    """In-memory stand-in for the Discord API that records every write."""

    def __init__(self, *, automod: list[dict[str, Any]] | None = None):
        self.dry_run = False
        self.writes: list[tuple[str, str, Any]] = []
        self.automod = automod or []

    def get(self, path: str) -> Any:
        assert path == f"/guilds/{ds.GUILD_ID}/auto-moderation/rules"
        return self.automod

    def write(self, method: str, path: str, body: Any, *, describe: str) -> Any:
        self.writes.append((method, path, body))
        return {"id": "new"}


AUTOMOD = f"/guilds/{ds.GUILD_ID}/auto-moderation/rules"


def test_missing_automod_rules_are_created():
    api = FakeApi(automod=[{"id": "default", "trigger_type": 5}])
    ds.setup(api)
    created = [b for m, p, b in api.writes if m == "POST" and p == AUTOMOD]
    assert [r["trigger_type"] for r in created] == [3, 4]
    assert created[1]["trigger_metadata"] == {"presets": [2, 3]}
    assert all(r["actions"][0]["type"] == 1 and r["enabled"] for r in created)


def test_existing_automod_rules_are_updated_in_place():
    api = FakeApi(automod=[{"id": "a1", "trigger_type": 3}, {"id": "a2", "trigger_type": 4}])
    ds.setup(api)
    automod = [(m, p) for m, p, _ in api.writes if p.startswith(AUTOMOD)]
    assert automod == [("PATCH", f"{AUTOMOD}/a1"), ("PATCH", f"{AUTOMOD}/a2")]
    patched = next(b for m, p, b in api.writes if p == f"{AUTOMOD}/a1")
    assert "trigger_type" not in patched


def test_registers_ping_and_meetup():
    api = FakeApi()
    ds.setup(api)
    path = f"/applications/{ds.APPLICATION_ID}/commands"
    commands = next(b for m, p, b in api.writes if m == "PUT" and p == path)
    assert [c["name"] for c in commands] == ["ping", "meetup"]


def test_registers_linked_roles_metadata():
    api = FakeApi()
    ds.setup(api)
    path = f"/applications/{ds.APPLICATION_ID}/role-connections/metadata"
    metadata = next(b for m, p, b in api.writes if m == "PUT" and p == path)
    assert metadata == [
        {
            "type": 7,
            "key": "member",
            "name": "fairfieldct.ai member",
            "description": "Has a fairfieldct.ai account",
        }
    ]


def test_dry_run_prints_changes_without_sending_them(monkeypatch, capsys):
    def urlopen(request):
        raise AssertionError("a dry run sent a request")

    monkeypatch.setattr(ds.urllib.request, "urlopen", urlopen)
    api = ds.Discord("token", dry_run=True)
    assert api.write("PUT", "/x", [], describe="register /ping") is None
    assert capsys.readouterr().out == "would register /ping\n"


def http_error(code: int, body: dict[str, Any]) -> urllib.error.HTTPError:
    payload = io.BytesIO(json.dumps(body).encode())
    return urllib.error.HTTPError("url", code, "error", email.message.Message(), payload)


def test_rate_limits_are_retried(monkeypatch):
    responses = [http_error(429, {"retry_after": 0}), io.BytesIO(b'{"ok": true}')]

    def urlopen(request):
        response = responses.pop(0)
        if isinstance(response, Exception):
            raise response
        return response

    monkeypatch.setattr(ds.urllib.request, "urlopen", urlopen)
    monkeypatch.setattr(ds.time, "sleep", lambda seconds: None)
    assert ds.Discord("token", dry_run=False).get("/x") == {"ok": True}


def test_persistent_rate_limit_gives_up(monkeypatch):
    def urlopen(request):
        raise http_error(429, {"retry_after": 0})

    monkeypatch.setattr(ds.urllib.request, "urlopen", urlopen)
    monkeypatch.setattr(ds.time, "sleep", lambda seconds: None)
    with pytest.raises(SystemExit, match="still rate limited"):
        ds.Discord("token", dry_run=False).get("/x")


def test_api_errors_stop_the_run(monkeypatch):
    def urlopen(request):
        raise http_error(403, {"message": "Missing Permissions"})

    monkeypatch.setattr(ds.urllib.request, "urlopen", urlopen)
    with pytest.raises(SystemExit, match=r"403: .*Missing Permissions"):
        ds.Discord("token", dry_run=False).write("PATCH", "/x", {}, describe="x")


def test_requests_authenticate_as_the_bot(monkeypatch):
    seen = []

    def urlopen(request):
        seen.append(request)
        return io.BytesIO(b"")

    monkeypatch.setattr(ds.urllib.request, "urlopen", urlopen)
    assert ds.Discord("abc", dry_run=False).write("PUT", "/x", [1], describe="x") is None
    assert seen[0].get_header("Authorization") == "Bot abc"
    assert seen[0].get_method() == "PUT"
    assert json.loads(seen[0].data) == [1]
