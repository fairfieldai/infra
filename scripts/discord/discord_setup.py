"""Configure the fairfieldct.ai Discord server.

Creates or updates the roles, categories, channels, permissions, server settings, rules post,
AutoMod rules, slash commands, Linked Roles metadata, invite, and the #inbox and #announcements
webhooks. Everything
is matched by name, so rerunning updates the server in place instead of duplicating anything.

The bot needs the Administrator permission while this runs, and its token is read from SSM.
With --dry-run, nothing changes; each create or update is printed instead.
"""

import argparse
import base64
import json
import os
import subprocess
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Protocol

GUILD_ID = "1557456560488448190"
APPLICATION_ID = "1557457463534686319"
TOKEN_PARAMETER = "/fairfieldct-ai/discord-bot-token"
AWS_PROFILE = "fairfieldct-ai-admin"
AWS_REGION = "us-east-1"
ICON = Path(__file__).parent / "icon.png"
RULES_HEADING = "# Welcome to fairfieldct.ai"

# Permission bits: https://discord.com/developers/docs/topics/permissions
VIEW_CHANNEL = 1 << 10
SEND_MESSAGES = 1 << 11
MANAGE_MESSAGES = 1 << 13
MENTION_EVERYONE = 1 << 17
MANAGE_EVENTS = 1 << 33
MANAGE_THREADS = 1 << 34
CREATE_PUBLIC_THREADS = 1 << 35
MODERATE_MEMBERS = 1 << 40
CREATE_EVENTS = 1 << 44
ORGANIZER_PERMISSIONS = (
    MANAGE_MESSAGES
    | MANAGE_THREADS
    | MODERATE_MEMBERS
    | MANAGE_EVENTS
    | CREATE_EVENTS
    | MENTION_EVERYONE
)

TEXT, CATEGORY, ANNOUNCEMENT, FORUM = 0, 4, 5, 15
SUPPRESS_EMBEDS = 1 << 2
MAX_ATTEMPTS = 6
OWNER_ONLY = 0o600
TOO_MANY_REQUESTS = 429

type Json = Any


class Api(Protocol):
    """The Discord API calls setup needs."""

    dry_run: bool

    def get(self, path: str) -> Json:
        """Read a resource."""
        ...

    def write(self, method: str, path: str, body: Json, *, describe: str) -> Json:
        """Create or change a resource, or only describe the change in a dry run."""
        ...


class Discord:
    """Discord REST API client authenticated as the bot."""

    def __init__(self, token: str, *, dry_run: bool) -> None:
        """Create a client for the bot token."""
        self.token = token
        self.dry_run = dry_run

    def get(self, path: str) -> Json:
        """Read a resource."""
        return self._request("GET", path)

    def write(self, method: str, path: str, body: Json, *, describe: str) -> Json:
        """Make a change, or print it and return a stand-in object in a dry run."""
        print(("would " if self.dry_run else "") + describe)
        if self.dry_run:
            name = body.get("name", describe) if isinstance(body, dict) else describe
            return {"id": placeholder(name), "code": "<invite>", "token": "<token>"}
        return self._request(method, path, body)

    def _request(self, method: str, path: str, body: Json = None) -> Json:
        data = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(
            f"https://discord.com/api/v10{path}",
            data=data,
            method=method,
            headers={
                "Authorization": f"Bot {self.token}",
                "Content-Type": "application/json",
                "User-Agent": "DiscordBot (https://www.fairfieldct.ai, 1.0)",
            },
        )
        for _ in range(MAX_ATTEMPTS):
            try:
                with urllib.request.urlopen(request) as response:
                    raw = response.read()
                    return json.loads(raw) if raw else None
            except urllib.error.HTTPError as error:
                detail = error.read()
                if error.code == TOO_MANY_REQUESTS:
                    time.sleep(float(json.loads(detail).get("retry_after", 1)) + 0.25)
                    continue
                message = f"{method} {path} -> {error.code}: {detail.decode()[:500]}"
                raise SystemExit(message) from error
        raise SystemExit(f"{method} {path}: still rate limited after {MAX_ATTEMPTS} attempts")


