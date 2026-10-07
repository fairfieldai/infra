import email.message
import io
import json
import stat
import urllib.error
from typing import Any

import pytest

import discord_setup as ds

BOT = "bot-1"


class FakeApi:
    """In-memory stand-in for the Discord API that records every write."""

    def __init__(self, *, channels: list[dict[str, Any]], dry_run: bool = False, **state: Any):
        self.dry_run = dry_run
        self.writes: list[tuple[str, str, Any]] = []
        self.next_id = 100
        self.state = {
            "guild": {"rules_channel_id": "rules", "public_updates_channel_id": "mods"},
            "channels": channels,
            "roles": [],
            "messages": [],
            "automod": [],
            "invites": [],
            "webhooks": [],
            **state,
        }

    def get(self, path: str) -> Any:
        routes = {
            f"/guilds/{ds.GUILD_ID}": "guild",
            f"/guilds/{ds.GUILD_ID}/channels": "channels",
            f"/guilds/{ds.GUILD_ID}/roles": "roles",
            f"/guilds/{ds.GUILD_ID}/auto-moderation/rules": "automod",
            f"/guilds/{ds.GUILD_ID}/invites": "invites",
        }
        if path == "/users/@me":
            return {"id": BOT}
        if path.endswith("/messages?limit=50"):
            return self.state["messages"]
        if path.endswith("/webhooks"):
            return self.state["webhooks"]
        return self.state[routes[path]]

    def write(self, method: str, path: str, body: Any, *, describe: str) -> Any:
        self.writes.append((method, path, body))
        self.next_id += 1
        return {"id": str(self.next_id), "code": "abc", "token": "secret-token"}

    def created(self) -> list[str]:
        return [b.get("name", "") for m, _, b in self.writes if m == "POST" and isinstance(b, dict)]

    def patched(self, path: str) -> Any:
        return next(b for m, p, b in self.writes if m == "PATCH" and p == path)


def channel(cid: str, name: str, kind: int = ds.TEXT) -> dict[str, Any]:
    return {"id": cid, "name": name, "type": kind}


DEFAULT_SERVER = [
    channel("text-cat", "Text Channels", ds.CATEGORY),
    channel("voice-cat", "Voice Channels", ds.CATEGORY),
    channel("general", "general"),
    channel("rules", "rules"),
    channel("mods", "moderator-only"),
]


def configured_server() -> list[dict[str, Any]]:
    specs = ds.CATEGORIES + ds.CHANNELS
    found = {"welcome-and-rules": "rules", "moderator-only": "mods"}
    return [channel(found.get(s.name, s.name), s.name, s.kind) for s in specs] + [
        channel("voice-cat", "Voice Channels", ds.CATEGORY)
    ]


def test_new_server_creates_roles_and_missing_channels(tmp_path):
    api = FakeApi(channels=list(DEFAULT_SERVER))
    ds.setup(api, tmp_path)

    created = api.created()
    assert {"Organizer", "Speaker / Demo"} <= set(created)
    assert {"Start here", "Events", "Organizers", "announcements", "help-and-questions"} <= set(
        created
    )
    # Existing channels are reused, not recreated.
    assert not {"Community", "general", "welcome-and-rules", "moderator-only"} & set(created)
    assert api.patched("/channels/text-cat")["name"] == "Community"
    assert api.patched("/channels/rules")["name"] == "welcome-and-rules"
    assert api.patched("/channels/mods")["name"] == "moderator-only"


def test_forum_and_announcement_channels_have_the_right_types(tmp_path):
    api = FakeApi(channels=list(DEFAULT_SERVER))
    ds.setup(api, tmp_path)
    bodies = {b["name"]: b for m, _, b in api.writes if m == "POST" and "name" in b}
    assert bodies["help-and-questions"]["type"] == ds.FORUM
    assert bodies["help-and-questions"]["default_forum_layout"] == 1
    assert bodies["announcements"]["type"] == ds.ANNOUNCEMENT