def placeholder(name: str) -> str:
    """ID standing in for an object a dry run would create."""
    return f"<{name}>"


def is_placeholder(object_id: str) -> bool:
    """Whether an ID belongs to an object that doesn't exist yet."""
    return object_id.startswith("<")


def overwrite(target: str, *, allow: int = 0, deny: int = 0) -> Json:
    """Channel permission overwrite for a role."""
    return {"id": target, "type": 0, "allow": str(allow), "deny": str(deny)}


@dataclass(frozen=True)
class ChannelSpec:
    """A category or channel the server should have."""

    name: str
    kind: int
    parent: str | None = None
    topic: str | None = None
    access: str | None = None
    rename_from: str | None = None
    guild_field: str | None = None


CATEGORIES = [
    ChannelSpec("Start here", CATEGORY),
    ChannelSpec("Community", CATEGORY, rename_from="Text Channels"),
    ChannelSpec("Events", CATEGORY),
    ChannelSpec("Organizers", CATEGORY, access="private"),
]

CHANNELS = [
    ChannelSpec(
        "welcome-and-rules",
        TEXT,
        "Start here",
        "Start here: community guidelines and links.",
        access="read_only",
        guild_field="rules_channel_id",
    ),
    ChannelSpec(
        "announcements",
        ANNOUNCEMENT,
        "Start here",
        "Event news and updates from organizers.",
        access="read_only",
    ),
    ChannelSpec(
        "introductions",
        TEXT,
        "Start here",
        "New here? Tell us who you are and what you're curious about.",
    ),
    ChannelSpec("general", TEXT, "Community", "Everyday conversation about AI and our town."),
    ChannelSpec(
        "show-and-tell",
        TEXT,
        "Community",
        "Share what you're building, how you built it, and what you learned.",
    ),
    ChannelSpec(
        "help-and-questions",
        FORUM,
        "Community",
        "Ask anything about using or building with AI. One post per question.",
    ),
    ChannelSpec("resources", TEXT, "Community", "Useful links, tools, papers, and tutorials."),
    ChannelSpec(
        "meetups",
        TEXT,
        "Events",
        "Meetup logistics and follow-ups. Dates and RSVPs live in Events.",
    ),
    ChannelSpec("organizers", TEXT, "Organizers", "Planning for organizers.", access="private"),
    ChannelSpec(
        "inbox",
        TEXT,
        "Organizers",
        "New email to hello@inbox.fairfieldct.ai.",
        access="private",
    ),
    ChannelSpec(
        "moderator-only",
        TEXT,
        "Organizers",
        "Updates from Discord about this community.",
        access="private",
        guild_field="public_updates_channel_id",
    ),
]

# Display order: categories, then channels within each category.
ORDER = [
    ["Start here", "Community", "Events", "Voice Channels", "Organizers"],
    ["welcome-and-rules", "announcements", "introductions"],
    ["general", "show-and-tell", "help-and-questions", "resources"],
]


@dataclass
class Server:
    """What setup has learned about the server so far."""

    api: Api
    guild: Json
    channels: list[Json]
    access: dict[str, list[Json]] = field(default_factory=dict)
    ids: dict[str, str] = field(default_factory=dict)


def ensure_role(api: Api, roles: dict[str, Json], name: str, body: Json) -> str:
    """Create or update a role, returning its ID."""
    body = {"name": name, "mentionable": True, **body}
    if name in roles:
        role_id = roles[name]["id"]
        api.write(
            "PATCH", f"/guilds/{GUILD_ID}/roles/{role_id}", body, describe=f"update role {name}"
        )
        return role_id
    return api.write("POST", f"/guilds/{GUILD_ID}/roles", body, describe=f"create role {name}")[
        "id"
    ]