def test_private_and_read_only_channels_get_overwrites(tmp_path):
    api = FakeApi(channels=configured_server())
    ds.setup(api, tmp_path)
    inbox = api.patched("/channels/inbox")["permission_overwrites"]
    assert {"id": ds.GUILD_ID, "type": 0, "allow": "0", "deny": str(ds.VIEW_CHANNEL)} in inbox
    rules = api.patched("/channels/rules")["permission_overwrites"]
    everyone = next(o for o in rules if o["id"] == ds.GUILD_ID)
    assert int(everyone["deny"]) & ds.SEND_MESSAGES
    assert "permission_overwrites" not in api.patched("/channels/general")


def test_configured_server_is_only_updated(tmp_path, capsys):
    api = FakeApi(
        channels=configured_server(),
        roles=[{"id": "r1", "name": "Organizer"}, {"id": "r2", "name": "Speaker / Demo"}],
        messages=[{"id": "m1", "author": {"id": BOT}, "content": ds.RULES_HEADING + "\nold"}],
        automod=[{"id": "a1", "trigger_type": 3}, {"id": "a2", "trigger_type": 4}],
        invites=[{"code": "keep", "inviter": {"id": BOT}, "max_age": 0, "max_uses": 0}],
        webhooks=[{"name": "Inbox"}],
    )
    ds.setup(api, tmp_path)

    assert api.created() == []
    assert api.patched("/channels/rules/messages/m1")["content"].startswith(ds.RULES_HEADING)
    assert "invite: https://discord.gg/keep" in capsys.readouterr().out
    assert not (tmp_path / "inbox-webhook-url").exists()


def test_rules_post_from_someone_else_is_not_edited(tmp_path):
    api = FakeApi(
        channels=configured_server(),
        messages=[{"id": "m1", "author": {"id": "human"}, "content": ds.RULES_HEADING}],
    )
    ds.setup(api, tmp_path)
    assert any(m == "POST" and p == "/channels/rules/messages" for m, p, _ in api.writes)


def test_rules_post_mentions_channels_and_policies():
    ids = {n: f"id-{n}" for n in ("introductions", "show-and-tell", "help-and-questions")}
    post = ds.rules_post({**ids, "announcements": "id-announcements"})
    assert post.startswith(ds.RULES_HEADING)
    assert "<#id-introductions>" in post
    assert "https://www.fairfieldct.ai/terms/" in post
    assert "https://www.fairfieldct.ai/privacy/" in post


def test_new_webhook_url_goes_to_owner_only_file_and_is_never_printed(tmp_path, capsys):
    api = FakeApi(channels=configured_server())
    ds.setup(api, tmp_path)
    path = tmp_path / "inbox-webhook-url"
    assert path.read_text().endswith("/secret-token")
    assert stat.S_IMODE(path.stat().st_mode) == ds.OWNER_ONLY
    assert "secret-token" not in capsys.readouterr().out


def test_dry_run_writes_nothing_and_reports_changes(tmp_path, capsys, monkeypatch):
    def refuse(*args, **kwargs):
        raise AssertionError("dry run made a request")

    monkeypatch.setattr(ds.urllib.request, "urlopen", refuse)
    discord = ds.Discord("token", dry_run=True)
    result = discord.write("POST", "/x", {"name": "inbox"}, describe="create #inbox")
    assert result["id"] == "<inbox>"
    assert ds.is_placeholder(result["id"])
    assert capsys.readouterr().out == "would create #inbox\n"


class DryRunApi(FakeApi):
    """Answers writes with placeholders, as a dry run does, and rejects reads of them."""

    def get(self, path: str) -> Any:
        assert "<" not in path, f"read a placeholder: {path}"
        return super().get(path)

    def write(self, method: str, path: str, body: Any, *, describe: str) -> Any:
        self.writes.append((method, path, body))
        return {"id": ds.placeholder(describe), "code": "c", "token": "t"}


def test_dry_run_on_a_new_server_skips_reads_of_channels_that_dont_exist(tmp_path):
    api = DryRunApi(channels=[], dry_run=True, guild={})
    ds.setup(api, tmp_path)
    assert api.created()
    assert not (tmp_path / "inbox-webhook-url").exists()


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