def ensure_roles(api: Api) -> str:
    """Create or update the Organizer and Speaker roles, returning the Organizer role's ID."""
    roles = {role["name"]: role for role in api.get(f"/guilds/{GUILD_ID}/roles")}
    organizer = ensure_role(
        api,
        roles,
        "Organizer",
        {"color": 0x1D7A66, "hoist": True, "permissions": str(ORGANIZER_PERMISSIONS)},
    )
    ensure_role(
        api, roles, "Speaker / Demo", {"color": 0xE3B23C, "hoist": False, "permissions": "0"}
    )
    # Granted by Discord through Linked Roles once a member connects their
    # account at https://www.fairfieldct.ai/connect/discord/. Discord's API
    # can't set a role's Links requirement; add "fairfieldct.ai member" to it in
    # Server Settings, Roles, Member, Links.
    ensure_role(api, roles, "Member", {"color": 0x4CC3A5, "hoist": False, "permissions": "0"})
    return organizer


def access_levels(organizer: str) -> dict[str, list[Json]]:
    """Permission overwrites for read-only and organizer-only channels."""
    return {
        "read_only": [
            overwrite(GUILD_ID, deny=SEND_MESSAGES | CREATE_PUBLIC_THREADS),
            overwrite(organizer, allow=SEND_MESSAGES),
        ],
        "private": [
            overwrite(GUILD_ID, deny=VIEW_CHANNEL),
            overwrite(organizer, allow=VIEW_CHANNEL | SEND_MESSAGES),
        ],
    }


def find_existing(server: Server, spec: ChannelSpec) -> Json:
    """The existing channel a spec refers to, if any."""
    if spec.guild_field:
        wanted = server.guild.get(spec.guild_field)
        return next((c for c in server.channels if c["id"] == wanted), None)
    for name in (spec.name, spec.rename_from):
        match = next(
            (c for c in server.channels if c["name"] == name and c["type"] == spec.kind), None
        )
        if match:
            return match
    return None


def ensure_channel(server: Server, spec: ChannelSpec) -> str:
    """Create or update a category or channel, returning its ID."""
    body: dict[str, Json] = {"name": spec.name}
    if spec.kind != CATEGORY:
        body["parent_id"] = server.ids[spec.parent] if spec.parent else None
    if spec.topic is not None:
        body["topic"] = spec.topic
    if spec.access:
        body["permission_overwrites"] = server.access[spec.access]
    label = f"category {spec.name}" if spec.kind == CATEGORY else f"#{spec.name}"
    current = find_existing(server, spec)
    if current:
        path = f"/channels/{current['id']}"
        server.api.write("PATCH", path, body, describe=f"update {label}")
        return current["id"]
    body["type"] = spec.kind
    if spec.kind == FORUM:
        body["default_forum_layout"] = 1
    path = f"/guilds/{GUILD_ID}/channels"
    return server.api.write("POST", path, body, describe=f"create {label}")["id"]


def ensure_channels(server: Server) -> None:
    """Create or update every category and channel, then put them in order."""
    for spec in CATEGORIES + CHANNELS:
        server.ids[spec.name] = ensure_channel(server, spec)
    voice = next(
        (c for c in server.channels if c["name"] == "Voice Channels" and c["type"] == CATEGORY),
        None,
    )
    if voice:
        server.ids["Voice Channels"] = voice["id"]
    for group in ORDER:
        positions = [
            {"id": server.ids[name], "position": i}
            for i, name in enumerate(n for n in group if n in server.ids)
        ]
        path = f"/guilds/{GUILD_ID}/channels"
        server.api.write("PATCH", path, positions, describe=f"order {', '.join(group)}")


def update_server(server: Server) -> None:
    """Set the server's icon, description, and safety and notification defaults."""
    icon = base64.b64encode(ICON.read_bytes()).decode()
    body = {
        "icon": f"data:image/png;base64,{icon}",
        "description": (
            "A local AI community for Fairfield, Connecticut: builders, thinkers, "
            "and the AI-curious."
        ),
        "default_message_notifications": 1,
        "explicit_content_filter": 2,
        "system_channel_id": server.ids["introductions"],
    }
    describe = "update server icon, description, notifications, content filter, and join messages"
    server.api.write("PATCH", f"/guilds/{GUILD_ID}", body, describe=describe)


def rules_post(ids: dict[str, str]) -> str:
    """The code of conduct posted in #welcome-and-rules."""
    return f"""{RULES_HEADING}
A local community in Fairfield, Connecticut for builders, thinkers, and the AI-curious to \
learn, share, and build together. Technical or not, you're welcome here.

## Community guidelines
1. Be respectful. No harassment, hate speech, threats, or personal attacks.
2. No spam, unsolicited advertising, or scams.
3. Don't share other people's personal information or content you don't have the right \
to share.
4. Nothing illegal or sexually explicit.
5. When you share AI-generated content, don't present it as someone else's words or use \
it to deceive.

Organizers may remove content, and anyone who breaks these guidelines, online or at events.

## Getting started
- Say hello in <#{ids["introductions"]}>
- Share what you're building in <#{ids["show-and-tell"]}>
- Ask anything in <#{ids["help-and-questions"]}>
- Event news lands in <#{ids["announcements"]}>

Terms of Service: https://www.fairfieldct.ai/terms/
Privacy Policy: https://www.fairfieldct.ai/privacy/
Questions? hello@inbox.fairfieldct.ai"""


def post_rules(server: Server, bot_id: str) -> None:
    """Post the code of conduct, or update the bot's earlier post."""
    channel = server.ids["welcome-and-rules"]
    body = {"content": rules_post(server.ids), "flags": SUPPRESS_EMBEDS}
    messages = (
        [] if is_placeholder(channel) else server.api.get(f"/channels/{channel}/messages?limit=50")
    )
    posted = next(
        (
            m
            for m in messages
            if m["author"]["id"] == bot_id and m["content"].startswith(RULES_HEADING)
        ),
        None,
    )
    if posted:
        path = f"/channels/{channel}/messages/{posted['id']}"
        server.api.write("PATCH", path, body, describe="update rules post")
    else:
        server.api.write("POST", f"/channels/{channel}/messages", body, describe="post rules")


def ensure_automod(api: Api) -> None:
    """Add spam and keyword filters alongside Discord's default mention-spam rule."""
    existing = {r["trigger_type"]: r for r in api.get(f"/guilds/{GUILD_ID}/auto-moderation/rules")}
    block = [{"type": 1, "metadata": {"custom_message": "This message was blocked by AutoMod."}}]
    wanted = [
        (3, "Block spam content", {}),
        (4, "Block sexual content and slurs", {"trigger_metadata": {"presets": [2, 3]}}),
    ]
    for trigger, name, extra in wanted:
        body = {"name": name, "event_type": 1, "actions": block, "enabled": True, **extra}
        if trigger in existing:
            path = f"/guilds/{GUILD_ID}/auto-moderation/rules/{existing[trigger]['id']}"
            api.write("PATCH", path, body, describe=f"update AutoMod rule {name}")
        else:
            path = f"/guilds/{GUILD_ID}/auto-moderation/rules"
            body["trigger_type"] = trigger
            api.write("POST", path, body, describe=f"create AutoMod rule {name}")


COMMANDS = [
    {"name": "ping", "description": "Check that the fairfieldct.ai bot is listening", "type": 1},
    {"name": "meetup", "description": "Show the next fairfieldct.ai meetup", "type": 1},
]


# Linked Roles metadata the site API sets on each member's role connection
# (fairfieldai/site, crates/api/src/discord_link.rs). Type 7 is BOOLEAN_EQUAL.
ROLE_CONNECTION_METADATA = [
    {
        "type": 7,
        "key": "member",
        "name": "fairfieldct.ai member",
        "description": "Has a fairfieldct.ai account",
    },
]


def register_role_connection_metadata(api: Api) -> None:
    """Tell Discord which Linked Roles fields the application sets."""
    path = f"/applications/{APPLICATION_ID}/role-connections/metadata"
    describe = "register Linked Roles metadata (member)"
    api.write("PUT", path, ROLE_CONNECTION_METADATA, describe=describe)


def register_commands(api: Api) -> None:
    """Register the slash commands the Discord Lambda in fairfieldai/site handles."""
    names = ", ".join(f"/{command['name']}" for command in COMMANDS)
    path = f"/applications/{APPLICATION_ID}/commands"
    api.write("PUT", path, COMMANDS, describe=f"register {names}")


def ensure_invite(server: Server, bot_id: str) -> str:
    """Reuse or create the bot's permanent invite, returning its URL."""
    invites = [
        i
        for i in server.api.get(f"/guilds/{GUILD_ID}/invites")
        if i.get("inviter", {}).get("id") == bot_id and i["max_age"] == 0 and i["max_uses"] == 0
    ]
    if invites:
        return f"https://discord.gg/{invites[0]['code']}"
    path = f"/channels/{server.ids['welcome-and-rules']}/invites"
    body = {"max_age": 0, "max_uses": 0, "unique": False}
    invite = server.api.write("POST", path, body, describe="create invite")
    return f"https://discord.gg/{invite['code']}"


@dataclass(frozen=True)
class WebhookSpec:
    """A webhook the Lambdas post through, and the SSM parameter that holds its URL."""

    channel: str
    name: str
    parameter: str
    avatar: bool = False


WEBHOOKS = [
    WebhookSpec("inbox", "Inbox", "/fairfieldct-ai/prod/discord-inbox-webhook"),
    # Meetup announcements and reminders appear to come from the community.
    WebhookSpec(
        "announcements",
        "fairfieldct.ai",
        "/fairfieldct-ai/prod/discord-announcements-webhook",
        avatar=True,
    ),
]


def ensure_webhook(server: Server, spec: WebhookSpec, output_dir: Path) -> None:
    """Create a webhook if it's missing, saving its URL to an owner-only file.

    The URL is a credential, so it's never printed.
    """
    channel = server.ids[spec.channel]
    hooks = [] if is_placeholder(channel) else server.api.get(f"/channels/{channel}/webhooks")
    if any(h["name"] == spec.name for h in hooks):
        print(f"#{spec.channel} webhook exists; its URL belongs in {spec.parameter}")
        return
    body = {"name": spec.name}
    if spec.avatar:
        body["avatar"] = f"data:image/png;base64,{base64.b64encode(ICON.read_bytes()).decode()}"
    describe = f"create #{spec.channel} webhook"
    hook = server.api.write("POST", f"/channels/{channel}/webhooks", body, describe=describe)
    if server.api.dry_run:
        return
    path = output_dir / f"{spec.channel}-webhook-url"
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, OWNER_ONLY)
    with os.fdopen(fd, "w") as f:
        f.write(f"https://discord.com/api/webhooks/{hook['id']}/{hook['token']}")
    print(
        f"saved the #{spec.channel} webhook URL to {path} (owner-only). "
        "Store it, then delete the file:\n"
        f"  aws ssm put-parameter --profile {AWS_PROFILE} --region {AWS_REGION} "
        f"--type SecureString --overwrite --name {spec.parameter} --value file://{path}"
    )


def setup(api: Api, output_dir: Path) -> None:
    """Bring the server to the configuration this script describes."""
    server = Server(
        api=api,
        guild=api.get(f"/guilds/{GUILD_ID}"),
        channels=api.get(f"/guilds/{GUILD_ID}/channels"),
    )
    bot_id = api.get("/users/@me")["id"]
    server.access = access_levels(ensure_roles(api))
    ensure_channels(server)
    update_server(server)
    post_rules(server, bot_id)
    ensure_automod(api)
    register_commands(api)
    register_role_connection_metadata(api)
    print(f"invite: {ensure_invite(server, bot_id)}")
    for spec in WEBHOOKS:
        ensure_webhook(server, spec, output_dir)


def ssm_parameter(name: str) -> str:
    """Read and decrypt an SSM parameter with the AWS CLI."""
    command = [
        "aws", "ssm", "get-parameter", "--profile", AWS_PROFILE, "--region", AWS_REGION,
        "--name", name, "--with-decryption", "--query", "Parameter.Value", "--output", "text",
    ]  # fmt: skip
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout.strip()


def main() -> None:
    """Parse arguments and run setup."""
    parser = argparse.ArgumentParser(description="Configure the fairfieldct.ai Discord server.")
    parser.add_argument("--dry-run", action="store_true", help="print changes without making them")
    args = parser.parse_args()
    token = os.environ.get("DISCORD_TOKEN") or ssm_parameter(TOKEN_PARAMETER)
    setup(Discord(token, dry_run=args.dry_run), Path.cwd())


if __name__ == "__main__":
    main()
